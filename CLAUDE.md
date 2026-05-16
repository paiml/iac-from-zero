# CLAUDE.md — agent context for iac-from-zero

This is the **companion repo** for the *IAC from Zero* Coursera course
(course 21 of the *Rust for Data Engineering* specialization). The repo
exists to give learners runnable, side-by-side demos of every OpenTofu
feature the course covers and its `forjar` equivalent.

## Scope

The 12 demo directories pair one `forjar.yaml` (from a numbered
[`forjar-cookbook`](https://github.com/paiml/forjar-cookbook) recipe)
with one `main.tf` showing the OpenTofu equivalent. The two files are
the lesson — nothing else ships in a demo dir except a brief `README.md`
and, for testing-DSL demos, a sibling `tests/*.tftest.hcl`.

```
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

## Where things live

- Cookbook recipes (upstream): `https://github.com/paiml/forjar-cookbook`
- Forjar binary (upstream): `https://github.com/paiml/forjar`
- Course config (curriculum): `course-studio/config/rde_c21_iac_from_zero.lua`
- Hero SVG + PNG: `assets/hero.{svg,png}`
- License: MIT OR Apache-2.0 (dual)
