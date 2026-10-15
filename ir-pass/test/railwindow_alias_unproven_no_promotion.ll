; DECLINE pending S5 + ADVERSARIAL (bd `test_C_libtooling-01po.19`, review round 1 F1; S7 built).
;
; S3 must preserve memory semantics. The region of loop H writes q[i] (theta), then
; on one path stores 5 to q[j] for a RUNTIME j and reads q[i] again: if j == i the
; reread is 5, not the rotated value. Promoting q[i] there would forward the theta
; result across that store (review probe h2_alias_exit.ll). Before S7 the region
; was left unpromoted (the file's name is that history). S7 now VERSIONS it on
; the two cell offsets (the stretch runs to the region's exits, the latch's S
; sub-loop entry re-simplified): each copy is a window of its own and is
; promoted there, where the pair is proven by the guard.
;   * DISTINCT copy (j != i): q[j] := 5, q[i] := theta ^ 1 (S5 sub-gap bd 01po.19.7, pending).
;   * ALIASED copy (j == i): q[i] := theta, then `store 5` and the reread name
;     ONE cell, so the reread is 5 and `5 ^ 1` folds to the CLASSICAL `store 4`
;     (a rebind): exactly C's memory semantics.
; Pinned: one versioning, a promotion in each copy, and the folded `store i32 4`
; on the aliased path. The decline now names S5 only.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank'
; RUN: env CQ_RAILWINDOW_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; (bd 01po.19 S5 review C-F5: the S5 sub-gap is named — `q[i] = l2 ^ 1` is a
; classical-operand update of the cell.)
; CHECK: cq rail window: quantum array not lowered yet (bd 01po.19), needs S5 classical-operand or subtrahend cell update (bd 01po.19.7){{$}}
; WIN: CQ_RAILWINDOW_DBG: @main claims %q cells=i32 loads=4 stores=3 Q=  br label %H
; WIN-NEXT: CQ_RAILWINDOW_DBG: version region %H on {%q.rails,+,4}<nw><%H> != ((4 * %j) + %q.rails)
; WIN-NEXT: CQ_RAILWINDOW_DBG: promote cell {%q.rails,+,4}<nw><%H> in region %H.split loads=2 stores=2 exits=2
; WIN-NEXT: CQ_RAILWINDOW_DBG: promote cell {%q.rails,+,4}<nw><%H> in region %H.split.cq.alias loads=2 stores=3 exits=2
; WIN-NEXT: CQ_RAILWINDOW_DBG: promoted 2 cell class(es)
; WIN: {{^}}B:
; WIN-NEXT: store i32 5, ptr
; WIN: {{^}}B.cq.alias:
; WIN-NEXT: store i32 4, ptr %cq.rail.addr,
; WIN-NEXT: br label

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double) nomerge
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define i32 @main(i64 %j, i1 %c) {
entry:
  %q = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr %q, i8 0, i64 32, i1 false)
  br label %H
H:
  %i = phi i64 [0, %entry], [%i1, %L]
  %a = getelementptr inbounds [8 x i32], ptr %q, i64 0, i64 %i
  %l1 = load i32, ptr %a
  %t = call i32 @cq_theta_si32(i32 %l1, double 0.5)
  store i32 %t, ptr %a
  br i1 %c, label %X, label %B
B:
  %bj = getelementptr inbounds [8 x i32], ptr %q, i64 0, i64 %j
  store i32 5, ptr %bj
  %l2 = load i32, ptr %a
  %x = xor i32 %l2, 1
  store i32 %x, ptr %a
  br label %S
S:
  %k = phi i64 [0, %B], [%k1, %S]
  %l3 = load i32, ptr %a
  %m3 = call i32 @cq_measure_si32(i32 %l3)
  %k1 = add nuw nsw i64 %k, 1
  %ce = icmp eq i64 %k1, 2
  br i1 %ce, label %L, label %S
L:
  %i1 = add nuw nsw i64 %i, 1
  %ci = icmp eq i64 %i1, 8
  br i1 %ci, label %X, label %H
X:
  %m = load i32, ptr %q
  %r = call i32 @cq_measure_si32(i32 %m)
  ret i32 %r
}
