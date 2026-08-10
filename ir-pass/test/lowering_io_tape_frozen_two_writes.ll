; lowering_io_tape_frozen_two_writes.ll — ACCEPT (Phase 7.6). The `tests/e2e/slice_io`
; shape expressed in IR, so the LIT layer pins the bd 261j(a) defect directly rather
; than depending on the e2e golden (which cannot witness "freed at |0>" at any ABI —
; a trace line records the symbol and its handles, never the rail's state).
;
; One theta root, TWO tape writes on the SAME rail (`printf("%d",x); putchar(x);`),
; then x is dead and unmeasured. The shipped pass emitted
;     cqrt_ry_i32(%H,-0.5) ; cqrt_free(%H)
; here, with `free_pairing_check.py` reporting `1 verified, 0 violations`. Only the
; `cqrt_free` is gone now; the ry adjoint stays. The adjoint pair cancels on paper,
; but the rail was READ in between by two
; CNOT-class copies onto tape entries the reversal NEVER touches, so %H is entangled
; at the free and `cqrt_free` (a hardware reset = projective measurement) is a hidden
; measurement (Rules 5/6/8).
;
; PINS, beyond the single-write case: that `Recorded` is a SET-MEMBERSHIP test and
; not a count. Two records freeze exactly as one does — and, per the ruling's
; algebra, arbitrarily many kept records are fine for a rail whose chain IS a basis
; permutation of live conditions, so the count genuinely carries no information.
;
; HONESTY BOUND (carry it, do not overstate this fixture): the observable damage is
; NIL. rho of the kept tape is the same with and without the free — the copy already
; mixed it and a local reset on %H cannot change the tape's reduced state
; (no-signalling). This is a violated hard invariant with a provably false written
; justification inside a freeze-gating ABI, NOT a wrong printed answer.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOFREE
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
declare i32 @putchar(i32)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  %c = call i32 @putchar(i32 %q)
  ret void
}

; Both writes land on the one rail; the rail is reverse-played and LEFT ALLOCATED:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NOFREE:     %[[TAPE2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; NOFREE-NOT: cqrt_free
