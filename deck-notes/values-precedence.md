# Values precedence — who wins

A boring slide that prevents an hour of confusion. Worth its place because the failure mode is
silent: your value is simply ignored and you don't know why.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  LOWEST PRECEDENCE                                        HIGHEST
  ─────────────────────────────────────────────────────────────────►

  ┌──────────────┐  ┌───────────┐  ┌───────────┐  ┌──────┐  ┌────────────┐
  │  subchart    │  │  chart's  │  │  -f a.yml │  │--set │  │--set-string│
  │  values.yaml │  │ values.yaml│ │  -f b.yml │  │      │  │            │
  └──────────────┘  └───────────┘  └───────────┘  └──────┘  └────────────┘
                                    later -f wins
                                    over earlier -f


  MERGING IS PER-KEY, NOT PER-FILE
  ─────────────────────────────────

  values.yaml            -f prod.yml           result
  ───────────            ───────────           ──────
  replicaCount: 1        replicaCount: 3       replicaCount: 3   ← overridden
  image:                 ingress:              image:
    repo: foo              host: kb.dk           repo: foo       ← KEPT
    tag: "1.0"                                   tag: "1.0"      ← KEPT
  ingress:                                     ingress:
    host: localhost                              host: kb.dk     ← overridden
    tls: false                                   tls: false      ← KEPT


  ⚠️  EXCEPT LISTS — a list is REPLACED wholesale, never merged

  values.yaml              -f prod.yml          result
  ───────────              ───────────          ──────
  args: [--a, --b]         args: [--c]          args: [--c]      ← --a, --b GONE
```

## Talking points

- **A values file only needs the difference from the defaults.** This is why `values-prod.yaml` in
  the exercise is 20 lines and not 200 — and why improving a chart default reaches every
  environment at once.
- **Maps merge, lists replace.** Say this twice. It's the single most surprising behaviour in Helm
  and the cause of "why did my extra arg disappear?"
- **`--set` is not sticky.** Each `helm upgrade` re-derives values from the chart defaults plus
  what you pass *this time*. Dropping a `--set` from the next command silently reverts it. Values
  files exist so you don't have to remember.
- **`--set-string` forces a string.** `--set tag=1.30` becomes the number `1.30` — which YAML then
  renders as `1.3`, and your image tag is now wrong. Use `--set-string tag=1.30`. This bites people
  with version numbers and with `true`/`false` strings.
- **Reset semantics on upgrade** (Helm 4 spellings):
  - `--reuse-values` — keep the last release's values, merge in new overrides
  - `--reset-values` — throw them away, back to chart defaults
  - `--reset-then-reuse-values` — reset, re-apply the last release's values, then overrides
  If you don't pass any of these, be able to say what the default is — or just use a values file
  and stop thinking about it.

## The two commands that end all arguments

```bash
helm get values <release>          # what this release is actually running
helm get values <release> --all    # the same, merged with chart defaults
```

> If someone says "but I set that value" — run the first one. It's nearly always a list that got
> replaced, a `--set` that wasn't repeated, or a subchart key at the wrong nesting level.

## Subchart values

```
  parent values.yaml
  ┌────────────────────────┐
  │ replicaCount: 3        │ ── this chart's templates
  │                        │
  │ postgres:              │ ── passed DOWN to the postgres subchart
  │   persistence:         │    (the subchart sees it WITHOUT the
  │     size: 20Gi         │     `postgres:` prefix)
  │                        │
  │ global:                │ ── visible to parent AND every subchart
  │   database:            │    the only shared namespace
  │     name: example      │
  └────────────────────────┘
```

- A subchart **cannot** read its parent's values. It gets exactly what the parent hands down.
- `global:` is the one exception, and it's how two tiers agree on a shared fact — the database name
  in `edu-greetings-chart` is the worked example.
- Values files are **plain YAML, not templates**, so a parent cannot compute a value to pass down.
  That's why the shared Secret name in the reference chart is a *convention* derived from
  `.Release.Name` in both charts, rather than something passed. Worth showing — it's a real
  limitation people hit fast.

---

**Depth for prep / for anyone who asks:** [BEST-PRACTICES.md §2 (values.yaml is your API) and §8 (dependencies)](../BEST-PRACTICES.md#2-valuesyaml-is-your-api)
