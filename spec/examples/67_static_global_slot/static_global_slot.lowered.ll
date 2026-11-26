; HAND-WRITTEN. Rules: 20, 5, 18, 16, 21, 4, 6, 3, 2; §1.3 (the bus, __cq_mem).
; Checked: y + saved, saved = x * c, y = bump(saved) (measured); the cell `saved` = x * c (read from the bus at exit).
; Clean: the load copy of saved (%8, un-copied after the add: no memory version change follows it), and every rail
; inside the clone.
; Kept: the user register x (%5); the product x * c (%6: the value rail of the kept store `saved = x * c`, rule 5,
; sentence 3) and that store's tape slot (no handle: it is in the backend and holds the displaced `saved`); the clone's
; result rail (%7, updated in place into y + saved, measured); the clone's tape rail and its tape field rail (never
; freed).
; Rotations: (Ry, x, th, 1).
; A function-local `static` is a global with internal linkage (the casin shape: openlibm keeps `static double complex
; ca, ct, zz, z2;` and stores quantum values into them between calls to csqrt/clog, which is what stops -O1 from
; localizing them). ONE BUS (rule 20): the global lives at its host address, on the bus through the overlay; nothing is
; allocated, seeded or registered for it, it is not host-resident (it is not `isConstant()`), and nothing is known
; about it at compile time. `saved = x * c` is a KEPT bus store at the classical address `ptrtoint (ptr @saved to
; i64)` (rule 5, sentence 3: no _unc, its tape slot stays for the shot, and so does its value rail, the product, which
; is therefore no longer uncomputed). The callee is cloned for its quantum argument (rule 18); its printf is the output
; tape of example 47 (rule 16: one tape per function, the entry appended once). A format entry is no memory version
; change (rule 5), so bump does not write memory and has a twin, which would recompute the pure chain only (tape
; operations are write-once and are never replayed). The read back of `saved` after the call is a fresh bus load copy
; (rule 3: a rail, whatever the cell holds); its last reader is the add, and no memory version change follows, so it
; is un-copied right after the add (sentence 1) while the cells still hold what they held at the load. The add is a
; plain add of a dead value, the call result y (a load copy is undone by its un-copy, never by rule 6): rule 6's
; in-place update, which by the owner ruling of 2026-11-26 applies though y is rule-5 garbage (a clone result with a
; twin), makes it ONE core gate add_i32(saved, y) on y's rail, which is the result from there on and is measured. The
; twin is therefore never called (the rail no longer holds y), and none is emitted.
source_filename = "static_global_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@static_global_slot.saved = internal unnamed_addr global i32 0, align 4    ; IR: @static_global_slot.saved  (lives at its host address on the bus; nothing is allocated for it)
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1    ; IR: @.str  (format string of the tape entry)

define i32 @static_global_slot(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (once, at function entry)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_mul_i32_hl(i32 %5, i32 %2)    ; IR: %5 = mul nsw i32 %4, %2
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 ptrtoint (ptr @static_global_slot.saved to i64), i32 %6)    ; IR: store i32 %5, ptr @static_global_slot.saved: saved = x * c  (kept store at a classical address: tape slot and value rail stay, no _unc)
  %7 = call fastcc i32 @__cq_q_bump_1(i32 %6)    ; IR: %6 = call @bump(%5), quantum clone (arg 0 quantum); a format entry is no memory version change
  %8 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @static_global_slot.saved to i64))    ; IR: %7 = load i32, ptr @static_global_slot.saved  (a bus load at the same classical address: a fresh rail)
  call void @cqrt_add_i32(i32 %8, i32 %7)    ; IR: %8 = add nsw i32 %7, %6  [rule 6, in-place update (owner ruling 2026-11-26: it applies to the clone result, rule-5 garbage with a twin): y is dead after the add, so the result IS the y rail: y += saved]
  call void @cqrt_qram_load_i32_hl_unc(i32 %8, i32 %4, i64 ptrtoint (ptr @static_global_slot.saved to i64))    ; IR: un-copy %7 (rule 5, sentence 1: its last reader is the add, no memory version change since the load)
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_bump_1(i32 %0) {
  %2 = call i32 @cqrt_tape_alloc()    ; IR: the clone's output tape
  call void @cqrt_tape_fmt(i32 %2, ptr @.str)    ; IR: %2 = printf(@.str, %0): open the entry with its format string
  %3 = call i32 @cqrt_tape_write_i32(i32 %2, i32 %0)    ; IR: %2 = printf(..., %0): field 0, a quantum value copied onto a fresh tape rail
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)    ; IR: %3 = add nsw i32 %0, 1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %3  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret i32 %5    ; IR: ret i32 %3
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cqrt_add_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
