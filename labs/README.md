# labs/ — exercises with reference solutions

The `labs/` tree is the **learner-facing exercises** half of this repo.
Each lab is one module of *IAC from Zero*. Where the `m1-…m5-` demos in
the repo root show OpenTofu and forjar side-by-side as **reference**,
the labs ask you to write `forjar.yaml` yourself and check your output
against committed `expected-*.json` fixtures.

## Lab map

| Lab | Module | Theme | Cookbook anchors |
|---|---|---|---|
| [`lab-01-first-yaml/`](lab-01-first-yaml/) | M1 — declarative IaC & plan/apply | Your first `forjar.yaml` | #01 `developer-workstation` |
| [`lab-02-dag/`](lab-02-dag/) | M2 — resources, the DAG & dependencies | Wiring resources together | #40 `scheduled-tasks`, #41 `user-provisioning`, #43 `log-management` |
| [`lab-03-drift/`](lab-03-drift/) | M3 — state, drift & recovery | Break it, watch it heal | #50–#52 failure family |
| [`lab-04-plan-pin/`](lab-04-plan-pin/) | M4 — plan, lifecycle & reproducibility | Plans are the contract | #12 `toolchain-pin`, #31 `json-plan`, #34 `moved-blocks` |
| [`lab-05-recipes/`](lab-05-recipes/) | M5 — recipes, composition & CI gates | Author one recipe, compose a stack | #53 `stack-dev-server`, #57 `stack-package-pipeline` |

Each lab directory contains:

```
lab-NN-…/
├── README.md                   # the exercise prompt
├── forjar.yaml                 # the starter / scaffold the learner edits
├── solution/                   # reference solution kept passing in CI
│   └── forjar.yaml
└── expected-status.json        # or expected-execution-order.json, etc.
                                # the fixture the solution must reproduce
```

## How CI uses the labs

`.github/workflows/iac.yml` (the `gate-matrix` job) treats every lab's
`solution/` as a regression test for forjar itself:

- `forjar validate -f labs/lab-N/solution/forjar.yaml`
- `forjar plan -f labs/lab-N/solution/forjar.yaml --state-dir labs/lab-N/solution/state`
- `forjar apply` then `forjar apply` again — proves claim **C3 (idempotency)** via
  the `actual_changes == 0 && forced_noop_count == 4` shape post-1.4.2
- `bash scripts/verify-fixtures.sh` — diffs the solution's `forjar status --json`
  against the committed `expected-status.json` (and equivalents for lab-02 / 04 / 05)
- For lab-04: `forjar pin` + manual lock corruption to demonstrate **C1
  (deterministic hash)** rejecting tampered state

The same `verify-fixtures.sh` script is exposed locally as `make verify`
from the repo-root Makefile.

## Running a lab locally

```bash
cd labs/lab-01-first-yaml/solution
forjar plan -f forjar.yaml          # see what would happen
forjar apply -f forjar.yaml --yes   # converge (local /tmp/ paths, no sudo)
forjar apply -f forjar.yaml --yes   # second run: should report 0 converged
```

Then go back to `lab-01-first-yaml/forjar.yaml` (the starter) and try
the exercise yourself. Diff against the solution when stuck.

## Relationship to the `m1-…m5-` demos

| Repo half | Audience | What you do |
|---|---|---|
| `m1-…m5-` | Reading | Compare `main.tf` ⇄ `forjar.yaml` side-by-side |
| `labs/` | Doing | Write `forjar.yaml` yourself; CI proves your solution converges |

Both halves anchor on the same cookbook recipes; both halves ship in
the same `make` driver. The repo-root README's "Demo map" covers the
reading side; this README covers the doing side.
