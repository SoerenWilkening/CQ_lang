; control_angle_select_phase_nonfinite_arm.ll — ACCEPT, and it records a
; DECISION, not a capability (bd test_C_libtooling-3qlq Inc 1 part A, Rule-13
; round-1 finding F-L4-1, the second half).
;
;     if (q == 5) cq_phi(INFINITY); else cq_phi(0.3);
;
; A NON-FINITE constant arm PASSES THROUGH to `cqrt_rz_i1(f, inf)`. That is
; deliberate, and this file exists so nobody "fixes" it later by re-enabling the
; whole 2b arm-value fence on this stem.
;
; WHY IT IS RIGHT HERE AND WRONG ON THE Ry STEM. `angleSelectArmsAdmissible`'s
; non-finite clauses exist because the by-difference lowering realizes `A − B` as
; a `double` the source never wrote: two FINITE arms can produce a non-finite
; DIFFERENCE (measured, from ±8.99e307), so the fence stops the compiler from
; manufacturing a value the program does not name. The register-free phase stem
; performs NO subtraction at all — `P(inf)` here is exactly the angle the source
; asked for, `inf` in and `inf` out.
;
; THE PRECEDENT IS ALREADY SHIPPED AND WAS MEASURED FOR THIS FINDING: an
; UNCONTROLLED `cq_theta(&q, INFINITY)` passes through on BOTH binaries
; ($SP/progress/review_r1_L4/repro/unc_inf.ll, exit 0). Refusing it under control
; while accepting it uncontrolled would be a fence on the CONTROL, not on the
; value, which is not a distinction the physics supports.
;
; WHAT IS *NOT* passed through, and it is the contrast that makes this file
; meaningful — an `undef`/`poison` arm DECLINES —
; `control_angle_select_phase_reject_{undef,poison}_arm.ll`. `inf` is a number
; the source named; `undef` is not a number at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll

; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x7FF0000000000000), !cq.branchphase

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE. NOTHING computes a difference: no
; `fsub` is minted, which is the structural reason the non-finite clauses have no
; subject on this stem.
; NOROUTE-NOT: fsub
; NOROUTE-NOT: fneg
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.

; The `cqrt_x` census. An UNPAIRED bracket is a wrong-branch phase.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(



; ── THE BRANCH-PHASE RECORD, COUNTED — Rule-13 round-2 finding F-R2-7 ────────
; The `!cq.branchphase` record is what stops the whole-DAG spine adjointing a
; kickback gate (round-1 F-L7-1, a CONFIRMED miscompile that cancelled the user's
; phase EXACTLY). It is minted at SIX emission sites, and until this file grew
; the two directives below the `AngleSelectEmit` stem — TWO of those six —
; was pinned by exactly ONE fixture in 1665, whose own stated subject is the
; deliberate `inf`-arm pass-through. Dropping the mark at `AngleSelectEmit.cpp`
; reddened one file. It now reddens three, and the two flagship P2 accepts are
; two of them.
;
; MDCNT counts the GATES, MDTAG counts the MARKED gates, in separate prefixes so
; the two questions cannot be answered by one directive. They must AGREE. (Read
; the pair precisely — round-2 F-R2-11: an unmarked gate BEFORE the marked one
; moves only MDCNT, a dropped mark moves only MDTAG, and an extra marked gate
; after moves both. All three are caught; only the second is what F-L7-1 was.)
; MDCNT-COUNT-2: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-2: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @slice(i32 %0) {
  %2 = call i32 @cq_theta_si32(i32 %0, double 5.000000e-01)
  %3 = icmp eq i32 %2, 5
  %4 = select i1 %3, double 0x7FF0000000000000, double 3.000000e-01
  call void @cq_phi(double %4)
  %5 = call i32 @cq_measure_si32(i32 %2)
  ret i32 %5
}
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
define i32 @main() { %1 = call i32 @slice(i32 5) ret i32 0 }
