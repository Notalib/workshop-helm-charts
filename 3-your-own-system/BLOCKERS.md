# Blockers

What stopped you. Fill this in before you leave, even if it's one line.

**Why this matters twice over:** it's your own to-do list, and collectively these blockers decide
what the next workshop covers. A syllabus built from ten real blockers beats one guessed in
advance — so an honest "I got nowhere because X" is more useful here than a tidy answer.

---

## My blockers

| # | Blocker | Which component | Can I solve it alone? | Who/what I need |
|---|---|---|---|---|
| 1 | | | ☐ yes ☐ no | |
| 2 | | | ☐ yes ☐ no | |
| 3 | | | ☐ yes ☐ no | |

---

## Common ones — tick anything that applies

Faster than writing prose, and it makes the pattern across the room visible.

**Images & build**
- [ ] The app isn't containerised at all
- [ ] It builds locally but there's no CI to build/push it
- [ ] No registry I can push to / don't know the credentials
- [ ] The image is huge or takes too long to build
- [ ] It needs a base image we're not allowed to pull from Docker Hub

**Platform**
- [ ] Needs a Windows host
- [ ] Needs a licence server / dongle / MAC-locked licence
- [ ] Needs a fixed IP or a specific hostname
- [ ] Needs a shared SMB/NFS mount
- [ ] Needs `ReadWriteMany` storage
- [ ] Needs privileged access to the host
- [ ] Depends on something only reachable from a specific network segment

**State & data**
- [ ] The database can't move / I'm not allowed to copy it
- [ ] There's state on local disk with no clear owner
- [ ] Migrations are manual and nobody's sure they're repeatable
- [ ] I don't know what's safe to lose

**Knowledge**
- [ ] Nobody knows where some config value comes from
- [ ] No health endpoint / no way to tell if it's up
- [ ] The person who built it has left
- [ ] There's no non-production environment to try this in

**Process & permissions**
- [ ] Not allowed to deploy this myself
- [ ] Needs a change request / security review first
- [ ] No time allocated for this work

**Helm/Kubernetes specifically**
- [ ] Got lost in template syntax
- [ ] Couldn't work out how to structure `values.yaml`
- [ ] Don't know how to handle secrets properly
- [ ] Unclear how this gets deployed for real (CI? ArgoCD? by hand?)
- [ ] Something else about Helm: ______________________________

---

## What I actually got done

- [ ] Canvas filled in
- [ ] Chart skeleton exists
- [ ] `helm lint` passes
- [ ] One component templated
- [ ] It installs
- [ ] It runs

## One thing I learned about my own system that I didn't know this morning

_______________________________________________________________

> Worth asking out loud. This is usually the most valuable sentence anyone writes today — the
> systems are different but the surprises rhyme.
