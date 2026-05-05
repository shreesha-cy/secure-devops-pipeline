#!/bin/bash

# 🎬 DEMO VERIFICATION SCRIPT - Run Before Professor Demo
# This script verifies all services are ready for the presentation

echo "=========================================="
echo "  🎬 PROFESSOR DEMO VERIFICATION"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize counters
TOTAL=0
PASSED=0
FAILED=0

# Function to check status
check_service() {
    local name=$1
    local command=$2
    local expected=$3
    
    TOTAL=$((TOTAL + 1))
    
    echo -n "Checking $name ... "
    result=$(eval "$command" 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "  Details: $result"
        FAILED=$((FAILED + 1))
    fi
}

echo "📋 CHECKING DOCKER CONTAINERS"
echo "=============================="

check_service "DefectDojo Nginx" "docker ps | grep defectdojo-nginx" "Up"
check_service "DefectDojo Django" "docker ps | grep defectdojo-django" "Up"
check_service "Grafana" "docker ps | grep grafana" "Up"
check_service "Prometheus" "docker ps | grep prometheus" "Up"
check_service "PostgreSQL" "docker ps | grep postgres" "Up"
check_service "Redis" "docker ps | grep redis" "Up"

echo ""
echo "🌐 CHECKING SERVICE CONNECTIVITY"
echo "=================================="

check_service "DefectDojo Web (8000)" "curl -s -I http://localhost:8000 | head -1" "200"
check_service "Grafana (3000)" "curl -s -I http://localhost:3000 | head -1" "200"
check_service "Prometheus (9090)" "curl -s -I http://localhost:9090 | head -1" "200"

echo ""
echo "📂 CHECKING REQUIRED FILES"
echo "=========================="

check_service "Pipeline YAML" "test -f .github/workflows/pipeline.yml && echo found" "found"
check_service "K8s Manifests" "test -f app/k8s/petclinic.yml && echo found" "found"
check_service "Dockerfile" "test -f docker/Dockerfile && echo found" "found"
check_service "OPA Policies" "test -f policy/no-root.rego && echo found" "found"
check_service "Demo Guide" "test -f PROFESSOR-DEMO-SCRIPT.md && echo found" "found"
check_service "Grafana Dashboards" "test -d grafana-dashboards && echo found" "found"

echo ""
echo "📊 CHECKING GITHUB"
echo "==================="

if command -v git &> /dev/null; then
    check_service "Git Status" "git status | grep 'On branch' | head -1" "branch"
    check_service "Latest Commits" "git log --oneline -5 | wc -l" "5"
else
    echo -e "${YELLOW}⚠️  Git not found in PATH${NC}"
fi

echo ""
echo "==========================================="
echo "  📊 SUMMARY"
echo "==========================================="
echo "Total Checks: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL SYSTEMS READY FOR DEMO!${NC}"
    echo ""
    echo "🎬 NEXT STEPS:"
    echo "  1. Read: PROFESSOR-DEMO-SCRIPT.md"
    echo "  2. Print: DEMO-CHECKLIST.md"
    echo "  3. Open browser tabs:"
    echo "     - https://github.com/Anoop1605/secure-devops-pipeline/actions"
    echo "     - http://localhost:8000 (DefectDojo)"
    echo "     - http://localhost:3000 (Grafana)"
    echo "  4. Start presentation!"
    echo ""
    exit 0
else
    echo -e "${RED}❌ SOME SYSTEMS NOT READY${NC}"
    echo ""
    echo "🔧 TROUBLESHOOTING:"
    echo "  • Check Docker daemon is running"
    echo "  • Run: docker-compose -f docker/monitoring/docker-compose.yml up -d"
    echo "  • Wait 2-3 minutes for services to initialize"
    echo "  • Then run this script again"
    echo ""
    exit 1
fi
