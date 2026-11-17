; HAND-WRITTEN. Rules: 2 (a cq_theta of a loaded value that is not stored straight back), 3, 5 (Memory, sentences 1 and 3), 10 (frozen), 20; §1.3 (the bus, __cq_mem).
; Checked: the measured value = src (the second load copy %4, measured -> %5); the cell `dst` = the rotated copy of src
;          and the cell `src` = 3, unchanged (both read from the bus at exit).
; Clean: nothing. No rail of this function is uncomputed or freed: it mints two load copies and both stay.
; Kept: the first load copy of src (%3): rotated, so a FROZEN register (rules 2, 10: never un-copied), and the value rail
;       of the kept store dst = v (rule 5 sentence 3); that store's tape slot (in the backend, holding the displaced
;       `dst`); the second load copy of src (%4, measured: rule 2's measured rail).
; Rotations: (Ry, the load copy of src, th, 1).
; Expected for the driver theta_of_load_copy(.5) (analytic, not replayed): the return value is 3 with probability 1. The
;   cell src is never written, so it stays HOST and holds 3; the second load copies it and the measurement reads 3
;   whatever the rotation did. The cell dst: Ry(th) acts on every qubit of the i32 copy, so each of its 32 bits flips
;   independently with probability s = sin^2(.25) = 0.0612087: dst = 3 with probability (1 - s)^32 = 0.132498, each
;   single-bit neighbour of 3 with probability s (1 - s)^31 = 0.008639, P(v) = s^d (1 - s)^(32 - d) at Hamming distance d.
; THE ROTATION ACTS ON THE LOAD COPY (rule 2, the fallback). cq_theta(&v, th) on `int v = src` is, in the -O1 code,
; `load @src; cq_theta_si32; store @dst`: the result is stored through ANOTHER pointer, so this is not rule 5's in-place
; form (no qram_swap: the gate must not reach the cell src) and the Ry acts on the fresh rail the load made, as the C
; program says (v is a copy of src). From the rotation on, that rail is a frozen register: it is never un-copied
; (cqrt_qram_load_i32_hl_unc would need the rail to still hold the cell's value) and never freed. `dst = v` is an ordinary
; kept store of it at the classical address of dst: no _unc exists, its tape slot and its value rail stay for the shot.
; The cell dst is QUANTUM from here on (its content is not classical-valued); the cell src is untouched and stays HOST.
; THE SECOND LOAD. `cq_measure(src)` loads src again: in the -O1 code the opaque call cq_theta_si32 lies between the two
; loads and may write @src for all clang knows, so the first load is not forwarded (the store to @dst alone would not
; prevent it: clang knows the two globals are distinct). The lowering asks nothing of the kind: the IR has a second load,
; so it is a second bus load at the same classical address, a fresh copy of the cell, measured. It reads the cell, not
; the rotated copy. A measured load copy is never un-copied, although no memory version change follows it here: it is
; rule 2's measured rail and stays allocated (no _unc, no free).
; ONE BUS, CLASSICAL ADDRESSES (rule 20). src and dst are globals at their host addresses: nothing is allocated, seeded
; or registered for them; the address operand of the _hl forms is the pointer's run-time i64 (ptrtoint).
source_filename = "theta_of_load_copy.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@src = local_unnamed_addr global i32 3, align 4
@dst = local_unnamed_addr global i32 0, align 4

define i32 @theta_of_load_copy(double noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %3 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @src to i64))    ; IR: %2 = load i32, ptr @src: v = src  (a bus load at a classical address: a fresh copy of the cell)
  call void @cqrt_ry_i32(i32 %3, double %0)    ; IR: %3 = cq_theta_si32(%2, %0)  [Ry on the load copy, rule 2: the result is stored through another pointer, so no in-place form; the copy is FROZEN from here on, never un-copied]
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @dst to i64), i32 %3)    ; IR: store i32 %3, ptr @dst: dst = v  (an ordinary kept store: tape slot and value rail stay, no _unc)
  %4 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @src to i64))    ; IR: %4 = load i32, ptr @src: src, loaded again  (a second fresh copy; the cell src was never rotated)
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)  (the measured load copy stays allocated)
  ret i32 %5    ; IR: ret i32 %5
}

declare i32 @__cq_mem()
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
