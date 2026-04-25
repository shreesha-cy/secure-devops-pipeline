#!/bin/bash

PASS=$(grep -c "\[PASS\]" bench-output.txt)
WARN=$(grep -c "\[WARN\]" bench-output.txt)
INFO=$(grep -c "\[INFO\]" bench-output.txt)

TOTAL=$((PASS + WARN + INFO))

if [ "$TOTAL" -eq 0 ]; then
  echo "❌ Could not calculate score"
  exit 1
fi

SCORE=$((PASS * 100 / TOTAL))

echo "PASS: $PASS"
echo "WARN: $WARN"
echo "INFO: $INFO"
echo "Total Checks: $TOTAL"
echo "CIS Compliance Score: $SCORE%"

if [ "$SCORE" -lt 80 ]; then
  echo "❌ Pipeline FAILED (CIS < 80%)"
  exit 1
else
  echo "✅ Pipeline PASSED (CIS >= 80%)"
fi
