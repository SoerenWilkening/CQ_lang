; lowering_reject_stale_reader_inloop_invariant_seed.ll — DECLINE.
;
; THE Rule-13 ROUND-1 FINDING (bd test_C_libtooling-3d8q, F-D1-1), pinned. A loop
; body holding EXACTLY ONE `cq_theta` on a loop-INVARIANT quantum name. It
; COMPILED on the binary this fixture was written against (`7fe2bcbf…`, `opt`
; exit 0, verify-clean, stage-2b `0 violation(s)`) and emitted a stream
; BYTE-IDENTICAL to the SELF-ASSIGNED chain — a DIFFERENT, well-formed program —
; which is bd 3d8q's own definition of the defect, surviving the fence built to
; close it.
;
;   int q = cq_theta(0, 0.3);
;   for (int i = 0; i < 3; i++) { int b = cq_theta(q, 0.1); s += cq_measure(b); }
;
; At trip 2 the name `q` denotes `Ry(.3)|0>` while the register holds
; `Ry(.4)|0>`; at trip 3, `Ry(.5)|0>`. Three states of one register named by one
; consumed name — CLAUDE.md CORRECTNESS RISK §2's rail-staleness rule verbatim:
; *"a rail member may be read only where no rail-relabelling gate (Ry …) executes
; between the record's definition and the read WITHOUT that definition
; re-executing."* The trip-1 gate executes between `%q`'s definition and the
; trip-2 read, and `%q` never re-executes.
;
; ⚠ THE STALING GATE IS THE READER'S OWN PREVIOUS DYNAMIC INSTANCE, which is why
; this survived: `recordStaleQuantumReaders` grants the reader the `Covered`
; self-exemption (`c = cq_theta(a,θ)` is an in-place Ry on the rail it reads, so
; without it every well-formed chain would decline against itself), `Covered` is
; tested INSIDE the walker BEFORE the harmlessness proof, and the exemption was
; UNCONDITIONAL. The fix asks `gateIsHarmless` about the self-gate — the same
; relation, the same arguments the walker would pass — before granting it.
;
; ⚠ THE ONE-OPERAND TWIN IS `lowering_stale_reader_postloop_measure_accept.ll`
; and that fixture's own header already contained the sentence that condemns this
; module: *"the header φ that IS the barrier has been replaced by the
; loop-INVARIANT preheader mint and this module declines."* Here `%q` IS that
; preheader mint: replace `%q` by a header φ carrying `%b` and the module becomes
; the ACCEPT `lowering_stale_reader_inloop_selfassign_accept.ll`. The two files
; differ by that one edge and pin the two dispositions of one shape; NEITHER was
; pinned before this fixture existed, which is how F-D1-1 shipped.
;
; RETIREMENT TRIGGER: this becomes an over-decline the day the pass can prove a
; loop body executes at most once (then the invariant seed is read exactly once
; and nothing is stale). Re-derive it then; do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; ⚠ Rule 12 fixture-hygiene (b): a `DS_Error` decline writes 0 bytes to stdout,
; so the property is pinned by the `not` inversion on the RUN line plus the
; CHECK on stderr — never by an IR-text `CHECK-NOT`, which would be vacuous.

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  br label %body
body:
  %b     = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m     = call i32 @cq_measure_si32(i32 %b)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %m
}

; CHECK: cq opcode lowering: rotation/measure operand predates a non-diagonal gate
