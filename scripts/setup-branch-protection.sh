#!/usr/bin/env bash
set -euo pipefail

# Applies branch protection (as a ruleset) to the default branch of a repo.
# Usage: ./setup-branch-protection.sh <owner>/<repo> <check-name> [<check-name> ...]
# Example: ./setup-branch-protection.sh M-K0s/secure-deploy-kit diff-scan audit

REPO="${1:-}"
shift || true
CHECKS=("$@")

if [ -z "$REPO" ] || [ "${#CHECKS[@]}" -eq 0 ]; then
  echo "Usage: $0 <owner>/<repo> <check-name> [<check-name> ...]"
  echo "Example: $0 M-K0s/secure-deploy-kit diff-scan audit"
  exit 1
fi

echo "Applying branch protection ruleset to $REPO"
echo "Required checks: ${CHECKS[*]}"

CHECKS_JSON=""
for check in "${CHECKS[@]}"; do
  if [ -n "$CHECKS_JSON" ]; then
    CHECKS_JSON="${CHECKS_JSON},"
  fi
  CHECKS_JSON="${CHECKS_JSON}{\"context\":\"${check}\"}"
done

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/rulesets" \
  --input - << JSON
{
  "name": "main-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [${CHECKS_JSON}],
        "strict_required_status_checks_policy": false
      }
    }
  ]
}
JSON

echo "Done. Check https://github.com/${REPO}/rules to confirm."
