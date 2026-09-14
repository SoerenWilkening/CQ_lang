; railbank_promote_reject_classical_store.ll — bd `xdu2` / L-1a clause C5 / carve
; clause C3: the stored value is CLASSICAL.
;
; ⚠ THIS IS THE BLAST-RADIUS FIXTURE, and it is the most important negative in
; the batch.  The promoter is a memory-to-SSA rewrite that could in principle
; claim any bounded array in any program.  What confines it to the programs this
; increment is about is ONE conjunct — the carve's C3 taint half: an untainted
; stored value is `NotBank`.  This module is the customer with the quantum
; removed; it compiles today and must stay BYTE-IDENTICAL.
;
; ⚠ NOTE THE RUN LINE: this is the ONE file in the batch that does NOT decline,
; because there is no tainted store to decline on.  The module still contains a
; `cq_measure`, so the pass runs rather than taking the passthrough early-out
; (and a 0-byte or quantum-free module would ACCEPT vacuously — bd memory
; `empty-module-accepts-vacuity-trap`).
;
; ⚠ WHY THIS REFUSAL IS PINNED AGAINST A MODULE DUMP: see the batch note in
; `railbank_promote_reject_two_cells.ll`.  Here the lowered IR IS on stdout, so
; the second RUN line pins the surviving `load`/`store` there as well.
;
; RUN: env CQ_RAILBANK_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s -o %t.out.ll 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG  --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=OUT  --input-file=%t.out.ll %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @sink(ptr)

define i32 @main(i32 %v) {
entry:
  %b = alloca [3 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 3, i1 false)
  br label %head

head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %head ]
  %g0 = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  %s0 = load i8, ptr %g0, align 1
  %cl = trunc i32 %v to i8
  %sum = add i8 %s0, %cl
  store i8 %sum, ptr %g0, align 1
  %i.next = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i.next, 3
  br i1 %done, label %out, label %head

out:
  %q = call i32 @cq_theta_si32(i32 %v, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG:        %s0 = load i8, ptr %g0, align 1
; DBG:        store i8 %sum, ptr %g0, align 1

; And on the LOWERED module, which this one file actually has:
; OUT:        %s0 = load i8, ptr %g0, align 1
; OUT:        store i8 %sum, ptr %g0, align 1
; OUT-NOT:    %cq.bank

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is NOT checked here and that is deliberate: this stage
; refuses this module, so a re-added metadata mint could never fire on it and
; the negative would be VACUOUS (Rule 12 hygiene defect (b), the shape the
; 2026-09-14 session measured as `checked 0`).  It is checked on the ACCEPT
; fixtures instead, where the promoter actually runs.

