; lowering_uncompute_interior_leak_irreducible_mint.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F1). The
; CANDIDATE-SELECTION half of the irreducible-cycle fence: a rail MINTED inside
; an irreducible cycle never enters the interior partition.
;
; Sibling of lowering_uncompute_interior_leak_irreducible_gate.ll (which fences
; an in-place WRITE inside the cycle). Here the `cq_template_mul_i32_hl` itself
; sits in `%A`, so the rail is re-minted on every trip: at runtime K distinct
; handles exist and the SSA value names only the last. At 99211ad the partition
; emitted one `mul_i32_hl_unc` + `cqrt_free` in `%exit` — correct for the LAST
; handle and a silent leak of the other K-1, while `LoopInfo::getLoopFor(%A)`
; returned null because the cycle (`entry -> A|B`, `A -> B|exit`, `B -> A`) has
; two entries and no dominating header, i.e. is IRREDUCIBLE.
;
; The candidate skip in §1 already stated the at-most-once property ("a rail
; minted inside a loop is re-minted every iteration" —
; lowering_uncompute_interior_leak_loop_rail.ll pins the NATURAL-loop spelling);
; it asked the wrong predicate. `canRepeat` = `LoopInfo` OR `blockCanRepeat`
; (reachable-from-itself DFS) is the strict superset, and this fixture is the
; irreducible spelling of that same fixture.
;
; DISCRIMINATION: the compare rail `%h_cmp` — minted and read entirely inside
; `%exit`, which cannot repeat — still discharges, with `%h_op` demoted to a
; BORROWED parent. That borrow is sound: every one of `%h_op`'s users is a
; forward template producer (`preservesBorrowedParent` row 2), so nothing
; relabels it between the forward compare and the strip, and both read the same
; last-minted handle.
;
; C REACHABILITY — same correction as the sibling gate fixture (bd
; test_C_libtooling-4p7j Rule-13 RE-review, finding G2). No C spelling of a WRITE
; (or of a MINT) inside an irreducible cycle is reachable today, because the
; cycle-carried tainted value is a phi `declineClassicalMuxes` refuses upstream.
; IRREDUCIBLE CFGs THEMSELVES ARE C-reachable at `-O1` — see
; lowering_uncompute_interior_irreducible_reader_accept.ll, which is clang output
; from plain `goto`s and exercises the READ-side accept — so neither fixture is a
; hand-IR-only curiosity, and neither fence is dead weight.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEOP < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @interior_irreducible_mint(i32 %u0, i1 %c0, i1 %c1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c0, label %A, label %B
A:                                        ; preds = %entry, %B — irreducible
  %r = mul i32 %q, 5
  br i1 %c1, label %B, label %exit
B:                                        ; preds = %entry, %A
  br label %A
exit:
  %c = icmp slt i32 %r, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @interior_irreducible_mint(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[OP]], i32 10)
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[CMP]], i32 %[[OP]], i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z]])

; The cycle-minted rail is never adjointed and never freed (one anchor, one
; prefix, window anchor -> EOF — bd memory [filecheck-check-not-window-trap]):
; NOFREEOP:     %[[OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(
; NOFREEOP-NOT: @cq_template_mul_i32_hl_unc(
; NOFREEOP-NOT: call void @cqrt_free(i32 %[[OP2]])
