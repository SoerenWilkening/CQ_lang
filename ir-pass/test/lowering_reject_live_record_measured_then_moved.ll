; lowering_reject_live_record_measured_then_moved.ll — M-A clause 4 must not
; exempt a measured record whose rail is WRITTEN again before the gate (bd
; test_C_libtooling-cmr9, found by the aako/gl3x Rule-11 review, 2026-10-05).
;
; SOURCE (clang -O1 IR of cmr9.c, attributes trimmed; the `!dbg` locations are
; hand-attached to the user rotations so each warning names its gate):
;
;      1  volatile int sink;
;      2  int measured_then_moved(int u) {           // WARNS at 6, 7 AND 8
;      3    int q = u; cq_theta(&q, 0.5);
;      4    int r = q & 1;
;      5    sink = cq_measure(r);                     // collapse of r
;      6    if (q > 3) cq_theta(&r, 0.9);             // r written again, under q's flag
;      7    cq_theta(&r, 0.125);
;      8    cq_theta(&q, 0.3);                        // T
;      9    return 0;
;     10  }
;     11  int measured_untouched(int u) {             // SILENT
;         ...  q, r = q & 1, sink = cq_measure(r) as above;
;     15    cq_theta(&q, 0.3);                        // T, r untouched since its measurement
;         }
;     18  int measured_moved_after_gate(int u) {      // WARNS at 23, 24, NOT at 22
;         ...  q, r = q & 1, sink = cq_measure(r) as above;
;     22    cq_theta(&q, 0.3);                        // T
;     23    if (q > 3) cq_theta(&r, 0.9);             // the same writes, after T
;     24    cq_theta(&r, 0.125);
;         }
;
; THE MISS (before this fix). Clause 4 exempted a record measured provably before
; the gate and asked nothing else, so in @measured_then_moved the gate on line 8
; was silent. The stream between the collapse and the gate is
;     %m = cqrt_measure_i32(%r)                      ; r collapsed to bit 0 of q
;     %f = cq_template_icmp_sgt_i32_hl(%q, 3)
;     cqrt_ry_i32_controlled(%f, %r, 0.9)            ; r rotated iff q > 3
;     cq_template_icmp_sgt_i32_hl_unc(%f, %q, 3); cqrt_free(%f)
;     cqrt_ry_i32(%r, 0.125)
;     cqrt_ry_i32(%q, 0.3)                           ; T
; After the controlled Ry, r's state depends on whether q > 3: r is again a
; record of q, nothing observes it after the gate, and the Ry on q acts on a
; partly dephased register. The measurement stopped being the last word on r the
; moment a gate wrote r again.
;
; THE RULE. A collapse exempts the record only if NO gate writes the record's
; rail inside the window (collapse, gate), on every path: the window scan of
; `railUnmovedInWindow` (Uncomputation.h), the same scan M-B's clause (d) asks
; of a borrowed parent. Label-preserving users (a forward template read, a
; diagonal rotation) are admitted anywhere; anything else must provably run
; outside the window.
;   * @measured_untouched: no user of r between the collapse and the gate. Silent.
;   * @measured_moved_after_gate: the same writes sit after T, outside the
;     window, so T stays silent; the two gates on r warn for their own reason (q's
;     rail stands as an unobserved record of r).
;
; The TAPE half of clause 4 is not asked this, because two upstream fences keep a
; taped record unwritten after its write: `IOSinkLowering`'s `tapedLineageClosed`
; (the taped name's own users) and `ArmClassify`'s condition-wire fence (a write
; through a stale pre-rotation alias, the bd r2j3.6 class); the park's flag is
; written only by its own `cqrt_x` bracket closing around the write
; (lowering_live_record_tape_before_gate.ll, @park_negated_then_gate, which also
; carries the retirement trigger).
;
; KNOWN COSTS OF THIS RULE, filed and not pinned here: a measured record that is
; only READ inside the window by an unrecorded `_unc` (the spine's adjoint; bd
; 7xsh's row admits only emitter-recorded strips), a `_controlled` gate or a clone
; call also warns at the gate, because the scan refuses those wherever the record
; sits (bd rced, an over-warning); and in a rolled loop the certificate covers
; only the current instance of the record (bd 9128, masked by a loud loop
; decline today).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err

@sink = global i32 0, align 4

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define noundef i32 @measured_then_moved(i32 noundef %0) local_unnamed_addr !dbg !10 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0, !dbg !14
  %3 = and i32 %2, 1
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #1
  store volatile i32 %4, ptr @sink, align 4
  %5 = icmp sgt i32 %2, 3
  br i1 %5, label %6, label %8

6:
  %7 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #0, !dbg !11
  br label %8

8:
  %9 = phi i32 [ %7, %6 ], [ %3, %1 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 1.250000e-01) #0, !dbg !12
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0, !dbg !13
  ret i32 0
}

define noundef i32 @measured_untouched(i32 noundef %0) local_unnamed_addr !dbg !20 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0, !dbg !22
  %3 = and i32 %2, 1
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #1
  store volatile i32 %4, ptr @sink, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0, !dbg !21
  ret i32 0
}

define noundef i32 @measured_moved_after_gate(i32 noundef %0) local_unnamed_addr !dbg !30 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #0, !dbg !34
  %3 = and i32 %2, 1
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #1
  store volatile i32 %4, ptr @sink, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #0, !dbg !31
  %6 = icmp sgt i32 %5, 3
  br i1 %6, label %7, label %9

7:
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #0, !dbg !32
  br label %9

9:
  %10 = phi i32 [ %8, %7 ], [ %3, %1 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 1.250000e-01) #0, !dbg !33
  ret i32 0
}

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!1 = !DIFile(filename: "cmr9.c", directory: "/")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !DISubroutineType(types: !5)
!5 = !{}
!10 = distinct !DISubprogram(name: "measured_then_moved", scope: !1, file: !1, line: 2, type: !4, scopeLine: 2, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!11 = !DILocation(line: 6, column: 14, scope: !10)
!12 = !DILocation(line: 7, column: 3, scope: !10)
!13 = !DILocation(line: 8, column: 3, scope: !10)
!14 = !DILocation(line: 3, column: 14, scope: !10)
!20 = distinct !DISubprogram(name: "measured_untouched", scope: !1, file: !1, line: 11, type: !4, scopeLine: 11, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!21 = !DILocation(line: 15, column: 3, scope: !20)
!22 = !DILocation(line: 12, column: 14, scope: !20)
!30 = distinct !DISubprogram(name: "measured_moved_after_gate", scope: !1, file: !1, line: 18, type: !4, scopeLine: 18, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!31 = !DILocation(line: 22, column: 3, scope: !30)
!32 = !DILocation(line: 23, column: 14, scope: !30)
!33 = !DILocation(line: 24, column: 3, scope: !30)
!34 = !DILocation(line: 19, column: 14, scope: !30)

; The collapse, then a controlled write of the same rail, then the gate on q.
; CHECK-LABEL: define {{.*}}@measured_then_moved(
; CHECK:      %[[AH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[AR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[AH]], i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[AR]])
; CHECK:      %[[AF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[AH]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[AF]], i32 %[[AR]], double 9.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[AR]], double 1.250000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[AH]], double 3.000000e-01)

; Nothing touches r between its collapse and the gate.
; CHECK-LABEL: define {{.*}}@measured_untouched(
; CHECK:      %[[BR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[BH:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[BR]])
; CHECK-NEXT: store volatile
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[BH]], double 3.000000e-01)

; The writes of r come after the gate.
; CHECK-LABEL: define {{.*}}@measured_moved_after_gate(
; CHECK:      %[[CR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[CH:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[CR]])
; CHECK-NEXT: store volatile
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[CH]], double 3.000000e-01)
; CHECK:      call void @cqrt_ry_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[CR]], double 9.000000e-01)

; Every gate of @measured_then_moved warns, line 8 (T) included; nothing for
; @measured_untouched; the two writes after T warn and T (line 22) does not.
; WARN:      warning: {{.*}}cmr9.c:6:14: in function measured_then_moved i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT:  warning
; WARN:      warning: {{.*}}cmr9.c:7:3: in function measured_then_moved i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT:  warning
; WARN:      warning: {{.*}}cmr9.c:8:3: in function measured_then_moved i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT:  warning
; WARN:      warning: {{.*}}cmr9.c:23:14: in function measured_moved_after_gate i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT:  warning
; WARN:      warning: {{.*}}cmr9.c:24:3: in function measured_moved_after_gate i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT:  warning
