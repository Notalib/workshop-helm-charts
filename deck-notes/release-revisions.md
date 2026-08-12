# Releases and revisions — git for your deployment

The payoff slide. This is what `kubectl apply` genuinely cannot give you.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  CHART (the package)              RELEASES (installations of it)
  ┌──────────────┐
  │  greetings   │  ──install──►   "dev"  in namespace dev    (1 replica)
  │   v1.0.0     │  ──install──►   "prod" in namespace prod   (3 replicas)
  └──────────────┘                 one chart, many releases


  ONE RELEASE OVER TIME  ("prod")

  rev 1        rev 2        rev 3        rev 4        rev 5
  install      upgrade      upgrade      upgrade      rollback→3
  v1.0.0       v1.0.1       v1.1.0       v1.2.0       v1.1.0
  ✅           ✅           ✅           ❌ FAILED    ✅
  │            │            │            │            │
  └────────────┴────────────┴────────────┴────────────┘
   superseded   superseded   superseded    failed      deployed
                     ▲                                   │
                     └───────────────────────────────────┘
                        rollback = a NEW revision whose
                        content equals an old one
                        (append-only, like git)
```

## Talking points

- **Chart ≠ release.** The chart is the package; a release is one installation of it, under a name
  you choose. Same chart installed twice = two independent releases. This trips everyone up once.
- **Every operation is a numbered revision** — install, upgrade *and* rollback. `helm history`
  shows the lot, with the values used.
- **Rollback doesn't rewind history, it appends to it.** Revision 5 above is "the content of
  revision 3, deployed now." Nothing is deleted. Exactly like `git revert`, not `git reset`.
- **The history lives in the cluster**, as one Secret per revision in the release's namespace:
  ```bash
  kubectl get secret -l owner=helm
  ```
  So a colleague with cluster access sees the same history you do. And deleting the namespace
  deletes the history.
- **`helm get values <rel> --revision N`** — the values a past revision ran with. Genuinely useful
  during an incident: *what changed?*

## The `--rollback-on-failure` slide

```
  helm upgrade ... --rollback-on-failure --timeout 60s

     apply new revision
            │
            ▼
     wait for healthy  ──── healthy? ────► ✅ done
            │
        not healthy within --timeout
            │
            ▼
     roll back to last good revision automatically
            │
            ▼
     ❌ command exits non-zero, nothing left half-deployed
```

- **Say the rename out loud:** this was **`--atomic`** in Helm 3. The old flag still works but
  prints a deprecation warning, and *every* blog post and Stack Overflow answer they find will use
  it. Rancher Desktop now ships Helm 4, so this is not academic.
- Setting it **implies `--wait`** — which is what makes a failure detectable at all. Without
  waiting, Helm submits the manifests, sees no error, and reports success while the Pod
  `ImagePullBackOff`s.
- **It only rolls *back*.** A failed *first* install has no previous revision, so Helm
  **uninstalls** instead. Worth stating — the error message otherwise looks alarming.
- **What it does NOT undo: your database.** If a migration hook ran and altered a schema, rolling
  back the release does not roll back the data. This is the honest limit, and it's the hardest real
  problem with schema migrations. Helm does not solve it.

## Tie-back

> "Merkur is on revision 266+. Every one of those is a state you could return to. That's the
> difference between a deployment and a pile of YAML someone applied on a Tuesday."

---

**Depth for prep / for anyone who asks:** [BEST-PRACTICES.md §9 (operating a chart)](../BEST-PRACTICES.md#9-operating-a-chart)
