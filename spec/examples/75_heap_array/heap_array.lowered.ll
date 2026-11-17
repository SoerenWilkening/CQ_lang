; HAND-WRITTEN. Rules: 16, 20, 21, 5, 6, 14, 4, 2, 3; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: r = a[k] + a[n - 1] (measured, %32 -> %33) over the heap cells a[i] = x + i, 0 <= i < n; the cells of the
; block on the bus at exit: a[i] = x + i.
; Clean: the two load copies a[k] and a[n - 1] (%27, %31: un-copied right after their only consumer, the add %32, which
; is measured; no memory version change follows them, rule 5 sentence 1); when n > 0, the old x rail (%6, rule 6:
; cleaned from the last cell's rail x + (n - 1), |0> after the copy) and the inverse t (%22), both freed.
; Kept: rule 5 sentence 3, per fill trip: the tape slot of the store a[i] = x + i (it holds the displaced zero bytes of
; the block) and its value rail x + i (%16); x (%6, the rotated register) only when n <= 0 (no image of it exists);
; r (%32, measured).
; Rotations: (Ry, x, th, 1).
; Driver heap_array(0, .5, 3, 1): Ry(.5) flips each of the 32 bits of x0 = 0 with probability s = sin^2(.25) =
; 0.061209, independently. The cells are a = {x, x + 1, x + 2}, r = a[1] + a[2] = 2x + 3 mod 2^32: bit 31 of x does not
; reach r, so r = 3 with probability (1 - s)^31 = 0.141137, and 3 + 2^(b + 1) for a single flipped bit b < 31 with
; s (1 - s)^30 = 0.009202 each.
; ONE BUS (rules 16, 20, 21). malloc(n * 4) is __cq_alloc(n * 4, 16) (alignment 16: malloc names none): zeroed host
; memory at an address never reused, its size as an i64 in the 8 bytes before it. The size is classical (n is a
; parameter), so no K2 and no overflow predicate. Nothing is known about the block at compile time: a is its run-time
; address, a classical ptr, and every getelementptr into it has untainted indices, so each stays as -O1 wrote it and
; the access's address is its ptrtoint, the _hl operand (rule 20). Every store is a bus store and every load a bus load
; whose result is a rail (rule 3). The cells hold the BYTES of the i32 values (store-size 4, little-endian): the
; allocation size and every gep stand as written for any element type.
; The fill loop has a classical bound (rule 14): each trip computes x + i into a fresh rail and stores it with
; cqrt_qram_store_i32_hl, a KEPT store (rule 5 sentence 3): its tape slot and its value rail stay for the shot, so no
; trip rail is pushed and there is no reverse loop. x's last reader is then the add of the last trip, and x + i is a
; bijection in x for the classical i: rule 6 cleans x on the loop's exit edge (reached only when n > 0) from the last
; trip's rail, t = (x + (n - 1)) - (n - 1). On the n <= 0 path no image exists and x stays allocated.
; The two loads are at classical addresses (_hl). r = a[n - 1] + a[k] is an add of two load copies, both garbage that
; rule 5 un-copies (no memory version change follows), so rule 6 has no trigger (198); r is measured, so the copies'
; last reader is the add itself, and each is un-copied (cqrt_qram_load_i32_hl_unc, the cells unchanged since the load)
; and freed right after it, before the measurement. free(a) is nothing (rule 16). Reading a[k] with k outside [0, n)
; is one bus load at that address, totalized by §2 (rule 21): no bounds check.
; SPEC GAP (rule 6, a loop-invariant register read by every trip of a classical loop): where the clean-up of x goes when
; its last reader is the last trip of a classical loop is not stated. Chosen: on the loop's exit edge, from the last
; trip's image (the loop block dominates the exit block, so its last %16 and %15 are read directly); on the zero-trip
; path x is kept (no image exists there).
source_filename = "heap_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @heap_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = sext i32 %2 to i64    ; IR: %6 = sext i32 %2 to i64  (classical)
  %8 = shl nsw i64 %7, 2    ; IR: %7 = shl nsw i64 %6, 2  (classical: n * sizeof(int) bytes)
  %9 = call ptr @__cq_alloc(i64 %8, i64 16)    ; IR: %8 = call ptr @malloc(i64 %7)  [rule 16: zeroed, never reused, the size at a - 8]
  %10 = icmp sgt i32 %2, 0    ; IR: %9 = icmp sgt i32 %2, 0  (classical)
  br i1 %10, label %11, label %23    ; IR: br i1 %9, label %10, label %12

11:
  %12 = zext nneg i32 %2 to i64    ; IR: %11 = zext nneg i32 %2 to i64  (classical)
  br label %13    ; IR: br label %21

13:
  %14 = phi i64 [ 0, %11 ], [ %19, %13 ]    ; IR: %22 = phi i64 [ 0, %10 ], [ %26, %21 ]  (classical i)
  %15 = trunc nuw nsw i64 %14 to i32    ; IR: %23 = trunc nuw nsw i64 %22 to i32  (classical)
  %16 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %15)    ; IR: %24 = add i32 %5, %23  [a[i]'s value rail]
  %17 = getelementptr inbounds i32, ptr %9, i64 %14    ; IR: %25 = getelementptr inbounds i32, ptr %8, i64 %22  (untainted: stays)
  %18 = ptrtoint ptr %17 to i64    ; IR: %25 as its run-time address (the _hl operand)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %18, i32 %16)    ; IR: store i32 %24, ptr %25  [kept store: its tape slot and its value rail stay, rule 5 sentence 3]
  %19 = add nuw nsw i64 %14, 1    ; IR: %26 = add nuw nsw i64 %22, 1  (classical)
  %20 = icmp eq i64 %19, %12    ; IR: %27 = icmp eq i64 %26, %11  (classical bound)
  br i1 %20, label %21, label %13    ; IR: br i1 %27, label %12, label %21

21:
  %22 = call i32 @cq_template_sub_i32_hl(i32 %16, i32 %15)    ; IR: rule 6 on the exit edge (n > 0): t = (x + i) - i of the last trip recomputes x
  call void @cqrt_copy_i32(i32 %22, i32 %6)    ; IR: rule 6: x ^= t: the dead x rail is now |0>  [SPEC GAP]
  call void @cq_template_sub_i32_hl_unc(i32 %22, i32 %16, i32 %15)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %22)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old x rail (|0> after the copy)
  br label %23    ; IR: br i1 %27, label %12  (the loop exit)

23:
  %24 = sext i32 %3 to i64    ; IR: %13 = sext i32 %3 to i64  (classical)
  %25 = getelementptr inbounds i32, ptr %9, i64 %24    ; IR: %14 = getelementptr inbounds i32, ptr %8, i64 %13  (untainted: stays)
  %26 = ptrtoint ptr %25 to i64    ; IR: %14 as its run-time address
  %27 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %26)    ; IR: %15 = load i32, ptr %14  [a[k]: a load copy]
  %28 = getelementptr i32, ptr %9, i64 %7    ; IR: %16 = getelementptr i32, ptr %8, i64 %6  (untainted: stays)
  %29 = getelementptr i8, ptr %28, i64 -4    ; IR: %17 = getelementptr i8, ptr %16, i64 -4  (untainted: stays)
  %30 = ptrtoint ptr %29 to i64    ; IR: %17 as its run-time address
  %31 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %30)    ; IR: %18 = load i32, ptr %17  [a[n - 1]: a load copy]
  %32 = call i32 @cq_template_add_i32(i32 %31, i32 %27)    ; IR: %19 = add nsw i32 %18, %15  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %31, i32 %5, i64 %30)    ; IR: un-copy %18: its consumer %19 is measured and no memory version change follows (rule 5 sentence 1)
  call void @cqrt_free(i32 %31)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %27, i32 %5, i64 %26)    ; IR: un-copy %15 (rule 5 sentence 1)
  call void @cqrt_free(i32 %27)    ; IR: release the %15 rail (|0>)
  %33 = call i32 @cqrt_measure_i32(i32 %32)    ; IR: call void @free(ptr %8) is nothing (rule 16); %20 = cq_measure_si32(%19)
  ret i32 %33    ; IR: ret i32 %20
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
