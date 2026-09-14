; ModuleID = 'b10_inplace_volatile_un.c'
source_filename = "b10_inplace_volatile_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !18
    #dbg_value(i32 %2, !15, !DIExpression(), !19)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !20
    #dbg_declare(ptr %1, !16, !DIExpression(), !21)
  store volatile i32 1, ptr %1, align 4, !dbg !21, !tbaa !22
  %3 = load volatile i32, ptr %1, align 4, !dbg !26, !tbaa !22
  %4 = xor i32 %3, %2, !dbg !27
    #dbg_value(i32 %4, !15, !DIExpression(), !19)
  %5 = load volatile i32, ptr %1, align 4, !dbg !28, !tbaa !22
  %6 = xor i32 %4, %5, !dbg !29
    #dbg_value(i32 %6, !15, !DIExpression(), !19)
  %7 = load volatile i32, ptr %1, align 4, !dbg !30, !tbaa !22
  %8 = xor i32 %6, %7, !dbg !31
    #dbg_value(i32 %8, !15, !DIExpression(), !19)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #3, !dbg !32
    #dbg_value(i32 %9, !15, !DIExpression(), !19)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3, !dbg !33
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !34
  ret i32 %10, !dbg !35
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !45
    #dbg_value(i32 %2, !15, !DIExpression(), !47)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !48
    #dbg_declare(ptr %1, !16, !DIExpression(), !49)
  store volatile i32 1, ptr %1, align 4, !dbg !49, !tbaa !22
  %3 = load volatile i32, ptr %1, align 4, !dbg !50, !tbaa !22
  %4 = xor i32 %3, %2, !dbg !51
    #dbg_value(i32 %4, !15, !DIExpression(), !47)
  %5 = load volatile i32, ptr %1, align 4, !dbg !52, !tbaa !22
  %6 = xor i32 %4, %5, !dbg !53
    #dbg_value(i32 %6, !15, !DIExpression(), !47)
  %7 = load volatile i32, ptr %1, align 4, !dbg !54, !tbaa !22
  %8 = xor i32 %6, %7, !dbg !55
    #dbg_value(i32 %8, !15, !DIExpression(), !47)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #3, !dbg !56
    #dbg_value(i32 %9, !15, !DIExpression(), !47)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3, !dbg !57
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !58
  ret i32 %10, !dbg !59
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!8 = !DIFile(filename: "b10_inplace_volatile_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "28e5cda326c96c92722722645281d4ae")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 4, type: !17)
!17 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!18 = !DILocation(line: 3, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 5, scope: !10)
!21 = !DILocation(line: 4, column: 18, scope: !10)
!22 = !{!23, !23, i64 0}
!23 = !{!"int", !24, i64 0}
!24 = !{!"omnipotent char", !25, i64 0}
!25 = !{!"Simple C/C++ TBAA"}
!26 = !DILocation(line: 5, column: 10, scope: !10)
!27 = !DILocation(line: 5, column: 7, scope: !10)
!28 = !DILocation(line: 5, column: 18, scope: !10)
!29 = !DILocation(line: 5, column: 15, scope: !10)
!30 = !DILocation(line: 5, column: 26, scope: !10)
!31 = !DILocation(line: 5, column: 23, scope: !10)
!32 = !DILocation(line: 6, column: 9, scope: !10)
!33 = !DILocation(line: 7, column: 12, scope: !10)
!34 = !DILocation(line: 8, column: 1, scope: !10)
!35 = !DILocation(line: 7, column: 5, scope: !10)
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 9, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 4, column: 5, scope: !10, inlinedAt: !46)
!49 = !DILocation(line: 4, column: 18, scope: !10, inlinedAt: !46)
!50 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !46)
!51 = !DILocation(line: 5, column: 7, scope: !10, inlinedAt: !46)
!52 = !DILocation(line: 5, column: 18, scope: !10, inlinedAt: !46)
!53 = !DILocation(line: 5, column: 15, scope: !10, inlinedAt: !46)
!54 = !DILocation(line: 5, column: 26, scope: !10, inlinedAt: !46)
!55 = !DILocation(line: 5, column: 23, scope: !10, inlinedAt: !46)
!56 = !DILocation(line: 6, column: 9, scope: !10, inlinedAt: !46)
!57 = !DILocation(line: 7, column: 12, scope: !10, inlinedAt: !46)
!58 = !DILocation(line: 8, column: 1, scope: !10, inlinedAt: !46)
!59 = !DILocation(line: 9, column: 18, scope: !44)
