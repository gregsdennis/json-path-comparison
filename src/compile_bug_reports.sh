#!/bin/bash
set -euo pipefail

readonly results_dir="$1"
readonly majority_dir="$2"
readonly consensus_dir="$3"
readonly implementation_dir="$4"

. src/shared.sh

all_queries() {
    find ./queries -type d -maxdepth 1 -mindepth 1 -print0 | xargs -0 -n1 basename | sort
}

indent_2() {
    sed 's/^/  /'
}

code_block() {
    echo "\`\`\`"
    cat
    echo "\`\`\`"
}

is_in_majority() {
    local query="$1"
    local implementation="$2"
    tail -n +4 < "${majority_dir}/${query}" | grep "^${implementation}\$" > /dev/null
}

has_consensus() {
    local query="$1"
    test -s "${consensus_dir}/${query}"
}

header() {
    echo "Results do not match other implementations

The following queries provide results that do not match those of other implementations of JSONPath
(compare https://cburgmer.github.io/json-path-comparison/):
"
}

footer() {
    local implementation="$1"

    echo
    echo "For reference, the output was generated by the program in https://github.com/cburgmer/json-path-comparison/tree/master/implementations/${implementation}."
}

unwrap_scalar_if_needed() {
    local query="$1"

    if [[ -f "./implementations/${implementation}/SINGLE_POSSIBLE_MATCH_RETURNED_AS_SCALAR" && -f "./queries/${query}/SCALAR_RESULT" ]]; then
        ./src/unwrap_scalar.py
    else
        cat
    fi
}

# https://github.com/cburgmer/json-path-comparison/issues/1
needs_workaround_for_unknown_scalar_consensus() {
    local query="$1"
    test -f "./implementations/${implementation}/SINGLE_POSSIBLE_MATCH_RETURNED_AS_SCALAR" \
        && test -f "./queries/${query}/SCALAR_RESULT" \
        && test "$(cat "${consensus_dir}/${query}")" == "[]"
}

failing_query() {
    local query="$1"
    local selector

    selector="$(cat "./queries/${query}/selector")"

    if needs_workaround_for_unknown_scalar_consensus "$query"; then
        return
    fi

    echo "- [ ] \`${selector}\`"
    {
        echo "Input:"
        ./src/oneliner_json.py < "./queries/${query}/document.json" | code_block
        if [[ -f "./queries/${query}/ALLOW_UNORDERED" ]]; then
            echo "Expected output (in any order as no consensus on ordering exists):"
        else
            echo "Expected output:"
        fi
        unwrap_scalar_if_needed "$query" < "${consensus_dir}/${query}" | ./src/oneliner_json.py | code_block

        if is_query_result_ok "${results_dir}/${query}/${implementation}"; then
            echo "Actual output:"
            query_result_payload "${results_dir}/${query}/${implementation}" | ./src/oneliner_json.py | code_block
        else
            echo "Error:"
            query_result_payload "${results_dir}/${query}/${implementation}" | code_block
        fi
    } | indent_2

    echo
}

process_implementation() {
    local implementation="$1"
    local query

    header

    while IFS= read -r query; do
        if has_consensus "$query" && ! is_in_majority "$query" "$implementation"; then
            failing_query "$query"
        fi
    done <<< "$(all_queries)"

    footer "$implementation"
}

main() {
    process_implementation "$(basename "$implementation_dir")"
}

main
