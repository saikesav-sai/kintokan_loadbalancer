#!/bin/bash
# install jq if not installed
# used cron - crontab to auto run this script see K0p1-Git/cloudflare-ddns-updater for more info
# used bashrc to auto run on boot
# to run cron everytime in kali use  1 cron   2 cron -e  3 */1 * * * * /home/load_balancer.sh >> /tmp/lb.log 2>&1


# CONFIGURE
ZONE_ID=""
API_TOKEN=""
RULESET_ID=""
RULE_ID=""
SOURCE_URL="https://kintokan.live"
TARGET_URL="https://server1.kintokan.live"
EMAIL="kintokanitsolutions@gmail.com"

# Check main site
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L  "$SOURCE_URL")

if [[ "$STATUS_CODE" -eq 200 ]]; then
  echo "Site is down (status $STATUS_CODE), updating redirect to server2..."

  # Get current ruleset and rule version
  RULESET_JSON=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESET_ID" \
  -H "X-Auth-Email: $EMAIL" \
  -H "X-Auth-Key: $API_TOKEN")

  RULESET_VERSION=$(echo "$RULESET_JSON" | jq -r '.result.version')
  RULE_VERSION=$(echo "$RULESET_JSON" | jq -r '.result.rules[0].version')

  if [[ -z "$RULESET_VERSION" || "$RULESET_VERSION" == "null" ]]; then
    echo "Failed to fetch ruleset version."
    exit 1
  fi

  echo "Using ruleset version $RULESET_VERSION, rule version $RULE_VERSION"

  # Update redirect target using ruleset_version and rule_version
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESET_ID" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_TOKEN"\
    --data @- <<EOF
{
  "name": "default",
  "description": "",
  "kind": "zone",
  "phase": "http_request_dynamic_redirect",
  "version":"$RULESET_VERSION",
  "rules": [
    {
      "id": "$RULE_ID",
      "ref": "$RULE_ID",
      "version": "$RULE_VERSION",
      "action": "redirect",
      "expression": "(http.request.full_uri wildcard r\"https://kintokan.live/*\")",
      "description": "load_balancer",
      "enabled": true,
      "action_parameters": {
        "from_value": {
          "status_code": 301,
          "preserve_query_string": true,
          "target_url": {
            "value": "$TARGET_URL"
          }
        }
      }
    }
  ]
}
EOF

else
  echo "Site is up (status $STATUS_CODE), no action needed."
fi