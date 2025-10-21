#!/bin/bash
# Compliance Scan Script for Packer Golden Images
# Run during image build to validate STIG compliance

set -e

STIG_PROFILE="${STIG_PROFILE:-xccdf_org.ssgproject.content_profile_stig}"
RESULTS_DIR="/tmp/compliance-scan"
TIMESTAMP=$(date +%s)

echo "================================"
echo "Forge Golden Image Compliance Scan"
echo "================================"
echo "Profile: $STIG_PROFILE"
echo "Timestamp: $TIMESTAMP"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Run compliance scan
echo "Running OpenSCAP compliance scan..."
oscap xccdf eval \
  --profile "$STIG_PROFILE" \
  --results "$RESULTS_DIR/scan-results-$TIMESTAMP.xml" \
  --report "$RESULTS_DIR/scan-report-$TIMESTAMP.html" \
  --oval-results \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml || true

# Parse results
echo ""
echo "Parsing scan results..."

PASS_COUNT=$(xmllint --xpath "count(//rule-result[result='pass'])" "$RESULTS_DIR/scan-results-$TIMESTAMP.xml" 2>/dev/null || echo "0")
FAIL_COUNT=$(xmllint --xpath "count(//rule-result[result='fail'])" "$RESULTS_DIR/scan-results-$TIMESTAMP.xml" 2>/dev/null || echo "0")
ERROR_COUNT=$(xmllint --xpath "count(//rule-result[result='error'])" "$RESULTS_DIR/scan-results-$TIMESTAMP.xml" 2>/dev/null || echo "0")
NOTAPPLICABLE_COUNT=$(xmllint --xpath "count(//rule-result[result='notapplicable'])" "$RESULTS_DIR/scan-results-$TIMESTAMP.xml" 2>/dev/null || echo "0")

TOTAL_COUNT=$((PASS_COUNT + FAIL_COUNT + ERROR_COUNT + NOTAPPLICABLE_COUNT))

if [ $TOTAL_COUNT -gt 0 ]; then
  COMPLIANCE_PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", ($PASS_COUNT / $TOTAL_COUNT) * 100}")
else
  COMPLIANCE_PERCENTAGE="0.00"
fi

# Display results
echo ""
echo "================================"
echo "Compliance Scan Results"
echo "================================"
echo "Total Rules:        $TOTAL_COUNT"
echo "Passed:             $PASS_COUNT"
echo "Failed:             $FAIL_COUNT"
echo "Errors:             $ERROR_COUNT"
echo "Not Applicable:     $NOTAPPLICABLE_COUNT"
echo "Compliance:         $COMPLIANCE_PERCENTAGE%"
echo "================================"
echo ""

# Generate Forge metadata
cat > "$RESULTS_DIR/forge-compliance-metadata.json" <<EOF
{
  "scan_timestamp": "$TIMESTAMP",
  "stig_profile": "$STIG_PROFILE",
  "results": {
    "total_rules": $TOTAL_COUNT,
    "passed": $PASS_COUNT,
    "failed": $FAIL_COUNT,
    "errors": $ERROR_COUNT,
    "not_applicable": $NOTAPPLICABLE_COUNT,
    "compliance_percentage": $COMPLIANCE_PERCENTAGE
  },
  "files": {
    "results_xml": "$RESULTS_DIR/scan-results-$TIMESTAMP.xml",
    "report_html": "$RESULTS_DIR/scan-report-$TIMESTAMP.html"
  },
  "forge_managed": true,
  "image_type": "golden-image"
}
EOF

echo "Compliance metadata saved to: $RESULTS_DIR/forge-compliance-metadata.json"
echo "HTML report saved to: $RESULTS_DIR/scan-report-$TIMESTAMP.html"
echo ""

# Check if compliance threshold is met (80% for warning, 95% for production)
COMPLIANCE_THRESHOLD="${COMPLIANCE_THRESHOLD:-95}"

if (( $(echo "$COMPLIANCE_PERCENTAGE >= $COMPLIANCE_THRESHOLD" | bc -l) )); then
  echo "✅ Image meets compliance threshold ($COMPLIANCE_THRESHOLD%)"
  exit 0
elif (( $(echo "$COMPLIANCE_PERCENTAGE >= 80" | bc -l) )); then
  echo "⚠️  Image meets minimum threshold (80%) but below target ($COMPLIANCE_THRESHOLD%)"
  exit 0
else
  echo "❌ Image FAILS compliance requirements (below 80%)"
  echo "   Failed rules: $FAIL_COUNT"
  echo "   Please review $RESULTS_DIR/scan-report-$TIMESTAMP.html"
  exit 1
fi

