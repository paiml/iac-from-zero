# M3 — Lifecycle and Refactoring

How IAC tools handle the day-2 problems: protecting production resources,
renaming without re-creating, and applying part of a config without the whole.
Terraform leans on `lifecycle`, `moved`, and `-target` HCL blocks; forjar
solves the same problems through idempotent recipes and content-addressed
resource IDs.

Three demos pair cookbook recipes 33, 34, and 36 against their forjar
equivalents.

## Lessons

| Video | Title | Comparison | Demo |
|---|---|---|---|
| 3.1.1 | Resource Lifecycle Blocks | `lifecycle { prevent_destroy }` + `create_before_destroy` vs idempotent re-converge | [`3.1.1-lifecycle/`](3.1.1-lifecycle/) |
| 3.1.2 | Moved Blocks for Refactoring | `moved { from to }` vs BLAKE3-keyed resource IDs | [`3.1.2-moved-blocks/`](3.1.2-moved-blocks/) |
| 3.1.3 | Resource Targeting | `terraform apply -target=` vs `forjar apply --recipe` | [`3.1.3-resource-targeting/`](3.1.3-resource-targeting/) |

## Run

```bash
make demo-3.1.1       # lifecycle blocks: prevent_destroy + create_before_destroy
make demo-3.1.2       # moved blocks: rename without re-creating
make demo-3.1.3       # resource targeting: partial applies, safely
```

## What you'll learn

- `lifecycle { prevent_destroy = true }` blocks accidental deletion of
  production resources; `create_before_destroy = true` flips the default
  replace order so the new resource boots before the old tears down.
- forjar's equivalent is idempotent recipes that re-converge to the declared
  end-state on every apply, with content-addressed outputs that prove the
  resource didn't change.
- Renaming a Terraform resource normally destroys and re-creates;
  `moved { from = ... to = ... }` tells Terraform it is a rename, not a delete.
- forjar handles renames through recipe composition: the resource ID is the
  BLAKE3 hash of its declaration, so a rename is a no-op if the body didn't
  change.
- `-target` lets you ship a config that wouldn't pass a full plan — drift
  accumulates between targeted-apply runs. `forjar apply --recipe` is the
  safe equivalent: it always runs that recipe's full DAG.
