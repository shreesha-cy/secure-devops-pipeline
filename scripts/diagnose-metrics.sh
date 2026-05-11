#!/bin/bash
# Diagnostic Script - Verify Metrics Pipeline Connection
# Run this to check if all components can reach each other

set -e

echo "🔍 METRICS PIPELINE DIAGNOSTIC"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_endpoint() {
  local name=$1
  local url=$2
  
  echo -n "Testing $name... "
  if curl -s "$url" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
    return 0
  else
    echo -e "${RED}❌ Failed${NC}"
    return 1
  fi
}

# Test 1: Pushgateway
echo "📤 PUSHGATEWAY"
test_endpoint "Pushgateway" "http://localhost:9091" || {
  echo -e "${RED}  → Pushgateway not responding${NC}"
  echo "     Run: docker ps | grep pushgateway"
}
echo ""

# Test 2: Prometheus
echo "📊 PROMETHEUS"
test_endpoint "Prometheus" "http://localhost:9090" || {
  echo -e "${RED}  → Prometheus not responding${NC}"
  echo "     Run: docker ps | grep prometheus"
}
echo ""

# Test 3: Grafana
echo "📈 GRAFANA"
test_endpoint "Grafana" "http://localhost:3000" || {
  echo -e "${RED}  → Grafana not responding${NC}"
  echo "     Run: docker ps | grep grafana"
}
echo ""

# Test 4: DefectDojo
echo "🛡️  DEFECTDOJO"
test_endpoint "DefectDojo" "http://localhost:8000" || {
  echo -e "${RED}  → DefectDojo not responding${NC}"
  echo "     Run: docker ps | grep defectdojo"
}
echo ""

# Test 5: Prometheus Targets
echo "🎯 PROMETHEUS TARGETS"
echo -n "  Checking Pushgateway job status... "
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "")
if echo "$TARGETS" | grep -q "pushgateway"; then
  if echo "$TARGETS" | grep -q '"health":"up".*pushgateway'; then
    echo -e "${GREEN}✅ UP${NC}"
  else
    echo -e "${YELLOW}⚠️  DOWN${NC}"
    echo "    Pushgateway job is DOWN in Prometheus"
    echo "    Check: http://localhost:9090/targets"
  fi
else
  echo -e "${RED}❌ Not found${NC}"
  echo "    Pushgateway job not configured in Prometheus"
fi
echo ""

# Test 6: Check if metrics exist in Pushgateway
echo "📊 PUSHGATEWAY METRICS"
echo -n "  Checking for stored metrics... "
METRICS=$(curl -s http://localhost:9091/metrics 2>/dev/null || echo "")
if [ -n "$METRICS" ]; then
  METRIC_COUNT=$(echo "$METRICS" | wc -l)
  echo -e "${GREEN}✅ Found $METRIC_COUNT lines${NC}"
  echo "    Sample metrics:"
  echo "$METRICS" | grep "^pipeline_" | head -5 | sed 's/^/      /'
else
  echo -e "${YELLOW}⚠️  No metrics yet${NC}"
  echo "    Pipeline hasn't pushed metrics yet"
fi
echo ""

# Test 7: Grafana Data Source
echo "💾 GRAFANA DATA SOURCE"
echo -n "  Checking Prometheus datasource... "
if curl -s http://localhost:3000/api/datasources 2>/dev/null | grep -q "prometheus"; then
  echo -e "${GREEN}✅ Configured${NC}"
else
  echo -e "${YELLOW}⚠️  Not found${NC}"
  echo "    Add Prometheus data source in Grafana"
fi
echo ""

# Test 8: Test Push
echo "🧪 TEST METRICS PUSH"
echo -n "  Creating test metric... "
cat > /tmp/test-metrics.txt << 'EOF'
# HELP test_push_metric Test metric for pipeline validation
# TYPE test_push_metric gauge
test_push_metric{job="diagnostic"} 100
EOF
echo -e "${GREEN}✅ Created${NC}"

echo -n "  Pushing to pushgateway... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --data-binary @/tmp/test-metrics.txt \
  http://localhost:9091/metrics/job/diagnostic_test)

if [ "$HTTP_CODE" == "202" ] || [ "$HTTP_CODE" == "200" ]; then
  echo -e "${GREEN}✅ HTTP $HTTP_CODE (Success)${NC}"
else
  echo -e "${RED}❌ HTTP $HTTP_CODE${NC}"
  echo "    Expected: 202 or 200"
fi

echo -n "  Verifying in Prometheus... "
sleep 2
QUERY_RESULT=$(curl -s 'http://localhost:9090/api/v1/query?query=test_push_metric' 2>/dev/null | grep -q "value" && echo "found" || echo "not_found")
if [ "$QUERY_RESULT" == "found" ]; then
  echo -e "${GREEN}✅ Query returned data${NC}"
else
  echo -e "${YELLOW}⚠️  Not yet in Prometheus${NC}"
  echo "    May take a few seconds to scrape"
fi
echo ""

# Test 9: GitHub Secrets Check (local)
echo "🔐 GITHUB SECRETS"
echo "  Check these are set in GitHub:"
echo "    □ PUSHGATEWAY_URL = http://localhost:9091"
echo "    □ DEFECTDOJO_URL = http://localhost:8000"
echo "    □ DEFECTDOJO_API_KEY = [your-api-key]"
echo ""

# Summary
echo "======================================"
echo "✨ SUMMARY"
echo ""
echo "If all tests passed (✅):"
echo "  1. Ensure GitHub secrets are set correctly"
echo "  2. Run a test pipeline: git push"
echo "  3. Check workflow logs in GitHub Actions"
echo "  4. Query metrics in Grafana"
echo ""
echo "If something failed (❌):"
echo "  1. Check Docker containers: docker ps"
echo "  2. Check container logs: docker logs [container]"
echo "  3. Verify ports: netstat -tuln | grep 909"
echo "  4. Restart containers: docker-compose -f docker/monitoring/docker-compose.yml restart"
echo ""
