# Helm CLI demo — the hook (facilitator)

**~15 minutes, run at the front of the room.** The appetiser: the whole module-5 system, as one
command.

This mirrors the CLI demos in workshops #1 and #2. Where #1 ran one container and #2 kept workloads
running on a cluster, this one shows the system **packaged** — installable, configurable,
versioned and reversible.

> **Prep before the room fills up:**
> ```bash
> kubectl config use-context rancher-desktop     # ⚠️ not a real cluster
> helm dependency update ./edu-greetings-chart    # optional; Helm prefers the source subchart
> docker pull ghcr.io/notalib/workshop-containerisation/edu-spring-boot:1.2
> docker pull postgres:18.3-alpine3.23
> ```
> Pre-pulling matters — a cold pull of the Spring image in front of 20 people is a long silence.
>
> **Tight on time?** Sections 1–3 and 6 carry the whole argument. Cut 5, 7 and 8 first.

---

# 0. The setup: what they did last time

Have workshop #2's module 5 open on screen — four YAML files, ~180 lines, applied by hand in a
specific order, with the "three things must agree" warning about `POSTGRES_HOST`.

Ask the question the teaser ended on:

> *"Do I really copy-paste all this YAML for every app and every environment?"*

---

# 1. One command, the whole system

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
- Everything after that — ReplicaSets, scheduling, self-healing, probes — is the Kubernetes they
  already know.
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

- One artifact, many environments. The difference between dev and prod is a **reviewable file in
  git**, not a folder of divergent YAML.
- Note what prod does *not* contain: a password. It names an existing Secret instead.
  ```bash
  helm template p ./edu-greetings-chart -f edu-greetings-chart/values-prod.yaml | grep -c "kind: Secret"
  # 0
  ```

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

# 5. See the change before you make it

```bash
helm diff upgrade dev ./edu-greetings-chart -n dev -f edu-greetings-chart/values-prod.yaml
```

## Observations

- This is `terraform plan` for Kubernetes, and it's the plugin most teams make mandatory.

*(Skip if the plugin isn't installed.)*

---

# 6. Break it on purpose — and watch it undo itself

The payoff. Deploy an image that doesn't exist:

```bash
helm upgrade dev ./edu-greetings-chart -n dev \
  --set image.tag=this-tag-does-not-exist \
  --rollback-on-failure --timeout 60s
```

While it waits, in a second terminal:

```bash
kubectl get pods -n dev -w      # new Pod stuck ImagePullBackOff, old Pods still serving
```

Then it fails — and rolls itself back:

```bash
helm history dev -n dev         # the failure AND the rollback are both recorded
curl -H "Host: greetings.localhost" http://127.0.0.1/greetings    # never stopped working
```

## Observations

- The bad version **never served traffic** — same protection as workshop #2's broken rollout, now
  wrapped in one flag.
- Failure left nothing half-deployed. Compare: a `kubectl apply` that fails halfway leaves you to
  work out what landed.
- `--rollback-on-failure` was `--atomic` in Helm 3. Say this out loud — every blog post they find
  will use the old name.
- It only rolls *back*. A failed **first** install has no previous revision, so Helm uninstalls
  instead.

---

# 7. A release that tests itself

```bash
helm test dev -n dev
```

A Pod curls the API and greps for a seeded row. Exit code non-zero = failed release.

## Observations

- This is what lets a pipeline promote a release without a human clicking around: deploy,
  `helm test`, roll back on failure.

---

# 8. In the Rancher UI

Rancher Desktop → **Cluster Dashboard** → **Apps → Installed Apps**.

`dev` and `prod` appear as **two managed applications** with chart version, values and revision
history — not a loose pile of Pods and Services. They can upgrade or uninstall from here too.

> **The real example:** our own **Merkur** on the beta cluster is the Helm release `merkur`, and
> it's on revision 266+. See [../live-demo](../live-demo/README.md) — a whole production system,
> versioned hundreds of times.

---

# 9. Cleanup

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
