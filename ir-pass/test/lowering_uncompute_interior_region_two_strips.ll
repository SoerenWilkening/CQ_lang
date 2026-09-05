; lowering_uncompute_interior_region_two_strips.ll — ACCEPT (M-B Increment 6,
; clause (d2); bd test_C_libtooling-160a Rule-13 round, finding F1c). ONE chain
; rail read by TWO emitter-recorded flag strips.
;
; PROVENANCE: `clang -O1` output of
;
;     int q = cq_theta(u, 0.5);
;     int k = (q * 5) >> 2;                 /* k == 5 <=> q == 4; k == 6 <=> q == 5 */
;     if (k == 5) q = cq_phi(q, PI);
;     if (k == 6) q = cq_phi(q, 0.25);
;     q = cq_theta(q, -0.5);  return cq_measure(q);
;
; `-O1` rewrites `(q*5)>>2` as `q + (q>>2)`, so the chain is `ashr` -> QQ `add`,
; and BOTH compares read the SAME `add` rail. The two `if`s become two SEQUENTIAL
; flat phase regions (bd hcrg), each recording its own strip.
;
; WHAT IS NEW HERE, AND WHY IT NEEDED A PIN. The shipped Increment-6 accepts each
; had ONE recorded strip per chain (`_region_chain`, `_int_chain`,
; `_ifelse_chain`) or PRODUCER-DISJOINT chains (`_seq_chains`). This is the third
; shape: one component, TWO admitted consumers on the same rail. The consumer
; test (`ChainWalk::isInteriorConsumer` clause (c)) is per USER, so both strips
; are admitted; `dagInsertPoint` then takes the LAST of them, and the discharge
; lands after strip 2 — never after strip 1, which would free a rail strip 2
; still reads (a use-after-free the golden byte-diff cannot see). Both regions'
; route groups fall inside the resulting interval and are exempted as UNITS by
; clause (d2); everything else that touches `%h` between the forward `add` and
; the discharge is a diagonal `cqrt_rz` on a WORK rail or an `cqrt_x` on a flag.
;
; RED-CHECKED against an `f27c7fd` (pre-Increment-6) plugin: there the chain is
; refused outright (an `_unc` reader is not an interior consumer), nothing after
; the second strip is emitted, and the whole program then DECLINES at the M-A
; guard on the S-dagger.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_recorded_strips(i32 noundef %0) {
  %2 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = ashr i32 %2, 2
  %4 = add nsw i32 %3, %2
  %5 = icmp eq i32 %4, 5
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  call void @cq_phi(double 0x400921FB54442D18)
  br label %8

8:                                                ; preds = %6, %1
  %10 = icmp eq i32 %4, 6
  br i1 %10, label %11, label %13

11:                                               ; preds = %8
  call void @cq_phi(double 2.500000e-01)
  br label %13

13:                                               ; preds = %11, %8
  %15 = call i32 @cq_theta_si32(i32 noundef %2, double noundef -5.000000e-01)
  %16 = call i32 @cq_measure_si32(i32 noundef %15)
  ret i32 %16
}

; CHECK-LABEL: define i32 @two_recorded_strips(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[SH:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[K:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[SH]])

; Region 1: mint, route, Rz, route back, rail free, STRIP 1 — and NOTHING of the
; chain is discharged yet, because strip 2 still reads %[[K]]:
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 5)
; the region, CONTROL-IN-PLACE since drbq Inc 2a: one `cqrt_rz_<W>_controlled` on
; the user's own register in place of the route quintuple — no work rail, no
; CSWAP, nothing to free but the flag.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[K]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])

; Region 2 reads the SAME rail, and only after ITS strip does the chain unwind,
; LIFO, each rail freed right after its own adjoint; the second flag's free
; trails the chain because the flag's own last use is its strip:
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 6)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[K]], i32 6)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[K]], i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])

; Only THEN the S-dagger — at which point %[[H]] is the one allocated rail:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
