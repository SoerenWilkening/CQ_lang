; lowering_reject_qram_read_under_control_range_attr.ll — DECLINE (bd s6ao).
; THE `range(lo,hi)` RETURN ATTRIBUTE — THE SPELLING LLVM 19 MIGRATED TO.
;
; `llvm.ctpop.i64`'s natural range is [0,64], which does not bound a 3-cell
; table. The `range(i64 0, 2)` return attribute narrows it to [0,1], and THAT is
; the whole bound. A `range` attribute is a promise: if it lies, the value is
; poison — so the bound holds only modulo poison, which this proof's speculated
; read may not rely on.
;
; *** THE TRAP THIS PINS. *** LLVM 19 MIGRATED call-site `!range` METADATA to the
; `range` ATTRIBUTE. `UseInstrInfo=false` gates `getMetadata` and therefore
; closes the RETIRED spelling, while leaving the CURRENT one wide open —
; `InstrInfoQuery` has no `getRange` accessor at all. So a fix that reasons "we
; turned instruction info off, ranges are handled" closes the spelling nothing
; emits any more and misses the one clang actually produces. Measured on the
; pre-fence plugin: the `!range` metadata form DECLINED while all three attribute
; forms (call-site, `declare`, and a PARAMETER attribute) ACCEPTED.
;
; *** HOW IT IS ACTUALLY CLOSED — AND IT IS NOT BY TESTING FOR THE ATTRIBUTE. ***
; An earlier header here claimed `indexBoundIsPoisonConditional` "tests
; `CallBase::getRange()` explicitly, and also tests `Attribute::Range` on an
; `Argument`". IT DOES NEITHER; `grep getRange ir-pass/src/PoisonFacts.cpp` is
; empty. Those tests belonged to a presence-scanning draft that was deleted for
; over-declining nine libm goldens.
;
; The real mechanism is stronger precisely because it never names the attribute:
; `unconditionalMax` bounds `ctpop` by its OPERAND'S BIT WIDTH (64), so the
; attribute's [0,2) is simply never consulted, and 64 >= 3 refuses the bound. A
; non-bit-count call falls to `full()` for the same reason, and an `Argument` is
; an ordinary non-Instruction leaf. Any future poison-carrying attribute LLVM
; invents is closed the same way, with no edit — which is the whole argument for
; asking "can this be bounded WITHOUT such facts" instead of enumerating them.
;
; 3 cells is non-power-of-two, so no sound `NeedsMask` fallback exists and the
; lost bound reaches the loud decline (contrast
; control_predmux_accept_qrom_read_cttz_masked.ll, where a pow2 table keeps the
; lowering by masking instead).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i64 @llvm.ctpop.i64(i64)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = call range(i64 0, 2) i64 @llvm.ctpop.i64(i64 %bits)   ; the attribute IS the bound
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [3 x double], ptr @t3, i64 0, i64 %sx
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
