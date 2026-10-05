; loop_caseA_postloop_region_handoff_reject_value_arm.ll — DECLINE (bd
; test_C_libtooling-wt8u's hazard probe; a known OVER-decline, see the trigger).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int slice(int n) {
;       int q = 0; cq_theta(&q, .5);
;       int r = 0; cq_theta(&r, .25);
;       cq_theta(&r, q == 5 ? .9 : .3);
;       for (int i = 0; i < n; i++) cq_theta(&r, .1);
;       if (q == 3) { r ^= 2; r += 5; r ^= 7; r += 9; r ^= 11; r += 13; }
;       return cq_measure(q) + cq_measure(r);
;     }
;
; (The arm is long so that `-O1` keeps the diamond; `if (q == 3) r ^= 2;` alone
; is if-converted to a tainted `select` and never reaches the hand-off.)
;
; WHAT IT PINS. Before wt8u, `tryCaseA`'s fixpoint absorbed the arm's
; `%18 = xor %9, 2` (an in-place shape on the loop's exit φ) and the region's
; merge φ, and its accept MARKED the xor in place: an UNCONDITIONAL
; `cqrt_xorc(h_r, 2)` for an op the source runs only when q == 3. Only the
; collapsed merge φ (detection then declined `control flow`) kept that mark from
; the backend. After wt8u the arm and its merge are handed to the control chain
; and nothing in the arm is marked; the value arm then declines at the
; routed-base wire fence (`classifyArms`, `findNonDiagonalWireGate` asked
; POSITION-FREE): the collapse renames the loop's exit φ to r's root mint, and
; the root's forward wire carries `T` and the loop's Ry, both of which run
; BEFORE the region. Loud, so safe; an over-decline (R1 gap), not a hazard.
;
; RETIREMENT TRIGGER: when that routed-base fence asks POSITIONALLY (a gate
; after the region's pred), this module must ACCEPT with the no-loop twin's
; stream after the loop: `%op = cq_template_xor_i32_hl(h_r, 2)`, `addc/xorc` on
; `%op` (never on h_r), `f = icmp_eq_hl(h_q, 3)`, `%out = alloc`, two
; X-bracketed `cqrt_copy_i32_controlled` (`%op`, then h_r) into `%out`, the flag
; strip and free, `measure(h_q)`, `measure(%out)`. Flip this fixture to that
; positive stream in the same reviewed change; a `cqrt_xorc_i32`/`cqrt_addc_i32`
; on h_r anywhere is the wt8u hazard and must never appear.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: routed base predates a non-diagonal gate under quantum control

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, double 9.000000e-01, double 3.000000e-01
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5)
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %11, label %8

8:
  %9 = phi i32 [ %6, %1 ], [ %14, %11 ]
  %10 = icmp eq i32 %2, 3
  br i1 %10, label %17, label %24

11:
  %12 = phi i32 [ %15, %11 ], [ 0, %1 ]
  %13 = phi i32 [ %14, %11 ], [ %6, %1 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01)
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %0
  br i1 %16, label %8, label %11

17:
  %18 = xor i32 %9, 2
  %19 = add nsw i32 %18, 5
  %20 = xor i32 %19, 7
  %21 = add nsw i32 %20, 9
  %22 = xor i32 %21, 11
  %23 = add nsw i32 %22, 13
  br label %24

24:
  %25 = phi i32 [ %23, %17 ], [ %9, %8 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25)
  %28 = add nsw i32 %27, %26
  ret i32 %28
}
