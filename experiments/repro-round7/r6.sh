#!/bin/bash
# r6.sh <build dir> files...
cd /private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r7-classical/c
B=$1; shift
D=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad4911e61618a65df
for f in "$@"; do
  r=$(CQ_BUILD_DIR=$B perl -e 'alarm 280; exec @ARGV' $D/driver/cqcc -S --cq-check --cq-entry f $f -o out/r6.$(basename $f).ll 2>&1 | tail -1 | cut -c1-150)
  echo "$(basename $f): $r"
done
