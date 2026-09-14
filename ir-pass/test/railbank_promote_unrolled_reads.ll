; railbank_promote_unrolled_reads.ll — bd `xdu2` / L-1a clause C5: the bank whose
; READS `clang -O1` unrolled into byte-offset geps and a direct load.
;
; ⚠ THE SECOND HALF OF THE MEASURED CORRECTION TO `SCOPE_L1a.md` §2 C1/C4.  For
; `a_loop_n3_noarm.c` / `a_loop_n3_uncond.c`, `-O1` unrolls the short measure
; loop `for (i…) s += cq_measure(b[i])` into
;     `load i8, ptr %b` · `gep inbounds i8, ptr %b, i64 1` · `… i64 2`
; — a DIRECT load and BYTE-OFFSET geps, none of them the canonical
; `[N x T], 0, idx` shape the carve recognises.  An alloca-wide scan that admits
; only canonical geps refuses the whole bank on account of instructions nothing
; rewrites.  They are provable in-bounds constant-offset READS of one cell and
; are admitted as such.
;
; ⚠ AND THE FENCE THAT COMES WITH THEM: such a read is admitted ONLY OUTSIDE the
; write loop.  Inside it, the promotion MOVES the activation's write to the
; activation's end, so any other observer of the object would see the write at a
; different point in the trip — see `railbank_promote_reject_inloop_other_read.ll`,
; which is that hazard as a decline.;
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
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %t0 = trunc nuw i8 %s0 to i1
  %q = call zeroext i1 @cq_theta_i1(i1 %t0, double 5.000000e-01)
  %z0 = zext i1 %q to i8
  store i8 %z0, ptr %g0, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %r0 = load i8, ptr %b, align 1
  %c0 = trunc nuw i8 %r0 to i1
  %m0 = call zeroext i1 @cq_measure_i1(i1 %c0)
  %e0 = zext i1 %m0 to i32
  %p1 = getelementptr inbounds i8, ptr %b, i64 1
  %r1 = load i8, ptr %p1, align 1
  %c1 = trunc nuw i8 %r1 to i1
  %m1 = call zeroext i1 @cq_measure_i1(i1 %c1)
  %e1 = zext i1 %m1 to i32
  %p2 = getelementptr inbounds i8, ptr %b, i64 2
  %r2 = load i8, ptr %p2, align 1
  %c2 = trunc nuw i8 %r2 to i1
  %m2 = call zeroext i1 @cq_measure_i1(i1 %c2)
  %e2 = zext i1 %m2 to i32
  %s = add nsw i32 %e0, %e1
  %s2 = add nsw i32 %s, %e2
  ret i32 %s2
}

; DBG: CQ_RAILBANK_DBG: promote bank %b in @main header %head cells=3 cell=i8 seed=zero loads=1 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG:      head:
; DBG:        %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
; DBG-NEXT:   %z0 = zext i1 %q to i8
; DBG:        %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
; DBG-NEXT:   store i8 %z0, ptr %cq.bank.addr, align 1

; The unrolled READS are left BYTE-UNTOUCHED — they read cells written by other
; activations, which no per-activation forwarding can reach (SCOPE_L1a §3c), and
; they are what the DEFERRED taint rule will have to claim.
; DBG:      out:
; DBG-NEXT:   %r0 = load i8, ptr %b, align 1
; DBG:        %p1 = getelementptr inbounds i8, ptr %b, i64 1
; DBG:        %p2 = getelementptr inbounds i8, ptr %b, i64 2

; NOTS-COUNT-1: CQ_RAILBANK_DBG: promote bank
; NOTS-COUNT-1: store i8 %z0

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
