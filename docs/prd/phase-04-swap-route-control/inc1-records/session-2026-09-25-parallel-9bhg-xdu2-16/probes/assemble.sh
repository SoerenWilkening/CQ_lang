#!/bin/bash
# assemble.sh <probe> <fixture-name>: write ir-pass/test/<fixture-name>.ll as
# hdr/<fixture-name>.hdr followed by a blank line and <probe>.s1.ll.
set -e
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/p9
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
src=$S/$1.s1.ll
[ -n "$3" ] && src=$3
{ cat "$S/hdr/$2.hdr"; echo; cat "$src"; } > "$W/ir-pass/test/$2.ll"
echo "wrote $W/ir-pass/test/$2.ll"
