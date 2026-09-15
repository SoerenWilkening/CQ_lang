#!/bin/zsh
# sweep4.sh <file.ll> -> one row: relpath|ORACLE|BASE_F|SUBJ_P|P_ALONE  (SEE ERRATUM AT EOF; the original label said |P_ALONE|SUBJ_P and was WRONG)
f="$1"
SCR=$SCRATCH
t=$(mktemp -d)
row="$f"
for d in /Users/sorenwilkening/Desktop/CQ_lang/build /Users/sorenwilkening/Desktop/CQ_F/build /Users/sorenwilkening/Desktop/CQ_P/build $SCR/R4/build; do
  err="$t/e"; out="$t/o.ll"
  "$d/ir-pass/cq-opt" -load-pass-plugin "$d/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$out" 2>"$err"; rc=$?
  if [ $rc -eq 0 ]; then
    if [ ! -s "$f" ]; then cell="EMPTY"; else cell="A:$(grep -v '^; ModuleID\|^source_filename' "$out" | md5 -q)"; fi
  else
    # full stderr, argv/stack-dump normalised away (PROTOCOL S3 + Track P's correction)
    cell="D$rc:$(grep -v 'Stack dump\|Program arguments\|^ *#[0-9]\|PLEASE submit\|^0x\|^[0-9]\+\.' "$err" | md5 -q)"
  fi
  row="$row|$cell"
done
rm -rf "$t"
echo "$row"

# ─────────────────────────────────────────────────────────────────────────────
# ⚠ ERRATUM, appended 2026-09-15 by the ARM group gate (armgate/GATE.md).
#
# THE COLUMN LABEL ON LINE 2 IS WRONG, AND THE ERROR INVERTS THE ONE
# CLASSIFICATION REVIEW.md SAYS "MUST NOT HAPPEN".
#
# The loop above visits
#     .../CQ_lang/build   .../CQ_F/build   .../CQ_P/build   $SCR/R4/build
# and `CQ_P` is the COMPOSED worktree (SUBJ_P) while `$SCR/R4` is the binary
# this round built for `main` + P' alone (P_ALONE). So the rows it writes are
#
#     relpath|ORACLE|BASE_F|SUBJ_P|P_ALONE          <-- WHAT IS EMITTED
#
# not the `relpath|ORACLE|BASE_F|P_ALONE|SUBJ_P` of line 2 (a label REVIEW.md
# section 7 copies verbatim). Columns 3 and 4 are TRANSPOSED with respect to
# the label.
#
# MEASURED over all 2047 committed rows of sweep4_3bb2fd4d.txt:
#     AS LABELLED  O|BF|PA|SP : identical 2042, REVERSION 2, P'-only 3
#     AS EMITTED   O|BF|SP|PA : identical 2042, F'-only  2, P'-only 3
#     REVIEW.md section 7     : identical 2042, F'-only  2, P'-only 3, 0 REVERSION
#
# ⚠ ONLY THE EMITTED ORDER REPRODUCES THE REPORTED COUNTS, so the reviewer's
# CONCLUSIONS ARE CORRECT and only this label is wrong — the classification was
# done with the true semantics and the header was mis-transcribed. REVIEW.md's
# own section 6 sentence "(mine, four binaries, ORACLE/BASE_F/SUBJ_P/P_ALONE)"
# uses the TRUE order, which is the second piece of evidence for that reading.
#
# ⚠ WHY THIS IS WORTH AN ERRATUM RATHER THAN A SHRUG (CLAUDE.md L10 — an
# instrument's failure mode is to report a PASS, or here a plausible-looking
# wrong label): a future reader taking line 2 at face value reads the two
# genuine F'-only rows as REVERSIONS and opens an investigation into a defect
# that does not exist, or — worse in the other direction — reads a real
# reversion as F'-only and closes one that does. The rows themselves are sound;
# do NOT regenerate them.
#
# The ARM gate's `armgate/probes/attribute.py` consumes this file in the EMITTED
# order and carries the same paragraph.
