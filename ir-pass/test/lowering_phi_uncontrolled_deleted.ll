; lowering_phi_uncontrolled_deleted.ll — ACCEPT. P7: an UNCONTROLLED or
; CLASSICALLY-CONTROLLED `cq_phi` is a GLOBAL PHASE and is DELETED (PRD §6.2 row
; P7, owner decision D2). A documented semantic, NOT a diagnostic — owner question
; Q2's assumed answer is "no remark".
;
; `cq_phi(θ)` means "multiply the amplitude of the CURRENT BRANCH by e^{iθ}". With
; no tainted condition above it there is only one branch — the whole state — so
; the operation is a global phase: unobservable, and therefore removable.
;
; BOTH SPELLINGS ARE HERE and both must go: the straight-line call, and one under
; a CLASSICAL (`volatile int`) branch, which is equally a global phase because the
; classical condition has a definite value on any run.
;
; POSITION IS THE SOUNDNESS ARGUMENT (`deleteGlobalPhases` runs immediately after
; `lowerControlRegions`): by then `detectControlRegions` has CLAIMED every tainted
; `br`/`switch` — and its emitter erased the phase call it claimed — or DECLINED
; it loudly, Rule 1's "there is no third path". A SURVIVOR therefore sits under
; classical control only, and that is ASSERTED rather than assumed: a survivor
; reachable through a tainted branch condition declines `unclaimed branch phase
; under quantum control` instead of vanishing (PRD §10.3 lens 4).
;
; The module must also leave NO `@cq_phi` declaration behind — an unresolved
; extern is a Stage-3 LINK error, which is why `PhaseCalls` is in the pass's
; passthrough early-out predicate.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C1 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=C2 < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

@cc = external global i32

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  call void @cq_phi(double 4.000000e-01)
  %cv = load volatile i32, ptr @cc, align 4
  %c = icmp eq i32 %cv, 0
  br i1 %c, label %merge, label %arm
arm:
  call void @cq_phi(double 6.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The Ry that made `q` quantum is untouched; nothing else is emitted for the two
; deleted phases — no gate, no flag, no ancilla.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so every count lives in its own GCNT prefix and NOROUTE carries no positives).
;
; The four things a register-free kickback must NEVER emit:
;   * a route of any kind — the whole point is that no work rail exists;
;   * a `_controlled` gate — the gate is UNCONTROLLED, on the flag ancilla;
;   * `cqrt_rz_<W>` for W != i1 — the TENSORED per-register Rz is the defect
;     this increment removes (PRD §1: it marks `(-1)^popcount(target)` and can
;     never mark |0..0>, which made every Grover golden the identity on q);
;   * a surviving `@cq_phi` CALL — it is lowered here or deleted (D2), never
;     left for the linker.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: cqrt_rz_i8
; NOROUTE-NOT: cqrt_rz_i16
; NOROUTE-NOT: cqrt_rz_i32
; NOROUTE-NOT: cqrt_rz_i64
; NOROUTE-NOT: cqrt_rz_f32
; NOROUTE-NOT: cqrt_rz_f64
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: cqrt_free

; ---------------------------------------------------------------------------
; GATE COUNTS — one prefix per pattern (see the NOROUTE note above).
; C1-COUNT-1: call i32 @cqrt_alloc_i32(
; C1-NOT:     call i32 @cqrt_alloc_i32(
; C2-COUNT-1: call void @cqrt_ry_i32(
; C2-NOT:     call void @cqrt_ry_i32(
