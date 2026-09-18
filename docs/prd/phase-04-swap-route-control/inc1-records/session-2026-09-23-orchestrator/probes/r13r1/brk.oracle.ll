; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/ir-pass/test/lowering_loop_break_unsigned.ll'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/ir-pass/test/lowering_loop_break_unsigned.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @break_unsigned(i32 %x, i32 %n) {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %x)
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
  %guard = icmp eq i32 %n, 0
  %cq.brk.R = call i32 @cqrt_alloc_i32(i32 0)
  %cq.brk.idx = call i32 @cqrt_alloc_i32(i32 0)
  %cq.brk.out = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %guard, label %exit, label %loop

loop:                                             ; preds = %loop, %entry
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  call void @cqrt_xorc_i32(i32 %h, i32 9)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0)
  %inext = add nuw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %cq.brk.eqz = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  %cq.brk.fire = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_toffoli(i32 %h_cmp, i32 %cq.brk.eqz, i32 %cq.brk.fire)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 %h, i32 %cq.brk.R)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz)
  %cq.brk.k = call i32 @cqrt_alloc_i32(i32 %inext)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire, i32 %cq.brk.k, i32 %cq.brk.idx)
  %cq.brk.negk = sub i32 0, %inext
  call void @cqrt_addc_i32(i32 %cq.brk.k, i32 %cq.brk.negk)
  call void @cqrt_free(i32 %cq.brk.k)
  %cq.brk.negk2 = sub i32 0, %inext
  call void @cqrt_addc_i32(i32 %cq.brk.idx, i32 %cq.brk.negk2)
  %cq.brk.eqz3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  call void @cqrt_cnot(i32 %cq.brk.eqz3, i32 %cq.brk.fire)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz3, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz3)
  call void @cqrt_addc_i32(i32 %cq.brk.idx, i32 %inext)
  call void @cqrt_free(i32 %cq.brk.fire)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0)
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 1)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_cmp)
  br i1 %bound, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %cq.brk.eqz4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.eqz4, i32 %h, i32 %cq.brk.R)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz4, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz4)
  call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
  %cq.brk.eqz5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.eqz5, i32 %h, i32 %cq.brk.R)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz5, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz5)
  %cq.brk.guard = xor i1 %guard, true
  %cq.brk.n1 = sub i32 %n, 1
  br i1 %cq.brk.guard, label %cq.brk.rev, label %cq.brk.tail

cq.brk.rev:                                       ; preds = %cq.brk.rev, %exit
  %cq.brk.ip = phi i32 [ %cq.brk.n1, %exit ], [ %cq.brk.ipdec, %cq.brk.rev ]
  %cq.brk.kp = add i32 %cq.brk.ip, 1
  %cq.brk.fire6 = call i32 @cqrt_alloc_i1(i1 false)
  %cq.brk.negk7 = sub i32 0, %cq.brk.kp
  call void @cqrt_addc_i32(i32 %cq.brk.idx, i32 %cq.brk.negk7)
  %cq.brk.eqz8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  call void @cqrt_cnot(i32 %cq.brk.eqz8, i32 %cq.brk.fire6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz8, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz8)
  call void @cqrt_addc_i32(i32 %cq.brk.idx, i32 %cq.brk.kp)
  %cq.brk.k9 = call i32 @cqrt_alloc_i32(i32 %cq.brk.kp)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire6, i32 %cq.brk.k9, i32 %cq.brk.idx)
  %cq.brk.negk10 = sub i32 0, %cq.brk.kp
  call void @cqrt_addc_i32(i32 %cq.brk.k9, i32 %cq.brk.negk10)
  call void @cqrt_free(i32 %cq.brk.k9)
  call void @cqrt_copy_i32_controlled(i32 %cq.brk.fire6, i32 %h, i32 %cq.brk.R)
  %cq.brk.eqz11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.brk.idx, i32 0)
  %0 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  %1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %0, i32 0)
  call void @cqrt_toffoli(i32 %1, i32 %cq.brk.eqz11, i32 %cq.brk.fire6)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %1, i32 %0, i32 0)
  call void @cq_template_and_i32_hl_unc(i32 %0, i32 %h, i32 1)
  call void @cqrt_free(i32 %0)
  call void @cqrt_free(i32 %1)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %cq.brk.eqz11, i32 %cq.brk.idx, i32 0)
  call void @cqrt_free(i32 %cq.brk.eqz11)
  call void @cqrt_free(i32 %cq.brk.fire6)
  call void @cqrt_xorc_i32(i32 %h, i32 9)
  %cq.brk.ipdec = sub i32 %cq.brk.ip, 1
  %cq.brk.more = icmp ne i32 %cq.brk.ip, 0
  br i1 %cq.brk.more, label %cq.brk.rev, label %cq.brk.tail

cq.brk.tail:                                      ; preds = %cq.brk.rev, %exit
  call void @cqrt_free(i32 %cq.brk.R)
  call void @cqrt_free(i32 %cq.brk.idx)
  %m1 = call i32 @cqrt_measure_i32(i32 %cq.brk.out)
  ret i32 %m1
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_xorc_i32(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_addc_i32(i32, i32)

declare void @cqrt_cnot(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
