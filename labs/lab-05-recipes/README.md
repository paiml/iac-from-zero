# Lab 5 — Author one recipe, compose a stack

> Module 5: Recipes, composition & CI gates. Anchors on cookbook recipes
> **#53 `stack-dev-server`** and **#57 `stack-package-pipeline`** as
> read-only references; you author your own `de-pipeline-host`.

## Goal

Author a parameterized recipe with typed inputs, then compose two stacks
that instantiate it with different inputs. Demonstrates claim **C7**
(recipe input validation): typed inputs fail at parse time when missing
or of the wrong type.

## What you write

```
labs/lab-05-recipes/
├── recipes/
│   └── de-pipeline-host.yaml   # the recipe — typed inputs, 5 resources
├── de-dev.yaml                 # composing stack: small, hourly schedule
└── de-staging.yaml             # composing stack: bigger, nightly schedule
```

The recipe's input contract is the playbook spec:

| Input              | Type   | Default        | Notes                          |
|--------------------|--------|----------------|--------------------------------|
| `postgres_version` | string | (required)     | Major version, e.g. `"15"`     |
| `etl_user`         | string | (required)     | System user owning data dir    |
| `data_dir`         | string | `/data`        | Root data directory            |
| `cron_schedule`    | string | `"0 2 * * *"`  | Cron expression for the ETL    |

Inside the recipe, refer to inputs as `{{inputs.<key>}}`, not
`{{params.<key>}}`. Inputs are recipe-local; params are global.

## Run it

```bash
forjar validate -f de-dev.yaml
forjar validate -f de-staging.yaml

forjar plan -f de-dev.yaml --json | jq '.changes | length'
# → 5 (the recipe's 5 resources)
forjar plan -f de-staging.yaml --json | jq '.changes | length'
# → 6 (recipe's 5 + the staging-only archive-dir)

forjar apply -f de-dev.yaml --yes      # → 5 converged
forjar apply -f de-dev.yaml --yes      # → 0 converged, 5 unchanged
forjar apply -f de-staging.yaml --yes  # → 6 converged
forjar apply -f de-staging.yaml --yes  # → 0 converged, 6 unchanged
```

The two stacks share *the same recipe* but produce *different infrastructure*
because they pass different inputs. That's the whole point of recipes — fix
the bug once, every consumer gets the fix on next pin.

## CI gate (claim C5 + C7)

Add `.github/workflows/iac.yml` (or extend the existing one) so that:

1. `forjar validate -f de-dev.yaml` runs on every PR and must pass
2. `forjar validate -f de-staging.yaml` runs on every PR and must pass
3. `forjar pin --check` runs on both and must pass

The repo's top-level `.github/workflows/iac.yml` already has this wired —
look at it for the gate-aggregator pattern (claim that the org's
`Green Main` branch ruleset keys off of).

## Self-check

```bash
forjar plan -f de-dev.yaml --json --state-dir state \
  | jq -S '{name, resources: (.changes | length)}' > my-dev-plan.json
forjar plan -f de-staging.yaml --json --state-dir state \
  | jq -S '{name, resources: (.changes | length)}' > my-staging-plan.json

diff <(jq -S . expected-dev-plan.json) my-dev-plan.json
diff <(jq -S . expected-staging-plan.json) my-staging-plan.json
```

Empty diffs = pass.

## Why recipes kill copy-paste

The cookbook's failure-story for this module: five teams each wrote the
same `nginx-with-tls` config; three of them carried the same off-by-one
TLS cipher mistake from a 2019 Stack Overflow answer; when CVE-2024-X
hit, four teams patched, one didn't notice for six weeks.

A recipe is one place to fix that bug. Every composing stack picks up
the fix on next `forjar pin`. Inputs make it parameterizable without
forking. Typed inputs catch wrong-shape calls at parse time. The
composability category (#53–61) of the cookbook shows what this looks
like at production scale.

## Reference solution

`solution/recipes/de-pipeline-host.yaml`, `solution/de-dev.yaml`,
`solution/de-staging.yaml` — the reference. Don't peek before finishing.
