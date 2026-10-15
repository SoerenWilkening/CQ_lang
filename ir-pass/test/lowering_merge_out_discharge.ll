; lowering_merge_out_discharge.ll — ACCEPT, DISCHARGED: a controlled-copy merge
; `%out` rail whose readers have all run is reversed by re-emitting its copy
; CORE in reverse (the copies are CNOT-class involutions, the `cqrt_x` brackets
; self-inverse) and freed at a proven |0>; the merge's own flag strip is
; deferred to after that adjoint (bd test_C_libtooling-r2j3.32, a P1
; verify-clean silent miscompile).
;
; THE MISCOMPILE (p18, docs/CQ_FINDINGS.md, measured on main 0125bc07):
;     bool a=0,b=0,t=0; cq_theta(&a,.5); cq_theta(&b,.6);
;     int s=2*a+b; if(s==3) cq_theta(&t,.7); cq_theta(&a,-.5); measure a,b,t
; `clang -O1` folds `2*a` into `select i1 %a, i32 2, i32 0` (the 4.4 merge,
; `SelectMergeEmit`). The merge rail `%out` (=2a, a CNOT record of a) was never
; reversed after its only consumer `or` was: `cqrt_ry_i1(a, -0.5)` then rotated
; a register entangled with a live copy, so P(a=1 | b=0) was
; 2 sin^2(.25) cos^2(.25) = sin^2(.5)/2 ~ 0.115 where the program says exactly 0.
;
; THE FIX (MergeRailDischarge.cpp): after every uncompute partition, a merge rail
; (Phase-4-owned, born |0>, written ONLY by `cqrt_copy_<W>_controlled` inside one
; closed emitted stream) whose every other user is a pure READ that has already
; run gets, right after its last reader: the adjoint of any M-C in-place gate on
; it, the copy core reversed, the stream's flag strip (moved, its flags live and
; untouched across the window), and the free. No register the stream reads may
; be written between the stream and that point; otherwise the rail stays
; allocated (the pre-fix disposition).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

; SILENT-NOT: {{.}}

; ── 1. p18 itself: the adjoint sits after the consumer's `_unc` and BEFORE the
;       user's later Ry on the condition register; the flag `F` lives across.
; CHECK-LABEL: define range(i32 0, 8) i32 @p18(
; CHECK:      %[[A:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %{{[0-9a-zA-Z_.]+}}, double 6.000000e-01)
; CHECK-NEXT: %[[F:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: %[[OUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[T:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[E:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[F]])
; CHECK:      call void @cq_template_or_i32_unc(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[OUT]], i32 %{{[0-9a-zA-Z_.]+}})
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[E]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[A]], double -5.000000e-01)
; CHECK:      ret i32

; ── 2. The consumer's RESULT is measured (it is never reversed): the merge rail
;       is still a function of the live condition alone, so it is discharged
;       right after its one forward reader.
; CHECK-LABEL: define i32 @consumer_measured(
; CHECK:      %[[A2:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[OUT2:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call i32 @cq_template_or_i32(i32 %[[OUT2]],
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2:[0-9a-zA-Z_.]+]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A2]], i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT2]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[A2]], double -5.000000e-01)

; ── 3. A compound condition (`and` of two Q-compare leaves): the leaf flags and
;       the node ancilla stay live across the reader, the core's adjoint runs on
;       the node, then the whole network strip (node, then leaves LIFO).
; CHECK-LABEL: define i32 @compound(
; CHECK:      %[[L1:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[L2:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(
; CHECK-NEXT: %[[N3:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[L1]], i32 %[[L2]], i32 %[[N3]])
; CHECK-NEXT: %[[OUT3:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT3]], i32 %{{[0-9a-zA-Z_.]+}})
; CHECK-NEXT: call void @cqrt_x(i32 %[[N3]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[N3]], i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[N3]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[N3]], i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[L1]], i32 %[[L2]], i32 %[[N3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[N3]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[L2]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[L2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[L1]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[L1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT3]])
; CHECK:      ret i32

; ── 4. Scalar-fp merge (`cqrt_copy_f64_controlled`), same discharge.
; CHECK-LABEL: define i32 @fp_merge(
; CHECK:      %[[OUT4:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:      call i32 @cq_template_fmul_f64_hl(i32 %[[OUT4]],
; CHECK-NEXT: call void @cqrt_x(
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(
; CHECK-NEXT: call void @cqrt_x(
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(
; CHECK-NEXT: call void @cqrt_cnot(
; CHECK-NEXT: call void @cqrt_free(
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT4]])
; CHECK:      ret i32

; ── 5. Two readers: the adjoint follows the LATER one.
; CHECK-LABEL: define i32 @two_readers(
; CHECK:      %[[OUT5:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call i32 @cq_template_add_i32_hl(i32 %[[OUT5]], i32 1)
; CHECK-NEXT: call i32 @cq_template_mul_i32_hl(i32 %[[OUT5]], i32 3)
; CHECK-NEXT: call void @cqrt_x(
; CHECK:      call void @cqrt_free(i32 %[[OUT5]])
; CHECK:      ret i32

; ── 6. Nested merges: the outer rail (which reads the inner one as a copy
;       source) is reversed FIRST, and the inner one only after that whole
;       group (LIFO).
; CHECK-LABEL: define i32 @nested(
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[IN6:[0-9a-zA-Z_.]+]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[IN6]], i32 %[[OUT6:[0-9a-zA-Z_.]+]])
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT6]], i32 %{{[0-9a-zA-Z_.]+}})
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[IN6]], i32 %[[OUT6]])
; CHECK:      call void @cqrt_free(i32 %[[OUT6]])
; CHECK-NEXT: call void @cqrt_x(
; CHECK:      call void @cqrt_free(i32 %[[IN6]])
; CHECK:      ret i32

; ── 7. An M-C in-place reassignment on the rail (`s + 1` → `cqrt_addc_i32`)
;       is adjointed FIRST (EmitInverse), then the core.
; CHECK-LABEL: define i32 @inplace_mc(
; CHECK:      %[[OUT10:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_addc_i32(i32 %[[OUT10]], i32 1)
; CHECK:      call i32 @cq_template_or_i32(i32 %[[OUT10]],
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[OUT10]], i32 -1)
; CHECK-NEXT: call void @cqrt_x(
; CHECK:      call void @cqrt_free(i32 %[[OUT10]])
; CHECK:      ret i32

; ── 8. The reader sits in the merge block's STRAIGHT-LINE successor (`br` to a
;       block whose only predecessor it is): the reversal follows it there.
; CHECK-LABEL: define i32 @chain_reader(
; CHECK:      %[[OUT11:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      br label %next
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT11]],
; CHECK-NEXT: call void @cqrt_x(
; CHECK:      call void @cqrt_free(i32 %[[OUT11]])
; CHECK:      ret i32

; ── 9. The reader's block has TWO predecessors (a classical diamond). Until the
;       R11 round-1 fix this was a leak (the replay needed a straight-line
;       chain); the replay now lands at the nearest common post-dominator of
;       the stream and its readers (`j`), the region entry..j being
;       single-entry/single-exit, so it runs exactly once per forward run.
; CHECK-LABEL: define i32 @offchain_reader(
; CHECK:      %[[OUT12:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      br i1 %c, label %l, label %r
; CHECK:      j:
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT12]],
; CHECK-NEXT: call void @cqrt_x(
; CHECK:      call void @cqrt_free(i32 %[[OUT12]])
; CHECK:      ret i32

; ── ADVERSARIAL: each of these keeps the merge rail allocated (the Rule-6 leak,
;    never a dirty free). NEG lines are windowed per function.
; NEG-LABEL: define i32 @out_measured(
; NEG:       %[[OUT7:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; NEG-NOT:   call void @cqrt_free(i32 %[[OUT7]])
; NEG:       ret i32
; NEG-LABEL: define i32 @out_returned(
; NEG:       %[[OUT8:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; NEG-NOT:   call void @cqrt_free(i32 %[[OUT8]])
; NEG:       ret i32
; NEG-LABEL: define i32 @cond_rotated_before_reader(
; NEG:       %[[OUT9:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; NEG-NOT:   call void @cqrt_free(i32 %[[OUT9]])
; NEG:       ret i32

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare double @cq_measure_f64(double noundef)

define range(i32 0, 8) i32 @p18() {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %3 = select i1 %1, i32 2, i32 0
  %4 = zext i1 %2 to i32
  %5 = or disjoint i32 %3, %4
  %6 = icmp eq i32 %5, 3
  br i1 %6, label %7, label %9

7:
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666) #0
  br label %9

9:
  %10 = phi i1 [ %8, %7 ], [ false, %0 ]
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef -5.000000e-01) #0
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11)
  %13 = zext i1 %12 to i32
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10)
  %16 = select i1 %14, i32 2, i32 0
  %17 = or disjoint i32 %16, %13
  %18 = select i1 %15, i32 4, i32 0
  %19 = or disjoint i32 %17, %18
  ret i32 %19
}

define i32 @consumer_measured() {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %3 = select i1 %1, i32 2, i32 0
  %4 = zext i1 %2 to i32
  %5 = or disjoint i32 %3, %4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef -5.000000e-01) #0
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7)
  %9 = zext i1 %8 to i32
  %10 = add i32 %6, %9
  ret i32 %10
}

define i32 @compound(i32 noundef %m, i32 noundef %n) {
  %x = tail call i32 @cq_theta_si32(i32 noundef %m, double noundef 5.000000e-01) #0
  %y = tail call i32 @cq_theta_si32(i32 noundef %n, double noundef 6.000000e-01) #0
  %c1 = icmp sgt i32 %x, 0
  %c2 = icmp slt i32 %y, 1
  %c = and i1 %c1, %c2
  %s = select i1 %c, i32 7, i32 1
  %u = add i32 %s, %y
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  ret i32 %r
}

define i32 @fp_merge() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %d = select i1 %a, double 1.500000e+00, double 2.500000e-01
  %e = fmul double %d, 2.000000e+00
  %r = tail call double @cq_measure_f64(double noundef %e)
  %i = fptosi double %r to i32
  ret i32 %i
}

define i32 @two_readers() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  %u = add i32 %s, 1
  %v = mul i32 %s, 3
  %r1 = tail call i32 @cq_measure_si32(i32 noundef %u)
  %r2 = tail call i32 @cq_measure_si32(i32 noundef %v)
  %r = add i32 %r1, %r2
  ret i32 %r
}

define i32 @nested() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s1 = select i1 %a, i32 2, i32 0
  %s2 = select i1 %b, i32 %s1, i32 5
  %bz = zext i1 %b to i32
  %u = add i32 %s2, %bz
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  ret i32 %r
}

define i32 @inplace_mc() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  %u = add i32 %s, 1
  %bz = zext i1 %b to i32
  %w = or i32 %u, %bz
  %r = tail call i32 @cq_measure_si32(i32 noundef %w)
  ret i32 %r
}

define i32 @chain_reader() {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  br label %next

next:
  %bz = zext i1 %b to i32
  %u = add i32 %s, %bz
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  ret i32 %r
}

define i32 @offchain_reader(i1 %c) {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  br i1 %c, label %l, label %r

l:
  br label %j

r:
  br label %j

j:
  %bz = zext i1 %b to i32
  %u = add i32 %s, %bz
  %m = tail call i32 @cq_measure_si32(i32 noundef %u)
  ret i32 %m
}

define i32 @out_measured() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  %r = tail call i32 @cq_measure_si32(i32 noundef %s)
  ret i32 %r
}

define i32 @out_returned() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  ret i32 %s
}

define i32 @cond_rotated_before_reader() {
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #0
  %s = select i1 %a, i32 2, i32 0
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #0
  %bz = zext i1 %b to i32
  %a2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %a, double noundef -5.000000e-01) #0
  %u = add i32 %s, %bz
  %r = tail call i32 @cq_measure_si32(i32 noundef %u)
  %m = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %a2)
  %z = zext i1 %m to i32
  %q = add i32 %r, %z
  ret i32 %q
}

attributes #0 = { nomerge nounwind }
