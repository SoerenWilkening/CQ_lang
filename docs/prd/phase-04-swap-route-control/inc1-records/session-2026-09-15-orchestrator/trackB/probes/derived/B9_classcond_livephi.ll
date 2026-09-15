; ModuleID = '/tmp/cqtrackB/b06_bank_classical_cond.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackB/probes/b06_bank_classical_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
  %3 = alloca [3 x i8], align 1
    #dbg_value(i32 %0, !18, !DIExpression(), !28)
    #dbg_value(ptr %1, !19, !DIExpression(), !28)
    #dbg_value(i32 %0, !20, !DIExpression(), !28)
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #3, !dbg !29
    #dbg_declare(ptr %3, !21, !DIExpression(), !30)
    #dbg_value(i32 0, !26, !DIExpression(), !31)
  %4 = icmp sgt i32 %0, 2
    #dbg_value(i32 0, !26, !DIExpression(), !31)
  br label %22, !dbg !32

5:                                                ; preds = %27
  %6 = load i8, ptr %3, align 1, !dbg !33, !tbaa !34, !range !38, !noundef !39
  %7 = trunc nuw i8 %6 to i1, !dbg !33
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3, !dbg !33
  %9 = zext i1 %8 to i32, !dbg !33
  %10 = getelementptr inbounds i8, ptr %3, i64 1, !dbg !40
  %11 = load i8, ptr %10, align 1, !dbg !40, !tbaa !34, !range !38, !noundef !39
  %12 = trunc nuw i8 %11 to i1, !dbg !40
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #3, !dbg !40
  %14 = zext i1 %13 to i32, !dbg !40
  %15 = add nuw nsw i32 %14, %9, !dbg !41
  %16 = getelementptr inbounds i8, ptr %3, i64 2, !dbg !42
  %17 = load i8, ptr %16, align 1, !dbg !42, !tbaa !34, !range !38, !noundef !39
  %18 = trunc nuw i8 %17 to i1, !dbg !42
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %18) #3, !dbg !42
  %20 = zext i1 %19 to i32, !dbg !42
  %21 = add nuw nsw i32 %15, %20, !dbg !43
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #3, !dbg !44
  ret i32 %21, !dbg !45

22:                                               ; preds = %27, %2
  %23 = phi i64 [ 0, %2 ], [ %28, %27 ]
    #dbg_value(i64 %23, !26, !DIExpression(), !31)
  br i1 %4, label %24, label %27, !dbg !46

24:                                               ; preds = %22
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3, !dbg !49
  br label %27, !dbg !52

27:                                               ; preds = %24, %22
  %cq.bank = phi i1 [ %25, %24 ], [ false, %22 ]
  %28 = add nuw nsw i64 %23, 1, !dbg !53
    #dbg_value(i64 %28, !26, !DIExpression(), !31)
  %29 = icmp eq i64 %28, 3, !dbg !54
  %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %23, !dbg !49
  %keep = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %cq.bank) #3, !dbg !51
  br i1 %29, label %5, label %22, !dbg !32, !llvm.loop !55
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !59 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare !dbg !64 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackB/probes/b06_bank_classical_cond.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "14e70f2ff6b50821230a3ee338e1acc5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19, !20, !21, !26}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 5, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 5, type: !14)
!20 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 7, type: !13)
!21 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 8, type: !22)
!22 = !DICompositeType(tag: DW_TAG_array_type, baseType: !23, size: 24, elements: !24)
!23 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!24 = !{!25}
!25 = !DISubrange(count: 3)
!26 = !DILocalVariable(name: "i", scope: !27, file: !8, line: 9, type: !13)
!27 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!28 = !DILocation(line: 0, scope: !10)
!29 = !DILocation(line: 8, column: 5, scope: !10)
!30 = !DILocation(line: 8, column: 10, scope: !10)
!31 = !DILocation(line: 0, scope: !27)
!32 = !DILocation(line: 9, column: 5, scope: !27)
!33 = !DILocation(line: 12, column: 12, scope: !10)
!34 = !{!35, !35, i64 0}
!35 = !{!"_Bool", !36, i64 0}
!36 = !{!"omnipotent char", !37, i64 0}
!37 = !{!"Simple C/C++ TBAA"}
!38 = !{i8 0, i8 2}
!39 = !{}
!40 = !DILocation(line: 12, column: 32, scope: !10)
!41 = !DILocation(line: 12, column: 30, scope: !10)
!42 = !DILocation(line: 12, column: 52, scope: !10)
!43 = !DILocation(line: 12, column: 50, scope: !10)
!44 = !DILocation(line: 13, column: 1, scope: !10)
!45 = !DILocation(line: 12, column: 5, scope: !10)
!46 = !DILocation(line: 10, column: 13, scope: !47)
!47 = distinct !DILexicalBlock(scope: !48, file: !8, line: 9, column: 33)
!48 = distinct !DILexicalBlock(scope: !27, file: !8, line: 9, column: 5)
!49 = !DILocation(line: 10, column: 29, scope: !50)
!50 = distinct !DILexicalBlock(scope: !47, file: !8, line: 10, column: 13)
!51 = !DILocation(line: 10, column: 27, scope: !50)
!52 = !DILocation(line: 10, column: 21, scope: !50)
!53 = !DILocation(line: 9, column: 28, scope: !48)
!54 = !DILocation(line: 9, column: 23, scope: !48)
!55 = distinct !{!55, !32, !56, !57, !58}
!56 = !DILocation(line: 11, column: 5, scope: !27)
!57 = !{!"llvm.loop.mustprogress"}
!58 = !{!"llvm.loop.unroll.disable"}
!59 = !DISubprogram(name: "cq_theta_i1", scope: !60, file: !60, line: 32, type: !61, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!61 = !DISubroutineType(types: !62)
!62 = !{!23, !23, !63}
!63 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!64 = !DISubprogram(name: "cq_measure_i1", scope: !60, file: !60, line: 77, type: !65, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!65 = !DISubroutineType(types: !66)
!66 = !{!23, !23}

