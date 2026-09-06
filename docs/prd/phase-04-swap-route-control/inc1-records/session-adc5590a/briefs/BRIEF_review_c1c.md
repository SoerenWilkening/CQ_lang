# BRIEF_review_c1c — ONE narrow Rule-13 lens on the THIRD C-1 round (the narrowing of round 2), READ-ONLY
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1c.md`, `$SP/progress/review_c1b.md` (the lens that found
F-C1B-1/2 — reproducers under `$SP/progress/review_c1b_work/p/`, the `CQ_DBG` copy under `…/dbgtree`), then
`$SP/progress/fix_c1c.md` IN FULL, and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.10–§3.11 + the §2 ⭐ table row it added.
Agent name: `review_c1c`. Model: opus. READ-ONLY on every checkout (write only under `$SP/progress/review_c1c_work/`).

## Binaries (name every path you use)
SUBJECT `$SP/wt/fix-c1` at dec2019 (build current — verify) · FIX-2 `$SP/progress/fix_c1c_work/{cq-opt.fix2,
libCQPass.so.fix2}` (638334c) · FIX-1 `$SP/progress/fix_c1b_work/*.fix1` (3ec40c9) · PRE-FIX main checkout 542d588 ·
ORACLE `$SP0/wt/pre-3qlq`. Control the harness (clean + known-bad) before trusting a number.

## The one question: is round 3 a pure NARROWING, and does it close F-C1B-1 completely?
1. **F-C1B-1 closed?** The four reproducers (`z23`, `z26`, `z27`, `z29`) on the subject: NO `cqrt_{addc,xorc}_i32`
   whose operand is a handle anywhere in the lowered IR; the emitted stream byte-identical to FIX-1's (the
   out-of-place `cq_template_add_i32(h,h)` + `_unc` + free). Then ATTACK the `isa<Constant>` fence: a `ConstantExpr`
   immediate; a `Constant` that is a `GlobalVariable` address / `ptrtoint`; `undef`/`poison` as the immediate;
   a vector constant; a constant at a different width (`i64` op, `i8` op); the op written as `sub`/`or`/`and`
   (which opcodes does `classifyInPlaceReassignment` admit at all?); the immediate a `Constant` but `P` (the
   rail operand) becoming a DIFFERENT wire at round 2 (can the flatten RAUW `P`?); the op's RESULT gaining a
   round-2 user (a merge phi RAUW'd to `%out`); the op moved INTO a loop by the flatten (can it?). For each:
   accept-and-correct (twin-identical), refuse (byte-identical to FIX-2 minus the miscompile), or loud decline —
   never a handle in the immediate slot, never K adjoints of one gate.
2. **The tripwire (1b)**: does it fire where the fix agent says (its mirror fixture is RED without it — re-run the
   mutation on a scratch copy only); is it asked ONLY of the ops this stage committed (not of the collapse's body
   markings — a body marking must never trip it: measure `d1i`, `d10`, `n1`, `z6`); is its string mirrored
   character-for-character; is there any path where the re-ask says "changed" and the module is still emitted?
3. **F-C1B-2 closed?** `z32` unmarked (leak-control byte-identical to FIX-1); `r33`/`r35`/`r40`/`z9`/`z10` still
   3/3 IDENTICAL; construct: the SAME root claimed in loop A and legitimately read invariant in loop B (no gate in
   B) — must be served by clause (ii) not clause (0); a loop whose header is the pred of a flattened region (does
   the header pointer survive the flatten? if the key is the header block, prove it; if not, what was used?);
   a root claimed by Case A whose loop is later DELETED/unrolled (LoopUnrollPrepass?) — a dangling key?
4. **Pure narrowing, measured**: the whole population (round 1 §3.5 + review_c1's 60 + fix_c1b's + review_c1b's
   51 + fix_c1c's), FIX-2 vs subject: the ONLY moved traces are the four F-C1B-1 reproducers, `z21`, and what the
   per-loop key refuses (list them) — every other trace byte-unchanged; NO new accept anywhere (every
   FIX-2-decline still declines with the same string; every FIX-2-leak still leaks or declines).
5. **Record truth, briefly**: the §3.11 input-stability table's claims each reproduce (or say which you could
   not test); the §2 row is true of the binary; counts by command (lit, ctest, matrix); red-greens reproduce.
Grade: `CONFIRMED-MISCOMPILE` / `LEAK` / `OVER-DECLINE` / `DOC` / `CLEAR`. Write `$SP/progress/review_c1c.md`
(findings F-C1C-k, reproducers under `$SP/progress/review_c1c_work/`, what you ran, verdict line `CLEAR` /
`CLEAR-WITH-ITEMS` / `FINDINGS`). Return it as your final message.
