; lowering_live_record_sibling_region_then_measured_accept.ll — ACCEPT: the
; ONE-INSTRUCTION DISCRIMINATION CONTROL for
; lowering_reject_live_record_sibling_region_after_theta.ll (M-A, bd
; test_C_libtooling-6uqc; the F1 ruling, 2026-08-28).
;
; SOURCE — the reject twin plus a single measurement:
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // the SIBLING
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     if (c == 5) { c = cq_phi(c, 3.0); }
;     int mp = cq_measure(c);            // <-- THE WHOLE DIFFERENCE
;     return cq_measure(w) + cq_measure(a) + mp;
;
; WHY IT LOWERS. `%h_op1` (`c`) is still a rail entangled with the wire and still
; undischarged when the gate fires — the physics AT THE GATE is identical to the
; reject twin's. What changed is that its lineage now reaches an OBSERVING SINK:
; after `RegionFlatten` dissolves the merge phi, `cq_measure(c)` is a
; `cqrt_measure_i32` directly on `%h_op1`. Under the ruled clause 3 that makes it
; the program's own live data, and a live record's dephasing of the rotation is
; SOURCE SEMANTICS, not a compiler defect (owner ruling 2026-08-27 (1)) — exactly
; the principle that keeps lowering_stale_record_add_before_theta.ll green.
;
; THE OTHER TWO RAILS, so the accept is not read as "regions are fine now":
;   * `%h` — measured after the gate, so clause 3 exempts it the same way.
;   * `%h_cmp` — the region's eq flag, minted AFTER the gate. It is skipped by the
;     F2 existence test (`provablyBefore(T, R)`): a rail that is not allocated when
;     the `Ry` fires cannot dephase it. Note it would NOT be exempt on clause 3 —
;     its only users are the two `cqrt_cswap` routes, the `_unc` strip and
;     `cqrt_free`, none of which observe anything. That is the division of labour
;     between the two fixes, visible in one module.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w  = mul i32 %q, 2                                          ; THE WIRE
  %c  = mul i32 %q, 3                                          ; the SIBLING — now observed
  %q2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %cc = icmp eq i32 %c, 5
  br i1 %cc, label %arm, label %merge
arm:
  %cz = call i32 @cq_phi_si32(i32 %c, double 3.000000e+00)
  br label %merge
merge:
  %p  = phi i32 [ %cz, %arm ], [ %c, %entry ]
  %mp = call i32 @cq_measure_si32(i32 %p)                      ; the OBSERVING SINK
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)
  %a  = add nsw i32 %m, %m0
  %r  = add nsw i32 %a, %mp
  ret i32 %r
}

; The gate fires on the wire, the region lowers as a routed phase arm, and the
; sibling rail is MEASURED — the observation that exempts it:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[C]], i32 5)
; CHECK:      call void @cqrt_cswap(i32 %[[F]], i32 %[[C]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[C]], i32 5)
; CHECK:      call void @cqrt_free(i32 %[[F]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[C]])
; CHECK-NOT:  cq rotation lowering

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
