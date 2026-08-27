# Helm CLI demo

**~15 minutes appetizer**: the whole module-5 system, as one command.

Mirrors the CLI demos in workshops #1 and #2. Where #1 ran one container and #2 kept workloads
running on a cluster. This one shows the system **packaged** — installable, configurable,
versioned and reversible.

> **Prep before demo:**
> ```bash
> kubectl config use-context rancher-desktop      # ⚠️ not a real cluster
> helm dependency update ./edu-greetings-chart    # optional; Helm prefers the source subchart
> docker pull ghcr.io/notalib/workshop-containerisation/edu-spring-boot:1.2
> docker pull postgres:18.3-alpine3.23
> ```

---

# 0. Where we ended last time

Workshop #2's module 5 — four YAML files, ~180 lines, applied by hand in a
specific order, with things that must agree, e.g. `POSTGRES_HOST`.

Teaser we ended on:

> *"Do I really copy-paste and apply all this YAML for every app and every environment?"*

---

# 1. One command, an entire system installed & ready

```bash
helm install dev ./edu-greetings-chart --namespace dev --create-namespace
```

Let the rendered `NOTES.txt` sit on screen for a second — the chart tells you how to use it.

```bash
kubectl get all,pvc,configmap,secret -n dev
```

Backend, Postgres, two Services, an Ingress, a PVC, a ConfigMap, a Secret and a completed
migration Job. **One command.**

```bash
curl -H "Host: greetings.localhost" http://127.0.0.1/greetings
```

## Observations

- The four files they hand-applied are now one package with a name and a version.
- `helm install` created the namespace, the objects and the schema, in the right order.

---

# 2. It's still just Kubernetes

Kill the mystique early — this is the point people most often get wrong about Helm.

```bash
helm get manifest dev -n dev | head -40
```

That's plain YAML. The cluster received ordinary objects; it has no idea Helm exists.

```bash
helm template ./edu-greetings-chart | head -20     # same rendering, no cluster at all
```

## Observations

- Helm is a **template engine plus a release ledger**. Its job ends at the API server.
- There is **no Helm server**. It's a CLI and some Secrets in the namespace:
  ```bash
  kubectl get secret -n dev -l owner=helm
  ```

---

# 3. Configurable, not editable

```bash
helm show values ./edu-greetings-chart | head -30
```

Those are the knobs. Nobody edits raw YAML to change an environment — and here's the same chart,
as prod, running **side by side**:

```bash
helm install prod ./edu-greetings-chart -n prod --create-namespace -f edu-greetings-chart/values-prod.yaml
helm list -A
kubectl get deploy -n dev; kubectl get deploy -n prod    # 1 replica vs 3
```

Then show the diff that *is* the difference between environments:

```bash
diff edu-greetings-chart/values-dev.yaml edu-greetings-chart/values-prod.yaml
```

## Observations

- One artifact, many environments. The difference between dev and prod is a **reviewable file in git**, not a folder of divergent YAML.

---

# 4. Versioned releases

```bash
helm upgrade dev ./edu-greetings-chart -n dev --set replicaCount=3
helm history dev -n dev
```

Every change is a numbered revision, and Helm kept the old ones — including the values used.

```bash
helm get values dev -n dev --revision 1
```

## Observations

- *Git for your deployment.* The whole system's state is versioned.

---

# 6. Break it on purpose - rollback on failure

Before we upgrade, let's monitor Pod changes:

```bash
kubectl get pods -n dev -w      # new Pod stuck ImagePullBackOff, old Pods still serving
```

Now let's try upgrading to an image that doesn't exist:

```bash
helm upgrade dev ./edu-greetings-chart -n dev \
  --set image.tag=this-tag-does-not-exist \
  --rollback-on-failure --timeout 20s
```

It should fail — **and rollback by itself to a working state**:

```bash
helm history dev -n dev         # failure AND rollback are both recorded
curl -H "Host: greetings.localhost" http://127.0.0.1/greetings    # never stopped working
```

## Observations

- The bad version **never served traffic** — same protection as workshop #2's broken rollout, now, now wrapped in one flag.
- `--rollback-on-failure` was `--atomic` in Helm 3. Lots of blog posts will refer to the old name.
- It only rolls *back*. A failed **first** install has no previous revision, so Helm uninstalls
  instead.

---

# 7. Create a new chart

Quickly scaffold a new chart

```bash
helm create my-chart
```
- Warning: Contains stuff you won't need. Could be better to start from `edu-greetings-chart` or existing simple chart. Delete templating you don't need - keep it simple at first!

# Extras

## See the upgrade diff before you execute it

```bash
# Requires plugin helm-diff
helm plugin install --verify=false https://github.com/databus23/helm-diff

helm diff upgrade dev ./edu-greetings-chart -n dev -f edu-greetings-chart/values-prod.yaml
```

- This is `terraform plan` for Kubernetes, and it's the plugin most teams make mandatory.

---

## Make the release test itself

```bash
helm test dev -n dev
```

A Pod curls the API and greps for a seeded row. Exit code non-zero = failed release.

- This is what lets a pipeline promote a release without a human clicking around: deploy,
  `helm test`, roll back on failure.

---

## Install helm charts from Rancher UI

Rancher Desktop → **Cluster Dashboard** → **Apps → Installed Apps**.

`dev` and `prod` appear as **two managed applications** with chart version, values and revision
history — not a loose pile of Pods and Services. They can upgrade or uninstall from here too.

> **The real example:** our own **Merkur** on the beta cluster is the Helm release `merkur`, and
> it's on revision 266+. See [../live-demo](../live-demo/README.md) — a whole production system,
> versioned hundreds of times.

---

# Cleanup

```bash
helm uninstall dev -n dev
helm uninstall prod -n prod
kubectl delete namespace dev prod
```

One command per release removes everything it created — no hunting for orphans.

---

## Key takeaways

- A chart packages a whole system as **one versioned, installable artifact**.
- Values replace editing YAML — one chart, many environments, and the diff is reviewable.
- Releases are **revisions**: upgrade, inspect, roll back.
- A failed deploy can undo itself.
- Underneath it's the same Kubernetes objects you already know. Helm renders; Kubernetes reconciles.

> **Today you'll build this up from scratch** — module 1 for the release model, module 2 for
> templating and rollback, and then 50 minutes on **your own** system.
