# Exercises for Helm Charts Workshop

Hands-on exercises for the Helm workshop — the third in the series, after
[Containerisation](https://github.com/notalib/workshop-containerisation) and
[Kubernetes](https://github.com/notalib/workshop-kubernetes).

Workshop #1 built *one container*. Workshop #2 got containers **running, scaled and reachable** on
a cluster — ending with a whole system wired together by hand, four YAML files at a time. This one
is about **packaging that system**: one versioned, installable, configurable artifact instead of a
directory of manifests you apply in the right order and hope you remember.

Workshop #2 closed with a promise, and this repo keeps it:

> *"Remember the four files you wrote in module 5? Next workshop we'll turn that system into a
> chart — templated, versioned, installable in dev/staging/prod with one command and a values file
> per environment."*

That chart is [`edu-greetings-chart/`](./edu-greetings-chart/README.md).

## Repo layout

- [deck-outline.md](./deck-outline.md) — the theory, slide by slide. `Helm_workshop.pptx` is built
  from it.
- [setup/](./setup/README.md) — **do this first.** Ten minutes, before the workshop starts.
- [cli-demo/](./cli-demo/README.md) — the opening live demo: a whole system in one command.
- `<num>-<name>/` — exercise modules for **you**, in order. Each has a `README.md` with `TASK`
  blocks and charts with `TODO`s to fill in.
- `edu-<name>/` — finished examples to read and run, not exercises.
- [live-demo/](./live-demo/README.md) — facilitator cheat-sheet for the real cluster.
- [deck-notes/](./deck-notes/) — supporting notes and diagrams for the presentation.

## Prerequisites

🤓 Skip these if you already have a working local Kubernetes and Helm 4. Just check
[setup](./setup/README.md) **section 2** — the one about which cluster you're pointed at.

- The same local cluster as workshop #2 — **Rancher Desktop** recommended. It ships a container
  runtime, `kubectl`, **`helm`**, a Traefik ingress controller and a `local-path` storage class.
- `~/.rd/bin` on your `PATH`.
- `kubectl get nodes` shows one `Ready` node (your machine).

### CLI tools

⚠️ Make sure these work in your terminal ⚠️

- `kubectl` (included with Rancher Desktop)
- **`helm` — v4.x** (included with Rancher Desktop). Check with `helm version`.
- Optional: [`helm diff`](https://github.com/databus23/helm-diff) plugin —
  `helm plugin install https://github.com/databus23/helm-diff`
- Optional: [k9s](https://k9scli.io/topics/install/). Still priceless.

> ### ⚠️ Helm 4, not Helm 3
>
> Rancher Desktop now ships **Helm 4**, and most Helm material online is Helm 3. A few things were
> renamed — the one you'll hit is **`--atomic`, which is now `--rollback-on-failure`** (the old flag
> still works but warns). `--dry-run` also takes `client`/`server` now instead of being a boolean.
>
> When a blog post and this repo disagree, `helm <command> --help` settles it. That habit is worth
> more than memorising either.

### Shell completion

```bash
source <(helm completion bash)   # or zsh
```

### IDE support

⚠️ Strongly recommended — Go templates inside YAML are unpleasant without help ⚠️

**VS Code**
- Kubernetes by Microsoft
  [link](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- **Helm Intellisense** by Tim Koehler
  [link](https://marketplace.visualstudio.com/items?itemName=Tim-Koehler.helm-intellisense) —
  autocompletes `.Values.` from your `values.yaml`. The one that actually helps.
- YAML by Red Hat [link](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

**IntelliJ IDEA**
- Kubernetes by JetBrains [link](https://plugins.jetbrains.com/plugin/10485-kubernetes)

> Turn on whitespace rendering. You'll thank yourself in module 2.

## Docs

Keep these open while you work:

- Using Helm: <https://helm.sh/docs/intro/using_helm/>
- **Chart template guide** — the one you'll actually use:
  <https://helm.sh/docs/chart_template_guide/>
- Debugging templates: <https://helm.sh/docs/chart_template_guide/debugging/>
- Function list: <https://helm.sh/docs/chart_template_guide/function_list/>
- Best practices: <https://helm.sh/docs/chart_best_practices/>
- An LLM makes a strong Helm tutor — but redact hostnames and credentials before pasting anything
  real. See `GOVERNANCE.md`.

## Modules

Work through them in order — each builds on the last.

### [1 — The simplest possible chart](./1-simplest-chart/README.md)
One Deployment, one ConfigMap, three values, no templating. Teaches the **release model**: what
`helm install` does, `helm template` vs `helm get manifest`, revisions and rollback, where a release
actually lives, and why two releases of a chart with hardcoded names collide.

### [2 — The gateway chart](./2-gateway-chart/README.md)
The main exercise. Nine hardcoded values across three files that should have come from
`values.yaml` — find them and template them. Then run the same chart as dev and as prod, break it
with `values-broken.yml`, watch `--rollback-on-failure` undo it, and package and publish the result.

### [3 — Your own system](./3-your-own-system/README.md) (open lab)
The last 50 minutes, and the homework. Pick a system you're responsible for and start moving it —
or one honest slice of it — toward Kubernetes. Fill in the [canvas](./3-your-own-system/CANVAS.md),
get a chart skeleton up, and write down [what stopped you](./3-your-own-system/BLOCKERS.md).

### [edu — The greetings chart](./edu-greetings-chart/README.md)
Not an exercise — the finished article. Workshop #2 module 5's Spring Boot + Postgres system as one
chart, with a worked example of every pattern you'll need: a Postgres **subchart**, a migration
**hook Job**, `checksum/config`, `values.schema.json`, `helm test`, and an `existingSecret` escape
hatch so no credential is ever templated. **Copy from this during module 3.**

## How the exercises work

Same shape as the previous two workshops: feel the problem, then fix it.

1. **Module 1 shows you the release model with a chart that has almost no templating** — so the
   collision you hit at the end is unmistakable.
2. **Module 2 makes you do the templating** that fixes it, on a chart with real `TODO`s.
3. **Module 3 is your own system**, with module 2's techniques and `edu-greetings-chart` as the
   reference.

The whole authoring loop is offline: `helm template` and `helm lint` need no cluster. Use them
constantly.

### Solutions

If you're stuck or want to compare, completed charts are on the
[`solutions`](https://github.com/notalib/workshop-helm-chart/tree/solutions) branch:

```bash
git checkout -t origin/solutions
```

## Essential helm

```bash
# Install & upgrade
helm install <release> <chart> [-n <ns>] [--create-namespace]
helm upgrade <release> <chart> -f values-prod.yaml --set key=value
helm upgrade --install <release> <chart>          # idempotent; what CI runs
helm uninstall <release>

# Render WITHOUT a cluster — your main feedback loop
helm template <chart> [-f values.yaml] [--set k=v] [--debug]
helm lint <chart>
helm install x <chart> --dry-run=client --debug

# Inspect a release
helm list [-A]                    # -A = all namespaces
helm get values <release> [--all] # --all merges in chart defaults
helm get manifest <release>       # the YAML the cluster actually received
helm get notes <release>
helm get hooks <release>          # hooks don't appear in `get manifest`

# Revisions
helm history <release>
helm rollback <release> [revision]              # omit revision = previous
helm upgrade ... --rollback-on-failure --timeout 60s   # was --atomic in Helm 3

# Meeting a chart you didn't write
helm show values <chart>          # every knob it exposes
helm show readme <chart>

# Dependencies, packaging, distribution
helm dependency update <chart>
helm package <chart>
helm registry login <host> && helm push <chart>.tgz oci://<host>/<project>
helm repo add <name> <url> && helm search repo <name> --versions
helm test <release>
```

## How to get unstuck

Before reaching for the solutions branch, these resolve nearly everything:

- **`helm template ./ --debug`** — renders even when it's broken, and shows the error in context.
  Your first stop for any template problem, and no cluster needed.
- **`helm get values <release>`** — "but I set that value!" No, you didn't. This proves it. Usually
  a list that got replaced wholesale, or a `--set` you didn't repeat.
- **`helm get manifest <release>`** — what the cluster actually received. Ends all arguments about
  what Helm "did".
- **`kubectl describe` + `kubectl logs`** — once a manifest reaches the cluster, it's just
  Kubernetes again, and workshop #2's tools apply unchanged. A Pod at `0/1 Running` is a failing
  probe, not a Helm problem.
- **`nil pointer evaluating interface {}`** — you referenced a value that isn't in `values.yaml`.
  Add it, or `{{ .Values.thing | default "x" }}`.
- **`helm <command> --help`** — especially for flags. Helm 4 renamed some.

## Best practices

- **`values.yaml` is an API, not a config file.** Every key is a promise to whoever installs your
  chart. Renaming one is a breaking change — which is what the chart version is for.
- **Derive object names from the release name** (`_helpers.tpl`), so two releases can coexist.
- **Never put a changing value in a selector.** Deployment selectors are immutable; a version label
  in there makes your chart permanently un-upgradeable.
- **Not everything should be configurable.** A knob that can only break things is a lie — see why
  `charts/postgres` has no `replicaCount`.
- **Credentials never go in a values file.** Take a Secret *name* (`existingSecret`) and let
  External Secrets / SOPS / sealed-secrets put the value there.
- **`required` and `values.schema.json`** — fail at install, not at 3am.
- **Pin your dependencies**, chart versions and image tags alike. Same rule as workshop #1.
- **Bump `version` on every chart change.** A chart version must mean exactly one thing forever.
- **`helm lint` in CI**, and `helm diff` before you upgrade anything you care about.

## Bonus

1. **Install something real.** `helm repo add` a public repo and install it — read its
   `values.yaml` first. Reading other people's charts is how you learn to write them.
   Start at <https://github.com/cdwv/awesome-helm#repositories--hubs>.
2. **Chart your own workshop #1 image.** You built and published images in #1; write the smallest
   chart that deploys one, with an Ingress.
3. **Turn `edu-greetings-chart`'s Postgres into a StatefulSet** with a `volumeClaimTemplate`. Why is
   that more correct for a database?
4. **Add a third environment.** Write a `values-staging.yaml`. How little did you have to write?
   That number is the point of this whole workshop.
5. **Put `helm lint` and `helm template | kubeconform` in a GitHub Action** for your own chart.
