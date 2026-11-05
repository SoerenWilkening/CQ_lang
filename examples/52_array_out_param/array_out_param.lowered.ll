; HAND-WRITTEN. Rules: 20, 21, 18, 19, 14, 9, 7, 5, 3, 2; §1.3, §1.4, §2.
; Checked: r (the classical phi of handles %33: the case-0 load copy of y[0] %21, the case-1 load copy of y[1] %25 or
; the default fsub %31; measured as %34). The cells at exit: tx[0..2] = x, x * a, x + a; y[0] = s, y[1] = s - tx[0],
; s = ((0 + tx[0] * c) + tx[1] * c) + ... over the first n cells of tx (0.0 when n <= 0).
; Clean: inside reduce, every trip rail: the accumulator rails and the product rails (popped and uncomputed by the
; reverse loop), the load copies of in[i] (pushed, un-copied by the reverse loop before the first store), the 0.0 seed
; on the loop path, and the load copy of in[0] (un-copied right after the fsub that reads it, before the store of
; out[1]). In the caller: the two load copies of y[0] and y[1] on the default path (un-copied right after the fsub).
; Kept: x (%11, the rotated register, also the value rail of the store tx[0]); by rule 5 the tape slots of the three
; stores into tx and their value rails tx[1] (%12) and tx[2] (%15); inside reduce the tape slots of the two stores
; into out and their value rails (the copy-out of s, or the 0.0 seed when n <= 0, and the fsub rail); the result r
; (measured: a load copy of y on cases 0 and 1, rule 2's measured rail, or the default fsub rail).
; Rotations: (Ry_f64, x, th, 1).
; ONE BUS (rules 20, 21): tx[] receives rail stores and is passed to a callee, y[] is passed to a callee, so both
; allocas are BUS-RESIDENT: __cq_alloc(24, 16) and __cq_alloc(16, 16) at their program points, no alloca remains and
; the lifetime markers are dropped (rule 16). Every store is a kept qram_store_f64_hl at the block's run-time address
; (the geps with constant offsets stay); every load is a qram_load_f64_hl rail (rule 3).
; A POINTER IS ONE SCALAR (§1.4, rule 18): reduce(tx, n, c, y) passes two classical ptrs, a classical int and a
; classical double, so its mask is all zero: the call is reduce's OWN symbol with its C parameter list, lowered (its
; loads are bus loads, rails, so its body is not its own unlowered code, rule 19). Nothing about the arrays crosses the
; call. reduce WRITES MEMORY (its two stores), so it has no twin (rule 18): what it stores stays (rule 5 sentence 3),
; and the call is a memory version change for the caller. Its result n + 1 is classical, so the caller's switch stays
; a classical switch; each arm's bus loads of y are rails merged by a classical phi of handles (rule 9).
; Case 0 and case 1 measure the load copy itself (rule 5 sentence 1: never un-copied, it stays allocated); the
; default's two load copies are un-copied right after the fsub, before the measurement (as 200).
; THE LOOP (rule 14, classical bound): each trip loads in[i] at the classical address in + 8i, computes the UNFUSED
; llvm.fmuladd.f64 (§2: fmul_f64_hl of in[i] and c into a fresh product rail, then fadd_f64 of the product and s into
; a fresh accumulator rail) and pushes the old accumulator, the load copy and the product. After the exit, s is copied
; out (alloc + copy) and the reverse loop pops each trip: the sum, then the product, then the load copy (un-copied at
; the address recomputed from the trip index), all before the first store, the next memory version change. The exit-0
; path (n <= 0) stores the 0.0 seed itself as out[0]: the seed is that store's value rail and is kept with it (rule 7).
; SPEC GAP: rule 5 sentence 1 un-copies a load when its last reader (here the fmul's _unc in the reverse loop) precedes
; the next memory version change; rule 14 places the reverse loop "after the result is copied out" but not relative to
; the stores of the copy. Read here: the reverse loop runs right after the copy-out (rule 5's convention: as early as
; the invariant allows), so the in[i] copies are un-copied and the stores, the in[0] load and the fsub read the copy.
; Placed after the stores, every in[i] copy would be KEPT, and its handle could not be pushed for the fmul's _unc
; (a rail rule 5 keeps is not pushed, rule 14; rule 22 names the only two exceptions).
; SPEC GAP: CR fixes no calling convention or linkage for a lowered own symbol; reduce keeps internal fastcc and
; unnamed_addr, and its range return attribute and the nocapture/readonly/writeonly parameter attributes are dropped
; (§1.4).
source_filename = "array_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @array_out_param(double noundef %0, double noundef %1, double noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %7 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %6 = alloca [3 x double], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %8 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (rule 21)
  %9 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [2 x double], align 16  [bus-resident: passed to a callee (rule 20)]
  %10 = ptrtoint ptr %9 to i64    ; IR: %7 as its run-time address
  %11 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %8 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %11, double %1)    ; IR: %8 = cq_theta_f64(%0, %1)  [Ry]
  call void @cqrt_qram_store_f64_hl(i32 %6, i64 %8, i32 %11)    ; IR: llvm.lifetime.start(24, %6) dropped; store double %8, ptr %6  [tx[0] = x: a kept store, rule 5]
  %12 = call i32 @cq_template_fmul_f64_hl(i32 %11, double %2)    ; IR: %9 = fmul double %8, %2
  %13 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %10 = getelementptr inbounds i8, ptr %6, i64 8  (nothing tainted: the gep stays)
  %14 = ptrtoint ptr %13 to i64    ; IR: %10 as its run-time address
  call void @cqrt_qram_store_f64_hl(i32 %6, i64 %14, i32 %12)    ; IR: store double %9, ptr %10  [kept store: its value rail %9 is kept with it]
  %15 = call i32 @cq_template_fadd_f64_hl(i32 %11, double %2)    ; IR: %11 = fadd double %8, %2
  %16 = getelementptr inbounds i8, ptr %7, i64 16    ; IR: %12 = getelementptr inbounds i8, ptr %6, i64 16
  %17 = ptrtoint ptr %16 to i64    ; IR: %12 as its run-time address
  call void @cqrt_qram_store_f64_hl(i32 %6, i64 %17, i32 %15)    ; IR: store double %11, ptr %12  [kept store: its value rail %11 is kept with it]
  %18 = call fastcc i32 @reduce(ptr noundef %7, i32 noundef %4, double noundef %3, ptr noundef %9)    ; IR: llvm.lifetime.start(16, %7) dropped; %13 = call @reduce(%6, %4, %3, %7): all-zero mask, reduce's own symbol; it writes memory, so no twin; classical result
  %19 = and i32 %18, 3    ; IR: %14 = and i32 %13, 3  (classical)
  switch i32 %19, label %26 [    ; IR: switch i32 %14  (classical)
    i32 0, label %20
    i32 1, label %22
  ]

20:
  %21 = call i32 @cqrt_qram_load_f64_hl(i32 %6, i64 %10)    ; IR: %16 = load double, ptr %7  [r = y[0]: a bus load, a rail; measured, so never un-copied]
  br label %32

22:
  %23 = getelementptr inbounds i8, ptr %9, i64 8    ; IR: %18 = getelementptr inbounds i8, ptr %7, i64 8
  %24 = ptrtoint ptr %23 to i64    ; IR: %18 as its run-time address
  %25 = call i32 @cqrt_qram_load_f64_hl(i32 %6, i64 %24)    ; IR: %19 = load double, ptr %18  [r = y[1]: measured, never un-copied]
  br label %32

26:
  %27 = call i32 @cqrt_qram_load_f64_hl(i32 %6, i64 %10)    ; IR: %21 = load double, ptr %7  [y[0]]
  %28 = getelementptr inbounds i8, ptr %9, i64 8    ; IR: %22 = getelementptr inbounds i8, ptr %7, i64 8
  %29 = ptrtoint ptr %28 to i64    ; IR: %22 as its run-time address
  %30 = call i32 @cqrt_qram_load_f64_hl(i32 %6, i64 %29)    ; IR: %23 = load double, ptr %22  [y[1]]
  %31 = call i32 @cq_template_fsub_f64(i32 %27, i32 %30)    ; IR: %24 = fsub double %21, %23  [result rail for default]
  call void @cqrt_qram_load_f64_hl_unc(i32 %30, i32 %6, i64 %29)    ; IR: un-copy %23 (its last reader %24 is done; no memory version change since the load, rule 5)
  call void @cqrt_qram_load_f64_hl_unc(i32 %27, i32 %6, i64 %10)    ; IR: un-copy %21
  call void @cqrt_free(i32 %30)    ; IR: release the %23 rail (|0>)
  call void @cqrt_free(i32 %27)    ; IR: release the %21 rail (|0>)
  br label %32

32:
  %33 = phi i32 [ %21, %20 ], [ %25, %22 ], [ %31, %26 ]    ; IR: %26 = phi double  (classical phi of handles, rule 9)
  %34 = call double @cqrt_measure_f64(i32 %33)    ; IR: %27 = cq_measure_f64(%26)
  ret double %34    ; IR: ret double %27  (llvm.lifetime.end dropped)
}

define internal fastcc i32 @reduce(ptr noundef %0, i32 noundef %1, double noundef %2, ptr noundef %3) unnamed_addr {
  %5 = call i32 @__cq_mem()    ; the bus M
  %6 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %7 = ptrtoint ptr %3 to i64    ; IR: %3 as its run-time address
  %8 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %9 / %16  [s before trip 0, a classical-valued rail]
  %9 = icmp sgt i32 %1, 0    ; IR: %5 = icmp sgt i32 %1, 0  (classical)
  br i1 %9, label %16, label %10    ; IR: br i1 %5, label %6, label %8

10:
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %7, i32 %8)    ; IR: store double %9, ptr %3 with %9 = 0.0: out[0] is the 0.0 seed, kept with its store (rules 5, 7)
  %11 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %6)    ; IR: %10 = load double, ptr %0  [in[0]]
  %12 = call i32 @cq_template_fsub_f64(i32 %8, i32 %11)    ; IR: %11 = fsub double %9, %10  [out[1] rail]
  call void @cqrt_qram_load_f64_hl_unc(i32 %11, i32 %5, i64 %6)    ; IR: un-copy %10 (its last reader %11 is done, before the store of out[1])
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  %13 = getelementptr inbounds i8, ptr %3, i64 8    ; IR: %12 = getelementptr inbounds i8, ptr %3, i64 8
  %14 = ptrtoint ptr %13 to i64    ; IR: %12 as its run-time address
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %14, i32 %12)    ; IR: store double %11, ptr %12  [kept store: its value rail %11 is kept]
  %15 = add nsw i32 %1, 1    ; IR: %13 = add nsw i32 %1, 1  (classical)
  ret i32 %15    ; IR: ret i32 %13

16:
  %17 = zext nneg i32 %1 to i64    ; IR: %7 = zext nneg i32 %1 to i64
  br label %18

18:
  %19 = phi i64 [ 0, %16 ], [ %26, %18 ]    ; IR: %15 = phi i64 [ 0, %6 ], [ %20, %14 ]  (classical)
  %20 = phi i32 [ %8, %16 ], [ %25, %18 ]    ; IR: %16 = phi double [ 0.0, %6 ], [ %19, %14 ]
  %21 = getelementptr inbounds double, ptr %0, i64 %19    ; IR: %17 = getelementptr inbounds double, ptr %0, i64 %15  (classical index: the gep stays)
  %22 = ptrtoint ptr %21 to i64    ; IR: %17 as its run-time address
  %23 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %22)    ; IR: %18 = load double, ptr %17  [in[i]: a bus load, a rail]
  %24 = call i32 @cq_template_fmul_f64_hl(i32 %23, double %2)    ; IR: %19 = fmuladd(%18, %2, %16)  [product in[i] * c]
  %25 = call i32 @cq_template_fadd_f64(i32 %24, i32 %20)    ; IR: %19 = fmuladd(%18, %2, %16)  [sum + s]
  call void @cqrt_push(i32 %20)    ; IR: %16 [old accumulator, kept for the reverse loop]
  call void @cqrt_push(i32 %23)    ; IR: %18 [the load copy, un-copied by the reverse loop]
  call void @cqrt_push(i32 %24)    ; IR: %19 [product rail, kept for the reverse loop]
  %26 = add nuw nsw i64 %19, 1    ; IR: %20 = add nuw nsw i64 %15, 1
  %27 = icmp eq i64 %26, %17    ; IR: %21 = icmp eq i64 %20, %7
  br i1 %27, label %28, label %18    ; IR: br i1 %21, label %8, label %14

28:
  %29 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %9 = phi with %9 = %19  [s copied out: out[0]'s value rail]
  call void @cqrt_copy_f64(i32 %25, i32 %29)    ; IR: copy s out
  br label %30

30:
  %31 = phi i64 [ %19, %28 ], [ %38, %30 ]    ; IR: trip being undone, from the last down to 0
  %32 = phi i32 [ %25, %28 ], [ %35, %30 ]    ; IR: %19 of that trip
  %33 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %34 = call i32 @cqrt_pop()    ; IR: that trip's load copy %18
  %35 = call i32 @cqrt_pop()    ; IR: that trip's %16
  call void @cq_template_fadd_f64_unc(i32 %32, i32 %33, i32 %35)    ; IR: uncompute %19 [sum]
  call void @cqrt_free(i32 %32)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %33, i32 %34, double %2)    ; IR: uncompute %19 [product]
  call void @cqrt_free(i32 %33)    ; IR: release the product rail (|0>)
  %36 = getelementptr double, ptr %0, i64 %31    ; IR: %17 of that trip, recomputed from the trip index
  %37 = ptrtoint ptr %36 to i64
  call void @cqrt_qram_load_f64_hl_unc(i32 %34, i32 %5, i64 %37)    ; IR: un-copy %18 (no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %34)    ; IR: release the %18 rail (|0>)
  %38 = add nsw i64 %31, -1
  %39 = icmp sgt i64 %38, -1
  br i1 %39, label %30, label %40

40:
  call void @cqrt_free(i32 %35)    ; IR: release the s rail before trip 0 (never written, holds 0.0)
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %7, i32 %29)    ; IR: store double %9, ptr %3  [out[0] = s: kept store, the copy-out is its value rail]
  %41 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %6)    ; IR: %10 = load double, ptr %0  [in[0]]
  %42 = call i32 @cq_template_fsub_f64(i32 %29, i32 %41)    ; IR: %11 = fsub double %9, %10  [out[1] rail]
  call void @cqrt_qram_load_f64_hl_unc(i32 %41, i32 %5, i64 %6)    ; IR: un-copy %10 (its last reader %11 is done, before the store of out[1])
  call void @cqrt_free(i32 %41)    ; IR: release the %10 rail (|0>)
  %43 = getelementptr inbounds i8, ptr %3, i64 8    ; IR: %12 = getelementptr inbounds i8, ptr %3, i64 8
  %44 = ptrtoint ptr %43 to i64    ; IR: %12 as its run-time address
  call void @cqrt_qram_store_f64_hl(i32 %5, i64 %44, i32 %42)    ; IR: store double %11, ptr %12  [kept store: its value rail %11 is kept]
  %45 = add nsw i32 %1, 1    ; IR: %13 = add nsw i32 %1, 1  (classical)
  ret i32 %45    ; IR: ret i32 %13
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_copy_f64(i32, i32)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_f64_hl(i32, i64, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare i32 @cq_template_fsub_f64(i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
