#!/usr/bin/env bash
set -e

# Generate JSON input files for noir-inspector --profile-execution from
# compiled artifact ABIs.  Each library can replace this script with its
# own input-generation logic.
#
# Usage: ./scripts/generate-benchmark-inputs.sh [artifacts_dir] [output_dir]

cd $(dirname "$0")/../

artifacts_path="${1:-./export}"
inputs_path="${2:-./benchmark-inputs}"
mkdir -p "$inputs_path"

# jq function that recursively generates a valid input value from an ABI type.
# `seed` controls the base value: different seeds yield distinct values so that
# e.g. a != b for assert_is_not_equal and b != 0 for division.
#
# For integer arrays (BigNum limbs, byte arrays) only the first element carries
# the seed value; the rest are zero.  This keeps BigNum values small and safely
# within any field modulus.
JQ_GEN='
def gen(seed):
  if .kind == "field" then (seed | tostring)
  elif .kind == "boolean" then false
  elif .kind == "integer" then
    if .width <= 8 then (seed % 256) else (seed | tostring) end
  elif .kind == "array" then
    .type as $elem | .length as $len |
    if $elem.kind == "integer" then
      [$elem | gen(seed)] + [range($len - 1) | $elem | gen(0)]
    else
      [range($len) | $elem | gen(seed)]
    end
  elif .kind == "struct" then
    [.fields[] | {key: .name, value: (.type | gen(seed))}] | from_entries
  else (seed | tostring)
  end;
'

count=0
for artifact in $(ls "$artifacts_path"/*.json 2>/dev/null); do
    name=$(basename "$artifact" .json)
    input_file="$inputs_path/${name}_input.json"

    # evaluate_quadratic_expression requires sum(lhs*rhs) + add = 0 mod p.
    # All-zero BigNums satisfy this trivially.
    if echo "$name" | grep -q "evaluate_quadratic_expression"; then
        jq "$JQ_GEN"'
          [.abi.parameters | to_entries[] |
            {key: .value.name, value: (.value.type | gen(0))}
          ] | from_entries
        ' "$artifact" > "$input_file"
    else
        jq "$JQ_GEN"'
          [.abi.parameters | to_entries[] |
            (.key + 1) as $seed |
            {key: .value.name, value: (.value.type | gen($seed))}
          ] | from_entries
        ' "$artifact" > "$input_file"
    fi

    count=$((count + 1))
done

echo "Generated $count input files in $inputs_path"
