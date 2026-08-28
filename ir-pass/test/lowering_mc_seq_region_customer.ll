; lowering_mc_seq_region_customer.ll — THE CAMPAIGN'S CUSTOMER SHAPE, at lit
; level (bd test_C_libtooling-6uqc M-C Increment 2a; bd test_C_libtooling-nepx).
;
; This is `tests/e2e/slice_control_seq_grover.c` as the pass receives it: a theta,
; a `q += off`, a tainted-condition phase region, the `q -= off`, a chained S†
; theta, a second region, and a final `q += off`. `off` is a volatile load in the
; slice precisely so `clang -O1` cannot cancel the pair; here the two loads are
; spelled directly.
;
; WHAT IT PINS, AND IT IS THE WHOLE REASON THE FENCE IS POSITION-AWARE. Site 3
; (`%18 = add i32 %17, %16`) has a parent whose user list is NOT empty: the
; region-2 compare read it, two `cqrt_cswap`s routed it, and its `_unc` strip read
; it again. Under the WITHDRAWN "single-consumer-ever" reading every one of those
; disqualified the site, and the customer stayed dephased (SPIKE §9.8). Under the
; RULED position-aware, spine-discharge-aware fence they do not, because every one
; of them is a PRIOR, COMPLETED reader: they all precede the add, and the compare's
; flag was `_unc`-stripped AND `cqrt_free`d before it. So both `add` sites convert
; and the two ancestor rails they used to mint are never allocated.
;
; WHAT IT DOES *NOT* PIN — read this before quoting a green run as a fix. The
; middle site is a `sub`, which BATCH 2a DOES NOT ADMIT. It still mints a fresh
; rail off the (now collapsed) `%h`, and that rail is still live and entangled
; when the S† `cqrt_ry_i32(…, -0.5)` fires. bd nepx is therefore STILL OPEN after
; this increment: this file goes from three ancestor rails to one, not to zero.
; The `CHECK` for the surviving `cq_template_sub_i32_hl` is deliberate — it is the
; batch boundary, and when batch 2b lands it must be replaced, not deleted.
;
; THE OTHER THING IT PINS is that `detectControlRegions` + `SwapRouteEmit` +
; `RegionFlatten` all run BEFORE `lowerOps`, which is why the fence can see this
; at all. Pre-flatten, the parent of sites 2 and 3 is a MERGE PHI whose later-use
; set is not readable off the CFG; post-flatten it is a plain SSA value with a
; positioned, fully torn-down user list.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ONERAIL < %t.cqd0.ll
;
; State prep: ONE rail, and `q += off` mutates it in place — no `h0`/`h1` pair.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
;
; Region 1 (the oracle) reads and fully tears down that same rail:
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
;
; BATCH BOUNDARY — the `sub` is NOT admitted by batch 2a, so it still mints an
; ancestor rail and the S† rotation still fires with `%[[H]]` live beside it.
; This is bd nepx's defect, one rail shorter, NOT bd nepx fixed:
; CHECK:      %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[S]], double -5.000000e-01)
;
; Region 2, then the LAST `q += off` — the site the withdrawn single-consumer
; reading would have refused, converting only because its parent's readers are
; prior and completed:
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[S]], i32 0)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[S]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call void @cqrt_addc_i32(i32 %[[S]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
;
; Exactly TWO `cqrt_alloc_i32` survive per region pair (the wire and each region's
; work rail) plus the sub's rail — never the two ancestor rails the out-of-place
; adds used to mint. ONERAIL counts the whole module:
; ONERAIL-COUNT-3: call i32 @cqrt_alloc_i32(
; ONERAIL-NOT:     call i32 @cqrt_alloc_i32(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@off = global i32 3

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)      ; S
  %2  = load volatile i32, ptr @off, align 4
  %3  = add nsw i32 %2, %1                                       ; site 1: q += off
  %4  = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:                                                ; the oracle arm
  %6  = call i32 @cq_phi_si32(i32 5, double 0x400921FB54442D18)
  br label %7

7:
  %8  = phi i32 [ %6, %5 ], [ %3, %0 ]
  %9  = load volatile i32, ptr @off, align 4
  %10 = sub nsw i32 %8, %9                                       ; site 2: BATCH 2b
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)   ; S-dagger
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; the reflection arm
  %14 = call i32 @cq_phi_si32(i32 0, double 0x400921FB54442D18)
  br label %15

15:
  %16 = phi i32 [ %14, %13 ], [ %11, %7 ]
  %17 = load volatile i32, ptr @off, align 4
  %18 = add nsw i32 %17, %16                                     ; site 3: q += off
  %19 = call i32 @cq_measure_si32(i32 %18)
  ret i32 %19
}
