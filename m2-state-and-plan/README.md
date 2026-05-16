# M2 — State and Plan

Where state lives and how plans are saved, reviewed, and consumed by CI/CD.
Terraform writes JSON state to S3 plus a Consul/DynamoDB lock; forjar writes
BLAKE3-hashed YAML to Git, so your VCS already does versioning, locking, and
history.

Two demos pair OpenTofu's saved-plan workflow (cookbook recipe 30) and JSON
plan output (cookbook recipe 31) against their forjar equivalents.

## Lessons

| Video | Title | Comparison | Demo |
|---|---|---|---|
| 2.1.1 | Where State Lives | S3 + Consul lock vs Git + BLAKE3 | (no demo — concept lesson) |
| 2.1.2 | Saved Plans | `terraform plan -out=plan.tfplan` vs `forjar plan --lock` | [`2.1.2-saved-plan/`](2.1.2-saved-plan/) |
| 2.1.3 | JSON Plan Output | `terraform show -json` vs `forjar plan --format json` | [`2.1.3-json-plan/`](2.1.3-json-plan/) |

## Run

```bash
# Saved-plan workflow — write a plan, review it, then apply the exact bytes
make demo-2.1.2

# JSON plan output — what CI consumes to gate on resource counts and policy
make demo-2.1.3
```

## What you'll learn

- Terraform's remote state is a JSON file in an S3 bucket plus a Consul or
  DynamoDB lock — losing the bucket means losing the state.
- forjar's BLAKE3 lock file IS the saved plan — readable YAML with hashes per
  resource; you diff it before apply with `git diff`.
- `terraform plan -out=plan.tfplan` writes binary; `forjar plan --lock` writes
  text — review-then-execute split, same workflow.
- `terraform show -json plan.tfplan` and `forjar plan --format json` emit the
  same shape (`resource_changes` array, before/after diffs).
- A CI policy script never needs to know which tool produced the plan; both
  Terraform and forjar speak the same JSON contract.
