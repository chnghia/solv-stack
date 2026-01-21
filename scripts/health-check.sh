#!/bin/bash
# ==============================================
# SOLV Stack - Health Check Script
# Check status of all services
# ==============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Base URL
BASE_URL="${1:-http://localhost:8080}"

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     SOLV Stack - Health Check              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Base URL: $BASE_URL"
echo ""

# Check function
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    printf "%-20s " "$name"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (HTTP $response)${NC}"
        return 1
    fi
}

echo "Service Status:"
echo "-------------------------------------------"

# Check all services
failed=0

check_service "OpenWebUI (Chat)" "$BASE_URL/" || ((failed++))
check_service "LiteLLM (API)" "$BASE_URL/api/health" || ((failed++))
check_service "Qdrant (Vector DB)" "$BASE_URL/qdrant/readyz" || ((failed++))
check_service "SearXNG (Search)" "$BASE_URL/search/" || ((failed++))

echo "-------------------------------------------"
echo ""

# Docker container status
echo "Docker Containers:"
echo "-------------------------------------------"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker Compose not running"
echo ""

# Summary
if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✅ All services are healthy!${NC}"
else
    echo -e "${YELLOW}⚠️  $failed service(s) may have issues${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  docker compose logs <service-name>"
    echo "  docker compose restart <service-name>"
fi
