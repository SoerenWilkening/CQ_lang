; control_inplace_ry_reject_stateprep_sunk_arith.ll — DECLINE, AND IT IS THE
; INCREMENT'S HEADLINE OVER-DECLINE, FOUND BY THE `--stateprep` TWIN MATRIX AND
; NOT BY THE POSITIVE SUITE (bd test_C_libtooling-drbq Inc 4; PRD §14.3's
; consumer rows are CORRECTED by this fixture).
;
;     int r = 0;  if (q == 5) r = cq_theta(0, .9);
;     int s = r * 3;                    /* ANY post-region op on r */
;
; ⚠ `clang -O1` SINKS THAT `mul` INTO THE ARM. It can, and only for THIS arm
; class: the straight-through value of `r` is a compile-time CONSTANT, so on that
; edge `r * 3` folds to `0` and the op has one live use left — inside the arm.
; The module the pass sees is therefore
;
;     arm:   %rt = call cq_theta_si32(i32 0, .9)
;            %rs = mul nsw i32 %rt, 3          <-- SUNK
;     merge: %rm = phi [ %rs, %arm ], [ 0, %entry ]
;
; which is not the §14.1 accept shape at all: the merge's arm incoming is a
; `mul`, not the theta, and the arm block holds TWO instructions. R1's shape half
; refuses it (`RegionFlatten` erases the arm block, so a stray op would be
; SILENTLY DROPPED and its taint work-list pointer would dangle), and the region
; declines with the generic string.
;
; ⚠ THE CHAINED TWIN DOES NOT HAVE THIS PROBLEM, WHICH IS EXACTLY WHY IT WENT
; UNNOTICED. With `int r = cq_theta(0, 0.0);` the straight-through value is a
; live REGISTER, `r * 3` does not fold on that edge, and `-O1` leaves the `mul`
; after the merge — so the Inc-1 shape accepts. MEASURED as 48 of the 297
; `--stateprep` twin-matrix cells reading SUBJECT-DECLINES-TWIN-ACCEPTS with the
; `control flow` message — 12 each of the four arithmetic consumers (`mul3`,
; `spine`, `deadadd`, `deadmul`) — plus the three `printf` cells at i8/i64/f64,
; where the sunk op is the `(int)` CAST and the string is `value-arm swap-route`.
; `printf_i32` needs no cast and is IDENTICAL, which is the control.
;
; ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L7 finding F-L7-4): NOT
; "across every cfg, cond and width". Re-counted from the committed post-4 table:
; the 48 sit at cfg `diamond` (40), `clsbefore` (4) and `negated` (4), and
;
;   * `clsbetween` contributes **ZERO** — all four of its arithmetic cells read
;     IDENTICAL, and that is the POSITIVE CONTROL FOR THE MECHANISM rather than
;     an exception to it: a second region between the prep and the op makes `r`'s
;     straight-through value NON-CONSTANT, so nothing folds, so nothing sinks;
;   * the four `ifelse` arithmetic cells DO decline, but on `rotation angle`
;     (`-O1` merges the two arms into one theta with an angle select, S3), not on
;     this fixture's clause, so they are not members of this class either.
;     ⚠ bd test_C_libtooling-fmt3 (2026-09-28): with `nomerge` on every `cq_theta_*`
;     the `ifelse` cells are no longer merged into an angle select, so the `rotation
;     angle` disposition above is PRE-fmt3; their post-fmt3 disposition was NOT
;     re-measured by fmt3 (the cells are not in the e2e or lit corpora).
;
; Read as "48 cells in ONE class, with two measured cfgs that show the class's
; own boundary" — a characterization, not a count of everything that declines.
;
; ⚠ PRD §14.12 WORRY 8 PREDICTED THIS EXACTLY, and the prediction is the reason
; the fixture exists: *"three of my accept rows are consumer-axis rows I did not
; compile as accepts, because none of them can compile until the fence exists …
; the DER lesson says that is exactly where a vacuous accept hides."* The probe
; family could only measure that the DIAMOND survives `-O1` for each consumer; it
; could not measure what `-O1` does to the ARM once the region is lowerable.
;
; WHAT WOULD BE NEEDED, stated so the decline is not mistaken for a fence:
; supporting `arm = { state-prep theta, value-op chain }` is a NEW CAPABILITY —
; a value arm whose base is a rail minted inside the arm — and F1 would then have
; to read "the Pred incoming is the arm's op chain CONST-FOLDED over the seed"
; rather than "the Pred incoming IS the seed". That is a design, not a relaxation,
; and it is on the owner's desk (notes §8).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  %rs = mul nsw i32 %rt, 3
  br label %merge
merge:
  %rm = phi i32 [ %rs, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
