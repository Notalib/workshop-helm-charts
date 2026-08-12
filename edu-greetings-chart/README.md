# edu — The greetings chart (worked example)

**This is not an exercise.** Nothing to fill in. It's the finished article: the Spring Boot +
Postgres system you containerised in workshop #1 and wired together by hand in
[workshop #2 module 5](https://github.com/notalib/workshop-kubernetes/tree/main/5-composite-system),
now packaged as **one installable, versioned, configurable chart**.

Workshop #2 closed with a promise:

> *"Remember the four files you wrote in module 5? Next workshop we'll turn that system into a
> chart — templated, versioned, installable in dev/staging/prod with one command and a values
> file per environment."*

This is that chart. Read it, run it, then steal from it in
[module 3](../3-your-own-system/README.md).

```
  Ingress (greetings.localhost)
      │
      ▼
  Service  g-greetings ──► Deployment  g-greetings   (Spring Boot, N replicas)
                                  │
                                  │  POSTGRES_HOST=database
                                  ▼
                           Service  database ──► Deployment  database  (Postgres)
                                                        │
                                                        ▼
                                                      PVC  database-data

  + hook Job  g-greetings-migrate   (schema, runs post-install / pre-upgrade)
  + test Pod  g-greetings-test-api  (only on `helm test`)
```

---

## Run it

```bash
helm install g ./ 
```

Follow the rendered `NOTES.txt`. Then:

```bash
curl -H "Host: greetings.localhost" http://127.0.0.1/greetings
helm test g
```

Add a greeting through the form at `http://greetings.localhost/new`, then prove it really landed
in Postgres:

```bash
kubectl exec deploy/database -- psql -U postgres -d example -c "SELECT * FROM greetings;"
```

Two environments from one chart:

```bash
helm upgrade g ./ -f values-dev.yaml
helm upgrade g ./ -f values-prod.yaml   # 3 replicas, TLS, bigger volume
```

Clean up with `helm uninstall g`.

---

## What to look at, and why

### The four files became one chart

| workshop #2 module 5 | here |
|---|---|
| `configmap.yaml` (hand-typed values) | `templates/configmap.yaml` (computed) |
| `secret.yaml` (password in git) | `templates/secret.yaml` (+ `existingSecret` escape hatch) |
| `postgres.yaml` (Deployment + Service + PVC) | `charts/postgres/` — a **subchart** |
| `backend.yaml` (Deployment + Service + Ingress) | `templates/{deployment,service,ingress}.yaml` |
| BONUS 4's `initContainers:` | `templates/job-migrate.yaml` — a **hook** |

Put `templates/deployment.yaml` side by side with module 5's `backend.yaml`. **That diff is the
whole lesson on templating** — same object, with the parts that vary per environment pulled out.

### The three-way contract became one value

Module 5's central warning was that three things had to agree by hand: the ConfigMap's
`POSTGRES_HOST`, the name of the database Service, and the env var on the backend. Get one wrong
and the backend can't connect.

Here, `greetings.databaseHost` in [`templates/_helpers.tpl`](./templates/_helpers.tpl) computes it
once. The ConfigMap reads the helper; the subchart's Service name comes from the same value. There
is nothing left to keep in agreement.

```bash
helm template g ./ | grep -E "POSTGRES_HOST|^  name: database"
```

### `global`, and why it exists

A subchart cannot read its parent's values, and a parent's values file is plain YAML — it can't
compute anything. So how do two charts agree on the database name?

`global:` is the one section both can read. See `global.database.name` in
[`values.yaml`](./values.yaml), used by this chart's ConfigMap *and* by
`charts/postgres/templates/deployment.yaml`.

Where `global` doesn't work — the Secret's name, which needs the release name — both charts derive
it from `.Release.Name` by the **same convention**, documented in both helper files. That coupling
is real and named rather than hidden.

### The migration is a hook, not an init container

[`templates/job-migrate.yaml`](./templates/job-migrate.yaml) is the most instructive file here.
Module 5's init container ran on every Pod start in every replica; this runs **once per release
operation**.

The comment at the top explains the trap that catches everyone writing their first hook: it's
`post-install`, **not** `pre-install`, because on `pre-install` the Postgres Deployment doesn't
exist yet — the Job would wait for a database Helm hasn't created, until `--timeout` kills the
install.

```bash
helm get hooks g                                    # what Helm considers a hook
kubectl logs job/g-greetings-migrate                # the migration's own output
```

### A rollout only when the config changed

Module 1's chart annotated Pods with `.Release.Revision`, restarting on *every* upgrade.
`templates/deployment.yaml` hashes the rendered ConfigMap instead:

```yaml
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

Change an unrelated value and the Pods stay up. Change `global.database.name` and they roll.

### The chart validates its own inputs

[`values.schema.json`](./values.schema.json) fails bad values in about a second, before anything
reaches the cluster. Try it:

```bash
helm template g ./ --set replicaCount=1000
# Error: at '/replicaCount': maximum: got 1,000, want 10

helm template g ./ --set global.database.name=my-db
# Error: 'my-db' does not match pattern '^[a-zA-Z_][a-zA-Z0-9_]*$'   (Postgres would reject it)

helm template g ./ --set image.pullPolicy=ifNotPresent
# Error: value must be one of 'Always', 'IfNotPresent', 'Never'
```

Each of those is a real outage avoided at zero cost.

### The release can test itself

[`templates/tests/test-api.yaml`](./templates/tests/test-api.yaml) is a Pod annotated
`helm.sh/hook: test` — not created on install, only by `helm test g`. `curl -f` exits non-zero on
an HTTP error, which fails the Pod, which fails `helm test`. No assertion framework.

This is what lets a pipeline promote a release automatically: deploy, `helm test`, and roll back
if it fails.

### The database can be swapped out

`dependencies:` in [`Chart.yaml`](./Chart.yaml) carries `condition: postgres.enabled`. So the toy
Postgres is one flag away from being replaced by a managed database:

```bash
helm template g ./ --set postgres.enabled=false --set database.hostOverride=db.example.com \
  | grep -E "^kind:|POSTGRES_HOST:"
```

The whole `database` Deployment, Service and PVC vanish, and the backend dials the external host
instead. That flexibility is why the database is a subchart rather than four more templates.

### Deliberate non-features

Worth noticing what *isn't* configurable, because restraint is part of chart design:

- **Postgres has no `replicaCount`.** Two Postgres Pods against one `ReadWriteOnce` volume cannot
  work, so exposing the knob would only let people break themselves. `strategy: Recreate` is set
  for the same reason — the default rolling update would deadlock on the volume.
- **The PVC has no `helm.sh/resource-policy: keep`.** So `helm uninstall` deletes your data. The
  comment in [`charts/postgres/templates/pvc.yaml`](./charts/postgres/templates/pvc.yaml) shows
  the one-line change, and why a real database chart wants it.

---

## Stuck?

- `helm template g ./ --debug` — render without a cluster.
- `helm get manifest g` — what the cluster actually received.
- `helm get hooks g` — the Job and test Pod, which don't appear in `get manifest`.
- Backend `CrashLoopBackOff`? `kubectl logs deploy/g-greetings --previous`. Almost always the DB:
  check `POSTGRES_HOST` in the ConfigMap against `kubectl get svc`.
- Migration Job never finishes? `kubectl logs job/g-greetings-migrate` — it loops on `pg_isready`
  until Postgres answers, so this usually means Postgres itself didn't start.
- `ImagePullBackOff`? The GHCR package must be public. `kubectl describe pod -l app.kubernetes.io/instance=g`.

## BONUS

1. **Make Postgres a StatefulSet** with a `volumeClaimTemplate` instead of a Deployment + PVC.
   Why is that the more correct choice for a database, and what do you gain? (Same BONUS as
   workshop #2 module 5 — now do it inside a chart.)
2. **Add `helm.sh/resource-policy: keep`** to the PVC, then `helm uninstall` and reinstall. Is
   your data still there? Now explain the trade-off to whoever has to clean up the cluster.
3. **Break the migration on purpose** — add invalid SQL to the hook Job, then
   `helm upgrade g ./ --rollback-on-failure --timeout 60s`. Does the release roll back? Does the
   *database* roll back? (This is the hardest real problem with schema migrations, and Helm does
   not solve it.)
4. **Add a second environment.** Write `values-staging.yaml` with two replicas and its own
   hostname. How much did you have to write? That number is the payoff of this whole workshop.
5. **Generate the password** instead of shipping a placeholder — look up `randAlphaNum` and the
   `lookup` function. Why is `lookup` necessary, and what breaks if you leave it out? (Hint: what
   happens to the password on the next `helm upgrade`?)
