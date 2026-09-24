; railbank_readorder_accept_unguarded.ll — ACCEPT (bd `test_C_libtooling-xdu2.10`, Track A).
;
; `int b[n]; for (i<n) b[i] = cq_theta(b[i], .5); for (i<n) s += cq_measure(b[i]);`
; with NO explicit `if (n <= 0) return`. `clang -O1` gives each loop its OWN
; `n > 0` guard (`%wg`, `%rg` — two distinct but identical compares), so the read
; guard `%rguard` is reached from the write guard's FALSE edge as well as from the
; write loop's exit, and the write-loop header does NOT dominate the read.
;
; ⚠ RED-GREEN. On the pre-change ORACLE (`cq-opt` sha256 c6f61f80…, main
; `d0720cb1`) this module declines `cq rail bank: array has cells no iteration
; writes` — C6's read-order test was `DT.dominates(Header, read)`. The read runs
; iff `n > 0` iff the write loop ran; `readFollowsLoopOnEveryPath` asks that
; question (`%wg` false IMPLIES `%rg` false, `isImpliedCondition`) and accepts.
;
; SOURCE: `tests/e2e/railbank_readorder_matrix.c` CASE 1 (`slice`), stage 1 at
; `clang -O1`, blocks renamed for reading; the instruction sequence is verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR   --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS --input-file=%t.ll %s
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:     > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG --input-file=%t.dbg %s \
; RUN:     --implicit-check-not='railbank [BankRaw]' --implicit-check-not='cq rail bank:'
;
; IR:      %b = alloca i32, i64 %ext, align 16, !cq.railbank
; IR:      w:
; IR:      %h = call i32 @cqrt_alloc_i32(i32 0)
; IR-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; IR:      store i32 %h, ptr %cq.bank.addr
; IR:      r:
; IR:      %cell = load i32, ptr %gr
; IR-NEXT: %m = call i32 @cqrt_measure_i32(i32 %cell)
;
; NOTS-NOT: @cq_theta_si32(
; NOTS-NOT: @cq_measure_si32(
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: store i32 0, ptr %cq.bank.addr
;
; DBG: railbank [Bank]

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %n) {
entry:
  %ext = zext i32 %n to i64
  %b = alloca i32, i64 %ext, align 16
  %wg = icmp sgt i32 %n, 0
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
