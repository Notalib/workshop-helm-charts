# Visual production guide

Use this as the image-generation and PowerPoint build brief for the deck. The attached workshop #1
and #2 visuals are the style reference: white background, left-to-right reading order, restrained
colour, generous spacing and only the labels needed to understand the diagram from the back of the
room.

## Shared style

- **Canvas:** 16:9, pure white background, generous safe margins. No dark panels or decorative
  background texture.
- **Look:** clean flat or lightly dimensional technical illustration. Soft shadows are fine; avoid
  photorealism, glossy 3D and strong gradients.
- **Palette:** dark navy text; medium blue for tooling/input; green for healthy runtime/output;
  muted purple for control-plane or process concepts; light neutral grey for containers. Red only
  means failure or a blocked path.
- **Labels are required for technical objects.** An unfamiliar icon must not carry the meaning by
  itself. Give each major object or stage one short label that remains readable from the back of the
  room.
- **Label style:** Danish narrative, English technical nouns; one to three words, sentence case,
  dark navy, high contrast and consistently placed below or inside the object. Aim for four to six
  labels per diagram.
- **Generate stable labels with the image.** Use PowerPoint overlays only when wording must remain
  editable, animation reveals it later, or the image model misspells it. Never bake YAML, commands,
  filenames, version numbers or explanatory sentences into a generated image.
- **Composition:** one direction of travel, thick arrows, four to six major objects at most. Keep
  enough whitespace for the slide title and any PowerPoint overlays.
- **Logos:** add official Docker, Kubernetes, Helm, Vault and Git logos in PowerPoint rather than
  asking an image model to reproduce them.
- **Consistency:** use the same icon/object for a Pod, Secret, chart package and cluster everywhere.

## Asset workflow

- Browser downloads go directly to [`deck-assets/generated`](../deck-assets/generated) under the
  filename suggested by ChatGPT. Do not rely on `~/Downloads`.
- Keep the raw download until it has been reviewed. Promote an approved iteration to a stable name:
  `slide-<number>-<short-description>-v<number>.png`.
- Compare hashes before retaining two files. A default-name download and a stable-name asset with
  the same SHA-256 are exact duplicates, not separate iterations; remove the default-name copy
  after verifying the promoted asset.
- Do not ask the browser agent to determine the downloaded filename by clicking around the image
  viewer. It should click **Download once and stop**; file handling happens in the workspace.
- Never click **Share**. If a share link is created accidentally, delete it immediately from
  ChatGPT's Shared Links settings.

## Generate as images

These benefit from illustration and contain little enough text to remain legible.

| Slide | Image brief | Required short labels |
|---|---|---|
| 2 — Serien | Three-stage progression: container image brick → small stack of Kubernetes manifest pages → boxed Helm package containing a system. Familiar workshop-series continuity, not a detailed architecture diagram. | `Containerisation`, `Kubernetes`, `Helm` |
| 14 — Chart = byggesættet | Loose coloured bricks and instruction pages flowing into one neat boxed building set. The contents stay visibly the same; only the packaging changes. | `Manifest`, `Chart` |
| 22 — Hvor Helms arbejde slutter | Left half is a laptop/workbench combining values and templates into manifests. A strong boundary crosses the middle. Right half is a Kubernetes control plane continuously reconciling Pods. | `Values`, `Templates`, `Manifests`, `API server`, `Controllers`, `Pods`; add `HELM STOPPER HER` at the boundary in PowerPoint |
| 58 — Values & Secrets | A secure Vault feeds an operator/controller, which creates a Kubernetes Secret consumed by a Pod. Four objects, one-way arrows, no secret value shown anywhere. | `Vault`, `External Secrets Operator`, `Kubernetes Secret`, `Pod` |
| 59 — Hvem kører `helm upgrade`? | Side-by-side paths. Left: developer laptop directly pushes to a cluster. Right: developer commits to git, a controller pulls, then updates the cluster. Make the right path calmer and more accountable, not triumphalist. | `Laptop`, `Git`, `ArgoCD / Flux`, `Cluster`; keep comparison bullets in PowerPoint |

## Hybrid builds

Use a generated image only as the visual base when the composition benefits from illustration but
the teaching content must remain exact and editable. Add criteria, commands, labels that may change,
and animation-dependent text as native PowerPoint elements.

For slide 62a, keep the selection and prioritisation criteria as native text and preserve
`Eliminate → nedlæg` as a clearly visible side exit. The funnel can be illustrative; the criteria
are the teaching content and must remain editable.

## Build in native PowerPoint

These depend on exact text, code, alignment or progressive reveal. Generating them as raster images
would trade away clarity for decoration.

| Slide | Build direction |
|---|---|
| 6 — Modul 5 | Real editor screenshot or live files; circle the three matching values with PPT annotations. |
| 15 — Chart anatomy | Monospace directory tree with restrained file-type icons and three emphasis callouts. |
| 18 — Release ≠ chart | One chart branching to two editable namespace boundaries: `dev` and `prod`. Reveal chart, dev and prod in three builds. |
| 19 — Revisioner | Five-node horizontal timeline. Revision 4 is red/failed; rollback curves from revision 5 back to the content of revision 3 without reversing the timeline. |
| 21 — Values precedence | Precedence row across the top; maps-merge and lists-replace examples below. Use builds to avoid showing all three ideas at once. |
| 23 — Helm vs Kustomize | Two equal columns with real YAML snippets and no winner/loser visual hierarchy. |
| 32 — Fra manifest til template | Real two-column diff; highlight only changed lines. |
| 34 — Tre ting der skal passe | Three short source snippets converge on one helper/value. |
| 49 — Parent, child og `global` | Parent box containing a child chart; `global` spans both. Avoid a generic org-chart look. |
| 52 — Hook-fælden | Two timelines revealed sequentially: database absent at `pre-install`, present at `post-install`. |
| 62b — Processen | Two-lane ownership diagram with workshop labels and the cloud-readiness band. Animate by step. |

## Additional visual aids

Useful additions that do not justify generated artwork:

- **Slide 8 — Hvad Helm giver os:** four simple icons in one row: package, sliders, revision
  history, registry. This makes the four promises memorable and gives later slides a visual callback.
- **Slide 20 — Hvor bor et release?:** draw a namespace boundary containing three stacked Helm
  revision Secrets. Keep the command beside it.
- **Slide 40 — Rollout når config ændrer sig:** `ConfigMap change → new checksum → new Pod` as a
  three-step strip under the exact annotation.
- **Slide 48 — Dependencies & subcharts:** show the Postgres chart nested inside the parent package;
  fade it out when `postgres.enabled=false`.
- **Slide 51 — Hooks:** a thin release lifecycle with hook attachment points. Highlight only the two
  hooks used by the migration Job.
- **Slide 55 — Rollback-flowet:** use the decision flow already sketched in
  `release-revisions.md`; reveal healthy and timeout branches separately.
- **Slide 57 — Packaging & publishing:** chart folder → `.tgz` package → OCI registry → install.
  Reuse the registry/container visual language from workshop #1.

## Avoid

- Generated screenshots, terminal windows, YAML or directory trees.
- More than one full architecture diagram per conceptual beat.
- Unlabelled technical icons that require the presenter to explain what each object represents.
- Tiny explanatory captions or sentence-length annotations; put detail in speaker notes.
- Labels smaller than the surrounding slide body text, low-contrast labels or labels placed over
  visually busy objects.
- Repeating the Docker/Kubernetes recap visuals when a small callback icon is enough.
- Purple as the dominant colour. Use it only for process/control-plane emphasis.
