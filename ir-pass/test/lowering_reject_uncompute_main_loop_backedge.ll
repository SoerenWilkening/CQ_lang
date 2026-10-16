; lowering_reject_uncompute_main_loop_backedge.ll — DECLINE (bd
; test_C_libtooling-r2j3.7; owner ruling owner-ruling-r2j3-7-main-dead-record-
; 2026-10-16). `main` runs the helper's dead-record discipline, so FreePoint's
; loop-backedge guard (§2.9) now speaks for a `main` terminal exactly as it does
; for a helper's.
;
; Source (clang -O1 -include CQ.h):
;   int main(int argc, char **argv) {
;     int a = 0; cq_theta(&a, .5); int t = a + 1;
;     for (int i = 0; i < argc; i++) printf("%d", t);
;     return 0; }
;
; Before r2j3.7 `main` short-circuited every handle to `Escaped` and this lowered
; with `t` left allocated (benign here: no later gate on `a`). A helper body
; declines with this message on the same base, character for character.
;
; ⚠ AN OVER-DECLINE, DISCLOSED (R1, L9). The in-loop users only READ `t` (tape
; writes), so a once-per-function discharge at the loop exit is sound; the guard
; keys on any use, where the M-B interior partition keys on WRITES. RETIREMENT
; TRIGGER: when FreePoint admits a read-only in-loop use of a pre-loop terminal
; (bd test_C_libtooling-8h7d.26), this file flips to an accept with the
; `_unc` + free after the loop.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}in function main{{.*}}cq uncompute: tainted handle live range crosses a loop backedge

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #0
  %4 = add nsw i32 %3, 1
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %7, label %6

6:
  ret i32 0

7:
  %8 = phi i32 [ %10, %7 ], [ 0, %2 ]
  %9 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4)
  %10 = add nuw nsw i32 %8, 1
  %11 = icmp eq i32 %10, %0
  br i1 %11, label %6, label %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr

attributes #0 = { nomerge nounwind }
