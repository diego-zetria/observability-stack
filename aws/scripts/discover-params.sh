#!/usr/bin/env bash
set -eu

REGION="${REGION:-us-east-1}"
CLUSTER="${CLUSTER:-my-cluster}"

echo "============================================="
echo "  Observability - Parameter Discovery"
echo "============================================="
echo ""

echo "==> Looking up cluster ${CLUSTER} configuration..."
SERVICE_ARN=$(aws ecs list-services --cluster ${CLUSTER} --region ${REGION} --query "serviceArns[?contains(@, 'myapp-backend')]|[0]" --output text)

if [ "${SERVICE_ARN}" = "None" ]; then
  echo "ERROR: No services found in cluster ${CLUSTER}"
  exit 1
fi

SERVICE_DETAILS=$(aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE_ARN} --region ${REGION})

SUBNETS=$(echo ${SERVICE_DETAILS} | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d['services'][0]['networkConfiguration']['awsvpcConfiguration']['subnets']))")
SG=$(echo ${SERVICE_DETAILS} | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['services'][0]['networkConfiguration']['awsvpcConfiguration']['securityGroups'][0])")

FIRST_SUBNET=$(echo ${SUBNETS} | cut -d',' -f1)
VPC_ID=$(aws ec2 describe-subnets --subnet-ids ${FIRST_SUBNET} --region ${REGION} --query 'Subnets[0].VpcId' --output text)

echo "  VPC_ID=${VPC_ID}"
echo "  PRIVATE_SUBNET_IDS=${SUBNETS}"
echo "  BACKEND_SG_ID=${SG}"

echo ""
echo "==> Looking for ALB in VPC ${VPC_ID}..."
ALB_ARN=$(aws elbv2 describe-load-balancers --region ${REGION} --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn" --output text | head -1)

if [ -n "${ALB_ARN}" ] && [ "${ALB_ARN}" != "None" ]; then
  ALB_SG=$(aws elbv2 describe-load-balancers --load-balancer-arns ${ALB_ARN} --region ${REGION} --query 'LoadBalancers[0].SecurityGroups[0]' --output text)
  LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn ${ALB_ARN} --region ${REGION} --query "Listeners[?Port==\`443\`].ListenerArn" --output text)
  echo "  ALB_SG_ID=${ALB_SG}"
  echo "  ALB_LISTENER_ARN=${LISTENER_ARN}"
else
  ALB_SG="<FILL_IN>"
  LISTENER_ARN="<FILL_IN>"
fi

echo ""
echo "============================================="
echo "  Export these before running 'make deploy':"
echo "============================================="
echo ""
echo "export VPC_ID=${VPC_ID}"
echo "export PRIVATE_SUBNET_IDS=${SUBNETS}"
echo "export BACKEND_SG_ID=${SG}"
echo "export ALB_SG_ID=${ALB_SG}"
echo "export ALB_LISTENER_ARN=${LISTENER_ARN}"
echo "export GRAFANA_ADMIN_PASSWORD=<your-secure-password>"
