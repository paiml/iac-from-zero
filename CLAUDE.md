# CLAUDE.md — agent context for iac-from-zero

This is the **companion repo** for the *IAC from Zero* Coursera course
(course 21 of the *Rust for Data Engineering* specialization). The repo
exists to give learners runnable, side-by-side demos of every OpenTofu
feature the course covers and its `forjar` equivalent.

## Scope

This repo has **two halves**:

1. **Reading half** — 12 `m1-…m5-` demo directories pair one `forjar.yaml`
   (from a numbered [`forjar-cookbook`](https://github.com/paiml/forjar-cookbook)
   recipe) with one `main.tf` showing the OpenTofu equivalent. Each demo
   dir is minimal: the two side-by-side files, a brief `README.md`, and
   (for testing-DSL demos) a sibling `tests/*.tftest.hcl`.
2. **Doing half** — 5 `labs/lab-NN-…` exercise directories with a starter
   `forjar.yaml`, a reference `solution/`, and a committed
   `expected-*.json` fixture the solution must reproduce. CI gates the
   solutions against drift via `make verify`.

```
# Reading half — 12 side-by-side demos
m1-first-apply/                           # cookbook 01 (developer-workstation)
m2-state-and-plan/2.1.2-saved-plan/       # cookbook 30
m2-state-and-plan/2.1.3-json-plan/        # cookbook 31
m3-lifecycle/3.1.1-lifecycle/             # cookbook 33
m3-lifecycle/3.1.2-moved-blocks/          # cookbook 34
m3-lifecycle/3.1.3-resource-targeting/    # cookbook 36
m4-drift/4.1.1-refresh-only/              # cookbook 35
m4-drift/4.1.2-check-blocks/              # cookbook 32
m4-drift/4.1.3-cross-config/              # cookbook 39
m5-testing-security/5.1.1-testing-dsl/    # cookbook 37
m5-testing-security/5.1.2-state-encryption/   # cookbook 38
m5-testing-security/5.1.3-capstone-canary-fleet/  # cookbook 94

# Doing half — 5 learner exercises
labs/lab-01-first-yaml/                   # M1 (anchors cookbook #01)
labs/lab-02-dag/                          # M2 (cookbook #40/#41/#43)
labs/lab-03-drift/                        # M3 (cookbook #50-#52 failure family)
labs/lab-04-plan-pin/                     # M4 (cookbook #12/#31/#34)
labs/lab-05-recipes/                      # M5 (cookbook #53/#57)
```

## Hard rules

- **Never modify a `forjar.yaml`** to make a demo "fit" — the YAML must
  remain a verbatim copy of the upstream cookbook recipe so the
  cookbook commit hash pins the demo's behavior. Track upstream by
  re-copying from `/home/noah/src/forjar-cookbook/recipes/<id>.yaml`.
- **Never delete the symlinked `includes/`** — `forjar validate` and
  `forjar plan` resolve `includes/policy-defaults.yaml` +
  `includes/notify-hooks.yaml` relative to the demo dir. The repo-root
  `includes/` is the canonical copy; each demo symlinks it.
- **`make demo-all` is the CI gate.** It runs `forjar validate` +
  `forjar plan` + `forjar plan --json` against every demo. A change
  that breaks the gate locally will break CI; never commit without
  running it.
- **`make apply-<dir>` is opt-in.** It actually converges a container
  target — do not chain it into `demo-all` or CI.

## Soft rules

- The `main.tf` files use only `null_resource` / `local_file` / built-in
  providers so they parse with `terraform validate` without cloud
  credentials. If a learner wants to apply them, they need to opt into
  real providers.
- READMEs are factual and table-heavy; no "comprehensive" / "leverage" /
  "powerful". Style modeled on
  [`design-by-provable-contracts/README.md`](https://github.com/paiml/design-by-provable-contracts).

## Where things live (full repo map)

| Path | Role | Notes |
|---|---|---|
| `m1-…m5-…/` | 12 OpenTofu ⇄ forjar side-by-side demos | gated by `make demo-all` + `make tofu-validate` |
| `labs/lab-01-…lab-05-…/` | 5 learner exercises with `solution/` + `expected-*.json` | gated by `.github/workflows/iac.yml` + `make verify` |
| `recipes/de-pipeline-host.yaml` | One end-to-end reference recipe | NOT exercised by CI today; carried for course reference |
| `capstone/` | M5 capstone scaffold | end-of-course assignment |
| `includes/` | Shared `policy-defaults.yaml` + `notify-hooks.yaml` | symlinked into every demo dir |
| `scripts/verify-fixtures.sh` | Diff lab solution outputs vs `expected-*.json` | called by `make verify` and by `iac.yml` directly |
| `assets/hero.{svg,png}` | README banner | 1200×600 OpenTofu / forjar / fleet panels |
| `.github/workflows/ci.yml` | `make demo-all` + `tofu-validate` + yamllint + shellcheck | the `m*-` demo gate |
| `.github/workflows/iac.yml` | `forjar` lab gate + fixture verification + C1/C3 claim checks | the `labs/` gate |

The two CI workflows have **distinct purposes** and are intentionally
kept separate:

- `ci.yml` — gates the **reading half** (`m1-…m5-` demos). Installs
  forjar from crates.io and OpenTofu from the official release, then
  runs `make demo-all` + `make tofu-validate`.
- `iac.yml` — gates the **doing half** (`labs/`). Installs forjar from
  a versioned cache, runs `forjar validate`/`plan` against every lab
  solution, then runs `scripts/verify-fixtures.sh` and the C1/C3 claim
  checks. The `gate` aggregator job at the end produces a status check
  the org's `Green Main` ruleset keys off of.

## Upstream references

- Cookbook recipes (upstream): `https://github.com/paiml/forjar-cookbook`
- Forjar binary (upstream): `https://github.com/paiml/forjar`
- Course config (curriculum): `course-studio/config/rde_c21_iac_from_zero.lua`
- License: MIT OR Apache-2.0 (dual)
