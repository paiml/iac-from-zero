# Lab 2 — Wiring resources together

> Module 2: Resources, the DAG & dependencies. Anchors on cookbook recipes
> **#41 `user-provisioning`**, **#40 `scheduled-tasks`**, and
> **#43 `log-management`** — but the dependency mechanic is the lesson;
> the resources can be plain files so the lab runs without sudo.

## Goal

Five file resources arranged in a small DAG. The chain is:

```
base-dir → data-dir → state-marker
                    → log-dir → logrotate-config
```

You declare *relationships* with `depends_on`. forjar's DAG resolver picks
the order — Kahn's topological sort, with alphabetical tie-breaking.
Same desired state in, same execution order out. Every time. That's
claim **C2** (deterministic execution).

## Run it

```bash
forjar validate -f forjar.yaml
forjar plan     -f forjar.yaml
forjar apply    -f forjar.yaml --yes

# The DAG mechanic — read the resolved order:
forjar plan -f forjar.yaml --json | jq '.execution_order'
```

Expected execution order (BFS-by-depth, alphabetical within a depth):

```json
[
  "base-dir",
  "data-dir",
  "log-dir",
  "state-marker",
  "logrotate-config"
]
```

`log-dir` and `state-marker` both depend only on `data-dir` (depth 3),
so they run before `logrotate-config` (depth 4 — depends on `log-dir`).
Within depth 3 the tie-break is alphabetical: `log-dir` before
`state-marker`. The single depth-4 node lands last.

## The cycle drill (claim C4)

After the linear chain converges, deliberately introduce a cycle:

```yaml
# in forjar.yaml — break it
base-dir:
  type: file
  ...
  depends_on: [logrotate-config]    # cycle: base ← logrotate ← log ← data ← base
```

Then run:

```bash
forjar validate -f forjar.yaml
```

forjar should reject this at *parse time* with a cycle error — no
filesystem touched, no partial state. Compare to a bash script that
would happily run the first three steps before hitting the missing
prereq on step four.

Restore the file once you've seen the error.

## Self-check

```bash
forjar plan -f forjar.yaml --json --state-dir state \
  | jq -S '.execution_order' > my-order.json

diff <(jq -S . expected-execution-order.json) my-order.json
```

Empty diff = pass.

## Why `depends_on` is a contract, not an order hint

`depends_on` declares a **relationship** the resolver respects. It does
not declare a position in a script. This matters because:

- Refactoring a config never breaks ordering — the resolver re-derives
  it from the relationships every time.
- Cycles are caught before any side effect (claim **C4**).
- Adding a new resource between two existing ones is a one-line change
  in YAML, not a 30-line script edit.
- Two engineers writing two parallel resources can list them in any
  order in the YAML file; the resolver merges deterministically.

A bash script encodes order in line numbers. A `forjar.yaml` encodes
relationships in `depends_on`. The first is fragile to refactor; the
second is built to be refactored.

## Reference solution

`solution/forjar.yaml` ships the reference implementation. Use it for
instructor self-check; finish your own copy first.
