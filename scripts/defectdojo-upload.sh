#!/bin/bash
# DefectDojo Upload Script for Secure DevOps Pipeline
# Uploads security scan reports to DefectDojo via the REST API.
# Usage: defectdojo-upload.sh --url URL --api-key KEY --product NAME --engagement NAME

set -e

DEFECTDOJO_URL=""
API_KEY=""
PRODUCT_NAME="Secure DevOps Pipeline"
ENGAGEMENT_NAME="CI Pipeline Run"

usage() {
  echo "Usage: $0 --url <defectdojo_url> --api-key <api_key> [--product <name>] [--engagement <name>]"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --url) DEFECTDOJO_URL="$2"; shift ;;
    --api-key) API_KEY="$2"; shift ;;
    --product) PRODUCT_NAME="$2"; shift ;;
    --engagement) ENGAGEMENT_NAME="$2"; shift ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

if [[ -z "$DEFECTDOJO_URL" || -z "$API_KEY" ]]; then
  echo "❌ Error: --url and --api-key are required"
  usage
fi

AUTH_HEADER="Authorization: Token $API_KEY"
CONTENT_TYPE="Content-Type: application/json"
API_BASE="$DEFECTDOJO_URL/api/v2"

echo "=================================================="
echo "🛡️  DefectDojo Upload - Secure DevOps Pipeline"
echo "=================================================="
echo "URL: $DEFECTDOJO_URL"
echo "Product: $PRODUCT_NAME"
echo "Engagement: $ENGAGEMENT_NAME"
echo ""

# Step 1: Get or create product
echo "📦 Looking up product: $PRODUCT_NAME"
PRODUCT_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "$AUTH_HEADER" \
  "$API_BASE/products/?name=$PRODUCT_NAME")
HTTP_CODE=$(echo "$PRODUCT_RESPONSE" | tail -1)
BODY=$(echo "$PRODUCT_RESPONSE" | head -n -1)

PRODUCT_COUNT=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('count',0))" 2>/dev/null || echo "0")

if [[ "$PRODUCT_COUNT" -gt 0 ]]; then
  PRODUCT_ID=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['results'][0]['id'])" 2>/dev/null || echo "")
  echo "✅ Found existing product ID: $PRODUCT_ID"
else
  echo "📝 Creating new product: $PRODUCT_NAME"
  CREATE_PRODUCT=$(curl -s -w "\n%{http_code}" -X POST \
    -H "$AUTH_HEADER" \
    -H "$CONTENT_TYPE" \
    "$API_BASE/products/" \
    -d "{\"name\": \"$PRODUCT_NAME\", \"description\": \"Secure DevOps Pipeline security findings\", \"prod_type\": 1}")
  HTTP_CODE=$(echo "$CREATE_PRODUCT" | tail -1)
  PRODUCT_BODY=$(echo "$CREATE_PRODUCT" | head -n -1)
  PRODUCT_ID=$(echo "$PRODUCT_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
  if [[ -z "$PRODUCT_ID" ]]; then
    echo "❌ Failed to create product (HTTP $HTTP_CODE)"
    exit 1
  fi
  echo "✅ Created product ID: $PRODUCT_ID"
fi

# Step 2: Create engagement
echo ""
echo "📋 Creating engagement: $ENGAGEMENT_NAME"
TODAY=$(date +%Y-%m-%d)
CREATE_ENG=$(curl -s -w "\n%{http_code}" -X POST \
  -H "$AUTH_HEADER" \
  -H "$CONTENT_TYPE" \
  "$API_BASE/engagements/" \
  -d "{\"name\": \"$ENGAGEMENT_NAME\", \"product\": $PRODUCT_ID, \"target_start\": \"$TODAY\", \"target_end\": \"$TODAY\", \"engagement_type\": \"CI/CD\", \"status\": \"In Progress\"}")
HTTP_CODE=$(echo "$CREATE_ENG" | tail -1)
ENG_BODY=$(echo "$CREATE_ENG" | head -n -1)
ENGAGEMENT_ID=$(echo "$ENG_BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
if [[ -z "$ENGAGEMENT_ID" ]]; then
  echo "❌ Failed to create engagement (HTTP $HTTP_CODE)"
  exit 1
fi
echo "✅ Created engagement ID: $ENGAGEMENT_ID"

# Helper function to upload a scan file
upload_scan() {
  local FILE="$1"
  local SCAN_TYPE="$2"
  local LABEL="$3"

  if [[ ! -f "$FILE" ]]; then
    echo "⚠️  Skipping $LABEL: file not found at $FILE"
    return 0
  fi

  echo ""
  echo "⬆️  Uploading $LABEL..."
  UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "$AUTH_HEADER" \
    "$API_BASE/import-scan/" \
    -F "file=@$FILE" \
    -F "scan_type=$SCAN_TYPE" \
    -F "engagement=$ENGAGEMENT_ID" \
    -F "active=true" \
    -F "verified=false" \
    -F "minimum_severity=Info")
  HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -1)
  UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | head -n -1)

  if [[ "$HTTP_CODE" == "201" ]]; then
    echo "✅ $LABEL uploaded successfully"
  else
    echo "⚠️  $LABEL upload returned HTTP $HTTP_CODE"
    echo "   Response: $UPLOAD_BODY"
  fi
}

# Step 3: Upload scan reports
echo ""
echo "📤 Uploading security scan reports..."
upload_scan "app/target/dependency-check-report.xml" "Dependency Check Scan" "OWASP Dependency Check"
upload_scan "checkov-report.json" "Checkov Scan" "Checkov IaC Scan"
upload_scan "trivy-report.json" "Trivy Scan" "Trivy Container Scan"

echo ""
echo "=================================================="
echo "✅ DefectDojo upload complete!"
echo "   Product ID:    $PRODUCT_ID"
echo "   Engagement ID: $ENGAGEMENT_ID"
echo "   View at: $DEFECTDOJO_URL/engagement/$ENGAGEMENT_ID"
echo "=================================================="
