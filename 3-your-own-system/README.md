# 3 — Your own system (open lab)

The last 50 minutes are yours. Pick a system **you** are responsible for and start moving it —
or one honest slice of it — toward running on Kubernetes.

This is not a tidy exercise with a solution branch. It's the actual work, and it's the homework
until the next workshop. Nobody finishes. That's expected and it's fine: **the goal is to find out
exactly what stands between your system and a cluster**, which is information you can only get by
trying.

---

## ⚠️ Before you start: what not to put in a values file

You are about to work with your real system's configuration, and the natural move is to copy your
real config into `values.yaml`. Don't.

- **No real passwords, tokens, API keys, connection strings or certificates** — not in
  `values.yaml`, not in a `-f` file, not in a `--set` flag in your shell history, not in a commit.
  Use an obvious placeholder like `REPLACE_ME` and write the real name down in
  [`BLOCKERS.md`](./BLOCKERS.md) instead.
- **Nothing patron-related or personal.** No GDPR-scoped data, no borrower records, no
  embargoed or rights-restricted material — not even as test data in a ConfigMap.
- **Don't paste real config into an LLM** while asking for help. Redact hostnames and credentials
  first. An LLM is a good Helm tutor; it's a bad place for your production connection string.

`edu-greetings-chart` shows the pattern that makes this easy: the chart takes
`database.existingSecret` and never templates the credential at all. Its `values-prod.yaml`
renders **zero** Secrets — check for yourself:

```bash
helm template x ../edu-greetings-chart -f ../edu-greetings-chart/values-prod.yaml | grep -c "kind: Secret"
```

Full policy: `GOVERNANCE.md`. If you're unsure which class some piece of data falls into, assume
the stricter one and ask.

---

## Pick something achievable

You are looking for **one component with an HTTP interface and no exotic dependencies**. Good
first candidates:

- a stateless API or web frontend
- a batch job or scheduled importer
- an internal tool nobody would miss for an hour

Bad first candidates (interesting later, painful today): anything needing a Windows host, a
licence dongle, a shared SMB mount, a fixed IP, or a database you're not allowed to copy.

> **You do not have to pick a whole system.** "The read-only API in front of our catalogue" is a
> better answer than "the catalogue platform."

---

## Tier 0 — Fill in the canvas (everyone does this)

Open [`CANVAS.md`](./CANVAS.md) and fill it in for your system. **Aim to finish this in about 20
minutes**, and do it before you write a single line of YAML.

This is not busywork. Every question on it maps to something a chart must express, and the ones
you can't answer are precisely your blockers. Most people discover their real obstacle here —
usually "there is no container image yet" or "nobody knows where that config comes from."

---

## Tier 1 — A chart skeleton (most people reach this)

Two ways to start. **Copying is the faster one:**

```bash
cp -r ../edu-greetings-chart ../my-system-chart
# then delete what you don't need and rename the helpers
```

Or scaffold a fresh one:

```bash
helm create my-system
```

> `helm create` in Helm 4 generates a *lot* — `hpa.yaml`, `httproute.yaml`,
> `serviceaccount.yaml`, a `tests/` dir. Delete everything you can't explain. A chart you
> understand at 40 lines beats a chart you inherited at 400. You can always add the HPA back when
> you actually need autoscaling.

Keep [`BEST-PRACTICES.md`](../BEST-PRACTICES.md) open while you do this — the "what to template"
and "values.yaml is your API" sections are exactly the decisions you're about to make, and the
pre-flight checklist at the bottom tells you when you're done.

Target for this tier:

- `Chart.yaml` with a real name, description and `appVersion`
- `values.yaml` whose keys match the components and knobs from your canvas
- **one** component templated: a Deployment and a Service
- `helm lint` passes and `helm template ./` renders

You do not need a cluster for any of that. `helm template` is the whole feedback loop.

---

## Tier 2 — Get it running (some people reach this)

Only realistic if a container image for your component **already exists in a registry your cluster
can pull from**. If it doesn't, that's homework #1 and it belongs in `BLOCKERS.md` — don't spend
the lab building an image.

```bash
helm install mine ./my-system-chart
kubectl get pods
kubectl logs deploy/<name>
```

Expect `ImagePullBackOff`, `CrashLoopBackOff` and a missing env var. That debugging *is* the
exercise — it's the same loop as workshop #2, and the same `kubectl describe` / `kubectl logs`
tools solve it.

---

## Tier 3 — The rest (homework)

Second component, ConfigMaps and Secrets wired up, persistent storage, an Ingress, probes,
resource requests, a `values-dev.yaml` / `values-prod.yaml` pair. Use
[`edu-greetings-chart`](../edu-greetings-chart/README.md) as the reference for each of these — it
has a worked example of every one.

---

## Before you leave: write down what stopped you

Fill in [`BLOCKERS.md`](./BLOCKERS.md). This is the single most useful thing you'll produce today.

Two reasons it matters. It's your own to-do list. And collectively, these blockers decide what the
**next workshop** is actually about — a syllabus built from ten real blockers beats one guessed in
advance.

### Homework — definition of done, before the next workshop

- [ ] `CANVAS.md` complete for at least one system
- [ ] a chart skeleton committed **in your own project's repo** (not this one)
- [ ] one component templated, `helm lint` clean
- [ ] `BLOCKERS.md` filled in, with the blockers you can't solve alone flagged

---

## Stuck?

The three commands that answer most questions, none of which need a cluster:

```bash
helm template ./my-system-chart --debug     # what does this actually render?
helm lint ./my-system-chart                 # is it structurally sane?
kubectl explain deployment.spec.template.spec.containers   # what fields exist?
```

- **"I don't know what this app needs to run"** — look at how it runs today. A `docker run`
  command, a Compose file, a systemd unit or an IIS config is a list of ports, env vars, mounts
  and dependencies. That list *is* your values file.
- **"It works locally but not in the cluster"** — it's almost always one of: image not pullable,
  a missing env var, a hostname that only resolves on your network, or a probe pointing at the
  wrong port. Workshop #2's module 5 "Stuck?" section covers all four.
- **Copy from the reference.** Every pattern you need — env from ConfigMap, secret via
  `existingSecret`, PVC, Ingress, probes, migration hook — has a worked example in
  `edu-greetings-chart`.
- Grab a facilitator. That's what the 50 minutes are for.
