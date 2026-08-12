# 1 — The simplest possible chart

Your first chart. It is deliberately tiny: **one Deployment, one ConfigMap, three values.**
No `_helpers.tpl`, no Ingress, no subcharts. The point of this module is not templating — it's
the **release model**: what Helm actually does when you type `helm install`, and what it
remembers afterwards.

> **Chart** — a directory of templates + a `values.yaml` of defaults + a `Chart.yaml` of
> metadata. A chart is a *package*, and it is inert until you install it.
> **Release** — one *installation* of a chart, under a name you choose. The same chart can be
> installed many times, in many namespaces, as many releases.
> **Revision** — one version of a release. Every `install`, `upgrade` and `rollback` creates a
> new numbered revision, and Helm keeps the old ones.

You may recognise the HTML this chart serves — it's the same page you mounted from a ConfigMap
in [workshop #2, module 3](https://github.com/notalib/workshop-kubernetes/tree/main/3-config-and-env).
Same Kubernetes objects. The only new thing is the packaging.

We work in the `default` namespace unless a task says otherwise.

---

## TASK 1: Install it

```bash
helm install simple ./
helm list
```

`simple` is the **release name** — your choice, not the chart's. Read the output: that's
`templates/NOTES.txt`, rendered. Follow it and check the app:

```bash
kubectl port-forward deploy/simplest-nginx 8888:80
# open http://localhost:8888 — the default nginx welcome page
```

Now look at what Helm created, using plain `kubectl` — nothing here is Helm-specific:

```bash
kubectl get deploy,configmap -l app.kubernetes.io/instance=simple
```

---

## TASK 2: Change it without editing a file

The chart exposes three knobs. Turn them with `--set`:

```bash
helm upgrade simple ./ --set overrideHtml=true
kubectl port-forward deploy/simplest-nginx 8888:80
```

**What happened to the website?** Look at [`templates/deployment.yaml`](./templates/deployment.yaml)
and find the `{{ if .Values.overrideHtml }}` block — a whole `volumeMounts` + `volumes` section
appeared because one boolean flipped. That's the thing raw YAML can't do.

Now change the name in the page and the image underneath it:

```bash
helm upgrade simple ./ --set overrideHtml=true --set myName="$(whoami)"
helm upgrade simple ./ --set overrideHtml=true --set imageTag=alpine
```

> **Careful:** `--set` is not sticky in the way people expect. Each `helm upgrade` starts from
> the chart's defaults again, so dropping `--set overrideHtml=true` from the second command
> would have turned the HTML override back off. Real deployments use a **values file**
> (module 2), not a pile of `--set` flags.

---

## TASK 3: A chart is a renderer — the cluster never sees your chart

Render the chart **without a cluster at all**:

```bash
helm template ./ --set overrideHtml=true
```

That's it. That's the whole trick. Helm turned templates + values into plain Kubernetes
manifests, on your laptop. Now ask the cluster what it was actually given:

```bash
helm get manifest simple
```

Compare the two. **The cluster has no idea Helm exists** — it received ordinary Deployment and
ConfigMap objects, exactly as if you had run `kubectl apply`. Helm's job ends at the API server;
everything after that (ReplicaSets, scheduling, self-healing) is the same Kubernetes you already
know from workshop #2.

Useful while writing charts:

```bash
helm install debug ./ --dry-run=client --debug   # render + show computed values, install nothing
```

> **Helm 4 note:** `--dry-run` now takes a value — `client` (render locally) or `server` (ask the
> API server to validate too). Bare `--dry-run` still works and means `client`.

---

## TASK 4: Revisions — the part `kubectl apply` doesn't give you

```bash
helm history simple
```

Every command you ran above is a numbered revision. Go back to any of them:

```bash
helm rollback simple 1
helm history simple
```

**Look carefully at the history.** The rollback did *not* delete revisions 2–4 — it added a
*new* revision whose content equals revision 1. The history is append-only, like git. That's why
"roll back the deploy" stops being a scary manual operation.

```bash
kubectl port-forward deploy/simplest-nginx 8888:80   # back to the default nginx page
```

---

## TASK 5: Where does a release actually live?

Helm stores each revision **in the cluster**, as a Secret in the release's namespace:

```bash
kubectl get secret -l owner=helm
```

One Secret per revision, holding the rendered manifests and the values used. Two consequences
worth remembering:

- **There is no Helm server.** Helm is a CLI plus some Secrets. Nothing is running.
- **The release lives in the namespace, not on your laptop.** A colleague with cluster access
  runs `helm history` and sees exactly what you see. Delete the namespace and the release
  history goes with it.

---

## TASK 6: Two releases from one chart

```bash
helm install second ./ --set myName=Ada
helm list
```

**It fails.** Read the error. Then look at [`templates/deployment.yaml`](./templates/deployment.yaml)
line 4:

```yaml
metadata:
  name: simplest-nginx     # hardcoded!
```

Two releases both want to own a Deployment called `simplest-nginx`, and Kubernetes names are
unique per namespace. Prove that the namespace is the boundary:

```bash
kubectl create namespace demo
helm install second ./ --namespace demo --set myName=Ada
helm list --all-namespaces
```

Now it works — different namespace, no collision. But needing a fresh namespace per release is a
poor answer. **The real fix is to derive object names from the release name**, which is exactly
what `_helpers.tpl` does in [module 2](../2-gateway-chart/README.md). Keep this failure in mind
when you get there.

---

## TASK 7: Why does a ConfigMap change restart anything?

Edit the HTML in [`templates/configmap.yaml`](./templates/configmap.yaml), then:

```bash
helm upgrade simple ./ --set overrideHtml=true
kubectl port-forward deploy/simplest-nginx 8888:80
```

Your edit shows up. But **it shouldn't have** — you changed a ConfigMap, not the Deployment, and
in workshop #2 you learned that editing a ConfigMap does *not* restart Pods.

Find the reason in `templates/deployment.yaml`:

```yaml
      annotations:
        revision: {{ .Release.Revision | quote }}
```

Every upgrade writes a new revision number into the **Pod template**, which changes the Pod
template, which makes the Deployment roll out fresh Pods. A one-line trick that turns "config
changed" into "app restarted."

> This chart restarts on *every* upgrade, which is blunt but fine for a demo. Production charts
> annotate with a **checksum of the config** instead, so a rollout happens only when the config
> genuinely changed. You'll see that in [`edu-greetings-chart`](../edu-greetings-chart/README.md).

---

## Clean up

```bash
helm uninstall simple
helm uninstall second --namespace demo
kubectl delete namespace demo
```

Note that `helm uninstall` removes **all** the objects the release created — no hunting for
leftovers. That is the other half of the packaging payoff.

---

## Stuck?

- `helm list --all-namespaces` — where did my release go?
- `helm get values simple` — what values is this release actually running with?
  Add `--all` to see the chart defaults merged in too.
- `helm get manifest simple` — the exact YAML the cluster received.
- `helm template ./ --debug` — renders even when the YAML is broken, and prints the error with
  line context. Your first stop for any template problem.
- Pod not starting? It's still just Kubernetes: `kubectl describe deploy/simplest-nginx` and read
  the Events.
- Docs: <https://helm.sh/docs/intro/using_helm/>

## BONUS

1. Break the YAML on purpose — remove a space from the indentation in `templates/deployment.yaml`
   and run `helm template ./`. Read the error. Now do it inside the `{{ if }}` block instead. Which
   error message is more helpful, and why is that the argument for keeping templates boring?
2. `helm get values simple --revision 2` — the values of a *past* revision. What could you use
   this for during an incident?
3. `helm install simple ./ --set imageTag=this-tag-does-not-exist`. Does `helm install` fail, or
   does it succeed while the Pod fails? What does that tell you about where Helm's
   responsibility ends? (Then look up `--wait`, which changes the answer.)
4. **Un-delete a release.** `helm list --uninstalled` shows releases that were removed but whose
   history was kept — find the flag that does that in `helm uninstall --help`, use it, then
   `helm rollback simple`. (Getting into the habit of reading `--help` for the flag rather than
   copying it from a blog post is worth more than the trick itself — see the `--atomic` rename in
   [module 2](../2-gateway-chart/README.md).)
