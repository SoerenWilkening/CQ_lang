; lowering_io_tape_partial_freeze_order.ll — ACCEPT (Phase 7.6). THE PARTIAL-FREEZE
; ORDERING fixture for bd 261j(a), on a three-rail chain with ALTERNATING freeze
; status:
;
;   %H    = theta root, carries `cqrt_ry`            -> Correlated, FROZEN
;   %OP   = %H + 1, a producer and nothing else      -> Correlated, NOT frozen
;   %OP1  = %OP + 2, carries `cqrt_ry`, and is TAPED -> Recorded,   FROZEN
;
; THE CLAIM: a frozen rail keeps its adjoint and loses only its `cqrt_free`, so a
; surviving neighbour's `_unc` still reads every operand at its PRODUCER-TIME value
; and still returns its own rail to |0>.
;
; THE MEASUREMENT: the full reverse-play is emitted — `ry(%OP1,-0.25)`,
; `add_unc(%OP1,%OP,2)`, `add_unc(%OP,%H,1)`, `ry(%H,-0.5)` — and exactly ONE
; `cqrt_free`, on %OP. %OP is genuinely |0> at that point: its `_unc` XORs %H+1 into
; a register holding %H+1, and %H is still forward because its own adjoint comes
; LATER in reverse program order. %OP is then PRODUCT with everything else, which is
; why freeing it is legal even though %OP1 — derived FROM %OP — is left allocated
; and entangled with the tape. Stage 2b agrees: `1 cqrt_free site: 1 verified`,
; strict.
;
; NOTE THE TWO ASYMMETRIES, both real and both easy to get backwards:
;  * Correlation propagates BACKWARD (the record reads a descendant's label, which
;    is a function of the ancestor's) — hence %H freezes.
;  * A descendant's dirtiness does NOT propagate FORWARD onto its parent's
;    freeability — hence %OP still frees despite %OP1 being dirty.
;
; AND THE HISTORY, because this fixture is why the design changed. Its first version
; asserted that a frozen rail gets NO adjoint, on the reasoning "frozen, hence never
; adjointed, hence still at its forward values". That reasoning conflates a
; register's FINAL forward value with its PRODUCER-TIME value, and the Rule-13 round
; measured four separate hidden measurements from it (see
; lowering_io_tape_interleaved_rotation.ll). The fixture also had three of its five
; CHECK-NOTs outside their scan window, so it could not have caught its own defect —
; and the FIRST repair, which moved them into one shared NOFREE prefix, reproduced
; the same bug with two anchors in that prefix. See the note above the guards below.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP1 < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %p  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = add i32 %p, 1
  %f0 = add i32 %r, 2
  %f  = call i32 @cq_theta_si32(i32 %f0, double 2.500000e-01)
  %z  = call i32 (ptr, ...) @printf(ptr @.str, i32 %f)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OP]], i32 2)
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP1]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP1]])
; The whole chain reverses, in reverse program order:
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP1]], double -2.500000e-01)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP1]], i32 %[[OP]], i32 2)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; The sandwiched rail is the ONLY one freed, and its free lands right after its own
; `_unc` — which read the still-forward frozen %H:
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NEITHER frozen neighbour is freed. ONE PREFIX PER GUARDED HANDLE, each with a
; SINGLE positive anchor so its CHECK-NOT window runs anchor->EOF. This is the
; third spelling of this block and the reason is worth writing down: a CHECK-NOT is
; bounded by the NEXT positive directive of the same prefix, so stacking two
; anchor+NOT pairs in one prefix silently kills the first NOT. Both earlier
; versions of this fixture shipped exactly that bug, the second time while claiming
; in its own header to have fixed it. If you add a handle here, add a PREFIX.
; NOFREEH:        %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREEH-NOT:    call void @cqrt_free(i32 %[[H2]])
; NOFREEOP1:      %[[OP12:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; NOFREEOP1-NOT:  call void @cqrt_free(i32 %[[OP12]])
