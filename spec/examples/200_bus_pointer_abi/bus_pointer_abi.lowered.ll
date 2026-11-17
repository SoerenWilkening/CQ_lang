; HAND-WRITTEN. Rules: 1, 2, 3, 4, 5, 7, 16, 18, 19, 20, 21, 22; §1.4.
; Checked: bus_pointer_arg: a[0] + a[1] (the add rail, measured) = 5 + ((k & 3) == 0 ? x : 0); the cells a[0..3] at
; exit: a[k & 3] = x, then a[2] = x, then a[1] = 5. bus_pointer_result: tab[1] (the load copy, measured) =
; ((k & 3) == 1 ? v : 0); the cells tab[0..3] at exit: tab[k & 3] = v. For the driver (k0 = 1, tk = .5, Ry on every
; bit of k): P(k & 3 = 0) = 0.0575, P(1) = 0.8813, P(2) = 0.0037, P(3) = 0.0575. bus_pointer_arg(1, .5, 9, .25)
; measures 5 with p = 0.9425 and 5 + x with p = 0.0575 (x the rotated 9: 14 with p = 0.0575 * 0.6057 = 0.0348);
; bus_pointer_result(1, .5, 9) measures 9 with p = 0.8813 and 0 with p = 0.1187 (tab is zero at the first call).
; Clean: bus_pointer_arg: the address chain of &a[k & 3] (k & 3, its zext, the scaled index, the address rail), each
; uncomputed by its template's _unc after the store in the clone and freed; the two load copies a[0] and a[1],
; un-copied after the add, before the measurement (no memory version change follows the loads) and freed.
; bus_pointer_result: the address rail __cq_q_slot_1 returned, zeroed by the twin __cq_q_slot_1_unc after the store
; and freed; every rail inside __cq_q_slot_1 and its twin.
; Kept: bus_pointer_arg: k and x (rotated registers; x is also the value rail of both clones' stores), the sum
; (measured), and by rule 5: the 16 tape slots of the memset's byte stores with their one value seed (i8 0), the tape
; slot of the store in __cq_q_put_11, the tape slot of the store in __cq_q_put_01, the tape slot and the value seed
; (i32 5) of the store in put. bus_pointer_result: k (rotated), the load copy of tab[1] (measured), and by rule 5 the
; tape slot and the value seed (i32 v) of the store.
; Rotations: bus_pointer_arg: (Ry, k, tk, 1); (Ry, x, tx, 1). bus_pointer_result: (Ry, k, tk, 1).
; A POINTER IS ONE SCALAR (§1.4, rules 1, 21). put(&a[k & 3], x) passes an address rail and a value rail: the clone
; __cq_q_put_11(i32 address rail, i32 value rail), mask digit 1 for the pointer, nothing about the pointee in the name
; or the parameter list. put(&a[2], x) passes a classical ptr and a value rail: the clone __cq_q_put_01(ptr, i32 value
; rail), mask digit 0 for the pointer, which stays the C ptr (no handle, no seed) and is the _hl address of the store.
; put(&a[1], 5) passes a classical ptr and a classical int: the all-zero mask, which is put's OWN symbol with its C
; parameter list, lowered (its store is a bus store at the run-time address, the value a seed).
; slot(k) returns a pointer computed from a rail: __cq_q_slot_1 returns ONE i32 handle to a 64-bit address rail; slot's
; own symbol has no caller left and is dropped (§1.4).
; A CLONE THAT STORES HAS NO TWIN (rules 5, 18): put writes memory, so none of __cq_q_put_11, __cq_q_put_01 and put
; has an _unc and each store's tape slot stays. The caller treats the rails it passed by its own rules: the address
; rail is a template result and is uncomputed after the call (the store is over), x is a user register. slot writes
; nothing and loads nothing, so its twin exists and runs after the result's last consumer, the store through it.
; THE ALLOCA IS BUS-RESIDENT (rule 20): a[] is indexed by a rail and passed to a callee, so it is __cq_alloc(16, 16) at
; its program point, no alloca remains and the lifetime markers are dropped (rule 16). Its memset is rule 22's host
; loop of 16 kept byte stores of one i8 seed at the classical addresses a + j (the cells are HOST and stay HOST).
; The gep with a tainted index is 64-bit template arithmetic on the run-time base: zext (as -O1 wrote it), mul by the
; element size, add of the classical base address (rule 20); tab is a mutable global and lives at its host address.
; SPEC GAP: rule 19 / §1.3 ask for a __cq_clone_register row (the _t clone, _t_ctl and their twins) per externally
; visible function. No conforming example of the corpus emits one; this module follows the corpus and registers
; nothing for bus_pointer_arg and bus_pointer_result (host code, no gate: §6 cannot tell the two readings apart).
; SPEC GAP: rule 5 sentence 1 speaks of the last consumer's uncompute; here the consumer (the add) is measured and has
; none. The load copies are un-copied right after the add, before the measurement, as a template operand of a
; measured result is (29, 195).
; SPEC GAP: rule 5 sentence 3 names two producers of a store's address rail (a template, a bus load). Here one address
; is the result of a twinned clone: it follows rule 18, twin after the store, then free. The other is a template
; result passed INTO a storing clone: the caller uncomputes it after the call, as it would after its own store.
; SPEC GAP: CR fixes no calling convention, linkage or attributes for a clone called by name or a lowered own symbol;
; they keep the callee's (internal fastcc), as the corpus does (07, 195), and every memory, capture, nullness and
; purity fact of the original (nocapture, writeonly, nonnull, memory(argmem: write), memory(none), nofree, willreturn)
; is dropped from the lowered bodies and their call sites: the lowered functions call the backend.
; SPEC GAP: rule 22's "host loop of n byte loads, then one of n byte stores" describes a copy; a memset has no loads
; and is ONE loop of n byte stores of its one value rail. It is emitted although the __cq_alloc block is already
; zero: what the destination holds is never asked (§0).
source_filename = "bus_pointer_abi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = internal global [4 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @bus_pointer_arg(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = alloca [4 x i32], align 16: bus-resident (rule 20), one zeroed block (rule 16)
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %10 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%5, i8 0, 16): the byte value as ONE seed rail (rules 7, 22), kept with its stores; llvm.lifetime.start dropped
  br label %11
11:
  %12 = phi i64 [ 0, %4 ], [ %14, %11 ]    ; IR: call @llvm.memset(%5, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %13 = add i64 %7, %12    ; IR: the classical address a + j
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %13, i32 %10)    ; IR: call @llvm.memset(%5, i8 0, 16): byte store j  (kept store, rule 5)
  %14 = add nuw nsw i64 %12, 1
  %15 = icmp eq i64 %14, 16
  br i1 %15, label %16, label %11
16:
  %17 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %8 = and i32 %6, 3
  %18 = call i32 @cq_template_zext_i32_to_i64(i32 %17)    ; IR: %9 = zext nneg i32 %8 to i64
  %19 = call i32 @cq_template_mul_i64_hl(i32 %18, i64 4)    ; IR: %10 = getelementptr [4 x i32], ptr %5, i64 0, i64 %9: the index scaled by the element size (rule 20)
  %20 = call i32 @cq_template_add_i64_hl(i32 %19, i64 %7)    ; IR: %10: plus the classical base address  [address rail of &a[k & 3]]
  call fastcc void @__cq_q_put_11(i32 %20, i32 %9)    ; IR: call fastcc void @put(ptr %10, i32 %7): the clone of mask 11 (address rail, value rail); it stores, so it has no twin (rule 18)
  call void @cq_template_add_i64_hl_unc(i32 %20, i32 %19, i64 %7)    ; IR: uncompute %10 (the address rail outlived its store)
  call void @cq_template_mul_i64_hl_unc(i32 %19, i32 %18, i64 4)    ; IR: uncompute %10 (the scaled index)
  call void @cq_template_zext_i32_to_i64_unc(i32 %18, i32 %17)    ; IR: uncompute %9
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %8, i32 3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %20)    ; IR: release the %10 rail (|0>)
  call void @cqrt_free(i32 %19)    ; IR: release the scaled index (|0>)
  call void @cqrt_free(i32 %18)    ; IR: release the %9 rail (|0>)
  call void @cqrt_free(i32 %17)    ; IR: release the %8 rail (|0>)
  %21 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %11 = getelementptr inbounds i8, ptr %5, i64 8  (nothing tainted: the gep stays)
  call fastcc void @__cq_q_put_01(ptr %21, i32 %9)    ; IR: call fastcc void @put(ptr %11, i32 %7): the clone of mask 01 (the classical ptr stays a ptr, value rail); it stores, so it has no twin (rule 18)
  %22 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %12 = getelementptr inbounds i8, ptr %5, i64 4  (nothing tainted: the gep stays)
  call fastcc void @put(ptr noundef %22, i32 noundef 5)    ; IR: call fastcc void @put(ptr %12, i32 5): all-classical, put's own symbol (the all-zero mask, §1.4)
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %13 = load i32, ptr %5  [a[0]: every load is a bus load, a rail (rule 3)]
  %24 = ptrtoint ptr %22 to i64    ; IR: %12 as its run-time address
  %25 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %24)    ; IR: %14 = load i32, ptr %12  [a[1]]
  %26 = call i32 @cq_template_add_i32(i32 %25, i32 %23)    ; IR: %15 = add nsw i32 %14, %13
  call void @cqrt_qram_load_i32_hl_unc(i32 %25, i32 %5, i64 %24)    ; IR: un-copy %14 (its last consumer %15 is done; no memory version change since the load, rule 5)
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %5, i64 %7)    ; IR: un-copy %13
  call void @cqrt_free(i32 %25)    ; IR: release the %14 rail (|0>)
  call void @cqrt_free(i32 %23)    ; IR: release the %13 rail (|0>)
  %27 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %16 = cq_measure_si32(%15)  [the sum rail stays allocated]
  ret i32 %27    ; IR: ret i32 %16  (llvm.lifetime.end dropped)
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_put_11(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  call void @cqrt_qram_store_i32(i32 %3, i32 %0, i32 %1)    ; IR: store i32 %1, ptr %0  [at the address rail; kept store: no _unc, the clone has no twin]
  ret void    ; IR: ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_put_01(ptr noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %4, i32 %1)    ; IR: store i32 %1, ptr %0  [the value rail at a classical address; kept store: no _unc, the clone has no twin]
  ret void    ; IR: ret void
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @put(ptr noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address
  %5 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: store i32 %1, ptr %0: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %4, i32 %5)    ; IR: store i32 %1, ptr %0  [kept store at a classical address]
  ret void    ; IR: ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @bus_pointer_result(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_slot_1(i32 %5)    ; IR: %5 = call fastcc ptr @slot(i32 %4): the clone of mask 1; the pointer result is ONE handle to a 64-bit address rail
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32(i32 %4, i32 %6, i32 %7)    ; IR: store i32 %2, ptr %5  [at the address rail; kept store]
  call fastcc void @__cq_q_slot_1_unc(i32 %6, i32 %5)    ; IR: uncompute %5 (the twin, after the result's last consumer)
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %8 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @tab, i64 4) to i64))    ; IR: %6 = load i32, ptr getelementptr inbounds (i8, ptr @tab, i64 4)  [tab[1], a rail]
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %7 = cq_measure_si32(%6)  [the load copy is the measured rail, rule 2]
  ret i32 %9    ; IR: ret i32 %7
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc i32 @__cq_q_slot_1(i32 noundef %0) unnamed_addr #1 {
  %2 = call i32 @cq_template_and_i32_hl(i32 %0, i32 3)    ; IR: %2 = and i32 %0, 3
  %3 = call i32 @cq_template_zext_i32_to_i64(i32 %2)    ; IR: %3 = zext nneg i32 %2 to i64
  %4 = call i32 @cq_template_mul_i64_hl(i32 %3, i64 4)    ; IR: %4 = getelementptr [4 x i32], ptr @tab, i64 0, i64 %3: the index scaled by the element size
  %5 = call i32 @cq_template_add_i64_hl(i32 %4, i64 ptrtoint (ptr @tab to i64))    ; IR: %4: plus the classical base address of tab
  %6 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: ret ptr %4  [fresh result rail]
  call void @cqrt_copy_i64(i32 %5, i32 %6)    ; IR: ret ptr %4  [copy the address out]
  call void @cq_template_add_i64_hl_unc(i32 %5, i32 %4, i64 ptrtoint (ptr @tab to i64))    ; IR: uncompute %4
  call void @cq_template_mul_i64_hl_unc(i32 %4, i32 %3, i64 4)    ; IR: uncompute %4 (the scaled index)
  call void @cq_template_zext_i32_to_i64_unc(i32 %3, i32 %2)    ; IR: uncompute %3
  call void @cq_template_and_i32_hl_unc(i32 %2, i32 %0, i32 3)    ; IR: uncompute %2
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the scaled index (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %2)    ; IR: release the %2 rail (|0>)
  ret i32 %6    ; IR: ret ptr %4
}

; Function Attrs: mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal fastcc void @__cq_q_slot_1_unc(i32 %0, i32 noundef %1) unnamed_addr #1 {
  %3 = call i32 @cq_template_and_i32_hl(i32 %1, i32 3)    ; IR: recompute %2
  %4 = call i32 @cq_template_zext_i32_to_i64(i32 %3)    ; IR: recompute %3
  %5 = call i32 @cq_template_mul_i64_hl(i32 %4, i64 4)    ; IR: recompute %4 (the scaled index)
  %6 = call i32 @cq_template_add_i64_hl(i32 %5, i64 ptrtoint (ptr @tab to i64))    ; IR: recompute %4
  call void @cqrt_copy_i64(i32 %6, i32 %0)    ; IR: ret ptr %4  [xor the result out of %out]
  call void @cq_template_add_i64_hl_unc(i32 %6, i32 %5, i64 ptrtoint (ptr @tab to i64))    ; IR: uncompute %4
  call void @cq_template_mul_i64_hl_unc(i32 %5, i32 %4, i64 4)    ; IR: uncompute %4 (the scaled index)
  call void @cq_template_zext_i32_to_i64_unc(i32 %4, i32 %3)    ; IR: uncompute %3
  call void @cq_template_and_i32_hl_unc(i32 %3, i32 %1, i32 3)    ; IR: uncompute %2
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the scaled index (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret void
}

declare i32 @__cq_mem()

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_copy_i64(i32, i32)

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare void @cqrt_qram_store_i32(i32, i32, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

declare i32 @cq_template_add_i32(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress noinline norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
