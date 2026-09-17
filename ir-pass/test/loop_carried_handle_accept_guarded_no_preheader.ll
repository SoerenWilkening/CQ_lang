; loop_carried_handle_accept_guarded_no_preheader.ll — bd `test_C_libtooling-h1ip`,
; the GUARDED loop-carried handle in the shape `clang -O1` ACTUALLY EMITS for a
; runtime trip bound: THE GUARD BRANCHES STRAIGHT INTO THE HEADER AND THERE IS NO
; PREHEADER AT ALL.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE A CLAIM IN `CLAUDE.md` §4e WAS OVER-GENERAL AND
; THE CORPUS COULD NOT SEE IT.  Clause (Z1)'s original comment said a rotated
; loop *has no preheader*; Rule-13 round 1 (bd `zujr`, 2026-09-19) called that
; FALSE, having measured `entry -> for.body.preheader -> header`.  Measured again
; 2026-09-20 on `probes/h1e_guarded_live.c`, `-O1` emits **NO PREHEADER**:
;
;     %3 = icmp sgt i32 %0, 0
;     br i1 %3, label %7, label %4          ; <- straight into the header
;
; so `getLoopPreheader()` returns null and (Z1) refused BEFORE (Z8) was ever
; asked.  BOTH the original sentence and its correction were over-general: `-O1`
; emits a preheader SOMETIMES, and a predicate may not depend on which.
;
; ⚠ AND NOTHING IN THE 2107-FIXTURE CORPUS PINNED IT.  The (Z1) relaxation moved
; ZERO fixtures — measured, ORACLE vs SUBJECT, `0 A->D | 2 D->A | 0 D->D | 1
; A->A` with the two D->A being the OTHER two new accepts.  A widening that
; changes nothing in the corpus is a widening the corpus cannot defend, which is
; the whole reason this file is here rather than a note.
;
; THE SHAPE.  `%a` is the carried handle; `%r` is the exit phi that carries the
; SEED on the zero-trip edge.  The single external predecessor of the header is
; `%entry`, which is ALSO the guard, so the mint point and the guard block are
; the same block — and the trip-1 register must be minted BEFORE the guard's
; branch or the zero-trip edge cannot name it.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves when (Z1)'s single-external-entry
; rule, the guard recognition, or the mint point changes.  RE-DERIVE it then; do
; not delete it, and do not predict the string.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.np.ll
; RUN: %filecheck %s < %t.np.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %head, label %exit

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ 7, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %anext = select i1 %b, i32 1, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %r = phi i32 [ 7, %entry ], [ %anext, %head ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; THE MINT IS IN THE GUARD'S OWN BLOCK, BEFORE ITS BRANCH — there is no other
; block it could go in, because there is no preheader.
; CHECK: entry:
; CHECK-NEXT: %guard = icmp sgt i32 %n, 0
; CHECK-NEXT: %cq.carried = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: br i1 %guard, label %head, label %exit

; Both phis name that one register on their external edge.
; CHECK: %a = phi i32 [ %cq.carried, %entry ], [ %out, %head ]
; CHECK: %r = phi i32 [ %cq.carried, %entry ], [ %out, %head ]

; The zero-trip path measures the SEED register, which is the right answer for a
; loop that never runs.
; CHECK: %m1 = call i32 @cqrt_measure_i32(i32 %r)
