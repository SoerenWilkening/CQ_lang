; lowering_live_record_post_gate_record_accept.ll — ACCEPT, and this is THE F2
; fixture (M-A, bd test_C_libtooling-6uqc; the Inc-3 Rule-13 round's F2 finding,
; 2026-08-28): A RECORD MINTED STRICTLY AFTER THE GATE CANNOT DEPHASE IT.
;
; SOURCE:
;     cq_theta(&a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     cq_theta(&w, 0.5);              // T — chained, in-place Ry on the wire
;     int z = a * 3;                     // a rail that does not EXIST yet at T
;     int y = a * 5;                     // ...and one that is observed
;     return cq_measure(w) + cq_measure(y);
;
; WHAT WAS WRONG. `warnLiveRecordRotations` walked the wire's record closure
; and then asked, per record, "is it discharged / measured / live?" — but never
; asked whether it EXISTS at the gate. `%h_op1` (`z`) is allocated by a
; `cq_template_mul` that is emitted AFTER the `cqrt_ry`, so at the instant the
; rotation fires there is no such rail; it cannot make the wire's reduced state
; diagonal, and there is nothing for the gate to be dephased BY. It is dead (never
; read, never measured, never taped), so every clause-3 test failed and the module
; DECLINED. MEASURED at the pre-fix tree: `opt` exit 1 with
; "cq rotation lowering: non-diagonal gate over a live derived record" — a FALSE
; decline on a rail that is not there.
;
; THE FIX IS A POSITION PROOF, `provablyBefore(T, R)`, and READ ITS MODALITY: it
; is the CONDITIONAL-on-`R` property — IF `R` executes then `T` already did, AND
; `T` is not reachable again from `R`. The second half is load-bearing, not
; decoration: a loop whose back edge re-runs the gate over a record minted in the
; body fails `isPotentiallyReachable` and the record still counts
; (lowering_reject_live_record_post_gate_record_loop.ll).
;
; WHY THE ANCESTOR HERE IS EXEMPT, because it is what makes this fixture isolate
; F2. `%h` (the alloc parent) is a live record of the wire and IS standing at the
; gate; it is exempt only because its post-gate read `y = a * 5` flows to a
; measurement — "a template read that itself flows to [an observing sink]", the
; F1 ruling's own wording. Delete `y`/`my` and this module declines again, on `%h`
; and correctly (that shape is lowering_reject_live_record_anc_alloc_parent_mul.ll
; plus a dead post-gate sibling). The two fixes are orthogonal and this module
; needs both.
;
; RULE-6 NOTE, so the trace is not misread: `%h_op1` is left ALLOCATED and never
; freed. The whole-DAG spine declines to reverse it because its parent `%h` sits
; in a measured lineage; leaving a rail allocated is the accepted safe leak, and
; it is orthogonal to what this fixture pins (the guard is pure analysis and emits
; nothing).
;
; `mul` is the vehicle at every hop (information-losing ⇒ never M-C-converted in
; place), so each of the three products really is a separate rail.
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
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %z   = mul i32 %q, 3                                          ; minted AFTER T, dead
  %y   = mul i32 %q, 5                                          ; minted AFTER T, observed
  %my  = call i32 @cq_measure_si32(i32 %y)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  %r   = add nsw i32 %m, %my
  ret i32 %r
}

; The gate fires BEFORE either post-gate rail is minted — that ordering is the
; whole fixture:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Y]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[W]])
; CHECK-NOT:  cq rotation lowering

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
