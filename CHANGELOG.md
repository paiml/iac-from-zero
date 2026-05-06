# Changelog

All notable changes to this companion repo are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `labs/lab-01-first-yaml/` — Module 1 lab: write your first `forjar.yaml`,
  apply it twice, observe `0 changes` (claim **C3**)
- `labs/lab-02-dag/` — Module 2 lab: declare `depends_on`, observe the DAG
  resolver, deliberately introduce a cycle (claim **C4**)
- `labs/lab-03-drift/` — Module 3 lab: break a resource outside forjar,
  detect with `forjar drift`, reconverge (claims **C5**, **C6**, **C10**)
- `labs/lab-04-plan-pin/` — Module 4 lab: JSON plans, moved blocks,
  `forjar pin` and the manual lock-edit failure mode (claim **C1**)
- `labs/lab-05-recipes/` — Module 5 lab: author the `de-pipeline-host`
  recipe with typed inputs and compose two stacks (claim **C7**)
- `recipes/de-pipeline-host.yaml` — the recipe Lab 5 produces; reused by
  the capstone
- `capstone/` — stub directory pointing at the Coursera capstone reading;
  students extend this in their fork
- `.github/workflows/iac.yml` — gate workflow that runs `forjar validate`,
  `forjar plan`, and `forjar pin --check` on every PR
- `assets/hero.{svg,png}` — README banner matching the sibling repos'
  oxide-premium chassis

## [0.1.0] - 2026-05-06

Initial public release. Companion repo for the Coursera course
**IaC From Zero**, sibling to `paiml/postgres-from-zero`,
`paiml/duckdb-from-zero`, and `paiml/mysql-from-zero`.
