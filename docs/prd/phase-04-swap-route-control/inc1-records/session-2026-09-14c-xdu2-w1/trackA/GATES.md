# Track A — GATES (bd `xdu2` / L-1a W1). PROTOCOL line format:
# `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`
#
# ⚠ A cited line whose hash does not match the binary on disk is a FINDING. Re-hash
# before citing: `shasum -a 256 build/ir-pass/cq-opt`.
#
# BINARIES OF THIS TRACK, in order:
#   5c6f7490a81c7505  the frozen session ORACLE — AND a clean build of this worktree at
#                     `c8007c37` with no edits, which came out BIT-IDENTICAL to it.
#   53d1a4b61b1ef4a7  subject 1: the classifier as first written. TWO OVER-ACCEPTS (H-1, H-13).
#   3f59baa01cfafea6  subject 2: + `getParentLoop` / `isStaticAlloca` / `hasNoSelfWrap`.
#   f2a9c0a49080ad5c  subject 3, SHIPPED: + the `isReachableFromEntry` API precondition.
#   libCQPass.so of the shipped subject: fb543059da3ebc597e8fefd1dc9c1f06e5141c034483b681185ad422f125a1ee

build the worktree (cmake --build build -j8, BOTH targets) | 5c6f7490a81c7505 | clean build at c8007c37, no edits; cq-opt BIT-IDENTICAL to the frozen ORACLE | impl | 2026-09-14
oracle hash verification (shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt) | 5c6f7490a81c7505 | 5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8 — MATCHES the brief; libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4 MATCHES | impl | 2026-09-14
per-probe pipeline, 16 Track L + Track A probes, ORACLE baseline | 5c6f7490a81c7505 | all 16 DECLINE rc=1; 12 of them `cq taint escape: tainted value stored to memory`; N4 `cq QRAM access: array address has aliasing fan-out`; N5_double_write `arm rewrites a condition operand`; A4 CC-FAIL (_BitInt(96) is not a CQ.h _Generic type) | impl | 2026-09-14
build the worktree (cmake --build build -j8) | 53d1a4b61b1ef4a7 | 0 errors, 2 pre-existing -Wunused-parameter warnings (TaintPropagation.cpp:309, :2148) | impl | 2026-09-14
per-probe pipeline, the clause matrix | 53d1a4b61b1ef4a7 | every clause fires its own string; the 6 Bank candidates keep kMsgStore and print the CQ_CTRL_DBG anchor | impl | 2026-09-14
lit --filter railbank | 53d1a4b61b1ef4a7 | 17 of 2011 tests, 17 PASS, 1.41s | impl | 2026-09-14
red half by BINARY (probes/redcheck.sh, each fixture's OWN RUN lines) | 53d1a4b61b1ef4a7 | ORACLE: 16 FAIL / 1 PASS (the PASS is the tainted-index axis non-regression, whose property IS that it does not move); SUBJECT: 17 PASS | impl | 2026-09-14
injection matrix (probes/inject_A.py) | 53d1a4b61b1ef4a7 | 29 mutations over 18 fixtures: 29 caught, MISSED 0, n/a-HOLE 0 — after TWO self-inflicted harness bugs, both recorded in the harness source | impl | 2026-09-14
corpus sweep ORACLE-vs-SUBJECT, ir-pass/test + trackL + trackA probes | 53d1a4b61b1ef4a7 | 2096 rows: 1042 D->D SAME, 1031 A->A SAME, 22 D->D STRMOVE, 1 CLANGERR. **0 VERDICTMOVE, 0 IRDIFF.** All 22 movers are the fixtures/probes this increment authored; `dbg=1->1` on every one (0 lost !dbg, 0 gained). NO pre-existing fixture or probe moved | impl | 2026-09-14
ADVERSARIAL SELF-ATTACK (probes/H1, H13, H17) | 53d1a4b61b1ef4a7 | **TWO OVER-ACCEPTS FOUND**: H1_nested_outer_rewrite and H13_alloca_in_loop both classify `Bank` (cells=3 abi=i8 trips=3). Found AFTER all 18 fixtures green, the corpus clean and the matrix 29/29 | impl | 2026-09-14
build the worktree (cmake --build build -j8) | 3f59baa01cfafea6 | 0 errors; + getParentLoop / isStaticAlloca / hasNoSelfWrap | impl | 2026-09-14
per-probe pipeline, the three self-attacks + the four Bank anchors | 3f59baa01cfafea6 | H1 and H13 now DECLINE `the cell walk is re-executed by an enclosing loop`; H17 still `Bank` (-O1 widened the IV — filed as R-4); all four Bank anchors still anchor | impl | 2026-09-14
build the worktree (cmake --build build -j8) | f2a9c0a49080ad5c | 0 errors; + the isReachableFromEntry API precondition | impl | 2026-09-14
lit --filter railbank | f2a9c0a49080ad5c | 21 of 2015 tests, 21 PASS, 3.37s | impl | 2026-09-14
