; control_swap_reject_abort_derived_copy_live.ll — bd test_C_libtooling-x61g
; DECLINE twin of control_swap_abort_park_inplace_ry.ll: a DERIVED COPY of the
; routed register, minted before the park and live after it.
;
; SOURCE (clang -O1, attributes trimmed):
;     int q = u; cq_theta(&q,.5); int t = q + 7; cq_measure(t);
;     if (q > 5) abort(); return cq_measure(t);
; The pre-park `cq_measure(t)` is what keeps `-O1` from sinking `t` into the
; remainder; without it `t` is computed AFTER the park (a different shape).
;
; `%3 = add %2, 7` is an out-of-place template result: a FRESH rail derived from
; Q, not a name of Q's rail. The park routes Q's rail only, so `%3` is an
; unparked register live across the park and the guard stays loud. Its
; `railWireNamesBackward` closure is `{%3}` (an `add` outside `InPlaceRailOps`
; is not crossed), so Q is not on its wire.
; MUTANT this file kills: "same register" asked as same ROOT MINT
; (`railChainRootMint(V) == railChainRootMint(Q)`), which peels the `add` by its
; dtzb SHAPE to `%2` and calls the fresh rail Q's.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = add nsw i32 %2, 7
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %5 = icmp sgt i32 %2, 5
  br i1 %5, label %6, label %7
6:
  tail call void @abort()
  unreachable
7:
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %8
}
