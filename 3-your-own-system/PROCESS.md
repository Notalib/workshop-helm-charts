# Where this lab fits in the real process

This module isn't a hypothetical. KB is moving existing systems onto the new Kubernetes platform over
the next three years, and there's an agreed process for it. **This lab is step 1 of that process,
done on your own system.**

Full version (Danish, with the Teknologirådet criteria in detail): see the migration-process page in
Confluence. Short version below.

---

## Two questions, in this order

| | Question | Answer |
|---|---|---|
| **Udvælgelse** | *Can this system be moved at all?* | yes / no / not yet |
| **Prioritering** | *In what order do we move the candidates?* | which one is next |

They're deliberately separate. A system can be perfectly possible to move and still be the wrong one
to start with — and a high-priority system can turn out to be legally or technically impossible.
[`CANVAS.md`](./CANVAS.md) starts with the *can we?* gate for exactly this reason: it's the cheapest
question and it's disqualifying.

**And there's a third answer nobody expects:** some systems shouldn't be migrated, they should be
**decommissioned**. A migration process without a "don't" outcome just moves technical debt from one
platform to another.

## The six steps, and who owns each

| # | Step | Owner | Output |
|---|---|---|---|
| 1 | Select a system, against the criteria | **Dev team** | nomination + a filled-in canvas |
| 2 | Containerise the components | **Dev team** | a Dockerfile per component, in a registry |
| 3 | `compose.yml` for local development | **Dev team** | the stack runs on a laptop |
| 4 | Set it up manually in Kubernetes *(recommended)* | **Dev team** | working manifests |
| 5 | Convert to a Helm chart | **Dev team + Platform team** | a linted, tested chart |
| 6 | GitOps deployment and CI/CD | **Platform team** | ArgoCD app + pipeline |
| — | Cloud-readiness cleanup | **Dev team**, parallel to 2–5 | see below |

### Why step 4, if the manifests get replaced by a chart anyway?

Because it separates two questions you'd otherwise debug simultaneously: *can this app run in
Kubernetes at all?* and *is my chart correct?* Two unknowns at once are much harder to isolate than
one. The working manifests are also exactly what you template the chart from — making running YAML
configurable beats writing a chart blind.

For your team's first system this is effectively mandatory. Once you have a chart to copy from, go
straight to step 5.

## You have already been trained for steps 2–5

| Step | Workshop |
|---|---|
| 2 Containerise | #1 Containerisation |
| 3 `compose.yml` | #1 Containerisation |
| 4 Manually in Kubernetes | #2 Kubernetes |
| 5 Helm chart | #3 — today |
| 6 GitOps + CI/CD | Platform team's half |

The workshop series *is* the Dev-team half of this pipeline. That's also why the hand-off sits at
step 5–6: the chart gets built jointly, and Platform takes over the deployment.

## The part that actually takes the time

Writing a Dockerfile for an existing app is a day or two. Getting config out of a properties file
baked into the artifact, logs onto stdout, sessions out of memory, and the app genuinely stateless —
that's **weeks to months**, and it's application development, not DevOps work.

So cloud-readiness is not a sub-step of containerising. It runs alongside, and it gets assessed at
selection time because it's the single biggest item in any estimate.

The factors that actually bite in Kubernetes, in rough order:

1. **Config** — from environment variables, not files baked into the image
2. **Logs** — stdout/stderr; logs written to disk vanish with the Pod
3. **Stateless processes** — no local disk state, no in-memory sessions, or you can't scale or roll
4. **Disposability** — fast startup, graceful SIGTERM, or every rollout drops requests
5. **Backing services** — reach dependencies by configured name, never a hardcoded host

Plus four things 12-factor predates (it's from 2011) that matter *more* than several of the twelve —
and which this workshop has already taught you: **health endpoints**, **readiness vs liveness**,
**resource requests and limits**, and **where secrets come from**
([`BEST-PRACTICES.md` §5](../BEST-PRACTICES.md#5-secrets)).

## A reference that has been all the way through

`Notalib/BookCoverService` has completed every step: four containerised components, a `compose.yml`
for local dev, a chart at v1.11.12 with 21 templates, CI bumping the chart version — and values files
for **four** environments including `values_kind.yaml` for a local kind cluster. Same chart in
production, on beta, on ngt, and on a laptop.

Its cloud-readiness work is the concrete version of the list above: OAuth2 authority, client ID and
required groups turned into values, every hardcoded sub-system URL and domain removed, Ingress
hostnames fully configurable. That's what made one chart serve four very different environments.

---

**So: the canvas you're filling in is not busywork.** It's the real first step, and the blockers you
write down decide what the next workshop covers.
