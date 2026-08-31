# 2 — The gateway chart: templating, environments, rollback

Module 1's chart had three values and hardcoded everything else.

This one is a realistic small chart:
— An **nginx gateway**
- A **http-echo backend** beside it in the same Pod
- A Service + Ingress
- All riddled with hardcoded values that *should* come from `values.yaml`.

Your job: Find them and template them. Then run the same chart as dev and as prod, break it, and
roll it back.

> **`values.yaml`** — the chart's *defaults*, and its API. Anything not in here is not
> configurable, and anything in here is a promise to whoever installs your chart.

> **`_helpers.tpl`** — named template definitions, available in every other template via
> `include`. This is where naming conventions live, so they're defined once.

> **`NOTES.txt`** — is itself a template. It is the only documentation most people will read.

```
  Request → Ingress (gateway.localhost) → Service → ┌─ Pod ──────────────────────┐
                                                    │ nginx  :80        /        │
                                                    │   └─ proxy_pass → :5678    │
                                                    │ http-echo :5678   /api     │
                                                    └────────────────────────────┘
```

> **Why one Pod with two containers?** Because they're genuinely coupled here — nginx proxies to
> the backend over `127.0.0.1`, no Service needed. That's the *sidecar* pattern. Contrast it with
> [`edu-greetings-chart`](../edu-greetings-chart/README.md), where backend and database scale
> independently and therefore get a Deployment and a Service each.

---

## TASK 1: Install it as-is

```bash
helm install gw ./
```

Follow the rendered `NOTES.txt`:

```bash
curl -i -H "Host: gateway.localhost" http://127.0.0.1/
curl -iL -H "Host: gateway.localhost" http://127.0.0.1/api
```

You should get "Gateway is up for gw" and "Hello from backend". If `curl` hangs or 404s, fix that
before templating anything — see **Stuck?** at the bottom.

> **Why `-L` on the second one?** The chart's nginx config deliberately redirects `/api` → `/api/`
> with a 308, so that both spellings work. Without `-L`, `curl` shows you the redirect instead of following it, and you'd conclude the backend is broken when it isn't.
---

## TASK 2: Find the hardcoding

```bash
helm template ./ | less
```

Read the rendered output next to `values.yaml` and find every place a value is *baked in* that
should have come from values. There are **nine**, each marked `# TODO:` across three files:

| File | What's wrong |
|---|---|
| `templates/deployment.yml` | replica count, both container images, both probe ports, backend port |
| `templates/configmap-nginx.yml` | the `/api` block is always present; the proxy target port |
| `templates/service.yml` | the Service port |

Don't fix them yet. First, predict: **which of these would break the app if someone changed the
matching value in `values.yaml`?** That is the actual bug class you're fixing.

---

## TASK 3: Template them

Fill in the nine `TODO`s. Useful syntax:

```
{{ .Values.replicaCount }}                    a value
{{ .Values.image.nginx }}                     a nested value
{{ .Values.backend.text | quote }}            pipe through a function
{{- if .Values.api.enabled }} ... {{- end }}  conditional block
{{ include "gateway.fullname" . }}            a named template from _helpers.tpl
```

Work in a fast loop — you do **not** need a cluster to check your work:

```bash
helm template ./                                  # does it render?
helm template ./ --set api.enabled=false          # does the conditional work?
helm template ./ --set service.port=8080 | grep -n 8080
```

### Definition of done

```bash
helm lint ./              # passes
helm template ./          # renders valid YAML
```

And each value actually controls what it claims to:

- [ ] `api.enabled` toggles the `/api` route to the backend container
- [ ] `service.port` controls the exposed port of the nginx proxy
- [ ] `backend.port` controls which port the backend exposes *and* which port nginx proxies to
- [ ] `backend.text` changes the backend's `/api` response
- [ ] `replicaCount` affects the number of Pods

Test the interesting one properly — change a port and confirm the app still works, which is the
whole point:

```bash
helm upgrade gw ./ --set service.port=8080 --set backend.port=9000
kubectl get pods -l app.kubernetes.io/instance=gw   # must reach 1/1 Ready, not 0/1
curl -iL -H "Host: gateway.localhost" http://127.0.0.1/api
```

> If it breaks the app, you probably didn't template the manifests consistently.

> **If the Pod sits at `0/1 Running`**, your probes are still pointing at port 80 while nginx now listens on 8080.
>
> The container is fine; the *probe* is failing, so the Pod never joins the Service's endpoints and the Ingress has nowhere to send traffic. This is the single most common real-world Helm bug: one value templated in four places and missed in a fifth.

>
> **If you can't reach the app via your browser** , you likely forgot to template the service port in `ingress.yml`.
Try skipping the Ingress:
 `kubectl port-forward service/gw-gateway 8888:8080`
Or forward directly to the Deployment:
`kubectl port-forward deploy/gw-service 8888:9000`
Open [localhost:8888](http://localhost:8888) at each step, make sure the :TARGET port matches your value.
This should give you a hint where it breaks...
## TASK 4: One chart, two environments

This is why charts exist. Same chart, different values file:

```bash
helm upgrade gw ./ -f values-dev.yml
curl -iL -H "Host: gateway-dev.localhost" http://127.0.0.1/api

helm upgrade gw ./ -f values-prod.yml
kubectl get pods -l app.kubernetes.io/instance=gw    # 3 replicas now
```

Read [`values-prod.yml`](./values-prod.yml) — it carries a question in a comment:
*"NOTES.txt is wrong now, how do you curl the app?"*

```bash
helm get notes gw
```

**Answer it.** `NOTES.txt` hardcodes `gateway.localhost` while the host is now a value. Fix
`templates/NOTES.txt` so it tells the truth for any values file. A chart whose own instructions
are wrong is worse than a chart with no instructions.

> `values-prod.yml` also sets `ingress.tls: true`, which makes the Ingress reference a
> `gw-gateway-tls` Secret that nobody created. The chart renders happily and the install succeeds
> — TLS just doesn't work. Helm validates *your templates*, not *your assumptions*. In a real
> cluster that Secret comes from cert-manager.

### Values precedence

Left to right, later wins:

```
chart's values.yaml  →  -f first.yml  →  -f second.yml  →  --set  →  --set-string
```

Prove it, and note what `--reset-values` does differently:

```bash
helm upgrade gw ./ -f values-dev.yml -f values-prod.yml --set replicaCount=2
helm get values gw          # what this release is running
helm get values gw --all    # merged with chart defaults
```

---

## TASK 5a: `values-broken.yml` — a test of your own templating 😈

[`values-broken.yml`](./values-broken.yml) moves three values away from their defaults, each with a
question in a comment. Deploy it:

```bash
helm upgrade gw ./ -f values-broken.yml
kubectl get pods -l app.kubernetes.io/instance=gw
curl -i -H "Host: gateway-broken.localhost" http://127.0.0.1/
```

**Here's the twist: whether this breaks depends entirely on how well you did TASK 3.**

`service.port: 1234` moves nginx off port 80. If you missed *any* of the places that port is
referenced, you get one of these — and if you missed both, you get both at once, which is what
makes this bug so annoying in real life:

- **Pod stuck at `1/2 Running`** (two containers — the backend is fine, nginx isn't). Your probes
  still say `port: 80` while nginx listens on 1234:
  ```bash
  kubectl describe pod -l app.kubernetes.io/instance=gw | grep "probe failed"
  # Readiness probe failed: Get "http://10.42.0.170:80/": connect: connection refused
  ```
  The container is healthy; the *probe* is looking in the wrong place. So the Pod never becomes
  Ready and never joins the Service's endpoints.
- **`curl` returns 404, not 503.** A different bug, and a sneakier one:
  ```bash
  kubectl get svc gw-gateway -o jsonpath='{.spec.ports[*].port}'                          # 80
  kubectl get ingress gw-gateway -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}'  # 1234
  ```
  The Ingress routes to Service port 1234, and the Service only exposes 80. Traefik has no valid
  backend at all, so it doesn't even get as far as a 503 — it 404s, which looks like a routing
  misconfiguration rather than a port bug. This is the `service.yml` TODO.
- **Everything still works?** Then you templated all nine consistently, and there was nothing to
  break. That's the actual lesson: **the file isn't broken, incomplete templating is.** One value
  referenced in five places and templated in four is the bug — and note it produced two completely
  different-looking symptoms.

Now answer the three questions in the comments — especially `api.publicPath: /api/v2`, which
*changes* behaviour without breaking anything. Which URL serves the backend now?

```bash
curl -iL -H "Host: gateway-broken.localhost" http://127.0.0.1/api      # ?
curl -iL -H "Host: gateway-broken.localhost" http://127.0.0.1/api/v2   # ?
```

---

## TASK 5b: A failure that always fails, and undoes itself

For the rollback demo we need a break that no amount of good templating can save. An image tag that
doesn't exist will do it:

```bash
helm upgrade gw ./ --set image.nginx=nginx:this-tag-does-not-exist \
  --rollback-on-failure --timeout 60s
```

> **If that succeeds instead of failing**, you haven't templated the nginx image yet — the
> Deployment is still pinned to a hardcoded `nginx:alpine`, so your `--set` changed nothing. Go back
> to TASK 3. (A value that silently does nothing is the whole bug class this exercise is about.)

While it waits, watch from another terminal:

```bash
kubectl get pods -l app.kubernetes.io/instance=gw -w
# the NEW Pod goes ImagePullBackOff; the OLD Pods keep serving
```

```bash
curl -i -H "Host: gateway-dev.localhost" http://127.0.0.1/   # still up, the whole time
```

**What happened?** Helm waited for the new Pods to become healthy, they never did, so it rolled the
release back to the last good revision and exited non-zero. Nothing was left half-deployed, and the
bad version never received traffic.

```bash
helm history gw          # the failed revision AND the rollback are both recorded
helm get values gw       # you're back on the previous values
```

> **Helm 4 renamed this flag.** It was `--atomic` in Helm 3, which is what every blog post and
> Stack Overflow answer still says. `--atomic` still works but prints a deprecation warning —
> use `--rollback-on-failure`. Setting it also switches `--wait` on for you, which is what makes
> the failure detectable in the first place: without waiting, Helm submits the manifests, sees no
> error, and cheerfully reports success while your Pod is in `ImagePullBackOff`.
>
> **One asymmetry worth knowing:** this only rolls *back*. If the very first `helm install` fails
> there is no previous revision, so Helm **uninstalls** instead. "Roll back" needs somewhere to
> roll back to.
>
> **And what it does NOT undo: your database.** If a migration had run, rolling back the release
> would not roll back the schema. That's the honest limit — see
> [`edu-greetings-chart`](../edu-greetings-chart/README.md) BONUS 3.

Now recover manually, the way you would at 3am:

```bash
helm history gw
helm rollback gw <a revision that worked>
curl -i -H "Host: gateway-dev.localhost" http://127.0.0.1/
```

---

## TASK 6: Two releases, side by side

Module 1's chart couldn't do this — hardcoded object names collided. This chart can:

```bash
kubectl create namespace gw-a
kubectl create namespace gw-b
helm install gw ./ -n gw-a -f values-dev.yml
helm install gw ./ -n gw-b -f values-prod.yml
helm list -A
```

Both work. Find out why:

```bash
helm template gw ./ | grep -E "^  name:"
```

Every object name comes from `gateway.fullname` in [`templates/_helpers.tpl`](./templates/_helpers.tpl),
which is `<release-name>-<chart-name>`. **Read that helper** — the `trunc 63 | trimSuffix "-"` is
not decoration, it's there because Kubernetes names max out at 63 characters and a trailing dash
is invalid.

**Now find what still collides.** Try installing both into the *same* namespace:

```bash
helm install gw2 ./ -n gw-a
```

Does it work? What about the Ingress **host** — two releases claiming `gateway.localhost`? Which
kinds of collision does `fullname` solve, and which does it not?

---

## TASK 7: Package and publish it

A chart directory is for developing. A **packaged chart** is what you ship.

```bash
helm lint ./
helm package ./
# -> gateway-0.1.0.tgz   (the version comes from Chart.yaml, not from git)
```

That `.tgz` is the whole deliverable, and it installs like anything else:

```bash
helm install from-tgz ./gateway-0.1.0.tgz
helm uninstall from-tgz
```

Look at what's actually inside it:

```bash
tar -tzf gateway-0.1.0.tgz
```

**`values-dev.yml` and `values-prod.yml` are not in there** — [`.helmignore`](./.helmignore)
excludes them, the same way `.dockerignore` trims a build context. That's deliberate and it's the
important idea: **the chart is the artifact; environment configuration is not part of it.** Your
values files live in whatever repo drives your deployments, and get passed in with `-f` at install
time. A colleague who installs your published chart gets the chart, not your hostnames.

### Publish to the workshop registry

Charts are **OCI artifacts** — they live in a container registry, right next to the images from
workshop #1. Your facilitator will give you the registry host and login.

```bash
helm registry login <registry-host>
helm push gateway-0.1.0.tgz oci://<registry-host>/<project>

# now install it the way a colleague would — no repo to clone
helm show values oci://<registry-host>/<project>/gateway --version 0.1.0
helm install gw-published oci://<registry-host>/<project>/gateway --version 0.1.0
```

> **Bump `version:` in `Chart.yaml` before every push.** Registries reject a re-push of an
> existing version, and for good reason: a chart version must mean exactly one thing forever.
> Note `Chart.yaml` has *two* versions — `version` (the chart) and `appVersion` (the app inside
> it). They move independently: fixing a typo in your template bumps `version`, not `appVersion`.

### No registry today? Use a local repo instead

Same lesson, no credentials — a chart repository is just a directory with an `index.yaml`:

```bash
mkdir -p /tmp/charts && cp gateway-0.1.0.tgz /tmp/charts/
helm repo index /tmp/charts
helm repo add workshop-local file:///tmp/charts
helm repo update
helm search repo workshop-local
helm install gw-local workshop-local/gateway
```

---

## Clean up

```bash
helm uninstall gw
helm uninstall gw -n gw-a && helm uninstall gw -n gw-b
kubectl delete namespace gw-a gw-b
```

---

## Stuck?

- **`curl` hangs or gives connection refused** — Traefik hasn't bound port 80. This is the same
  Rancher Desktop fix as workshop #2 module 2:
  `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80`, then `rdctl shutdown && rdctl start`.
  Or skip the Ingress entirely: `kubectl port-forward deploy/gw-gateway 8888:80`.
- **404 from the Ingress** — first just **wait a few seconds and retry.** Traefik takes a moment to
  notice a new Ingress, so an immediate `curl` after `helm install` often 404s once and then works.
  If it persists, check the class matches your cluster: `kubectl get ingressclass`. Rancher Desktop
  / k3d = `traefik`; kind + ingress-nginx = `nginx`. Override with `--set ingress.className=...`.
  A **persistent** 404 with a Ready Pod usually means the Ingress and the Service disagree about
  the port — see TASK 5a.
- **Template errors** — `helm template ./ --debug`. For "cannot find template" check the exact
  name in `_helpers.tpl` against the `include`.
- **Pod `0/1 Running`** — a probe is failing. `kubectl describe pod -l app.kubernetes.io/instance=gw`
  and read the Events. Almost always a port you forgot to template.
- **`nil pointer evaluating interface {}`** — you referenced `.Values.something.missing`. Add it
  to `values.yaml`, or guard it: `{{ .Values.thing | default "fallback" }}`.
- **Upgrade says "has no deployed releases"** — the previous install failed, so there's nothing to
  upgrade. `helm uninstall` and install fresh.
- Docs: <https://helm.sh/docs/chart_template_guide/> and
  <https://helm.sh/docs/chart_template_guide/debugging/>

## BONUS

1. **Install someone else's chart.** Charts are distributed like packages:
   ```bash
   helm repo add examples https://helm.github.io/examples
   helm search repo examples --versions
   helm show values examples/hello-world
   helm install hello examples/hello-world
   ```
   Other repos worth a look: <https://helm.elastic.co>, <https://charts.gitlab.io/>, and the
   list at <https://github.com/cdwv/awesome-helm#repositories--hubs>.
2. **Whitespace.** Change a `{{-` to `{{` somewhere in `configmap-nginx.yml` and render. YAML is
   whitespace-significant and Go templates are not, which is the single most annoying thing about
   writing charts. Learn what `{{-`, `-}}`, `nindent` and `indent` do.
3. **`required`.** Make the chart refuse to install without a backend text:
   `{{ required "backend.text is required" .Values.backend.text }}`. Fail at install, not at 3am.
4. **Move the sidecar out.** Turn the `backend` container into its own Deployment + Service, so it
   scales independently — nginx then proxies to `http://<fullname>-backend:{{ .Values.backend.port }}`
   instead of `127.0.0.1`. This is the jump from sidecar to real service discovery, and it's what
   `edu-greetings-chart` does.
5. **`helm diff`.** Install the plugin (`helm plugin install https://github.com/databus23/helm-diff`)
   then `helm diff upgrade gw ./ -f values-prod.yml`. See the change *before* you make it. This is
   the plugin most teams consider mandatory.
6. **Add resource requests and limits.** This chart deliberately has none, which
   [`BEST-PRACTICES.md`](../BEST-PRACTICES.md) lists as something you should almost always template
   — a laptop and a production node want very different numbers. Add a `resources:` block to
   `values.yaml` and render it with `{{- toYaml .Values.resources | nindent 12 }}`. Copy the pattern
   from [`edu-greetings-chart`](../edu-greetings-chart/templates/deployment.yaml). Then work out why
   `nindent 12` and not `nindent 10`.
7. **Give the chart a `values.schema.json`.** Right now `--set service.port=notaport` renders happily
   and fails only when Kubernetes rejects it. Add a schema that catches it in one second. Start from
   [`edu-greetings-chart/values.schema.json`](../edu-greetings-chart/values.schema.json). Which of
   this chart's nine values have a range or a format worth enforcing?
8. **The backend container has no probe.** So `--wait` and `--rollback-on-failure` can't tell a
   broken backend from a working one — only a broken *nginx*. Add a probe to the `backend` container
   and prove it: break the backend's port on purpose and watch the upgrade fail where it previously
   succeeded.
