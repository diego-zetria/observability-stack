#!/bin/bash
# =============================================================================
# Observability Stack - Helper Script
# =============================================================================
# Usage: ./scripts/monitoring.sh {start|stop|restart|status|logs|clean}

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_urls() {
  echo ""
  echo -e "${GREEN}Monitoring stack started successfully\!${NC}"
  echo ""
  echo "  Grafana:      http://localhost:3333  (admin/admin)"
  echo "  Prometheus:    http://localhost:9090"
  echo "  Netdata:       http://localhost:19999"
  echo "  Alloy UI:      http://localhost:12345"
  echo "  Loki API:      http://localhost:3200"
  echo "  Tempo API:     http://localhost:3201"
  echo ""
  echo -e "${YELLOW}To send traces from your backend:${NC}"
  echo "  export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318"
  echo ""
}

case "${1:-}" in
  start)
    echo "Starting monitoring stack..."
    docker compose -f "$COMPOSE_FILE" up -d
    print_urls
    ;;

  stop)
    echo "Stopping monitoring stack..."
    docker compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}Monitoring stack stopped.${NC}"
    ;;

  restart)
    echo "Restarting monitoring stack..."
    docker compose -f "$COMPOSE_FILE" down
    docker compose -f "$COMPOSE_FILE" up -d
    print_urls
    ;;

  status)
    docker compose -f "$COMPOSE_FILE" ps
    ;;

  logs)
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
      docker compose -f "$COMPOSE_FILE" logs -f "$SERVICE"
    else
      docker compose -f "$COMPOSE_FILE" logs -f
    fi
    ;;

  clean)
    echo -e "${RED}This will remove all monitoring data (volumes).${NC}"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker compose -f "$COMPOSE_FILE" down -v
      echo -e "${GREEN}Monitoring stack and data removed.${NC}"
    else
      echo "Cancelled."
    fi
    ;;

  *)
    echo "Usage: $0 {start|stop|restart|status|logs [service]|clean}"
    echo ""
    echo "Commands:"
    echo "  start    - Start all monitoring services"
    echo "  stop     - Stop all monitoring services"
    echo "  restart  - Restart all monitoring services"
    echo "  status   - Show status of all services"
    echo "  logs     - Follow logs (optionally for a specific service)"
    echo "  clean    - Stop and remove all data (volumes)"
    exit 1
    ;;
esac
