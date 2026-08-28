; lowering_uncompute_tape_nonterminal_rail.ll — ACCEPT (Phase 5 + 7.6). THE
; NON-TERMINAL PRESERVING-SINK ORDERING fixture (bd test_C_libtooling-e4zs, and the
; tape half of bd test_C_libtooling-8gi5 item 3 — one root cause, two surfaces).
;
; THE DEFECT IT PINS. `FreePoint::computeFreePoint` is called PER TERMINAL and
; classifies `Terminal->users()`. A `cqrt_tape_write_<W>` is a SOURCE-PRESERVING
; sink — it READS its src register without consuming it — so when the src IS the
; terminal it lands in that scan's `Users` set and the reversal is correctly placed
; after it. When the src is an UPSTREAM rail it is in nobody's `users()` scan, never
; joins the post-dominator user set, and the insertion point can precede it. Here
; `%a` is exactly that: a rail whose forward lineage continues into `%b`, so `%b` is
; the terminal and `%a` is not.
;
; MEASURED before the fix: `cqrt_free(%h_op)` was emitted BEFORE
; `cqrt_tape_write_i32(%tape, %h_op)`. `opt` exited 0 and `opt -passes=verify` was
; clean — this defect is invisible to both. `free_pairing_check.py` DOES name it
; (`VIOLATION F2-use-after-free ... @cqrt_tape_write_i32 uses %h_op after its
; cqrt_free`), but stage 2b runs only in the e2e harness, so nothing in the lit
; layer caught it. Hence this fixture.
;
; THE FIX is in `DagTraversal` (every preserving sink on every recovered rail is
; recorded in `DataDag::PreservingSinks`) and `Uncomputation::reverseTerminalGroup`
; (those sinks join the `dagInsertPoint` anchor set). It is an ORDERING fix only: the
; same adjoints and the same frees are emitted, later.
;
; WHY NO SHIPPED SLICE HITS IT, stated precisely because the imprecise version is
; what let it sit: the 7.6 emitter declines to tape a value whose lineage continues
; (`tapedLineageClosed`, IOSinkLowering.cpp, `kMsgIOFanout`), so EMITTER-produced IR
; cannot build this shape. That is a fact about the emitter, not about the spine —
; and the pass accepts hand-written `cqrt_*` IR (every `cqrt_*` callee is carved out
; of `declineTaintEscapes`), so the shape is reachable today. The corpus is silent
; here (MEASURED: byte-identical across all 240 registered e2e slices and all lit
; fixtures), which is exactly why the pin has to be hand-written.
;
; %h_op is RECORDED onto a kept tape, so bd 261j(a)'s freeze is consulted — and
; correctly declines to freeze it: its only gate is a `cq_template_*` producer, a
; basis permutation of its live parent, so it reverses to |0> and DOES free (the
; 261j discrimination case). The freeze decides WHETHER to free; this fixture pins
; WHERE.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the first `+ 1` lowers IN
; PLACE, so the rail the tape write reads IS the root. The property under test is
; unchanged: that rail is still NON-TERMINAL (the terminal is the `+ 2` producer),
; so `computeFreePoint` — which scans only the TERMINAL's users — still cannot see
; the sink, and the anchor extension is still what keeps the reversal after the
; read. The root's own free stays suppressed by the record freeze.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @taped_upstream(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1                     ; the NON-terminal rail the tape reads
  %b = add i32 %a, 2                     ; lineage continues ⇒ %b is the terminal
  %tape = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %a)
  ret void
}

; Forward stream first — both rails are produced, then the tape records the UPSTREAM
; one:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 1)
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 2)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])
;
; ONLY THEN the whole-DAG reversal. This ORDER is the whole fixture: FileCheck
; directives match in sequence, so if the reversal moved back above the tape write
; the write would be consumed first and these lines could not match after it —
; which is precisely the pre-fix output.
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP1]], i32 %[[H]], i32 2)
; CHECK:     call void @cqrt_free(i32 %[[OP1]])
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 -1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
