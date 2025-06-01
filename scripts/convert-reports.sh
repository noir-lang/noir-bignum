#!/usr/bin/env bash
set -e

input_file=$1
output_file_gates="benchmark-gates.json"
output_file_brillig="benchmark-brillig.json"

if [[ $input_file == *"gates_report.json"* ]]; then
    # Convert gates report
    jq -r '[.programs[] | {
        "name": "\(.package_name)/main/acir_opcodes",
        "unit": "acir_opcodes",
        "value": (.functions[0].acir_opcodes // 0)
    }, {
        "name": "\(.package_name)/main/circuit_size",
        "unit": "circuit_size",
        "value": (.functions[0].circuit_size // 0)
    }]' $input_file > $output_file_gates

elif [[ $input_file == *"brillig_report.json"* ]]; then
    # Convert brillig report
    jq -r '[.programs[] | .unconstrained_functions[] | {
        "name": (if (.package_name // "") == "" then .name else "\(.package_name | sub("^null/"; ""))/\(.name)" end),
        "unit": "opcodes",
        "value": (.opcodes // 0)
    }]' $input_file > $output_file_brillig

else
    echo "Error: Input file must be either gates_report.json or brillig_report.json"
    exit 1
fi
