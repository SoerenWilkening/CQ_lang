; lowering_measure_classical_accept.ll — ACCEPT: `cq_measure` of a value that never
; became quantum lowers to THE VALUE ITSELF. bd test_C_libtooling-21mg.
;
; Measuring a classical value is the identity on the quantum state and its outcome
; is that value, so the call is replaced by its operand: NO runtime symbol, NO
; gate, NO `cqrt_alloc_<W>` and NO trace line. Refusing it was an over-decline
; (`cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` — the
; ORACLE's verdict on EVERY function below, which is why this whole file is RED on
; `main` e96f89c / 86c0d25).
;
; THIS MODULE HAS NO `cq_theta` AT ALL, deliberately: it is the purely-classical
; corner, where the `NOALLOC` / `NOMEAS` prefixes below are exact rather than
; windowed. The pass is NOT a passthrough here — `taint.MeasureCalls` is non-empty,
; so `CQLoweringPass::run`'s early-out does not fire and `lowerMeasures` does the
; work (see it with `; MOD` below: the module still contains the seven bodies).
;
; ⚠ `cqrt_alloc` IS THE POINT OF THE `NOALLOC` PREFIX, not decoration: minting a
; qubit for a value the taint analysis says is classical is the f64/angle
; miscompile family (Rule 3 / Key Prohibitions). `@f_double` is the explicit
; f64-width member of that family — an `fmul double` whose result is CLASSICAL
; must not become `cqrt_alloc_f64`.
;
; COVERAGE, one function per operand species that plain C can produce:
;   @f_const_i1    a constant `i1`                      (`bool b = 0;` — the owner's b1)
;   @f_const_i32   a constant `i32`                      (`int a = 7;`)
;   @f_ssa_i32     classical arithmetic of an argument    (`n + 3`)
;   @f_double      classical fp arithmetic, f64 width     (`x * 2.0`)
;   @f_phi         verdict (b): a classical `phi`         (an if/else -O1 did not fold)
;   @f_select      verdict (b): a classical `select`      (what -O1 usually emits instead)
;   @f_arg         an unmodified function argument, i64 width
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MOD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMEAS < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOALLOC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINTR < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare double @cq_measure_f64(double)
declare i64 @cq_measure_sll(i64)

define i1 @f_const_i1() {
entry:
  %m = call i1 @cq_measure_i1(i1 false)
  ret i1 %m
}
; CHECK-LABEL: define i1 @f_const_i1()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i1 false

define i32 @f_const_i32() {
entry:
  %m = call i32 @cq_measure_si32(i32 7)
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_const_i32()
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i32 7

define i32 @f_ssa_i32(i32 %n) {
entry:
  %a = add nsw i32 %n, 3
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_ssa_i32(i32 %n)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %a = add nsw i32 %n, 3
; CHECK-NEXT:    ret i32 %a

define double @f_double(double %x) {
entry:
  %y = fmul double %x, 2.000000e+00
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
; CHECK-LABEL: define double @f_double(double %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %y = fmul double %x, 2.000000e+00
; CHECK-NEXT:    ret double %y

define i32 @f_phi(i1 %c) {
entry:
  br i1 %c, label %t, label %f
t:
  br label %j
f:
  br label %j
j:
  %p = phi i32 [ 9, %t ], [ 1, %f ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_phi(i1 %c)
; CHECK:         %p = phi i32 [ 9, %t ], [ 1, %f ]
; CHECK-NEXT:    ret i32 %p

define i32 @f_select(i1 %c, i32 %a, i32 %b) {
entry:
  %s = select i1 %c, i32 %a, i32 %b
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
; CHECK-LABEL: define i32 @f_select(i1 %c, i32 %a, i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %s = select i1 %c, i32 %a, i32 %b
; CHECK-NEXT:    ret i32 %s

define i64 @f_arg(i64 %n) {
entry:
  %m = call i64 @cq_measure_sll(i64 %n)
  ret i64 %m
}
; CHECK-LABEL: define i64 @f_arg(i64 %n)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i64 %n

; ── WHOLE-FILE PREFIXES (Rule 12 (a): counts and negatives get their OWN prefix,
; never a window inside another one) ─────────────────────────────────────────────
;
; all seven bodies survive — this is a lowering, not a deletion, and the module is
; not a passthrough:
; MOD: define i1 @f_const_i1()
; MOD: define i32 @f_const_i32()
; MOD: define i32 @f_ssa_i32(
; MOD: define double @f_double(
; MOD: define i32 @f_phi(
; MOD: define i32 @f_select(
; MOD: define i64 @f_arg(
;
; NOT ONE measurement gate anywhere in the module:
; NOMEAS-NOT: cqrt_measure_
;
; NOT ONE rail minted anywhere — including at f64 (the angle/f64 miscompile
; family) and including the `declare` a lazy `measureRtFn` would have left behind:
; NOALLOC-NOT: cqrt_alloc
; NOALLOC-NOT: cqrt_ry
; NOALLOC-NOT: cqrt_free
; NOALLOC-NOT: cq_template_
;
; every front-end intrinsic call is GONE (Rule 1's checked postcondition,
; `declineSurvivingIntrinsicCalls`, would otherwise be loud):
; NOINTR-NOT: call{{.*}}@cq_measure_
;
; and the whole module accepts — no decline of any kind on stderr:
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: undef/poison literal
