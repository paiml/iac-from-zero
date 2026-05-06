# Lab 4 — Plans are the contract

> Module 4: Plan, lifecycle & reproducibility. Anchors on cookbook
> recipes **#31 `json-plan`**, **#34 `moved-blocks`**, and
> **#12 `toolchain-pin`**. Local-only; no sudo required.

## Goal

Treat `forjar plan` as a *promise* about what `apply` will do. Save the
plan, jq into it, refactor a resource name with a `moved` block (no
destroy + create), pin all inputs with `forjar pin`, then manually edit
one BLAKE3 hash and watch `forjar pin --check` fail.

## Drill

```bash
# 1. Initial apply — three resources, one named `heartbeat`.
#    See solution/forjar.yaml for what to write at the start.
forjar apply -f forjar.yaml --yes

# 2. Read the plan as JSON, jq into it. The plan is a contract; on a
#    no-change apply you should see an empty `changes` array.
forjar plan -f forjar.yaml --json | jq '{
  unchanged: (.unchanged | length),
  to_create: (.to_create | length),
  to_update: (.to_update | length),
  to_destroy: (.to_destroy | length)
}'

# 3. Save the plan to a binary file (FJ-1250). Apply it later from
#    that exact bytes — what was reviewed is what gets applied.
forjar plan -f forjar.yaml --out planfile.bin
ls -la planfile.bin

# 4. Refactor `heartbeat` → `de-heartbeat` via a moved block.
#    The solution config already has this rename. The moved block
#    is a one-time migration: the lock file resource entry is rewritten
#    in place — no recreate, no destroy, no lost state.
#    After the next apply, the lock file has `de-heartbeat` instead
#    of `heartbeat` with the same hash; the live file is untouched.
forjar apply -f forjar.yaml --yes

# 5. Pin every input. Walks the resource graph, computes BLAKE3
#    hashes for each input, writes state/forjar.inputs.lock.yaml.
#    This is claim C1 (deterministic hashing) made operational.
forjar pin -f forjar.yaml

# 6. CI gate — pass.
forjar pin --check -f forjar.yaml
# → Lock file is fresh and complete — PASS

# 7. Manually corrupt one hash.
sed -i 's/blake3:[0-9a-f]\{6\}/blake3:DEADBEEF/' state/forjar.inputs.lock.yaml

# 8. CI gate — fail. Exit code is non-zero, message names every drifted pin.
forjar pin --check -f forjar.yaml
# → error: Lock file check FAILED: N stale, 0 missing

# 9. Restore.
forjar pin -f forjar.yaml          # rewrites the lock file from current inputs
forjar pin --check -f forjar.yaml  # PASS again
```

## Self-check

```bash
forjar plan -f forjar.yaml --json --state-dir state \
  | jq -S '{name, unchanged: (.unchanged | length), changes_count: (.changes | length)}' \
  > my-plan.json

diff <(jq -S . expected-plan-shape.json) my-plan.json
```

Empty diff = pass.

## Why `pin --check` is the right CI gate

A typical "is the lock file up to date?" check in other tools means
running the full plan and checking the diff is empty. That's expensive
because plan does I/O against every backend.

`forjar pin --check` is a hash compare against the inputs lock — pure
local work, milliseconds. It catches three real failure modes:

1. **Teammate forgot to re-pin after editing the config.** Lock is
   stale relative to the YAML; CI fails immediately.
2. **Teammate manually edited the lock file** (typo, merge conflict
   resolved badly, malicious supply-chain pin substitution). Hashes no
   longer match the YAML; CI fails immediately.
3. **Teammate added a new resource without re-pinning.** Lock is
   missing entries; CI reports `N missing`.

Pair this with `forjar plan` on PR (claim C5 — content-addressed state)
and you have a deterministic, fast gate that catches the lock-rot
class of bug at machine speed instead of human speed.

## Reference solution

`solution/forjar.yaml` is the reference for instructor self-check.
