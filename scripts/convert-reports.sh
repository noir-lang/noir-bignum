#!/usr/bin/env bash
set -e

input_file=$1
output_file_opcodes="benchmark-opcodes.json"
output_file_circuit="benchmark-circuit.json"
output_file_brillig="benchmark-brillig.json"

if [[ $input_file == *"gates_report.json"* ]]; then
    # Convert gates report - opcodes
    jq -r '[.programs[] | {
        "name": "\(.package_name)/main",
        "unit": "acir_opcodes",
        "value": (.functions[0].acir_opcodes // 0)
    }]' $input_file > $output_file_opcodes

    # Convert gates report - circuit size
    jq -r '[.programs[] | {
        "name": "\(.package_name)/main",
        "unit": "circuit_size",
        "value": (.functions[0].circuit_size // 0)
    }]' $input_file > $output_file_circuit

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
