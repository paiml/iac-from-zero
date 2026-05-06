# Lab 1 — Your first `forjar.yaml`

> Module 1: Declarative IaC & the plan/apply loop. Anchors on cookbook
> recipe **#01 `developer-workstation`**, simplified to four resources
> that run in the lab container in under 2 seconds.

## Goal

Finish `forjar.yaml` so it declares a 4-resource workstation. Apply it
once — `forjar` reports `4 converged`. Apply it again — `forjar` reports
`0 converged, 4 unchanged`. That second outcome is the demonstration of
forjar's claim **C3** (idempotency): same desired state in, same lock
file out, no changes.

You will edit two `params:` values and add three resources to
`forjar.yaml`. The first resource (`data-dir`) is given as a template.

## What "finished" looks like

`params`:
- `user: de`
- `data_dir: /tmp/iac-from-zero-lab01`

`resources` (four total):
1. `data-dir` — the directory at `params.data_dir` (given)
2. `config-dir` — a directory at `{{params.data_dir}}/config`, depends on `data-dir`
3. `de-config` — a file at `{{params.data_dir}}/config/de.yaml` containing
   `data_dir:` and `user:` lines populated from params, depends on `config-dir`
4. `readme-marker` — a file at `{{params.data_dir}}/README.txt` with a short
   "managed by forjar" message, depends on `data-dir`

## Run it

```bash
forjar validate -f forjar.yaml          # schema check, no apply
forjar plan     -f forjar.yaml          # show what apply will do
forjar apply    -f forjar.yaml --yes    # converge to desired state

# The C3 moment — second apply should report 0 converged, 4 unchanged:
forjar apply    -f forjar.yaml --yes
```

After the second apply, your output should match this exactly:

```
localhost: 0 converged, 4 unchanged, 0 failed
Apply complete: 0 converged, 4 unchanged.
```

## Self-check

Compare your status against the canonical fixture:

```bash
forjar status --json --state-dir state \
  | jq -S 'del(.global.last_apply, .global.machines.localhost.last_apply,
               .machines[].generated_at, .machines[].resources[].applied_at,
               .machines[].resources[].duration_seconds,
               .machines[].resources[].details.live_hash,
               .machines[].generator, .global.generator,
               .machines[].blake3_version)' > my-status.json

diff <(jq -S . expected-status.json) my-status.json
```

Empty diff = pass. The `jq` filter strips timestamps, the live-state hash
(which captures filesystem-side state and varies across runs), and the
generator string (so a forjar version bump doesn't invalidate the
fixture). The desired-state BLAKE3 hashes — the ones forjar derives from
your config — *are* compared. They are deterministic.

## Why this is a win over a bash script

Look at the four resources you wrote. Now imagine the bash equivalent:

```bash
mkdir -p /tmp/iac-from-zero-lab01
mkdir -p /tmp/iac-from-zero-lab01/config
cat > /tmp/iac-from-zero-lab01/config/de.yaml <<EOF
data_dir: /tmp/iac-from-zero-lab01
user: de
EOF
cat > /tmp/iac-from-zero-lab01/README.txt <<EOF
This directory is managed by forjar.
EOF
```

Both produce the same output the first time. But:

- Your forjar.yaml asserts **what** the system should look like; the bash
  script asserts **how** to get there.
- Re-running the bash script will `cat >` over the files unconditionally
  every time — there is no concept of "already done." `forjar apply`
  on the second run reports `0 changes` and writes nothing.
- If a teammate manually deletes one file, `forjar drift` reports it
  (Lab 3) and `forjar apply` puts it back. Re-running the bash script
  fixes it too — but it also re-overwrites the three files that *weren't*
  drifted, mtime-thrashing them, breaking any `make` rules that key off
  mtime, and burning IO for no gain.

The bash script can never give you `0 changes`. forjar can. That's the
discipline this course exists to teach.

## Reference solution

`solution/forjar.yaml` ships the reference implementation for instructor
self-check. Don't peek before finishing — the lab is much more useful if
you actually write the four resources from the TODO comments.
