#!/usr/bin/env python3
"""ARM group gate — attribute every corpus mover PER TRACK, BY STRING.

Input A: this gate's two-column sweep on the COMBINED binary
         <relpath>|ORACLE|MERGED                       (gate_sweep.py)
Input B: the Rule-13 round's four-column sweep, joined on relpath
         <relpath>|ORACLE|BASE_F|SUBJ_P|P_ALONE        (review_r13_armclassify/probes/sweep4_*.txt)

⚠ ⚠ THAT COLUMN ORDER IS **NOT** THE ONE THE COMMITTED FILE'S OWN HEADER CLAIMS,
AND THE DIFFERENCE INVERTS THE MOST IMPORTANT CLASSIFICATION IN THE TABLE.
`sweep4.sh` labels its rows `relpath|ORACLE|BASE_F|P_ALONE|SUBJ_P` (and REVIEW.md
§7 copies that label), but the loop that writes them is

    for d in .../CQ_lang/build .../CQ_F/build .../CQ_P/build $SCR/R4/build

and `CQ_P` is the COMPOSED worktree (SUBJ_P) while `$SCR/R4` is the one this
round built for `main`+P′ alone (P_ALONE). **Columns 3 and 4 are therefore
transposed with respect to the label.** Read AS LABELLED, the two rows the
reviewer correctly reports as F′-only come out as **REVERSION** — the single
classification REVIEW.md says "must not happen".

MEASURED, over all 2047 committed rows, which is why this is a fact and not a
reading:
    AS LABELLED  O|BF|PA|SP : identical 2042, REVERSION 2, P'-only 3
    AS EMITTED   O|BF|SP|PA : identical 2042, F'-only  2, P'-only 3
    REVIEW.md §7 REPORTS    : identical 2042, F'-only  2, P'-only 3, 0 REVERSION
Only the emitted order reproduces the reported counts, so **the reviewer's
CONCLUSIONS are correct and only the committed LABEL is wrong** — the classifier
was applied with the true semantics and the header was mis-transcribed. This
script uses the EMITTED order and says so; an erratum is appended to
`review_r13_armclassify/probes/sweep4.sh` in the same change (L7-with-a-twist: a
record correction that is not applied to the source is not a correction).

⚠ THE JOIN IS ONLY LEGAL IF THE CELL FORMATS AGREE, so that is CHECKED rather
than assumed: the ORACLE column is measured independently in both files and must
agree row for row. Any disagreement is reported and the join for that row is
refused — an instrument whose own precondition fails must say so, not quietly
produce a table (L10).

Classification of a MERGED-vs-ORACLE mover, using B's columns:
  F'-only    ORACLE == P_ALONE != BASE_F == SUBJ_P
  P'-only    ORACLE == BASE_F  != SUBJ_P == P_ALONE
  COMPOSED   ORACLE == BASE_F  == P_ALONE != SUBJ_P
  REVERSION  ORACLE == SUBJ_P  != BASE_F
  UNATTRIBUTED  anything else, or no row in B  -> A FINDING
And independently: MERGED must equal SUBJ_P on EVERY row (this gate's fixes are
comment-only and its binary is bit-identical to SUBJ_P, so any inequality is
either a fix that was not comment-only or a broken join).
"""
import os
import sys
from collections import Counter

ROOT = "/Users/sorenwilkening/Desktop/CQ_ARM"
SES = (f"{ROOT}/docs/prd/phase-04-swap-route-control/inc1-records/"
       "session-2026-09-15-orchestrator")
A_PATH = sys.argv[1]
B_PATH = f"{SES}/review_r13_armclassify/probes/sweep4_3bb2fd4d.txt"

A, B = {}, {}
for line in open(A_PATH):
    p = line.rstrip("\n").split("|")
    if len(p) == 3:
        A[p[0]] = p[1:]
for line in open(B_PATH):
    p = line.rstrip("\n").split("|")
    if len(p) == 5:
        B[p[0]] = p[1:]

print(f"rows measured here : {len(A)}")
print(f"rows in the R-13 4-binary file: {len(B)}")
joined = [k for k in A if k in B]
print(f"joined on relpath  : {len(joined)}")

# --- precondition: the two independently measured ORACLE columns must agree ---
oracle_mismatch = [k for k in joined if A[k][0] != B[k][0]]
print(f"\nPRECONDITION — ORACLE column agreement over the join: "
      f"{len(joined) - len(oracle_mismatch)}/{len(joined)} agree")
if oracle_mismatch:
    print("  ⚠ JOIN REFUSED on these rows (cell formats differ). KNOWN, ONE ROW:")
    print("    this gate's hasher appends a trailing newline to reproduce `grep`'s")
    print("    output, which differs from `md5 -q` of a TRULY EMPTY lowered module")
    print("    (md5 of '\\n' vs md5 of ''). Same VERDICT, different byte. Cosmetic.")
    for k in oracle_mismatch[:10]:
        print(f"    {k}\n      here={A[k][0]}\n      R13 ={B[k][0]}")
    if len(oracle_mismatch) > 10:
        print(f"    ... and {len(oracle_mismatch) - 10} more")

good = [k for k in joined if k not in set(oracle_mismatch)]

# --- MERGED must equal SUBJ_P everywhere ---
subjp_diff = [k for k in good if A[k][1] != B[k][2]]  # col 3 IS SUBJ_P
print(f"\nMERGED == SUBJ_P over the join: {len(good) - len(subjp_diff)}/{len(good)}")
for k in subjp_diff[:20]:
    print(f"  ⚠ DIFFERS: {k}\n      MERGED={A[k][1]}\n      SUBJ_P={B[k][2]}")

# --- movers, attributed ---
def classify(o, bf, pa, sp):
    if o == bf == pa == sp:
        return "identical"
    if o == pa and bf == sp and o != bf:
        return "F'-only"
    if o == bf and sp == pa and o != sp:
        return "P'-only"
    if o == bf == pa and sp != o:
        return "COMPOSED"
    if o == sp and bf != o:
        return "REVERSION"
    return "UNATTRIBUTED"

counts = Counter()
movers = []
for k in good:
    o, m = A[k]
    if o == m:
        counts["identical (ORACLE == MERGED)"] += 1
        continue
    # B[k] is [ORACLE, BASE_F, SUBJ_P, P_ALONE] as EMITTED; classify() takes
    # (o, bf, pa, sp), so columns 3 and 4 are passed in swapped ON PURPOSE.
    cls = classify(B[k][0], B[k][1], B[k][3], B[k][2]) if k in B else "UNATTRIBUTED (no R-13 row)"
    counts[cls] += 1
    movers.append((k, cls, o, m))

print("\n--- ORACLE vs MERGED, movers attributed per track ---")
for k, v in sorted(counts.items()):
    print(f"  {v:5d}  {k}")
print(f"\nmovers ({len(movers)}):")
for k, cls, o, m in sorted(movers):
    print(f"  [{cls:>12}] {k}\n      ORACLE={o}\n      MERGED={m}")

unjoined = [k for k in A if k not in B]
print(f"\nrows measured here with NO R-13 row (probe corpora, not in that "
      f"sweep's scope): {len(unjoined)}")
un_movers = [k for k in unjoined if A[k][0] != A[k][1]]
print(f"  of which MOVE ORACLE->MERGED: {len(un_movers)}")
for k in sorted(un_movers):
    print(f"    {k}\n      ORACLE={A[k][0]}\n      MERGED={A[k][1]}")

empt = [k for k in A if A[k][0] == "EMPTY"]
print(f"\nEMPTY (0-byte) modules, scored EMPTY not ACCEPT: {len(empt)}")
for k in sorted(empt):
    print(f"    {k}")

bad = len(oracle_mismatch) + len(subjp_diff) + counts["UNATTRIBUTED"]
print("\nRESULT:", "FINDINGS PRESENT" if bad else
      "clean — every mover attributed, MERGED == SUBJ_P, ORACLE columns agree")
