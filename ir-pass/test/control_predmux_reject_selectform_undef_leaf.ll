; control_predmux_reject_selectform_undef_leaf.ll — DECLINE (bd 3c6m.14.2).
; ARM: `valueCarriesUndef` at the CONE walk's leaf.
;
; A SECOND ARM OF THE SAME DEFECT, INDEPENDENT OF THE CALL CLAUSE AND REACHABLE
; WITH NO CALL AT ALL. `coneDefinedAfterFlagDrop` used to shortcut every
; non-Instruction with a bare `// Constant / Argument leaf — defined`. A literal
; `undef`/`poison` IS a Constant. So a shielded cone containing one was called
; defined and the region claimed. Measured on the pre-fix plugin, this module
; emitted — verify-clean, `opt` exit 0, free_pairing_check STRICT 6/6 —
;
;   %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 poison)
;
; an UNDEFINED classical literal in a runtime template's operand slot, which at
; the shipped -O0 stage 3 materialised as the garbage constant 73896:
;
;   cq_template_add_i32_hl(h0, 73896) -> h1
;
; That falsifies the natural defence of the call arm ("tainted args ⇒ Phase-6
; clone ⇒ runtime templates, so no IR poison survives"): here the poison survives
; as a template OPERAND, and the rail built from it is compared, conjoined and
; strip-uncomputed as if it were data.
;
; `PoisonValue` derives from `UndefValue`, so one `isa<UndefValue>` covers both
; spellings; the walk also descends constant aggregates/expressions.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = add i32 %q, poison               ; the poison CONSTANT leaf — no call
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

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

; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
