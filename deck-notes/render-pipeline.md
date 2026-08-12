# The render pipeline — where Helm's job ends

The most important conceptual slide in the deck. If people leave believing Helm "runs" their app,
the workshop has failed.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
   YOUR LAPTOP                                    │  THE CLUSTER
                                                  │
   templates/          values.yaml                │
   ┌──────────┐        ┌──────────┐               │
   │ {{ }}    │   +    │ replicas │               │
   │ {{ }}    │        │ image:   │               │
   └────┬─────┘        └────┬─────┘               │
        │                   │                     │
        └─────────┬─────────┘                     │
                  ▼                               │
          ┌───────────────┐                       │
          │ Go templating │   ← helm template     │
          └───────┬───────┘     (no cluster       │
                  │              needed!)         │
                  ▼                               │
        ┌─────────────────────┐                   │
        │ plain K8s manifests │                   │
        └──────────┬──────────┘                   │
                   │                              │
                   │  HTTPS ──────────────────────┼──►  ┌──────────────┐
                   │                              │     │  API server  │
      ═══════════════════════════════════════     │     └──────┬───────┘
      ▲ HELM'S JOB ENDS HERE ▲                    │            │
                                                  │            ▼
                                                  │     ┌──────────────┐
                                                  │     │ controllers  │  ← reconcile
                                                  │     │  ReplicaSet  │     forever
                                                  │     │  Scheduler   │
                                                  │     └──────┬───────┘
                                                  │            ▼
                                                  │          Pods
                                                  │
                                                  │  + one Secret per revision
                                                  │    (the release ledger)
```

## Talking points

- **Helm is a template engine plus a release ledger.** That's all. Two jobs.
- **There is no Helm server.** Nothing is running. Helm 2 had one (Tiller) and it was a security
  problem; Helm 3 deleted it. If someone remembers Tiller, that's why it's gone.
- **`helm template` needs no cluster.** This is the practical takeaway — the whole authoring
  feedback loop is offline and instant. Demo it with the wifi metaphorically off.
- **The cluster receives ordinary objects.** `helm get manifest` proves it. Nothing in the
  Deployment says "Helm".
- **So everything you learned in workshop #2 still applies.** Self-healing, rollouts, probes,
  service discovery — unchanged. Helm doesn't add runtime behaviour; it adds *authoring* and
  *versioning*.
- **Corollary worth stating explicitly:** Helm does not watch anything. If someone
  `kubectl edit`s a Deployment that Helm installed, Helm neither knows nor cares — until the next
  `helm upgrade` overwrites it. *Continuous* reconciliation of your manifests against git is what
  ArgoCD/Flux add, and that's the GitOps slide later.

## Common misconception to name out loud

> "Helm deploys my app and keeps it running."

No — **Helm renders and submits; Kubernetes keeps it running.** A useful test question for the
room: *if I delete a Pod from a Helm release, what recreates it?* (The Deployment's ReplicaSet
controller. Helm isn't involved and isn't even aware.)

---

**Depth for prep / for anyone who asks:** [BEST-PRACTICES.md §9 (operating a chart)](../BEST-PRACTICES.md#9-operating-a-chart)
