; HAND-WRITTEN. Rules: 24, 20, 16, 21, 5 (Memory, sentences 1 and 3), 6, 4, 2.
; Checked: y = tmp * 2 (measured, %11 -> %12); the cell tmp on the bus at exit holds x + c.
; Clean: the old x rail (%7, rule 6: x + c is a bijection in x, the add is x's only reader, and x is not itself the
; value rail of the kept store, so a clean-up point exists: right after the add, t = (x + c) - c recomputes x fresh,
; copy_i32(t, x) zeroes x, t is uncomputed, and both are freed); the load copy of tmp, un-copied and freed after its
; last reader (the shl), before the measurement.
; Kept: the sum rail x + c, the value rail of the kept store to tmp, and that store's tape slot (rule 5 sentence 3);
; the result rail (measured). Nothing else.
; Rotations: (Ry, x, th, 1).
; Expected: Ry acts on all 32 qubits of x and everything after it is a basis permutation, so the measured value is
; the C program on independent bit flips of x with p = sin^2(.25) = 0.061209: volatile_local(0, .5, 3) measures
; 2 * ((0 ^ e) + 3) mod 2^32 for the flip pattern e, 6 with (1 - p)^31 = 0.141137 (e = 0, or e = 1<<31: 2 * (2^31 + 3) wraps to 6).
; THE VOLATILE IS UNOBSERVABLE (rule 24): its pointer operand is the alloca %4, whose only uses are the volatile store
; and load through it, lifetime intrinsics aside (rule 24), so the qualifier is dropped and both accesses are rule 20's.
; THE SLOT IS BUS-RESIDENT (rule 20 (b)): the store writes the rail x + c, a tainted value, so the alloca fails the
; host-resident test. It is __cq_alloc(4, 4) at the alloca's program point (rule 16), no alloca remains, and the
; lifetime markers are dropped. Its address is the classical i64 ptrtoint of the block (rule 21), so the store is
; qram_store_i32_hl and the load qram_load_i32_hl. No rule forwards the stored value to the load: the load is a fresh
; copy of the cell (rule 20: every load is a bus load), and -O1's `tmp * 2` = shl 1 is an _hl shl template on it.
; THE STORE IS KEPT (rule 5 sentence 3): its tape slot stays for the shot and so does its value rail, the sum x + c,
; which is therefore never uncomputed. The load copy's last reader is the shl, whose result is measured (no _unc to
; wait for); no memory version change follows, so the copy is un-copied right after the shl, before the measurement
; (rule 5 sentence 1).
source_filename = "volatile_local.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @volatile_local(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %4 = alloca i32, align 4  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_add_i32_hl(i32 %7, i32 %2)    ; IR: llvm.lifetime.start(4, %4) dropped (rule 16); %6 = add nsw i32 %5, %2
  %9 = call i32 @cq_template_sub_i32_hl(i32 %8, i32 %2)    ; IR: rule 6 (right after the update): t = (x + c) - c recomputes x
  call void @cqrt_copy_i32(i32 %9, i32 %7)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %9)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the old x rail (|0> after the copy)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %8)    ; IR: store volatile i32 %6, ptr %4  [qualifier dropped (rule 24); a kept store: its tape slot and its value rail %6 stay (rule 5)]
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %7 = load volatile i32, ptr %4  [qualifier dropped (rule 24); a bus load at a classical address: a rail (rule 20)]
  %11 = call i32 @cq_template_shl_i32_hl(i32 %10, i32 1)    ; IR: %8 = shl nsw i32 %7, 1
  call void @cqrt_qram_load_i32_hl_unc(i32 %10, i32 %4, i64 %6)    ; IR: un-copy %7 (rule 5: no memory version change since the load; the cell holds the loaded value)
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %12    ; IR: llvm.lifetime.end(4, %4) dropped (rule 16); ret i32 %9
}

declare i32 @__cq_mem()

declare ptr @__cq_alloc(i64, i64)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
