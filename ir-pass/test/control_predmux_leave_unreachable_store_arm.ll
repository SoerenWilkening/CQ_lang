; control_predmux_leave_unreachable_store_arm.ll — LEAVE→DECLINE (bd 20xt.5 (d)
; adversarial probe): the accept twin, but one exhaustive-switch case arm holds
; a STORE. Tolerating the `unreachable` default (d) must NOT relax E4 — a store
; inside the claimed region still makes PredMux LEAVE (E4: pure speculatable
; dataflow only; no memory writes). Pins that (d) widened ONLY the merge
; computation + `unreachable` arm terminators, never the body-purity ladder.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The store makes PredMux LEAVE at E4 (`gate=E4-dataflow`, verified), so it is
; never flattened; `declineTaintEscapes` then fires the precise store diagnostic.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@g = internal global i32 0

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %sp = icmp sgt i32 %q, 100
  br i1 %sp, label %special, label %quad
special:
  %s = mul i32 %q, 2
  br label %merge
quad:
  %m = and i32 %q, 3
  switch i32 %m, label %dead [
    i32 0, label %c0
    i32 1, label %c1
    i32 2, label %c2
    i32 3, label %c3
  ]
c0:
  %a0 = add i32 %q, 10
  br label %merge
c1:
  store i32 %q, ptr @g, align 4                ; a MEMORY WRITE — E4 excludes it
  %a1 = mul i32 %q, 5
  br label %merge
c2:
  %a2 = xor i32 %q, 7
  br label %merge
c3:
  %a3 = sub i32 %q, 4
  br label %merge
dead:
  unreachable
merge:
  %rm = phi i32 [ %s, %special ], [ %a0, %c0 ], [ %a1, %c1 ], [ %a2, %c2 ], [ %a3, %c3 ]
  %r  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %r
}
; CHECK: error{{.*}}taint escape: tainted value stored to memory
