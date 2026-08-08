; control_predmux_reject_selectform_purecallee_inherentpoison.ll — DECLINE
; (bd 3c6m.14.2). ARM: the DELETED pure-callee disjunct in the shielded-cone
; call admission.
;
; THE ASYMMETRY THIS CLOSES. `coneDefinedAfterFlagDrop` licenses rewriting
; clang -O1's poison-shielded `select i1 %a, i1 %b, i1 false` into a plain
; `and`, which OBSERVES `%b` on the %a=false basis states the select never did.
; Its whitelist deliberately FAILS a variable-amount `shl/lshr/ashr` INLINE —
; an amount >= the bit width is INHERENT poison, there is no flag to drop and
; `stripPoisonCone` walks only `I->operands()`, so it never enters a callee
; body. That inline decline is pinned by
; lowering_predmux_leave_selectform_poisoncone.ll. Behind a CALL the very same
; op used to be ADMITTED, because the clause asked only
; `isSpeculatablePureCalleeBody` — a purity/totality/termination proof that
; reaches its answer through `isSpeculatableDataflow`, which admits Shl/LShr/AShr
; at any operand unconditionally.
;
; MEASURED PRE-EXISTING (bd adia Lever C), not introduced by the bd 3c6m.14.1
; i80 widening: this file has NO i80 anywhere and the pre-3c6m.14.1 and
; post-3c6m.14.1 plugins BOTH accepted it, emitting the same 5-`cqrt_toffoli`
; conjunction network. The pair of files to read together is this one and the
; inline twin above; they must give the same verdict for the same op, and before
; this fix they did not.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
e:
  %s = shl i32 %a, %a           ; INHERENT POISON for %a >= 32 — no flag to drop
  ret i32 %s
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false   ; clang -O1's poison-shielded `a && b`
  br i1 %sc, label %arm, label %merge

arm:                                    ; two merge phis = the W3 claim witness,
  %k = add i32 %q, 7                    ; without which the region leaves at
  %k2 = mul i32 %q, 3                   ; gate=W-witness and this file would
  br label %merge                       ; prove nothing (a no-power probe).

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The GATE is what makes this file discriminating: it must leave at the E6
; condition-tree claim — i.e. the shielded-cone proof said "not defined" and
; NOTHING was mutated — not at some later gate after a claim (the
; detect-before-mutate class).
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
