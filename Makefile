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
TMPDIR := .tmp
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

help:
	@echo "IAC from Zero — companion repo"
	@echo ""
	@echo "Top-level targets:"
	@echo "  make install     install forjar from crates.io (cargo install forjar)"
	@echo "  make demo-all    run validate + plan + plan-json across all 12 demos (CI gate)"
	@echo "  make validate    forjar validate every demo"
	@echo "  make plan        forjar plan every demo"
	@echo "  make plan-json   forjar plan --json every demo (CI/CD policy gate format)"
	@echo "  make fmt         forjar fmt every demo (write changes)"
	@echo "  make lint        forjar lint every demo (read-only)"
	@echo "  make clean       remove state/ + .forjar/ + temp plan files"
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
	@( cd "$(1)" && $(FORJAR) plan     -f forjar.yaml --no-color ) > "$(CURDIR)/$(TMPDIR)/plan-$$(echo '$(1)' | tr '/' '-').txt"
	@( cd "$(1)" && $(FORJAR) plan     -f forjar.yaml --json )     > "$(CURDIR)/$(TMPDIR)/plan-$$(echo '$(1)' | tr '/' '-').json"
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

clean:
	@for d in $(DEMOS); do \
	  rm -rf "$$d/state" "$$d/.forjar" || exit 1; \
	done
	@rm -rf "$(TMPDIR)"
	@echo "cleaned state/, .forjar/, $(TMPDIR)/"
