; lowering_io_tape_derived_uncompute.ll — ACCEPT (Phase 7.6). THE DISCRIMINATION
; FIXTURE for the bd 261j(a) record freeze: `putchar(x + 1)` on a tainted x, then
; dead. The DERIVED value `x+1` (a `cq_template_add` producer) is taped, and the two
; rails in the DAG get OPPOSITE treatment — which is the entire behavioural
; difference between the shipped per-rail freeze and the blunt DAG-global rule that
; was rejected.
;
;   %OP = x+1  — reversed (`_unc`) and FREED. Its forward chain is
;                `cq_template_add_i32_hl(%H, 1)`: a basis permutation conditioned on
;                the LIVE parent %H, so `add_unc(%OP, %H, 1)` genuinely returns %OP
;                to |0> even though the tape holds a copy of its label. Freeing it
;                is Rule-6-legal.
;   %H  = x    — reversed but NOT FREED: LEFT ALLOCATED. It is an ANCESTOR of the
;                recorded rail (the backward closure reaches it: the tape read
;                %OP's label, which is a function of %H's), and its own chain
;                `cqrt_ry_i32(%H, 0.5)` has an EMPTY condition set (the angle is
;                classical, Rule 3), so `Ry†` does not return it to |0>. Freeing it
;                would be a hidden measurement (Rules 5/6/8).
;
; So a tape write recognized as a sink does NOT mean "the source lineage uncomputes
; normally" — that was the false rationale bd 261j(a) overturned (PRD-7.6 §2.4,
; narrowed). It means the closure scan does not bail; FREEABILITY is decided per
; rail afterwards. `opt` still exits 0 and emits no diagnostic: a freeze is a Rule-6
; safe leak, not a decline.
;
; NOTE WHAT IS *NOT* DISCRIMINATED: both rails are still fully REVERSE-PLAYED. The
; freeze subtracts `cqrt_free`, never an adjoint — and %H's surviving
; `cqrt_ry_i32(%H, -0.5)` is not incidental, it is what a sibling rail's `_unc`
; would need if one existed (see lowering_io_tape_interleaved_rotation.ll).
;
; KILLED BY: the blunt `D.NotClosed = true` at the DagTraversal output-sink site
; (drops all four emitted lines, losing the SOUND free of %OP); by mirroring the
; freeze into `ChainWalk::isTerminalHandle` (empties Terminals — same loss); and by
; writing `preservesBasisUnderRecord` as {rz, qram_store} with producers closed
; (railOf returns the gate ITSELF for a producer, so %OP would freeze too).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @putchar(i32)

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = add i32 %q, 1
  %r = call i32 @putchar(i32 %s)
  ret void
}

; The derived add is taped; the DERIVED rail then reverses AND frees, while the
; recorded-Ry ancestor reverses but is left allocated:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; THE discrimination, in a whole-module window: the ancestor is never freed while
; the derived rail is. Own prefix so the negative cannot go dead (see
; lowering_io_tape_printf_i32.ll for why).
; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: call void @cqrt_free(i32 %[[H2]])
