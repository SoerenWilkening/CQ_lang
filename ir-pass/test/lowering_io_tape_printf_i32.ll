; lowering_io_tape_printf_i32.ll — ACCEPT (Phase 7.6): a tainted `printf("%d", x)`
; lowers COHERENTLY to the reversible output tape. `x = cq_theta` -> printf, then
; x is dead. The tainted i32 arg is APPENDED (one lazy `cqrt_tape_alloc` + a
; `cqrt_tape_write_i32`) as a KEPT |0> output rail. NO measurement is inserted
; (Rule 5), no `@printf` call survives, and the output rail is never freed/reversed.
;
; THE SOURCE RAIL IS REVERSE-PLAYED BUT NEVER FREED (bd 261j(a), owner ruling
; 2026-08-10). This fixture asserted a `cqrt_free(%H)` until that ruling. The tape
; write is a CNOT-class copy onto a rail the reversal NEVER touches, so %H stays
; ENTANGLED with the kept tape. %H's forward chain is `cqrt_ry_i32(%H, 0.5)`, whose
; only other operand is a CLASSICAL angle (Rule 3) — cond(W) is EMPTY, so the chain
; is not a basis permutation of anything still live and `Ry†` does not return %H to
; |0>. `cqrt_free` is a hardware reset = a projective measurement, so the old free
; was a hidden measurement of an entangled rail (Rules 5/6/8). Leaving %H allocated
; is Rule 6's stated fallback (a qubit leak in the qubits-not-scarce regime), NOT a
; decline: `opt` still exits 0 and emits no diagnostic.
;
; THE `cqrt_ry_i32(%H, -0.5)` ADJOINT IS STILL EMITTED, and that is deliberate, not
; an oversight. The freeze suppresses the FREE, never the reversal. Suppressing the
; adjoint too (the first implementation of this ruling) is itself a silent
; miscompile: a surviving non-frozen rail's `_unc` reads the frozen rail and needs
; it at its PRODUCER-TIME value, which only the full reverse-play restores. See
; lowering_io_tape_interleaved_rotation.ll, which is that defect's regression pin.
; Applying a unitary adjoint to a rail we then leak is harmless and, on the kept
; carrier, not even observable.
;
; This shape is INVISIBLE to both shipped gates — `opt -verify` is clean either way
; and `free_pairing_check.py` certified the old free via A2-reduces-to-identity — so
; the NOFREE block below is the only regression protection until bd 261j(b).
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
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  ret void
}

; One lazy stdout tape; the tainted i32 arg appended to it; the source rail
; reverse-played AFTER the write; no measurement, no surviving printf call:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[H]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; The freeze itself. A CHECK-NOT only scans between its neighbouring positive
; CHECKs, so the negative lives in its OWN prefix anchored at the alloc — the
; window is then the whole remaining module and cannot go dead if the CHECK block
; above is later reordered (that window bug shipped once in this family already).
; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: cqrt_free
