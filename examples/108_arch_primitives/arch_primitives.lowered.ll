; HAND-WRITTEN. Rules: 2, 4, 5, 16, 18, 20, 24, §1.4.
; Checked: ctz_q: (unsigned)ctzll(x | 1 << 32) (measured, the trunc rail %6 -> %7); trap_q: x + 1 (measured, %6 -> %7);
; tls_q: tl * 2 (measured, the shl rail %8 -> %9).
; Clean: ctz_q: the or rail (%4) and the cttz rail (%5), uncomputed and freed; tls_q: the slot's rail x + 1 (%5) and
; the clone's rail x + 1 + c (%7, zeroed by the __cq_q_touch_10_unc twin), both freed.
; Kept: x in each function (%3 of ctz_q, 64 bits; %4 of trap_q; %4 of tls_q: the rotated user registers); trap_q's
; abort flag x > k (%5): a noreturn-arm predicate passed to cqrt_abort_i1 stays allocated and the backend measures it
; after the program's last own measurement.
; Rotations: (Ry, x, th, 1) in each of the three functions (an i64 Ry in ctz_q).
; The three intrinsics the CQ musl architecture headers produce when their asm is spelled as
; builtins (LIBC_COVERAGE.md): llvm.cttz (a_ctz_64 = bsf) is the unary template cq_template_cttz_<W> exactly as 56's ctlz,
; the is_zero_poison literal being a promise about the operand, not an operand; llvm.trap (a_crash = hlt) is a noreturn
; under a quantum predicate, 45's abort arm: the predicate rail goes to cqrt_abort_i1 and stays allocated, the backend
; measures it after the program's last own measurement; llvm.threadlocal.address (every __thread access) and
; llvm.thread.pointer (__get_tp = mov %fs:0) are classical host intrinsics kept as they are: ONE THREAD, so the TLS block is
; one object of the table with a classical base, and a thread_local global is a classical slot holding a handle exactly
; like 67's static global (the quantum value stored into it is a rail, the load after the call yields that handle). The
; Darwin x86-64 backend has no code generation for llvm.thread.pointer, so this host's trace cannot exercise it; its
; lowering is the same as threadlocal.address's (a classical call returning the object's base), only the latter is shown.
; The callee
; touching the slot through a classical pointer is the clone of 106; its mask is per §1.4, left to right: the pointer-to-slot
; formal p carries one quantum field (digit 1), c is classical (digit 0), __cq_q_touch_10. Its _unc twin takes (args..., old
; slot handles in slot order) = (p, c, the cell's previous handle), zeroes the new rail in place and restores the slot; the
; caller frees the new rail.
source_filename = "arch_primitives.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tl = internal thread_local global i32 0, align 4    ; IR: @tl  (the TLS object: one thread, one object; a classical slot holding a handle)

define i32 @ctz_q(i64 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %3 = cq_theta_ull(%0, %1)  [register x, 64 bits]
  call void @cqrt_ry_i64(i32 %3, double %1)    ; IR: %3 = cq_theta_ull(%0, %1)  [Ry]
  %4 = call i32 @cq_template_or_i64_hl(i32 %3, i64 4294967296)    ; IR: %4 = or i64 %3, 4294967296
  %5 = call i32 @cq_template_cttz_i64(i32 %4)    ; IR: %5 = llvm.cttz.i64(%4, true)  (trailing zeros; the literal is a poison promise, not an operand)
  %6 = call i32 @cq_template_trunc_i64_to_i32(i32 %5)    ; IR: %6 = trunc i64 %5 to i32  [result rail]
  call void @cq_template_cttz_i64_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %4, i32 %3, i64 4294967296)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_ui32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define i32 @trap_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %4, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [predicate of the noreturn block %6]
  call void @cqrt_abort_i1(i32 %5)    ; IR: block %6: llvm.trap(); unreachable  (noreturn arm flag, kept allocated; measured by the backend at end of shot)
  %6 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: %8 = add nsw i32 %4, 1  (block %7, runs uncontrolled)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %7    ; IR: ret i32 %9
}

define i32 @tls_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: %5 = add nsw i32 %4, 1
  %6 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @tl)    ; IR: %6 = llvm.threadlocal.address(@tl)  (classical host intrinsic: the slot's address)
  store i32 %5, ptr %6, align 4    ; IR: store i32 %5, ptr %6  (the slot takes the handle of %5)
  call fastcc void @__cq_q_touch_10(ptr %6, i32 %2)    ; IR: call @touch(%6, %2): clone, mask 10 (the slot parameter carries one quantum field, c is classical; 106)
  %7 = load i32, ptr %6, align 4    ; IR: %7 = load i32, ptr %6  (the handle the clone stored: x + 1 + c)
  %8 = call i32 @cq_template_shl_i32_hl(i32 %7, i32 1)    ; IR: %8 = shl nsw i32 %7, 1  [result rail]
  call fastcc void @__cq_q_touch_10_unc(ptr %6, i32 %2, i32 %5)    ; IR: twin (args..., old slot handle): the new rail is zeroed, the slot holds %5 again
  call void @cqrt_free(i32 %7)    ; IR: release the clone's rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: uncompute %5 (the slot's rail)
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>); the slot's handle is dead
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc void @__cq_q_touch_10(ptr noundef %0, i32 noundef %1) {
  %3 = load i32, ptr %0, align 4    ; IR: %3 = load i32, ptr %0  (the cell's handle)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %1)    ; IR: %4 = add nsw i32 %3, %1  [fresh rail]
  store i32 %4, ptr %0, align 4    ; IR: store i32 %4, ptr %0  (the cell takes the new handle)
  ret void    ; IR: ret void
}

define internal fastcc void @__cq_q_touch_10_unc(ptr noundef %0, i32 noundef %1, i32 %2) {
  %4 = load i32, ptr %0, align 4    ; IR: the cell's current handle (%4)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %2, i32 %1)    ; IR: uncompute %4 in place (|0>)
  store i32 %2, ptr %0, align 4    ; IR: the cell holds the previous handle again
  ret void    ; IR: ret void
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_abort_i1(i32)
declare i32 @cq_template_or_i64_hl(i32, i64)
declare void @cq_template_or_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_cttz_i64(i32)
declare void @cq_template_cttz_i64_unc(i32, i32)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare ptr @llvm.threadlocal.address.p0(ptr)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
