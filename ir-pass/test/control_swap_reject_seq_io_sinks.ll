; control_swap_reject_seq_io_sinks.ll — DECLINE (bd hcrg decline partition): two
; sequential tainted-condition regions whose arms are I/O SINKS, not gates.
;
; `if(q>5) putchar(q); if(q>3) putchar(q);` — the shape IOSinkLowering.cpp's own
; OVERLAP guard names in its comment ("one diamond's merge is the next diamond's
; pred (sequential `if(q)printf; if(q)printf`)"). That guard deliberately does
; NOT lower either candidate; it LEAVES them both "for `detectControlRegions` to
; decline loudly". Before hcrg that deferral was satisfied by the blanket
; merge-hosted-branch check at the top of `recoverRegion`.
;
; hcrg moved that check to the BOTTOM, so this file exists to prove the deferral
; is still honoured — by a different route, with the same outcome. A side-effect
; arm contributes NO merge phi, so `soleMergePhi` returns null, every recognizer
; fails, control reaches the relocated `Nested` return, and `recoverRegionTree`
; declines. Loud, exit non-zero, nothing lowered.
;
; This is the one interaction hcrg creates that no other fixture covers:
; `lowerControlledIOSinks` runs BEFORE `detectControlRegions`
; (CQLoweringPass.cpp:293 vs :321), so it is the FIRST stage whose "leave it for
; detection" contract depends on what detection still declines. If a future
; widening ever lets a phi-less sequential pair match a recognizer, this file
; goes red before anything reaches a user.
;
; (The sibling mix — an I/O sink followed by a PHASE region — declines earlier and
; louder inside IOSinkLowering itself: `conditional output is not a lowerable
; single-sink if(q) diamond`. Measured, not assumed.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @putchar(i32)

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %r1 = call i32 @putchar(i32 %q)
  br label %m1
m1:                                    ; no merge phi — a side-effect arm …
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm2, label %m2    ; … and the next region's tainted branch
arm2:
  %r2 = call i32 @putchar(i32 %q)
  br label %m2
m2:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
