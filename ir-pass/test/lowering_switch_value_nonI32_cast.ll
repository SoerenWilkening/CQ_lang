; lowering_switch_value_nonI32_cast.ll — bd p119.8 (the same gap as p119.6, for
; the SWITCH value-arm merge), RE-DERIVED for bd test_C_libtooling-3qlq Inc 2.
;
; A tainted `switch` with homogeneous VALUE arms over a shared base %p (an i64
; theta) — %p, %p+1, %p+2 — produces a NON-i32 (i64) merge that feeds a
; downstream `trunc i64 -> i32`. The value arms lower and RAUW the merge to the
; i64 out-rail. Without `SwitchValueEmit` recording HandleWidth[out]="i64" the
; trunc reads the laundered i32 handle type and OVER-DECLINES; with the width
; recorded it lowers to `cq_template_trunc_i64_to_i32`.
;
; ⚠ THE p119.8 PROPERTY IS PINNED BY EXACTLY ONE POSITIVE DIRECTIVE: the
; `CHECK-NEXT` on `call i32 @cq_template_trunc_i64_to_i32(i32 %[[OUT]])` at the
; foot of the region stream below (with the whole-file `NOROUTE-NOT` on
; `cq_template_trunc_i32` and on a surviving `= trunc` as its counterfactuals).
; MEASURED by mutation (fix_inc2_r2, 2026-09-06): commenting out
; `SwitchValueEmit.cpp`'s `taint.HandleWidth[Out] = Abi;` and rebuilding makes
; the pass OVER-DECLINE — `no template for opcode 'trunc i32' in tainted
; context`, `opt` exit 1 — so the failure lands on the FIRST RUN line and the
; whole file reddens; the positive directive above is what NAMES the property
; that regressed. (The mutation was reverted and the binary rebuilt
; byte-identical, so nothing of it survives in the tree.)
;
; ⚠ THIS FIXTURE DOCUMENTED THE RETIRED SWAP ROUTE IN THE PRESENT TENSE UNTIL
; 3qlq Inc 2 (Rule-13 round-2 review finding F-I2-3). Its output moved under Inc
; 2 — per case a |0> work rail plus four `cqrt_cswap` and a reverse-play became
; the 4.5 data-mux recipe with the default LITERAL replaced by the quantum
; register %p — and NOTHING went red, because its three directives were about
; the cast alone and are blind to the mechanism. It is now re-derived from the
; pass output, whole-region and adjacent, so a mechanism change reddens it.
; RED-GREEN, MEASURED against the INC-1-ONLY binary (`main` a3c1513, which still
; routes): of the six prefixes, THREE discriminate — the default block (the
; `CHECK-NEXT` at the `%[[OUT]]` alloc: the route mints its flags and work rails
; first), `NOROUTE` (on `cqrt_cswap`) and `CCNT` (the route emits ZERO
; `cqrt_copy_i64_controlled`). `FCNT` and `PCNT` do NOT: the route also frees
; exactly four rails and also emits exactly one uncontrolled `cqrt_copy_i64`
; preload, so those two prefixes are shape assertions, not mechanism ones. Said
; out loud because a prefix that cannot tell the two mechanisms apart must not be
; quoted as if it could.
;
; The shipped recipe (identical to `control_swap_switch_value.ll`, at i64):
;
;   alloc out(0); cqrt_copy_i64(p, out)                  <- the ONE preload copy
;   per case i:  R_i(p) hoisted into the pred (unconditional, ordinary tainted
;                arithmetic lowered by `lowerOps`), discharged by the whole-DAG
;                spine (`add_i64_hl_unc` + `cqrt_free`) right where it dies
;                d_i = R_i(p) XOR p          (a Q+Q `xor`, `cq_template_xor_i64`)
;                f_i = icmp_eq(q, c_i)       (an i32 compare — the SCRUTINEE is
;                                             i32 here, only the MERGE is i64)
;                cqrt_copy_i64_controlled(f_i, d_i, out)  <- out ^= f_i . d_i
;   strip + free every f_i
;
; `out` starts at p and at most ONE delta lands: the eq-flags are MUTUALLY
; EXCLUSIVE by `switch` semantics. So there is no conjunction flag and NO
; ¬-bracket, hence zero `cqrt_x`. %p and the two deltas are left ALLOCATED
; (every delta is a function of %p, which is kept live, so they record no
; which-path information %p does not already record); `%out` is reversed and
; freed after its reader since bd r2j3.32 (pinned below).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPUT < %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i64 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i64 @cq_theta_sll(i64 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i64 %p, 1
  br label %merge
a1:
  %v1 = add i64 %p, 2
  br label %merge
merge:
  %pm = phi i64 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]   ; i64 value merge (non-i32)
  %t  = trunc i64 %pm to i32                                  ; cast off the merge (needs From=i64)
  %m  = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

; The INPUT really is a `switch`, not a chain of `br` diamonds — without this the
; file could go green on a program that never exercises `SwitchValueEmit`.
; INPUT: switch i32 %q, label %merge

; THE WHOLE REGION STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first
; alloc to the measure is the contract (the F-V2-5 lesson recorded in
; `control_swap_switch_value.ll`: symbol ORDER cannot see a gate spliced between
; two pinned lines, adjacency can).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %p0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[P]], double 0x3FE6666666666666)
; --- PRELOAD: out = |0>, then the ONE uncontrolled basis copy out ^= p ---
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_copy_i64(i32 %[[P]], i32 %[[OUT]])
; --- case 0 (q==0): chain on p, XOR-delta, discharge, flag, controlled copy ---
; CHECK-NEXT: %[[T0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64_hl(i32 %[[P]], i64 1)
; CHECK-NEXT: %[[D0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i64(i32 %[[P]], i32 %[[T0]])
; CHECK-NEXT: call void @cq_template_add_i64_hl_unc(i32 %[[T0]], i32 %[[P]], i64 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T0]])
; CHECK-NEXT: %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F0]], i32 %[[D0]], i32 %[[OUT]])
; --- case 1 (q==1) ---
; CHECK-NEXT: %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64_hl(i32 %[[P]], i64 2)
; CHECK-NEXT: %[[D1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i64(i32 %[[P]], i32 %[[T1]])
; CHECK-NEXT: call void @cq_template_add_i64_hl_unc(i32 %[[T1]], i32 %[[P]], i64 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T1]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F1]], i32 %[[D1]], i32 %[[OUT]])
; --- bd p119.8, THE PROPERTY THIS FILE EXISTS FOR: the cast off the i64 merge
;     reads the recorded WIDTH, not the laundered i32 handle type ---
; CHECK-NEXT: %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[OUT]])
; --- bd r2j3.32 (R11 round 1): the cast is `%out`'s last reader, so every write
;     of `%out` is re-applied in reverse — both controlled delta copies and the
;     UNCONTROLLED preload copy of %p (all XOR involutions; %p, the deltas and the
;     flags are only read in between) — leaving `%out` at |0>. The eq-flag strips
;     are DEFERRED to after that, each still adjacent to the free it licenses,
;     so a dropped strip is a red here ---
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F1]], i32 %[[D1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F0]], i32 %[[D0]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_copy_i64(i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[CAST]])

; Whole-file PURE-NEGATIVE scan (a `NOROUTE-COUNT` here would WINDOW every
; negative after it — the drbq Inc-4 lesson; the counts live in their own
; prefixes below). No route survives; the merge is positive-polarity (mutually
; exclusive eq-flags) so there is ZERO `cqrt_x`; and the p119.8 counterfactuals
; are here — a surviving `trunc` instruction, or a trunc lowered at the WRONG
; source width (`cq_template_trunc_i32_to_*`).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: cq_template_trunc_i32
; NOROUTE-NOT: phi i64
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: switch i32
; This module contains no `cq_phi` at all, so ANY Rz would be wrong here — which
; is strictly stronger than the epic-wide property (bd test_C_libtooling-3qlq
; Inc 1 D3: the emitted Rz set is `cqrt_rz_i1` alone, and a non-i1 `cqrt_rz` is
; the TENSORED gate the epic exists to retire).
; NOROUTE-NOT: cqrt_rz_

; EXACTLY FOUR frees: the two chain intermediates + the two flags. %p, %out and
; the two deltas are never freed (they are not provably |0>, Rule 6).
; FCNT-COUNT-5: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY N=2 controlled copies — one per content case.
; CCNT-COUNT-4: call void @cqrt_copy_i64_controlled(
; CCNT-NOT:     call void @cqrt_copy_i64_controlled(
; EXACTLY ONE uncontrolled basis copy — the preload. A second would mean a case
; wrote %out unconditionally.
; PCNT-COUNT-2: call void @cqrt_copy_i64(i32
; PCNT-NOT:     call void @cqrt_copy_i64(i32
