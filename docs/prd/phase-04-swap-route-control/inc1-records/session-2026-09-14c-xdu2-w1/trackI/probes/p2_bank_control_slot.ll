; p2 — bd 21re SUBJECT B: the bead's own example. A rail-BANK cell load is passed
; as the CONTROL of `cqrt_copy_i32_controlled`, and the underlying rail is
; flipped THROUGH ITS MINT NAME between the two halves of the pair. The two
; copies therefore do NOT cancel — the second acts on the opposite branch of the
; flag — so `%o` is left holding `%r`'s value, not |0>, and the `cqrt_free(%o)`
; is a hardware reset of a rail entangled with %hb (Rules 6/8).
;
; The checker's write history is keyed on the literal SSA operand string, so
; `%v`'s history is EMPTY and `unchanged_over("%v", ...)` answers "unchanged".
; This is the second, distinct wrong-discharge the falsified premise opens, and
; it does NOT go through `provably_not_a_rail` at all.
;
; HAND-BUILT BY CONSTRUCTION (see p1's header). L8 RETIREMENT TRIGGER: when
; L-1a's type rewrite lands, a real slice produces this shape; re-derive this
; fixture against it then; do NOT delete it.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %v = load i32, ptr %cell, align 4                     ; THE BANK LOAD = a rail
  %r = call i32 @cqrt_alloc_i32(i32 3)
  %o = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %v, i32 %r, i32 %o)
  call void @cqrt_x(i32 %hb)                            ; the control flips
  call void @cqrt_copy_i32_controlled(i32 %v, i32 %r, i32 %o)
  call void @cqrt_free(i32 %o)                          ; %o is NOT |0>
  %m = call i1 @cqrt_measure_i1(i32 %hb)
  %z = zext i1 %m to i32
  ret i32 %z
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)

!0 = !{!"i1"}
