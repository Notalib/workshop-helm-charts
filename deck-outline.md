# Helm Charts Workshop — deck outline

Slide-by-slide spec for `Helm_workshop.pptx`. Build it in the KB/Nota template used for
[workshop #1](https://github.com/notalib/workshop-containerisation) and
[#2](https://github.com/notalib/workshop-kubernetes).

**Conventions carried over from the previous two decks:**

- Danish narrative, English technical terms — as in *"Hvad er Kubernetes?"*, *"Komplekse
  systemer"*, but `Deployment`, `values.yaml`, `rollback` untranslated.
- Numbered section dividers (`1. Helm Basics`, `2. CLI Demo`, …).
- An **"Exercise recap"** slide after every exercise: *Hvad lærte vi? Hvad var svært? Se på
  løsning.*
- Extras section at the end (`X. Extras`) for the questions that come up.

**Analogies — extend the established set, don't replace it.** Workshop #1/#2 established
*Container = Legoklods*, manifests = IaC, cluster = 🧠 + 💪. This deck adds **Chart = byggesættet**
(the boxed Lego set: parts list + instruction booklet) and reuses **release = git for your
deployment** from the #2 teaser, deliberately, for continuity.

**Templating gets no analogy.** This is a developer audience — say it plainly: *a template is the
manifest you already wrote in module 5, with the parts that vary pulled out into variables.* Slide
32 shows module 5's `backend.yaml` beside the templated version and lets the diff carry it.

**68 slides / 240 minutes.** Density matches `Kubernetes_workshop.pptx` (71 slides / 4h).
Timings per section are in the headers and mirror `README.md`'s run sheet.

---

## Front matter (slides 1–3)

### Slide 1 — Title
**Content:** Helm Charts · Workshop · DevOps workshop #3 · [dato] · af Daniel Freiling
**Notes:** Same visual identity as #1 and #2 — this is a series, and it should look like one.

### Slide 2 — Serien
**Content:**
- #1 **Containerisation** — byg *én* container
- #2 **Kubernetes** — kør, skalér og eksponér containere på et cluster
- #3 **Helm** — pak hele systemet som *ét* versioneret release
- #4 — bestemmes af hvad I løber ind i i dag 👀

**Notes:** Land the arc in 30 seconds. The last line is not a joke — the open lab's `BLOCKERS.md`
genuinely decides the next workshop's topic. Say so; it changes how seriously they fill it in.
**[VISUAL: three-step progression, image → manifests → package. Reuse the Lego motif.]**

### Slide 3 — Workshop indhold
**Content:** the run sheet, with `[+Exercise]` markers — same layout as #2's slide 3.
| | |
|---|---|
| Helm Basics | CLI Demo (appetitvækker) |
| Chart anatomy & releases | `[+Exercise]` |
| Templating | `[+Exercise]` |
| Charts i drift + GitOps | `[+Exercise]` |
| **Dit eget system** | `[+50 min åbent lab]` |

**Notes:** Flag the last block explicitly and early. People work differently when they know
they'll be asked about their own system before lunch — some will start thinking about which system
during the theory, which is exactly what you want.

---

## 1. Hvor er vi? (slides 4–8) — 10 min

### Slide 4 — Section divider
**Content:** `1.` Hvor er vi? — fra manifests til pakke

### Slide 5 — Recap: hvad I kan nu
**Content:**
- #1: `Dockerfile` → container image → kører hvor som helst
- #2: manifests → Deployment, Service, Ingress, ConfigMap, Secret, PVC → reconciliation
- Modul 5: et helt system — backend + database — wired sammen i hånden

**Notes:** Fast. Purely to activate the prior knowledge that the whole deck builds on.

### Slide 6 — Modul 5, som I efterlod det
**Content:** the four files on screen — `configmap.yaml`, `secret.yaml`, `postgres.yaml`,
`backend.yaml`. ~180 lines. Applied by hand, in order.
**Notes:** Have the real files open, not a picture of them. Point at the "three things must agree"
warning about `POSTGRES_HOST` — it comes back on slide 34 as a one-line helper, and that payoff
only works if you plant it here.
**[VISUAL: four YAML files side by side, the POSTGRES_HOST value circled in all three places it appears.]**

### Slide 7 — Spørgsmålet fra sidst
**Content:** > *"Skal jeg virkelig copy-paste al den YAML for hver app og hvert miljø?"*
**Notes:** This is verbatim the question workshop #2's `helm-teaser` ended on. Quote the teaser's
promise too — *"next workshop we'll turn that system into a chart"* — and then say: that's today,
and it's the first thing you'll see.

### Slide 8 — Hvad Helm giver os
**Content:**
- **Pakke** — hele systemet som ét artefakt med et versionsnummer
- **Konfiguration** — knapper i stedet for at redigere rå YAML
- **Releases** — nummererede revisioner, med rollback
- **Distribution** — charts ligger i et registry, ved siden af jeres images

**Notes:** Four promises. Each maps to a section of the deck, and each gets demonstrated in the
next 15 minutes. Don't elaborate — the demo does the arguing.

---

## 2. CLI Demo — appetitvækker (slides 9–11) — 15 min

### Slide 9 — Section divider
**Content:** `2.` Helm CLI Demo — én kommando, hele systemet

### Slide 10 — Hvad I skal se efter
**Content:**
- Ét system, én kommando
- Clusteret ser **almindelige manifests** — Helm forsvinder
- Samme chart som dev **og** prod, side om side
- Revisioner: upgrade, historik, rollback
- Vi ødelægger det med vilje — og det retter sig selv

**Notes:** Give them the checklist before the terminal, so the demo is legible rather than a blur
of commands. Then run [`cli-demo/README.md`](./cli-demo/README.md).

### Slide 11 — Observationer
**Content:** left blank on purpose — fill in from the room.
**Notes:** Ask what they noticed before telling them. The answers you're fishing for: "it's still
just Kubernetes underneath", "the diff between dev and prod is tiny", "the broken version never
served traffic". If nobody says the first one, say it yourself — it's the load-bearing insight and
slide 22 depends on it.

---

## 3. Helm Basics (slides 12–25) — 20 min

### Slide 12 — Section divider
**Content:** `3.` Helm Basics — chart, release, revision

### Slide 13 — Hvad er Helm?
**Content:**
- **En package manager for Kubernetes** — `apt`/`npm`, men for cluster-workloads
- Chart = pakken · Repository = registry · Release = installation · Revision = version
- CLI + noget metadata i clusteret. **Ingen server.**

**Notes:** If anyone remembers Tiller from Helm 2: it was a server, it was a security problem, it's
gone. Helm 3 deleted it.

### Slide 14 — Chart = byggesættet
**Content:** Loose bricks (manifests) → a boxed set with a parts list and an instruction booklet.
Same bricks. Now shippable, and someone else can build it.
**Notes:** The one analogy in the deck, and it extends #1's *Container = Legoklods* rather than
competing with it. Don't over-work it — one slide, then back to concrete.
**[VISUAL: pile of loose bricks → boxed Lego set with parts list. Reuse #1's brick styling.]**

### Slide 15 — Chart anatomy
**Content:** the directory tree.
**Notes:** Full talking points in [`deck-notes/chart-anatomy.md`](./deck-notes/chart-anatomy.md).
Emphasise: only `Chart.yaml` + `templates/` are mandatory; `_` prefix means "not a manifest";
`NOTES.txt` **is a template** (module 2 has a task where it lies).
**[VISUAL: annotated directory tree — see deck-notes/chart-anatomy.md]**

### Slide 16 — `Chart.yaml`
**Content:** `apiVersion: v2` · `name` · `version` · `appVersion` · `dependencies`
**Notes:** The two version numbers and why they move independently — `version` is the chart,
`appVersion` is the app inside. Fixing a typo in a template bumps `version` only.
(Helm 4 introduced `apiVersion: v3`, but `helm create` still emits `v2` and v2 is what everything
uses. Mention only if asked.)

### Slide 17 — `values.yaml` er et API
**Content:**
- Chart-defaults — og chartets **offentlige kontrakt**
- Hver key er et løfte til den der installerer
- At omdøbe en value er et **breaking change** → derfor versionsnummeret

**Notes:** The mindset shift that separates a chart people can use from one only its author can.
Most first charts expose either everything or nothing.

### Slide 18 — Release ≠ chart
**Content:** one chart → many releases (`dev`, `prod`, different namespaces), each independent.
**Notes:** Trips up everyone exactly once. Module 1 TASK 6 makes them feel it: install the same
chart twice, watch it collide on hardcoded object names, then fix it with the release name.

### Slide 19 — Revisioner
**Content:** the revision timeline. install → upgrade → upgrade → **failed** → rollback.
**Notes:** [`deck-notes/release-revisions.md`](./deck-notes/release-revisions.md). Key point:
rollback **appends** a revision, it doesn't rewind. Like `git revert`, not `git reset`.
**[VISUAL: revision timeline — see deck-notes/release-revisions.md]**

### Slide 20 — Hvor bor et release?
**Content:** `kubectl get secret -l owner=helm` — one Secret per revision, in the namespace.
**Notes:** Two consequences: there's no Helm server, and the history belongs to the *namespace*,
not to your laptop. A colleague sees the same `helm history`. Delete the namespace and it's gone.

### Slide 21 — Values precedence
**Content:** chart defaults → `-f a.yml` → `-f b.yml` → `--set` → `--set-string`
**Notes:** [`deck-notes/values-precedence.md`](./deck-notes/values-precedence.md). Say the two
gotchas out loud: **maps merge, lists replace**, and `--set` is **not sticky** across upgrades.
**[VISUAL: precedence arrow + the map-merge vs list-replace comparison]**

### Slide 22 — Hvor Helms arbejde slutter ⭐
**Content:** values + templates → render → plain manifests → **API server** ═══ Helm stops here
═══ → controllers reconcile forever.
**Notes:** **The most important slide in the deck.** [`deck-notes/render-pipeline.md`](./deck-notes/render-pipeline.md).
Name the misconception explicitly: *"Helm deploys my app and keeps it running"* — no. Helm renders
and submits; Kubernetes keeps it running. Test question for the room: *if I delete a Pod from a Helm
release, what recreates it?* (The ReplicaSet controller. Helm isn't involved and isn't aware.)
Two payoffs: everything from #2 still applies, and `helm template` needs no cluster.
**[VISUAL: the render pipeline — see deck-notes/render-pipeline.md]**

### Slide 23 — Helm vs Kustomize
**Content:** templating vs overlay patching — the honest comparison.
**Notes:** [`deck-notes/helm-vs-kustomize.md`](./deck-notes/helm-vs-kustomize.md). Someone will
ask, so get ahead of it. Concede the real point: for your own app on your own clusters with two
environments, Kustomize is simpler and it's already in `kubectl`. Helm wins on packaging,
versioning and distribution — and because everything you want to *install* is a chart.
**[VISUAL: side-by-side, see deck-notes/helm-vs-kustomize.md]**

### Slide 24 — Hvad Helm **ikke** er
**Content:**
- ❌ Ikke et CD-værktøj — noget andet skal beslutte *hvornår*
- ❌ Ikke en secrets manager — credentials hører ikke i en values-fil
- ❌ Ikke reconciliation — det er stadig Kubernetes
- ❌ Ikke en garanti for at din app virker

**Notes:** Stating the limits early buys credibility for everything else, and each ❌ is picked up
later: CD on slide 58, secrets on 57, reconciliation on 22, and "your app still has to work" the
moment their first Pod CrashLoops.

### Slide 25 — Kommandoerne I får brug for
**Content:**
```
helm install / upgrade / uninstall     helm template        # render, no cluster
helm list / history / rollback         helm get values|manifest|notes|hooks
helm lint / package / push             helm show values     # what knobs does it have?
```
**Notes:** They don't need to memorise it — `README.md` has the reference. Point at
`helm show values <chart>` as the single most useful command when meeting a chart you didn't write.

---

## Exercise 1 (slides 26–28) — 25 min

### Slide 26 — Section divider
**Content:** `4.` Exercise: **1-simplest-chart** — release-modellen

### Slide 27 — Opgaven
**Content:**
- `git clone https://github.com/notalib/workshop-helm-chart`
- Følg [`1-simplest-chart/README.md`](./1-simplest-chart/README.md)
- Én Deployment, én ConfigMap, tre values — **ingen templating endnu**
- Mål: install → upgrade → `helm template` vs `get manifest` → history → rollback

**Notes:** Check the room is on **Helm 4** and on a **local context** before they start —
`helm version` and `kubectl config current-context`. Someone always has a work cluster selected.
Point at [`setup/README.md`](./setup/README.md) §2.

### Slide 28 — Exercise recap
**Content:** Hvad lærte vi? · Hvad var svært? · Se på løsning
**Notes:** Fish for TASK 6 — installing twice collides on hardcoded names. That's the exact
motivation for `_helpers.tpl`, which is the first thing they meet in module 2. If nobody hit it,
demo it in 30 seconds; the next section is much easier with that failure fresh.

---

## 4. Templating (slides 29–42) — 25 min

### Slide 29 — Section divider
**Content:** `5.` Templating — manifests med huller i

### Slide 30 — Go templates på 60 sekunder
**Content:**
- `{{ .Values.replicaCount }}` — indsæt en værdi
- `{{ .Values.name | quote }}` — pipe gennem en funktion
- `{{- if ... }} ... {{- end }}` — betingelse
- `{{ include "chart.fullname" . }}` — genbrug et named template

**Notes:** Deliberately minimal. They'll learn the rest by doing, and the exercise README has the
same four lines as a cheat-sheet.

### Slide 31 — De indbyggede objekter
**Content:** `.Values` · `.Release` (`.Name`, `.Namespace`, `.Revision`, `.Service`) · `.Chart`
(`.Name`, `.Version`, `.AppVersion`) · `.Capabilities` · `.Template`
**Notes:** `.Release.Name` is the one that matters most — it's what makes two releases coexist.
`.Capabilities.KubeVersion` is how a chart supports several Kubernetes versions; mention, don't dwell.

### Slide 32 — Fra manifest til template ⭐
**Content:** module 5's `backend.yaml` on the left, `edu-greetings-chart/templates/deployment.yaml`
on the right. Highlight only the changed lines.
**Notes:** **This slide replaces any explanation of templating.** They wrote the left-hand side by
hand six weeks ago. The diff is small and self-evident: the parts that vary per environment became
values, everything else is untouched. Let the room read it. Don't narrate the syntax.
**[VISUAL: two-column diff, module 5 backend.yaml vs the templated version. Highlight ONLY changed lines.]**

### Slide 33 — `_helpers.tpl`
**Content:**
```
{{- define "greetings.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "greetings.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
```
**Notes:** Answers module 1's collision directly. Explain `trunc 63` (Kubernetes name limit) and
`trimSuffix "-"` (trunc can leave an invalid trailing dash) — these look like noise and aren't.

### Slide 34 — Tre ting der skal passe → én value ⭐
**Content:** module 5's `POSTGRES_HOST` contract → `greetings.databaseHost` helper.
**Notes:** The payoff for slide 6. Three hand-maintained agreements collapse into one computed
value used in both places. This is the most convincing argument for templating in the whole deck
because they personally felt the pain.
**[VISUAL: three circled values converging into one helper definition.]**

### Slide 35 — Betingede blokke
**Content:** `{{- if .Values.ingress.enabled }}` · `{{- with .Values.annotations }}` ·
`{{- range .Values.hosts }}`
**Notes:** `with` both rescopes `.` **and** skips the block when empty — which is how you avoid an
`annotations:` key with nothing under it. That's a real YAML error people hit.

### Slide 36 — Whitespace 😤
**Content:** `{{-` and `-}}` chomp · `nindent` vs `indent` · `toYaml | nindent 4`
**Notes:** Show a broken render on screen. This is the genuinely annoying part of Helm and module 2
will make them feel it — naming it in advance makes the frustration legible rather than
demoralising. Tell them to turn on whitespace rendering in their editor.

### Slide 37 — Debugging
**Content:**
```
helm template ./ --debug           # render + see the error in context
helm install x ./ --dry-run=client # render without installing
helm lint ./
helm get manifest <release>        # what the cluster actually got
```
**Notes:** **Helm 4:** `--dry-run` now takes `client` or `server`. Bare `--dry-run` still means
`client`. Hammer the loop: you don't need a cluster to iterate on a template.

### Slide 38 — Funktioner der faktisk bruges
**Content:** `default` · `required` · `quote` · `toYaml` · `nindent` · `sha256sum` · `printf` ·
`trunc` · `b64enc` · `tpl`
**Notes:** ~60 functions exist (Sprig); these ten cover almost everything. `required` is the one
they should adopt today — fail at install rather than deploy something broken.

### Slide 39 — Fejl tidligt: `required` og `values.schema.json`
**Content:**
```
password: {{ required "database.password is required" .Values.database.password }}
```
```
"replicaCount": { "type": "integer", "minimum": 1, "maximum": 10 }
```
**Notes:** Show the real error output from `edu-greetings-chart` — `--set replicaCount=1000` fails
in about a second with `at '/replicaCount': maximum: got 1,000, want 10`. Cheap, and it's an outage
that never happens.

### Slide 40 — Rollout når config ændrer sig
**Content:** `checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}`
**Notes:** Callback to workshop #2: editing a ConfigMap does **not** restart Pods. This annotation
makes it. Contrast the two charts — module 1 uses `.Release.Revision` (restarts on *every* upgrade,
blunt); `edu-greetings-chart` hashes the config (restarts only when it changed).

### Slide 41 — Chart-hygiejne
**Content:**
- Selector labels må **aldrig** indeholde version → Deployment-selectors er immutable
- Named ports i stedet for tal gentaget fem steder
- Ikke alt skal være konfigurerbart
- `helm lint` i CI

**Notes:** The first bullet bricks charts permanently and is worth 30 seconds — a changing value in
a selector makes the Deployment un-upgradeable. The third is the design point: `charts/postgres`
deliberately has no `replicaCount`, because two Postgres Pods on one `ReadWriteOnce` volume cannot
work. Exposing a knob that only breaks things is a lie.

### Slide 42 — Exercise-brief
**Content:** ni hardcodede værdier, tre filer, fem success-kriterier.
**Notes:** Set the expectation that the probe ports are the interesting ones — a missed probe port
is the classic "one value templated in four places, missed in a fifth" bug, and `values-broken.yml`
is built to expose exactly that.

---

## Break (slide 43) — 10 min

### Slide 43 — Pause ☕
**Notes:** Genuinely take it. There's 2 hours left and the open lab needs them awake.

---

## Exercise 2 (slides 44–46) — 35 min

### Slide 44 — Section divider
**Content:** `6.` Exercise: **2-gateway-chart** — templating, miljøer, rollback

### Slide 45 — Opgaven
**Content:**
- Følg [`2-gateway-chart/README.md`](./2-gateway-chart/README.md), TASK 1–6
- Template de ni `TODO`s → dev/prod values → ødelæg det → rul tilbage
- `helm lint` + `helm template` er hele feedback-loopet
- Stuck? → `solutions`-branchen

**Notes:** Circulate. The two questions you'll get most: whitespace, and `nil pointer` from a
missing values key. Both are in the README's "Stuck?" section — point rather than solve, at least
the first time.

### Slide 46 — Exercise recap
**Content:** Hvad lærte vi? · Hvad var svært? · Se på løsning
**Notes:** Fish for: the Pod that stayed `0/1` because a probe port wasn't templated; `NOTES.txt`
lying after the hostname changed. Both are the "a value referenced in N places" lesson, which is
the whole reason charts beat copy-pasted YAML.

---

## 5. Charts i drift (slides 47–60) — 25 min

### Slide 47 — Section divider
**Content:** `7.` Charts i drift — dependencies, hooks, publishing, GitOps

### Slide 48 — Dependencies & subcharts
**Content:**
```yaml
dependencies:
  - name: postgres
    version: "1.0.0"
    repository: "file://charts/postgres"
    condition: postgres.enabled
```
**Notes:** `condition` is the payoff: `--set postgres.enabled=false` and the whole database tier
disappears, so the toy Postgres can be swapped for a managed one. Demo it live from
`edu-greetings-chart` — it takes 10 seconds and it lands.

### Slide 49 — Parent, child og `global`
**Content:** parent values → `postgres:` passed down · `global:` visible to both · a subchart
cannot read its parent's values
**Notes:** [`deck-notes/values-precedence.md`](./deck-notes/values-precedence.md), subchart section.
Add the limitation that bites fast: values files are **plain YAML, not templates**, so a parent
can't *compute* a value to pass down. That's why the shared Secret name in the reference chart is a
convention derived from `.Release.Name` in both charts.
**[VISUAL: parent/child value scoping — see deck-notes/values-precedence.md]**

### Slide 50 — Umbrella charts
**Content:** one chart whose only job is to depend on several others — a whole platform as one
release.
**Notes:** This is the shape Merkur has. One release, many components. Ties slide 48 to the live
demo.

### Slide 51 — Hooks
**Content:** `pre-install` · `post-install` · `pre-upgrade` · `post-upgrade` · `pre-delete` ·
`test`
```yaml
annotations:
  "helm.sh/hook": post-install,pre-upgrade
  "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```
**Notes:** Hooks are the thing raw manifests genuinely cannot do — ordered, run-once work around a
release.

### Slide 52 — Hook-fælden ⭐
**Content:** Why the migration Job is `post-install`, **not** `pre-install`.
**Notes:** Best "you would have lost an hour to this" moment in the deck. On `pre-install` the
Postgres Deployment doesn't exist yet — hooks run *before* the manifests of their phase — so the
Job waits for a database Helm hasn't created, until `--timeout` kills the install.
`post-install` + `pre-upgrade` gives the right ordering: migrate, then roll out the code that needs
the migration. Walk through the comment at the top of
[`templates/job-migrate.yaml`](./edu-greetings-chart/templates/job-migrate.yaml).
**[VISUAL: timeline — pre-install hook runs BEFORE manifests exist (✗) vs post-install (✓).]**

### Slide 53 — Fra init container til hook
**Content:** module 5 BONUS 4's `initContainers:` → a hook Job.
**Notes:** The init container ran on every Pod start in every replica — three backend replicas
meant three containers racing to create the same table. A hook runs once per release operation.
Continuity with something they actually typed.

### Slide 54 — `helm test`
**Content:** a Pod annotated `helm.sh/hook: test`, `curl -f`, exit code = verdict.
**Notes:** `curl -f` exits non-zero on an HTTP error → the Pod fails → `helm test` fails. No
assertion framework. This is what lets a pipeline promote a release without a human: deploy,
`helm test`, roll back on failure.

### Slide 55 — Rollback-flowet
**Content:** `helm upgrade --rollback-on-failure --timeout 60s`
**Notes:** [`deck-notes/release-revisions.md`](./deck-notes/release-revisions.md). Say the rename
again — it was `--atomic`, every blog post still says `--atomic`, it warns now. It implies `--wait`.
It only rolls *back*, so a failed first install uninstalls. And the honest limit: **it does not
roll back your database.**

### Slide 56 — `helm diff`
**Content:** `helm diff upgrade prod ./chart -f values-prod.yaml`
**Notes:** `terraform plan` for Kubernetes. Not built in; most teams treat it as mandatory. Show
it against the reference chart if the plugin's installed.

### Slide 57 — Packaging & publishing
**Content:**
```
helm package ./          # -> greetings-1.0.0.tgz
helm push greetings-1.0.0.tgz oci://<registry>/<project>
helm install x oci://<registry>/<project>/greetings --version 1.0.0
```
**Notes:** Charts are **OCI artifacts** — they live in a container registry next to workshop #1's
images. Same registry, same auth, same mental model. A chart version must mean exactly one thing
forever, so registries reject re-pushing an existing version. Bump `version` every time.

### Slide 58 — Secrets hører ikke i en values-fil
**Content:**
- **External Secrets Operator** — henter fra Vault / Key Vault / AWS SM
- **Sealed Secrets / SOPS** — krypteret, sikkert i git
- **`existingSecret`** — chartet kender kun *navnet*

**Notes:** Show the number: `edu-greetings-chart`'s `values-prod.yaml` renders **zero** Secrets,
because it names one instead of containing one. Tie forward to the open lab's governance rule —
they're about to touch their own real config.

### Slide 59 — Hvem kører egentlig `helm upgrade`? ⭐
**Content:** laptop → cluster (❌ no audit trail, creds on laptops) vs git → ArgoCD/Flux → cluster
(✅ the deploy button is a merge)
**Notes:** [`deck-notes/gitops-loop.md`](./deck-notes/gitops-loop.md). The question the Merkur demo
provokes: someone ran 266 upgrades — who? Not a person. Callback to slide 22: Helm renders and
stops caring; a GitOps controller reconciles continuously. **This is the honest boundary of what
today taught.**
**[VISUAL: the two loops — see deck-notes/gitops-loop.md]**

### Slide 60 — Merkur, for alvor
**Content:** Apps → Installed Apps → `merkur` · revision 266+ · one release, ~9 components
**Notes:** Run [`live-demo/README.md`](./live-demo/README.md) sections A–D. **Read-only.** Scan the
values for anything credential-shaped before projecting them — and if there is something, that's
the teaching moment for slide 58.

---

## Exercise 2b (slide 61) — 15 min

### Slide 61 — Pak og publicér dit chart
**Content:** `2-gateway-chart` TASK 7 — `helm lint` → `helm package` → `helm push` →
`helm install oci://…` → `helm show values`
**Notes:** Registry host and login on screen. If the registry isn't ready, the README's
local-`.tgz` + `helm repo index` path teaches the same thing with no credentials — say which one
you're doing before they start. **This is the compression valve:** if you're behind, demo it in 5
minutes instead and protect the open lab.

---

## 6. Dit eget system (slides 62–66) — 50 min

### Slide 62 — Section divider
**Content:** `8.` Dit eget system — åbent lab

### Slide 63 — Briefen
**Content:**
- Vælg **ét** system I er ansvarlige for — eller én ærlig skive af det
- Tier 0: udfyld [`CANVAS.md`](./3-your-own-system/CANVAS.md) (~20 min) — **alle**
- Tier 1: chart-skelet, én komponent templated
- Tier 2: få den til at køre
- Tier 3: resten → hjemmearbejde
- Skriv [`BLOCKERS.md`](./3-your-own-system/BLOCKERS.md) før I går

**Notes:** Say plainly that **nobody finishes, and that's the design.** The output is knowing what
stands in the way. Push hard on doing the canvas *before* any YAML — people who skip it spend 40
minutes fighting `helm create` scaffold and learn nothing about their system.

### Slide 64 — ⚠️ Hvad der IKKE må i en values-fil
**Content:**
- Ingen rigtige passwords, tokens, connection strings — brug `REPLACE_ME`
- Intet patron-/persondata, intet embargo-belagt materiale
- Redigér hostnames og credentials **ud** før I spørger en LLM
- `GOVERNANCE.md`

**Notes:** Do not skip this slide and do not rush it. They are about to copy real configuration,
and the natural move is pasting a production connection string into `values.yaml` or into a chat
window. Point at `existingSecret` as the pattern that makes doing it properly the easy path.

### Slide 65 — Hvor I kopierer fra
**Content:** [`edu-greetings-chart`](./edu-greetings-chart/README.md) has a worked example of every
pattern: env from ConfigMap, `existingSecret`, PVC, Ingress, probes, migration hook, subchart,
schema, test.
**Notes:** `cp -r edu-greetings-chart my-system-chart` and delete what doesn't apply is a faster
start than `helm create`, which in Helm 4 generates an HPA, an HTTPRoute and a ServiceAccount they
didn't ask for. Rule of thumb: delete anything you can't explain.

### Slide 66 — Fælles fund
**Content:** *Én ting du fandt ud af om dit eget system, som du ikke vidste i morges.*
**Notes:** Call this at ~40 minutes, 5 minutes, one sentence each. Highest-value part of the lab —
the systems differ but the surprises rhyme, and hearing "we don't know where that config comes
from" from three people reframes it from personal failure to organisational fact.

---

## Close (slides 67–68) — 10 min

### Slide 67 — Hvad I kan nu
**Content:**
- Skrive et chart der pakker jeres system og eksponerer de rigtige knapper
- Validere sine egne inputs og teste sig selv
- Køre samme chart som dev og prod, og rulle tilbage når det går galt
- Publicere det som et OCI-artefakt

**Notes:** Then the honest boundary: getting it deployed automatically from git, with secrets
handled properly, is the next problem — and a bigger one than it looks.

### Slide 68 — Hjemmearbejde og workshop #4
**Content:**
- [ ] `CANVAS.md` udfyldt for mindst ét system
- [ ] chart-skelet committed i **jeres eget** repo
- [ ] én komponent templated, `helm lint` clean
- [ ] `BLOCKERS.md` udfyldt

> Workshop #4's emne bestemmes af hvad der står i jeres `BLOCKERS.md`.

**Notes:** Mean it. Collect the blockers — however you like, but collect them. Committing to a topic
here would waste the best input you're going to get, and saying that out loud is a better close
than a promise.

---

## X. Extras (slides 69–74)

Not presented. For questions, and for people who read the deck afterwards.

### Slide 69 — Library charts
**Content:** `type: library` — shared named templates, no manifests of its own. For an org with
many similar charts.

### Slide 70 — `lookup`
**Content:** read live cluster state during render. The password-generation pattern
(`randAlphaNum` + `lookup` so it isn't regenerated on every upgrade) and why it's fragile —
`helm template` has no cluster, so `lookup` returns empty.

### Slide 71 — Post-renderers
**Content:** pipe rendered manifests through `kustomize` or any binary before apply. The escape
hatch when a third-party chart doesn't expose the value you need.

### Slide 72 — Testing charts i CI
**Content:** `helm lint` · `helm template | kubeconform` · `helm-unittest` · `ct` (chart-testing) ·
Renovate for bumping chart and image versions.

### Slide 73 — `helm.sh/resource-policy: keep`
**Content:** the annotation that keeps a resource on `helm uninstall`. Usually wanted on a
database PVC; deliberately left off `edu-greetings-chart` so the workshop cleans up after itself.

### Slide 74 — Gateway API
**Content:** Helm 4's `helm create` now scaffolds an `HTTPRoute` alongside `Ingress` — Gateway API
is the successor to Ingress. Worth knowing it exists; Traefik on Rancher Desktop still does Ingress.
