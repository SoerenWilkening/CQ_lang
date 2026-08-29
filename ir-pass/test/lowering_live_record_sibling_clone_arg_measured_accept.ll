; lowering_live_record_sibling_clone_arg_measured_accept.ll — ACCEPT: the
; observing sink is reached THROUGH a Phase-6 specialized clone call (M-A, bd
; test_C_libtooling-6uqc; the F1 ruling, 2026-08-28).
;
; SOURCE:
;     __attribute__((noinline)) static int inner(int x){ return x * 3; }
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // a SIBLING of the wire
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     int z  = inner(c);                 // the sibling's post-gate fate
;     int mz = cq_measure(z);            // ...and it IS observed
;     return cq_measure(w) + mz + cq_measure(a);
;
; WHY IT LOWERS. `%h_op1` (`c`) is undischarged and entangled at the gate, and its
; only post-gate use is the call `@__cq_q_inner_1(%h_op1)`. A clone call is a
; value-preserving HOP in the observing-sink walk exactly as it is in the clause-1
; record walk (the Increment-1 F1 severance fix): putting an expression behind a
; `noinline static` must not change the verdict. The walk crosses it, reaches
; `cqrt_measure_i32` on the clone's returned `cqq.out` rail, and exempts `c`.
;
; DISCRIMINATION: drop `mz` (leave the call's result unobserved) and this module
; DECLINES — the clone is a hop, never a sink, so a call whose answer nobody reads
; observes nothing. That is the same distinction
; lowering_reject_live_record_clone_call_hop.ll /
; lowering_live_record_clone_call_measured_accept.ll draw for the walk's clause-1
; half; this pair draws it for clause 3.
;
; THE OTHER RAILS: `%h` is measured after the gate (clause 3, direct sink), and
; the clone's `cqq.out` return — the copy-destination record class Increment 3
; closed — is minted AFTER the gate, so the F2 existence test skips it (and it is
; measured anyway).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; the SIBLING
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %z   = call fastcc i32 @inner(i32 %c)                         ; CLONE HOP
  %mz  = call i32 @cq_measure_si32(i32 %z)                      ; the OBSERVING SINK
  %m   = call i32 @cq_measure_si32(i32 %q2)
  %m0  = call i32 @cq_measure_si32(i32 %q)
  %a   = add nsw i32 %m, %mz
  %r   = add nsw i32 %a, %m0
  ret i32 %r
}

define internal fastcc i32 @inner(i32 %x) {
  %a = mul i32 %x, 3
  ret i32 %a
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      %[[Z:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(i32 %[[C]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Z]])
; CHECK-NOT:  cq rotation lowering

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
