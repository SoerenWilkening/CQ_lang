#!/bin/bash
# eq.sh TAG SUBJ TWIN [TWIN_TAG]: byte compare + rhk5's trace_twin_equiv.py (read from the rhk5 r2 worktree) on
# the traces rv.sh last wrote. Re-run rv.sh with the same args for both before calling.
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
TE=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9/tools/trace_twin_equiv.py
D=${OUT:-$SP/r1B_out}
a=$D/$2.$1.trace; b=$D/$3.${4:-$1}.trace
[ -f "$a" ] || { echo "$1 $2 vs $3: NO-SUBJ-TRACE"; exit; }
[ -f "$b" ] || { echo "$1 $2 vs $3: NO-TWIN-TRACE"; exit; }
if cmp -s "$a" "$b"; then byte=IDENT; else byte=DIFF; fi
e=$(python3 $TE "$a" "$b" 2>&1 | tail -1 | cut -c1-110)
echo "$1 $2 vs $3${4:+@$4}: byte=$byte equiv=[$e]"
