; HAND-WRITTEN. Rules: 26, 22, 20, 21, 18, 16, 7, 5, 4, 3, 2, 25; §1.4.
; Checked: creall(q) + cimagl(q), q = scale2(re + im*I) (measured): (re + im*0) * 2 + im * 2 in x87 extended
; arithmetic, re the rotated register; the cells of z's block and of the byval copy at exit (z.real = re + im*0 at
; offset 0, z.imag = im at offset 16, both blocks).
; Clean: the clone's two result rails (zeroed by the twin __cq_q_scale2_0_unc after their last consumer, the sum, then
; freed); every rail inside the clone and its twin (the two bus load copies of z.real and z.imag, un-copied after their
; templates' _unc, and the two fadd results).
; Kept: the user register re; by rule 5 the real part re + im*0 (the value rail of the kept f80 store into z.real), the
; seed im (the value rail of the kept store into z.imag), the tape slots of those two stores, the 32 byte load copies
; of the byval copy (each the value rail of a kept byte store) and the 32 tape slots of those byte stores; the sum
; (measured).
; Rotations: (Ry, re, th, 1).
; ONE BUS (rules 20, 21, 26): on x86-64 a `long double complex` does not travel in registers: -O1 builds z in an
; `alloca { x86_fp80, x86_fp80 }` and passes it `byval`; the return comes back as the SSA aggregate
; { x86_fp80, x86_fp80 }. The alloca is BUS-RESIDENT (a store of a tainted value through it, and the call, are among
; its users), so it is __cq_alloc(32, 16) at its program point, no alloca remains and the lifetime markers are dropped
; (rule 16). Its two stores are f80 bus stores (10 cells each, store size; the 6 padding bytes behind each are never
; touched) at the block's run-time address and at the untainted getelementptr + 16, which stays: the real part is the
; rail re + im*0, the imaginary part the classical im minted as a seed (rule 7). Both are kept stores (rule 5).
; THE BYVAL COPY (rules 26, 22): the caller makes the copy, a second block q = __cq_alloc(32, 16) and a bus copy of
; the 32 bytes of the byval type (padding included): one host loop of 32 qram_load_i8_hl at z's block, each byte rail
; pushed, then one host loop of 32 qram_store_i8_hl at q, popping, bytes 31 down to 0. Each byte store is kept with
; its value rail, the byte's load copy (rule 22). The call passes q as a plain ptr: no `byval` remains on it.
; THE CLONE (§1.4, rules 18, 26): the plain-ptr form of a function with a byval formal is spelled by the clone grammar
; even with the all-zero mask: q is a classical ptr, mask 0, so __cq_q_scale2_0(ptr). Nothing about the pointee
; crosses the call: the clone reads both fields from the bus at q and q + 16, and every load is a rail (rule 3), so
; z.imag, classical in C, is a rail inside the clone and both results are rails: the clone returns { i32, i32 }, each
; result copied into a fresh rail (rule 18), its SSA body uncomputed (the templates' _unc, then the load copies
; un-copied: no memory version change in the clone). The clone writes no memory, so it has a twin; its call is a
; load for rule 5: the twin runs after the results' last consumer, the caller's fadd, with no memory version change
; between, and the caller frees both result rails after it. scale2's own symbol is internal and has no caller left,
; so it is dropped (§1.4).
; SPEC GAP: rule 26 says the caller makes the byval copy but not at which program point; it is made immediately before
; the call (after z's two stores, which it must read).
; complex_long_double is externally visible and its address is never taken: by §5's example convention its clone-table
; row, _t clone, _t_ctl and their twins are omitted (the compiler emits them; they emit no gate and §6 does not compare
; them).
source_filename = "complex_long_double.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define x86_fp80 @complex_long_double(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 32, i64 16)    ; IR: %4 = alloca { x86_fp80, x86_fp80 }, align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %5 = cq_theta_f80(%0, %1)  [register re]
  call void @cqrt_ry_f80(i32 %7, double %1)    ; IR: %5 = cq_theta_f80(%0, %1)  [Ry]
  %8 = fmul x86_fp80 %2, 0xK00000000000000000000    ; IR: %6 = fmul x86_fp80 %2, 0  (classical)
  %9 = call i32 @cq_template_fadd_f80_hl(i32 %7, x86_fp80 %8)    ; IR: %7 = fadd x86_fp80 %6, %5  (real part of z; commutative, quantum operand first)
  %10 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: llvm.lifetime.start(32, %4) dropped (rule 16); %8 = getelementptr inbounds i8, ptr %4, i64 16  (nothing tainted: the getelementptr stays)
  %11 = ptrtoint ptr %10 to i64    ; the run-time address of z.imag, a classical i64 (rule 21)
  call void @cqrt_qram_store_f80_hl(i32 %4, i64 %6, i32 %9)    ; IR: store x86_fp80 %7, ptr %4  [z.real: a kept store at a classical address; its tape slot and its value rail %7 stay (rule 5)]
  %12 = call i32 @cqrt_alloc_f80(x86_fp80 %2)    ; IR: store x86_fp80 %2, ptr %8: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_f80_hl(i32 %4, i64 %11, i32 %12)    ; IR: store x86_fp80 %2, ptr %8  [z.imag: a kept store (rule 5); classical-valued, the cells stay HOST]
  %13 = call ptr @__cq_alloc(i64 32, i64 16)    ; IR: %9 = call @scale2(byval %4): the caller's byval copy, a fresh block of the byval type's size and alignment (rule 26)  ; SPEC GAP: rule 26 does not place the copy; immediately before the call
  %14 = ptrtoint ptr %13 to i64    ; the copy's run-time address, a classical i64 (rule 21)
  br label %15    ; IR: %9: the byval copy (rule 22: load all 32 source bytes, then store all 32)

15:
  %16 = phi i64 [ 0, %3 ], [ %19, %15 ]    ; byte index of the load loop (classical)
  %17 = add i64 %6, %16    ; the source byte's address in z's block (classical)
  %18 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %17)    ; IR: %9: source byte j  [a bus load; the copy is the value rail of byte j's store, KEPT (rules 5, 22)]
  call void @cqrt_push(i32 %18)    ; IR: %9: the byte rail to the store loop (rule 22)
  %19 = add nuw nsw i64 %16, 1
  %20 = icmp eq i64 %19, 32
  br i1 %20, label %21, label %15

21:
  %22 = phi i64 [ 32, %15 ], [ %23, %21 ]    ; bytes left to store (classical)
  %23 = add nsw i64 %22, -1    ; byte index of this store: 31 down to 0 (the pop order)
  %24 = call i32 @cqrt_pop()    ; IR: %9: the load copy of byte %23
  %25 = add i64 %14, %23    ; the destination byte's address in the copy (classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %25, i32 %24)    ; IR: %9: destination byte  [a kept store: its tape slot and the byte rail stay (rules 5, 22)]
  %26 = icmp eq i64 %23, 0
  br i1 %26, label %27, label %21

27:
  %28 = call fastcc { i32, i32 } @__cq_q_scale2_0(ptr noundef %13)    ; IR: %9 = call @scale2(byval %4): the plain-ptr form, mask 0 (q classical); no byval on the lowered call (rule 26, §1.4)
  %29 = extractvalue { i32, i32 } %28, 0    ; IR: %10 = extractvalue %9, 0  (handle of the real result; classical)
  %30 = extractvalue { i32, i32 } %28, 1    ; IR: %11 = extractvalue %9, 1  (handle of the imaginary result: a rail, it came through the bus)
  %31 = call i32 @cq_template_fadd_f80(i32 %29, i32 %30)    ; IR: llvm.lifetime.end(32, %4) dropped (rule 16); %12 = fadd x86_fp80 %10, %11  [result rail]
  call fastcc void @__cq_q_scale2_0_unc(i32 %29, i32 %30, ptr noundef %13)    ; IR: uncompute %10, %11 (the call's results; the twin after their last consumer %12, no memory version change since the call, rule 18)
  call void @cqrt_free(i32 %29)    ; IR: release the %10 rail (|0>)
  call void @cqrt_free(i32 %30)    ; IR: release the %11 rail (|0>)
  %32 = call x86_fp80 @cqrt_measure_f80(i32 %31)    ; IR: %13 = cq_measure_f80(%12)
  ret x86_fp80 %32    ; IR: ret x86_fp80 %13
}

define internal fastcc { i32, i32 } @__cq_q_scale2_0(ptr noundef %0) unnamed_addr {
  %2 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %3 = ptrtoint ptr %0 to i64    ; %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %4 = call i32 @cqrt_qram_load_f80_hl(i32 %2, i64 %3)    ; IR: %2 = load x86_fp80, ptr %0  [z.real: a bus load, a rail (rule 3)]
  %5 = getelementptr inbounds i8, ptr %0, i64 16    ; IR: %3 = getelementptr inbounds i8, ptr %0, i64 16  (nothing tainted: the getelementptr stays)
  %6 = ptrtoint ptr %5 to i64    ; the run-time address of z.imag (rule 21)
  %7 = call i32 @cqrt_qram_load_f80_hl(i32 %2, i64 %6)    ; IR: %4 = load x86_fp80, ptr %3  [z.imag: a bus load, a rail (rule 3)]
  %8 = call i32 @cq_template_fadd_f80(i32 %4, i32 %4)    ; IR: %5 = fadd x86_fp80 %2, %2  (the same rail in both slots)
  %9 = call i32 @cq_template_fadd_f80(i32 %7, i32 %7)    ; IR: %6 = fadd x86_fp80 %4, %4  (the same rail in both slots)
  %10 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: %7 = insertvalue poison, %5, 0  [result rail: real]
  call void @cqrt_copy_f80(i32 %8, i32 %10)    ; IR: copy the real part out
  call void @cq_template_fadd_f80_unc(i32 %8, i32 %4, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  %11 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: %8 = insertvalue %7, %6, 1  [result rail: imaginary]
  call void @cqrt_copy_f80(i32 %9, i32 %11)    ; IR: copy the imaginary part out
  call void @cq_template_fadd_f80_unc(i32 %9, i32 %7, i32 %7)    ; IR: uncompute %6
  call void @cqrt_free(i32 %9)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_load_f80_hl_unc(i32 %7, i32 %2, i64 %6)    ; IR: un-copy %4 (its last reader is the _unc of %6; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %7)    ; IR: release the %4 rail (|0>)
  call void @cqrt_qram_load_f80_hl_unc(i32 %4, i32 %2, i64 %3)    ; IR: un-copy %2 (its last reader is the _unc of %5)
  call void @cqrt_free(i32 %4)    ; IR: release the %2 rail (|0>)
  %12 = insertvalue { i32, i32 } poison, i32 %10, 0    ; IR: %7 = insertvalue poison, %5, 0  (handle of the real result)
  %13 = insertvalue { i32, i32 } %12, i32 %11, 1    ; IR: %8 = insertvalue %7, %6, 1  (handle of the imaginary result)
  ret { i32, i32 } %13    ; IR: ret { x86_fp80, x86_fp80 } %8
}

define internal fastcc void @__cq_q_scale2_0_unc(i32 %0, i32 %1, ptr noundef %2) unnamed_addr {
  %4 = call i32 @__cq_mem()    ; the bus M
  %5 = ptrtoint ptr %2 to i64    ; %2 as its run-time address
  %6 = call i32 @cqrt_qram_load_f80_hl(i32 %4, i64 %5)    ; IR: reload %2 (z.real)
  %7 = getelementptr inbounds i8, ptr %2, i64 16    ; IR: %3
  %8 = ptrtoint ptr %7 to i64    ; the run-time address of z.imag
  %9 = call i32 @cqrt_qram_load_f80_hl(i32 %4, i64 %8)    ; IR: reload %4 (z.imag)
  %10 = call i32 @cq_template_fadd_f80(i32 %6, i32 %6)    ; IR: recompute %5
  call void @cqrt_copy_f80(i32 %10, i32 %0)    ; IR: xor the real part out of the result rail
  call void @cq_template_fadd_f80_unc(i32 %10, i32 %6, i32 %6)    ; IR: uncompute %5
  call void @cqrt_free(i32 %10)    ; IR: release the %5 rail (|0>)
  %11 = call i32 @cq_template_fadd_f80(i32 %9, i32 %9)    ; IR: recompute %6
  call void @cqrt_copy_f80(i32 %11, i32 %1)    ; IR: xor the imaginary part out of the result rail
  call void @cq_template_fadd_f80_unc(i32 %11, i32 %9, i32 %9)    ; IR: uncompute %6
  call void @cqrt_free(i32 %11)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_load_f80_hl_unc(i32 %9, i32 %4, i64 %8)    ; IR: un-copy %4
  call void @cqrt_free(i32 %9)    ; IR: release the %4 rail (|0>)
  call void @cqrt_qram_load_f80_hl_unc(i32 %6, i32 %4, i64 %5)    ; IR: un-copy %2
  call void @cqrt_free(i32 %6)    ; IR: release the %2 rail (|0>)
  ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_ry_f80(i32, double)
declare void @cqrt_copy_f80(i32, i32)
declare void @cqrt_free(i32)
declare x86_fp80 @cqrt_measure_f80(i32)
declare void @cqrt_qram_store_f80_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_f80_hl(i32, i64)
declare void @cqrt_qram_load_f80_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_fadd_f80(i32, i32)
declare void @cq_template_fadd_f80_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f80_hl(i32, x86_fp80)
