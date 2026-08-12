# Helm chart best practices — the short version

A checklist for writing charts you'll still like in a year. Every rule has a reason and a working
example in this repo, mostly in [`edu-greetings-chart`](./edu-greetings-chart/README.md).

Read it once now, then keep it open during [module 3](./3-your-own-system/README.md).

---

## The 60-second version

| Do | Because |
|---|---|
| Template anything that differs per environment | That's the entire point of a chart |
| Never template the `namespace` | `--namespace` is the caller's job |
| Default `image.tag` to `.Chart.AppVersion`, never `latest` | `latest` makes rollback meaningless |
| Bump `version` on **every** chart change | A published version must mean one thing forever |
| Keep credentials out of values files | Values files live in git and get pasted into tickets |
| Never put a changing value in a selector | Selectors are immutable — you'd brick the chart |
| Migrations go in a `post-install,pre-upgrade` hook | `pre-install` deadlocks; see below |
| `required` + `values.schema.json` | Fail in one second, not at 3am |
| Don't expose a knob that can only break things | A lie in your API is worse than a missing feature |
| `helm lint` in CI, `helm diff` before upgrade | Cheap; catches the embarrassing ones |

---

## 1. What to template

The test: **would two environments ever want different values here?** If yes, template it.

Almost always template:

- **Image repository and tag.** Default the tag to `.Chart.AppVersion` so the chart and the image
  it deploys can't drift apart, and so nobody has to remember to set it.
  → [`_helpers.tpl` `greetings.image`](./edu-greetings-chart/templates/_helpers.tpl)
- **Replica counts** — for things that can actually scale.
- **Ingress hostname, class, TLS and annotations.** Hostnames are the single most common
  hardcoding, and the class differs by cluster (`traefik` locally, something else in production).
- **Resource requests and limits.** A laptop and a production node want very different numbers.
- **Hostnames and ports of dependencies** — databases, caches, external APIs. Also the toggle that
  swaps a bundled dependency for a managed one.
- **Storage class and volume size.** `local-path` locally, `longhorn` or a cloud class in prod.
- **Feature toggles** for optional components, so one chart serves the small and large deployments.

### The rule that actually bites: one value, N references

A port or a hostname is usually referenced in **more places than you think**. Miss one and you get
a failure that looks like something else entirely. In this workshop's gateway chart, `service.port`
appears in five places, and getting four of five right produces two *different* symptoms:

- probes still on the old port → Pod never Ready → no endpoints
- Service and Ingress disagreeing on the port → Traefik 404s, which looks like a routing bug

**Mitigation: use named ports.** `targetPort: http` and `port: http` in probes follow the container
automatically, so there's one number instead of four.

```yaml
ports:
  - name: http                      # name it once
    containerPort: {{ .Values.service.port }}
readinessProbe:
  httpGet:
    port: http                      # then reference the NAME everywhere else
```

### What NOT to template

- **`namespace` in `metadata`.** Official guidance: leave it out and let `--namespace` decide.
  Hardcoding it breaks installing the chart twice and confuses every other tool.
- **Anything that can only break.** `charts/postgres` deliberately has **no** `replicaCount`,
  because two Postgres Pods on one `ReadWriteOnce` volume cannot work. A knob whose only effect is
  an outage is a lie in your API.
- **Selector labels.** More below — this one is permanent.
- **Secret values.** Take a Secret *name*, not a password.
- **Everything, just in case.** Every value is a promise you have to keep. A 40-line chart you
  understand beats a 400-line one you inherited.

---

## 2. `values.yaml` is your API

Treat it like a public interface, because that's what it is.

- **camelCase, starting lowercase.** `chickenNoodleSoup`, not `Chicken_Noodle_Soup`. Initial caps
  can collide with built-ins; hyphens don't work in template paths.
- **Prefer flat over nested.** Every level of nesting is another existence check in your templates.
  Nest only when a group of related values genuinely belongs together.
- **Prefer maps over arrays.** `--set servers.foo.port=80` is usable; overriding array index 3 is
  not. Arrays also **replace wholesale** on merge instead of merging (see below).
- **Quote strings, never quote integers.** YAML type coercion will surprise you — `1.30` becomes
  `1.3` and your image tag is wrong. Environment variable values are the exception: quote those
  even when numeric.
- **Document every value with a comment that starts with the property name.** It makes the file
  greppable and lets doc tooling pick it up.

### Merge semantics people get wrong

```
chart values.yaml → -f a.yaml → -f b.yaml → --set → --set-string      (later wins)
```

**Maps merge per key. Arrays are replaced entirely.** So a `-f prod.yaml` that sets `args: [--c]`
silently drops `--a` and `--b` from the defaults. This is the most surprising behaviour in Helm.

And `--set` is **not sticky**: each upgrade re-derives values from the chart defaults plus what you
pass *this time*. Use values files so you don't have to remember.

When someone insists they set a value: `helm get values <release>` (add `--all` for defaults
merged in). It's nearly always a replaced array or an unrepeated `--set`.

---

## 3. Versioning

Two version numbers in `Chart.yaml`, moving independently:

| Field | Means | Bump when |
|---|---|---|
| `version` | the **chart** | any change to templates or values — SemVer |
| `appVersion` | the **app inside** | you ship a new application build |

- **Fixing a typo in a template bumps `version` only.** `appVersion` didn't change.
- **SemVer honestly.** Renaming or removing a value is a **breaking change** → major bump. Your
  users' values files stop working; that's a major by definition.
- **A published chart version is immutable.** Registries reject re-pushing an existing version, and
  rightly so — a version must mean exactly one thing forever. Bump before every push.
- **Never default an image tag to `latest`.** You can't roll back to a tag that moved. Default to
  `.Chart.AppVersion` and pin real versions.
- **`Chart.lock`:** commit it when you have **remote** dependencies, so two engineers running
  `helm dependency update` on different days get the same versions. It adds nothing for a
  `file://` subchart that lives in the same commit — which is why this repo gitignores it.

---

## 4. Hooks

Hooks are the thing plain manifests genuinely cannot do: ordered, run-once work around a release.
`pre-install`, `post-install`, `pre-upgrade`, `post-upgrade`, `pre-delete`, `test`.

### Migrations: `post-install,pre-upgrade`

```yaml
annotations:
  "helm.sh/hook": post-install,pre-upgrade
  "helm.sh/hook-weight": "-5"
  "helm.sh/hook-delete-policy": before-hook-creation
```

**Why not `pre-install`?** Hooks run to completion *before* the manifests of that phase are
applied — so on `pre-install` your database doesn't exist yet. The migration Job waits for a
database Helm hasn't created, until `--timeout` kills the whole install. This catches everybody
once.

- `post-install` → the database exists. First-run schema.
- `pre-upgrade` → runs **before** the new code rolls out, on an existing database. Migrate, *then*
  deploy the code that depends on the migration.

**The payoff, worth knowing:** a failing `pre-upgrade` hook aborts the upgrade with the live
release **bit-for-bit untouched** — old ConfigMap, old Pods, still serving. With a `post-upgrade`
migration the new code is already taking traffic when the migration fails, and now you have new
code against an old schema. That's the genuinely bad outage.

### Don't delete a successful migration Job

`hook-delete-policy: hook-succeeded` looks tidy and destroys your evidence — `kubectl logs job/...`
then returns `NotFound` and there's no record the migration ran or what it changed. Use
`before-hook-creation` alone: the previous Job is cleared just before the next run (a Job's spec is
immutable, so *something* has to clear it), and the log survives.

For a schema change, the record is worth more than a clean namespace. `kubectl get jobs` also then
answers "did the migration run?" at a glance.

### Hook limits

- **Rollback does not undo a hook's side effects.** `helm rollback` restores manifests; it does not
  un-migrate your database. Write migrations so they're backward-compatible with the previous
  release, or accept that rollback is manifests-only.
- **Make hooks idempotent.** `pre-upgrade` runs on every upgrade forever.
  `CREATE TABLE IF NOT EXISTS` and `ON CONFLICT DO NOTHING`.
- `hook-weight` orders hooks in the same phase (lowest first).

---

## 5. Secrets

**Never in a values file.** Values files are committed, diffed, pasted into tickets and fed to
LLMs.

Best to worst:

1. **External Secrets Operator** — chart references a Secret; the operator populates it from Vault
   / Key Vault / AWS SM. Usually the right answer.
2. **Sealed Secrets or SOPS** — encrypted values, safe to commit.
3. **`existingSecret`** — the chart takes a Secret *name* and never templates the credential at all.
   Cheapest to implement and always worth offering as an escape hatch.

```yaml
database:
  existingSecret: greetings-db-credentials   # chart uses this and ignores any password value
  existingSecretKey: password
```

Prove it works: `values-prod.yaml` in this repo renders **zero** Secrets.

```bash
helm template x ./edu-greetings-chart -f edu-greetings-chart/values-prod.yaml | grep -c "kind: Secret"
# 0
```

Also: **base64 is encoding, not encryption.** And the `randAlphaNum` password trick regenerates on
every upgrade unless you guard it with `lookup` — which itself returns empty under
`helm template` (no cluster). Generating passwords in a chart is more fragile than it looks.

---

## 6. Naming and labels

```
{{- define "chart.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "chart.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
```

- **Derive object names from `.Release.Name`** so the chart can be installed twice in one namespace.
  Hardcoded names collide — [module 1](./1-simplest-chart/README.md) makes you feel it.
- `trunc 63` because Kubernetes names cap at 63 characters; `trimSuffix "-"` because truncation can
  leave a trailing dash, which is invalid.
- Chart names must be DNS-1123: lowercase, numbers, dashes.

### ⚠️ Selector labels are immutable

```yaml
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

A Deployment's `spec.selector` **cannot be changed after creation.** Put anything that varies —
especially `app.kubernetes.io/version` or a chart version — in there and your chart becomes
**permanently un-upgradeable**; users have to delete and recreate the release. Keep selector labels
a small, stable subset of your full labels.

This is the single most damaging chart mistake, because it's discovered later and can't be fixed
forward.

---

## 7. Fail early

```yaml
password: {{ required "database.password is required (or set database.existingSecret)" .Values.database.password }}
```

And a [`values.schema.json`](./edu-greetings-chart/values.schema.json) so bad input dies before it
reaches the cluster:

```bash
helm template g ./edu-greetings-chart --set replicaCount=1000
# Error: at '/replicaCount': maximum: got 1,000, want 10
helm template g ./edu-greetings-chart --set image.pullPolicy=ifNotPresent
# Error: value must be one of 'Always', 'IfNotPresent', 'Never'
```

Worth schema-validating: enums (`pullPolicy`), port ranges, Kubernetes quantities
(`^[0-9]+(Mi|Gi|Ti)$` catches `size: 1` and `size: 1GB`), and identifiers with real syntax rules —
a Postgres database name can't contain a dash, so `^[a-zA-Z_][a-zA-Z0-9_]*$` catches `my-db` at
install instead of at connection time.

Keep the schema **loose for subchart values** — the subchart owns its own contract, and
over-specifying it means editing two files every time it changes.

---

## 8. Dependencies and subcharts

```yaml
dependencies:
  - name: postgres
    version: "1.0.0"
    repository: "file://charts/postgres"
    condition: postgres.enabled
```

- **`condition`** makes a dependency optional — one flag swaps the bundled toy database for a
  managed one. This is the main reason to use a subchart rather than four more templates.
- **A subchart cannot read its parent's values.** It gets exactly what the parent passes under its
  own key.
- **`global:` is the only shared namespace.** Anything both tiers must agree on goes there.
- **Values files are plain YAML, not templates**, so a parent *cannot compute* a value to pass down.
  When both charts need a name that depends on `.Release.Name`, they have to derive it by the same
  documented convention. Name that coupling in a comment rather than hiding it.
- **Pin dependency versions**, and put Renovate or Dependabot on them.
- **Don't fork a third-party chart to change one thing.** Look for the value first, then an
  `extraEnv`-style escape hatch, then a post-renderer. A fork is a maintenance liability forever.

---

## 9. Operating a chart

```bash
helm diff upgrade prod ./chart -f values-prod.yaml        # see it before you do it
helm upgrade ... --rollback-on-failure --timeout 60s      # was --atomic in Helm 3
helm test <release>                                       # can the release verify itself?
```

- **`--rollback-on-failure`** implies `--wait`, which is what makes failure detectable at all.
  Without waiting, Helm submits manifests, sees no error, and reports success while the Pod is in
  `ImagePullBackOff`. It only rolls *back* — a failed **first** install has nowhere to go, so Helm
  uninstalls instead.
- **Probes are what make `--wait` meaningful.** No readiness probe means Helm can't tell a working
  release from a broken one. Liveness should check the process, readiness the dependencies —
  deliberately *not* both, or one database blip restarts every replica at once.
- **`helm test`** with a Pod that `curl -f`s a real endpoint. Non-zero exit fails the test, which
  is what lets a pipeline promote a release without a human clicking around.
- **`helm.sh/resource-policy: keep`** on anything you'd cry about losing — notably a database PVC,
  which `helm uninstall` otherwise deletes along with your data.
- **`checksum/config`** annotation so a ConfigMap change rolls the Pods, and an unrelated value
  doesn't:
  ```yaml
  checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  ```
  Annotating with `.Release.Revision` instead restarts on *every* upgrade — blunt, but fine for a
  demo.

---

## 10. Anti-patterns

| ❌ | Instead |
|---|---|
| `image.tag: latest` | default to `.Chart.AppVersion`, pin real versions |
| Password in `values.yaml` | `existingSecret` + External Secrets / SOPS |
| `namespace:` in `metadata` | let `--namespace` decide |
| Version label in a selector | keep selectors small and stable — otherwise unfixable |
| Copying a chart to make "the prod one" | one chart, a values file per environment |
| Exposing every field "just in case" | expose what varies; delete the rest |
| Deleting a successful migration Job | keep the log |
| `pre-install` migration hook | `post-install,pre-upgrade` |
| A knob that can only break things | don't offer it |
| Forking a chart to change one value | values, escape hatch, or post-renderer |
| Templating so hard nobody can read it | boring templates; the next reader is you at 3am |
| `helm upgrade` from a laptop as the deploy process | CI or GitOps — see [gitops-loop](./deck-notes/gitops-loop.md) |

---

## Pre-flight checklist

Before you publish a chart, or open a PR that changes one:

- [ ] `helm lint ./chart` passes
- [ ] `helm template ./chart` renders, and with **each** values file
- [ ] `helm template ./chart | kubeconform -` (or `kubectl apply --dry-run=server`)
- [ ] No credentials anywhere in the chart or its values files
- [ ] `version` bumped; major if you renamed or removed a value
- [ ] Image tags pinned, nothing on `latest`
- [ ] Every value in `values.yaml` has a comment
- [ ] Selector labels contain nothing that changes
- [ ] Readiness probe exists, so `--wait` and `--rollback-on-failure` mean something
- [ ] `NOTES.txt` still tells the truth for a non-default values file
- [ ] Installs into a **fresh namespace** from scratch, not just as an upgrade of your dev release

That last one catches more real bugs than the rest combined.

---

## Sources

Official Helm guidance:
[Chart best practices](https://helm.sh/docs/chart_best_practices/),
[General conventions](https://helm.sh/docs/chart_best_practices/conventions/),
[Values](https://helm.sh/docs/chart_best_practices/values/),
[Tips and tricks](https://helm.sh/docs/howto/charts_tips_and_tricks/).

Community write-ups consulted:
[Production-Ready Helm Charts (DevOpsil, 2026)](https://devopsil.com/articles/2026-03-21-helm-chart-best-practices-production),
[Helm Charts Best Practices 2026 (TechStackGuide)](https://techstackguide.com/helm-charts-best-practices/),
[Helm Chart Validation & Structure (Toolgrid, 2026)](https://blog.toolgrid.io/2026/04/helm-chart-validator.html).

The hook-ordering, delete-policy and port-drift items were confirmed by running them on a local
cluster while building this workshop, not just read.
