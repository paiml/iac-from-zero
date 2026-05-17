# IAC from Zero — companion repo Makefile
#
# Every demo target runs the full forjar lifecycle that's safe on the
# studio box (validate + plan + plan --json). `make apply-<id>` opts
# into a real apply, which most demos pin to container transport so they
# require Docker on PATH.
#
# Run `make demo-all` for the CI gate.
# Lint: `bashrs make lint Makefile` — clean (0 errors, 0 warnings).

.SUFFIXES:
.DELETE_ON_ERROR:
.ONESHELL:

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

FORJAR ?= forjar
TOFU ?= tofu
TMPDIR := .tmp
# Placeholder for tofu validate of the m5 state-encryption demo, which
# references a `var.state_passphrase` at init time. The value is never
# applied to real state — it just satisfies tofu's static-analysis pass.
TF_VAR_state_passphrase ?= placeholder-for-validation-only-32chars
export TF_VAR_state_passphrase

DEMOS := \
	m1-first-apply \
	m2-state-and-plan/2.1.2-saved-plan \
	m2-state-and-plan/2.1.3-json-plan \
	m3-lifecycle/3.1.1-lifecycle \
	m3-lifecycle/3.1.2-moved-blocks \
	m3-lifecycle/3.1.3-resource-targeting \
	m4-drift/4.1.1-refresh-only \
	m4-drift/4.1.2-check-blocks \
	m4-drift/4.1.3-cross-config \
	m5-testing-security/5.1.1-testing-dsl \
	m5-testing-security/5.1.2-state-encryption \
	m5-testing-security/5.1.3-capstone-canary-fleet

.PHONY: help install demo-all validate plan plan-json fmt lint clean
.PHONY: tofu-validate tofu-fmt verify hello hello-clean

help:
	@echo "IAC from Zero — companion repo"
	@echo ""
	@echo "Hello-world (30-second first impression):"
	@echo "  make hello          apply → vandalize → drift → apply-force → restore"
	@echo "                      exercises C1 + C3 + C5 + C10 contracts"
	@echo ""
	@echo "Top-level targets (forjar side):"
	@echo "  make install        install forjar from crates.io"
	@echo "  make demo-all       forjar validate + plan + plan-json across all 12 demos (CI gate)"
	@echo "  make validate       forjar validate every demo"
	@echo "  make plan           forjar plan every demo"
	@echo "  make plan-json      forjar plan --json every demo"
	@echo "  make fmt            forjar fmt every demo (write changes)"
	@echo "  make lint           forjar lint every demo (read-only)"
	@echo "  make clean          remove state/ + .forjar/ + .terraform/ + .tmp/"
	@echo ""
	@echo "Top-level targets (OpenTofu/Terraform side):"
	@echo "  make tofu-validate  tofu init -backend=false + tofu validate per main.tf"
	@echo "  make tofu-fmt       tofu fmt -check every main.tf (no writes)"
	@echo ""
	@echo "Lab fixtures (in labs/):"
	@echo "  make verify         scripts/verify-fixtures.sh — diff lab solutions against expected-*.json"
	@echo ""
	@echo "Per-demo targets (one per directory):"
	@for d in $(DEMOS); do echo "  make demo-$$d"; done

install:
	cargo install forjar --locked || exit 1

# ---- per-demo recipes ----
# `demo-<dir>` runs validate → plan → plan-json on one directory.
# Output is grouped so a CI failure points at the right demo.

define DEMO_template
demo-$(1):
	@mkdir -p "$(TMPDIR)"
	@printf '\n\033[1;36m=== demo-$(1) ===\033[0m\n'
	@( cd "$(1)" && $(FORJAR) validate -f forjar.yaml )
	@( cd "$(1)" && $(FORJAR) plan     -f forjar.yaml --no-color ) > "$(CURDIR)/$(TMPDIR)/plan-$$$$(echo '$(1)' | tr '/' '-').txt"
	@( cd "$(1)" && $(FORJAR) plan     -f forjar.yaml --json )     > "$(CURDIR)/$(TMPDIR)/plan-$$$$(echo '$(1)' | tr '/' '-').json"
	@printf '\033[1;32m✓ demo-$(1)\033[0m  validate + plan + plan-json clean\n'
endef

$(foreach d,$(DEMOS),$(eval $(call DEMO_template,$(d))))

# ---- aggregate gates ----
# demo-all runs each demo inline (no recursive make) so the lint stays
# clean. Per-demo targets (`make demo-<dir>`) are still available via
# the DEMO_template-generated rules above.

demo-all:
	@mkdir -p "$(TMPDIR)"
	@for d in $(DEMOS); do \
	  printf '\n\033[1;36m=== demo-%s ===\033[0m\n' "$$d"; \
	  ( cd "$$d" && $(FORJAR) validate -f forjar.yaml ) || exit 1; \
	  ( cd "$$d" && $(FORJAR) plan -f forjar.yaml --no-color > "$(CURDIR)/$(TMPDIR)/plan-$$(echo "$$d" | tr '/' '-').txt" ) || exit 1; \
	  ( cd "$$d" && $(FORJAR) plan -f forjar.yaml --json     > "$(CURDIR)/$(TMPDIR)/plan-$$(echo "$$d" | tr '/' '-').json" ) || exit 1; \
	  printf '\033[1;32m✓ demo-%s\033[0m  validate + plan + plan-json clean\n' "$$d"; \
	done
	@printf '\n\033[1;32m=== ALL 12 DEMOS PASSED ===\033[0m\n'

validate:
	@for d in $(DEMOS); do \
	  printf '  validate %s ... ' $$d; \
	  (cd $$d && $(FORJAR) validate -f forjar.yaml >/dev/null) && echo OK || { echo FAIL; exit 1; }; \
	done

plan:
	@for d in $(DEMOS); do \
	  printf '\n=== plan %s ===\n' $$d; \
	  (cd $$d && $(FORJAR) plan -f forjar.yaml --no-color); \
	done

plan-json:
	@for d in $(DEMOS); do \
	  printf '  plan --json %s ... ' $$d; \
	  (cd $$d && $(FORJAR) plan -f forjar.yaml --json >/dev/null) && echo OK || { echo FAIL; exit 1; }; \
	done

fmt:
	@for d in $(DEMOS); do \
	  (cd $$d && $(FORJAR) fmt -f forjar.yaml) || true; \
	done

lint:
	@for d in $(DEMOS); do \
	  printf '  lint %s\n' $$d; \
	  (cd $$d && $(FORJAR) lint -f forjar.yaml --no-color) || true; \
	done

# ---- opt-in apply targets (require Docker) ----
# `make apply-<dir>` actually converges the demo's container target.
# Not part of demo-all; opt-in only.

define APPLY_template
apply-$(1):
	@printf '\n\033[1;33m=== apply-$(1) (this converges a real container) ===\033[0m\n'
	@( cd "$(1)" && $(FORJAR) apply -f forjar.yaml --no-color )
endef

$(foreach d,$(DEMOS),$(eval $(call APPLY_template,$(d))))

clean: hello-clean
	@for d in $(DEMOS); do \
	  rm -rf "$$d/state" "$$d/.forjar" "$$d/.terraform" || exit 1; \
	  rm -f  "$$d/.terraform.lock.hcl" || exit 1; \
	done
	@rm -rf "$(TMPDIR)"
	@echo "cleaned state/, .forjar/, .terraform/, $(TMPDIR)/, hello/world+state/"

# ---- OpenTofu / Terraform validation gate ----
# `tofu init -backend=false` downloads providers without connecting to
# a real backend, so it works in CI without cloud credentials. Then
# `tofu validate` does the static-analysis pass.

tofu-validate:
	@command -v $(TOFU) >/dev/null 2>&1 || { \
	  printf '\033[1;33m⚠  %s not on PATH — install OpenTofu (https://opentofu.org/docs/intro/install/) to run this target\033[0m\n' "$(TOFU)"; \
	  exit 1; \
	}
	@for d in $(DEMOS); do \
	  printf '  tofu validate %s ... ' "$$d"; \
	  ( cd "$$d" && $(TOFU) init -backend=false -no-color >/dev/null && $(TOFU) validate -no-color >/dev/null ) && echo OK || { echo FAIL; exit 1; }; \
	done

tofu-fmt:
	@command -v $(TOFU) >/dev/null 2>&1 || { \
	  printf '\033[1;33m⚠  %s not on PATH — install OpenTofu to run this target\033[0m\n' "$(TOFU)"; \
	  exit 1; \
	}
	@for d in $(DEMOS); do \
	  printf '  tofu fmt -check %s ... ' "$$d"; \
	  ( cd "$$d" && $(TOFU) fmt -check -no-color >/dev/null ) && echo OK || { echo "FAIL (run \`tofu fmt $$d\` to fix)"; exit 1; }; \
	done

# ---- Lab fixture verification ----
# `scripts/verify-fixtures.sh` diffs each lab solution's
# `forjar status --json` against its committed `expected-*.json`.

verify:
	@bash scripts/verify-fixtures.sh

# ---- Hello world ----
# 30-second demo that exercises the heart of forjar's contract bundle:
#   1. forjar apply               → file created from desired state
#   2. forjar apply (again)       → 0 converged, 2 unchanged   (C3 idempotent apply)
#   3. echo BROKEN > file         → simulate sysadmin tampering
#   4. forjar drift               → reports BLAKE3 hash mismatch (C1 + C5)
#   5. forjar apply (no --force)  → BLOCKED by drift gate        (C10 jidoka)
#   6. forjar apply --force       → file restored bit-for-bit
# Per-step state lands in hello/state/ + hello/world/, both gitignored.

hello: hello-clean
	@printf '\n\033[1;36m═══ HELLO FORJAR — watch it heal ═══\033[0m\n\n'
	@printf '\033[1;33m[1/6]\033[0m forjar apply (create world.txt)\n'
	@( cd hello && $(FORJAR) apply -f forjar.yaml --yes --no-color | tail -3 )
	@printf '\n\033[1;33m[2/6]\033[0m forjar apply AGAIN — expect 0 converged, 2 unchanged (C3 idempotent)\n'
	@( cd hello && $(FORJAR) apply -f forjar.yaml --yes --no-color | tail -3 )
	@printf '\n\033[1;33m[3/6]\033[0m vandalize: echo BROKEN > hello/world/world.txt\n'
	@echo BROKEN > hello/world/world.txt
	@printf '         hello/world/world.txt now: '
	@head -1 hello/world/world.txt
	@printf '\n\033[1;33m[4/6]\033[0m forjar drift — BLAKE3 hash mismatch (C1 deterministic hash + C5 content-addressed)\n'
	@( cd hello && $(FORJAR) drift -f forjar.yaml --no-color | head -8 ) || true
	@printf '\n\033[1;33m[5/6]\033[0m forjar apply without --force — REFUSED (C10 jidoka: drift blocks apply)\n'
	@( cd hello && $(FORJAR) apply -f forjar.yaml --yes --no-color 2>&1 | tail -3 ) || true
	@printf '\n\033[1;33m[6/6]\033[0m forjar apply --force — heals from desired state\n'
	@( cd hello && $(FORJAR) apply -f forjar.yaml --yes --force --no-color | tail -3 )
	@printf '         hello/world/world.txt now: '
	@head -1 hello/world/world.txt
	@printf '\n\033[1;32m✓ HEALED — contracts C1, C3, C5, C10 all exercised in one make target\033[0m\n'

hello-clean:
	@rm -rf hello/world hello/state hello/forjar.lock.yaml hello/forjar.lock.yaml.b3
