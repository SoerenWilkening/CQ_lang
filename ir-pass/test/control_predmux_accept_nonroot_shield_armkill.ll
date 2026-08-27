; control_predmux_accept_nonroot_shield_armkill.ll — ACCEPT (bd kqqv).
; ARM: the ARM-KILL for control_predmux_accept_nonroot_shield_no_orphan.ll.
; Byte-identical to it except that the two branch successors are SWAPPED, so the
; gate arm is the FALSE successor and the entry condition routes through
; `buildNegation` instead of `canonicalizePred`.
;
; WHY IT IS COMMITTED RATHER THAN LEFT AS A ONE-OFF. Its sibling's whole content
; is `SWEPT-NOT: cqrt_copy_i1_controlled`, and a CHECK-NOT can pass for the wrong
; reason: a future change that stops CLAIMING this region, that declines it, or
; that renames the symbol satisfies it trivially and nobody would know. This row
; pins the opposite half — the same shield, the same module, the polarity that
; was ALWAYS clean — so the pair localises the defect to the polarity rather than
; to the shape. Measured at 3319975, before the fix: 2 orphan controlled copies
; here on the TRUE arm, 0 here on the FALSE arm; 9 rail mints of which 5 left
; allocated, against 7 of which 3.
;
; THE MECHANISM THE PAIR ISOLATES. `buildNegation` REPLACES every node it
; visits, and bd `qesi` made it `track()` on entry; every arm then re-enters
; `buildNegation` on its operands, so the whole cone is tracked for free — the
; shield included, one level down or ten. `canonicalizePred` KEEPS most of what
; it visits and rebuilds only a shield, which is why its leak needed a shield at
; depth ≥ 1 to become visible at all.
;
; NOTE WHAT THIS ROW ASSERTS AND WHAT IT DOES NOT. The negation of
; `a && (b && c)` is leaf-inverted De Morgan, so the surviving predicates here
; are the INVERSES (`sle`/`sge`/`eq`), and the or-tree is built from cnot/cnot/
; toffoli rather than a bare toffoli. That difference is the point: the sibling
; asserts the absence of symbols this row proves are otherwise emitted, on a
; module that differs from it in exactly two tokens.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=SWEPT

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %c = icmp ne i32 %q, 7
  %inner = select i1 %b, i1 %c, i1 false     ; the NON-ROOT shield
  %sc = and i1 %a, %inner
  br i1 %sc, label %merge, label %arm        ; arm = FALSE successor (the only change)

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The INVERSE predicates are what survive here — no negation is skipped and no
; original predicate lingers, so the sibling's `sgt`/`slt`/`ne` positives are
; genuinely a property of the other polarity and not of the shape:
; CHECK:     call i32 @cq_template_icmp_sle_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     call i32 @cq_template_icmp_sge_i32_hl(i32 %[[H]], i32 100)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 7)
; CHECK:     call void @cqrt_cnot
; CHECK:     call void @cqrt_copy_i32_controlled
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc
; CHECK:     call void @cqrt_free

; This polarity never leaked, and must not start:
; SWEPT-NOT: cqrt_copy_i1_controlled
