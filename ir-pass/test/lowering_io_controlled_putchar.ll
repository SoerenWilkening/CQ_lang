; lowering_io_controlled_putchar.ll — ACCEPT (Phase 7.6 Increment 2): the second
; recognized I/O sink, `putchar`, under tainted control. `if (q > 5) putchar(q)`
; lowers to ONE `cqrt_tape_write_i32_controlled` exactly like the `printf` case
; (the recognition is by EXACT callee name {printf,putchar}; putchar's discarded
; i32 result is erased with the flattened arm).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @putchar(i32)

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %r = call i32 @putchar(i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[FLAG]], i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: br i1
