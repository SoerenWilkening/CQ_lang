; lowering_volatile_scalar_deadstore_vector_untouched.ll — ARM PIN (bd k710) for
; the `isFloatingPointTy() || isIntegerTy()` clause: a dead volatile VECTOR slot
; must be left BYTE-UNTOUCHED. The alloca and its volatile store survive lowering.
;
; The store here is CLASSICAL, and that is the whole trick. A *tainted* vector
; cannot arm this clause: every way to build one from a tainted scalar
; (`insertelement`, `insertvalue`, `shufflevector`) is itself an unsupported
; instruction, so the module dies on `kMsgOther` BEFORE the store is ever
; considered — measured, and it is why the first draft of this fixture was thrown
; away (it was a `not %cq-opt` decline fixture that stayed RED with the clause
; removed, i.e. it pinned nothing). With a classical value there is no upstream
; decline, the module lowers, and the only observable difference between "clause
; present" and "clause removed" is whether these two lines still exist. That
; difference is what the ARM-KILL measures.
;
; WHY THE CLAUSE IS THERE: "scalar" is what makes the whole-alloca user scan a
; COMPLETE account of the slot. On a vector or an aggregate a store may write only
; PART of the object, so "one store, zero loads" stops meaning "nothing observable
; happens here". CQ's own history is the argument — the f64/angle miscompile family
; came from exactly this axis (scalar-only `isFloatingPointTy()` missing
; `<2 x double>`), so a scalar assumption silently applied to a vector is a
; recorded failure mode here, not a hypothetical.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @probe(float %u0, <2 x float> %vin) {
entry:
  %u = alloca <2 x float>, align 8
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  store volatile <2 x float> %vin, ptr %u, align 8   ; CLASSICAL, dead, volatile
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; In source order: the slot survives, the rotation lowers around it, the store
; survives. BOTH untouched lines must be present — drop the type clause and the
; stage erases them, which is exactly the mutation this fixture pins.
; CHECK-LABEL: define float @probe
; CHECK:      alloca <2 x float>
; CHECK-NEXT: call i32 @cqrt_alloc_f32(float %u0)
; CHECK-NEXT: call void @cqrt_ry_f32(
; CHECK-NEXT: store volatile <2 x float> %vin
; CHECK-NEXT: call float @cqrt_measure_f32(
