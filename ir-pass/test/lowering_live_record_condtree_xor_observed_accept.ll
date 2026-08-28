; lowering_live_record_condtree_xor_observed_accept.ll — ACCEPT: the XOR spelling
; of the condition-tree node. A CONTROL of `cqrt_cnot` HOPS to the node ancilla,
; exactly as the AND node's `cqrt_toffoli` does (M-A, bd test_C_libtooling-6uqc;
; round 2 of the Increment-3 Rule-13 round, 2026-08-28).
;
; SOURCE (the reviewer's g10 witness):
;     static volatile int k = 3;
;     int a = cq_theta(u0, 0.5);
;     int b = cq_theta(u0 + 1, 0.5);     // a SECOND wire
;     int w = a * 2;                     // THE WIRE
;     int c = a * k;                     // the SIBLING record
;     int d = b * 5;
;     w = cq_theta(w, 0.25);             // T
;     int m = ((c > 3) ^ (d < 9)) ? 10 : 20;   // `xor i1` -> TWO cqrt_cnot
;     return cq_measure(m) + cq_measure(w) + cq_measure(a) + cq_measure(b);
;
; WHY THIS SPELLING GETS ITS OWN FIXTURE. The xor node is not decoration: it is
; the openlibm ULP-DIRECTION IDIOM `if ((x > 0.0) ^ (x < y))` that bd 3c6m.67
; admitted to the condition-tree grammar, and its network is the OR network MINUS
; the toffoli — `cqrt_cnot(L, G); cqrt_cnot(Rv, G)` onto a fresh `|0⟩` ancilla
; (SelectMergeEmit.cpp:192-196). So the AND fixture's `cqrt_toffoli` CHECK does
; not cover it, and the two gates reach the walk by different arities.
;
; WHAT STANDS AT THE GATE and WHY IT LOWERS: identical to
; lowering_live_record_condtree_toffoli_observed_accept.ll — read that header for
; the rail-by-rail account. The only difference is the middle hop:
;     c --(icmp_sgt HOP)--> %h_cmp1 --(cqrt_cnot CONTROL)--> %g
;       --(cqrt_copy_i32_controlled CTRL)--> %out --(cqrt_measure_i32)--> SINK.
;
; HEAD (d2828e3) `opt` exit 0. PRE-ROUND-2 TREE `opt` exit 1 — a C-reachable
; over-decline, measured through the real pipeline.
;
; NOTE WHICH CNOT CARRIES IT. Four `cqrt_cnot`s are emitted: two forward and two in
; the LIFO strip after the copies. The walk crosses whichever it reaches first and
; the verdict is the same either way — deeper nodes in this walk carry no position
; test (documented at `reachesObservingSink`), and the FORWARD pair alone already
; establishes the observation.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WHOLE < %t.cqd0.ll
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
  %cnd = xor i1 %cd, %cc                                        ; XOR node -> cnot pair
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

; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:       %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:       call void @cqrt_ry_i32(i32 %[[W]], double 2.500000e-01)
; CHECK:       %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[C]], i32 3)
; CHECK:       %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:       call void @cqrt_cnot(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[CMP]], i32 %[[G]])
; CHECK:       %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT:   cq rotation lowering

; WHOLE-FILE negative in its OWN prefix, so it scans the entire module and not just
; the tail after the last positive CHECK (the bd 261j(a) dead-window lesson). The
; xor node carries NO toffoli — bd 3c6m.67's silent-miscompile pin, re-asserted
; here because this fixture's whole point is that the CNOT pair alone IS the node,
; and a stray toffoli would compute `L AND Rv` while still verifying:
; WHOLE-NOT: cqrt_toffoli
