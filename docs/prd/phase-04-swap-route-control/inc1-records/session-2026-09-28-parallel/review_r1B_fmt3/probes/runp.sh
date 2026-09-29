#!/bin/bash
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/r1B_fmt3
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
p=$1; shift
$S/pipe.sh $S/probes/$p.c $p.NEW $W/include "$@"
$S/pipe.sh $S/probes/$p.c $p.OLD $S/oldinc "$@"
