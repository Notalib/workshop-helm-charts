# Chart anatomy

What's in the box. The single most useful slide for people who've never opened a chart.

## Suggested visual (ASCII sketch to redraw as a diagram)

```
  my-chart/
  │
  ├── Chart.yaml ............. metadata. name, version, appVersion, dependencies
  │                           ⇒ the label on the box
  │
  ├── values.yaml ............ DEFAULTS, and the chart's public API
  │                           ⇒ the knobs on the front
  │
  ├── values.schema.json ..... optional: validates values before install
  │                           ⇒ the knobs only turn to legal positions
  │
  ├── templates/
  │   ├── deployment.yaml .... the manifests you already write, with holes in them
  │   ├── service.yaml
  │   ├── ingress.yaml
  │   ├── _helpers.tpl ....... named templates. Leading _ = not a manifest
  │   ├── NOTES.txt .......... printed after install. ALSO a template
  │   └── tests/ ............. only run by `helm test`
  │
  ├── charts/ ................ subcharts (dependencies) live here
  │
  └── .helmignore ............ like .dockerignore, for `helm package`
```

## Talking points

- **Only `Chart.yaml` and `templates/` are mandatory.** Everything else is optional. A chart can
  be three files.
- **`values.yaml` is an API, not a config file.** Every key is a promise to whoever installs the
  chart. Renaming one is a breaking change for your users — which is why chart versions matter.
- **The `_` prefix in `_helpers.tpl` is meaningful**: files starting with `_` are never rendered as
  manifests. That's how Helm tells a definition from an object.
- **`NOTES.txt` is a template.** Emphasise this — the exercise deliberately ships a `NOTES.txt`
  that lies once you change the hostname via values, and fixing it is a task. A chart whose own
  instructions are wrong is worse than one with no instructions.
- **Two version numbers in `Chart.yaml`**, and they move independently:
  - `version` — the chart. Bump for any template or values change.
  - `appVersion` — the app inside. Tracks the image tag.
  Fixing a typo in a template bumps `version` only.
- **What is NOT in a chart:** no state, no credentials, no environment. A chart is a *package*;
  it's inert until installed. The environment-specific part lives in the values file you pass in.

## Tie-back

> "The box analogy: workshop #2 gave you loose bricks — a pile of manifests you applied in the
> right order by hand. This is the boxed set: same bricks, plus a parts list and an instruction
> booklet, and you can hand it to someone else."
