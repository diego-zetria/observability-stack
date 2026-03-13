#!/usr/bin/env bash
set -eu

STACK_NAME="${STACK_NAME:-obs-monitoring}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
REGION="${REGION:-us-east-1}"
TEMPLATES_BUCKET="${TEMPLATES_BUCKET:-obs-monitoring-templates-${ENVIRONMENT}}"

PARAMS=(
  ParameterKey=Environment,ParameterValue=${ENVIRONMENT}
  ParameterKey=VpcId,ParameterValue="${VPC_ID:?Set VPC_ID env var}"
  "ParameterKey=PrivateSubnetIds,ParameterValue=\"${PRIVATE_SUBNET_IDS:?Set PRIVATE_SUBNET_IDS env var (comma-separated)}\""
  ParameterKey=AlbListenerArn,ParameterValue="${ALB_LISTENER_ARN:?Set ALB_LISTENER_ARN env var}"
  ParameterKey=AlbSecurityGroupId,ParameterValue="${ALB_SG_ID:?Set ALB_SG_ID env var}"
  ParameterKey=BackendSecurityGroupId,ParameterValue="${BACKEND_SG_ID:?Set BACKEND_SG_ID env var}"
  ParameterKey=GrafanaAdminPassword,ParameterValue="${GRAFANA_ADMIN_PASSWORD:-admin}"
  ParameterKey=TemplatesBucket,ParameterValue=${TEMPLATES_BUCKET}
)

echo "==> Deploying stack: ${STACK_NAME}"
echo "    Environment: ${ENVIRONMENT}"
echo "    Region: ${REGION}"
echo ""

# Check if stack exists
if aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${REGION} 2>/dev/null; then
  echo "==> Updating existing stack..."
  set +e
  OUTPUT=$(aws cloudformation update-stack \
    --stack-name ${STACK_NAME} \
    --template-url "https://${TEMPLATES_BUCKET}.s3.amazonaws.com/template.yaml" \
    --parameters "${PARAMS[@]}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${REGION} \
    --tags Key=Project,Value=obs-monitoring Key=Environment,Value=${ENVIRONMENT} 2>&1)
  EXIT_CODE=$?
  set -e

  if [ ${EXIT_CODE} -ne 0 ]; then
    if echo "${OUTPUT}" | grep -q "No updates are to be performed"; then
      echo "==> No changes detected. Stack is up to date."
      exit 0
    else
      echo "${OUTPUT}" >&2
      exit ${EXIT_CODE}
    fi
  fi
else
  echo "==> Creating new stack..."
  aws cloudformation create-stack \
    --stack-name ${STACK_NAME} \
    --template-url "https://${TEMPLATES_BUCKET}.s3.amazonaws.com/template.yaml" \
    --parameters "${PARAMS[@]}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${REGION} \
    --tags Key=Project,Value=obs-monitoring Key=Environment,Value=${ENVIRONMENT}
fi

echo ""
echo "==> Stack operation initiated!"
echo "    Monitor: aws cloudformation describe-stack-events --stack-name ${STACK_NAME} --region ${REGION}"
echo "    After deployment: make monitoring-start"
