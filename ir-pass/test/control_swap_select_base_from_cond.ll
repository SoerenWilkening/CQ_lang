; control_swap_select_base_from_cond.ll — HALF TWO OF A PAIR (see
; `control_swap_value_reject_base_from_cond.ll`, which declines). SAME source
; program, the arm hoisted by hand into a `?:`; the 4.4 controlled-XOR copy merge
; ACCEPTS it. bd test_C_libtooling-3qlq Inc 2, Rule-13 round-2 review F-I2-7.
;
; PROVENANCE — captured from real `clang -O1`, SSA values renamed and nothing else.
; Source (`$SP/progress/fix_inc2_r2_work/p/q1e_ent_twin.c`):
;
;   int slice(void){ int q=3; q=cq_theta(q,0.5); int p=q+11;
;     int t=p; t=t+3; t=t*5; t=t^9; t=t+1; t=t*7; t=t^2;
;     p=(q>3)?t:p;
;     return cq_measure(p); }
;
; `-O1` reassociates the chain onto %q here too, so BOTH select operands are
; independently q-derived — the exact condition the `br` half declines on. The
; select classifier does not ask that question at all: it needs only two tainted
; operands of one integer width and a mintable flag, and it merges them by copying
; each into a FRESH |0> ancilla under the flag (a permutation, hence linear).
;
; ⚠ THIS ACCEPT IS NOT AN INC-2 CAPABILITY. MEASURED: the pre-3qlq ORACLE
; (52d7764), `main` a3c1513 and this branch all produce a BYTE-IDENTICAL lowering
; of this module, STRICT stage 2b clean (2 rails minted, both left allocated, 2
; frees, 2 verified, 0 violations). It is committed as the CONTROL that makes the
; decline in the other half legible as an asymmetry rather than as a property of
; the program — without it, that file pins a decline no one can weigh.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @slice() {
entry:
  %q  = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %p  = add nsw i32 %q, 11       ; the false operand, DERIVED from %q
  %t1 = mul i32 %q, 5            ; the true operand's chain — also bottoms at %q
  %t2 = add i32 %t1, 70
  %t3 = xor i32 %t2, 9
  %t4 = mul i32 %t3, 7
  %t5 = add i32 %t4, 7
  %t6 = xor i32 %t5, 2
  %c   = icmp sgt i32 %q, 3
  %sel = select i1 %c, i32 %t6, i32 %p
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; THE WHOLE REGION STREAM, CONTIGUOUS from the first alloc to the measure.
; Adjacency is the contract (the F-V2-5 lesson: symbol order cannot see a gate
; spliced between two pinned lines) — and it is what makes a DROPPED line visible:
; measured with the round-2 injection harness, a block that started at the flag
; mint and left the arithmetic to the counts below was caught by 6 of 7 mutations
; and MISSED `drop the chain's _unc`, because the free count does not move. The
; block below catches all seven.
;
; Read the arithmetic prologue for what `-O1` handed the pass: `%p = q+11` is an
; OUT-of-place template rail; the true operand's chain opens with an out-of-place
; `mul_i32_hl` and then converts IN PLACE (`cqrt_addc`/`cqrt_xorc`) on that fresh
; rail; the intermediate is reverse-played and freed mid-stream, and the surviving
; rail takes the last two in-place ops. None of that is the select's doing.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 11)
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[I]], i32 70)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[I]], i32 9)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[I]], i32 7)
; --- the intermediate rail is reverse-played and freed right where it dies ---
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[I]], i32 9)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[I]], i32 -70)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[I]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[I]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[T]], i32 7)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[T]], i32 2)
; --- THE MERGE ---
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; --- true operand under the flag, then false operand under the ¬-bracket ---
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[T:[a-zA-Z0-9_.]+]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; --- strip + free the flag, then measure the fresh out-rail ---
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])

; Whole-file PURE-NEGATIVE scan (no count inside it — the drbq Inc-4 windowing
; lesson). A select merge routes nothing and keeps no CFG; and this module has no
; `cq_phi`, so ANY `cqrt_rz` would be wrong (a non-i1 one is the tensored gate
; bd test_C_libtooling-3qlq exists to retire).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz_
; NOROUTE-NOT: select i1
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: br i1
; NOROUTE-NOT: under quantum control

; EXACTLY TWO controlled copies — one per operand. A third would mean a value was
; written unconditionally into the out-rail.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
; EXACTLY TWO frees, and both are TEMPLATE-minted rails returned to |0> by their
; own `_unc` on the line above: the dead chain intermediate (`mul_i32_hl_unc`) and
; the flag (`icmp_sgt_i32_hl_unc`). The out-rail, %q, both select operands and the
; surviving chain rail are NOT provably |0> and are left ALLOCATED (Rule 6).
; STRICT stage 2b on this module reports `2 rail mint(s) of which 2 left
; allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` — note
; its "mints" are the two `cqrt_alloc` sites (%q's handle and the out-rail), which
; are exactly the two it reports left allocated; the freed pair are template rails
; it counts separately.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
