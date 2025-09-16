#!/usr/bin/env bash
set -euo pipefail

TARGET_COLOR="${1:-}"

if [[ -z "$TARGET_COLOR" ]]; then
  echo "Usage: $0 <blue|green>" >&2
  exit 1
fi

if [[ -z "${ALB_LISTENER_ARN:-}" || -z "${BLUE_TARGET_GROUP_ARN:-}" || -z "${GREEN_TARGET_GROUP_ARN:-}" ]]; then
  echo "ALB_LISTENER_ARN, BLUE_TARGET_GROUP_ARN and GREEN_TARGET_GROUP_ARN environment variables must be set" >&2
  exit 2
fi

case "$TARGET_COLOR" in
  blue)
    TARGET_GROUP_ARN="$BLUE_TARGET_GROUP_ARN"
    ;;
  green)
    TARGET_GROUP_ARN="$GREEN_TARGET_GROUP_ARN"
    ;;
  *)
    echo "target color must be 'blue' or 'green'" >&2
    exit 3
    ;;
esac

echo "Switching listener $ALB_LISTENER_ARN to target group $TARGET_GROUP_ARN"
aws elbv2 modify-listener \
  --listener-arn "$ALB_LISTENER_ARN" \
  --default-actions "Type=forward,TargetGroupArn=$TARGET_GROUP_ARN"

echo "Listener updated to $TARGET_COLOR"
