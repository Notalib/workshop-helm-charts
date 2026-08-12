# System canvas

Fill this in for **one** system before writing any YAML. Copy it to your own repo — don't commit
your answers here.

Every question maps to something a Helm chart has to express. A question you can't answer is a
blocker, not a failure — note it in [`BLOCKERS.md`](./BLOCKERS.md) and move on.

**Target: ~20 minutes.** Don't polish. Rough answers to all of it beat perfect answers to a third
of it.

---

## The system

| | |
|---|---|
| **Name** | |
| **What it does** (one line) | |
| **Who owns it** | |
| **Why move it to Kubernetes?** (be honest — "everything else is moving" is a valid answer) | |
| **What would break if it were down for an hour?** | |

> **The slice I'm actually attempting today:**
>
> _(one component, not the whole system)_

---

## Components

One row per process that runs. A "component" is anything you would start separately — a web app, a
worker, a database, a cache, a scheduled job.

**Worked example** (the greetings app from `edu-greetings-chart`, so you can see the expected level
of detail):

| Component | Image exists? | Port(s) | Stateless? | Replicas | Notes |
|---|---|---|---|---|---|
| `backend` | ✅ `ghcr.io/notalib/…/edu-spring-boot:1.2` | 8080 (HTTP) | ✅ yes | 1–3 | Spring Boot; `/healthz` + `/readyz` |
| `database` | ✅ `postgres:18.3-alpine3.23` | 5432 | ❌ no | 1 only | needs a volume; can't scale |

Now yours:

| Component | Image exists? | Port(s) | Stateless? | Replicas | Notes |
|---|---|---|---|---|---|
| | | | | | |
| | | | | | |
| | | | | | |

**"Image exists?" is the most important column on this page.** Options:
- ✅ **in a registry the cluster can pull from** → you can reach Tier 2 today
- ⚠️ **builds locally but isn't pushed anywhere** → needs a registry + CI. Homework.
- ❌ **not containerised at all** → that's workshop #1's job, and it's the real blocker. Homework.

---

## Configuration

Everything the app reads at startup that differs between environments. Env vars, config files,
command-line flags, registry keys.

| Setting | Where it lives today | Differs per environment? | → Chart destination |
|---|---|---|---|
| _e.g._ `POSTGRES_HOST` | `application.properties` | yes | ConfigMap, from a value |
| | | | |
| | | | |

> **Chart destination** is one of: a **value** (varies per environment), a **ConfigMap**
> (non-secret config the app reads), a **Secret** (credentials), or **baked into the image**
> (never changes). If you can't decide, it's a value.

---

## Secrets

⚠️ **Names and locations only. No values.** See the warning in the [README](./README.md).

| What | Where it comes from today | Who can issue a new one |
|---|---|---|
| _e.g._ DB password | a `.properties` file on the server | DBA team |
| | | |

- [ ] Could this system get its secrets from an existing Secret in the cluster (`existingSecret`)
      rather than from a values file? _(If no — why not? That's a blocker.)_

---

## Storage

| What's stored | Where today | Size | Survives a restart? | Shared between replicas? |
|---|---|---|---|---|
| _e.g._ uploaded scans | local disk `/var/data` | ~40 GB | must | must be shared → needs `ReadWriteMany` |
| | | | | |

> **The hard question:** does anything need to be written to a filesystem that **more than one Pod
> reads at the same time**? `ReadWriteOnce` (one node) is easy; `ReadWriteMany` needs a storage
> backend that supports it and is the most common reason a lift-and-shift stalls. Flag it now.

---

## Network & dependencies

| | |
|---|---|
| **Hostname(s) it's reached on today** | |
| **Does it need to be reachable from outside the cluster?** | |
| **TLS — who issues the certificate today?** | |
| **What does it call out to?** (other services, DBs, SMB shares, external APIs, licence servers) | |
| **Does anything call *in* to it on a fixed IP or hostname?** | |
| **Any firewall rules tied to a specific source IP?** | |

---

## Lifecycle

| | |
|---|---|
| **How is it deployed today?** (installer, script, manual copy, CI pipeline) | |
| **Database migrations — who runs them, and when?** | |
| **Scheduled jobs / cron** | |
| **Startup order dependencies** ("X must be up before Y") | |
| **How do you know it's healthy?** (a URL? a log line? someone complains?) | |

> The last row becomes your **readiness probe**, and it's worth real thought — it's what makes
> zero-downtime rollouts possible. No health endpoint is itself a finding worth writing down.

---

## Verdict

Be realistic. This is the useful output of the exercise.

- **Tier I can reach today:** ☐ 0 (canvas only) ☐ 1 (skeleton) ☐ 2 (running) ☐ 3 (multi-component)
- **The single biggest thing in my way:**

  _______________________________________________

- **The smallest next step that would unblock it:**

  _______________________________________________

- **Can I do that alone?** ☐ yes ☐ no — needs: _______________________________

→ Now fill in [`BLOCKERS.md`](./BLOCKERS.md).
