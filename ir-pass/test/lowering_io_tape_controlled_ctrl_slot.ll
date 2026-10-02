; lowering_io_tape_controlled_ctrl_slot.ll — ACCEPT (Phase 7.6). THE SLOT-BLINDNESS
; fixture for the bd 261j(a) record freeze.
;
; `cqrt_tape_write_<W>_controlled(ctrl, tape, src)` (runtime/cq_runtime.h:438-442)
; records BOTH of its quantum operands: the src's label goes into the entry's
; CONTENT, and the ctrl's label goes into the entry's EXISTENCE pattern. Either
; correlates its rail with a carrier the reversal never touches, so
; `recordsIntoKeptCarrier` scans EVERY argument rather than a fixed slot.
;
; Note the argument order, which is why a slot-indexed test is a trap: the
; UNCONTROLLED form is `(tape, src)` with src at arg 1, but the controlled form puts
; ctrl at arg 0, the tape TOKEN at arg 1 and src at arg 2. Writing the record test as
; "src is arg 1" would therefore both MISS the controlled form's src AND mis-read the
; classical tape token as a recorded rail. An under-freeze is the over-accept class
; (Rules 6/8) — hence blind, and hence this fixture.
;
; HAND-WRITTEN PROBE, deliberately. No emitter mints this shape today: the 7.6
; controlled-I/O emitter always uses its OWN compare flag as the ctrl and frees that
; flag itself (IOSinkLowering, the `cqrt_x`-bracketed strip), so the ctrl slot never
; carries a spine-owned rail in shipped output. The predicate must still be right
; before it does — the pass accepts hand-written `cqrt_*` IR (every `cqrt_*` callee
; is carved out of `declineTaintEscapes`), so the shape is reachable and must be
; pinned rather than left to a future emitter to discover.
;
; PER-RAIL PROOF IN ONE MODULE: %H is used ONLY as the ctrl and freezes (reversed,
; never freed); the independent, unrecorded rail %P in the same DAG still reverses
; AND frees. A module-global or "any tape write in the function" rule would drop
; %P's free.
;
; BOTH ROOTS ARE SEEDED WITH THE LITERAL 0, and that is load-bearing (bd 5c5b,
; libcqops vmz9). A runtime seed is not provably |0⟩ at birth, so `BirthFreeze`
; would keep %P (no free to discriminate) and would keep %H for a reason that is
; not the record — masking the slot-blindness this file exists to pin. With zero
; seeds the record freeze is the ONLY reason %H stays allocated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

define void @slice(i32 %u0, i32 %u1, i32 %plain) {
entry:
  %ctrl = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %tape = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32_controlled(i32 %ctrl, i32 %tape, i32 %plain)
  ret void
}

; The ctrl rail %H is recorded and frozen (reversed, never freed); the unrecorded
; sibling %P reverses AND frees:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %plain)
; CHECK:     call void @cqrt_ry_i32(i32 %[[P]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[P]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; The ctrl-slot rail is never freed, anywhere in the module:
; Anchored on the tape write's CTRL slot: both roots now mint `cqrt_alloc_i32(i32 0)`,
; and one anchor per prefix keeps `tools/fixture_guard_liveness.py` able to check it.
; NOFREE:     call i32 @cqrt_tape_write_i32_controlled(i32 %[[H2:[a-zA-Z0-9_.]+]],
; NOFREE-NOT: call void @cqrt_free(i32 %[[H2]])
