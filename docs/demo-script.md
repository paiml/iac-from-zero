# Script — Hello, forjar: watch it heal

**Lesson:** the 30-second first impression of declarative IaC.
**Visual reference:** terminal screencast — one repo (`paiml/iac-from-zero`), one file, four contracts (C1, C3, C5, C10).
**Target length:** ~2 min.

## Demo (one terminal, one file — `hello/forjar.yaml`)

```bash
cd ~/src/iac-from-zero
```

```bash
cat hello/forjar.yaml
```
**The spec.** Two resources — one directory, one file. The file's `content:` block is the desired state. Nothing else exists.

```bash
cd hello && forjar apply -f forjar.yaml --yes
```
**2 converged.** Directory and file created from the spec. State written to `state/forjar.lock.yaml` as a BLAKE3 hash of the desired content.

```bash
forjar apply -f forjar.yaml --yes
```
**0 converged, 2 unchanged.** The lock hash matches the live file — second apply is a no-op. Claim **C3 (idempotent apply)**.

```bash
echo BROKEN > world/world.txt
```
**Vandalize.** A sysadmin SSH'd in and edited the file by hand. The classic IaC nightmare.

```bash
forjar drift -f forjar.yaml
```
**DRIFTED — Expected blake3:4c1c… / Actual blake3:9c51…**. Hash of desired vs hash of actual — claim **C1 (deterministic hashing)** + **C5 (content-addressed state)**. No cloud API poll, no metadata read — a single local hash compare.

```bash
forjar apply -f forjar.yaml --yes
```
**REFUSED. `error: 1 drift finding(s) block apply — use --force to override`.** Claim **C10 (jidoka)**: first failure stops execution. Forjar will not silently overwrite human edits.

```bash
forjar apply -f forjar.yaml --yes --force
```
**2 converged. File restored bit-for-bit.** The BLAKE3 hash from the lock is the source of truth; `--force` is the explicit "yes, I meant it" override.

## Close

One file, four contracts, ten seconds. The other 12 `m1-…m5-` demos are yours to explore — same Makefile, same gates, same claims, scaled up to canary fleets.

## Speaking notes

- Pace ~140 wpm. Let `BROKEN` linger on screen for a beat before running `forjar drift`.
- Pronunciation: forjar = "for-HAR" (Spanish, "to forge"); BLAKE3 = "blake three"; jidoka = "jee-DOH-ka".
- The whole demo runs in `hello/` so paths stay short on screen. State + world dir are gitignored.
- Shortcut: `make hello` from the repo root runs all 7 commands with colored step headers. Use that as a safety net if you fumble the heredoc.
- Land the close on the restored file content. No extra terminal output after it.

## Quickstart (one command)

```bash
make hello
```
Runs the entire demo above with `[1/6] … [6/6]` step headers and ends on `✓ HEALED — contracts C1, C3, C5, C10 all exercised`.
