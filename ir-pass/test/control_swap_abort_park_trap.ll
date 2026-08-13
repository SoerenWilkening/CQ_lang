; control_swap_abort_park_trap.ll — Phase 7.2 Inc 3 ACCEPT variant: the noreturn
; sink is the `@llvm.trap` intrinsic (`__builtin_trap()`). Its call site carries
; no explicit `noreturn` attribute (only the decl does), so the recognizer keys on
; the intrinsic NAME (PRD-7.2 §2.11-B). Same park cascade.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

; CHECK: %[[FLAG:.+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:.+]], i32 5)
; CHECK: %[[GRAVE:.+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[Q]], i32 %[[GRAVE]])
; CHECK: call i32 @cqrt_tape_write_i1(i32 %{{.+}}, i32 %[[FLAG]])
; CHECK-NOT: call void @llvm.trap()
; CHECK-NOT: call void @cqrt_free(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.trap()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %cont
a:
  call void @llvm.trap()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
