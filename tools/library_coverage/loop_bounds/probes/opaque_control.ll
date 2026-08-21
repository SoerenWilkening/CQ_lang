; POSITIVE + NEGATIVE CONTROL for `cq-spike-opaque` (bd 19v3).
;
; The 66rz lesson: a discriminator that never discriminates is not evidence. The
; opacification probe's job is to separate a bound that is STRUCTURAL (survives
; losing every outside value => positive evidence for bucket A) from one that
; rests on OUTSIDE PROVENANCE (dies => needs the semantic leg before it may be
; called total). This file contains one of each, so the probe is measured in both
; directions before any cell result is read off it.
;
;   $LLVM/opt -load-pass-plugin build/LoopBoundProbe.so -passes=cq-spike-scev   \
;       -disable-output probes/opaque_control.ll
;   $LLVM/opt -load-pass-plugin build/LoopBoundProbe.so -passes=cq-spike-opaque \
;       -disable-output probes/opaque_control.ll
;
; MEASURED, LLVM 19.1.7 (Homebrew), 2026-08-21:
;
;   fn                  baseline constant-max   opacified   probe verdict
;   @provenance_masked  6   (trip 7)            -2 (vacuous)  DIES   <- must die
;   @structural         32  (trip 33)           32 (trip 33)  SURVIVES <- must not
;
; @provenance_masked's bound exists only because `and i32 %n, 7` pins the limit's
; range to [0,8) OUTSIDE the loop. @structural's is the shl-until-sign bit-width
; fact and depends on nothing outside. Those are exactly the two cases the 19v3
; (A)/(B) split turns on.
;
; --- A SEPARATE MEASUREMENT, recorded because it narrows where bucket (B) can
; --- come from at all, and because assuming the opposite would be the natural
; --- mistake.
; @guarded_lessthan carries a dominating entry guard `icmp ult %n, 8` that makes
; the true trip count <= 7. LLVM 19's `getConstantMaxBackedgeTakenCount` DOES NOT
; USE IT: the baseline is already the vacuous `-2` (trip 4294967295), before any
; opacification. So on this shape the guard-conditional bound the 19v3 bucket (B)
; warns about never forms in the first place — the risk arrives through outside
; VALUE RANGE (@provenance_masked), not through a dominating branch.
;
; Do not over-read that. It is one shape, measured once. It shows this guard was
; not consulted; it does not establish that SCEV never consults a guard, and the
; f80 `manl|manh != 0` case in SPIKE-8zj2 §2 remains a guard-conditional bound in
; FACT even though SCEV reports nothing for it. The probe stays one-sided: a
; SURVIVING bound is evidence of structure; a DYING one is a question, not a
; verdict.

define i32 @provenance_masked(i32 %n) {
entry:
  %m = and i32 %n, 7
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %inc = add nuw nsw i32 %i, 1
  %cmp = icmp ult i32 %inc, %m
  br i1 %cmp, label %loop, label %done

done:
  ret i32 %i
}

define i32 @structural(i32 %x) {
entry:
  br label %loop

loop:
  %v = phi i32 [ %x, %entry ], [ %sh, %loop ]
  %b = phi i32 [ 0, %entry ], [ %nb, %loop ]
  %sh = shl i32 %v, 1
  %nb = add i32 %b, 1
  %cmp = icmp sgt i32 %sh, 0
  br i1 %cmp, label %loop, label %done

done:
  ret i32 %nb
}

define i32 @guarded_lessthan(i32 %n) {
entry:
  %c = icmp ult i32 %n, 8
  br i1 %c, label %ph, label %done

ph:
  br label %loop

loop:
  %i = phi i32 [ 0, %ph ], [ %inc, %loop ]
  %inc = add nuw nsw i32 %i, 1
  %cmp = icmp ult i32 %inc, %n
  br i1 %cmp, label %loop, label %done

done:
  %r = phi i32 [ 0, %entry ], [ %i, %loop ]
  ret i32 %r
}

; --- THE THREE HOLES, as runnable counterexamples (bd 19v3 adversarial round) ----
; Each of these reports SURVIVES. None of them is evidence of anything. They are
; committed so the probe's limits are reproducible rather than only written down.

; HOLE 1a — a small, non-negative, CONSTANT bound (C1+C2+C3 all pass) resting
; entirely on an object defined outside the loop, carried by a POINTER. The
; collector replaces only integer/fp values, so this opacifies ZERO uses and then
; prints SURVIVES. The NULL-MUTATION banner is what makes it visible.
; MEASURED: baseline constant-max 7 / trip 8; opacified 7 / trip 8; 0 uses replaced.
define i32 @ptr_small() {
entry:
  %buf = alloca [8 x i8], align 1
  %end = getelementptr inbounds i8, ptr %buf, i64 8
  br label %loop

loop:
  %p = phi ptr [ %buf, %entry ], [ %np, %loop ]
  %n = phi i32 [ 0, %entry ], [ %nn, %loop ]
  %np = getelementptr inbounds i8, ptr %p, i64 1
  %nn = add i32 %n, 1
  %c = icmp ne ptr %np, %end
  br i1 %c, label %loop, label %done

done:
  ret i32 %nn
}

; HOLE 1b — the same, carried by !range metadata on an in-loop load. Metadata is
; never touched. MEASURED: 7 / 8 both before and after, 0 uses replaced.
@g = external global i32
define i32 @global_range_bound() {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %lim = load i32, ptr @g, align 4, !range !0
  %inc = add nuw nsw i32 %i, 1
  %c = icmp ult i32 %inc, %lim
  br i1 %c, label %loop, label %done

done:
  ret i32 %i
}
!0 = !{i32 0, i32 9}

; HOLE 3 / C5 — the bound is small, non-negative and constant, and FALSE. This is
; the ilogb shl-until-sign idiom with the shift amount equal to the type width:
; `shl i32 %v, 32` is POISON and the loop never terminates, yet SCEV still reports
; the width. Opacification says SURVIVES. Only C5 (1 <= amount <= W-1) rejects it,
; which is why "magnitude alone decides vacuity" is wrong.
; MEASURED: constant-max 32 / trip 33.
define i32 @shift_width_poison(i32 %x) {
entry:
  br label %loop

loop:
  %v = phi i32 [ %x, %entry ], [ %sh, %loop ]
  %b = phi i32 [ 0, %entry ], [ %nb, %loop ]
  %sh = shl i32 %v, 32
  %nb = add i32 %b, 1
  %c = icmp sgt i32 %sh, 0
  br i1 %c, label %loop, label %done

done:
  ret i32 %nb
}

; C2/C3 WIDTH TRAP — a vacuous wrapped bound at i6: 2^6-2 = 62, so the trip bound
; is 63, which PASSES a "small <= 64" test. It is caught only by the signed
; rendering `-2`, i.e. by C2 — the condition that fails at i64. Neither C2 nor C3
; is a vacuity test on its own; they cover for each other, and on the libm corpus
; that works only because every width there is >= 32.
define i32 @vacuous_narrow(i6 %n) {
entry:
  br label %loop

loop:
  %i = phi i6 [ 0, %entry ], [ %inc, %loop ]
  %inc = add i6 %i, 1
  %c = icmp ult i6 %inc, %n
  br i1 %c, label %loop, label %done

done:
  ret i32 0
}
