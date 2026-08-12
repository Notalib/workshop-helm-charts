# Live cluster demo — Merkur as a Helm release (facilitator cheat-sheet)

Talking points for showing the **real Merkur application** on the beta cluster
(<https://rancher.beta.dbb.dk>, cluster `local` / Nota-BETA), driven from the **Rancher UI**.

Workshop #2 used this cluster to show what a single-node laptop cluster can't: multiple nodes, real
DNS and TLS, Longhorn storage. This time there's one specific thing to show — **Merkur is a Helm
release, and it has been upgraded hundreds of times.**

That is the strongest argument in the whole workshop, because it isn't a demo app.

> **Setup:** in Rancher, set the namespace filter to **`merkur`**.
>
> ## ⚠️ Safety
>
> This section is **read-only**. Do not roll back, upgrade or uninstall a real release in front of
> the room — not even on beta. Scaling a Pod in workshop #2 was recoverable; a Helm rollback of a
> composite system is not the same class of action.
>
> Also: **check the namespace filter and the context before you type anything.** If you're
> demoing from a terminal rather than the UI, confirm with `kubectl config current-context` on
> screen — modelling that habit in front of the room is worth as much as the demo.

---

## A. Merkur is one release

**Apps → Installed Apps → `merkur`**

The whole system — `merkur-nota` (the public app, 3 replicas), `merkur-internal`, `merkur-dodp`,
`merkur-liveupdate`, `merkur-kibana`, an `importer`, two `redis` caches, with
Elasticsearch/Longhorn behind it — appears as **one application**, with a chart version and a
values set.

Point at the labels on `merkur-nota`: `app.kubernetes.io/managed-by: Helm`.

**Talking point:** *"Every Deployment, Service, Ingress and cache you can see here is one Helm
release. Not nine things someone applied in order — one package, with one version number."*

---

## B. The revision count

```bash
helm history merkur -n merkur
```

Or in the UI, the release's history view.

It was on **revision 266** at workshop #2. Check the live number before you present — it will be
higher, and *that* is the point.

**Talking point:** *"This system has been upgraded 270-odd times, and every one of those is a
revision you could roll back to. Compare that with the four files you applied by hand last
workshop — how would you roll those back? To what?"*

Then connect it to what they just did in module 2:

> *"You ran `helm history` on a chart you'd installed twice. Same command, same mechanism. The
> difference between your gateway chart and Merkur is scale, not concept."*

---

## C. Values, not edited YAML

Show the release's **values** in the UI (or `helm get values merkur -n merkur`).

**Talking point:** *"Nobody edited raw YAML to configure this. There's a chart, and there's a
values file per environment — exactly the dev/prod pair from module 2. This is the same pattern at
production scale."*

⚠️ Scan before projecting. If the values contain anything credential-shaped, don't show them —
describe them instead, and use it as the teaching moment: *"which is exactly why production
credentials belong in a Secret the chart references, not in a values file."* That's the
`existingSecret` pattern from `edu-greetings-chart`.

---

## D. What Helm does *not* do — the bridge to GitOps

The obvious question once they've seen revision 270: **who ran those 270 upgrades?**

Not a person on a laptop. Show whatever is true for Merkur today — the CI pipeline, or ArgoCD if
it's in play.

**Talking point:** *"Helm is a package manager, not a deployment pipeline. Something has to decide
when to run `helm upgrade`, with which values, after which tests. That something is CI or a GitOps
controller, and the deploy button is a merge to main. Helm is one component in that chain, and
it's the one you now know how to write."*

This is the natural hand-off into the closing section of the deck.

---

## E. Optional: the cluster things a laptop can't show

Only if there's time and they're curious. All read-only.

- **Cluster → Nodes** — `merkur-nota`'s 3 replicas on three different worker nodes.
- **Ingresses tab** — real hostnames (`merkur.beta.dbb.dk`) with real TLS, and the padlock in a
  browser. Contrast with `*.localhost` through Traefik.
- **Longhorn / PersistentVolumeClaims** — real distributed storage instead of `local-path`.
- **StatefulSets** — the stateful tier, which is the BONUS in `edu-greetings-chart`, for real.

---

## Suggested placement

| When | Show |
|---|---|
| End of the hook demo (`cli-demo` §8) | A + B — one release, 270 revisions. The "this is real" moment. |
| During Theory 3 (charts in operation) | C + D — values per environment, and who actually runs the upgrade. |
| Only if time allows | E |
