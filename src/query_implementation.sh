#!/bin/bash
set -euo pipefail

wrap_scalar_if_needed() {
    local implementation="$1"
    local query="$2"

    if [[ -f "${implementation}/SINGLE_POSSIBLE_MATCH_RETURNED_AS_SCALAR" && -f "${query}/SCALAR_RESULT" ]]; then
        ./src/wrap_scalar.py
    else
        cat
    fi
}

fail_on_absolute_paths_leaked() {
    # Absolute paths will make it hard to provide a reproducible outcome
    # Best way to avoid them in most languages is to catch exceptions and
    # print a simple error instead.
    local file="$1"
    if grep '/home\|/Users\|/usr' < "$file" > /dev/null; then
        echo "This error message includes an absolute path which will make it hard to reproduce on other machines."
        echo "Please change the script to error without it."
        echo
        cat "$file"
        exit 1
    fi
}

run_query() {
    local query="$1"
    local implementation="$2"
    local selector_file="$query"/selector
    local document="$query"/document.json
    local selector
    selector="$(cat "${selector_file}")"

    "$implementation"/run.sh "$selector" < "$document" | wrap_scalar_if_needed "$implementation" "$query"
}

main() {
    local query="$1"
    local implementation="$2"
    local tmp_stdout="/tmp/query_implementation.stdout.$$"
    local tmp_stderr="/tmp/query_implementation.stderr.$$"

    if run_query "$query" "$implementation" > "$tmp_stdout" 2> "$tmp_stderr"; then
        echo "OK"

        ./src/canonical_json.py < "$tmp_stdout"
    else
        echo "ERROR"

        fail_on_absolute_paths_leaked "$tmp_stderr"
        fail_on_absolute_paths_leaked "$tmp_stdout"
        # Some implementations don't report errors on stderr
        cat "$tmp_stderr"
        cat "$tmp_stdout"
    fi

    rm "$tmp_stdout"
    rm "$tmp_stderr"
}

main "$@"