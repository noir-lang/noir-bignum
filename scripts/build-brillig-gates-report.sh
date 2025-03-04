#!/usr/bin/env bash
set -e

INSPECTOR=${INSPECTOR:-noir-inspector}
cd $(dirname "$0")/../

artifacts_path="./export"
artifacts=$(ls $artifacts_path)

# Start the JSON array
echo "{\"programs\": [" > opcode_report.json

first=true
for artifact in $artifacts; do    
    ARTIFACT_NAME=$(basename "$artifact")
    # Remove .json extension from the name
    ARTIFACT_NAME_NO_EXT="${ARTIFACT_NAME%.json}"

    # Add comma before object if not first item
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> opcode_report.json
    fi

    # Get and format the opcode info
    OPT_CODE_INFO=$($INSPECTOR info --json "$artifacts_path/$artifact")
    
    # Simplified jq expression to output only package_name and total_unconstrained_opcodes
    echo "$(echo $OPT_CODE_INFO | jq --arg name "$ARTIFACT_NAME_NO_EXT" '{
        package_name: $name,
        total_unconstrained_opcodes: (
            if .programs then
                (.programs[] | 
                    if .unconstrained_functions then
                        (.unconstrained_functions | map(.opcodes) | add)
                    else 
                        0 
                    end
                )
            else 
                0 
            end
        )
    }')" >> opcode_report.json

done

# Close the JSON structure
echo "]}" >> opcode_report.json 
