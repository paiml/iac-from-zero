# M1 — Why IAC, Why Forjar

The opening module. Declarative infrastructure replaces imperative bash
scripts; plan-then-apply is the universal IAC contract; and `forjar` collapses
Terraform's Go runtime, S3 backend, and HCL DSL into a single Rust binary with
BLAKE3-hashed YAML state.

The single demo in this module is cookbook recipe 01 `developer-workstation` —
a Tier-2 container target that provisions packages, a user, and dotfiles, then
proves strong idempotency on the second apply.

## Lessons

| Video | Title | Comparison | Demo |
|---|---|---|---|
| 1.1.1 | Why Declarative Infrastructure | imperative bash vs declarative IAC | (no demo — concept lesson) |
| 1.1.2 | What Forjar Is | Terraform's 200 Go modules vs forjar's 17-crate Rust binary | (no demo — comparison table) |
| 1.1.3 | Your First Forjar Apply | `terraform apply` vs `forjar apply` + BLAKE3 lock | [`./forjar.yaml`](forjar.yaml) |

## Run

```bash
# First apply — provisions the devbox container end-to-end (< 60 s)
forjar apply

# Second apply — strong idempotency, completes in < 2 s because every
# BLAKE3 hash matches the lock file
forjar apply

# Inspect the lock file — readable YAML with hashes per resource
cat forjar.lock
```

Or from the repo root:

```bash
make demo-1.1.3
```

## What you'll learn

- Declarative IAC says "here is the end state" and the tool figures out the
  diff; the same config converges from any starting point.
- Plan-then-apply is the universal IAC contract: every tool from Terraform to
  forjar shows you what will change before it changes anything.
- forjar is a single Rust binary — 17 crate dependencies, no Go runtime, no
  Python interpreter, no provider plugins.
- State lives in Git as BLAKE3-hashed YAML; the lock file IS the state, so
  recovery from a corrupted state is `git checkout`.
- A second `forjar apply` against the unchanged config completes in
  ~408 ms because BLAKE3 hashes match — that is strong idempotency,
  qualified in the cookbook.
