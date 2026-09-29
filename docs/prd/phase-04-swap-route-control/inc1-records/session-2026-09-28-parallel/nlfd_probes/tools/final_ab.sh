#!/bin/bash
# final_ab.sh : rebuild the corpus, run the NULL control (SUBJECT vs SUBJECT) FIRST, then
# ORACLE -> SUBJECT and stage-A -> SUBJECT and stage-B -> SUBJECT, and the drop census.
set -u
H=$(cd "$(dirname "$0")" && pwd); R=$H/../results
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
S=$W/build/ir-pass/cq-opt; O=$SP/frozen/cq-opt.main_9a230646
rm -rf "$SP/nlfd/corpus"
python3 "$H/ab.py" --build > "$R/final_corpus_build.txt" 2>&1
python3 "$H/ab.py" "$S" "$S" > "$R/final_ab_null_SS.txt" 2>&1
python3 "$H/ab.py" "$O" "$S" > "$R/final_ab_OS.txt" 2>&1
python3 "$H/ab.py" "$SP/nlfd/bin/cq-opt.A" "$S" > "$R/final_ab_AS.txt" 2>&1
python3 "$H/census.py" "$O" "$S" > "$R/final_census_OS.txt" 2>&1
echo done
