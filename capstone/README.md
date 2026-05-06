# Capstone — Provisioning a Production ETL Stack with forjar

This directory is intentionally a stub. The capstone is a **Reading**
item in Module 5 of the Coursera course — start there. The reading
defines the four tasks, the acceptance criteria, and the rubric. This
directory is where your solution lives.

## What you commit here

By the end of the capstone you will have:

```
capstone/
├── README.md                # what you wrote: how to apply, how to verify,
│                            # which Postgres path you took, how this
│                            # exercises claims C1 and C5
├── forjar.yaml              # the production-shaped config that imports
│                            # the de-pipeline-host recipe + adds an
│                            # ETL binary install + logrotate config
├── recipes/
│   └── de-pipeline-host.yaml  # copy of (or symlink to) the Lab 5 recipe
└── state/
    ├── forjar.lock.yaml          # written by forjar apply
    └── forjar.inputs.lock.yaml   # written by forjar pin (commit this!)
```

The CI workflow at `.github/workflows/iac.yml` already runs
`forjar plan` and `forjar pin --check` on every PR. You do not author
that file from scratch — you extend it if you want extra gates (e.g.
the stretch-goal `cargo audit` job).

## The four capstone tasks (summary)

The Coursera reading is the source of truth. In short:

1. **Compose `de-pipeline-host` into a real `forjar.yaml`.** Concrete
   inputs (`postgres_version: "15"`, `etl_user: "de-pipeline"`,
   `data_dir: "/data/etl"`, `cron_schedule: "0 2 * * *"`) plus the
   Course 3 ETL binary install + logrotate.
2. **Pin every input via `forjar pin`.** Commit the resulting
   `state/forjar.inputs.lock.yaml`. Every input gets a BLAKE3 hash —
   this operationalizes claim **C1** (deterministic hashing).
3. **Wire `pin --check` as a required CI gate.** Open a PR that
   manually edits one BLAKE3 hash; CI fails. Open a follow-up that
   reverts; CI passes. Both PRs linked in the README — that's the
   evidence that the gate is functional, not ceremonial.
4. **Write the README that documents claims C1 and C5.** A short
   one-page README explaining the falsifiable-claims framing this
   artifact exercises. Required, not optional.

## Postgres path choice

The reading lets you pick:

- **Full path:** `package: postgresql` server install. ~18s first apply.
  Heavier; matches a real production target. Distinction-grade.
- **Lite path:** `package: postgresql-client`. Connect to a sidecar
  Postgres baked into the lab image. Lighter; matches the labs.

Document your choice in the README.

## Acceptance — the five-step checklist

A reviewer reads your README, then runs:

1. Clone your fork.
2. `cargo install forjar --version 1.3.0` (course-pinned).
3. `forjar apply -f capstone/forjar.yaml --yes` exits 0 within 60 s.
4. Re-apply reports `0 changes` (claim **C3**).
5. CI on a public PR branch shows `pin-check: PASS`. After manually
   editing one hash in the lock file, CI shows `pin-check: FAIL`.

If any step fails, the capstone is not done.

## Where to start

Read the Module 5 capstone reading on Coursera first. Re-read the
Lab 5 README for the recipe author you are reusing. Then start by
copying the Lab 5 reference solution into `capstone/forjar.yaml` and
extending it with the ETL binary install and the logrotate.

The path from "all five labs done" to "capstone done" is a half-day
of careful integration work — most of it spent on tasks 3 and 4
(the CI proof and the falsifiable-claims write-up). The forjar.yaml
itself is a 30-line composition.
