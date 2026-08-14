; lowering_reject_qram_read_under_control_nneg_bound.ll — DECLINE (bd s6ao).
; THE `nneg` CHANNEL, WHICH `UseInstrInfo=false` STRUCTURALLY CANNOT REACH.
;
; `zext nneg i8 %t8 to i64` promises the SOURCE is non-negative as a signed i8,
; which tightens the result's max from 255 to 127 — and 127 < 192 is the entire
; bound. If the promise lies the value is poison, so the bound is exactly the
; poison-conditional kind this proof may not use.
;
; *** WHY THIS NEEDS ITS OWN FENCE AND NOT JUST `UseInstrInfo=false`. *** LLVM
; 19's `InstrInfoQuery` (SimplifyQuery.h:25-59) wraps EXACTLY five accessors —
; `getMetadata`, `hasNoUnsignedWrap`, `hasNoSignedWrap`, `isExact`,
; `hasNoSignedZeros`. There is NO accessor for `nneg`, so `UseInstrInfo=false`
; cannot gate it and `computeKnownBits` consults it identically either way
; (measured: `max=127 nonneg=1 => PROVABLE=YES` on BOTH settings). This fixture
; is the arm-kill for the explicit `indexBoundIsPoisonConditional` walk; deleting
; that walk while keeping the `UseInstrInfo` argument leaves this module
; ACCEPTING an unmasked out-of-bounds read, with every other QROM fixture green.
;
; THE TABLE SIZE IS CHOSEN, NOT ARBITRARY. 192 is (a) NON-power-of-two, so no
; sound `NeedsMask` fallback exists and the lost bound reaches the loud decline
; rather than a mask, and (b) inside the load-bearing window `2^(N-1) < Count <=
; 2^N` for N=8 — i.e. 128 < 192 <= 256 — which is precisely where `nneg`'s extra
; bit decides the verdict. Outside that window the flag changes nothing and the
; fixture would pass for the wrong reason.
;
; CONTROL: deleting the single token `nneg` makes the max 255, which is >= 192,
; so the module declines with this same diagnostic for an UNRELATED reason. The
; flag is therefore the sole discriminator between accept and decline on the
; pre-fence plugin, which is what makes this a real arm-kill.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t192 = internal unnamed_addr constant [192 x double] zeroinitializer
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %t8 = trunc i64 %bits to i8
  %sx = zext nneg i8 %t8 to i64            ; nneg: max 255 -> 127, the whole bound
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [192 x double], ptr @t192, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hd = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hd, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Mirrored character-for-character from `kMsgQromUnderControlBounds`.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
