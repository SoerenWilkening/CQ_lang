; railbank_promote_loop_n2_wholeobj_init.ll — bd `xdu2` / L-1a clause C5: the
; customer at N=2, and the WHOLE-OBJECT INTEGER ZERO STORE initializer.
;
; ⚠ THIS FILE IS THE MEASURED CORRECTION TO `SCOPE_L1a.md` §2 C1.  That clause
; admits only "a constant-zero `llvm.memset`" (`QramLowering.cpp:1953-1971`).
; `clang -O1` writes `bool b[3] = {0}` with a memset and `bool b[2] = {0}` /
; `bool b[8] = {0}` with a single whole-object INTEGER STORE — `store i16 0` /
; `store i64 0` — because those sizes fit one instruction.  A memset-only clause
; therefore refuses TWO OF THE THREE SIZES the increment's own fixture list
; names, which is an over-decline of the program we set out to compile (owner
; ruling 2026-09-11), not a safety margin.
;
; The whole-object zero store is a PROOF that the object is all-zero, exactly as
; the memset is — it is NOT a second manufacture.  Only the NO-INITIALIZER case
; (owner ruling D1) invents a value the source never wrote, and only that case
; carries the bd `z9t1` disclosure (`railbank_promote_uninit_bank.ll`).;
; ⚠ STAGED LANDING.  W1 is three pieces and only TWO land this session (Track A's
; carve verdict and this promotion).  The taint rule (a `load` from a
; `!cq.railbank` alloca is tainted), the `[N x i1]` -> `[N x i32]` type rewrite
; and the D5 allow-list are deliberately DEFERRED, so an ACCEPT here would be a
; SILENT MISCOMPILE: `SCOPE_L1a.md` §4.4(D) — `cq_measure` of an UNTAINTED load
; takes `MeasureLowering.cpp`'s classical split and emits no gate, no symbol and
; NO TRACE LINE, which the golden byte-diff cannot see.  So the module still
; DECLINES `cq taint escape: tainted value stored to memory`.
;
; ⚠ A `DS_Error` decline writes 0 BYTES TO STDOUT, so the promotion is not
; observable on the lowered IR at this stage and an IR-text `CHECK` on stdout
; would be VACUOUS (Rule 12 hygiene defect (b)).  It is pinned on the
; `CQ_RAILBANK_DBG` MODULE DUMP instead — the `CQ_FP80_DBG` / `CQ_SPEC_DBG`
; precedent — so the `DBG` prefix below checks the REAL post-promotion module.
;
; ⚠ L8 RETIREMENT TRIGGER: when the L-1a taint rule + type rewrite + D5
; allow-list land (bd `xdu2`, the second half), this file's RUN lines become an
; ACCEPT and the shape below becomes checkable on stdout.  Re-derive it then; do
; NOT delete it.
;
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG       --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS      --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DECLINE   --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOMD      --input-file=%t.dbg %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [2 x i8], align 2
  store i16 0, ptr %b, align 2
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %c = icmp sgt i32 %a, 2
  br i1 %c, label %arm, label %latch

arm:
  %g0 = getelementptr inbounds [2 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  br label %latch

latch:
  %g1 = getelementptr inbounds [2 x i8], ptr %b, i64 0, i64 %i
  %s1 = load i8, ptr %g1, align 1
  %t1 = trunc nuw i8 %s1 to i1
  %sub = add nsw i32 %a, -3
  %a.next = select i1 %t1, i32 %sub, i32 %a
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 2
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %a.next)
  ret i32 %m
}

; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=2 cell=i8 seed=zero loads=2 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; The initializer is PROVED, not rewritten: it stays exactly where it was.
; DBG:        store i16 0, ptr %b, align 2
; DBG:      arm:
; DBG-NEXT:   %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
; DBG:      latch:
; DBG-NEXT:   %cq.bank = phi i8 [ %z0, %arm ], [ 0, %head ]
; DBG:        %cq.bank.addr = getelementptr inbounds [2 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   store i8 %cq.bank, ptr %cq.bank.addr, align 1


; Counts, in their OWN whole-file prefix (a positive CHECK-COUNT inside a
; negative prefix WINDOWS every negative after it — caught by 0 of 20 blocks).
; NOTS-COUNT-1: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: CQ_RAILBANK_DBG: promote bank

; DECLINE: cq taint escape: tainted value stored to memory

; ⚠ ITS OWN WHOLE-FILE PREFIX, AND THAT IS THE POINT.  A positive `CHECK-COUNT`
; inside a negative prefix WINDOWS every negative after it — FileCheck only scans
; forward from the positive match — and this file's `NOTS` prefix carries counts,
; so a `NOTS-NOT: !cq.railbank` there would never see the `alloca` line, which is
; ABOVE them in the dump.  MEASURED: with the negative in `NOTS`, a mutant that
; re-adds the metadata mint was caught by only 3 of the 7 accept fixtures; in its
; own prefix it is caught by all 7.  (`CLAUDE.md` Rule 12 hygiene defect (a): the
; same shape was caught by 0 of 20 blocks the first time it shipped.)
;
; The promoter mints NO membership record.  `!cq.railbank` is the FREEZE's, and the
; freeze is in W1's deferred half — `SCOPE_L1a.md` §4.3 and `trackA/SIGNATURE.md`
; deviation (2) put the mint on the TYPE REWRITER next session, because a record
; with no reader is Rule 12 hygiene defect (c) in its purest form.
; NOMD-NOT: !cq.railbank
