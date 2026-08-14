; lowering_reject_qram_read_under_control_urem_wide.ll — DECLINE (bd s6ao,
; Rule-13 round 2). *** THIS ONE PINS A CRASH, NOT A VERDICT. ***
;
; `unconditionalMax`'s `URem` rule computes `(C - 1).zext(Wide)` where `Wide` is
; 65 (the caller has already forced the index to the 64-bit pointer-index width)
; and `C`'s APInt width is the UREM's OWN type width. An `iN` urem with N > 65,
; reached through the `Trunc` rule, therefore made that a DOWN-extension —
; `APInt::zext` memcpy's `getNumWords(N)` words into a 2-word buffer and then
; memsets with a wrapped negative count.
;
; MEASURED on the draft: EXIT 139 (SIGSEGV), 3 runs of 3, with the symbolized
; stack naming
;   llvm::APInt::zext <- cq::unconditionalMax <- cq::indexBoundIsPoisonConditional
;                     <- qromIndexKnownInBounds <- classifyQromReadUnderControlImpl
;                     <- cq::flattenPredMuxRegions
; i.e. the pass segfaulting inside its own bounds proof. The preceding write is a
; heap overrun, so this is a memory-safety defect independent of any QROM verdict.
; Every other extension site in PoisonFacts.cpp was already width-guarded; this
; one was not, which is why no other rule exhibits it.
;
; NOT HAND-IR-ONLY: `clang -O1 -std=c23` on ordinary `unsigned _BitInt(256)` code
; emits `urem i256 %x, <const>`, and wide integers (`__int128`/`_BitInt`) are
; explicitly in Phase-7.1 scope, so the construct is one the pass must survive.
; i128 alone does NOT crash (2 source words into a 2-word result), so the fixture
; uses i256 deliberately — an i128 probe would pass while pinning nothing.
;
; WHAT A REGRESSION LOOKS LIKE: not a wrong CHECK match but a non-zero exit from
; a signal. `not` treats a crash as success on exit code alone, so the CHECK line
; is what distinguishes "declined loudly" from "died" — a fixture asserting only
; the exit code would go green on the SIGSEGV it exists to prevent.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %w = zext i64 %bits to i256
  %rm = urem i256 %w, 1000                 ; C is 256 bits wide; Wide is 65
  %sx = trunc i256 %rm to i64
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

; A LOUD DECLINE, not a signal. The message text is mirrored
; character-for-character from `kMsgQromUnderControlBounds`.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
