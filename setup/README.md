# Setup — Helm on your local cluster

**Do this before the workshop starts.** It takes ten minutes and it's the difference between
spending the first exercise learning Helm or fighting your laptop.

You need the same working local Kubernetes you had in workshop #2. If you still have it, you're
almost done — Helm ships with Rancher Desktop.

---

## 1. A working local cluster

```bash
kubectl get nodes          # at least one Ready node
kubectl get storageclass   # local-path (default)
kubectl get ingressclass   # traefik
curl -s http://localhost   # "404 page not found" = Traefik has port 80
```

All four working? Skip to step 2.

If not, the full guide from workshop #2 still applies:
<https://github.com/notalib/workshop-kubernetes/tree/main/setup>. The short version:

- Install **Rancher Desktop**, enable Kubernetes under Preferences, leave **Traefik** on.
- Put `~/.rd/bin` on your `PATH`.
- Linux: let Rancher bind port 80 —
  `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80`, then `rdctl shutdown && rdctl start`.

---

## 2. ⚠️ Check which cluster you're pointed at

**Read this one even if you skipped step 1.** You will be running `helm uninstall` and
`helm rollback` today. Those are real, and `kubectl` is perfectly happy to aim them at a
production cluster if that's what your kubeconfig says.

```bash
kubectl config current-context
```

If that prints anything other than `rancher-desktop` (or your own local cluster), fix it now:

```bash
kubectl config use-context rancher-desktop
```

```bash
kubectl config get-contexts    # everything your kubeconfig can reach
```

> **If you have work clusters in your kubeconfig, put a guardrail in front of yourself.** A shell
> function that refuses to run destructive Helm commands outside a local context costs five
> minutes and eventually saves your afternoon. Ask a facilitator — there's a working example to
> copy, and it has earned its keep.

Everything in this workshop happens in the `default` namespace of your **local** cluster unless a
task says otherwise.

---

## 3. Helm

```bash
helm version
```

You want **v4.x**. Rancher Desktop ships it, so if `~/.rd/bin` is on your `PATH` you already have
it.

> **Helm 4 matters for this workshop.** Most Helm material online is Helm 3, and a few things were
> renamed. The big one: `--atomic` became `--rollback-on-failure`. The old flag still works but
> warns. When a blog post and this repo disagree, check `helm <command> --help` — that habit is
> worth more than memorising either.

If you have an older Helm from Homebrew shadowing Rancher's, either reorder your `PATH` or
`brew upgrade helm`.

### Shell completion

Worth 30 seconds:

```bash
source <(helm completion bash)    # or zsh
```

---

## 4. The `helm diff` plugin

Not built in, and the one plugin most teams treat as mandatory — it shows what an upgrade *would*
change before you run it.

```bash
helm plugin install https://github.com/databus23/helm-diff
helm plugin list
```

If plugin install is blocked on your machine, that's fine — it's used in one BONUS task only.

---

## 5. Chart registry (optional, facilitator will confirm)

Charts are OCI artifacts and live in a container registry alongside the images from workshop #1.
If a registry is available on the day, log in once:

```bash
helm registry login <registry-host>
```

Your facilitator will give you the host, project and credentials. Module 2 TASK 7 has a
**local-only fallback** that teaches the same thing with no registry at all, so don't worry if
this doesn't happen.

---

## 6. IDE support

Strongly recommended — Go templates inside YAML are unpleasant without help.

**VS Code**
- Kubernetes by Microsoft —
  [link](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- **Helm Intellisense** by Tim Koehler —
  [link](https://marketplace.visualstudio.com/items?itemName=Tim-Koehler.helm-intellisense)
  (autocompletes `.Values.` from your `values.yaml` — the one that actually helps)
- YAML by Red Hat — [link](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

**IntelliJ IDEA**
- Kubernetes by JetBrains — [link](https://plugins.jetbrains.com/plugin/10485-kubernetes)
  (includes Helm chart support)

> Set your editor to show whitespace. You will spend real time on YAML indentation today, and
> Go templates make it worse.

---

## 7. Get the repo

```bash
git clone https://github.com/notalib/workshop-helm-charts
cd workshop-helm-charts
```

---

## 8. Verify the whole toolchain

This renders both exercise charts **without touching your cluster**. If it prints OK twice,
you're ready:

```bash
helm lint ./1-simplest-chart && helm template ./1-simplest-chart > /dev/null && echo "OK 1"
helm lint ./2-gateway-chart  && helm template ./2-gateway-chart  > /dev/null && echo "OK 2"
```

And one live check that the cluster can actually run a release:

```bash
helm install smoke ./1-simplest-chart
kubectl get pods -l app.kubernetes.io/instance=smoke
helm uninstall smoke
```

---

## Docs to keep open

- Using Helm: <https://helm.sh/docs/intro/using_helm/>
- **Chart template guide** (the one you'll actually use): <https://helm.sh/docs/chart_template_guide/>
- Debugging templates: <https://helm.sh/docs/chart_template_guide/debugging/>
- Built-in functions: <https://helm.sh/docs/chart_template_guide/function_list/>
- Best practices: <https://helm.sh/docs/chart_best_practices/>
- An LLM makes a strong Helm tutor — but redact hostnames and credentials before you paste
  anything real. See `GOVERNANCE.md`.
