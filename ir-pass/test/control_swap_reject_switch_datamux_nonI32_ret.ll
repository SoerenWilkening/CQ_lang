; control_swap_reject_switch_datamux_nonI32_ret.ll — NON-i32 RETURN reject (8mld,
; the switch sibling of control_classical_call_arm_reject_nonI32_ret.ll;
; re-routed by dugh): a tainted-scrutinee `switch` whose all-`ConstantInt` merge phi
; is `i64` and is consumed by a DIRECT `ret i64`. The data-mux emitter preloads +
; XOR-delta-copies into a FRESH `%out` handle and RAUWs the merge phi to it;
; `cqrt_alloc_<W>` is i32 at every width (Rule 15), so accepting leaves
; `ret i64 <i32 handle>` — a BROKEN MODULE the verifier aborts on, NOT a Rule-1
; decline. A crash on well-formed valid input (opt -verify exit 0) violates Rule 1.
;
; The data-mux merge is UNTAINTED (all-ConstantInt incomings). dugh (Phase 4×6)
; retired the `proveSwitchDataMux` G6 merge-out gate and instead RE-SEEDS a second
; propagation from the emitted `%out` (`repropagateControlMerges`); the now-tainted
; `ret` declines via the precise `kMsgNonI32Return`. The return check keys on the
; FUNCTION return type (i64), not the RAUW'd RV type (i32), so it catches the
; post-emit mismatch and `exit(1)`s before the verifier. i64-MEASURE data-muxes stay
; accepted (the sink re-types); the non-i32 raw quantum return is the (A1) limit that
; STAYS declined (feature jx32). NEVER lowered.
;
; bd p3kd.21 / bd jx32 (2026-10-14) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. The function has no in-module use (an entry
; point / export, `declineQuantumReturnCalls`' Escaped contract), so its non-i32
; tainted `ret` returns the register's i32 runtime HANDLE: the return is
; re-declared `i32` after lowering (`retypeQuantumExportReturns`,
; SpecializeGateInline.h) and the verifier-abort hazard described above cannot
; arise (a `ret` still carrying a non-i32 value there fails loudly with the same
; non-i32 string). The gate stream is the one the i32-typed twin of the same body
; emits (measured on the value diamond: identical, call for call; the twin's arm
; chain is left allocated exactly as there). The non-i32 decline remains for a
; function WITH an in-module use: spec_reject_gate_sub_indirect_nonI32.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(i32 %u0)
; CHECK: [[OUT:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 5)
; CHECK: call void @cqrt_copy_i64_controlled(i32 {{%[a-z0-9_.]+}}, i32 {{%[a-z0-9_.]+}}, i32 [[OUT]])
; CHECK: ret i32 [[OUT]]
declare i32 @cq_theta_si32(i32, double)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  br label %merge
c1:
  br label %merge
merge:
  %y = phi i64 [ 10, %c0 ], [ 20, %c1 ], [ 5, %entry ]   ; UNTAINTED all-const i64 data-mux
  ret i64 %y                                             ; non-i32 ret of the RAUW'd i32 handle
}
