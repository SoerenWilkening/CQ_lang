; control_swap_reject_select_cmp_inloop_measure_after.ll — DECLINE (Track A.1,
; bd test_C_libtooling-r10v). THE REPRODUCER, VERBATIM `clang -O1`:
;
;     int b = cq_theta(0, .5);
;     for (int i = 0; i < 3; ++i) {
;         int a = (b == 1) ? i : 5;              // arm is loop-VARIANT
;         acc += cq_measure(a) + cq_measure(b);  // collapses b IN THE BODY
;     }
;
; MEASURED on `main` 0c7380c: `opt` exit 0, verify-clean, STRICT stage 2b clean,
; a 38-line trace in which lines 14->15 and 26->27 read
;
;     cqrt_measure_i32(h0)
;     cq_template_icmp_eq_i32_hl(h0, 1)
;
; i.e. trips 2 and 3 mint the merge flag from a register trip 1 COLLAPSED. It is
; the COMPARE half of the orchestrator finding F-B1-1, whose RAIL half was fixed
; in Increment 1b-B.1 (`control_swap_reject_select_rail_inloop_measure_after.ll`,
; the same program with `_Bool`).
;
; THE ARM MUST BE LOOP-VARIANT for the select to stay in the body — that is what
; puts the READ POINT on the cycle. With a constant arm `-O1` LICM-hoists the
; whole select into the entry block and the program is a legitimate ACCEPT
; (`control_swap_select_cmp_inloop_hoisted_measure_after.ll`); the hand-IR
; spelling that keeps a constant-arm select inside the body declines here too
; (`..._reject_select_cmp_inloop_measure_after_constarm.ll`).
;
; AND THE DECLINE IS ABOUT THE REGISTER'S LIFETIME, NOT ABOUT THE LOOP: `b` is
; minted ONCE, in the entry block, so no path from the body measure back to the
; body select re-executes its definition. An ITERATION-LOCAL register — minted
; fresh every trip — is the accept `..._select_cmp_inloop_iterlocal_measure_after.ll`,
; and that pair is what the per-activation barrier in
; `railMeasuredBeforeReadPoint` exists to separate.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br label %4

3:
  ret i32 %11

4:
  %5 = phi i32 [ 0, %0 ], [ %11, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %12, %4 ]
  %7 = select i1 %2, i32 %6, i32 5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %10 = add i32 %8, %5
  %11 = add i32 %10, %9
  %12 = add nuw nsw i32 %6, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %3, label %4
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
