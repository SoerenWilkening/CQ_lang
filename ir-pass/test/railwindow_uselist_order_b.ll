; DECLINE (bd `test_C_libtooling-01po.19`, review round 1 F4, R8): the use-list
; twin of `railwindow_uselist_order_a.ll` (`uselistorder ptr %q, { 1, 0 }`); the
; CHECKs are identical to that file's.
;

; ⚠ bd `test_C_libtooling-01po.19` S4 (2026-10-15): DECLINE -> ACCEPT. The window
; model now LOWERS this array (RailWindow.h: handle array materialized at the
; quantization point, cell reads are borrowed roots, a cell rail is never freed
; or reverse-played). Reviewed by trace, not by green:
; ADVERSARIAL twin of _a (use-list order differs): the same stream, the same two theta rails measured.
; The S4 prefix pins the whole emitted runtime stream and that no rail is freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not=cqrt_free --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @main(
; S4: %q.rails = alloca i32, i64 2, align 4, !cq.railwindow !7
; S4: %h = call i32 @cqrt_alloc_i32(i32 0)
; S4: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; S4: %h5 = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; S4: %cq.win.in3 = load i32, ptr %cq.rail.addr1, align 4
; S4: %cq.win.in = load i32, ptr %cq.rail.addr, align 4
; S4: %h4 = call i32 @cqrt_alloc_i32(i32 0)
; S4: call void @cqrt_ry_i32(i32 %h4, double 2.500000e-01)
; S4: %m = call i32 @cqrt_measure_i32(i32 %h)
; S4: %m6 = call i32 @cqrt_measure_i32(i32 %h4)
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @main claims %q cells=i32 loads=2 stores=2 Q=  store i32 %t0, ptr %g0, align 4, !dbg !7
; WIN: CQ_RAILWINDOW_DBG: promote cell %q.rails in region %entry.split.split loads=1 stores=1 exits=0
; WIN: CQ_RAILWINDOW_DBG: promote cell (4 + %q.rails)<nuw> in region %entry.split.split loads=1 stores=1 exits=0
; WIN: CQ_RAILWINDOW_DBG: promoted 2 cell class(es)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double) nomerge
declare i32 @cq_measure_si32(i32)

define i32 @main() !dbg !5 {
entry:
  %q = alloca [2 x i32], align 4
  %g0 = getelementptr inbounds [2 x i32], ptr %q, i64 0, i64 0
  %g1 = getelementptr inbounds [2 x i32], ptr %q, i64 0, i64 1
  %t0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01), !dbg !10
  store i32 %t0, ptr %g0, align 4, !dbg !10
  %t1 = call i32 @cq_theta_si32(i32 0, double 2.500000e-01), !dbg !11
  store i32 %t1, ptr %g1, align 4, !dbg !11
  %l0 = load i32, ptr %g0, align 4, !dbg !12
  %l1 = load i32, ptr %g1, align 4, !dbg !12
  %m0 = call i32 @cq_measure_si32(i32 %l0), !dbg !12
  %m1 = call i32 @cq_measure_si32(i32 %l1), !dbg !12
  %r = add i32 %m0, %m1
  ret i32 %r, !dbg !12
  uselistorder ptr %q, { 1, 0 }
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "x", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!1 = !DIFile(filename: "u.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 7, !"Dwarf Version", i32 4}
!5 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!6 = !DISubroutineType(types: !7)
!7 = !{}
!10 = !DILocation(line: 10, column: 3, scope: !5)
!11 = !DILocation(line: 20, column: 3, scope: !5)
!12 = !DILocation(line: 30, column: 3, scope: !5)
