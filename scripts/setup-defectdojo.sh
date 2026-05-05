#!/bin/bash
# DefectDojo Quick Setup Script for SDOP-2025
# This script uses Docker Compose to spin up DefectDojo with PostgreSQL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_DIR="$PROJECT_ROOT/docker/monitoring"

DEFECTDOJO_URL="http://localhost:8000"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"
API_TIMEOUT=120

echo "=================================================="
echo "🛡️  SDOP-2025 DefectDojo Setup (Docker Compose)"
echo "=================================================="
echo ""

# Check if docker and docker-compose are available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed or not in PATH."
    exit 1
fi

cd "$DOCKER_COMPOSE_DIR"

# Step 1: Start core services
echo "📦 Starting PostgreSQL and Redis..."
docker-compose up -d postgres redis

sleep 5

echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec postgres pg_isready -U defectdojo 2>/dev/null; then
        echo "✅ PostgreSQL is ready!"
        break
    fi
    echo "   Attempt $i/30..."
    sleep 2
done

# Step 2: Start DefectDojo
echo ""
echo "🚀 Starting DefectDojo..."
docker-compose up -d defectdojo

echo "⏳ Waiting for DefectDojo API to initialize (~90 seconds)..."
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $API_TIMEOUT ]; then
        echo "❌ DefectDojo did not start within $API_TIMEOUT seconds"
        echo ""
        echo "💡 Troubleshooting:"
        echo "   1. Check logs: docker-compose logs defectdojo"
        echo "   2. Verify port 8000 is not in use: lsof -i :8000"
        echo "   3. Check disk space for Docker volumes"
        exit 1
    fi
    
    if curl -s "$DEFECTDOJO_URL/api/v2/system_settings/" >/dev/null 2>&1; then
        echo "✅ DefectDojo API is ready!"
        break
    fi
    
    printf "   Elapsed: %d seconds...\r" $ELAPSED
    sleep 5
done

# Step 3: Start monitoring stack
echo ""
echo "📊 Starting Prometheus and Grafana..."
docker-compose up -d prometheus grafana

sleep 5

# Step 4: Verify all services
echo ""
echo "✅ Verifying all services..."

docker-compose ps

# Step 5: Output configuration
echo ""
echo "=================================================="
echo "✅ DefectDojo Setup Complete!"
echo "=================================================="
echo ""
echo "📝 Access Credentials:"
echo "   Username: $ADMIN_USER"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "🌐 Service URLs:"
echo "   DefectDojo:  $DEFECTDOJO_URL"
echo "   Prometheus:  http://localhost:9090"
echo "   Grafana:     http://localhost:3000 (admin/admin)"
echo ""
echo "🔑 Next Steps:"
echo ""
echo "   1. Open DefectDojo: $DEFECTDOJO_URL"
echo "   2. Login with: $ADMIN_USER / $ADMIN_PASSWORD"
echo "   3. Generate API token (Admin → Tokens)"
echo "   4. Create Engagement (Engagements → New)"
echo ""
echo "   See: docs/DEFECTDOJO-SETUP.md for detailed instructions"
echo ""
echo "📋 GitHub Secrets to Configure:"
echo "   DEFECTDOJO_URL=$DEFECTDOJO_URL"
echo "   DEFECTDOJO_API_KEY=<generated_from_ui>"
echo "   DEFECTDOJO_ENGAGEMENT_ID=<created_engagement_id>"
echo ""