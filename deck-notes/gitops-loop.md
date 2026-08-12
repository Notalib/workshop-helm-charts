# Who actually runs `helm upgrade`?

The closing conceptual slide. It answers the question the Merkur demo provokes — *someone ran 266
upgrades, who?* — and it's the honest boundary of what this workshop taught.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  WHERE MOST TEAMS START                    WHERE THEY END UP
  ──────────────────────                    ─────────────────

  ┌──────────┐                              ┌──────────┐
  │ developer│                              │ developer│
  │  laptop  │                              │  laptop  │
  └────┬─────┘                              └────┬─────┘
       │ helm upgrade                            │ git push
       │ (from whose values?                     ▼
       │  with which flags?                 ┌──────────┐
       │  who else can?)                    │   git    │  ← values-prod.yaml
       ▼                                    │   repo   │    lives HERE
  ┌──────────┐                              └────┬─────┘
  │ cluster  │                                   │ merge to main
  └──────────┘                                   ▼
                                            ┌──────────┐
  ❌ no audit trail                          │ ArgoCD / │  ← watches the repo
  ❌ needs cluster creds on laptops          │  Flux /  │     runs helm
  ❌ "works on my machine" values            │   CI     │     continuously
  ❌ nobody knows what's deployed            └────┬─────┘        reconciles
                                                 │
                                                 ▼
                                            ┌──────────┐
                                            │ cluster  │
                                            └──────────┘

                                            ✅ git IS the audit trail
                                            ✅ no human needs cluster creds
                                            ✅ the deploy button is a MERGE
                                            ✅ drift is detected and corrected
```

## Talking points

- **Helm is a package manager, not a deployment pipeline.** Something has to decide *when* to
  upgrade, *with which values*, and *what to do if it fails*. Helm has no opinion. This is the
  honest limit of everything taught today.
- **The values file is the deliverable.** Once `values-prod.yaml` lives in git, "what is deployed
  to production?" has a reviewable answer, and changing production is a pull request. That's the
  whole idea — the chart made it possible, git makes it accountable.
- **Push vs pull:**
  - **CI push** — the pipeline holds cluster credentials and runs `helm upgrade`. Simple, and where
    most teams start. The credentials are the weak point.
  - **GitOps pull** — a controller *inside* the cluster watches the repo and applies it. No
    external system needs cluster credentials, and drift gets corrected continuously.
- **The thing Helm alone doesn't do: continuous reconciliation.** Recall the render-pipeline slide
  — Helm renders and submits, then stops caring. If someone `kubectl edit`s a Deployment, Helm
  won't notice until the next upgrade. ArgoCD notices in ~3 minutes and puts it back. That's the
  actual difference, and it's worth stating precisely rather than as a buzzword.
- **Secrets are the unsolved-looking part**, and the answer is: never in the values file.
  - **External Secrets Operator** — the chart references a Secret; the operator populates it from
    Vault / Azure Key Vault / AWS Secrets Manager. Usually the right answer.
  - **Sealed Secrets / SOPS** — encrypted values, safe to commit. Good when you want everything in
    git.
  - **`existingSecret`** — the chart takes a Secret *name* and never templates the credential at
    all. `edu-greetings-chart` does this, and `values-prod.yaml` renders zero Secrets as a result.
    Show that number; it lands.

## Where this leaves them

> "You can now write a chart that packages your system, exposes the right knobs, validates its own
> inputs, and can roll itself back. That's the artifact. Getting it deployed automatically, from
> git, with secrets handled properly — that's the next problem, and it's a bigger one than it
> looks."

Then hand over to the open lab: **the point of the last 50 minutes is finding out what stands
between your system and this diagram.** The blockers they write down are the input for what the
next workshop covers.

---

**Depth for prep / for anyone who asks:** [BEST-PRACTICES.md §5 (secrets) and §9 (operating a chart)](../BEST-PRACTICES.md#5-secrets)
