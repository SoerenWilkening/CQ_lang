; railbank_readorder_reject_guard_false_reaches_read.ll — DECLINE (bd `xdu2.10`, Track A).
;
; The unsound neighbour of `railbank_readorder_accept_unguarded.ll`: the write
; loop runs only under `n > 2`, the read loop under `n > 0`. For n in 1..2 the
; write guard's FALSE edge reaches a read of cells nothing wrote — after the
; handle-storage rewrite those read as handle 0, a LIVE rail. `n <= 2` does not
; imply `n <= 0`, so `readFollowsLoopOnEveryPath` cannot prune the bypass edge,
; the walk reaches the read, and C6 keeps its decline.
;
; C spelling: `tests/e2e/railbank_readorder_matrix.c` CASE 9.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout (Rule 12 (b)): the property is
; the `not` on the RUN line, the exact message, and the absent `Bank` anchor.
;
;
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.
; The shared string `kMsgBankTotality` is emitted by six C6 sub-clauses, so the
; env-gated anchor below is what pins WHICH one fired: the read-order walk
; (Rule-13 round 1, P3-4). Without it this fixture was pinned only by mutant M1.

; ⚠ bd `test_C_libtooling-01po.19` S4 (2026-10-15): DECLINE -> ACCEPT. The window
; model now LOWERS this array (RailWindow.h: handle array materialized at the
; quantization point, cell reads are borrowed roots, a cell rail is never freed
; or reverse-played). Reviewed by trace, not by green:
; same as the bypass case: every read names a materialized rail, written or not.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @slice(
; S4: %b.rails = alloca i32, i64 %ext, align 4, !cq.railwindow !0
; S4: %h = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; S4: %seed.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %seed.rail, double 5.000000e-01)
; S4: store i32 %seed.rail, ptr %cq.rail.addr, align 4
; S4: %cell.rail = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %cell.rail)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %n) {
entry:
  %ext = zext i32 %n to i64
  %b = alloca i32, i64 %ext, align 16
  %wg = icmp sgt i32 %n, 2
  br i1 %wg, label %wph, label %rguard

wph:
  %wn = zext nneg i32 %n to i64
  br label %w

rguard:
  %rg = icmp sgt i32 %n, 0
  br i1 %rg, label %rph, label %exit

rph:
  %rn = zext nneg i32 %n to i64
  br label %r

w:
  %i = phi i64 [ 0, %wph ], [ %inext, %w ]
  %g = getelementptr inbounds i32, ptr %b, i64 %i
  %seed = load i32, ptr %g, align 4
  %t = tail call i32 @cq_theta_si32(i32 noundef %seed, double noundef 5.000000e-01)
  store i32 %t, ptr %g, align 4
  %inext = add nuw nsw i64 %i, 1
  %wdone = icmp eq i64 %inext, %wn
  br i1 %wdone, label %rguard, label %w

exit:
  %res = phi i32 [ 0, %rguard ], [ %s2, %r ]
  ret i32 %res

r:
  %j = phi i64 [ 0, %rph ], [ %jnext, %r ]
  %s = phi i32 [ 0, %rph ], [ %s2, %r ]
  %gr = getelementptr inbounds i32, ptr %b, i64 %j
  %cell = load i32, ptr %gr, align 4
  %mv = tail call i32 @cq_measure_si32(i32 noundef %cell)
  %s2 = add nsw i32 %mv, %s
  %jnext = add nuw nsw i64 %j, 1
  %rdone = icmp eq i64 %jnext, %rn
  br i1 %rdone, label %exit, label %r
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
