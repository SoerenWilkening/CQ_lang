; control_inplace_ry_reject_tape_continued.ll — DECLINE. The RED half of the
; F-L5-2 red-green pair: the accept `control_inplace_ry_tape_after_region.ll`
; with a genuine CONTINUATION after the tape write.
;
;     if (q == 5) { r = cq_theta(r, .9); }
;     printf("%d\n", r);            /* 7.6 tape write */
;     r = cq_theta(r, .125);        /* the lineage genuinely continues */
;     return cq_measure(q) + cq_measure(r);
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review finding F-L5-2.
; This is what makes the accept a repair rather than a hole: the 7.6 guard is a
; TERMINALITY guard, and here the taped value is genuinely non-terminal — a later
; in-place Ry moves the register the tape claims to have recorded. Both binaries
; (HEAD and the pre-Inc-3 oracle) decline it with the identical string, so the
; guard did not lose its subject; it stopped firing on a continuation that only
; M-α's RAUW had manufactured.
;
; VERBATIM `clang -O1` output for the C above.
;
; Guard: IOLowering's output-sink continued-lineage predicate. It OWNS the exact
; `Msg` string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 1.250000e-01)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: error{{.*}}cq I/O output sink: tainted argument has continued lineage (only a terminal or measured value may be taped)
