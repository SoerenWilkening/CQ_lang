; control_predmux_accept_recorded_railphi_boolalg_converted.ll — ACCEPT, and the
; WITNESS FOR THE ONE CONJUNCT THAT KEEPS bd `test_C_libtooling-woa0`'s fence from
; being a regression.
;
; woa0 RECORDS every rail φ E6 admits as a condition-tree leaf and declines loudly
; if a LATER claim SELECT-CHAINS it. The observation is gated on `!BoolAlg`, and
; this file is why. `isStructuralRailPhi` matches "every incoming is a rail CALL or
; an `i1` CONSTANT", so it ALSO matches an ALL-CONSTANT 2-incoming `i1` φ — and for
; that shape `convertPhis` takes the BOOLEAN-ALGEBRA path, which yields an
; in-grammar and/or tree that every downstream consumer already accepts. Without
; the conjunct this module DECLINES.
;
; THE COMPOSITION, and every step of it is measured, not asserted:
;   1. region A (entry `%J`) claims. Its condition is `and(%cphi, %c3)`; `%cphi`
;      sits at A's OWN ENTRY, so M4's placement conjunct admits it and woa0
;      COMMITS it to the cross-claim record (instrumented commit log:
;      `commit fn=probe phiblk=J phi=%cphi entry=J merge=Am`);
;   2. region B (entry `%head`) then claims — its merge IS `%J`, which carries two
;      φs, so the W anti-overlap witness lets it through — and `convertPhis(%J)`
;      converts `%cphi`;
;   3. that conversion takes the BOOLEAN-ALGEBRA path, because `%cphi`'s incomings
;      are `i1` constants and pass `convertPhis`' scope-less `isBooleanCondTree`
;      re-check. No `select i1` is minted, nothing goes off-grammar, and the
;      module compiles.
;
; ⚠ BLOCK ORDER IS LOAD-BEARING AND IS NOT COSMETIC. The driver iterates
; `for (BasicBlock &BB : F)`, so `%J` must sit textually BEFORE `%head` or region B
; claims first and there is no recorded φ to convert. `%pre` is an unconditional
; entry block for the same reason — it keeps the function's first block from being
; region B's entry. Re-derive this if the file is ever reformatted.
;
; ⚠ AND THE SECOND φ IN `%J` IS LOAD-BEARING TOO. With `%cphi` alone, region B
; leaves at `gate=W-witness` (one merge φ with two incomings satisfies no claim
; witness), `convertPhis(%J)` never runs, and the file silently stops testing
; anything while still passing. That is the vacuity trap this project keeps paying
; for; `%dphi` is what closes it and it is measured, not argued.
;
; NON-VACUITY, MEASURED BY MUTATION (both directions), against a build with the
; `!BoolAlg` conjunct dropped:
;   ORACLE (git 18d18728, pre-woa0)          -> rc=0, and its lowered module is
;                                               BYTE-IDENTICAL to this one
;   woa0 as shipped                           -> rc=0, byte-identical to the ORACLE
;   woa0 with `!BoolAlg` removed              -> rc=1, `… rail phi converted by a
;                                               later flatten`  <- an A→D
; ⚠ It is the ONLY witness in the tree for that conjunct: with it removed, a
; whole-corpus A/B over all 2156 committed fixtures reports **0 movers** (null
; control run first). A predicate whose corpus population is empty is pinned by
; this file or by nothing.
;
; bd r2j3.32: the grep counts of `cqrt_free`/`cqrt_x`/`cqrt_copy_*` grew by
; exactly the discharged merge rails (each: two reversed copies, two `cqrt_x`,
; one free); every other count is unchanged.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: grep "call i32 @cqrt_alloc_i1(" %t.cqd0.ll | count 3
; bd dm7f.81: the six constant-arm source rails are gone (each arm is now a
; `cqrt_xorc_i32_controlled` literal), so 10 -> 4 allocs and 8 copies -> 8 xorcs.
; RUN: grep "call i32 @cqrt_alloc_i32(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 8
; RUN: grep "call void @cqrt_x(" %t.cqd0.ll | count 8
; RUN: grep "call void @cqrt_toffoli(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_xorc_i32_controlled(" %t.cqd0.ll | count 8
; RUN: not grep "call void @cqrt_copy_i32_controlled(" %t.cqd0.ll
; RUN: grep "@cqrt_measure" %t.cqd0.ll | count 5
; RUN: grep "@cqrt_ry" %t.cqd0.ll | count 4
; RUN: grep "@cq_template_icmp_sgt_i32_hl(" %t.cqd0.ll | count 4
; RUN: grep "@cq_template_icmp_sgt_i32(" %t.cqd0.ll | count 3
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=REV < %t.cqd0.ll
;
; ⚠ THE COUNTS ARE EXACT AND ARE THE ASSERTION. A prefixed positive alone means
; "at least N" — the increment-2 round-1 lesson, where an injected NINTH controlled
; copy was missed by all four prefixes. The negatives below are what pin the
; boolean-algebra path specifically: a SELECT CHAIN would leave a `select i1` and
; the conversion of `%cphi` would leave nothing at all.
; bd r2j3.32 (R11 round 1, item 7) — THE REVERSAL, pinned with CAPTURED handles:
; the merge rail of the round-2 select (%out10, minted in a block laid out
; below its readers) is reversed right after its last reader, the strip that
; reads it: both writes (controlled xor-immediates since bd dm7f.81) re-applied in reverse under its still-live flag, the
; flag's strip deferred behind them, then the same rail freed.
; REV-LABEL: define i32 @probe(
; REV:      call void @cqrt_xorc_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 6)
; REV:      call void @cq_template_icmp_sgt_i32_unc(i32 %[[P_H_CMP4:[a-zA-Z0-9_.]+]], i32 %[[P_H:[a-zA-Z0-9_.]+]], i32 %[[P_OUT10:[a-zA-Z0-9_.]+]])
; REV-NEXT: call void @cqrt_x(i32 %[[P_H_CMP9:[a-zA-Z0-9_.]+]])
; REV-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[P_H_CMP9]], i32 %[[P_OUT10]], i32 2)
; REV-NEXT: call void @cqrt_x(i32 %[[P_H_CMP9]])
; REV-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[P_H_CMP9]], i32 %[[P_OUT10]], i32 1)
; REV-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[P_H_CMP9]], i32 %[[P_H]], i32 9)
; REV-NEXT: call void @cqrt_free(i32 %[[P_H_CMP9]])
; REV-NEXT: call void @cqrt_free(i32 %[[P_OUT10]])
; CHECK: cqrt_alloc_i32
; NEG-NOT: select i1
; NEG-NOT: phi i1
; NEG-NOT: rail phi converted
;
; ⚠ RETIREMENT TRIGGER (L8). If woa0's observation ever stops being gated on the
; conversion PATH — if it asks a placement question again, or is moved to the claim
; — re-derive this file from scratch: it is the cell that separates "a recorded φ
; was converted" from "a recorded φ was converted UNSAFELY", and those are not the
; same predicate. Do not delete it to make a stricter fence green.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)

define i32 @probe(i32 %u) {
pre:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br label %head
J:
  %cphi = phi i1 [ true, %P1 ], [ false, %P2 ]
  %dphi = phi i32 [ 1, %P1 ], [ 2, %P2 ]
  %c3 = icmp sgt i32 %q, %dphi
  %t  = and i1 %cphi, %c3
  br i1 %t, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 5, %J ]
  %v2 = phi i32 [ 3, %Aarm ], [ 6, %J ]
  br label %Bm
head:
  br i1 %c, label %P1, label %P2
P1:
  br label %J
P2:
  br label %J
Bm:
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %v2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
