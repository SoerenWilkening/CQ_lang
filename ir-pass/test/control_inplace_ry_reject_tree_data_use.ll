; control_inplace_ry_reject_tree_data_use.ll — DECLINE: the tree ROOT is also read as data (`cq_measure(c)`).
;
; bd test_C_libtooling-dm7f.52 — the in-place controlled Ry / controlled state
; prep under a COMPOUND i1 condition. Before dm7f.52 every such region declined
; `control flow under quantum control` at `classifyArms`' first gate while the
; `cq_phi` twin lowered (docs/CQ_FINDINGS.md F2). The mechanism: the condition
; tree is minted into ONE flag by `CondTreeEmit::emitCondNetwork` (the branch
; phase's network), `cqrt_ry_<W>_controlled(flag, h, θ)` fires, and
; `stripCondNetwork` returns every ancilla to |0> (LIFO) before its free. The
; target must lie off every leaf wire (`classifyArms` R4 over the leaf-union
; `Prov`), which is what makes the strip exact. IR transcribed from clang -O1.
;
;   bool c = a & b; if (c) cq_theta(&t, .7); ... cq_measure(c)
;
; `condTreeShapeRefusal`: the root ancilla is stripped and freed inside the
; region, so a data reader would read a freed rail. A tree has no ziov
; share path (the branch phase's identical fence).
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 (the file keeps its
; name, L8). `c = a & b` is read past its control (`cq_measure(c)`), so the
; commit stage tags it a FRESH REGISTER CONDITION (RegCondLeaf.h): the controlled
; prep reads c's own out-of-place `and` rail, which the program keeps and
; measures. Nothing is minted, stripped or freed for it, so the decline's reason
; above ("a data reader would read a freed rail") has no subject: the stream is
; and(a,b) -> c; CRy(c -> t, .7); measure(c); measure(t) — the source circuit.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[C]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[C]])
; CHECK-NOT:   cqrt_free

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = and i1 %1, %2
  br i1 %3, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ false, %0 ]
  %8 = call i1 @cq_measure_i1(i1 %3)
  %9 = zext i1 %8 to i32
  %10 = call i1 @cq_measure_i1(i1 %7)
  %11 = select i1 %10, i32 4, i32 0
  %12 = or disjoint i32 %11, %9
  ret i32 %12
}

