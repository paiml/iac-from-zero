# M5 — Testing, Security, and a Capstone Fleet

The closing module. Terraform's `.tftest.hcl` files give infrastructure configs
a real test DSL; OpenTofu 1.7's `state_encryption` block protects state at
rest. forjar's equivalents are `plan-test` mode (unit tests on the YAML diff)
and content-addressed signing (state-integrity end to end). The capstone
deploys a real canary fleet via cookbook recipe 94 and asserts all 10
falsifiable forjar claims against it live.

## Lessons

| Video | Title | Comparison | Demo |
|---|---|---|---|
| 5.1.1 | Testing IAC Configs | `.tftest.hcl` vs `forjar plan-test` | [`5.1.1-testing-dsl/`](5.1.1-testing-dsl/) |
| 5.1.2 | State Encryption | `state_encryption {}` vs content-addressed signing | [`5.1.2-state-encryption/`](5.1.2-state-encryption/) |
| 5.1.3 | Capstone — Canary Deployment Fleet | full recipe 94 fleet, all 10 contracts asserted (live demo) | [`5.1.3-capstone-canary-fleet/`](5.1.3-capstone-canary-fleet/) |

## Run

```bash
make demo-5.1.1       # testing DSL: .tftest.hcl vs forjar plan-test
make demo-5.1.2       # state encryption: AES-GCM at rest vs signed BLAKE3 state
make demo-5.1.3       # capstone: canary fleet + all 10 contracts asserted live
```

The capstone demo (`5.1.3`) is the only one that runs a full apply by default
— it provisions a primary + canary host, rolls the canary, and runs the
assertion suite.

## What you'll learn

- Terraform's `.tftest.hcl` files declare assertions on plan and apply outputs
  — a real test DSL for infrastructure configs.
- forjar's `plan-test` mode runs the DAG resolution and asserts on the YAML
  diff without touching real hosts — the unit-test layer of IAC.
- OpenTofu 1.7's `state_encryption` block encrypts the JSON state file at
  rest with AES-GCM; forjar's BLAKE3 store is content-addressed and recipe
  outputs are signed.
- The threat-model difference: Terraform protects state-at-rest; forjar
  protects state-integrity end to end — no signature, no apply.
- The capstone proves the workflow end to end: `forjar plan` shows the DAG,
  `forjar apply` rolls the canary, and the assertion run proves all 10
  falsifiable claims hold against the live fleet.
