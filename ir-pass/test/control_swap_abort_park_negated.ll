; control_swap_abort_park_negated.ll — Phase 7.2 Inc 3 ACCEPT, orientation B
; (Rule 9): `clang -O1` may make the abort arm the FALSE successor. The abort then
; fires on flag=0, so BOTH the park `cqrt_cswap` AND the tape record ride the
; self-inverse `cqrt_x(flag)` ¬flag bracket — `emitRoute` brackets the cswap, and
; the record is bracketed so the committed tape value is the ABORT indicator (1 =
; aborted), not its complement. The bracket SPAN is verify-clean-invisible (a
; mis-span commits on the wrong basis branch), so it is pinned by an ORDERED CHECK.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

; The park cswap is X-bracketed (fires on ¬flag = the abort branch)...
; CHECK: %[[FLAG:.+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:.+]], i32 5)
; CHECK: %[[GRAVE:.+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_x(i32 %[[FLAG]])
; CHECK: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[Q]], i32 %[[GRAVE]])
; CHECK: call void @cqrt_x(i32 %[[FLAG]])
; ...and the tape record is X-bracketed too (commits the abort indicator on ¬flag).
; CHECK: call void @cqrt_x(i32 %[[FLAG]])
; CHECK: call i32 @cqrt_tape_write_i1(i32 %{{.+}}, i32 %[[FLAG]])
; CHECK: call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NOT: call void @abort()
; CHECK-NOT: call void @cqrt_free(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %cont, label %a       ; abort is the FALSE successor (Rule 9)
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
a:
  call void @abort()
  unreachable
}
