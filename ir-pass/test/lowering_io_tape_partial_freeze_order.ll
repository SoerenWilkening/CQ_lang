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
; `mul_unc(%OP1,%OP,5)`, `mul_unc(%OP,%H,3)`, `ry(%H,-0.5)` — and among the three
; CHAIN rails exactly ONE `cqrt_free`, on %OP. %OP is genuinely |0> at that point:
; its `_unc` XORs 3H into a register holding 3H, and %H is still forward because its
; own adjoint comes LATER in reverse program order. %OP is then PRODUCT with
; everything else, which is why freeing it is legal even though %OP1 — derived FROM
; %OP — is left allocated and entangled with the tape.
;
; ── THE `%A` AND `%B` LINES ARE NOT DECORATION (M-A Increment 3, bd
; test_C_libtooling-6uqc). READ THIS BEFORE DELETING THEM. ─────────────────────
; They are template READS of %H and %OP emitted AFTER the gate whose results are
; taped, i.e. OBSERVING data uses of both ancestors after `T`. Without them this
; module DECLINES with
;     cq rotation lowering: non-diagonal gate over a live derived record
; and CORRECTLY so: with the chained `Ry` on the chain TIP, %H (|a>) and %OP (|3a>)
; are live, undischarged basis records of %OP1 (|15a>) at the instant the gate
; fires, so %OP1's reduced state is diagonal and the rotation acts on a mixture.
; Census 0.1 forecast this exact module (SPIKE §2R.5, spine-aware column) and the
; owner ruled that reading in (§2R.5a, 2026-08-27) — the spine's post-`T` `_unc`
; reads and adjoint `Ry` are the compiler undoing ITSELF, not the user reading data.
; With %A and %B present, both ancestors are the program's OWN live data (clause 3)
; and the accept is by principle, exactly as in
; lowering_stale_record_add_before_theta.ll. THE THREE-RAIL VERDICTS AND THE
; REVERSAL ORDER ARE BYTE-FOR-BYTE WHAT THEY WERE (measured): %H frozen, %OP freed
; right after its own `_unc`, %OP1 frozen. %A and %B carry no rotation, so they
; reverse and free too — which is the same freeze-keys-on-gates contrast
; lowering_io_tape_derived_uncompute.ll pins. The negative form of this hazard is
; lowering_reject_live_record_io_tape_chained_theta.ll (the canonical §2R.5 case).
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
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The two derived rails are built with `mul`, not `add`. Since M-C a dead-parent
; `q + c` lowers to the VOID in-place `cqrt_addc_<W>`, which mints NO rail — with
; `add` this program would collapse to ONE rail and a PARTIAL freeze would have
; nothing to be partial about. `mul` is information-losing and so is outside the
; dtzb in-place bijection family at every batch. The three-rail structure, the
; per-rail verdicts (h frozen, op FREED, op1 frozen) and the reversal ORDER are
; all byte-for-byte what they were.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP1 < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [9 x i8] c"%d %d %d\00"

define void @slice(i32 %u0) {
entry:
  %p  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = mul i32 %p, 3
  %f0 = mul i32 %r, 5
  %f  = call i32 @cq_theta_si32(i32 %f0, double 2.500000e-01)
  %a  = mul i32 %p, 7                                          ; %H read AFTER the gate
  %b  = mul i32 %r, 11                                         ; %OP read AFTER the gate
  %z  = call i32 (ptr, ...) @printf(ptr @.str, i32 %f, i32 %a, i32 %b)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OP]], i32 5)
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP1]], double 2.500000e-01)
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[OP]], i32 11)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP1]])
; The two un-rotated liveness reads reverse and free first (reverse program order):
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %[[OP]], i32 11)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; Then the chain itself reverses, in reverse program order:
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP1]], double -2.500000e-01)
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP1]], i32 %[[OP]], i32 5)
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 3)
; The sandwiched rail is the only CHAIN rail freed, and its free lands right after
; its own `_unc` — which read the still-forward frozen %H:
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
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
; NOFREEOP1:      %[[OP12:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; NOFREEOP1-NOT:  call void @cqrt_free(i32 %[[OP12]])
