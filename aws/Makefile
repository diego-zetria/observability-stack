# Observability Stack - AWS Deployment
# Usage:
#   make deploy              Deploy/update full stack
#   make build               Build and push custom Docker images
#   make monitoring-start    Start monitoring (desired_count=1)
#   make monitoring-stop     Stop monitoring (desired_count=0)
#   make monitoring-status   Check monitoring status
#   make monitoring-logs     Tail ECS logs
#   make destroy             Delete entire stack

STACK_NAME ?= obs-monitoring
ENVIRONMENT ?= dev
CLUSTER ?= my-cluster
SERVICE ?= obs-monitoring-$(ENVIRONMENT)
REGION ?= us-east-1
TEMPLATES_BUCKET ?= obs-monitoring-templates-$(ENVIRONMENT)

.PHONY: deploy build monitoring-start monitoring-stop monitoring-status monitoring-logs destroy upload-templates

build:
	@echo "==> Building and pushing monitoring images..."
	@bash scripts/build-and-push.sh

upload-templates:
	@echo "==> Creating templates bucket (if needed)..."
	@aws s3 mb s3://$(TEMPLATES_BUCKET) --region $(REGION) 2>/dev/null || true
	@echo "==> Uploading CloudFormation templates..."
	@aws s3 sync stacks/ s3://$(TEMPLATES_BUCKET)/stacks/ --region $(REGION)
	@aws s3 cp template.yaml s3://$(TEMPLATES_BUCKET)/template.yaml --region $(REGION)
	@echo "==> Packaging and uploading Lambda code..."
	@cd lambda/monitoring-control && zip -j /tmp/monitoring-control.zip index.py
	@aws s3 cp /tmp/monitoring-control.zip s3://$(TEMPLATES_BUCKET)/lambda/monitoring-control.zip --region $(REGION)
	@rm -f /tmp/monitoring-control.zip
	@echo "==> Templates uploaded!"

deploy: upload-templates
	@echo "==> Deploying monitoring stack..."
	@bash scripts/deploy.sh

monitoring-start:
	@echo "==> Starting monitoring stack..."
	@aws ecs update-service --cluster $(CLUSTER) --service $(SERVICE) --desired-count 1 --region $(REGION) --query 'service.{status:status,desired:desiredCount,running:runningCount}' --output table
	@echo ""
	@echo "Grafana: https://monitoring.dev.example.com"
	@echo "(may take 1-2 minutes to become healthy)"

monitoring-stop:
	@echo "==> Stopping monitoring stack..."
	@aws ecs update-service --cluster $(CLUSTER) --service $(SERVICE) --desired-count 0 --region $(REGION) --query 'service.{status:status,desired:desiredCount,running:runningCount}' --output table
	@echo "Monitoring stopped. Cost: ~$$1.55/month (storage only)"

monitoring-status:
	@echo "==> Monitoring stack status:"
	@aws ecs describe-services --cluster $(CLUSTER) --services $(SERVICE) --region $(REGION) --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount}' --output table

monitoring-logs:
	@echo "==> Following monitoring logs (Ctrl+C to stop)..."
	@aws logs tail /ecs/obs-monitoring-$(ENVIRONMENT) --follow --region $(REGION)

destroy:
	@echo "WARNING: This will delete the entire monitoring stack!"
	@echo "S3 bucket and data will be retained."
	@read -p "Are you sure? (y/N) " confirm && [ "$$confirm" = "y" ] || exit 1
	@aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(REGION)
	@echo "Stack deletion initiated."
