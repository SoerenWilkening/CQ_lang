; ACCEPT (bd `test_C_libtooling-01po.19`): the p16 cascade cut to ONE controlled step.
;
; `cq_theta(&q[0], .5); for (i = 1; i < 2; i++) if (q[i-1]) cq_theta(&q[i], .3*(i+1));`
; has a straight-line store beside the walk, so the rolled bank refused it (the
; generic `cq taint escape: tainted value stored to memory`). The constant-trip walk is
; unrolled and the array scalarized (RailBankUnroll.h): `if (q0) Ry(q1, 0.6)` on a fresh
; |0> rail, i.e. `cqrt_ry_i1_controlled(q0, q1, 0.6)` — R6's in-place controlled Ry.
;
; ANALYTIC: Ry(0.5)|0> = cos(.25)|0> + sin(.25)|1> on q0; the controlled Ry(0.6) on q1
; gives cos(.25)|00> + sin(.25)(cos(.3)|10> + sin(.3)|11>) (q0 first), the source's state.
;
; ⚠ COMPILED WITH `-g`, DELIBERATELY. The stage's first adoption spliced the trial
; clone's body back into the function, and `CloneFunction` mints a fresh DISubprogram:
; MEASURED, the verifier aborted ("!dbg attachment points at wrong subprogram for
; function") on every `-g` module the stage accepted. The fix re-runs the deterministic
; transformation on the original; this file is the regression pin.
;
; SOURCE (clang -g -O1, verbatim below):
;   #include <stdbool.h>
;   /* p16 shrunk to one controlled step: the array form of `if (q0) cq_theta(&q1,.6)`. */
;   int main(void) {
;     bool q[2] = {0};
;     cq_theta(&q[0], .5);
;     for (int i = 1; i < 2; i++)
;       if (q[i-1]) cq_theta(&q[i], .3 * (i + 1));
;     int r = 0;
;     for (int i = 0; i < 2; i++) r += cq_measure(q[i]);
;     return r;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --implicit-check-not='call {{.*}}@cq'
; CHECK-LABEL: define {{.*}} @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: %h2 = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1_controlled(i32 %h, i32 %h2, double 6.000000e-01)
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %h)
; CHECK: %m3 = call i1 @cqrt_measure_i1(i32 %h2)
; CHECK: ret i32

; ModuleID = 'p16_one.c'
source_filename = "p16_one.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca [2 x i8], align 2
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %1) #3, !dbg !26
    #dbg_declare(ptr %1, !16, !DIExpression(), !27)
  store i16 0, ptr %1, align 2, !dbg !27
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4, !dbg !28
  %3 = zext i1 %2 to i8, !dbg !28
  store i8 %3, ptr %1, align 2, !dbg !28, !tbaa !29
    #dbg_value(i32 1, !21, !DIExpression(), !33)
    #dbg_value(i32 poison, !21, !DIExpression(), !33)
  br i1 %2, label %4, label %10, !dbg !34

4:                                                ; preds = %0
  %5 = getelementptr inbounds i8, ptr %1, i64 1, !dbg !36
  %6 = load i8, ptr %5, align 1, !dbg !36, !tbaa !29, !range !38, !noundef !39
  %7 = trunc nuw i8 %6 to i1, !dbg !36
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 6.000000e-01) #4, !dbg !36
  %9 = zext i1 %8 to i8, !dbg !36
  store i8 %9, ptr %5, align 1, !dbg !36, !tbaa !29
  br label %10, !dbg !36

10:                                               ; preds = %0, %4
  br label %12, !dbg !40

11:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %1) #3, !dbg !41
  ret i32 %20, !dbg !42

12:                                               ; preds = %10, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %10 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %10 ]
    #dbg_value(i64 %13, !24, !DIExpression(), !43)
    #dbg_value(i32 %14, !23, !DIExpression(), !44)
  %15 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %13, !dbg !45
  %16 = load i8, ptr %15, align 1, !dbg !45, !tbaa !29, !range !38, !noundef !39
  %17 = trunc nuw i8 %16 to i1, !dbg !45
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3, !dbg !45
  %19 = zext i1 %18 to i32, !dbg !45
  %20 = add nuw nsw i32 %14, %19, !dbg !47
    #dbg_value(i32 %20, !23, !DIExpression(), !44)
  %21 = add nuw nsw i64 %13, 1, !dbg !48
    #dbg_value(i64 %21, !24, !DIExpression(), !43)
  %22 = icmp eq i64 %13, 0, !dbg !49
  br i1 %22, label %12, label %11, !dbg !40, !llvm.loop !50
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !54 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare !dbg !59 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "p16_one.c", directory: ".", checksumkind: CSK_MD5, checksum: "e53a55c7be16a0ebcbf459f89deeda07")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "p16_one.c", directory: ".", checksumkind: CSK_MD5, checksum: "e53a55c7be16a0ebcbf459f89deeda07")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !21, !23, !24}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 4, type: !17)
!17 = !DICompositeType(tag: DW_TAG_array_type, baseType: !18, size: 16, elements: !19)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !{!20}
!20 = !DISubrange(count: 2)
!21 = !DILocalVariable(name: "i", scope: !22, file: !11, line: 6, type: !14)
!22 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 3)
!23 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 8, type: !14)
!24 = !DILocalVariable(name: "i", scope: !25, file: !11, line: 9, type: !14)
!25 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 3)
!26 = !DILocation(line: 4, column: 3, scope: !10)
!27 = !DILocation(line: 4, column: 8, scope: !10)
!28 = !DILocation(line: 5, column: 3, scope: !10)
!29 = !{!30, !30, i64 0}
!30 = !{!"_Bool", !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C/C++ TBAA"}
!33 = !DILocation(line: 0, scope: !22)
!34 = !DILocation(line: 7, column: 9, scope: !35)
!35 = distinct !DILexicalBlock(scope: !22, file: !11, line: 6, column: 3)
!36 = !DILocation(line: 7, column: 17, scope: !37)
!37 = distinct !DILexicalBlock(scope: !35, file: !11, line: 7, column: 9)
!38 = !{i8 0, i8 2}
!39 = !{}
!40 = !DILocation(line: 9, column: 3, scope: !25)
!41 = !DILocation(line: 11, column: 1, scope: !10)
!42 = !DILocation(line: 10, column: 3, scope: !10)
!43 = !DILocation(line: 0, scope: !25)
!44 = !DILocation(line: 0, scope: !10)
!45 = !DILocation(line: 9, column: 36, scope: !46)
!46 = distinct !DILexicalBlock(scope: !25, file: !11, line: 9, column: 3)
!47 = !DILocation(line: 9, column: 33, scope: !46)
!48 = !DILocation(line: 9, column: 27, scope: !46)
!49 = !DILocation(line: 9, column: 21, scope: !46)
!50 = distinct !{!50, !40, !51, !52, !53}
!51 = !DILocation(line: 9, column: 36, scope: !25)
!52 = !{!"llvm.loop.mustprogress"}
!53 = !{!"llvm.loop.unroll.disable"}
!54 = !DISubprogram(name: "cq_theta_i1", scope: !55, file: !55, line: 93, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a0da27534ff7d9495/include/CQ.h", directory: "", checksumkind: CSK_MD5, checksum: "c73338595d27285d87c2371656290be5")
!56 = !DISubroutineType(types: !57)
!57 = !{!18, !18, !58}
!58 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!59 = !DISubprogram(name: "cq_measure_i1", scope: !55, file: !55, line: 138, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!18, !18}
