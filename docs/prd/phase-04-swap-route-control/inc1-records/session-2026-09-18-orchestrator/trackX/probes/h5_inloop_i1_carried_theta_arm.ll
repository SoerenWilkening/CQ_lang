; h5_inloop_i1_carried_theta_arm.ll — Track X (bd x5fp), session 2026-09-18.
; THE OWNER'S SCALAR LOOP WITH THE `i8` WIRE REMOVED — i.e. what x01 would look
; like if bd `r903`'s trunc/zext transparency had landed. The arm is now a BARE
; `@cq_theta_i1` call, so `inPlaceRotationArmTheta` (R1) claims it and the VALUE
; path — the only path that consults §3c — is never entered.
; It answers the scoping question "is the §3c clobber fence on the owner's
; critical path AT ALL, or is it an artefact of the `_Bool` memory type?"
define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %b = phi i1 [ false, %entry ], [ %bm, %latch ]
  %a = phi i32 [ 5, %entry ], [ %anext, %latch ]
  %c = icmp sgt i32 %a, 2
  br i1 %c, label %arm, label %merge

arm:
  %b1 = call i1 @cq_theta_i1(i1 %b, double 5.000000e-01)
  br label %merge

merge:
  %bm = phi i1 [ %b1, %arm ], [ %b, %hdr ]
  %asub = add nsw i32 %a, -3
  %anext = select i1 %bm, i32 %asub, i32 %a
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 2
  br i1 %done, label %exit, label %hdr

exit:
  %m1 = call i32 @cq_measure_si32(i32 %anext)
  %m2 = call i1 @cq_measure_i1(i1 %bm)
  %m2z = zext i1 %m2 to i32
  %s = add nsw i32 %m1, %m2z
  ret i32 %s
}

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)
