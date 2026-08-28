; lowering_reject_live_record_anc_router_phi.ll — DECLINE: the gate reaches its
; wire through a one-register ROUTER PHI (the bd tayx spelling) and the dead
; record is an ANCESTOR of that wire (M-A Increment 3, bd
; test_C_libtooling-6uqc).
;
; The ancestor twin of lowering_reject_live_record_router_phi.ll: same router
; construction, but the record sits UPSTREAM of the wire instead of downstream.
;
; SOURCE SHAPE:
;     a = cq_theta(a, 0.5);      // mints %h
;     int d = a * 3;             // out-of-place: THE WIRE; %h stays live
;     if (c) d = cq_phi(d, .25); // CLASSICAL condition, diagonal arm
;     d = cq_theta(d, 0.125);    // T — chained Ry reached through the merge phi
;     return cq_measure(d);
;
; WHAT IS STANDING AT THE GATE: `%h`, the `cqrt_alloc_i32`-minted parent of the
; mul rail, never read again, never uncomputed, never freed.
;
; WHY THE PHI IS NOT ITSELF THE PROBLEM, and why that matters here.
; `declineClassicalMuxes`'s one-register merge-phi LIFT (test_C_libtooling-5j5)
; runs at run-line 381, ~90 lines before `lowerRotations`, and proves `%p` a pure
; SSA renaming of the mul rail — so at this LATE slot the recorded `cqrt_ry`'s
; arg-0 already IS the rail and the ancestor walk starts from it with no alias
; closure of any kind. bd tayx measured that a router phi hides a chained theta
; from the position-free wire walks on three separate paths; the ancestor half
; must not be evadable the same way, and it is not — structurally, not by a
; special case. (The guard nonetheless walks phi/select incomings backward, for
; the shapes the lift declines to collapse.)
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0, ONE `cqrt_alloc_i32`, the phi gone
; — the over-accept this closes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul i32 %q, 3                                           ; the WIRE; %h = DEAD ancestor
  br i1 %c, label %arm, label %merge                           ; CLASSICAL condition

arm:
  %dz = call i32 @cq_phi_si32(i32 %d, double 2.500000e-01)     ; diagonal, in place
  br label %merge

merge:
  %p  = phi i32 [ %dz, %arm ], [ %d, %entry ]                  ; the one-register router
  %q2 = call i32 @cq_theta_si32(i32 %p, double 1.250000e-01)   ; T — chained Ry THROUGH the phi
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m2
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
