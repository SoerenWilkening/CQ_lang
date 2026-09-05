; control_swap_switch_value.ll — ACCEPT spec: a clean homogeneous VALUE switch,
; lowered by PRELOAD + XOR-DELTA CONTROLLED COPY (bd test_C_libtooling-3qlq
; Inc 2, retire-swap-route-PRD §7.2 shape V3; symbol ORDER is the contract).
;
; `switch(q){ case 0: p=p+1; case 1: p=p+2; }` — each arm a pure linear value
; chain over the SHARED base %p = the merge default-edge (straight-through)
; incoming, p != q (the C2 anchor; a chain on q would clobber the eq-flags, §3c).
;
; ⚠ THIS FIXTURE PINNED THE RETIRED SWAP ROUTE UNTIL 3qlq Inc 2 (per case: a |0>
; work rail, two cswaps forward, two more in the reverse-play, plus one
; uncontrolled `cqrt_copy_i32(p,out)` — 4N cswap = 4NW Toffoli + 8NW CNOT). The
; replacement is the 4.5 data-mux's own "preload + XOR-delta" recipe with the
; default LITERAL replaced by the quantum register %p:
;
;   alloc out(0); cqrt_copy_i32(p, out)                  <- the ONE preload copy
;   per case i:  R_i(p) hoisted into the pred (unconditional, ordinary tainted
;                arithmetic lowered by `lowerOps`)
;                d_i = R_i(p) XOR p          (a Q+Q `xor`, fwd_qq/unc_qq)
;                f_i = icmp_eq(q, c_i)
;                cqrt_copy_i32_controlled(f_i, d_i, out)  <- out ^= f_i . d_i
;   strip + free every f_i
;
; `out` starts at p and at most ONE delta lands, because the eq-flags are
; MUTUALLY EXCLUSIVE — a property of `switch` semantics (LLVM's verifier rejects
; a duplicated case value), ASSERTED in the emitter rather than assumed. So
; `out = R_i(p)` on case i and `out = p` on every other branch, with no
; conjunction flag and NO ¬-bracket anywhere.
;
; The per-case intermediate rails discharge through the ordinary whole-DAG spine
; (`add_i32_hl_unc` + `cqrt_free` below); the deltas and %p are left ALLOCATED —
; every one of them is a function of %p, which is itself kept live and entangled
; with %out (keep-source-live), so they record no which-path information %p does
; not already record. Every CHECK is re-derived from the pass output.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE REGION STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first
; alloc to the measure is the contract here, not decoration (bd
; test_C_libtooling-3qlq Inc 2, Rule-13 round-1 review finding F-V2-5): the
; re-derivation that first shipped this file used bare positional directives
; throughout, and a stray gate spliced between two pinned lines — a
; `cqrt_ry_i32` immediately before the first controlled copy — then passed
; EVERY prefix. Symbol ORDER cannot see an insertion; adjacency can.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %p0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 0x3FE6666666666666)
; --- PRELOAD: out = |0>, then the ONE uncontrolled basis copy out ^= p ---
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; --- case 0 (q==0): chain on p, XOR-delta, flag, one controlled copy ---
; CHECK-NEXT: %[[T0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 1)
; CHECK-NEXT: %[[D0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[P]], i32 %[[T0]])
; the chain intermediate discharges through the ordinary whole-DAG spine
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[T0]], i32 %[[P]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T0]])
; CHECK-NEXT: %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[D0]], i32 %[[OUT]])
; --- case 1 (q==1) ---
; CHECK-NEXT: %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 2)
; CHECK-NEXT: %[[D1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[P]], i32 %[[T1]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[T1]], i32 %[[P]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T1]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D1]], i32 %[[OUT]])
; --- strips + flag frees, forward order (each reads PRISTINE q); every strip
;     is adjacent to the free it licenses, so a dropped strip is a red here ---
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; Whole-file PURE-NEGATIVE scan. No route survives; the merge is
; positive-polarity (mutually exclusive eq-flags) so there is ZERO cqrt_x — a
; stray x would be swapped operands + a dirty flag, an identical-multiset wrong
; unitary the ordered prefix above cannot see.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: switch i32

; EXACTLY FOUR frees: the two chain intermediates + the two flags. %p, %out and
; the two deltas are never freed.
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY N=2 controlled copies — one per content case.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
; EXACTLY ONE uncontrolled basis copy — the preload. A second would mean a case
; wrote %out unconditionally.
; PCNT-COUNT-1: call void @cqrt_copy_i32(
; PCNT-NOT:     call void @cqrt_copy_i32(
