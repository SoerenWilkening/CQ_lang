; carried_fence_bank.ll — cq-merge-selftest input (NOT a lit test: `Inputs/`
; is excluded; ctest `ir-pass-merge-discharge-selftest` runs it). bd
; test_C_libtooling-r2j3.36, R11 round 1 (reviewer B, scratchpad
; review_r236B/probe.ll):
;   F1  per-trip CELL LOADS of a materialized rail bank (the 01po.19 S4 shape:
;       cells minted at Q, each trip loads its own) are FRESH when the cell was
;       parked as a fresh mint, the address is a no-wrap AddRec of the carried
;       loop and no coupling of that cell can precede the gate
;       (MergeCarriedFenceFresh.h, clauses (a)–(c)). Before this, every cell
;       load joined the protected set through the bank's single alias class
;       and a controlled Ry onto cell i was loud after trip 0 coupled cell 0.
;   F2  a merge rail carried through a CELL rather than a header φ is a
;       carried rail (`carriedLoop`); both binaries were silent on
;       memcarried_cond_ry_loud.
; The quiet controls:
;   * s4_slice_materialized       the flagship slice, cells materialized, one
;                                 controlled Ry onto cell i per trip;
;   * s4_slice_materialized_nory  the same without the Ry;
;   * s4_rotate_then_condition    `θ(&q[i],.5); if (q[i]) a -= 3;` per trip;
;   * memcarried_kept             the rail carried through a cell; the
;                                 recorded condition is only measured.
; The loud shapes (the tagged call is the one that must fire):
;   * s4_nonaddrec_reuse_loud     index `i & 1`: trip 2 re-reads cell 0, which
;                                 trip 0 coupled (not an AddRec);
;   * s4_invariant_index_loud     a loop-invariant index: every trip re-reads
;                                 one cell (not an AddRec of the loop);
;   * s4_neighbor_coupling_loud   trip i couples cell i+1 into the record and
;                                 trip i+1 rotates it: a DIFFERENT address
;                                 SCEV in one trip is the SAME cell one trip
;                                 later, so a different SCEV is never exempt;
;   * memcarried_cond_ry_loud     pB with the carried rail parked in a cell:
;                                 a Ry on the recorded condition in the loop.

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1 zeroext)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare zeroext i1 @cqrt_measure_i1(i32)

define i32 @s4_slice_materialized() #1 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 3
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ci = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  %h = load i32, ptr %ci, align 4
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 2)
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %a, i32 2)
  call void @cqrt_free(i32 %h_cmp)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

define i32 @s4_slice_materialized_nory() #1 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 3
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ci = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  %h = load i32, ptr %ci, align 4
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

define i32 @s4_rotate_then_condition() #1 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 3
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ci = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  %q = load i32, ptr %ci, align 4
  call void @cqrt_ry_i1(i32 %q, double 5.000000e-01)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %q)
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %a, i32 %out)
  call void @cqrt_x(i32 %q)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; index `i & 1`: cells 0, 1, 0 — trip 2 rotates the cell trip 0 coupled.
define i32 @s4_nonaddrec_reuse_loud() #0 !dbg !902 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 3
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ix = and i64 %i, 1
  %ci = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %ix
  %q = load i32, ptr %ci, align 4
  call void @cqrt_ry_i1(i32 %q, double 5.000000e-01), !cq.selftest.fires !0, !dbg !903
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %q)
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %a, i32 %out)
  call void @cqrt_x(i32 %q)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; a loop-invariant index: one cell, rotated every trip after trip 0 coupled it.
define i32 @s4_invariant_index_loud(i64 %k) #0 !dbg !904 {
entry:
  %bank = alloca [3 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 3
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ck = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %k
  %q = load i32, ptr %ck, align 4
  call void @cqrt_ry_i1(i32 %q, double 5.000000e-01), !cq.selftest.fires !0, !dbg !905
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %q)
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %a, i32 %out)
  call void @cqrt_x(i32 %q)
  %i1 = add nuw nsw i64 %i, 1
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; trip i couples cell i+1 to the carried φ; trip i+1 rotates that cell.
; RETIREMENT CONDITION (L7; owner ruling ruling-r2j336-round1-qs-2026-10-15
; Q1, bd r2j3.36.1): a coupling at a DIFFERENT address SCEV always counts
; today. The sound narrower exemption, if built: same trip loop, same step s,
; both no-wrap AddRecs, gate L = {b,+,s}, coupling X = {a,+,s}; the coupled
; cell is re-read by L iff (a−b) is divisible by s and (a−b)/s ≥ 0. Here
; a−b = +4 = s, so this case STAYS loud under that exemption; a case with
; (a−b)/s < 0 (coupling q[i−1]) or a non-multiple offset is what it would
; newly accept (memory scev-vacuous-trip-bounds: trip-bound reasoning over
; SCEV can be vacuous).
define i32 @s4_neighbor_coupling_loud() #0 !dbg !906 {
entry:
  %bank = alloca [4 x i32], align 4, !cq.railbank !1
  br label %mat
mat:
  %j = phi i64 [ 0, %entry ], [ %j1, %mat ]
  %r = call i32 @cqrt_alloc_i1(i1 false)
  %cj = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %j
  store i32 %r, ptr %cj, align 4
  %j1 = add nuw nsw i64 %j, 1
  %dj = icmp eq i64 %j1, 4
  br i1 %dj, label %pre, label %mat
pre:
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i64 [ 0, %pre ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %pre ], [ %out, %loop ]
  %ci = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i
  %q = load i32, ptr %ci, align 4
  call void @cqrt_ry_i1(i32 %q, double 5.000000e-01), !cq.selftest.fires !0, !dbg !907
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %q)
  call void @cqrt_copy_i32_controlled(i32 %q, i32 %a, i32 %out)
  call void @cqrt_x(i32 %q)
  %i1 = add nuw nsw i64 %i, 1
  %cn = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i1
  %qn = load i32, ptr %cn, align 4
  call void @cqrt_cnot(i32 %a, i32 %qn)
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m
}

; pB with the carried rail parked in a cell (S3 Q6(a) re-materialization).
define i32 @memcarried_cond_ry_loud(i32 %u) #0 !dbg !908 {
entry:
  %bank = alloca [4 x i32], align 4, !cq.railbank !1
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  %c0 = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 0
  store i32 %seed, ptr %c0, align 4
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %ci = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i
  %a = load i32, ptr %ci, align 4
  %ii = trunc i64 %i to i32
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %ii)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %ii)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i64 %i, 1
  %cn = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i1
  store i32 %out, ptr %cn, align 4
  call void @cqrt_ry_i32(i32 %h, double 2.000000e-01), !cq.selftest.fires !0, !dbg !909
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}

; the memory-carried control: the recorded condition is only measured.
define i32 @memcarried_kept(i32 %u) #1 {
entry:
  %bank = alloca [4 x i32], align 4, !cq.railbank !1
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  %c0 = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 0
  store i32 %seed, ptr %c0, align 4
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i1, %loop ]
  %ci = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i
  %a = load i32, ptr %ci, align 4
  %ii = trunc i64 %i to i32
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %ii)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %ii)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i64 %i, 1
  %cn = getelementptr inbounds [4 x i32], ptr %bank, i64 0, i64 %i1
  store i32 %out, ptr %cn, align 4
  %done = icmp eq i64 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  ret i32 %m
}

attributes #0 = { "cq-selftest-expect"="loud" "cq-selftest-message"="cq merge discharge: non-diagonal gate on a register a leaked loop-carried merge rail records" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
!1 = !{i32 1}

; debug info: only the tagged call carries a !dbg line (cq-merge-selftest
; checks the diagnostic fired at that line).
!llvm.dbg.cu = !{!890}
!llvm.module.flags = !{!891}
!890 = distinct !DICompileUnit(language: DW_LANG_C11, file: !892, producer: "hand", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!891 = !{i32 2, !"Debug Info Version", i32 3}
!892 = !DIFile(filename: "carried_fence_bank.ll", directory: "ir-pass/test/Inputs/merge_selftest")
!893 = !DISubroutineType(types: !{})
!902 = distinct !DISubprogram(name: "s4_nonaddrec_reuse_loud", scope: !892, file: !892, line: 101, type: !893, scopeLine: 101, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!903 = !DILocation(line: 101, scope: !902)
!904 = distinct !DISubprogram(name: "s4_invariant_index_loud", scope: !892, file: !892, line: 102, type: !893, scopeLine: 102, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!905 = !DILocation(line: 102, scope: !904)
!906 = distinct !DISubprogram(name: "s4_neighbor_coupling_loud", scope: !892, file: !892, line: 103, type: !893, scopeLine: 103, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!907 = !DILocation(line: 103, scope: !906)
!908 = distinct !DISubprogram(name: "memcarried_cond_ry_loud", scope: !892, file: !892, line: 104, type: !893, scopeLine: 104, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !890)
!909 = !DILocation(line: 104, scope: !908)
