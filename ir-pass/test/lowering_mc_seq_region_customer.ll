; lowering_mc_seq_region_customer.ll — THE CAMPAIGN'S CUSTOMER SHAPE, at lit
; level (bd test_C_libtooling-6uqc M-C Increments 2a+2b; bd
; test_C_libtooling-nepx, which this file's 2b state CLOSES).
;
; This is `tests/e2e/slice_control_seq_grover.c` as the pass receives it: a theta,
; a `q += off`, a tainted-condition phase region, the `q -= off`, a chained S†
; theta, a second region, and a final `q += off`. `off` is a volatile load in the
; slice precisely so `clang -O1` cannot cancel the pair; here the two loads are
; spelled directly.
;
; WHAT IT PINS, AND IT IS THE WHOLE REASON THE FENCE IS POSITION-AWARE. Site 3
; (`%18 = add i32 %17, %16`) has a parent whose user list is NOT empty: the
; region-2 compare read it, the arm's controlled `Rz` read it (two `cqrt_cswap`s
; routed it before the §6a control-in-place peephole), and its `_unc` strip read
; it again. Under the WITHDRAWN "single-consumer-ever" reading every one of those
; disqualified the site, and the customer stayed dephased (SPIKE §9.8). Under the
; RULED position-aware, spine-discharge-aware fence they do not, because every one
; of them is a PRIOR, COMPLETED reader: they all precede the add, and the compare's
; flag was `_unc`-stripped AND `cqrt_free`d before it. So both `add` sites convert
; and the two ancestor rails they used to mint are never allocated.
;
; WHAT BATCH 2b ADDED, AND IT IS THE WHOLE OF bd nepx. The middle site is the
; `sub`, and 2a did not admit it: it still minted a fresh rail off the (collapsed)
; `%h`, and that rail was live and entangled when the S† `cqrt_ry_i32(…, -0.5)`
; fired — one ancestor instead of three, but a dephased reflection either way.
; With `sub` admitted (`q - c` → `cqrt_addc_i32(q, -c)`, the immediate negated in
; CLASSICAL IR) this function is a ONE-RAIL program end to end: exactly one data
; register is ever allocated, and every gate after the state prep acts on it in
; place. The `cq_template_sub_i32_hl` CHECK this file used to carry as its batch
; boundary is REPLACED below by the negation + in-place gate it became — replaced
; and not deleted, exactly as the 2a text asked.
;
; The negation `%cq_negimm = sub i32 0, %2` is CLASSICAL: it is created in Phase 2
; of `lowerOps` (after the taint set is frozen), never joins `taint.Tainted`,
; never becomes a gate, and emits NO trace line — the e2e golden sees only the
; negated runtime value `-3` in the `addc` immediate slot.
;
; THE OTHER THING IT PINS is that `detectControlRegions` + `SwapRouteEmit` +
; `RegionFlatten` all run BEFORE `lowerOps`, which is why the fence can see this
; at all. Pre-flatten, the parent of sites 2 and 3 is a MERGE PHI whose later-use
; set is not readable off the CFG; post-flatten it is a plain SSA value with a
; positioned, fully torn-down user list.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ONERAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; State prep: ONE rail, and `q += off` mutates it in place — no `h0`/`h1` pair.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
;
; Region 1 (the oracle) reads and fully tears down that same rail; its phase arm
; fires IN PLACE on `%[[H]]`, controlled by the flag:
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
;
; bd nepx's DEFECT SITE, now the fix. `q -= off` becomes a CLASSICAL negation
; feeding the in-place gate on the SAME `%[[H]]` — no ancestor rail is minted, so
; the S† rotation on the next line fires with nothing live beside it. The whole
; of nepx is these three lines:
; CHECK:      %[[N:[a-zA-Z0-9_.]+]] = sub i32 0, %{{[a-zA-Z0-9_.]+}}
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[N]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
;
; Region 2 reads THAT SAME REGISTER (not a `%h_op` descendant of it), then the
; LAST `q += off` — the site the withdrawn single-consumer reading would have
; refused, converting only because its parent's readers are prior and completed:
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
;
; NOT ONE out-of-place data rail is minted anywhere in this function. The only
; `cq_template_*` calls left are the two region flags and their `_unc` strips:
; CHECK-NOT:  cq_template_sub_
; CHECK-NOT:  cq_template_add_
;
; RE-MEASURED after the §6a collapse: ONE `cqrt_alloc_i32` in the whole module and
; no more — the ONE wire. Never an ancestor, and (since Increment 2a) never a work
; rail either: the two per-region work rails the route used to mint are gone, so
; this was 3. ONERAIL counts them:
; ONERAIL-COUNT-1: call i32 @cqrt_alloc_i32(
; ONERAIL-NOT:     call i32 @cqrt_alloc_i32(
; The swap route must not come back for these flat phase shapes. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@off = global i32 3

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)      ; S
  %2  = load volatile i32, ptr @off, align 4
  %3  = add nsw i32 %2, %1                                       ; site 1: q += off
  %4  = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:                                                ; the oracle arm
  call void @cq_phi(double 0x400921FB54442D18)
  br label %7

7:
  %9  = load volatile i32, ptr @off, align 4
  %10 = sub nsw i32 %3, %9                                       ; site 2: q -= off
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)   ; S-dagger
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; the reflection arm
  call void @cq_phi(double 0x400921FB54442D18)
  br label %15

15:
  %17 = load volatile i32, ptr @off, align 4
  %18 = add nsw i32 %17, %11                                     ; site 3: q += off
  %19 = call i32 @cq_measure_si32(i32 %18)
  ret i32 %19
}
