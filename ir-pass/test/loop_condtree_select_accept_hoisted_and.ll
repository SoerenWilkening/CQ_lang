; loop_condtree_select_accept_hoisted_and.ll — ACCEPT (bd test_C_libtooling-xdu2.16).
;
; `int a = 0; for (i < n) if ((q > 1) & (r < 5)) a += 3;` with `q`, `r` two
; quantum registers read ONLY as the condition (TRACK_E_xdu2_13.md probe p19).
; `clang -O1` LICM-hoists the whole condition tree — both compares AND the fused
; `and i1` — into the loop preheader (`%ph`), and if-converts the arm into a 4.4
; DATA select in the body. This is the stage-1 IR, names cleaned, shape verbatim.
;
; WHY IT DECLINED BEFORE, measured on the pre-change ORACLE `438c77bf45c02e3e`
; (main 983f9361): exit 1, `cq loop lowering: round-1 iteration-local marking
; falsified by round-2 taint`. At ROUND 1 `lowerLoops` grants the body an
; iteration-local marking on the roots {carried `a` chain, `%c`} — `%c` admitted
; by `invariantRegisterRootsImpl` clause (ii-d) as a hoisted template rail. The
; 4.4 emitter then consumes the tree: `emitCondNetwork` mints FRESH flags from the
; leaves' operands `%q`/`%r` immediately before the select (in the BODY), strips
; and frees them there, and ERASES the now-dead `%c`, `%c1`, `%c2`. The recorded
; `WeakTrackingVH` for `%c` goes NULL, and `declineRound2FalsifiedRailGrants`
; refused every nulled root unconditionally.
;
; WHAT CHANGED: a nulled root is no longer a refusal BY ITSELF. The grant is
; re-derived from scratch under FINAL taint by the owner
; (`invariantRegisterRoots`) and must be TOTAL; the recorded round-1 roots are
; discarded, not unioned; `railLocalQualifies` is re-asked on the fresh set. Here
; the body now reads `%q` and `%r` (via the emitter's in-body flag mints), both
; ROOT MINTS (clause (ii)), so the re-derivation is total and the marking stands.
;
; THE STREAM TO READ IT BY (per trip, all in the body): h_cmp = icmp_sgt_hl(h, 1),
; h_cmp1 = icmp_slt_hl(h2, 5), g = toffoli into a fresh |0> ancilla, the two
; X-bracketed controlled copies into a fresh `%out`, the toffoli undo, free(g),
; each compare's `_unc`, free. `h` and `h2` are read ONLY as controls/template
; operands and never freed or bracketed. The preheader keeps NOTHING of the tree.
; It is byte-for-byte the stream of the SAME module with the three tree
; instructions hand-sunk into the body (a shape the ORACLE already lowers) —
; measured `diff` empty, TRACK_XDU2_16.md §3.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H2:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK:      ph:
; CHECK-NEXT: br label %body
; CHECK:      body:
; CHECK-NEXT: %i = phi i32
; CHECK-NEXT: %[[A:[a-z0-9_.]+]] = phi i32 [ %cq.carried, %ph ], [ %[[OUT:out[0-9]*]], %body ]
; CHECK-NEXT: %[[OP:h_op[0-9]*]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 3)
; CHECK-NEXT: %[[F1:h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[F2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H2]], i32 5)
; CHECK-NEXT: %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: %[[OUT]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[OP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[H2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %i.next = add nuw nsw i32 %i, 1
;
; Whole-file negatives in a PURE prefix, counts in their own (Rule 12 (a)): the
; tree is gone from the preheader, no user register is freed or bracketed, and the
; select is gone.
; NEG-NOT: and i1
; NEG-NOT: select i1
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; NEG-NOT: cqrt_x(i32 %h{{[0-9]*}})
; CNT-COUNT-2: call void @cqrt_toffoli(
; CNT-NOT: call void @cqrt_toffoli(
; ERR-NOT: cq loop lowering
; ERR-NOT: error

define i32 @slice(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit

ph:
  %c1 = icmp sgt i32 %q, 1
  %c2 = icmp slt i32 %r, 5
  %c = and i1 %c1, %c2
  br label %body

exit:
  %a.lcssa = phi i32 [ 0, %entry ], [ %a.next, %body ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s0 = add nsw i32 %mr, %mq
  %ma = call i32 @cq_measure_si32(i32 %a.lcssa)
  %s = add nsw i32 %s0, %ma
  ret i32 %s

body:
  %i = phi i32 [ 0, %ph ], [ %i.next, %body ]
  %a = phi i32 [ 0, %ph ], [ %a.next, %body ]
  %a3 = add nsw i32 %a, 3
  %a.next = select i1 %c, i32 %a3, i32 %a
  %i.next = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i.next, %n
  br i1 %done, label %exit, label %body
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
