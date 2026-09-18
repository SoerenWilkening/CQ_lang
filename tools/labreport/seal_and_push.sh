#!/bin/bash
# seal_and_push.sh <entry.tex> — bd `test_C_libtooling-6hy4`, THE ORDERING FIX.
#
# ⚠ THIS SCRIPT EXISTS BECAUSE AN ERRATUM PREVENTED NOTHING, THREE TIMES.  Entry
# 012 recorded a close hash that `git pull --rebase` had rewritten; entry 013
# carried the erratum FOR 012 and then repeated it about ninety seconds after
# sealing.  The cause is not care, it is ORDERING: the close hash is read from
# HEAD *before* the rebase that rewrites every unpushed commit, so no amount of
# attention at the writing step can fix a value computed too early.
#
# THE ORDER, and the whole point is that it is not optional:
#   pull --rebase  ->  read HEAD  ->  write the header  ->  seal  ->  commit  ->  push
#   -> then VERIFY with `git merge-base --is-ancestor`, which is the only step
#      that actually closes the loop and costs one second.
#
# ⚠ AND IF THE PUSH IS REJECTED AND A SECOND `pull --rebase` IS NEEDED, THE HASH
# MOVES AGAIN — so the verify runs AFTER the push, every time, and a `false` is
# an erratum owed IMMEDIATELY, not next session.
#
# The SEALING COMMIT's own hash is unknowable at seal time and that is fine: the
# close hash names the last commit of the session's WORK, not the commit that
# seals the record of it.  What must be stable is the former, and after the
# rebase it is.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ENTRY="${1:?usage: seal_and_push.sh docs/labreport/sessions/NNN-YYYY-MM-DD-slug.tex}"
[ -f "$ENTRY" ] || { echo "no such entry: $ENTRY" >&2; exit 2; }

echo "==> 1/6  integrate upstream   (hashes are final only after this)"
# ⚠ `git pull --rebase` FLATTENS MERGE COMMITS, AND IT DOES SO EVEN WHEN THERE IS
# NOTHING TO PULL.  Found on this script's FIRST REAL USE (2026-09-21): the branch
# carried a `--no-ff` merge, `origin/main` was 0 commits ahead, and the rebase
# still tried to replay the merge's second parent as an ordinary commit and
# stopped on a conflict that had already been resolved once.  A close procedure
# that rewrites the history it is recording is worse than the defect it fixes.
#
# So: integrate ONLY if there is something to integrate, and preserve merge
# topology when doing it.
git fetch origin
UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "origin/$(git rev-parse --abbrev-ref HEAD)")
BEHIND=$(git rev-list --count "HEAD..$UPSTREAM" 2>/dev/null || echo 0)
if [ "$BEHIND" -eq 0 ]; then
  echo "         nothing upstream ($UPSTREAM is not ahead) — no rebase, no rewrite"
else
  echo "         $BEHIND commit(s) upstream; rebasing WITH merge topology preserved"
  git rebase --rebase-merges "$UPSTREAM"
fi

H=$(git rev-parse --short=8 HEAD)
echo "==> 2/6  close hash = $H"

if grep -q "{$H}" "$ENTRY"; then
  echo "         header already carries $H"
else
  OLD=$(grep -oE '^\s*\{[0-9a-f]{8}\}' "$ENTRY" | head -1 | tr -d ' {}') || true
  if [ -n "${OLD:-}" ]; then
    echo "         rewriting header hash $OLD -> $H"
    sed -i '' "s/{$OLD}/{$H}/" "$ENTRY"
  else
    echo "!! could not find an 8-hex close hash in $ENTRY — write it by hand as {$H}" >&2
    exit 3
  fi
fi

echo "==> 3/6  seal"
tools/labreport/build.py --seal

echo "==> 4/6  commit"
git add -A docs/labreport
git commit -m "docs(labreport): $(basename "$ENTRY" .tex) sealed — close hash $H"

echo "==> 5/6  push"
git push

echo "==> 6/6  VERIFY — the step that actually closes the loop"
if git merge-base --is-ancestor "$H" main; then
  echo "    OK: $H is reachable from main."
else
  echo "!!  $H is NOT reachable from main.  AN ERRATUM IS OWED IMMEDIATELY," >&2
  echo "!!  in this session, not the next one.  Correct hash: $(git rev-parse --short=8 HEAD)" >&2
  exit 1
fi
