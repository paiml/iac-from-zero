# Lab 3 — Break it, watch it heal

> Module 3: State, drift & recovery. Anchors on cookbook recipes
> **#50 `failure-partial-apply`**, **#51 `failure-state-recovery`**,
> **#52 `failure-idempotent-crash`**. Every operation is local; no
> sudo required.

## Goal

Apply a 3-resource stack. Manually delete one of the files from outside
forjar. Run `forjar drift` and watch forjar detect the missing resource
without touching any cloud API or remote state backend — pure local
hash compare against the lock file. Run `forjar apply` to put it back.

This lab exercises three forjar claims operationally:

- **C5** (content-addressed state) — the lock file is the source of truth
  about what *should* be on disk
- **C6** (atomic state persistence) — the lock file is updated via temp
  file + rename, so a SIGKILL mid-apply leaves either the old or the new
  lock, never a torn one
- **C10** (Jidoka — first failure stops execution) — if you set the
  resource to an invalid value, forjar halts at that resource and
  preserves prior progress

## Drill

```bash
# 1. Converge.
forjar apply -f forjar.yaml --yes

# 2. Drift it. Pretend an on-call engineer rm'd this at 2 AM.
rm /tmp/iac-from-zero-lab03/heartbeat.txt

# 3. Detect drift. forjar walks the lock file and hash-compares against
#    the live filesystem. No network calls, no rate limits, no auth.
forjar drift -f forjar.yaml

# 4. Reconverge. Drift is a tripwire by default — apply refuses
#    until you explicitly acknowledge it with --force.
forjar apply -f forjar.yaml --yes --force

# 5. Check the lock file is still the same — desired state didn't change,
#    so the lock didn't change. Only the live filesystem moved.
sha256sum state/forjar.lock.yaml
```

After step 4, `forjar drift -f forjar.yaml` should report no drift.

## The Jidoka drill (claim C10)

After the basic drill works, deliberately edit `forjar.yaml` and set the
`cron-stub` resource's `mode` to garbage:

```yaml
cron-stub:
  type: file
  ...
  mode: "0999"   # not a valid mode
```

Run `forjar apply -f forjar.yaml --yes`. Two outcomes possible:

- **Caught at validate time.** forjar rejects the bad mode at parse time
  (best case — claim **C4** territory).
- **Caught at apply time.** forjar gets through `base-dir` and
  `heartbeat`, then halts at `cron-stub` and reports the failure. The
  prior two resources stay converged. There is no half-converged
  cron-stub, no partial state. That's claim **C10**.

Restore the mode to `"0644"` and re-apply — only the broken resource is
re-attempted; the converged ones stay untouched.

## Self-check

```bash
# After the drill (drift detected and reconverged), drift_count should be 0:
forjar status --json --state-dir state | jq '.machines[].resources | length'
# → 3
```

The fixture shape lives in `expected-status.json` for this lab.

## Why drift detection without API calls is a big deal

Other tools' drift detection requires:

- **Terraform**: a remote-state backend (S3/Cloud Storage/etc.), API calls
  to every cloud provider with rate limits, IAM roles, network
  reachability. Detecting drift on 1000 resources can take 5+ minutes
  and cost real money.
- **Ansible**: nothing — Ansible has no concept of drift detection;
  re-running a playbook *blindly re-converges* and prints what it did,
  which is not the same thing.
- **Hand-rolled scripts**: nothing.

forjar walks the lock file, hashes the live state, compares. The whole
operation is `O(resources)` local work and finishes in milliseconds for
typical stacks.

## Reference solution

`solution/forjar.yaml` is the reference for instructor self-check.
