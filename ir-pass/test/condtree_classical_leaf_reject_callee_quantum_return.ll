; condtree_classical_leaf_reject_callee_quantum_return.ll — DECLINE (bd
; test_C_libtooling-xdu2.13 / bd test_C_libtooling-3jru).
;
; Rule-13 round 2 F-1 (reviewer probes q04/q05). `g` RETURNS a `cq_theta`
; register. Before bd 3jru, taint did not cross a call return, so `%r = call @g`
; was UNTAINTED in the caller even though its value is a quantum register's
; HANDLE ID. `icmp eq %r, %n` then became a classical `_hl` literal (red on
; bc42274e: it accepted, emitting `and_i1_hl(h_cmp, icmp eq <handle id>, %n)`).
; [HISTORY: round 2 fenced this with a syntactic conjunct (d) in
; `condLiteralAdmissible`. Round 3 defeated it five ways, and it is REMOVED.]
; bd 3jru now TAINTS `%r` at the call site (the `propagate` fixpoint), and
; `declineQuantumReturnCalls` refuses the use loudly.
;
; bd p3kd.21 (2026-10-14) — NOW AN ACCEPT; the file name and the DECLINE text
; above are history. The returning callee is a GATE SUBROUTINE (it holds
; `cq_theta`), so its call is compiled at the call site (SpecializeGateInline.h,
; trigger (c): a used register return) and the 3jru crossing no longer exists: the
; register is the caller's own. Measured: the lowered body is identical, call for
; call, to `clang -O1` of the same source with the helper force-inlined, on the
; pre-change binary (taint_reject_quantum_return_helper_arg.ll's twin). The 3jru
; refusal itself is unchanged and still pinned by the members of this family whose
; callee is not inlined (taint_reject_quantum_return_outparam.ll,
; taint_reject_quantum_return_volatile_flag.ll, …).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal i32 @slice(
; CHECK: call void @cqrt_ry_i32(i32 {{%[a-z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK: call void @cqrt_toffoli(
; CHECK: call i32 @cqrt_measure_i32(
; CHECK-NOT: call {{.*}}@g(

define i32 @g(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  ret i32 %t
}
define internal i32 @slice(i32 %m, i32 %n) {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @g(i32 %m)
  %t = icmp sgt i32 %q, 1
  %c = icmp eq i32 %r, %n
  %a = and i1 %t, %c
  %s = select i1 %a, i32 10, i32 7
  %m1 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
