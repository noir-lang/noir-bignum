#!/usr/bin/env bash
set -e

INSPECTOR=${INSPECTOR:-noir-inspector}
cd $(dirname "$0")/../

artifacts_path="./export"
inputs_path="./benchmark-inputs"

# Generate inputs (each library provides its own generate-benchmark-inputs.sh)
./scripts/generate-benchmark-inputs.sh "$artifacts_path" "$inputs_path"

# Run execution profiling on each artifact
REPORTS=$(jq --null-input '[]')

# Known failures (skipped):
#   batch_invert_10_elements_{U256,U2048}: U256/U2048 have has_multiplicative_inverse=false
#   sqrt_{U256,U2048}: sqrt requires a prime field (asserts has_multiplicative_inverse)
#   to_field_BLS12_377Fr: validate_gt in limbs_to_field uses MOD_BITS=253 for range
#     checking the subtraction result, but GRUMPKIN_MODULUS[2]=0x3064 needs 14 bits
#     (see https://github.com/noir-lang/noir-bignum/issues/266)

for artifact in $(ls "$artifacts_path"/*.json 2>/dev/null); do
    name=$(basename "$artifact" .json)
    input_file="$inputs_path/${name}_input.json"

    if [ ! -f "$input_file" ]; then
        echo "Skipping $name (no input file)"
        continue
    fi

    echo "Profiling execution: $name"
    OP_CODE_INFO=$($INSPECTOR info --json --profile-execution \
        --input-file "$input_file" \
        "$artifact") || { echo "FAILED: $name"; continue; }

    REPORTS=$(echo "$OP_CODE_INFO" | jq -c '.programs[0] | del(.functions)' \
        | jq -c --argjson old_reports "$REPORTS" '$old_reports + [.]')
done

echo "$REPORTS" | jq '{ programs: . }' > brillig_execution_report.json

# Convert to benchmark-action format
jq -r '[.programs[] | .package_name as $pkg | .unconstrained_functions[] | {
    "name": (if ($pkg // "") == "" then .name else "\($pkg | sub("^null/"; ""))/\(.name)" end),
    "unit": "brillig_opcodes_executed",
    "value": (.opcodes // 0)
}]' brillig_execution_report.json > benchmark-brillig-execution.json

echo "Reports written: brillig_execution_report.json, benchmark-brillig-execution.json"
