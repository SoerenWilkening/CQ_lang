#!/bin/bash
# corpus_par.sh A B OUT — parallel (6) A/B over every ir-pass/test/*.ll; bash only.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
HERE=$(cd "$(dirname "$0")" && pwd)
ls "$W"/ir-pass/test/*.ll | xargs -P 6 -n 1 "$HERE/corpus_one.sh" "$1" "$2" > "$3"
echo "DENOM $(wc -l < "$3" | tr -d ' ') MOVERS $(grep -c '^MOVER' "$3") ACCEPT_A $(grep -c ' A:rc=0' "$3") ACCEPT_B $(grep -c ' B:rc=0' "$3")"
