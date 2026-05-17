# Script — Capstone: Canary Deployment Fleet

**Lesson:** 5.1.3-capstone-canary-fleet
**Visual reference:** terminal screencast — one repo (`paiml/iac-from-zero`), one canary fleet, ten falsifiable claims.
**Target length:** ~3 min.

## Demo (one terminal, one Makefile — `paiml/iac-from-zero`)

```bash
cd ~/src/iac-from-zero
```

```bash
wc -l m5-testing-security/5.1.3-capstone-canary-fleet/{forjar.yaml,main.tf}
```
**The diff IS the lesson.** ~200 lines of YAML next to ~140 lines of HCL — same canary topology, two DSLs, side-by-side.

```bash
make demo-m5-testing-security/5.1.3-capstone-canary-fleet
```
**Forjar validate + plan + plan-json, one command.** No hosts touched.

```bash
jq -r '.execution_order[]' .tmp/plan-m5-testing-security-5.1.3-capstone-canary-fleet.json
```
**Seven-resource DAG.** `deploy-dir → blue-config → green-config → nginx-backend → health-gate → traffic-switch → rollback-script`. Same input always yields this order — claim **C2 (deterministic DAG)**.

```bash
make tofu-validate
```
**OpenTofu half passes too.** Same canary topology in HCL — no cloud creds, no `apply`, just the static-analysis gate across all 12 demos.

```bash
make verify
```
**Six committed lab fixtures, all match.** `forjar status --json` against the snapshot the course was authored against — claim **C1 (deterministic hashing)** and **C5 (content-addressed state)** asserted live.

```bash
make demo-all
```
**Twelve demos, under a second.** Same command CI runs. Local box and `green main` agree byte-for-byte.

## Close

The canary fleet is the lesson; the gate is the proof. Same Makefile, same JSON, same C1–C10 contracts — local box, CI runner, production cluster.

## Speaking notes

- Pace ~140 wpm. Let the green "ALL 12 DEMOS PASSED" hold for a beat.
- Pronunciation: forjar = "for-HAR" (Spanish, "to forge"); BLAKE3 = "blake three"; jidoka = "jee-DOH-ka"; OpenTofu = "open-TOH-foo".
- Do NOT `apply` on stream — recipe 94 wants Docker + bound ports. `make demo-all` is plan-only by design: every claim is asserted before any host is touched.
- C3 (idempotent apply) is NOT demonstrated by `make demo-all` alone (no apply runs). If you want to show C3, opt in to `make apply-m5-...` on a Docker host, then re-apply — `actual_changes=0 forced_noop_count=7` is the C3 read-out (forjar 1.4.2+).
- Land the close on the green banner. No extra terminal output after it.
