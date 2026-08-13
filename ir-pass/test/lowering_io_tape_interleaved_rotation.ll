; lowering_io_tape_interleaved_rotation.ll — ACCEPT (Phase 7.6). THE REGRESSION PIN
; for the silent miscompile that the bd 261j(a) Rule-13 round found in the FIRST
; implementation of the record freeze. If you are about to make the freeze skip a
; frozen rail's adjoint, this fixture is the reason not to.
;
; THE SHAPE. A `cqrt_ry` on the frozen rail %H sits BETWEEN the surviving rail %OP's
; producer and the reversal point:
;     ry(%H,0.5) ; %OP = add(%H,1) ; ry(%H,0.25) ; tape(%OP)
; Six lines of ordinary C reach it, because a CHAINED `cq_theta` lowers to an
; in-place `ry` on the EXISTING handle (RotationLowering):
;     int x = cq_theta(seed,0.5); int y = x+1; int x2 = cq_theta(x,0.25);
;     printf("%d", y);
;
; THE DEFECT (MEASURED, three independent refuters failed to refute it, plus two
; more instances on the QRAM surface). The first implementation froze %H and skipped
; ALL its gates, including `ry(%H,0.25)`. %OP is NOT frozen — its only gate is the
; whitelisted producer — so `add_unc(%OP,%H,1)` and `cqrt_free(%OP)` were still
; emitted. But %OP was computed from %H BEFORE the 0.25 rotation, and the `_unc`
; recomputes %H+1 from %H AFTER it. The two differ, so %OP is left holding
; (p+1)^(p'+1) instead of |0>, entangled with %H and with the kept tape — and
; `cqrt_free` on it is exactly the hidden measurement (Rules 5/6/8) that this
; ticket exists to remove. Worse, that free was SOUND before bd 261j(a) touched it:
; the fix cured one hidden measurement by creating another.
;
; THE INVARIANT CLAUSE IT VIOLATES is (d): "every register in cond(W) still holds
; its forward value when W† fires". "Forward value" means the value it held WHEN THE
; FORWARD GATE RAN — not its value at the end of the stream. Reverse program order
; delivers (d) only while EVERY gate in between is adjointed.
;
; THE FIX, pinned below: the freeze suppresses the `cqrt_free`, never the adjoint.
; `ry(%H,-0.25)` is emitted, `add_unc` then reads %H at its producer-time value, %OP
; is genuinely |0>, and `cqrt_free(%OP)` is sound — while %H, the recorded rail,
; still gets no free. Stage 2b confirms the flip: `T2-operand-mutated UNPROVEN`
; (rc=1) before, `1 verified, 0 violations` (rc=0) after.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = add i32 %q, 1
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  %z  = call i32 (ptr, ...) @printf(ptr @.str, i32 %c)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; The INTERLEAVED rotation — the gate whose adjoint must not be skipped:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; THE LOAD-BEARING LINE: the interleaved rotation IS adjointed, and BEFORE the
; surviving child's `_unc`, so the `_unc` reads %H at its producer-time value:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; The recorded rail is still never freed — the 261j fix itself is intact:
; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: call void @cqrt_free(i32 %[[H2]])
