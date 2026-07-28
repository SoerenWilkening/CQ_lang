; control_swap_switch_datamux.ll — ACCEPT spec: a clean constant DATA-MUX switch
; (4.5 WI-4; IMPLEMENTATION-4.5 §4C — preload + XOR-delta controlled copy, symbol
; ORDER is the contract).
;
; `switch(q){ case 0: r=7; case 1: r=9; default: r=3 }` — every merge incoming is a
; ConstantInt (default v_d=3, cases v_0=7 / v_1=9): a compile-time multiplexer. The
; lowering PRELOADS %out = cqrt_alloc_i32(v_d=3), then per content case mints the
; eq-flag f_i=(q==c_i), allocates the COMPILE-TIME XOR-delta %d_i = v_i ^ v_d
; (7^3=4, 9^3=10), and fires cqrt_copy_i32_controlled(f_i, d_i, out) — out ^= d_i
; iff f_i=1. Distinct literals ⇒ MUTUALLY EXCLUSIVE flags ⇒ at most one copy fires:
; the matched case k gives out = v_d ^ (v_k ^ v_d) = v_k; no match (default) leaves
; out = v_d. Then each flag is stripped with icmp_eq_inv(q) (q==q0 — the copies
; write %out, never q) and freed: EXACTLY TWO frees (the N flags). %out (the result),
; q, and every %d_i scratch are NEVER freed (a benign classical leak, Rule 6).
;
; NO route cswap, NO ¬-bracket cqrt_x (distinct literals are disjoint — the default
; is the PRELOAD, NOT a synthesized ¬OR flag), NO reverse-play, NO surviving phi.
;
; (Hand-written `switch i32`: clang -O1 folds a small const data-mux to a select
; chain / jump-table gep+load, so the real tainted switch is authored by hand — the
; INPUT prefix pins that this fixture exercises the SWITCH path, not the pre-
; detection `declineTaintEscapes` gep/load decline.) WI-1 reached the would-be-ACCEPT
; and fired the TRANSITIONAL "switch" decline; WI-4 graduates: push + emit + flatten.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=ORD
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
; Whole-output stray-x/-cswap scan (WI-7 §8.2 lit-robustness): the §4C recipe is a
; preload + XOR-delta controlled copy — NO route cswap, NO ¬-bracket cqrt_x. The
; default CHECK-NOT block scans only post-measure; this independent whole-file scan
; also rejects a stray x/cswap BEFORE the measure (an identical-multiset miscompile).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=XCT
; The fixture exercises the real switch path (not the jump-table gep/load decline):
; RUN: %filecheck %s --check-prefix=INPUT < %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; the scrutinee theta lowers to the alloc+ry handle (RAUW q -> the i32 handle)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; --- PRELOAD %out = cqrt_alloc(v_d=3) ---
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; --- case 0 (q==0): eq-flag -> XOR-delta alloc(7^3=4) -> controlled copy ---
; CHECK:     %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     %[[D0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[D0]], i32 %[[OUT]])
; --- case 1 (q==1): eq-flag -> XOR-delta alloc(9^3=10) -> controlled copy ---
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[D1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D1]], i32 %[[OUT]])
; --- strip + free both flags (each strip reads pristine q == q0) ---
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F0]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; --- the merge phi RAUWs to %out — the measure reads the muxed answer ---
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no third free (neither %out nor either XOR-delta scratch — a spurious free is a
; hidden measurement, Rule 6); zero route/¬-bracket/controlled-rotation gates; no
; surviving data-mux phi:
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_x
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: cqrt_ry{{.*}}_controlled
; CHECK-NOT: phi i32

; Exact free count — TWO (the N flags only), no third anywhere (the deltas + %out
; are left allocated — a benign classical leak, never freed):
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; ORDER is the contract (a mis-ordered N-way emit yields the IDENTICAL symbol
; MULTISET — order-blind structural CHECKs miss it). Pin the §4C stream:
; preload -> (eq -> alloc(delta) -> copy_controlled) x2 -> eq_inv x2.
; ORD:     @cqrt_alloc_i32(i32 3)
; ORD:     @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; ORD:     @cqrt_alloc_i32(i32 4)
; ORD:     @cqrt_copy_i32_controlled(
; ORD:     @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; ORD:     @cqrt_alloc_i32(i32 10)
; ORD:     @cqrt_copy_i32_controlled(
; ORD:     @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 0)
; ORD:     @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 1)

; the switch ACCEPTS — no decline anywhere:
; ACC-NOT: under quantum control

; No route, no ¬-bracket: ZERO cqrt_x AND ZERO cqrt_cswap in the whole output (a
; stray x/cswap = a wrong unitary with the same default + a single extra symbol).
; XCT-NOT: call void @cqrt_x(
; XCT-NOT: call void @cqrt_cswap(

; INPUT (matched against the source): the fixture holds a REAL tainted switch, not a
; clang-folded select-chain / jump-table gep+load (which would decline pre-detection
; at declineTaintEscapes — failing the positive stream CHECK above, the real teeth):
; INPUT: switch i32 %q, label %merge
