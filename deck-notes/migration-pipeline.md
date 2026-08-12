# The migration pipeline, and who owns each step

The slide that turns the whole workshop series from "training" into "you have been trained for your
half of a real process." Lands best immediately before the open lab.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  ALLE SYSTEMER
       │
       ▼
  ┌─ 1. UDVÆLGELSE ──────┐        ┌─ 2. PRIORITERING ────┐
  │  "Kan vi?"           │───────►│  "Hvornår?"          │
  │  kompatibilitet      │  kand- │  kompleksitet        │
  │  licens / afregning  │  ida-  │  udgivelsesfrekvens  │
  │  hardware            │  ter   │  driftsbyrde         │
  │  TIME-placering      │        │  skalerbarhed        │
  └──────────┬───────────┘        │  sårbarhed           │
             │                    │  teamets egen        │
      ELIMINATE → NEDLÆG          └──────────┬───────────┘
      (containerisér ikke)                   │ næste system
                                             ▼

  ─────────────────────────────────────────────────────────────────────
   DEV-TEAM                                    │  PLATFORM-TEAM
  ─────────────────────────────────────────────────────────────────────

   ① Udvælg system                             │
        │                                      │
        ▼                                      │
   ② Containerisér komponenter    ← workshop #1│
        │                                      │
        ▼                                      │
   ③ compose.yml, lokal dev       ← workshop #1│
        │                                      │
        ▼                                      │
   ④ Manuelt i Kubernetes         ← workshop #2│
        │  (anbefalet: giver de manifests      │
        │   chartet templates ud fra)          │
        ▼                                      │
   ⑤ Helm chart  ◄══════ sammen ══════════════►│  ⑤ Helm chart
        │                    ▲                 │
        │              workshop #3             │
        │                                      ▼
        │                                      ⑥ GitOps + CI/CD
        │                                      │   ArgoCD, pipeline
        └──────────────────────────────────────┴──►  KØRER I DRIFT

  ═════════════════════════════════════════════════════════════════════
   ⚠  CLOUD-READINESS  ── løber parallelt med ②–⑤, og er hvor tiden går
      config · logs · stateless · disposability · backing services
      + health-endpoints, probes, resource limits, secrets
  ═════════════════════════════════════════════════════════════════════
```

## Talking points

- **Read the swimlane out loud once.** Dev owns 1–4, step 5 is joint, Platform owns 6. That's the
  agreed split, and the uncertainty everyone worries about — "who does what?" — is answered for
  everything up to go-live.
- **Then point at the workshop labels.** Steps 2–5 are workshops #1, #1, #2 and #3. Say plainly:
  *"you have already been trained for your half of this."* This is the moment the series pays off,
  and it's worth a pause.
- **Step 4 needs its justification stated**, or someone will correctly object that the manifests get
  thrown away. It separates "can this app run in Kubernetes?" from "is my chart right?" — two
  unknowns at once are much harder to isolate. And templating working YAML beats writing a chart
  blind. First system: do it. Fifth system: copy your previous chart.
- **The Eliminate arrow is the one to dwell on.** A migration process with no "don't migrate this"
  outcome is a machine for moving technical debt onto a newer platform. Some systems should be
  switched off instead, and that's a *success*, not a failure of the process.
- **The cloud-readiness band is drawn wide and underneath on purpose.** It is not step 2.5. For a
  legacy app the Dockerfile is a day; getting config out of the artifact, logs onto stdout and
  sessions out of memory is weeks to months of *application* work. Estimates that miss this are
  wrong by an order of magnitude, and that's the single most useful thing the room can take away.

## Tie-in to the lab, which comes next

> "The canvas you're about to fill in is step 1. Not a practice version of step 1 — step 1."

Then the honest bit: nobody finishes today, and that's the design. The output is knowing what stands
between your system and the right-hand side of this diagram.

## Tie-back to BookCoverService

If you show the pilot, this is where: **BookCoverService has been all the way through.** Four
components, `compose.yml`, a 21-template chart at v1.11.12, CI bumping versions — and values files
for four environments including `values_kind.yaml` for a local kind cluster. Same chart, production
through laptop.

⚠️ Show the chart's **structure** and `values_kind.yaml`, not `ci/helm-chart/values.yaml` — it has
two literal credentials in it until that's cleaned up.

---

**Depth for prep / for anyone who asks:** [BEST-PRACTICES.md §5 (secrets)](../BEST-PRACTICES.md#5-secrets),
and `3-your-own-system/PROCESS.md` for the English summary of the process.
