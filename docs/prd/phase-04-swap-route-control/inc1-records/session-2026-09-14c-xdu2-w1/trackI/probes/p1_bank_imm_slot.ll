; p1 — bd 21re SUBJECT A: a rail arriving through a rail-BANK cell lands in a
; slot the ABI only ASSERTS is classical. This is the bd `az1h` defect verbatim,
; resurrected through the door `free_pairing_check.py:1292` reasons is shut:
;   "A handle cannot reach a global and come back - a tainted `store` is a loud
;    decline at `declineTaintEscapes` long before lowering - so a load result is
;    not a rail."
; bd `xdu2` (L-1a) exists precisely to remove that decline.
;
; HAND-BUILT BY CONSTRUCTION, and it has to be: Track A ships the CLASSIFIER
; this session while the taint rule and the `[N x i1]` -> `[N x i32]` type
; rewrite are deliberately DEFERRED, so no compiler in the tree can emit a
; `!cq.railbank` load today (BRIEF_A §0).
;
; L8 RETIREMENT TRIGGER: when L-1a's type rewrite lands, a real slice produces
; this shape; re-derive this fixture against it then; do NOT delete it.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %hb, double 5.000000e-01)   ; superposed rail
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4                     ; the bank store
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %cell, align 4                     ; THE BANK LOAD = a rail
  call void @cqrt_xorc_i32(i32 %r, i32 %v)              ; entangles %r with %hb
  call void @cqrt_free(i32 %r)                          ; hidden measurement
  %m = call i1 @cqrt_measure_i1(i32 %hb)
  %z = zext i1 %m to i32
  ret i32 %z
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)

!0 = !{!"i1"}
