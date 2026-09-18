; control_swap_value_reject_arm_cone_store.ll — DECLINE: the cone's (K2)
; conjunct (bd test_C_libtooling-fn1q, increment 1).
;
; `if (q > 5) { k = 7; p += 3; }` — a `store` beside the chain. It was a stray op
; before the increment and it is still refused, because a write-arm belongs to the
; 7.5 GUARDED-STORE owner, whose whole reversal spine would stop running if this
; classifier claimed the region instead.
;
; ⚠ THIS FILE IS THE CONTAINMENT PIN FOR A WIDENING THAT LOOKS INNOCENT. The cone
; rule reads "a pure classical arm op may be hoisted"; a `store` is neither pure
; nor hoistable, and reordering it above a quantum-controlled branch would also
; make it unconditional — which for a WRITE is a visible change to the classical
; program, not merely a speculation question. (K2) is what keeps the two apart.
;
; ⚠ RETIREMENT TRIGGER (inherited from `MergePhiPeel`'s P10, and it applies here
; verbatim): the narrow `mayWriteToMemory` spelling is sufficient only while the
; 7.5 guarded store is the ONLY owner in the tree that accepts a writing arm. The
; day any classifier accepts a `MemIntrinsic` or a writer call, (K2) must be
; re-derived with it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  store i32 7, ptr @k, align 4      ; (K2) — a WRITE beside the chain
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: impure value arm under quantum control
