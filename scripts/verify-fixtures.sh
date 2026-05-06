#!/bin/bash
# Verify each lab's solution still produces its expected status / plan
# fixture. Run from the repo root: `make verify` calls this.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO=$(pwd)

verify_status() {
    local labname="$1"
    local expected="$REPO/labs/$labname/expected-status.json"
    if [ ! -f "$expected" ]; then return 0; fi
    pushd "labs/$labname/solution" > /dev/null
    forjar apply -f forjar.yaml --yes --force > /dev/null 2>&1
    forjar apply -f forjar.yaml --yes --force > /dev/null 2>&1
    forjar status --json --state-dir state \
      | jq -S 'del(.global.last_apply, .global.machines.localhost.last_apply,
                   .machines[].generated_at, .machines[].resources[].applied_at,
                   .machines[].resources[].duration_seconds,
                   .machines[].resources[].details.live_hash,
                   .machines[].generator, .global.generator,
                   .machines[].blake3_version)' > "/tmp/my-status-$labname.json"
    if diff -q <(jq -S . "$expected") "/tmp/my-status-$labname.json" > /dev/null; then
        echo "[verify] $labname status ✓"
    else
        echo "[verify] $labname status MISMATCH ✗"
        diff <(jq -S . "$expected") "/tmp/my-status-$labname.json"
        exit 1
    fi
    popd > /dev/null
}

verify_lab02_order() {
    pushd labs/lab-02-dag/solution > /dev/null
    forjar apply -f forjar.yaml --yes --force > /dev/null 2>&1
    forjar plan -f forjar.yaml --json | jq -S '.execution_order' \
      > /tmp/my-order.json
    if diff -q <(jq -S . "$REPO/labs/lab-02-dag/expected-execution-order.json") \
                /tmp/my-order.json > /dev/null; then
        echo "[verify] lab-02-dag execution-order ✓"
    else
        echo "[verify] lab-02-dag execution-order MISMATCH ✗"
        exit 1
    fi
    popd > /dev/null
}

verify_lab04_plan() {
    pushd labs/lab-04-plan-pin/solution > /dev/null
    forjar apply -f forjar.yaml --yes --force > /dev/null 2>&1
    forjar plan -f forjar.yaml --json --state-dir state \
      | jq -S '{name, unchanged, to_create, to_update, to_destroy,
                real_changes: (.changes | map(select(.action != "no_op")) | length)}' \
      > /tmp/my-plan.json
    if diff -q <(jq -S . "$REPO/labs/lab-04-plan-pin/expected-plan-shape.json") \
                /tmp/my-plan.json > /dev/null; then
        echo "[verify] lab-04-plan-pin plan-shape ✓"
    else
        echo "[verify] lab-04-plan-pin plan-shape MISMATCH ✗"
        exit 1
    fi
    popd > /dev/null
}

verify_lab05_plans() {
    pushd labs/lab-05-recipes/solution > /dev/null
    forjar apply -f de-dev.yaml --yes --force > /dev/null 2>&1
    forjar apply -f de-staging.yaml --yes --force > /dev/null 2>&1
    for stack in dev staging; do
        forjar plan -f de-$stack.yaml --json --state-dir state \
          | jq -S '{name, resources: (.changes | length)}' \
          > /tmp/my-$stack-plan.json
        if diff -q <(jq -S . "$REPO/labs/lab-05-recipes/expected-$stack-plan.json") \
                    /tmp/my-$stack-plan.json > /dev/null; then
            echo "[verify] lab-05-recipes $stack plan ✓"
        else
            echo "[verify] lab-05-recipes $stack plan MISMATCH ✗"
            exit 1
        fi
    done
    popd > /dev/null
}

echo "[verify] running fixture diffs against committed expected-*.json …"
verify_status lab-01-first-yaml
verify_status lab-03-drift
verify_lab02_order
verify_lab04_plan
verify_lab05_plans
echo "[verify] all fixtures match"
