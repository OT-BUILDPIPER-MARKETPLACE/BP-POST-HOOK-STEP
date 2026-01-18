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

case "$ACTION" in
  build)
    POST_HOOK_CMD=$(getPostHookBuildCommand)
    logInfoMessage "Selected action: $ACTION"
    ;;
  deploy)
    POST_HOOK_CMD=$(getPostHookDeployCommand)
    logInfoMessage "Selected action: $ACTION"
    ;;
  *)
    logInfoMessage "Usage: {build|deploy}"
    ;;
esac

if [ -z "$PRE_HOOK_CMD" ]; then
  logInfoMessage "No PRE_HOOKS found"
  exit 1
fi

MASKED_CMD="$POST_HOOK_CMD"
MASKED_CMD=$(echo "$MASKED_CMD" | sed -E 's/(AWS|DB|TOKEN|PASSWORD|PASS|SECRET|KEY|CRED|AUTH|PRIVATE|FERNET|ACCESS|SESSION)=([^ ]+)/\1=****/Ig')
MASKED_CMD=$(echo "$MASKED_CMD" | sed -E 's/(export[[:space:]]+[^=]+=)[^ ]+/\1****/Ig')

logInfoMessage "POST_HOOK_CMD is: $MASKED_CMD"


CODEBASE_LOCATION="${WORKSPACE}/${CODEBASE_DIR}"
logInfoMessage "I'll ${INSTRUCTION_TYPE} the code available at [$CODEBASE_LOCATION]"
sleep "${SLEEP_DURATION}"

cd "${CODEBASE_LOCATION}" || {
  logErrorMessage "Failed to change directory to $CODEBASE_LOCATION"
  exit 1
}


echo "$POST_HOOK_CMD" | while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue

  # Mask command for logging
  SAFE_LOG_CMD=$(echo "$cmd" | sed -E 's/(AWS|DB|TOKEN|PASSWORD|PASS|SECRET|KEY|CRED|AUTH|PRIVATE|FERNET|ACCESS|SESSION)=([^ ]+)/\1=****/Ig')
  SAFE_LOG_CMD=$(echo "$SAFE_LOG_CMD" | sed -E 's/(export[[:space:]]+[^=]+=)[^ ]+/\1****/Ig')

  logInfoMessage "Running sanitized command: $SAFE_LOG_CMD"


  IFS=';&' read -ra CMD_PARTS <<< "$cmd"

  for part in "${CMD_PARTS[@]}"; do
    clean_cmd=$(echo "$part" | xargs)
    [ -z "$clean_cmd" ] && continue


    if [[ "$clean_cmd" == "env" ]]; then
      logInfoMessage "Executing env with sensitive variables masked"

      env | sed -E '
        s/(AWS|DB|TOKEN|PASSWORD|PASS|SECRET|KEY|CRED|AUTH|PRIVATE|FERNET|ACCESS|SESSION)=.*/\1=****/Ig
      '
      TASK_STATUS=$?
    else
      eval "$clean_cmd"
      TASK_STATUS=$?
    fi
  done
  saveTaskStatus "${TASK_STATUS}" "${ACTIVITY_SUB_TASK_CODE}"
done
