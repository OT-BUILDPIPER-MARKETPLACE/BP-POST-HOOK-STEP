#!/bin/bash

# Source common functions
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/str-functions.sh
source /opt/buildpiper/shell-functions/file-functions.sh
source /opt/buildpiper/shell-functions/aws-functions.sh

# Enable Debugging if required
if [ "$DEBUG" = true ]; then
  set -x
fi

export POST_HOOK_CMD=$(getPostHookCommand)


CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"
logInfoMessage "I'll $INSTRUCTION_TYPE the code available at [$CODEBASE_LOCATION]"
sleep  $SLEEP_DURATION

cd "${CODEBASE_LOCATION}" || { logErrorMessage "Failed to change directory to $CODEBASE_LOCATION"; exit 1; }

#######################################################

if [ -z "$POST_HOOK_CMD" ]; then
    logInfoMessage "No post-hook commands found."
else
    echo "$POST_HOOK_CMD" | while IFS= read -r cmd; do
        if [ -n "$cmd" ]; then
            logInfoMessage "Running: $cmd"
            eval "$cmd" || logErrorMessage "Command failed: $cmd (continuing...)"
        fi
    done
fi


TASK_STATUS=$?
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}


