# Helm vs Kustomize

Somebody will ask. Answer it honestly in one slide rather than getting ambushed, and resist selling
Helm — the room will trust the rest of the material more.

Note that `kubectl` ships Kustomize built in (`kubectl apply -k`), so it's already on every machine
in the room.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  HELM — templating                     KUSTOMIZE — overlay patching
  ─────────────────                     ────────────────────────────

  deployment.yaml                       base/deployment.yaml
  ┌────────────────────────┐            ┌────────────────────────┐
  │ replicas: {{ .Values   │            │ replicas: 1            │  ← valid YAML
  │            .replicas }}│            │ image: app:1.0         │    on its own
  └────────────────────────┘            └────────────────────────┘
           +                                      +
  values-prod.yaml                      overlays/prod/patch.yaml
  ┌────────────────────────┐            ┌────────────────────────┐
  │ replicas: 3            │            │ replicas: 3            │
  └────────────────────────┘            └────────────────────────┘
           ▼                                      ▼
   fill in the blanks                     merge on top of the base

  ✅ one artifact, parameterised          ✅ every file is real YAML
  ✅ versioned, packaged, shippable       ✅ no template language to learn
  ✅ registry distribution                ✅ no {{ }} in your manifests
  ❌ YAML-with-{{}} isn't valid YAML      ❌ no packaging or versioning
  ❌ whitespace pain                      ❌ no distribution story
  ❌ a real language to learn             ❌ patches get hard to follow at depth
```

## Talking points

- **Different problems, not competitors.**
  - Helm answers *"how do I package a system and give it to someone else, versioned?"*
  - Kustomize answers *"how do I vary my own manifests per environment without a template
    language?"*
- **The honest split:**
  - Shipping software other teams install → **Helm**. There is no real alternative; a registry full
    of charts is the ecosystem.
  - Installing third-party software → **Helm**, because that's how it's distributed. You don't get
    a choice.
  - Your own app, your own clusters, few environments → **Kustomize is a legitimate and simpler
    answer.** Say this plainly. It's true, and pretending otherwise costs credibility.
- **They compose.** `helm template | kubectl apply -k`, or Kustomize's `helmCharts` field, or a
  Helm post-renderer. ArgoCD supports both natively. Nobody has to pick a side forever.
- **The real reason most teams end up on Helm:** everything you want to *install* is a chart. Once
  Helm is in the toolchain for Elasticsearch and ingress controllers, using it for your own apps is
  one fewer tool.
- **The real reason to dislike Helm:** `{{ }}` inside YAML means your manifests aren't valid YAML,
  your editor can't fully help you, and whitespace bugs are real. This is a genuine cost. Acknowledge
  it — they're about to feel it in module 2, and pre-naming it makes the frustration legible instead
  of demoralising.

## If asked about the others

- **Kustomize** — in `kubectl`. Overlay patching. Above.
- **jsonnet / cdk8s / Pulumi** — generate manifests from a real programming language. Powerful,
  much steeper, small communities by comparison.
- **Operators** — for software that needs ongoing *operational* logic (failover, backups,
  resharding), not just installation. Complementary: many operators are installed *by* a Helm chart.
- **Plain YAML in git** — genuinely fine for a handful of manifests. The moment you copy a
  directory to make "the prod one", you've outgrown it.
