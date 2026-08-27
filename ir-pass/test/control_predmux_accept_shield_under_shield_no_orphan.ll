; control_predmux_accept_shield_under_shield_no_orphan.ll — ACCEPT (bd kqqv).
; The SECOND recursion path into `canonicalizePred`, and the row that shows the
; retired "root-level is clean" claim is a statement about DEPTH and not about
; who the branch condition is.
;
; THE SHAPE. The branch condition IS a poison-shielded short-circuit select — so
; `run()`'s `track(BI->getCondition())` covers it, exactly as bd `qesi` measured
; — but its CONDITION operand is ANOTHER shield:
;     %in = select i1 %b, i1 %c, i1 false      ; stranded: nothing tracks it
;     %sc = select i1 %in, i1 %d, i1 false     ; the root: tracked by run()
; `canonicalizePred` rewrites the root into `and(canonicalizePred(%in), %d)` and
; recurses into `%in` through `Sel->getCondition()` — a DIFFERENT operand path
; from the `and`/`or` recursion the sibling fixture exercises, and one that no
; committed module reached before this file. Pre-fix it emitted the same dead 4.4
; controlled-copy merge: 2 `cqrt_copy_i1_controlled` on an `%out` that is written
; twice and never read, plus a never-freed `%selop` and an `icmp_ne` flag with no
; `_unc` and no `cqrt_free` (measured on this module at 3319975).
;
; See control_predmux_accept_nonroot_shield_no_orphan.ll for the full account,
; the depth table, and why neither shipped gate can see this.
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
  %b = icmp slt i32 %q, 100
  %c = icmp ne i32 %q, 7
  %d = icmp eq i32 %q, 42
  %in = select i1 %b, i1 %c, i1 false        ; the stranded inner shield
  %sc = select i1 %in, i1 %d, i1 false       ; the root shield (tracked by run())
  br i1 %sc, label %arm, label %merge        ; arm = TRUE successor

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

; Both shields collapse into one and-tree over the three original compare leaves,
; each minted, uncomputed and freed:
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 100)
; CHECK:     call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 7)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 42)
; CHECK:     call void @cqrt_toffoli
; CHECK:     call void @cqrt_copy_i32_controlled
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc
; CHECK:     call void @cqrt_free

; No i1 DATA exists in this function, so any i1 controlled copy is the stranded
; inner shield's dead merge:
; SWEPT-NOT: cqrt_copy_i1_controlled
