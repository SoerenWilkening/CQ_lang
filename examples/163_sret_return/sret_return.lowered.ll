; HAND-WRITTEN. Rules: 26, 20, 18, 4, 5, 7, §1.4.
; Checked: r.a + r.b + r.c (measured).
; Clean: the two quantum field rails of the sret slot (r.a, r.b; zeroed in place by the twin, freed by the caller) and
;        the partial sum r.b + r.a.
; Kept: the register x (frozen) and the measured result rail.
; Rotations: Ry(tx) on x.
; A 24-byte struct is returned through an SRET pointer: the caller passes the address of a local, the callee stores the
; three fields into it. By rule 26 the sret pointer is a SLOT parameter (rule 20): the caller's alloca becomes a record
; of one cell per field whose KIND follows what the callee stores into it (129's per-column kinds): r.a = x + c and
; r.b = x * c are quantum, so cells a and b are 4-byte HANDLE cells; r.c = c is classical and stays a classical i64
; cell (rule 26: classical fields stay classical). The record is { i32, i32, i64 }, so -O1's byte-offset geps (8, 16)
; are re-emitted at the record's own offsets (4, 8). The clone __cq_q_mk_00010 (§1.4, one digit per field of the slot
; parameter, none quantum on entry, then x quantum, c classical) writes the two handles and the classical c straight
; into the slot (no copy-out: a store into a slot is the result's home, 31) and returns void. The caller loads the
; handles (no gate), adds out of place (rule 4), and once the sum is formed runs the twin _unc(args..., old slot
; contents in slot order): it loads the handles from the slot, zeroes each in place by its producer's _unc (as 31) and
; restores the slot's prior contents (never written before the call: poison); the caller then frees both rails.
source_filename = "sret_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @sret_return(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = alloca { i32, i32, i64 }, align 8    ; IR: %4 = alloca %struct.big  (the sret slot: handle cells for a and b, a classical i64 cell for c)
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_sl(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %5, double %1)    ; IR: %5 = cq_theta_sl(%0, %1)  [Ry]
  call fastcc void @__cq_q_mk_00010(ptr %4, i32 %5, i64 %2)    ; IR: llvm.lifetime.start(%4) (nothing); call @mk(sret %4, %5, %2): clone for mask (slot a, b, c: nothing quantum on entry; x quantum; c classical); the callee fills the slot
  %6 = load i32, ptr %4, align 8    ; IR: %6 = load i64, ptr %4  (the handle of r.a, no gate)
  %7 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %7 = getelementptr %4, 8  (field b: cell 1 of the record)
  %8 = load i32, ptr %7, align 4    ; IR: %8 = load i64, ptr %7  (the handle of r.b)
  %9 = call i32 @cq_template_add_i64(i32 %8, i32 %6)    ; IR: %9 = add nsw i64 %8, %6
  %10 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %10 = getelementptr %4, 16  (field c: the classical cell)
  %11 = load i64, ptr %10, align 8    ; IR: %11 = load i64, ptr %10  (classical: r.c = c)
  %12 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %11)    ; IR: %12 = add nsw i64 %9, %11  [result rail]
  call void @cq_template_add_i64_unc(i32 %9, i32 %8, i32 %6)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_mk_00010_unc(ptr %4, i32 %5, i64 %2, i32 poison, i32 poison, i64 poison)    ; IR: adjoint of the call: the twin zeroes the slot's two rails in place and restores the slot's contents from before the call (never written: poison)
  call void @cqrt_free(i32 %6)    ; IR: release the r.a rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the r.b rail (|0>)
  %13 = call i64 @cqrt_measure_i64(i32 %12)    ; IR: %13 = cq_measure_sl(%12)
  ret i64 %13    ; IR: llvm.lifetime.end(%4) (nothing); ret i64 %13
}

define internal fastcc void @__cq_q_mk_00010(ptr %0, i32 %1, i64 %2) {
  %4 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %2)    ; IR: %4 = add nsw i64 %2, %1  (commutative: handle first)  [r.a]
  store i32 %4, ptr %0, align 8    ; IR: store i64 %4, ptr %0  (the handle into cell a)
  %5 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: %5 = getelementptr %0, 8  (cell b)
  %6 = call i32 @cq_template_mul_i64_hl(i32 %1, i64 %2)    ; IR: %6 = mul nsw i64 %2, %1  [r.b]
  store i32 %6, ptr %5, align 4    ; IR: store i64 %6, ptr %5  (the handle into cell b)
  %7 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: %7 = getelementptr %0, 16  (cell c, classical)
  store i64 %2, ptr %7, align 8    ; IR: store i64 %2, ptr %7  (classical)
  ret void    ; IR: ret void  (the slot holds the result; the rails are the caller's to uncompute through the twin)
}

define internal fastcc void @__cq_q_mk_00010_unc(ptr %0, i32 %1, i64 %2, i32 %3, i32 %4, i64 %5) {
  %7 = load i32, ptr %0, align 8    ; IR: the handle the clone stored into cell a
  %8 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: cell b
  %9 = load i32, ptr %8, align 4    ; IR: the handle the clone stored into cell b
  %10 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: cell c
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %1, i64 %2)    ; IR: uncompute %6 (r.b) in place; the caller frees it
  call void @cq_template_add_i64_hl_unc(i32 %7, i32 %1, i64 %2)    ; IR: uncompute %4 (r.a) in place; the caller frees it
  store i32 %3, ptr %0, align 8    ; IR: restore cell a's content from before the call (§1.4: old slot contents last)
  store i32 %4, ptr %8, align 4    ; IR: restore cell b
  store i64 %5, ptr %10, align 8    ; IR: restore cell c
  ret void
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
