; lowering_qram_reject_stale_index_i64.ll — DECLINE: a bare i64 QRAM index read
; AFTER an in-place `cq_theta` on its register (bd test_C_libtooling-r2j3.2, P1
; silent miscompile). Plain C, clang -O1:
;
;     long q = u; cq_theta(&q, .5);
;     long q2 = q; cq_theta(&q2, .3);  // chained, in-place Ry on q's register
;     int v = tbl[q];                // `q` names the PRE-Ry record
;
; The QROM emitter mints `cqrt_qram_load_i32(arr, q)` AT the load, after the Ry,
; so the copy-out reads the rotated register. MEASURED on the pre-fix binary:
; `opt` exit 0, stage 2b clean, trace `ry(h1,.5); ry(h1,.3); trunc(h1);
; qram_load(a0, h2)`. The `int` twin declined only because its widening `sext`
; (a pure op the stale-record sweep asks) was scheduled after the gate; a native
; i64 index has no op between the gep and the register. Fix: the sweep asks the
; pure-op question about the register a QRAM access reads, at the access
; (`qramAccessReads`), with the same diagnostic, anchored on the load's `!dbg`.
; RETIREMENT TRIGGER: this flips to ACCEPT when the stale-read lowering exists
; (owner question filed with r2j3.2); until then it must fail loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: stale.c:5:11:{{.*}}cq opcode lowering: operand predates a non-diagonal gate

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sl(i64)

define i32 @example(i64 %u) !dbg !4 {
entry:
  %q = call i64 @cq_theta_sl(i64 %u, double 5.000000e-01), !dbg !7
  %q2 = call i64 @cq_theta_sl(i64 %q, double 3.000000e-01), !dbg !8
  %p = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %q, !dbg !9
  %v = load i32, ptr %p, align 4, !dbg !9
  %m = call i32 @cq_measure_si32(i32 %v), !dbg !10
  %n = call i64 @cq_measure_sl(i64 %q2), !dbg !10
  %nt = trunc i64 %n to i32
  %s = add nsw i32 %m, %nt
  ret i32 %s
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "stale.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "example", scope: !1, file: !1, line: 2, type: !5, scopeLine: 2, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 3, column: 12, scope: !4)
!8 = !DILocation(line: 4, column: 13, scope: !4)
!9 = !DILocation(line: 5, column: 11, scope: !4)
!10 = !DILocation(line: 6, column: 10, scope: !4)
