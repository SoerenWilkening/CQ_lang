; control_inplace_ry_stateprep_selfcontrolled_folded_as_prep.ll — ACCEPT, and
; THE FIXTURE THAT STATES THE TRADE THE 2026-09-11 RULING BUYS.
;
; ⚠ THIS MODULE IS `clang -O1`'s OUTPUT FOR **TWO DIFFERENT PROGRAMS**, AND THAT
; IS THE WHOLE POINT. It was produced from `probes/u2.c` —
;
;     int q = cq_theta(0, .25);
;     int r = 5;  if (q == 5) r = cq_theta(q, .9);   // rotate the CONDITION's
;                                                    // own register IN PLACE
;
; — i.e. from the SELF-CONTROLLED source, not from a state prep. The genuine
; prep `r = cq_theta(5, .9)` compiles to the identical module: MEASURED on the
; sibling pair `probes/a_prep.c` / `probes/a_self.c`, where
; `diff` over the two `-O1` slice bodies is **EMPTY**. IPSCCP proves `q == 5` on
; the equality edge and substitutes the literal for every use of `q` there, so
; arg-0 of the arm's `cq_theta` is folded to `i32 5` and the two sources arrive
; at the pass as ONE module.
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also
; WE DO NOT WANT ANOTHER cq function. it should just be an application of gates
; … I dont see the need for the over-decline."* (bd `drbq.14`; F2's `CondWire`
; narrowing — a pinned value on the CONDITION'S OWN BACKWARD WIRE is no longer a
; collider.)
;
; ⚠ WHAT THIS FILE COSTS, SAID PLAINLY (SCOPE H-1, the top hazard): the
; self-controlled source above was LOUDLY REFUSED before the ruling and now
; receives, with NO diagnostic, the circuit for the OTHER reading — a FRESH rail
; prepared to |5> and rotated under the flag, with the condition register `q`
; never touched. There is no fence that could separate them, because after `-O1`
; there is nothing left to separate: one module, two authors' intents. The
; mitigation is disclosure — this header, the ruling in CLAUDE.md and PRD §14,
; and the committed e2e slice — not a predicate.
;
; WHY THAT IS ADMISSIBLE RATHER THAN RECKLESS: the rival reading has never had a
; lowering in CQ and cannot acquire one while R4 stands. `railWireClosure`
; inserts its seed BEFORE any gate, so `RotBase` is always in `BaseWireOrder`,
; so `RotBase ∈ CondRails ⇒ R4 declines` for every CHAINED (register-arg-0)
; rotation arm; the only path past R4 is `StatePrep`, which is this folded case,
; where the register is not in the module at all. Measured, on the NARROWED
; binary: the UNFOLDED spellings of that same intent decline
; `condition predates a non-diagonal gate` (`probes/u6.c`, `v1.c`, `v2.c`,
; `w3.c`), `rotation arm on a condition wire` (`probes/v3.c` — R4 itself),
; `state prep merged with a quantum register` (`probes/u1.c`, `w1.c`, `w2.c`)
; and `condition data use neither escaped nor measured` (`probes/u5.c`, `w4.c`,
; `w5.c`). 19 of 19 alternative readings of the flipped fixtures decline too
; (`probes/alt/`).
;
; ⚠ AND THE NARROWING IS THE WIRE, NOTHING WIDER:
; `control_inplace_ry_reject_stateprep_nonwire_still_collides.ll` is the same
; program with the pin moved OFF the condition's backward cone, and it still
; DECLINES.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #2
  %2 = icmp eq i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])

; ------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (no positive directive inside the
; NOROUTE prefix: a positive `-COUNT-n` WINDOWS every negative after
; it, the drbq Inc-4 round-1 lesson). The counts below are the
; injection matrix's answer: an extra uncontrolled `cqrt_ry` on the
; CONDITION register moves RYCNT, an extra `cqrt_free` moves FCNT, and
; a `_controlled` on the WRONG flag breaks the CHECK capture.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; THE FREEZE: no `cqrt_free` may ever name the PREPPED rail.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL.
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

