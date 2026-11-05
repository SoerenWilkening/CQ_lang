; HAND-WRITTEN. Rules: 18, 14, 20, 21, 3, 4, 5 (Memory, sentence 1), 2; §1.3 (the bus), §1.4 (mask, attributes).
; Checked: polyval(x, c, n) (the clone's result rail %6, measured as %7) = Horner evaluation of c[0..n-1] at x, the
; coefficients read from the bus at the classical addresses c + 4i.
; Clean: every per-trip rail of the clone (the old s, the product s * x and the load copy of c[i], popped by the
; reverse loop: the sum and the copy un-copied, then the product; each freed) and the load copy of c[0] (un-copied by
; qram_load_i32_hl_unc after its last reader and freed: right after the copy-out on the n <= 1 path, after the reverse
; loop on the loop path).
; Kept: x (%5 of the caller, the rotated register) and the result rail %6 (measured). No tape slot: nothing is stored.
; Rotations: (Ry, x, th, 1).
; A POINTER IS ONE SCALAR (§1.4, rules 18, 21). c is a classical ptr argument, so polyval(x, c, n) is the clone of mask
; 100 (x a rail, c and n classical, left to right): the formal c stays the C ptr, and nothing about the pointee crosses
; the call. The memory, capture and purity facts of the original (memory(argmem: read), nocapture, readonly, nofree,
; nosync) are dropped from the clone, from its call and from the lowered own symbol callee_with_loop (§1.4).
; EVERY LOAD IS A BUS LOAD (rules 3, 20): c is a pointer argument, neither a constant global nor an alloca, so c[0] and
; each c[i] is qram_load_i32_hl(m, address) at the run-time address (ptrtoint of c once at entry, ptrtoint of the
; untainted gep in the loop) and its result is a rail. The trip's add is then an add of two rails, cq_template_add_i32
; in the IR's operand order. The clone writes no memory, so no memory version change follows any of its loads: every
; load copy is un-copied after its last reader (rule 5 sentence 1). The load copy of c[i] is read by the add, whose
; _unc runs in the reverse loop, so the copy is pushed with the trip's other rails and un-copied right after that
; _unc, at the address recomputed from the trip index (an affine induction with a classical start, never pushed). The
; load copy of c[0] is s before trip 1: popped by the last reverse trip and un-copied after it. The add is an update
; of two garbage operands (the product, a template result, and the load copy, un-copied), so rule 6 has no trigger.
; The clone __cq_q_polyval_100 calls m = __cq_mem() once at its entry; the caller makes no bus access and has none.
; The clone runs the classical-bound loop with the handle stack (rule 14, as example 25), copies the result into a
; fresh rail, mirrors the loop and returns the copy; on the n <= 1 path the result is the copy of c[0], copied out the
; same way. polyval loads from the bus, so its call is a load for rule 5 (rule 18); the caller measures the result, so
; no twin is called and none is defined. polyval's own symbol has no caller left and is dropped (§1.4).
source_filename = "callee_with_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_with_loop(i32 noundef %0, double noundef %1, ptr noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_polyval_100(i32 %5, ptr noundef %2, i32 noundef %3)    ; IR: %6 = call fastcc i32 @polyval(%5, %2, %3): the clone of mask 100 (x a rail; the classical ptr c stays a ptr; n classical); it loads from the bus and writes nothing
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)  [the result rail stays allocated, rule 2]
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_polyval_100(i32 %0, ptr %1, i32 %2) unnamed_addr {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = ptrtoint ptr %1 to i64    ; IR: c as its run-time address (mask digit 0: the formal is the C ptr; rule 20, once at entry)
  %6 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %5)    ; IR: %4 = load i32, ptr %1: c[0], a bus load (rule 3): a rail  [s before trip 1]
  %7 = icmp sgt i32 %2, 1    ; IR: %5 = icmp sgt i32 %2, 1
  br i1 %7, label %10, label %8    ; IR: br i1 %5, label %6, label %8

8:
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9, %9 = %4 from %3  [result rail of the call, rule 18]
  call void @cqrt_copy_i32(i32 %6, i32 %9)    ; IR: copy the s rail (the load copy of c[0]) out
  call void @cqrt_qram_load_i32_hl_unc(i32 %6, i32 %4, i64 %5)    ; IR: un-copy %4: its last reader (the copy-out) precedes every memory version change (rule 5 sentence 1)
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  ret i32 %9    ; IR: ret i32 %9

10:
  %11 = zext nneg i32 %2 to i64    ; IR: %7 = zext nneg i32 %2 to i64
  br label %12

12:
  %13 = phi i64 [ 1, %10 ], [ %20, %12 ]    ; IR: %11 = phi i64 [ 1, %6 ], [ %17, %10 ]  (classical)
  %14 = phi i32 [ %6, %10 ], [ %19, %12 ]    ; IR: %12 = phi i32 [ %4, %6 ], [ %16, %10 ]
  %15 = call i32 @cq_template_mul_i32(i32 %14, i32 %0)    ; IR: %13 = mul nsw i32 %12, %0
  %16 = getelementptr inbounds i32, ptr %1, i64 %13    ; IR: %14 = getelementptr inbounds i32, ptr %1, i64 %11  (nothing tainted: the gep stays)
  %17 = ptrtoint ptr %16 to i64    ; IR: %14 as its run-time address
  %18 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %17)    ; IR: %15 = load i32, ptr %14: c[i], a bus load (rule 3): a rail
  %19 = call i32 @cq_template_add_i32(i32 %18, i32 %15)    ; IR: %16 = add nsw i32 %15, %13  (two rails)
  call void @cqrt_push(i32 %14)    ; IR: %12 [old s, for the mirror]
  call void @cqrt_push(i32 %15)    ; IR: %13 [product rail, for the mirror]
  call void @cqrt_push(i32 %18)    ; IR: %15 [load copy of c[i], un-copied by the mirror after %16's _unc]
  %20 = add nuw nsw i64 %13, 1    ; IR: %17 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %20, %11    ; IR: %18 = icmp eq i64 %17, %7
  br i1 %21, label %22, label %12    ; IR: br i1 %18, label %8, label %10

22:
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %9, %9 = %16  [result rail of the call]
  call void @cqrt_copy_i32(i32 %19, i32 %23)    ; IR: copy the result out
  br label %24

24:
  %25 = phi i64 [ %13, %22 ], [ %32, %24 ]    ; IR: trip being undone, from the last down to 1
  %26 = phi i32 [ %19, %22 ], [ %31, %24 ]
  %27 = getelementptr i32, ptr %1, i64 %25    ; IR: %14 of that trip, recomputed from the trip index
  %28 = ptrtoint ptr %27 to i64    ; IR: its run-time address
  %29 = call i32 @cqrt_pop()    ; IR: that trip's load copy %15
  %30 = call i32 @cqrt_pop()    ; IR: that trip's product rail %13
  %31 = call i32 @cqrt_pop()    ; IR: that trip's %12
  call void @cq_template_add_i32_unc(i32 %26, i32 %29, i32 %30)    ; IR: uncompute %16
  call void @cqrt_free(i32 %26)    ; IR: release the %16 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %4, i64 %28)    ; IR: un-copy %15: its last reader %16 is uncomputed and no memory version change followed the load (rule 5 sentence 1)
  call void @cqrt_free(i32 %29)    ; IR: release the %15 rail (|0>)
  call void @cq_template_mul_i32_unc(i32 %30, i32 %31, i32 %0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %30)    ; IR: release the %13 rail (|0>)
  %32 = add nsw i64 %25, -1
  %33 = icmp sgt i64 %32, 0
  br i1 %33, label %24, label %34

34:
  call void @cqrt_qram_load_i32_hl_unc(i32 %31, i32 %4, i64 %5)    ; IR: un-copy %4 (the first s rail): its last reader, trip 1's %13, is uncomputed (rule 5 sentence 1)
  call void @cqrt_free(i32 %31)    ; IR: release the %4 rail (|0>)
  ret i32 %23    ; IR: ret i32 %9
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
