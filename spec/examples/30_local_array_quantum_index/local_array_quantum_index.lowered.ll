; HAND-WRITTEN. Rules: 2, 3, 4, 5, 7, 16, 20, 21, 22.
; Checked: local_array_quantum_index: v = arr[x & 3] (the load copy, measured, %25 -> %26) = {a, b, a + b, a * b}[x & 3].
; local_array_quantum_write: arr[0] + arr[2] (the add rail, measured, %24 -> %25) = ((x & 3) == 0 || (x & 3) == 2) ? a :
; 0; the cells of arr at exit, read from the bus at the block's address: arr[i] = (i == (x & 3)) ? a : 0.
; For the driver (x0 = 0, th = .5, Ry on every bit of x; a bit flips with p = sin^2(.25) = 0.061209): x & 3 = 0, 1, 2,
; 3 with 0.881329, 0.057462, 0.057462, 0.003747. local_array_quantum_index(0, .5, 3, 4) measures 3, 4, 7, 12 with
; those probabilities; local_array_quantum_write(0, .5, 7) measures 7 with p = 0.938791 and 0 with p = 0.061209.
; Clean: local_array_quantum_index: the address chain of &arr[x & 3] (x & 3, its zext, the scaled index, the address
; rail: %21..%24), uncomputed and freed right after the load. local_array_quantum_write: the address chain of
; &arr[x & 3] (%15..%18), uncomputed and freed right after the store; the two load copies arr[0] and arr[2] (%20, %23),
; un-copied after the add (no memory version change follows the loads) and freed.
; Kept: x (%8, %7: the rotated register). local_array_quantum_index: the load copy v (%25, measured, rule 2);
; by rule 5 the tape slots of the four element stores and their four value seeds (a, b, a + b, a * b: %9, %12, %16,
; %20). local_array_quantum_write: the sum (%24, measured); by rule 5 the tape slots of the memset's 16 byte stores
; with their one value seed (i8 0, %8), and the tape slot of the store at the address rail with its value seed (a,
; %19). Every seed is classical-valued (no qubit, §0).
; Rotations: (Ry, x, th, 1) in each entry.
; ONE BUS (rule 20). In both functions arr is BUS-RESIDENT: a getelementptr with a tainted index (x & 3) is among its
; users, which rule 20 (b) does not allow, so no alloca remains: the block is __cq_alloc(16, 16) at the alloca's
; program point (rule 16: zeroed, an address never reused) and the lifetime markers are dropped. m = __cq_mem() is
; called once, at entry (§5). Nothing is known about an address at compile time: the base is the block's run-time
; address, a classical i64 (ptrtoint, rule 21); a getelementptr with only constant indices stays and its address is
; its ptrtoint; the getelementptr with the tainted index is 64-bit template arithmetic into an address rail (rule 20):
; the index rail (-O1's zext nneg to i64, as written), mul_i64_hl by the element size 4, add_i64_hl of the classical
; part (the base; the constant index 0 contributes 0). No index is narrowed, bounded or checked.
; local_array_quantum_index. A local array of classical values that is READ at a quantum index is no longer a QROM:
; every store is a bus store and every load a bus load (rule 20). The four element stores are qram_store_i32_hl at
; classical addresses, each of a seed alloc_i32(value) minted for it (rule 7), kept with its store (rule 5 sentence
; 3); their value, address and control are classical-valued, so they write host bytes and the cells stay HOST. The
; read is ONE qram_load_i32 at the address rail; the load copy is measured, so it is never un-copied (rules 2, 5
; sentence 1), and its address rail, whose last reader is that access, is uncomputed right after it.
; local_array_quantum_write. The initializer `= {0, 0, 0, 0}` is -O1's llvm.memset(arr, 0, 16) into a bus-resident
; destination: rule 22's ONE host loop of 16 kept byte stores qram_store_i8_hl at the classical addresses arr + j, all
; of one i8 seed alloc_i8(0), never widened into word stores and emitted although the block is already zero (§0).
; arr[x & 3] = a is ONE qram_store_i32 at the address rail of the seed alloc_i32(a): a kept store (no _unc, its tape
; slot and its value seed stay); its address rail is template garbage, uncomputed right after the store (rule 5
; sentence 3). arr[0] and arr[2] are qram_load_i32_hl at classical addresses; no memory version change follows them,
; so each is un-copied after its last reader, the add, before the measurement of the sum (rule 5 sentence 1).
source_filename = "local_array_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @local_array_quantum_index(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address, a classical i64 (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: llvm.lifetime.start(16, %5) dropped (rule 16); store i32 %2, ptr %5: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %9)    ; IR: store i32 %2, ptr %5  [arr[0] = a: a kept store at a classical address (rule 5)]
  %10 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %7 = getelementptr inbounds i8, ptr %5, i64 4  (nothing tainted: the gep stays)
  %11 = ptrtoint ptr %10 to i64    ; IR: %7 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %7: the seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %11, i32 %12)    ; IR: store i32 %3, ptr %7  [arr[1] = b: kept store]
  %13 = add nsw i32 %3, %2    ; IR: %8 = add nsw i32 %3, %2  (classical)
  %14 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %9 = getelementptr inbounds i8, ptr %5, i64 8  (the gep stays)
  %15 = ptrtoint ptr %14 to i64    ; IR: %9 as its run-time address
  %16 = call i32 @cqrt_alloc_i32(i32 %13)    ; IR: store i32 %8, ptr %9: the seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %15, i32 %16)    ; IR: store i32 %8, ptr %9  [arr[2] = a + b: kept store]
  %17 = mul nsw i32 %3, %2    ; IR: %10 = mul nsw i32 %3, %2  (classical)
  %18 = getelementptr inbounds i8, ptr %6, i64 12    ; IR: %11 = getelementptr inbounds i8, ptr %5, i64 12  (the gep stays)
  %19 = ptrtoint ptr %18 to i64    ; IR: %11 as its run-time address
  %20 = call i32 @cqrt_alloc_i32(i32 %17)    ; IR: store i32 %10, ptr %11: the seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %19, i32 %20)    ; IR: store i32 %10, ptr %11  [arr[3] = a * b: kept store]
  %21 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %12 = and i32 %6, 3
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %13 = zext nneg i32 %12 to i64
  %23 = call i32 @cq_template_mul_i64_hl(i32 %22, i64 4)    ; IR: %14 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %13  [the tainted index scaled by the element size (rule 20)]
  %24 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %7)    ; IR: %14 = getelementptr  [+ the classical part, the run-time base: the address rail of &arr[x & 3]]
  %25 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %24)    ; IR: %15 = load i32, ptr %14, align 4  [v = arr[x & 3]: ONE load at the address rail; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %23, i64 %7)    ; IR: uncompute %14  [the address rail's last reader was the load (rule 20)]
  call void @cqrt_free(i32 %24)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %23, i32 %22, i64 4)    ; IR: uncompute %14 (the scaled index)
  call void @cqrt_free(i32 %23)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)    ; IR: uncompute %13
  call void @cqrt_free(i32 %22)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %8, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %21)    ; IR: release the %12 rail (|0>)
  %26 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %16 = cq_measure_si32(%15)  [the load copy is the measured rail, rule 2]
  ret i32 %26    ; IR: llvm.lifetime.end(16, %5) dropped (rule 16); ret i32 %16
}

define i32 @local_array_quantum_write(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: llvm.lifetime.start(16, %4) dropped (rule 16); call @llvm.memset(%4, i8 0, 16): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %9

9:
  %10 = phi i64 [ 0, %3 ], [ %12, %9 ]    ; IR: call @llvm.memset(%4, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %11 = add i64 %6, %10    ; IR: the classical address arr + j
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %11, i32 %8)    ; IR: call @llvm.memset(%4, i8 0, 16): byte store j  (kept store, rule 5; classical-valued, the cell stays HOST)
  %12 = add nuw nsw i64 %10, 1
  %13 = icmp eq i64 %12, 16
  br i1 %13, label %14, label %9

14:
  %15 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %6 = and i32 %5, 3
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %15)    ; IR: %7 = zext nneg i32 %6 to i64
  %17 = call i32 @cq_template_mul_i64_hl(i32 %16, i64 4)    ; IR: %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7  [the tainted index scaled by the element size (rule 20)]
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 %6)    ; IR: %8 = getelementptr  [+ the run-time base: the address rail of &arr[x & 3]]
  %19 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %8: the classical value a as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32(i32 %4, i32 %18, i32 %19)    ; IR: store i32 %2, ptr %8, align 4  [arr[x & 3] = a: ONE kept store at the address rail; its tape slot and its value seed stay (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 %6)    ; IR: uncompute %8  [the address rail follows its producer, after the store (rule 5)]
  call void @cqrt_free(i32 %18)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %17, i32 %16, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %17)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %15)    ; IR: uncompute %7
  call void @cqrt_free(i32 %16)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %7, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %15)    ; IR: release the %6 rail (|0>)
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %9 = load i32, ptr %4, align 16  [arr[0]: a bus load at a classical address, a rail (rule 3)]
  %21 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %10 = getelementptr inbounds i8, ptr %4, i64 8  (nothing tainted: the gep stays)
  %22 = ptrtoint ptr %21 to i64    ; IR: %10 as its run-time address
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %22)    ; IR: %11 = load i32, ptr %10, align 8  [arr[2]]
  %24 = call i32 @cq_template_add_i32(i32 %23, i32 %20)    ; IR: %12 = add nsw i32 %11, %9  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %4, i64 %22)    ; IR: un-copy %11 (its last consumer %12 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %23)    ; IR: release the %11 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %20, i32 %4, i64 %6)    ; IR: un-copy %9
  call void @cqrt_free(i32 %20)    ; IR: release the %9 rail (|0>)
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %13 = cq_measure_si32(%12)  [the sum rail stays allocated]
  ret i32 %25    ; IR: llvm.lifetime.end(16, %4) dropped (rule 16); ret i32 %13
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
