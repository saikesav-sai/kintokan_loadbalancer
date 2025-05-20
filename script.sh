#!/bin/bash

# CONFIGURE THESE
ZONE_ID="8573ed2f9df102b5e754a28398011500"
API_TOKEN="7a144fd0ffb2eda66e9156cfb8553f9e76aa9"
RULESET_ID="5908984c42af4df08cebd4d23d1023e9"
RULE_ID="0f4c230f45a04cad8b3b305a00d6cec2"
CURRENT_RULE_VERSION="3"
RULESET_VERSION="8"



# 1. Check if site is up
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://kintokan.live)


# 2. If site is down (non-200), update the redirect
if [[ "$STATUS_CODE" -ne 200 ]]; then
  echo "Site is down (status $STATUS_CODE), updating redirect to server2..."

  curl -s -o /dev/null -X PUT  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/$RULESET_ID" \
    -H "X-Auth-Email: kintokanitsolutions@gmail.com" \
    -H "X-Auth-Key: $API_TOKEN"\
    --data '{
    "name": "default",
    "description": "",
    "kind": "zone",
    "phase": "http_request_dynamic_redirect",
    "version": "$RULESET_VERSION",
    "rules": [
      {
        "id": "$RULE_ID",
        "ref": "$RULE_ID",
        "version": "$CURRENT_RULE_VERSION",
        "action": "redirect",
        "expression": "(http.request.full_uri wildcard r\"https://kintokan.live/*\")",
        "description": "load_balancer",
        "enabled": true,
        "action_parameters": {
          "from_value": {
            "status_code": 301,
            "preserve_query_string": true,
            "target_url": {
              "value": "https://server1.kintokan.live"
            }
          }
        }
      }
    ]
  }'

else
  echo "Site is up (status $STATUS_CODE), no action needed."
fi