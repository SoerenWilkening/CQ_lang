; control_inplace_ry_clone_base_frozen.ll — ACCEPT, and the ONE fixture whose
; rotated base is a PHASE-6 SPECIALIZATION-CLONE RESULT (`@__cq_q_<callee>_<mask>`).
;
;     static int helper(int x) { return x * 3; }      // noinline
;     int q = …, p = …; cq_theta(&q, …); cq_theta(&p, …);
;     int r = helper(p);                 // the clone result IS the rotated base
;     if (q == 5) cq_theta(&r, .9);   // the accepted in-place Ry arm
;     int s = r + 1; cq_theta(&s, .125); // a post-region chain, so the spine has work
;     return cq_measure(q);
;
; WHY THIS SHAPE (bd test_C_libtooling-drbq round-2 Rule-13 review, lens A §1).
; The control-in-place FREEZE (`ChainWalk::railCarriesControlledRotation`) is what
; stops the whole-DAG spine emitting `cqrt_ry_<W>_controlled(f, h, -θ)` against a
; flag the region already `cqrt_free`d — finding A's use-after-free plus a dirty
; free of a condition-entangled register. Inc 1 shipped that freeze asked ONLY
; over `DataDag::Rails` (roots ∪ template producers), while the thing it must
; suppress — `emitDagReversal`'s `emitInverseCall` — iterates `DataDag::Calls`,
; and THOSE TWO SETS ARE DOCUMENTED IN-SOURCE TO BE UNEQUAL (see the
; `emitDagReversal` header, which closes the `cqrt_free` half of the same gap
; with an explicit `D.Rails` intersection, bd uow0).
;
; A `@__cq_q_*` clone result is exactly a member of the difference:
; `isTemplateProducer` admits `cq_template_*` and `cqrt_qram_load_*` and nothing
; else, so a clone result is never a RAIL — yet a `cqrt_ry_<W>_controlled` on it
; IS in `D.Calls`, and Inc 0 made that gate `isInverseEmittable`. So the ADJOINT
; half of the uow0 gap acquired a customer this increment. The fix asks the
; freeze in `recoverDataDag`'s STEP-1 WALK, of every walked handle, so it no
; longer depends on `isTemplateProducer`'s membership list.
;
; ⚠ HONEST LABEL — WHAT THIS FIXTURE DOES AND DOES NOT PIN. It pins the ACCEPT
; and the absence of any caller-side reversal. It does NOT distinguish the fix:
; the emitted stream is byte-identical with and without the step-1 query,
; because the caller's spine already refuses this DAG for an independent reason
; — the clone call is an unrecognized forward consumer of `%h1` (the rail it is
; passed), which the step-3 closure scan reads as `NotClosed`. Measured on three
; C reproducers in the round-2 review, including the UNCONTROLLED and
; NO-ROTATION twins, which leak identically. So the freeze query on this shape is
; pinned by a CODE READ, not by a stream, and this header says so rather than
; implying a fence the CHECKs cannot see. It becomes a real fence the moment
; caller-side reversal of a clone-call chain is enabled; until then it is a
; structural belt-and-braces second route to the same Rule-6-safe outcome.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The CHECK-NOTs run as their OWN prefix so FileCheck scans the WHOLE file, not
; only the tail after the last positive CHECK (the L6 finding-1 lesson).
; RUN: %filecheck %s --check-prefix=NOREV < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT   < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %r = call fastcc i32 @helper(i32 %p)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %s  = add i32 %rm, 1
  %d  = call i32 @cq_theta_si32(i32 %s, double 1.250000e-01)
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

define internal fastcc i32 @helper(i32 %0) unnamed_addr {
  %2 = mul i32 %0, 3
  ret i32 %2
}

; The forward stream: the clone is called on `p`'s rail, the flag is minted at the
; compare, the controlled Ry fires ON THE CLONE RESULT, the flag is stripped and
; freed, and the post-region chain still lowers in place (M-C) — the freeze is
; about the REVERSAL, not the forward program.
; CHECK:      %[[CR:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_helper_1(i32 %h1)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[CR]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[CR]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[CR]], double 1.250000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %h)

; NOTHING in the CALLER reverses: no negated-angle controlled-rotation adjoint
; (the use-after-free of the freed flag), no negated addc, no negated Ry, and no
; free of the clone result or of either source rail. (The clone BODY keeps its
; own internal `mul` reversal — that rail is closed and freed inside the clone,
; which is correct and is why the frees below are named individually rather than
; counted to zero.)
; NOREV-NOT: double -9.000000e-01
; NOREV-NOT: double -1.250000e-01
; NOREV-NOT: double -2.500000e-01
; NOREV-NOT: double -5.000000e-01
; NOREV-NOT: cqrt_addc_i32(i32 %r, i32 -1)
; NOREV-NOT: cqrt_free(i32 %r)
; NOREV-NOT: cqrt_free(i32 %h)
; NOREV-NOT: cqrt_free(i32 %h1)

; EXACTLY two frees in the whole module: the caller's flag, and the clone body's
; own internal `mul` rail.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
