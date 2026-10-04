; lowering_live_record_condtree_toffoli_observed_accept.ll — ACCEPT: a CONTROL of
; a condition-tree AND node (`cqrt_toffoli`) HOPS to the node's target ancilla, so
; the sibling's lineage reaches the measurement of the merge OUT rail (M-A, bd
; test_C_libtooling-6uqc; round 2 of the Increment-3 Rule-13 round, 2026-08-28).
;
; SOURCE (the reviewer's g9 witness, verbatim in structure):
;     static volatile int k = 3;
;     int a = u0; cq_theta(&a, 0.5);
;     int b = u0 + 1; cq_theta(&b, 0.5);  // a SECOND wire
;     int w = a * 2;                     // THE WIRE
;     int c = a * k;                     // the SIBLING record (volatile k so -O1
;                                        //   keeps the multiply; the pass sees the
;                                        //   folded literal, written directly here)
;     int d = b * 5;
;     cq_theta(&w, 0.25);             // T — chained, in-place Ry on the wire
;     int m = ((c > 3) & (d < 9)) ? 10 : 20;   // `and i1` -> ONE cqrt_toffoli
;     return cq_measure(m) + cq_measure(w) + cq_measure(a) + cq_measure(b);
;
; WHAT STANDS AT THE GATE. Two rails: `%h` (the alloc parent, an ANCESTOR of the
; wire) and `%h_op4` (`c`, a DEAD-looking SIBLING). `%h` is measured after the gate
; — a direct sink, exempt. Everything else in the module (`%h_cmp`, `%h_cmp1`,
; `%g`, `%out`, the two `%selop` constants) is minted AFTER `T`, so the clause-6
; existence test skips it. The verdict therefore rests entirely on `%h_op4`.
;
; WHY IT LOWERS. `%h_op4`'s post-gate lineage is
;     c  --(cq_template_icmp_sgt, a HOP)-->  %h_cmp1
;        --(cqrt_toffoli CONTROL, THE HOP THIS ROUND ADDED)-->  %g
;        --(cqrt_copy_i32_controlled CTRL slot, a HOP)-->  %out
;        --(cqrt_measure_i32)-->  the OBSERVING SINK.
; The user reads a number that depends on `c`, so `c` is the program's own live
; data and its dephasing of `T` is source semantics — the ruled ACCEPT.
;
; WHY THE HOP HAD TO BE ADDED, AND WHY THE CSWAP RATIONALE DOES NOT COVER IT.
; `cqrt_cnot` and `cqrt_toffoli` shipped in the F1 walk's NON-USE bucket beside
; `cqrt_cswap`/`cqrt_x`, on the route argument: a routed value comes back to its
; OWN rail, so the route observes nothing and a later measurement of that rail is
; a direct user that counts on its own. That argument is TRUE FOR A ROUTE AND
; FALSE HERE. A CNOT/Toffoli does not move a value and return it — it WRITES the
; controls' information into a FRESH `|0⟩` ancilla, which is precisely the
; `and`/`or`/`xor` node of a condition tree, and the merge then reads that ancilla
; as the copy CONTROL. Nothing brings `c`'s information back; it flows ONWARD.
;
; HEAD (d2828e3) `opt` exit 0. PRE-ROUND-2 TREE `opt` exit 1 — a C-REACHABLE
; OVER-DECLINE, measured on the C above through the real pipeline, not constructed.
;
; DISCRIMINATION, one instruction wide: delete `cq_measure(m)` and this module
; DECLINES — the walk still reaches `%out`, but nothing observes it. That is
; lowering_reject_live_record_condtree_out_unobserved.ll, and it is what keeps this
; fixture from reading as "a toffoli exempts everything".
;
; The XOR spelling of the same node (`cqrt_cnot` pair, bd 3c6m.67's openlibm
; ulp-direction idiom) is lowering_live_record_condtree_xor_observed_accept.ll.
;
; `mul` is the vehicle at both hops (information-losing => never M-C-converted in
; place), so the sibling really is a separate rail and not a second name for the
; wire.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %u1  = add nsw i32 %u0, 1
  %b   = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)  ; a SECOND wire
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; the SIBLING record
  %q2  = call i32 @cq_theta_si32(i32 %w, double 2.500000e-01)   ; T
  %cc  = icmp sgt i32 %c, 3
  %cd  = icmp slt i32 %b, 9
  %cnd = and i1 %cd, %cc                                        ; AND node -> toffoli
  %m   = select i1 %cnd, i32 10, i32 20
  %mm  = call i32 @cq_measure_si32(i32 %m)                      ; the OBSERVING SINK
  %m1  = call i32 @cq_measure_si32(i32 %q2)
  %m2  = call i32 @cq_measure_si32(i32 %q)
  %m3  = call i32 @cq_measure_si32(i32 %b)
  %a1  = add nsw i32 %mm, %m1
  %a2  = add nsw i32 %a1, %m2
  %a3  = add nsw i32 %a2, %m3
  ret i32 %a3
}

; The sibling, the gate, the compare that reads the sibling, then the whole
; observation chain the walk now follows — node ancilla, controlled copy into the
; merge OUT rail, measurement:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 2.500000e-01)
; CHECK:      %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[C]], i32 3)
; CHECK:      %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[CMP]], i32 %[[G]])
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT:  cq rotation lowering

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. The guard now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a zero exit code is no longer a witness that it accepted — every fixture in
; this family would have kept passing while silently pinning nothing. `SILENT`
; reads the pass's stderr and is the pin that survived the severity change.
; SILENT-NOT: non-diagonal gate over a live derived record
