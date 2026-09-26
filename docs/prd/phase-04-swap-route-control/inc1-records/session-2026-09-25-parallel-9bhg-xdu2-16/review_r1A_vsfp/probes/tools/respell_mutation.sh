#!/usr/bin/env bash
# Fixture-level mutation of the 29 re-spelled fixtures (+1 converted): copy each as orig__X and
# mut__X (every IR line `%vsfp.read = ...` deleted) into a private lit dir whose lit.site.cfg.py
# loads a COPY of ir-pass/test/lit.cfg.py (so test_source_root is the private dir), then
# `lit .` there. MUT_CQ_OPT selects the binary (default: the SUBJECT). Scratchpad paths.
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rA_vsfp
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
cd $R/litmut/tests
for f in $(git -C $W diff --name-status aee8f4f8 5e56060b -- ir-pass/test | awk '$1=="M"{print $2}' | xargs -n1 basename); do
  cp -f $W/ir-pass/test/$f ./orig__$f
  grep -v '^[[:space:]]*%vsfp\.read' $W/ir-pass/test/$f > ./mut__$f
done
lit -q .
