.PHONY: help validate plan apply lab1 lab2 lab3 lab4 lab5 demo verify clean

FORJAR := forjar
LABS := lab-01-first-yaml lab-02-dag lab-03-drift lab-04-plan-pin lab-05-recipes

help:
	@echo "IaC From Zero — companion repo"
	@echo ""
	@echo "  make validate  — forjar validate every lab solution + the recipe"
	@echo "  make plan      — forjar plan every lab solution (no apply)"
	@echo "  make demo      — apply lab-01-first-yaml then re-apply (claim C3)"
	@echo "  make verify    — diff each lab's status against expected-status.json"
	@echo "  make lab1 .. lab5 — apply a specific lab's solution config"
	@echo "  make clean     — remove ephemeral state under labs/*/solution/state/"

validate:
	@for lab in lab-01-first-yaml lab-02-dag lab-03-drift lab-04-plan-pin; do \
		echo "=== validate $$lab ==="; \
		$(FORJAR) validate -f labs/$$lab/solution/forjar.yaml || exit 1; \
	done
	@echo "=== validate lab-05-recipes (de-dev + de-staging) ==="
	@$(FORJAR) validate -f labs/lab-05-recipes/solution/de-dev.yaml
	@$(FORJAR) validate -f labs/lab-05-recipes/solution/de-staging.yaml

plan:
	@for lab in lab-01-first-yaml lab-02-dag lab-03-drift lab-04-plan-pin; do \
		echo "=== plan $$lab ==="; \
		$(FORJAR) plan -f labs/$$lab/solution/forjar.yaml \
		  --state-dir labs/$$lab/solution/state || exit 1; \
	done
	@echo "=== plan lab-05-recipes (de-dev + de-staging) ==="
	@$(FORJAR) plan -f labs/lab-05-recipes/solution/de-dev.yaml \
	  --state-dir labs/lab-05-recipes/solution/state
	@$(FORJAR) plan -f labs/lab-05-recipes/solution/de-staging.yaml \
	  --state-dir labs/lab-05-recipes/solution/state

demo: lab1

lab1:
	@cd labs/lab-01-first-yaml/solution && $(FORJAR) apply -f forjar.yaml
	@echo ""
	@echo "--- second apply (claim C3: idempotent — expect 0 changes) ---"
	@cd labs/lab-01-first-yaml/solution && $(FORJAR) apply -f forjar.yaml

lab2:
	@cd labs/lab-02-dag/solution && $(FORJAR) plan -f forjar.yaml --json | jq '.execution_order'

lab3:
	@cd labs/lab-03-drift/solution && $(FORJAR) drift -f forjar.yaml || true

lab4:
	@cd labs/lab-04-plan-pin/solution && $(FORJAR) pin -f forjar.yaml

lab5:
	@cd labs/lab-05-recipes/solution && $(FORJAR) plan -f de-dev.yaml --json | jq '.changes | length'
	@cd labs/lab-05-recipes/solution && $(FORJAR) plan -f de-staging.yaml --json | jq '.changes | length'

verify:
	@bash scripts/verify-fixtures.sh

clean:
	@for lab in $(LABS); do \
		rm -rf labs/$$lab/solution/state/forjar.lock.yaml \
		       labs/$$lab/solution/state/events; \
	done
	@echo "ephemeral state removed (lock files kept where committed)"
