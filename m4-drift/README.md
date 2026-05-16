# M4 — Drift and Convergence

Drift is what happens between applies — someone SSHs into a host and edits a
config, an API rate-limits a tag update, a sibling tool mutates state.
Terraform's answer is `refresh-only` mode (poll every cloud API), `check`
blocks (post-apply assertions), and `terraform_remote_state` (read another
stack's outputs). forjar's answer is a local BLAKE3 hash compare, runtime
contracts on every apply, and explicit hash-pinned recipe imports.

Three demos pair cookbook recipes 35, 32, and 39 against their forjar
equivalents.

## Lessons

| Video | Title | Comparison | Demo |
|---|---|---|---|
| 4.1.1 | Drift Detection | `terraform plan -refresh-only` vs BLAKE3 hash compare | [`4.1.1-refresh-only/`](4.1.1-refresh-only/) |
| 4.1.2 | Check Blocks for Policy Gates | `check { assert {} }` vs forjar contracts (C1–C10) | [`4.1.2-check-blocks/`](4.1.2-check-blocks/) |
| 4.1.3 | Cross-Config Sharing | `terraform_remote_state` vs `forjar` recipe imports | [`4.1.3-cross-config/`](4.1.3-cross-config/) |

## Run

```bash
make demo-4.1.1       # drift detection: refresh-only vs hash compare
make demo-4.1.2       # check blocks: post-apply assertions vs runtime contracts
make demo-4.1.3       # cross-config: remote_state vs hash-pinned recipe import
```

## What you'll learn

- `terraform plan -refresh-only` polls every cloud API — slow, expensive, only
  catches drift in resources Terraform created.
- forjar's drift detection is a local BLAKE3 hash compare against the lock
  file: runs in milliseconds, no API rate limits.
- OpenTofu 1.5+ `check { assert { condition = ... } }` is post-apply policy
  validation; forjar's 10 falsifiable claims (C1–C10) are asserted on every
  apply, closer to a property test than a health check.
- `terraform_remote_state` is the canonical way to share VPC IDs and subnet
  ARNs across stacks; forjar imports outputs by ID + BLAKE3 hash, refusing to
  apply if the upstream recipe changed since the lock was written.
- The architectural shift: forjar's drift signal IS the lock file's content
  hash mismatch — nothing to poll, nothing to schedule.
