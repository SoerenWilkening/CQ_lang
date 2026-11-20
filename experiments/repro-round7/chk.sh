#!/bin/bash
# chk.sh <build dir> <file.c> [entry]
cd /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r7-classical/c
D=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad4911e61618a65df
tag=$(basename $(dirname $1))
CQ_BUILD_DIR=$1 perl -e 'alarm 280; exec @ARGV' $D/driver/cqcc -S --cq-check --cq-entry ${3:-f} $2 -o out/$(basename $2).$tag.ll 2>&1 | tail -${LINES_:-4}
echo "rc=${PIPESTATUS[0]}"
