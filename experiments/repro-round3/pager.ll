; ModuleID = 'sqlite/build/lib/linked.ll'
source_filename = "src/sqlite-amalgamation-3460100/sqlite3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.sqlite3StatType = type { [10 x i64], [10 x i64] }
%struct.Sqlite3Config = type { i32, i8, i8, i8, i8, i8, i8, i8, i32, i32, i32, i32, i32, %struct.sqlite3_mem_methods, %struct.sqlite3_mutex_methods, %struct.sqlite3_pcache_methods2, ptr, i32, i32, i32, i64, i64, ptr, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, ptr, ptr, ptr, i64, ptr, i32, ptr, i32, i32, i32 }
%struct.sqlite3_mem_methods = type { ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }
%struct.sqlite3_mutex_methods = type { ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }
%struct.sqlite3_pcache_methods2 = type { i32, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }
%struct.Mem0Global = type { ptr, i64, i64, i32 }
%struct.et_info = type { i8, i8, i8, i8, i8, i8 }
%struct.sqlite3PrngType = type { [16 x i32], [64 x i8], i8 }
%struct.sqlite3_vfs = type { i32, i32, i32, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }
%struct.FuncDefHash = type { [23 x ptr] }
%struct.PCacheGlobal = type { %struct.PGroup, i32, i32, i32, i32, i32, i32, ptr, ptr, ptr, ptr, i32, i32 }
%struct.PGroup = type { ptr, i32, i32, i32, i32, %struct.PgHdr1 }
%struct.PgHdr1 = type { %struct.sqlite3_pcache_page, i32, i16, i16, ptr, ptr, ptr, ptr }
%struct.sqlite3_pcache_page = type { ptr, ptr }
%struct.sqlite3_io_methods = type { i32, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr }
%struct.FuncDef = type { i8, i32, ptr, ptr, ptr, ptr, ptr, ptr, ptr, %union.anon.9 }
%union.anon.9 = type { ptr }
%struct.FpDecode = type { i8, i8, i32, i32, ptr, [24 x i8] }
%struct.__va_list_tag = type { i32, i32, ptr, ptr }
%struct.sqlite3_str = type { ptr, ptr, i32, i32, i32, i8, i8 }
%struct.PagerSavepoint = type { i64, i64, ptr, i32, i32, i32, [4 x i32] }
%struct.sqlite3_context = type { ptr, ptr, ptr, ptr, i32, i32, i8, i8, i8, [1 x ptr] }
%struct.sqlite3_value = type { %union.MemValue, ptr, i32, i16, i8, i8, ptr, i32, i32, ptr, ptr }
%union.MemValue = type { double }

@sqlite3Stat = external hidden unnamed_addr global %struct.sqlite3StatType, align 8
@sqlite3Config = external hidden global %struct.Sqlite3Config, align 8
@vfsList = external hidden unnamed_addr global ptr, align 8
@mem0 = external hidden unnamed_addr global %struct.Mem0Global, align 8
@.str = external hidden unnamed_addr constant [2 x i8], align 1
@fmtinfo = external hidden unnamed_addr constant [23 x %struct.et_info], align 16
@sqlite3_str_vappendf.zOrd = external hidden unnamed_addr constant [9 x i8], align 1
@aDigits = external hidden unnamed_addr constant [33 x i8], align 16
@aPrefix = external hidden unnamed_addr constant [7 x i8], align 1
@.str.1 = external hidden unnamed_addr constant [5 x i8], align 1
@.str.2 = external hidden unnamed_addr constant [4 x i8], align 1
@.str.3 = external hidden unnamed_addr constant [5 x i8], align 1
@.str.4 = external hidden unnamed_addr constant [1 x i8], align 1
@.str.5 = external hidden unnamed_addr constant [5 x i8], align 1
@.str.6 = external hidden unnamed_addr constant [7 x i8], align 1
@.str.7 = external hidden unnamed_addr constant [2 x i8], align 1
@.str.8 = external hidden unnamed_addr constant [10 x i8], align 1
@.str.9 = external hidden unnamed_addr constant [21 x i8], align 1
@.str.10 = external hidden unnamed_addr constant [14 x i8], align 1
@sqlite3Prng = external hidden global %struct.sqlite3PrngType, align 4
@sqlite3_randomness.chacha20_init = external hidden unnamed_addr constant [4 x i32], align 16
@sqlite3UpperToLower = external hidden unnamed_addr constant [274 x i8], align 16
@sqlite3_os_init.aVfs = external hidden global [9 x %struct.sqlite3_vfs], align 16
@sqlite3PendingByte = external hidden unnamed_addr global i32, align 4
@sqlite3CtypeMap = external hidden constant [256 x i8], align 16
@sqlite3BuiltinFunctions = external hidden unnamed_addr global %struct.FuncDefHash, align 8
@.str.45 = external hidden unnamed_addr constant [85 x i8], align 1
@.str.46 = external hidden unnamed_addr constant [2 x i8], align 1
@azTempDirs = external hidden unnamed_addr global [6 x ptr], align 16
@.str.81 = external hidden unnamed_addr constant [25 x i8], align 1
@.str.121 = external hidden unnamed_addr constant [14 x i8], align 1
@.str.122 = external hidden unnamed_addr constant [7 x i8], align 1
@pcache1_g = external hidden global %struct.PCacheGlobal, align 8
@memdb_vfs = external hidden global %struct.sqlite3_vfs, align 8
@MemJournalMethods = external hidden constant %struct.sqlite3_io_methods, align 8
@.str.144 = external hidden unnamed_addr constant [7 x i8], align 1
@.str.145 = external hidden unnamed_addr constant [19 x i8], align 1
@sqlite3Utf8Trans1 = external hidden unnamed_addr constant [64 x i8], align 16
@.str.146 = external hidden unnamed_addr constant [14 x i8], align 1
@sqlite3RegisterBuiltinFunctions.aBuiltinFunc = external hidden global [76 x %struct.FuncDef], align 16
@sqlite3AlterFunctions.aAlterTableFuncs = external hidden global [5 x %struct.FuncDef], align 16
@sqlite3WindowFunctions.aWindowFuncs = external hidden global [15 x %struct.FuncDef], align 16
@sqlite3RegisterDateTimeFunctions.aDateTimeFuncs = external hidden global [10 x %struct.FuncDef], align 16
@sqlite3RegisterJsonFunctions.aJsonFunc = external hidden global [34 x %struct.FuncDef], align 16
@sqlite3MemSetDefault.defaultMethods = external hidden constant %struct.sqlite3_mem_methods, align 8
@sqlite3PCacheSetDefault.defaultMethods = external hidden constant %struct.sqlite3_pcache_methods2, align 8
@.str.1323 = external hidden unnamed_addr constant [7 x i8], align 1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nounwind ssp uwtable
define i32 @sqlite3_initialize() local_unnamed_addr #1 {
  %1 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 340), align 4, !tbaa !6
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %3, label %444

3:                                                ; preds = %0
  store i32 1, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 348), align 4, !tbaa !16
  %4 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 352), align 8, !tbaa !17
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %27

6:                                                ; preds = %3
  %7 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), align 8, !tbaa !18
  %8 = icmp eq ptr %7, null
  br i1 %8, label %9, label %11

9:                                                ; preds = %6
  %10 = tail call i32 (i32, ...) @sqlite3_config(i32 noundef 4, ptr noundef nonnull @sqlite3MemSetDefault.defaultMethods)
  br label %11

11:                                               ; preds = %9, %6
  store ptr inttoptr (i64 8 to ptr), ptr @mem0, align 8, !tbaa !19
  %12 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 312), align 8, !tbaa !21
  %13 = icmp eq ptr %12, null
  %14 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 320), align 8
  %15 = icmp slt i32 %14, 512
  %16 = select i1 %13, i1 true, i1 %15
  %17 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 324), align 4
  %18 = icmp slt i32 %17, 1
  %19 = select i1 %16, i1 true, i1 %18
  br i1 %19, label %20, label %21

20:                                               ; preds = %11
  store ptr null, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 312), align 8, !tbaa !21
  store i32 0, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 320), align 8, !tbaa !22
  br label %21

21:                                               ; preds = %20, %11
  %22 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 72), align 8, !tbaa !23
  %23 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 88), align 8, !tbaa !24
  %24 = tail call i32 %22(ptr noundef %23) #16
  %25 = icmp eq i32 %24, 0
  br i1 %25, label %27, label %26

26:                                               ; preds = %21
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) @mem0, i8 0, i64 32, i1 false)
  br label %27

27:                                               ; preds = %26, %21, %3
  %28 = phi i32 [ 0, %3 ], [ %24, %21 ], [ %24, %26 ]
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %34

30:                                               ; preds = %27
  store i32 1, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 352), align 8, !tbaa !17
  %31 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 368), align 8, !tbaa !25
  %32 = icmp eq ptr %31, null
  br i1 %32, label %33, label %34

33:                                               ; preds = %30
  store ptr inttoptr (i64 8 to ptr), ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 368), align 8, !tbaa !25
  br label %34

34:                                               ; preds = %33, %30, %27
  %35 = phi i32 [ 0, %30 ], [ 0, %33 ], [ %28, %27 ]
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %444

37:                                               ; preds = %34
  %38 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 360), align 8, !tbaa !26
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 360), align 8, !tbaa !26
  %40 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 340), align 4, !tbaa !6
  %41 = icmp eq i32 %40, 0
  %42 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 344), align 8
  %43 = icmp eq i32 %42, 0
  %44 = select i1 %41, i1 %43, i1 false
  br i1 %44, label %45, label %435

45:                                               ; preds = %37
  store i32 1, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 344), align 8, !tbaa !27
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(184) @sqlite3BuiltinFunctions, i8 0, i64 184, i1 false)
  br label %46

46:                                               ; preds = %102, %45
  %47 = phi i64 [ 0, %45 ], [ %107, %102 ]
  %48 = getelementptr inbounds %struct.FuncDef, ptr @sqlite3AlterFunctions.aAlterTableFuncs, i64 %47
  %49 = getelementptr inbounds i8, ptr %48, i64 56
  %50 = load ptr, ptr %49, align 8, !tbaa !28
  %51 = icmp eq ptr %50, null
  br i1 %51, label %56, label %52

52:                                               ; preds = %46
  %53 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %50) #16
  %54 = trunc i64 %53 to i32
  %55 = and i32 %54, 1073741823
  br label %56

56:                                               ; preds = %52, %46
  %57 = phi i32 [ %55, %52 ], [ 0, %46 ]
  %58 = load i8, ptr %50, align 1, !tbaa !30
  %59 = sext i8 %58 to i32
  %60 = add nsw i32 %57, %59
  %61 = srem i32 %60, 23
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds [23 x ptr], ptr @sqlite3BuiltinFunctions, i64 0, i64 %62
  %64 = load ptr, ptr %63, align 8, !tbaa !30
  %65 = icmp eq ptr %64, null
  br i1 %65, label %94, label %66

66:                                               ; preds = %90, %56
  %67 = phi ptr [ %92, %90 ], [ %64, %56 ]
  %68 = getelementptr inbounds i8, ptr %67, i64 56
  %69 = load ptr, ptr %68, align 8, !tbaa !28
  br label %70

70:                                               ; preds = %86, %66
  %71 = phi ptr [ %50, %66 ], [ %88, %86 ]
  %72 = phi ptr [ %69, %66 ], [ %87, %86 ]
  %73 = load i8, ptr %72, align 1, !tbaa !30
  %74 = load i8, ptr %71, align 1, !tbaa !30
  %75 = icmp eq i8 %73, %74
  br i1 %75, label %76, label %78

76:                                               ; preds = %70
  %77 = icmp eq i8 %73, 0
  br i1 %77, label %89, label %86

78:                                               ; preds = %70
  %79 = zext i8 %73 to i64
  %80 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %79
  %81 = load i8, ptr %80, align 1, !tbaa !30
  %82 = zext i8 %74 to i64
  %83 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %82
  %84 = load i8, ptr %83, align 1, !tbaa !30
  %85 = icmp eq i8 %81, %84
  br i1 %85, label %86, label %89

86:                                               ; preds = %78, %76
  %87 = getelementptr inbounds i8, ptr %72, i64 1
  %88 = getelementptr inbounds i8, ptr %71, i64 1
  br label %70, !llvm.loop !31

89:                                               ; preds = %78, %76
  br i1 %75, label %94, label %90

90:                                               ; preds = %89
  %91 = getelementptr inbounds i8, ptr %67, i64 64
  %92 = load ptr, ptr %91, align 8, !tbaa !30
  %93 = icmp eq ptr %92, null
  br i1 %93, label %94, label %66, !llvm.loop !33

94:                                               ; preds = %90, %89, %56
  %95 = phi ptr [ null, %56 ], [ %67, %89 ], [ null, %90 ]
  %96 = icmp eq ptr %95, null
  br i1 %96, label %100, label %97

97:                                               ; preds = %94
  %98 = getelementptr inbounds i8, ptr %95, i64 16
  %99 = load ptr, ptr %98, align 8, !tbaa !35
  br label %102

100:                                              ; preds = %94
  %101 = getelementptr inbounds i8, ptr %48, i64 16
  store ptr null, ptr %101, align 8, !tbaa !35
  br label %102

102:                                              ; preds = %100, %97
  %103 = phi i64 [ 64, %100 ], [ 16, %97 ]
  %104 = phi ptr [ %64, %100 ], [ %99, %97 ]
  %105 = phi ptr [ %63, %100 ], [ %98, %97 ]
  %106 = getelementptr inbounds i8, ptr %48, i64 %103
  store ptr %104, ptr %106, align 8, !tbaa !30
  store ptr %48, ptr %105, align 8, !tbaa !36
  %107 = add nuw nsw i64 %47, 1
  %108 = icmp eq i64 %107, 5
  br i1 %108, label %109, label %46, !llvm.loop !37

109:                                              ; preds = %165, %102
  %110 = phi i64 [ %170, %165 ], [ 0, %102 ]
  %111 = getelementptr inbounds %struct.FuncDef, ptr @sqlite3WindowFunctions.aWindowFuncs, i64 %110
  %112 = getelementptr inbounds i8, ptr %111, i64 56
  %113 = load ptr, ptr %112, align 8, !tbaa !28
  %114 = icmp eq ptr %113, null
  br i1 %114, label %119, label %115

115:                                              ; preds = %109
  %116 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %113) #16
  %117 = trunc i64 %116 to i32
  %118 = and i32 %117, 1073741823
  br label %119

119:                                              ; preds = %115, %109
  %120 = phi i32 [ %118, %115 ], [ 0, %109 ]
  %121 = load i8, ptr %113, align 1, !tbaa !30
  %122 = sext i8 %121 to i32
  %123 = add nsw i32 %120, %122
  %124 = srem i32 %123, 23
  %125 = sext i32 %124 to i64
  %126 = getelementptr inbounds [23 x ptr], ptr @sqlite3BuiltinFunctions, i64 0, i64 %125
  %127 = load ptr, ptr %126, align 8, !tbaa !30
  %128 = icmp eq ptr %127, null
  br i1 %128, label %157, label %129

129:                                              ; preds = %153, %119
  %130 = phi ptr [ %155, %153 ], [ %127, %119 ]
  %131 = getelementptr inbounds i8, ptr %130, i64 56
  %132 = load ptr, ptr %131, align 8, !tbaa !28
  br label %133

133:                                              ; preds = %149, %129
  %134 = phi ptr [ %113, %129 ], [ %151, %149 ]
  %135 = phi ptr [ %132, %129 ], [ %150, %149 ]
  %136 = load i8, ptr %135, align 1, !tbaa !30
  %137 = load i8, ptr %134, align 1, !tbaa !30
  %138 = icmp eq i8 %136, %137
  br i1 %138, label %139, label %141

139:                                              ; preds = %133
  %140 = icmp eq i8 %136, 0
  br i1 %140, label %152, label %149

141:                                              ; preds = %133
  %142 = zext i8 %136 to i64
  %143 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %142
  %144 = load i8, ptr %143, align 1, !tbaa !30
  %145 = zext i8 %137 to i64
  %146 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %145
  %147 = load i8, ptr %146, align 1, !tbaa !30
  %148 = icmp eq i8 %144, %147
  br i1 %148, label %149, label %152

149:                                              ; preds = %141, %139
  %150 = getelementptr inbounds i8, ptr %135, i64 1
  %151 = getelementptr inbounds i8, ptr %134, i64 1
  br label %133, !llvm.loop !31

152:                                              ; preds = %141, %139
  br i1 %138, label %157, label %153

153:                                              ; preds = %152
  %154 = getelementptr inbounds i8, ptr %130, i64 64
  %155 = load ptr, ptr %154, align 8, !tbaa !30
  %156 = icmp eq ptr %155, null
  br i1 %156, label %157, label %129, !llvm.loop !33

157:                                              ; preds = %153, %152, %119
  %158 = phi ptr [ null, %119 ], [ %130, %152 ], [ null, %153 ]
  %159 = icmp eq ptr %158, null
  br i1 %159, label %163, label %160

160:                                              ; preds = %157
  %161 = getelementptr inbounds i8, ptr %158, i64 16
  %162 = load ptr, ptr %161, align 8, !tbaa !35
  br label %165

163:                                              ; preds = %157
  %164 = getelementptr inbounds i8, ptr %111, i64 16
  store ptr null, ptr %164, align 8, !tbaa !35
  br label %165

165:                                              ; preds = %163, %160
  %166 = phi i64 [ 64, %163 ], [ 16, %160 ]
  %167 = phi ptr [ %127, %163 ], [ %162, %160 ]
  %168 = phi ptr [ %126, %163 ], [ %161, %160 ]
  %169 = getelementptr inbounds i8, ptr %111, i64 %166
  store ptr %167, ptr %169, align 8, !tbaa !30
  store ptr %111, ptr %168, align 8, !tbaa !36
  %170 = add nuw nsw i64 %110, 1
  %171 = icmp eq i64 %170, 15
  br i1 %171, label %172, label %109, !llvm.loop !37

172:                                              ; preds = %228, %165
  %173 = phi i64 [ %233, %228 ], [ 0, %165 ]
  %174 = getelementptr inbounds %struct.FuncDef, ptr @sqlite3RegisterDateTimeFunctions.aDateTimeFuncs, i64 %173
  %175 = getelementptr inbounds i8, ptr %174, i64 56
  %176 = load ptr, ptr %175, align 8, !tbaa !28
  %177 = icmp eq ptr %176, null
  br i1 %177, label %182, label %178

178:                                              ; preds = %172
  %179 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %176) #16
  %180 = trunc i64 %179 to i32
  %181 = and i32 %180, 1073741823
  br label %182

182:                                              ; preds = %178, %172
  %183 = phi i32 [ %181, %178 ], [ 0, %172 ]
  %184 = load i8, ptr %176, align 1, !tbaa !30
  %185 = sext i8 %184 to i32
  %186 = add nsw i32 %183, %185
  %187 = srem i32 %186, 23
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds [23 x ptr], ptr @sqlite3BuiltinFunctions, i64 0, i64 %188
  %190 = load ptr, ptr %189, align 8, !tbaa !30
  %191 = icmp eq ptr %190, null
  br i1 %191, label %220, label %192

192:                                              ; preds = %216, %182
  %193 = phi ptr [ %218, %216 ], [ %190, %182 ]
  %194 = getelementptr inbounds i8, ptr %193, i64 56
  %195 = load ptr, ptr %194, align 8, !tbaa !28
  br label %196

196:                                              ; preds = %212, %192
  %197 = phi ptr [ %176, %192 ], [ %214, %212 ]
  %198 = phi ptr [ %195, %192 ], [ %213, %212 ]
  %199 = load i8, ptr %198, align 1, !tbaa !30
  %200 = load i8, ptr %197, align 1, !tbaa !30
  %201 = icmp eq i8 %199, %200
  br i1 %201, label %202, label %204

202:                                              ; preds = %196
  %203 = icmp eq i8 %199, 0
  br i1 %203, label %215, label %212

204:                                              ; preds = %196
  %205 = zext i8 %199 to i64
  %206 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %205
  %207 = load i8, ptr %206, align 1, !tbaa !30
  %208 = zext i8 %200 to i64
  %209 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %208
  %210 = load i8, ptr %209, align 1, !tbaa !30
  %211 = icmp eq i8 %207, %210
  br i1 %211, label %212, label %215

212:                                              ; preds = %204, %202
  %213 = getelementptr inbounds i8, ptr %198, i64 1
  %214 = getelementptr inbounds i8, ptr %197, i64 1
  br label %196, !llvm.loop !31

215:                                              ; preds = %204, %202
  br i1 %201, label %220, label %216

216:                                              ; preds = %215
  %217 = getelementptr inbounds i8, ptr %193, i64 64
  %218 = load ptr, ptr %217, align 8, !tbaa !30
  %219 = icmp eq ptr %218, null
  br i1 %219, label %220, label %192, !llvm.loop !33

220:                                              ; preds = %216, %215, %182
  %221 = phi ptr [ null, %182 ], [ %193, %215 ], [ null, %216 ]
  %222 = icmp eq ptr %221, null
  br i1 %222, label %226, label %223

223:                                              ; preds = %220
  %224 = getelementptr inbounds i8, ptr %221, i64 16
  %225 = load ptr, ptr %224, align 8, !tbaa !35
  br label %228

226:                                              ; preds = %220
  %227 = getelementptr inbounds i8, ptr %174, i64 16
  store ptr null, ptr %227, align 8, !tbaa !35
  br label %228

228:                                              ; preds = %226, %223
  %229 = phi i64 [ 64, %226 ], [ 16, %223 ]
  %230 = phi ptr [ %190, %226 ], [ %225, %223 ]
  %231 = phi ptr [ %189, %226 ], [ %224, %223 ]
  %232 = getelementptr inbounds i8, ptr %174, i64 %229
  store ptr %230, ptr %232, align 8, !tbaa !30
  store ptr %174, ptr %231, align 8, !tbaa !36
  %233 = add nuw nsw i64 %173, 1
  %234 = icmp eq i64 %233, 10
  br i1 %234, label %235, label %172, !llvm.loop !37

235:                                              ; preds = %291, %228
  %236 = phi i64 [ %296, %291 ], [ 0, %228 ]
  %237 = getelementptr inbounds %struct.FuncDef, ptr @sqlite3RegisterJsonFunctions.aJsonFunc, i64 %236
  %238 = getelementptr inbounds i8, ptr %237, i64 56
  %239 = load ptr, ptr %238, align 8, !tbaa !28
  %240 = icmp eq ptr %239, null
  br i1 %240, label %245, label %241

241:                                              ; preds = %235
  %242 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %239) #16
  %243 = trunc i64 %242 to i32
  %244 = and i32 %243, 1073741823
  br label %245

245:                                              ; preds = %241, %235
  %246 = phi i32 [ %244, %241 ], [ 0, %235 ]
  %247 = load i8, ptr %239, align 1, !tbaa !30
  %248 = sext i8 %247 to i32
  %249 = add nsw i32 %246, %248
  %250 = srem i32 %249, 23
  %251 = sext i32 %250 to i64
  %252 = getelementptr inbounds [23 x ptr], ptr @sqlite3BuiltinFunctions, i64 0, i64 %251
  %253 = load ptr, ptr %252, align 8, !tbaa !30
  %254 = icmp eq ptr %253, null
  br i1 %254, label %283, label %255

255:                                              ; preds = %279, %245
  %256 = phi ptr [ %281, %279 ], [ %253, %245 ]
  %257 = getelementptr inbounds i8, ptr %256, i64 56
  %258 = load ptr, ptr %257, align 8, !tbaa !28
  br label %259

259:                                              ; preds = %275, %255
  %260 = phi ptr [ %239, %255 ], [ %277, %275 ]
  %261 = phi ptr [ %258, %255 ], [ %276, %275 ]
  %262 = load i8, ptr %261, align 1, !tbaa !30
  %263 = load i8, ptr %260, align 1, !tbaa !30
  %264 = icmp eq i8 %262, %263
  br i1 %264, label %265, label %267

265:                                              ; preds = %259
  %266 = icmp eq i8 %262, 0
  br i1 %266, label %278, label %275

267:                                              ; preds = %259
  %268 = zext i8 %262 to i64
  %269 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %268
  %270 = load i8, ptr %269, align 1, !tbaa !30
  %271 = zext i8 %263 to i64
  %272 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %271
  %273 = load i8, ptr %272, align 1, !tbaa !30
  %274 = icmp eq i8 %270, %273
  br i1 %274, label %275, label %278

275:                                              ; preds = %267, %265
  %276 = getelementptr inbounds i8, ptr %261, i64 1
  %277 = getelementptr inbounds i8, ptr %260, i64 1
  br label %259, !llvm.loop !31

278:                                              ; preds = %267, %265
  br i1 %264, label %283, label %279

279:                                              ; preds = %278
  %280 = getelementptr inbounds i8, ptr %256, i64 64
  %281 = load ptr, ptr %280, align 8, !tbaa !30
  %282 = icmp eq ptr %281, null
  br i1 %282, label %283, label %255, !llvm.loop !33

283:                                              ; preds = %279, %278, %245
  %284 = phi ptr [ null, %245 ], [ %256, %278 ], [ null, %279 ]
  %285 = icmp eq ptr %284, null
  br i1 %285, label %289, label %286

286:                                              ; preds = %283
  %287 = getelementptr inbounds i8, ptr %284, i64 16
  %288 = load ptr, ptr %287, align 8, !tbaa !35
  br label %291

289:                                              ; preds = %283
  %290 = getelementptr inbounds i8, ptr %237, i64 16
  store ptr null, ptr %290, align 8, !tbaa !35
  br label %291

291:                                              ; preds = %289, %286
  %292 = phi i64 [ 64, %289 ], [ 16, %286 ]
  %293 = phi ptr [ %253, %289 ], [ %288, %286 ]
  %294 = phi ptr [ %252, %289 ], [ %287, %286 ]
  %295 = getelementptr inbounds i8, ptr %237, i64 %292
  store ptr %293, ptr %295, align 8, !tbaa !30
  store ptr %237, ptr %294, align 8, !tbaa !36
  %296 = add nuw nsw i64 %236, 1
  %297 = icmp eq i64 %296, 34
  br i1 %297, label %298, label %235, !llvm.loop !37

298:                                              ; preds = %354, %291
  %299 = phi i64 [ %359, %354 ], [ 0, %291 ]
  %300 = getelementptr inbounds %struct.FuncDef, ptr @sqlite3RegisterBuiltinFunctions.aBuiltinFunc, i64 %299
  %301 = getelementptr inbounds i8, ptr %300, i64 56
  %302 = load ptr, ptr %301, align 8, !tbaa !28
  %303 = icmp eq ptr %302, null
  br i1 %303, label %308, label %304

304:                                              ; preds = %298
  %305 = tail call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %302) #16
  %306 = trunc i64 %305 to i32
  %307 = and i32 %306, 1073741823
  br label %308

308:                                              ; preds = %304, %298
  %309 = phi i32 [ %307, %304 ], [ 0, %298 ]
  %310 = load i8, ptr %302, align 1, !tbaa !30
  %311 = sext i8 %310 to i32
  %312 = add nsw i32 %309, %311
  %313 = srem i32 %312, 23
  %314 = sext i32 %313 to i64
  %315 = getelementptr inbounds [23 x ptr], ptr @sqlite3BuiltinFunctions, i64 0, i64 %314
  %316 = load ptr, ptr %315, align 8, !tbaa !30
  %317 = icmp eq ptr %316, null
  br i1 %317, label %346, label %318

318:                                              ; preds = %342, %308
  %319 = phi ptr [ %344, %342 ], [ %316, %308 ]
  %320 = getelementptr inbounds i8, ptr %319, i64 56
  %321 = load ptr, ptr %320, align 8, !tbaa !28
  br label %322

322:                                              ; preds = %338, %318
  %323 = phi ptr [ %302, %318 ], [ %340, %338 ]
  %324 = phi ptr [ %321, %318 ], [ %339, %338 ]
  %325 = load i8, ptr %324, align 1, !tbaa !30
  %326 = load i8, ptr %323, align 1, !tbaa !30
  %327 = icmp eq i8 %325, %326
  br i1 %327, label %328, label %330

328:                                              ; preds = %322
  %329 = icmp eq i8 %325, 0
  br i1 %329, label %341, label %338

330:                                              ; preds = %322
  %331 = zext i8 %325 to i64
  %332 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %331
  %333 = load i8, ptr %332, align 1, !tbaa !30
  %334 = zext i8 %326 to i64
  %335 = getelementptr inbounds [274 x i8], ptr @sqlite3UpperToLower, i64 0, i64 %334
  %336 = load i8, ptr %335, align 1, !tbaa !30
  %337 = icmp eq i8 %333, %336
  br i1 %337, label %338, label %341

338:                                              ; preds = %330, %328
  %339 = getelementptr inbounds i8, ptr %324, i64 1
  %340 = getelementptr inbounds i8, ptr %323, i64 1
  br label %322, !llvm.loop !31

341:                                              ; preds = %330, %328
  br i1 %327, label %346, label %342

342:                                              ; preds = %341
  %343 = getelementptr inbounds i8, ptr %319, i64 64
  %344 = load ptr, ptr %343, align 8, !tbaa !30
  %345 = icmp eq ptr %344, null
  br i1 %345, label %346, label %318, !llvm.loop !33

346:                                              ; preds = %342, %341, %308
  %347 = phi ptr [ null, %308 ], [ %319, %341 ], [ null, %342 ]
  %348 = icmp eq ptr %347, null
  br i1 %348, label %352, label %349

349:                                              ; preds = %346
  %350 = getelementptr inbounds i8, ptr %347, i64 16
  %351 = load ptr, ptr %350, align 8, !tbaa !35
  br label %354

352:                                              ; preds = %346
  %353 = getelementptr inbounds i8, ptr %300, i64 16
  store ptr null, ptr %353, align 8, !tbaa !35
  br label %354

354:                                              ; preds = %352, %349
  %355 = phi i64 [ 64, %352 ], [ 16, %349 ]
  %356 = phi ptr [ %316, %352 ], [ %351, %349 ]
  %357 = phi ptr [ %315, %352 ], [ %350, %349 ]
  %358 = getelementptr inbounds i8, ptr %300, i64 %355
  store ptr %356, ptr %358, align 8, !tbaa !30
  store ptr %300, ptr %357, align 8, !tbaa !36
  %359 = add nuw nsw i64 %299, 1
  %360 = icmp eq i64 %359, 76
  br i1 %360, label %361, label %298, !llvm.loop !37

361:                                              ; preds = %354
  %362 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 356), align 4, !tbaa !38
  %363 = icmp eq i32 %362, 0
  br i1 %363, label %364, label %373

364:                                              ; preds = %361
  %365 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 184), align 8, !tbaa !39
  %366 = icmp eq ptr %365, null
  br i1 %366, label %367, label %369

367:                                              ; preds = %364
  %368 = tail call i32 (i32, ...) @sqlite3_config(i32 noundef 18, ptr noundef nonnull @sqlite3PCacheSetDefault.defaultMethods)
  br label %369

369:                                              ; preds = %367, %364
  %370 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 184), align 8, !tbaa !39
  %371 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 176), align 8, !tbaa !40
  %372 = tail call i32 %370(ptr noundef %371) #16
  br label %373

373:                                              ; preds = %369, %361
  %374 = phi i32 [ %372, %369 ], [ 0, %361 ]
  %375 = icmp eq i32 %374, 0
  br i1 %375, label %376, label %386

376:                                              ; preds = %373
  store i32 1, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 356), align 4, !tbaa !38
  %377 = tail call i32 @sqlite3_initialize()
  %378 = icmp eq i32 %377, 0
  br i1 %378, label %379, label %381

379:                                              ; preds = %376
  %380 = tail call fastcc ptr @sqlite3Malloc(i64 noundef 10)
  br label %381

381:                                              ; preds = %379, %376
  %382 = phi ptr [ null, %376 ], [ %380, %379 ]
  %383 = icmp eq ptr %382, null
  br i1 %383, label %386, label %384

384:                                              ; preds = %381
  tail call void @sqlite3_free(ptr noundef nonnull %382)
  %385 = tail call i32 @sqlite3_os_init()
  br label %386

386:                                              ; preds = %384, %381, %373
  %387 = phi i32 [ %374, %373 ], [ 0, %384 ], [ 7, %381 ]
  %388 = icmp eq i32 %387, 0
  br i1 %388, label %389, label %400

389:                                              ; preds = %386
  %390 = tail call i32 @sqlite3_initialize()
  %391 = icmp ne i32 %390, 0
  %392 = load ptr, ptr @vfsList, align 8
  %393 = icmp eq ptr %392, null
  %394 = select i1 %391, i1 true, i1 %393
  br i1 %394, label %400, label %395

395:                                              ; preds = %389
  %396 = getelementptr inbounds i8, ptr %392, i64 4
  %397 = load i32, ptr %396, align 4, !tbaa !41
  store ptr %392, ptr getelementptr inbounds (i8, ptr @memdb_vfs, i64 32), align 8, !tbaa !43
  %398 = tail call i32 @llvm.umax.i32(i32 %397, i32 24)
  store i32 %398, ptr getelementptr inbounds (i8, ptr @memdb_vfs, i64 4), align 4, !tbaa !41
  %399 = tail call i32 @sqlite3_vfs_register(ptr noundef nonnull @memdb_vfs, i32 noundef 0)
  br label %400

400:                                              ; preds = %395, %389, %386
  %401 = phi i32 [ %387, %386 ], [ %399, %395 ], [ 1, %389 ]
  %402 = icmp eq i32 %401, 0
  br i1 %402, label %403, label %434

403:                                              ; preds = %400
  %404 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 312), align 8, !tbaa !21
  %405 = load i32, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 80), align 8, !tbaa !44
  %406 = icmp eq i32 %405, 0
  br i1 %406, label %433, label %407

407:                                              ; preds = %403
  %408 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 324), align 4, !tbaa !50
  %409 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 320), align 8, !tbaa !22
  %410 = icmp eq ptr %404, null
  %411 = select i1 %410, i32 0, i32 %408
  %412 = icmp eq i32 %411, 0
  %413 = and i32 %409, -8
  %414 = select i1 %412, i32 0, i32 %413
  store i32 %414, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 92), align 4, !tbaa !51
  store i32 %411, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 136), align 8, !tbaa !52
  store i32 %411, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 96), align 8, !tbaa !53
  %415 = icmp sgt i32 %411, 90
  br i1 %415, label %419, label %416

416:                                              ; preds = %407
  %417 = sdiv i32 %411, 10
  %418 = add nsw i32 %417, 1
  br label %419

419:                                              ; preds = %416, %407
  %420 = phi i32 [ %418, %416 ], [ 10, %407 ]
  store i32 %420, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 100), align 4, !tbaa !54
  store ptr %404, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 104), align 8, !tbaa !55
  store ptr null, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 128), align 8, !tbaa !56
  store i32 0, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 140), align 4, !tbaa !57
  br i1 %412, label %431, label %421

421:                                              ; preds = %419
  %422 = sext i32 %414 to i64
  br label %423

423:                                              ; preds = %423, %421
  %424 = phi ptr [ %404, %421 ], [ %428, %423 ]
  %425 = phi i32 [ %411, %421 ], [ %427, %423 ]
  %426 = phi ptr [ null, %421 ], [ %424, %423 ]
  %427 = add nsw i32 %425, -1
  store ptr %426, ptr %424, align 8, !tbaa !58
  %428 = getelementptr inbounds i8, ptr %424, i64 %422
  %429 = icmp eq i32 %427, 0
  br i1 %429, label %430, label %423, !llvm.loop !60

430:                                              ; preds = %423
  store ptr %424, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 128), align 8, !tbaa !56
  br label %431

431:                                              ; preds = %430, %419
  %432 = phi ptr [ %428, %430 ], [ %404, %419 ]
  store ptr %432, ptr getelementptr inbounds (i8, ptr @pcache1_g, i64 112), align 8, !tbaa !61
  br label %433

433:                                              ; preds = %431, %403
  store i32 1, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 340), align 4, !tbaa !6
  br label %434

434:                                              ; preds = %433, %400
  store i32 0, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 344), align 8, !tbaa !27
  br label %435

435:                                              ; preds = %434, %37
  %436 = phi i32 [ %401, %434 ], [ 0, %37 ]
  %437 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 360), align 8, !tbaa !26
  %438 = add nsw i32 %437, -1
  store i32 %438, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 360), align 8, !tbaa !26
  %439 = icmp slt i32 %437, 2
  br i1 %439, label %440, label %441

440:                                              ; preds = %435
  store ptr null, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 368), align 8, !tbaa !25
  br label %441

441:                                              ; preds = %440, %435
  %442 = tail call fastcc i32 @hasHighPrecisionDouble(i32 noundef %436)
  %443 = trunc nuw nsw i32 %442 to i8
  store i8 %443, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 10), align 2, !tbaa !62
  br label %444

444:                                              ; preds = %441, %34, %0
  %445 = phi i32 [ %436, %441 ], [ 0, %0 ], [ %35, %34 ]
  ret i32 %445
}

; Function Attrs: nounwind ssp uwtable
define i32 @sqlite3_vfs_register(ptr noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @sqlite3_initialize()
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %38

5:                                                ; preds = %2
  %6 = icmp eq ptr %0, null
  br i1 %6, label %26, label %7

7:                                                ; preds = %5
  %8 = load ptr, ptr @vfsList, align 8, !tbaa !36
  %9 = icmp eq ptr %8, %0
  br i1 %9, label %22, label %10

10:                                               ; preds = %7
  %11 = icmp eq ptr %8, null
  br i1 %11, label %26, label %12

12:                                               ; preds = %12, %10
  %13 = phi ptr [ %15, %12 ], [ %8, %10 ]
  %14 = getelementptr inbounds i8, ptr %13, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !63
  %16 = icmp eq ptr %15, null
  %17 = icmp eq ptr %15, %0
  %18 = or i1 %16, %17
  br i1 %18, label %19, label %12, !llvm.loop !64

19:                                               ; preds = %12
  br i1 %17, label %20, label %26

20:                                               ; preds = %19
  %21 = getelementptr inbounds i8, ptr %13, i64 16
  br label %22

22:                                               ; preds = %20, %7
  %23 = phi ptr [ %21, %20 ], [ @vfsList, %7 ]
  %24 = getelementptr inbounds i8, ptr %0, i64 16
  %25 = load ptr, ptr %24, align 8, !tbaa !63
  store ptr %25, ptr %23, align 8, !tbaa !36
  br label %26

26:                                               ; preds = %22, %19, %10, %5
  %27 = icmp ne i32 %1, 0
  %28 = load ptr, ptr @vfsList, align 8
  %29 = icmp eq ptr %28, null
  %30 = select i1 %27, i1 true, i1 %29
  br i1 %30, label %34, label %31

31:                                               ; preds = %26
  %32 = getelementptr inbounds i8, ptr %28, i64 16
  %33 = load ptr, ptr %32, align 8, !tbaa !63
  br label %34

34:                                               ; preds = %31, %26
  %35 = phi ptr [ %33, %31 ], [ %28, %26 ]
  %36 = phi ptr [ %32, %31 ], [ @vfsList, %26 ]
  %37 = getelementptr inbounds i8, ptr %0, i64 16
  store ptr %35, ptr %37, align 8, !tbaa !63
  store ptr %0, ptr %36, align 8, !tbaa !36
  br label %38

38:                                               ; preds = %34, %2
  %39 = phi i32 [ %3, %2 ], [ 0, %34 ]
  ret i32 %39
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc ptr @sqlite3Malloc(i64 noundef %0) unnamed_addr #1 {
  %2 = add i64 %0, -2147483392
  %3 = icmp ult i64 %2, -2147483391
  br i1 %3, label %53, label %4

4:                                                ; preds = %1
  %5 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %49, label %7

7:                                                ; preds = %4
  %8 = trunc nuw nsw i64 %0 to i32
  %9 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 64), align 8, !tbaa !66
  %10 = tail call i32 %9(i32 noundef %8) #16
  %11 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 120), align 8, !tbaa !67
  %12 = icmp slt i64 %11, %0
  br i1 %12, label %13, label %14

13:                                               ; preds = %7
  store i64 %0, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 120), align 8, !tbaa !67
  br label %14

14:                                               ; preds = %13, %7
  %15 = load i64, ptr getelementptr inbounds (i8, ptr @mem0, i64 8), align 8, !tbaa !68
  %16 = icmp sgt i64 %15, 0
  br i1 %16, label %17, label %30

17:                                               ; preds = %14
  %18 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %19 = sext i32 %10 to i64
  %20 = sub nsw i64 %15, %19
  %21 = icmp slt i64 %18, %20
  br i1 %21, label %29, label %22

22:                                               ; preds = %17
  store atomic i32 1, ptr getelementptr inbounds (i8, ptr @mem0, i64 24) monotonic, align 8
  %23 = load i64, ptr getelementptr inbounds (i8, ptr @mem0, i64 16), align 8, !tbaa !69
  %24 = icmp eq i64 %23, 0
  br i1 %24, label %30, label %25

25:                                               ; preds = %22
  %26 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %27 = sub nsw i64 %23, %19
  %28 = icmp slt i64 %26, %27
  br i1 %28, label %30, label %53

29:                                               ; preds = %17
  store atomic i32 0, ptr getelementptr inbounds (i8, ptr @mem0, i64 24) monotonic, align 8
  br label %30

30:                                               ; preds = %29, %25, %22, %14
  %31 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), align 8, !tbaa !18
  %32 = tail call ptr %31(i32 noundef %10) #16
  %33 = icmp eq ptr %32, null
  br i1 %33, label %53, label %34

34:                                               ; preds = %30
  %35 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %36 = tail call i32 %35(ptr noundef nonnull %32) #16
  %37 = sext i32 %36 to i64
  %38 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %39 = add nsw i64 %38, %37
  store i64 %39, ptr @sqlite3Stat, align 8, !tbaa !67
  %40 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 80), align 8, !tbaa !67
  %41 = icmp sgt i64 %39, %40
  br i1 %41, label %42, label %43

42:                                               ; preds = %34
  store i64 %39, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 80), align 8, !tbaa !67
  br label %43

43:                                               ; preds = %42, %34
  %44 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %45 = add nsw i64 %44, 1
  store i64 %45, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %46 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 152), align 8, !tbaa !67
  %47 = icmp slt i64 %44, %46
  br i1 %47, label %53, label %48

48:                                               ; preds = %43
  store i64 %45, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 152), align 8, !tbaa !67
  br label %53

49:                                               ; preds = %4
  %50 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), align 8, !tbaa !18
  %51 = trunc nuw nsw i64 %0 to i32
  %52 = tail call ptr %50(i32 noundef %51) #16
  br label %53

53:                                               ; preds = %49, %48, %43, %30, %25, %1
  %54 = phi ptr [ %52, %49 ], [ null, %1 ], [ null, %25 ], [ %32, %48 ], [ %32, %43 ], [ %32, %30 ]
  ret ptr %54
}

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_free(ptr noundef %0) #1 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %16, label %3

3:                                                ; preds = %1
  %4 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %3
  %7 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %8 = tail call i32 %7(ptr noundef nonnull %0) #16
  %9 = sext i32 %8 to i64
  %10 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %11 = sub nsw i64 %10, %9
  store i64 %11, ptr @sqlite3Stat, align 8, !tbaa !67
  %12 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %13 = add nsw i64 %12, -1
  store i64 %13, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  br label %14

14:                                               ; preds = %6, %3
  %15 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %15(ptr noundef nonnull %0) #16
  br label %16

16:                                               ; preds = %14, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc ptr @sqlite3Realloc(ptr noundef %0, i64 noundef %1) unnamed_addr #1 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = tail call fastcc ptr @sqlite3Malloc(i64 noundef %1)
  br label %70

6:                                                ; preds = %2
  %7 = icmp eq i64 %1, 0
  br i1 %7, label %8, label %22

8:                                                ; preds = %6
  %9 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %20, label %11

11:                                               ; preds = %8
  %12 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %13 = tail call i32 %12(ptr noundef nonnull %0) #16
  %14 = sext i32 %13 to i64
  %15 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %16 = sub nsw i64 %15, %14
  store i64 %16, ptr @sqlite3Stat, align 8, !tbaa !67
  %17 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %18 = add nsw i64 %17, -1
  store i64 %18, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %19 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %19(ptr noundef nonnull %0) #16
  br label %70

20:                                               ; preds = %8
  %21 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %21(ptr noundef nonnull %0) #16
  br label %70

22:                                               ; preds = %6
  %23 = icmp ugt i64 %1, 2147483391
  br i1 %23, label %70, label %24

24:                                               ; preds = %22
  %25 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %26 = tail call i32 %25(ptr noundef nonnull %0) #16
  %27 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 64), align 8, !tbaa !66
  %28 = trunc nuw nsw i64 %1 to i32
  %29 = tail call i32 %27(i32 noundef %28) #16
  %30 = icmp eq i32 %26, %29
  br i1 %30, label %70, label %31

31:                                               ; preds = %24
  %32 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %67, label %34

34:                                               ; preds = %31
  %35 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 120), align 8, !tbaa !67
  %36 = icmp slt i64 %35, %1
  br i1 %36, label %37, label %38

37:                                               ; preds = %34
  store i64 %1, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 120), align 8, !tbaa !67
  br label %38

38:                                               ; preds = %37, %34
  %39 = sub nsw i32 %29, %26
  %40 = icmp sgt i32 %39, 0
  br i1 %40, label %41, label %53

41:                                               ; preds = %38
  %42 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %43 = load i64, ptr getelementptr inbounds (i8, ptr @mem0, i64 8), align 8, !tbaa !68
  %44 = zext nneg i32 %39 to i64
  %45 = sub nsw i64 %43, %44
  %46 = icmp slt i64 %42, %45
  br i1 %46, label %53, label %47

47:                                               ; preds = %41
  %48 = load i64, ptr getelementptr inbounds (i8, ptr @mem0, i64 16), align 8, !tbaa !69
  %49 = icmp slt i64 %48, 1
  %50 = sub nsw i64 %48, %44
  %51 = icmp slt i64 %42, %50
  %52 = select i1 %49, i1 true, i1 %51
  br i1 %52, label %53, label %70

53:                                               ; preds = %47, %41, %38
  %54 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 48), align 8, !tbaa !72
  %55 = tail call ptr %54(ptr noundef nonnull %0, i32 noundef %29) #16
  %56 = icmp eq ptr %55, null
  br i1 %56, label %70, label %57

57:                                               ; preds = %53
  %58 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %59 = tail call i32 %58(ptr noundef nonnull %55) #16
  %60 = sub nsw i32 %59, %26
  %61 = sext i32 %60 to i64
  %62 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %63 = add nsw i64 %62, %61
  store i64 %63, ptr @sqlite3Stat, align 8, !tbaa !67
  %64 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 80), align 8, !tbaa !67
  %65 = icmp sgt i64 %63, %64
  br i1 %65, label %66, label %70

66:                                               ; preds = %57
  store i64 %63, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 80), align 8, !tbaa !67
  br label %70

67:                                               ; preds = %31
  %68 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 48), align 8, !tbaa !72
  %69 = tail call ptr %68(ptr noundef nonnull %0, i32 noundef %29) #16
  br label %70

70:                                               ; preds = %67, %66, %57, %53, %47, %24, %22, %20, %11, %4
  %71 = phi ptr [ %5, %4 ], [ null, %22 ], [ %69, %67 ], [ %0, %24 ], [ null, %11 ], [ null, %20 ], [ null, %47 ], [ %55, %53 ], [ %55, %57 ], [ %55, %66 ]
  ret ptr %71
}

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_str_vappendf(ptr noundef %0, ptr noundef %1, ptr noundef %2) local_unnamed_addr #1 {
  %4 = alloca double, align 8
  %5 = alloca double, align 8
  %6 = alloca double, align 8
  %7 = alloca double, align 8
  %8 = alloca double, align 8
  %9 = alloca double, align 8
  %10 = alloca double, align 8
  %11 = alloca double, align 8
  %12 = alloca double, align 8
  %13 = alloca double, align 8
  %14 = alloca double, align 8
  %15 = alloca double, align 8
  %16 = alloca double, align 8
  %17 = alloca double, align 8
  %18 = alloca double, align 8
  %19 = alloca double, align 8
  %20 = alloca double, align 8
  %21 = alloca double, align 8
  %22 = alloca double, align 8
  %23 = alloca double, align 8
  %24 = alloca double, align 8
  %25 = alloca double, align 8
  %26 = alloca double, align 8
  %27 = alloca double, align 8
  %28 = alloca double, align 8
  %29 = alloca double, align 8
  %30 = alloca double, align 8
  %31 = alloca double, align 8
  %32 = alloca double, align 8
  %33 = alloca double, align 8
  %34 = alloca double, align 8
  %35 = alloca double, align 8
  %36 = alloca double, align 8
  %37 = alloca double, align 8
  %38 = alloca double, align 8
  %39 = alloca double, align 8
  %40 = alloca double, align 16
  %41 = alloca double, align 8
  %42 = alloca [70 x i8], align 16
  %43 = alloca %struct.FpDecode, align 8
  call void @llvm.lifetime.start.p0(i64 70, ptr nonnull %42) #16
  %44 = getelementptr inbounds i8, ptr %0, i64 29
  %45 = load i8, ptr %44, align 1, !tbaa !73
  %46 = and i8 %45, 2
  %47 = icmp eq i8 %46, 0
  br i1 %47, label %64, label %48

48:                                               ; preds = %3
  %49 = load i32, ptr %2, align 8
  %50 = icmp ult i32 %49, 41
  br i1 %50, label %51, label %57

51:                                               ; preds = %48
  %52 = getelementptr inbounds i8, ptr %2, i64 16
  %53 = load ptr, ptr %52, align 8
  %54 = zext nneg i32 %49 to i64
  %55 = getelementptr i8, ptr %53, i64 %54
  %56 = add nuw nsw i32 %49, 8
  store i32 %56, ptr %2, align 8
  br label %61

57:                                               ; preds = %48
  %58 = getelementptr inbounds i8, ptr %2, i64 8
  %59 = load ptr, ptr %58, align 8
  %60 = getelementptr i8, ptr %59, i64 8
  store ptr %60, ptr %58, align 8
  br label %61

61:                                               ; preds = %57, %51
  %62 = phi ptr [ %55, %51 ], [ %59, %57 ]
  %63 = load ptr, ptr %62, align 8, !tbaa !36
  br label %64

64:                                               ; preds = %61, %3
  %65 = phi ptr [ %63, %61 ], [ null, %3 ]
  %66 = getelementptr inbounds i8, ptr %0, i64 24
  %67 = getelementptr inbounds i8, ptr %0, i64 16
  %68 = getelementptr inbounds i8, ptr %0, i64 8
  %69 = getelementptr inbounds i8, ptr %65, i64 4
  %70 = getelementptr inbounds i8, ptr %65, i64 8
  %71 = getelementptr inbounds i8, ptr %2, i64 8
  %72 = getelementptr inbounds i8, ptr %2, i64 16
  %73 = getelementptr inbounds i8, ptr %65, i64 4
  %74 = getelementptr inbounds i8, ptr %65, i64 8
  %75 = getelementptr inbounds i8, ptr %2, i64 8
  %76 = getelementptr inbounds i8, ptr %2, i64 16
  %77 = getelementptr inbounds i8, ptr %2, i64 8
  %78 = getelementptr inbounds i8, ptr %2, i64 16
  %79 = getelementptr inbounds i8, ptr %0, i64 24
  %80 = getelementptr inbounds i8, ptr %0, i64 16
  %81 = getelementptr inbounds i8, ptr %0, i64 8
  %82 = getelementptr inbounds i8, ptr %0, i64 24
  %83 = getelementptr inbounds i8, ptr %0, i64 16
  %84 = getelementptr inbounds i8, ptr %0, i64 8
  %85 = getelementptr inbounds i8, ptr %0, i64 8
  %86 = getelementptr inbounds i8, ptr %0, i64 24
  %87 = getelementptr inbounds i8, ptr %0, i64 16
  %88 = getelementptr inbounds i8, ptr %0, i64 8
  %89 = getelementptr inbounds i8, ptr %0, i64 24
  %90 = getelementptr inbounds i8, ptr %0, i64 16
  %91 = getelementptr inbounds i8, ptr %0, i64 8
  %92 = getelementptr inbounds i8, ptr %2, i64 8
  %93 = getelementptr inbounds i8, ptr %2, i64 16
  %94 = getelementptr inbounds i8, ptr %0, i64 24
  %95 = getelementptr inbounds i8, ptr %0, i64 16
  %96 = getelementptr inbounds i8, ptr %0, i64 8
  %97 = getelementptr inbounds i8, ptr %2, i64 8
  %98 = getelementptr inbounds i8, ptr %2, i64 16
  %99 = getelementptr inbounds i8, ptr %0, i64 24
  %100 = getelementptr inbounds i8, ptr %0, i64 16
  %101 = getelementptr inbounds i8, ptr %0, i64 8
  %102 = getelementptr inbounds i8, ptr %65, i64 4
  %103 = getelementptr inbounds i8, ptr %65, i64 8
  %104 = getelementptr inbounds i8, ptr %2, i64 8
  %105 = getelementptr inbounds i8, ptr %2, i64 16
  %106 = getelementptr inbounds i8, ptr %0, i64 28
  %107 = getelementptr inbounds i8, ptr %0, i64 16
  %108 = getelementptr inbounds i8, ptr %0, i64 20
  %109 = getelementptr inbounds i8, ptr %0, i64 20
  %110 = getelementptr inbounds i8, ptr %65, i64 4
  %111 = getelementptr inbounds i8, ptr %65, i64 8
  %112 = getelementptr inbounds i8, ptr %2, i64 8
  %113 = getelementptr inbounds i8, ptr %2, i64 16
  %114 = getelementptr inbounds i8, ptr %0, i64 24
  %115 = getelementptr inbounds i8, ptr %0, i64 20
  %116 = getelementptr inbounds i8, ptr %0, i64 28
  %117 = getelementptr inbounds i8, ptr %0, i64 8
  %118 = getelementptr inbounds i8, ptr %0, i64 16
  %119 = getelementptr inbounds i8, ptr %65, i64 4
  %120 = getelementptr inbounds i8, ptr %65, i64 8
  %121 = getelementptr inbounds i8, ptr %2, i64 8
  %122 = getelementptr inbounds i8, ptr %2, i64 16
  %123 = getelementptr inbounds i8, ptr %42, i64 1
  %124 = getelementptr inbounds i8, ptr %42, i64 2
  %125 = getelementptr inbounds i8, ptr %42, i64 3
  %126 = getelementptr inbounds i8, ptr %42, i64 1
  %127 = getelementptr inbounds i8, ptr %42, i64 2
  %128 = getelementptr inbounds i8, ptr %42, i64 1
  %129 = getelementptr inbounds i8, ptr %0, i64 24
  %130 = getelementptr inbounds i8, ptr %0, i64 16
  %131 = getelementptr inbounds i8, ptr %0, i64 8
  %132 = getelementptr inbounds i8, ptr %0, i64 24
  %133 = getelementptr inbounds i8, ptr %0, i64 16
  %134 = getelementptr inbounds i8, ptr %0, i64 8
  %135 = getelementptr inbounds i8, ptr %0, i64 28
  %136 = getelementptr inbounds i8, ptr %0, i64 8
  %137 = getelementptr inbounds i8, ptr %0, i64 24
  %138 = getelementptr inbounds i8, ptr %2, i64 8
  %139 = getelementptr inbounds i8, ptr %2, i64 16
  %140 = getelementptr inbounds i8, ptr %65, i64 4
  %141 = getelementptr inbounds i8, ptr %65, i64 8
  %142 = getelementptr inbounds i8, ptr %2, i64 4
  %143 = getelementptr inbounds i8, ptr %2, i64 8
  %144 = getelementptr inbounds i8, ptr %2, i64 16
  %145 = getelementptr inbounds i8, ptr %43, i64 1
  %146 = getelementptr inbounds i8, ptr %43, i64 24
  %147 = getelementptr inbounds i8, ptr %43, i64 16
  %148 = getelementptr inbounds i8, ptr %43, i64 4
  %149 = getelementptr inbounds i8, ptr %43, i64 8
  %150 = getelementptr inbounds i8, ptr %43, i64 4
  %151 = getelementptr inbounds i8, ptr %43, i64 8
  %152 = getelementptr inbounds i8, ptr %43, i64 4
  %153 = getelementptr inbounds i8, ptr %43, i64 8
  %154 = getelementptr inbounds i8, ptr %43, i64 8
  %155 = getelementptr inbounds i8, ptr %43, i64 4
  %156 = getelementptr inbounds i8, ptr %43, i64 8
  %157 = getelementptr inbounds i8, ptr %0, i64 28
  %158 = getelementptr inbounds i8, ptr %0, i64 16
  %159 = getelementptr inbounds i8, ptr %0, i64 20
  %160 = getelementptr inbounds i8, ptr %0, i64 20
  %161 = getelementptr inbounds i8, ptr %43, i64 4
  %162 = getelementptr inbounds i8, ptr %43, i64 4
  %163 = getelementptr inbounds i8, ptr %42, i64 1
  %164 = getelementptr inbounds i8, ptr %65, i64 4
  %165 = getelementptr inbounds i8, ptr %65, i64 8
  %166 = getelementptr inbounds i8, ptr %2, i64 8
  %167 = getelementptr inbounds i8, ptr %2, i64 16
  %168 = getelementptr inbounds i8, ptr %2, i64 8
  %169 = getelementptr inbounds i8, ptr %2, i64 16
  %170 = getelementptr inbounds i8, ptr %2, i64 8
  %171 = getelementptr inbounds i8, ptr %2, i64 16
  %172 = getelementptr inbounds i8, ptr %65, i64 4
  %173 = getelementptr inbounds i8, ptr %65, i64 8
  %174 = getelementptr inbounds i8, ptr %2, i64 8
  %175 = getelementptr inbounds i8, ptr %2, i64 16
  %176 = getelementptr inbounds i8, ptr %2, i64 8
  %177 = getelementptr inbounds i8, ptr %2, i64 16
  %178 = getelementptr inbounds i8, ptr %2, i64 8
  %179 = getelementptr inbounds i8, ptr %2, i64 16
  %180 = getelementptr inbounds i8, ptr %0, i64 28
  %181 = getelementptr inbounds i8, ptr %0, i64 16
  %182 = getelementptr inbounds i8, ptr %0, i64 20
  %183 = getelementptr inbounds i8, ptr %0, i64 20
  %184 = getelementptr inbounds i8, ptr %0, i64 24
  %185 = getelementptr inbounds i8, ptr %0, i64 16
  %186 = getelementptr inbounds i8, ptr %0, i64 8
  %187 = getelementptr inbounds i8, ptr %0, i64 24
  %188 = getelementptr inbounds i8, ptr %0, i64 16
  %189 = getelementptr inbounds i8, ptr %0, i64 8
  %190 = getelementptr inbounds i8, ptr %0, i64 8
  %191 = getelementptr inbounds i8, ptr %0, i64 24
  %192 = getelementptr inbounds i8, ptr %0, i64 16
  %193 = getelementptr inbounds i8, ptr %0, i64 8
  %194 = getelementptr inbounds i8, ptr %0, i64 8
  br label %195

195:                                              ; preds = %2626, %64
  %196 = phi i32 [ undef, %64 ], [ %2492, %2626 ]
  %197 = phi i32 [ undef, %64 ], [ %2495, %2626 ]
  %198 = phi ptr [ null, %64 ], [ %2496, %2626 ]
  %199 = phi ptr [ %1, %64 ], [ %2627, %2626 ]
  %200 = load i8, ptr %199, align 1, !tbaa !30
  switch i8 %200, label %201 [
    i8 0, label %2628
    i8 37, label %226
  ]

201:                                              ; preds = %201, %195
  %202 = phi ptr [ %203, %201 ], [ %199, %195 ]
  %203 = getelementptr inbounds i8, ptr %202, i64 1
  %204 = load i8, ptr %203, align 1, !tbaa !30
  switch i8 %204, label %201 [
    i8 0, label %205
    i8 37, label %205
  ]

205:                                              ; preds = %201, %201
  %206 = ptrtoint ptr %203 to i64
  %207 = ptrtoint ptr %199 to i64
  %208 = sub i64 %206, %207
  %209 = trunc i64 %208 to i32
  %210 = load i32, ptr %66, align 8, !tbaa !75
  %211 = add i32 %210, %209
  %212 = load i32, ptr %67, align 8, !tbaa !76
  %213 = icmp ult i32 %211, %212
  br i1 %213, label %215, label %214

214:                                              ; preds = %205
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull %199, i32 noundef %209)
  br label %223

215:                                              ; preds = %205
  %216 = icmp eq i32 %209, 0
  br i1 %216, label %223, label %217

217:                                              ; preds = %215
  store i32 %211, ptr %66, align 8, !tbaa !75
  %218 = load ptr, ptr %68, align 8, !tbaa !77
  %219 = zext i32 %210 to i64
  %220 = getelementptr inbounds i8, ptr %218, i64 %219
  %221 = shl i64 %208, 32
  %222 = ashr exact i64 %221, 32
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %220, ptr noundef nonnull align 1 %199, i64 noundef %222, i1 noundef false) #16
  br label %223

223:                                              ; preds = %217, %215, %214
  %224 = load i8, ptr %203, align 1, !tbaa !30
  %225 = icmp eq i8 %224, 0
  br i1 %225, label %2628, label %226

226:                                              ; preds = %223, %195
  %227 = phi ptr [ %199, %223 ], [ %198, %195 ]
  %228 = phi ptr [ %203, %223 ], [ %199, %195 ]
  %229 = getelementptr inbounds i8, ptr %228, i64 1
  %230 = load i8, ptr %229, align 1, !tbaa !30
  %231 = icmp eq i8 %230, 0
  br i1 %231, label %232, label %245

232:                                              ; preds = %226
  %233 = getelementptr inbounds i8, ptr %0, i64 24
  %234 = load i32, ptr %233, align 8, !tbaa !75
  %235 = add i32 %234, 1
  %236 = getelementptr inbounds i8, ptr %0, i64 16
  %237 = load i32, ptr %236, align 8, !tbaa !76
  %238 = icmp ult i32 %235, %237
  br i1 %238, label %240, label %239

239:                                              ; preds = %232
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull @.str, i32 noundef 1)
  br label %2628

240:                                              ; preds = %232
  store i32 %235, ptr %233, align 8, !tbaa !75
  %241 = getelementptr inbounds i8, ptr %0, i64 8
  %242 = load ptr, ptr %241, align 8, !tbaa !77
  %243 = zext i32 %234 to i64
  %244 = getelementptr inbounds i8, ptr %242, i64 %243
  store i8 37, ptr %244, align 1
  br label %2628

245:                                              ; preds = %479, %226
  %246 = phi i8 [ %468, %479 ], [ 0, %226 ]
  %247 = phi i8 [ %469, %479 ], [ 0, %226 ]
  %248 = phi i8 [ %470, %479 ], [ 0, %226 ]
  %249 = phi i8 [ %471, %479 ], [ 0, %226 ]
  %250 = phi i8 [ %472, %479 ], [ 0, %226 ]
  %251 = phi i8 [ %473, %479 ], [ 0, %226 ]
  %252 = phi i8 [ %474, %479 ], [ 0, %226 ]
  %253 = phi i32 [ %475, %479 ], [ 0, %226 ]
  %254 = phi i32 [ %476, %479 ], [ -1, %226 ]
  %255 = phi i8 [ %481, %479 ], [ %230, %226 ]
  %256 = phi ptr [ %480, %479 ], [ %229, %226 ]
  %257 = sext i8 %255 to i32
  switch i8 %255, label %264 [
    i8 45, label %466
    i8 43, label %258
    i8 32, label %259
    i8 35, label %260
    i8 33, label %261
    i8 48, label %262
    i8 44, label %263
    i8 108, label %265
    i8 49, label %277
    i8 50, label %277
    i8 51, label %277
    i8 52, label %277
    i8 53, label %277
    i8 54, label %277
    i8 55, label %277
    i8 56, label %277
    i8 57, label %277
    i8 42, label %304
    i8 46, label %370
  ]

258:                                              ; preds = %245
  br label %466

259:                                              ; preds = %245
  br label %466

260:                                              ; preds = %245
  br label %466

261:                                              ; preds = %245
  br label %466

262:                                              ; preds = %245
  br label %466

263:                                              ; preds = %245
  br label %466

264:                                              ; preds = %245
  br label %466

265:                                              ; preds = %245
  %266 = getelementptr inbounds i8, ptr %256, i64 1
  %267 = load i8, ptr %266, align 1, !tbaa !30
  %268 = icmp eq i8 %267, 108
  br i1 %268, label %269, label %272

269:                                              ; preds = %265
  %270 = getelementptr inbounds i8, ptr %256, i64 2
  %271 = load i8, ptr %270, align 1, !tbaa !30
  br label %272

272:                                              ; preds = %269, %265
  %273 = phi i8 [ 2, %269 ], [ 1, %265 ]
  %274 = phi i8 [ %271, %269 ], [ %267, %265 ]
  %275 = phi ptr [ %270, %269 ], [ %266, %265 ]
  %276 = sext i8 %274 to i32
  br label %466

277:                                              ; preds = %245, %245, %245, %245, %245, %245, %245, %245, %245
  %278 = add nsw i32 %257, -48
  %279 = getelementptr inbounds i8, ptr %256, i64 1
  %280 = load i8, ptr %279, align 1, !tbaa !30
  %281 = sext i8 %280 to i32
  %282 = add i8 %280, -48
  %283 = icmp ult i8 %282, 10
  br i1 %283, label %284, label %296

284:                                              ; preds = %284, %277
  %285 = phi i32 [ %293, %284 ], [ %281, %277 ]
  %286 = phi ptr [ %291, %284 ], [ %279, %277 ]
  %287 = phi i32 [ %290, %284 ], [ %278, %277 ]
  %288 = mul i32 %287, 10
  %289 = add i32 %285, %288
  %290 = add i32 %289, -48
  %291 = getelementptr inbounds i8, ptr %286, i64 1
  %292 = load i8, ptr %291, align 1, !tbaa !30
  %293 = sext i8 %292 to i32
  %294 = add i8 %292, -48
  %295 = icmp ult i8 %294, 10
  br i1 %295, label %284, label %296, !llvm.loop !78

296:                                              ; preds = %284, %277
  %297 = phi ptr [ %256, %277 ], [ %286, %284 ]
  %298 = phi i32 [ %278, %277 ], [ %290, %284 ]
  %299 = phi ptr [ %279, %277 ], [ %291, %284 ]
  %300 = phi i8 [ %280, %277 ], [ %292, %284 ]
  %301 = phi i32 [ %281, %277 ], [ %293, %284 ]
  %302 = and i32 %298, 2147483647
  switch i8 %300, label %466 [
    i8 108, label %303
    i8 46, label %303
  ]

303:                                              ; preds = %296, %296
  br label %466

304:                                              ; preds = %245
  br i1 %47, label %344, label %305

305:                                              ; preds = %304
  %306 = load i32, ptr %65, align 8, !tbaa !79
  %307 = load i32, ptr %73, align 4, !tbaa !81
  %308 = icmp sgt i32 %306, %307
  br i1 %308, label %309, label %341

309:                                              ; preds = %305
  %310 = load ptr, ptr %74, align 8, !tbaa !82
  %311 = add nsw i32 %307, 1
  store i32 %311, ptr %73, align 4, !tbaa !81
  %312 = sext i32 %307 to i64
  %313 = getelementptr inbounds ptr, ptr %310, i64 %312
  %314 = load ptr, ptr %313, align 8, !tbaa !36
  %315 = getelementptr inbounds i8, ptr %314, i64 20
  %316 = load i16, ptr %315, align 4, !tbaa !83
  %317 = zext i16 %316 to i32
  %318 = and i32 %317, 36
  %319 = icmp eq i32 %318, 0
  br i1 %319, label %322, label %320

320:                                              ; preds = %309
  %321 = load i64, ptr %314, align 8, !tbaa !30
  br label %341

322:                                              ; preds = %309
  %323 = and i32 %317, 8
  %324 = icmp eq i32 %323, 0
  br i1 %324, label %332, label %325

325:                                              ; preds = %322
  %326 = load double, ptr %314, align 8, !tbaa !30
  %327 = fcmp olt double %326, 0xC3DFFFFFFFFFFFFF
  br i1 %327, label %341, label %328

328:                                              ; preds = %325
  %329 = fcmp ogt double %326, 0x43DFFFFFFFFFFFFF
  br i1 %329, label %341, label %330

330:                                              ; preds = %328
  %331 = fptosi double %326 to i64
  br label %341

332:                                              ; preds = %322
  %333 = and i32 %317, 18
  %334 = icmp eq i32 %333, 0
  br i1 %334, label %341, label %335

335:                                              ; preds = %332
  %336 = getelementptr inbounds i8, ptr %314, i64 8
  %337 = load ptr, ptr %336, align 8, !tbaa !85
  %338 = icmp eq ptr %337, null
  br i1 %338, label %341, label %339

339:                                              ; preds = %335
  %340 = call fastcc i64 @memIntValue(ptr noundef readonly %314)
  br label %341

341:                                              ; preds = %339, %335, %332, %330, %328, %325, %320, %305
  %342 = phi i64 [ 0, %305 ], [ %321, %320 ], [ %340, %339 ], [ 0, %335 ], [ 0, %332 ], [ %331, %330 ], [ -9223372036854775808, %325 ], [ 9223372036854775807, %328 ]
  %343 = trunc i64 %342 to i32
  br label %358

344:                                              ; preds = %304
  %345 = load i32, ptr %2, align 8
  %346 = icmp ult i32 %345, 41
  br i1 %346, label %347, label %352

347:                                              ; preds = %344
  %348 = load ptr, ptr %76, align 8
  %349 = zext nneg i32 %345 to i64
  %350 = getelementptr i8, ptr %348, i64 %349
  %351 = add nuw nsw i32 %345, 8
  store i32 %351, ptr %2, align 8
  br label %355

352:                                              ; preds = %344
  %353 = load ptr, ptr %75, align 8
  %354 = getelementptr i8, ptr %353, i64 8
  store ptr %354, ptr %75, align 8
  br label %355

355:                                              ; preds = %352, %347
  %356 = phi ptr [ %350, %347 ], [ %353, %352 ]
  %357 = load i32, ptr %356, align 4, !tbaa !86
  br label %358

358:                                              ; preds = %355, %341
  %359 = phi i32 [ %343, %341 ], [ %357, %355 ]
  %360 = icmp slt i32 %359, 0
  %361 = icmp eq i32 %359, -2147483648
  %362 = sub nsw i32 0, %359
  %363 = select i1 %361, i32 0, i32 %362
  %364 = select i1 %360, i8 1, i8 %252
  %365 = select i1 %360, i32 %363, i32 %359
  %366 = getelementptr inbounds i8, ptr %256, i64 1
  %367 = load i8, ptr %366, align 1, !tbaa !30
  %368 = sext i8 %367 to i32
  switch i8 %367, label %369 [
    i8 108, label %466
    i8 46, label %466
  ]

369:                                              ; preds = %358
  br label %466

370:                                              ; preds = %245
  %371 = getelementptr inbounds i8, ptr %256, i64 1
  %372 = load i8, ptr %371, align 1, !tbaa !30
  %373 = icmp eq i8 %372, 42
  br i1 %373, label %378, label %374

374:                                              ; preds = %370
  %375 = sext i8 %372 to i32
  %376 = add i8 %372, -48
  %377 = icmp ult i8 %376, 10
  br i1 %377, label %442, label %454

378:                                              ; preds = %370
  br i1 %47, label %418, label %379

379:                                              ; preds = %378
  %380 = load i32, ptr %65, align 8, !tbaa !79
  %381 = load i32, ptr %69, align 4, !tbaa !81
  %382 = icmp sgt i32 %380, %381
  br i1 %382, label %383, label %415

383:                                              ; preds = %379
  %384 = load ptr, ptr %70, align 8, !tbaa !82
  %385 = add nsw i32 %381, 1
  store i32 %385, ptr %69, align 4, !tbaa !81
  %386 = sext i32 %381 to i64
  %387 = getelementptr inbounds ptr, ptr %384, i64 %386
  %388 = load ptr, ptr %387, align 8, !tbaa !36
  %389 = getelementptr inbounds i8, ptr %388, i64 20
  %390 = load i16, ptr %389, align 4, !tbaa !83
  %391 = zext i16 %390 to i32
  %392 = and i32 %391, 36
  %393 = icmp eq i32 %392, 0
  br i1 %393, label %396, label %394

394:                                              ; preds = %383
  %395 = load i64, ptr %388, align 8, !tbaa !30
  br label %415

396:                                              ; preds = %383
  %397 = and i32 %391, 8
  %398 = icmp eq i32 %397, 0
  br i1 %398, label %406, label %399

399:                                              ; preds = %396
  %400 = load double, ptr %388, align 8, !tbaa !30
  %401 = fcmp olt double %400, 0xC3DFFFFFFFFFFFFF
  br i1 %401, label %415, label %402

402:                                              ; preds = %399
  %403 = fcmp ogt double %400, 0x43DFFFFFFFFFFFFF
  br i1 %403, label %415, label %404

404:                                              ; preds = %402
  %405 = fptosi double %400 to i64
  br label %415

406:                                              ; preds = %396
  %407 = and i32 %391, 18
  %408 = icmp eq i32 %407, 0
  br i1 %408, label %415, label %409

409:                                              ; preds = %406
  %410 = getelementptr inbounds i8, ptr %388, i64 8
  %411 = load ptr, ptr %410, align 8, !tbaa !85
  %412 = icmp eq ptr %411, null
  br i1 %412, label %415, label %413

413:                                              ; preds = %409
  %414 = call fastcc i64 @memIntValue(ptr noundef readonly %388)
  br label %415

415:                                              ; preds = %413, %409, %406, %404, %402, %399, %394, %379
  %416 = phi i64 [ 0, %379 ], [ %395, %394 ], [ %414, %413 ], [ 0, %409 ], [ 0, %406 ], [ %405, %404 ], [ -9223372036854775808, %399 ], [ 9223372036854775807, %402 ]
  %417 = trunc i64 %416 to i32
  br label %432

418:                                              ; preds = %378
  %419 = load i32, ptr %2, align 8
  %420 = icmp ult i32 %419, 41
  br i1 %420, label %421, label %426

421:                                              ; preds = %418
  %422 = load ptr, ptr %72, align 8
  %423 = zext nneg i32 %419 to i64
  %424 = getelementptr i8, ptr %422, i64 %423
  %425 = add nuw nsw i32 %419, 8
  store i32 %425, ptr %2, align 8
  br label %429

426:                                              ; preds = %418
  %427 = load ptr, ptr %71, align 8
  %428 = getelementptr i8, ptr %427, i64 8
  store ptr %428, ptr %71, align 8
  br label %429

429:                                              ; preds = %426, %421
  %430 = phi ptr [ %424, %421 ], [ %427, %426 ]
  %431 = load i32, ptr %430, align 4, !tbaa !86
  br label %432

432:                                              ; preds = %429, %415
  %433 = phi i32 [ %417, %415 ], [ %431, %429 ]
  %434 = icmp slt i32 %433, 0
  %435 = icmp eq i32 %433, -2147483648
  %436 = sub nsw i32 0, %433
  %437 = select i1 %435, i32 -1, i32 %436
  %438 = select i1 %434, i32 %437, i32 %433
  %439 = getelementptr inbounds i8, ptr %256, i64 2
  %440 = load i8, ptr %439, align 1, !tbaa !30
  %441 = sext i8 %440 to i32
  br label %459

442:                                              ; preds = %442, %374
  %443 = phi i32 [ %451, %442 ], [ %375, %374 ]
  %444 = phi ptr [ %449, %442 ], [ %371, %374 ]
  %445 = phi i32 [ %448, %442 ], [ 0, %374 ]
  %446 = mul i32 %445, 10
  %447 = add i32 %446, -48
  %448 = add i32 %447, %443
  %449 = getelementptr inbounds i8, ptr %444, i64 1
  %450 = load i8, ptr %449, align 1, !tbaa !30
  %451 = sext i8 %450 to i32
  %452 = add i8 %450, -48
  %453 = icmp ult i8 %452, 10
  br i1 %453, label %442, label %454, !llvm.loop !87

454:                                              ; preds = %442, %374
  %455 = phi i32 [ 0, %374 ], [ %448, %442 ]
  %456 = phi ptr [ %371, %374 ], [ %449, %442 ]
  %457 = phi i32 [ %375, %374 ], [ %451, %442 ]
  %458 = and i32 %455, 2147483647
  br label %459

459:                                              ; preds = %454, %432
  %460 = phi i32 [ %438, %432 ], [ %458, %454 ]
  %461 = phi i32 [ %441, %432 ], [ %457, %454 ]
  %462 = phi ptr [ %439, %432 ], [ %456, %454 ]
  %463 = icmp eq i32 %461, 108
  br i1 %463, label %464, label %466

464:                                              ; preds = %459
  %465 = getelementptr inbounds i8, ptr %462, i64 -1
  br label %466

466:                                              ; preds = %464, %459, %369, %358, %358, %303, %296, %272, %264, %263, %262, %261, %260, %259, %258, %245
  %467 = phi i1 [ false, %264 ], [ true, %464 ], [ false, %369 ], [ true, %358 ], [ false, %272 ], [ true, %263 ], [ true, %262 ], [ true, %261 ], [ true, %260 ], [ true, %259 ], [ true, %258 ], [ true, %245 ], [ true, %303 ], [ false, %296 ], [ false, %459 ], [ true, %358 ]
  %468 = phi i8 [ %246, %264 ], [ %246, %464 ], [ %246, %369 ], [ %246, %358 ], [ %246, %272 ], [ 44, %263 ], [ %246, %262 ], [ %246, %261 ], [ %246, %260 ], [ %246, %259 ], [ %246, %258 ], [ %246, %245 ], [ %246, %303 ], [ %246, %296 ], [ %246, %459 ], [ %246, %358 ]
  %469 = phi i8 [ %247, %264 ], [ %247, %464 ], [ %247, %369 ], [ %247, %358 ], [ %273, %272 ], [ %247, %263 ], [ %247, %262 ], [ %247, %261 ], [ %247, %260 ], [ %247, %259 ], [ %247, %258 ], [ %247, %245 ], [ %247, %303 ], [ %247, %296 ], [ %247, %459 ], [ %247, %358 ]
  %470 = phi i8 [ %248, %264 ], [ %248, %464 ], [ %248, %369 ], [ %248, %358 ], [ %248, %272 ], [ %248, %263 ], [ 1, %262 ], [ %248, %261 ], [ %248, %260 ], [ %248, %259 ], [ %248, %258 ], [ %248, %245 ], [ %248, %303 ], [ %248, %296 ], [ %248, %459 ], [ %248, %358 ]
  %471 = phi i8 [ %249, %264 ], [ %249, %464 ], [ %249, %369 ], [ %249, %358 ], [ %249, %272 ], [ %249, %263 ], [ %249, %262 ], [ 1, %261 ], [ %249, %260 ], [ %249, %259 ], [ %249, %258 ], [ %249, %245 ], [ %249, %303 ], [ %249, %296 ], [ %249, %459 ], [ %249, %358 ]
  %472 = phi i8 [ %250, %264 ], [ %250, %464 ], [ %250, %369 ], [ %250, %358 ], [ %250, %272 ], [ %250, %263 ], [ %250, %262 ], [ %250, %261 ], [ 1, %260 ], [ %250, %259 ], [ %250, %258 ], [ %250, %245 ], [ %250, %303 ], [ %250, %296 ], [ %250, %459 ], [ %250, %358 ]
  %473 = phi i8 [ %251, %264 ], [ %251, %464 ], [ %251, %369 ], [ %251, %358 ], [ %251, %272 ], [ %251, %263 ], [ %251, %262 ], [ %251, %261 ], [ %251, %260 ], [ %255, %259 ], [ %255, %258 ], [ %251, %245 ], [ %251, %303 ], [ %251, %296 ], [ %251, %459 ], [ %251, %358 ]
  %474 = phi i8 [ %252, %264 ], [ %252, %464 ], [ %364, %369 ], [ %364, %358 ], [ %252, %272 ], [ %252, %263 ], [ %252, %262 ], [ %252, %261 ], [ %252, %260 ], [ %252, %259 ], [ %252, %258 ], [ 1, %245 ], [ %252, %303 ], [ %252, %296 ], [ %252, %459 ], [ %364, %358 ]
  %475 = phi i32 [ %253, %264 ], [ %253, %464 ], [ %365, %369 ], [ %365, %358 ], [ %253, %272 ], [ %253, %263 ], [ %253, %262 ], [ %253, %261 ], [ %253, %260 ], [ %253, %259 ], [ %253, %258 ], [ %253, %245 ], [ %302, %303 ], [ %302, %296 ], [ %253, %459 ], [ %365, %358 ]
  %476 = phi i32 [ %254, %264 ], [ %460, %464 ], [ %254, %369 ], [ %254, %358 ], [ %254, %272 ], [ %254, %263 ], [ %254, %262 ], [ %254, %261 ], [ %254, %260 ], [ %254, %259 ], [ %254, %258 ], [ %254, %245 ], [ %254, %303 ], [ %254, %296 ], [ %460, %459 ], [ %254, %358 ]
  %477 = phi i32 [ %257, %264 ], [ 108, %464 ], [ %368, %369 ], [ %368, %358 ], [ %276, %272 ], [ 44, %263 ], [ 48, %262 ], [ 33, %261 ], [ 35, %260 ], [ 32, %259 ], [ 43, %258 ], [ 45, %245 ], [ %301, %303 ], [ %301, %296 ], [ %461, %459 ], [ %368, %358 ]
  %478 = phi ptr [ %256, %264 ], [ %465, %464 ], [ %366, %369 ], [ %256, %358 ], [ %275, %272 ], [ %256, %263 ], [ %256, %262 ], [ %256, %261 ], [ %256, %260 ], [ %256, %259 ], [ %256, %258 ], [ %256, %245 ], [ %297, %303 ], [ %299, %296 ], [ %462, %459 ], [ %256, %358 ]
  br i1 %467, label %479, label %483

479:                                              ; preds = %466
  %480 = getelementptr inbounds i8, ptr %478, i64 1
  %481 = load i8, ptr %480, align 1, !tbaa !30
  %482 = icmp eq i8 %481, 0
  br i1 %482, label %483, label %245, !llvm.loop !88

483:                                              ; preds = %479, %466
  %484 = phi i32 [ %477, %466 ], [ 0, %479 ]
  %485 = phi ptr [ %478, %466 ], [ %480, %479 ]
  br label %489

486:                                              ; preds = %489
  %487 = add nuw nsw i64 %490, 1
  %488 = icmp eq i64 %487, 23
  br i1 %488, label %498, label %489, !llvm.loop !89

489:                                              ; preds = %486, %483
  %490 = phi i64 [ 0, %483 ], [ %487, %486 ]
  %491 = getelementptr inbounds [23 x %struct.et_info], ptr @fmtinfo, i64 0, i64 %490
  %492 = load i8, ptr %491, align 2, !tbaa !90
  %493 = sext i8 %492 to i32
  %494 = icmp eq i32 %484, %493
  br i1 %494, label %495, label %486

495:                                              ; preds = %489
  %496 = getelementptr inbounds i8, ptr %491, i64 3
  %497 = load i8, ptr %496, align 1, !tbaa !92
  br label %498

498:                                              ; preds = %495, %486
  %499 = phi i8 [ %497, %495 ], [ 17, %486 ]
  %500 = phi ptr [ %491, %495 ], [ @fmtinfo, %486 ]
  switch i8 %499, label %2628 [
    i8 13, label %501
    i8 15, label %502
    i8 0, label %502
    i8 16, label %503
    i8 1, label %886
    i8 2, label %886
    i8 3, label %886
    i8 4, label %1694
    i8 7, label %1710
    i8 8, label %1711
    i8 5, label %1906
    i8 6, label %1906
    i8 9, label %2070
    i8 10, label %2070
    i8 14, label %2070
    i8 11, label %2236
    i8 12, label %2358
  ]

501:                                              ; preds = %498
  br label %503

502:                                              ; preds = %498, %498
  br label %503

503:                                              ; preds = %502, %501, %498
  %504 = phi i8 [ %468, %498 ], [ 0, %501 ], [ 0, %502 ]
  %505 = phi i8 [ %469, %498 ], [ 2, %501 ], [ %469, %502 ]
  %506 = getelementptr inbounds i8, ptr %500, i64 2
  %507 = load i8, ptr %506, align 1, !tbaa !93
  %508 = and i8 %507, 1
  %509 = icmp eq i8 %508, 0
  br i1 %509, label %592, label %510

510:                                              ; preds = %503
  br i1 %47, label %547, label %511

511:                                              ; preds = %510
  %512 = load i32, ptr %65, align 8, !tbaa !79
  %513 = load i32, ptr %164, align 4, !tbaa !81
  %514 = icmp sgt i32 %512, %513
  br i1 %514, label %515, label %587

515:                                              ; preds = %511
  %516 = load ptr, ptr %165, align 8, !tbaa !82
  %517 = add nsw i32 %513, 1
  store i32 %517, ptr %164, align 4, !tbaa !81
  %518 = sext i32 %513 to i64
  %519 = getelementptr inbounds ptr, ptr %516, i64 %518
  %520 = load ptr, ptr %519, align 8, !tbaa !36
  %521 = getelementptr inbounds i8, ptr %520, i64 20
  %522 = load i16, ptr %521, align 4, !tbaa !83
  %523 = zext i16 %522 to i32
  %524 = and i32 %523, 36
  %525 = icmp eq i32 %524, 0
  br i1 %525, label %528, label %526

526:                                              ; preds = %515
  %527 = load i64, ptr %520, align 8, !tbaa !30
  br label %587

528:                                              ; preds = %515
  %529 = and i32 %523, 8
  %530 = icmp eq i32 %529, 0
  br i1 %530, label %538, label %531

531:                                              ; preds = %528
  %532 = load double, ptr %520, align 8, !tbaa !30
  %533 = fcmp olt double %532, 0xC3DFFFFFFFFFFFFF
  br i1 %533, label %587, label %534

534:                                              ; preds = %531
  %535 = fcmp ogt double %532, 0x43DFFFFFFFFFFFFF
  br i1 %535, label %587, label %536

536:                                              ; preds = %534
  %537 = fptosi double %532 to i64
  br label %587

538:                                              ; preds = %528
  %539 = and i32 %523, 18
  %540 = icmp eq i32 %539, 0
  br i1 %540, label %587, label %541

541:                                              ; preds = %538
  %542 = getelementptr inbounds i8, ptr %520, i64 8
  %543 = load ptr, ptr %542, align 8, !tbaa !85
  %544 = icmp eq ptr %543, null
  br i1 %544, label %587, label %545

545:                                              ; preds = %541
  %546 = call fastcc i64 @memIntValue(ptr noundef readonly %520)
  br label %587

547:                                              ; preds = %510
  %548 = load i32, ptr %2, align 8
  %549 = icmp ult i32 %548, 41
  switch i8 %505, label %562 [
    i8 0, label %574
    i8 2, label %550
  ]

550:                                              ; preds = %547
  br i1 %549, label %551, label %556

551:                                              ; preds = %550
  %552 = load ptr, ptr %167, align 8
  %553 = zext nneg i32 %548 to i64
  %554 = getelementptr i8, ptr %552, i64 %553
  %555 = add nuw nsw i32 %548, 8
  store i32 %555, ptr %2, align 8
  br label %559

556:                                              ; preds = %550
  %557 = load ptr, ptr %166, align 8
  %558 = getelementptr i8, ptr %557, i64 8
  store ptr %558, ptr %166, align 8
  br label %559

559:                                              ; preds = %556, %551
  %560 = phi ptr [ %554, %551 ], [ %557, %556 ]
  %561 = load i64, ptr %560, align 8, !tbaa !67
  br label %587

562:                                              ; preds = %547
  br i1 %549, label %563, label %568

563:                                              ; preds = %562
  %564 = load ptr, ptr %171, align 8
  %565 = zext nneg i32 %548 to i64
  %566 = getelementptr i8, ptr %564, i64 %565
  %567 = add nuw nsw i32 %548, 8
  store i32 %567, ptr %2, align 8
  br label %571

568:                                              ; preds = %562
  %569 = load ptr, ptr %170, align 8
  %570 = getelementptr i8, ptr %569, i64 8
  store ptr %570, ptr %170, align 8
  br label %571

571:                                              ; preds = %568, %563
  %572 = phi ptr [ %566, %563 ], [ %569, %568 ]
  %573 = load i64, ptr %572, align 8, !tbaa !94
  br label %587

574:                                              ; preds = %547
  br i1 %549, label %575, label %580

575:                                              ; preds = %574
  %576 = load ptr, ptr %169, align 8
  %577 = zext nneg i32 %548 to i64
  %578 = getelementptr i8, ptr %576, i64 %577
  %579 = add nuw nsw i32 %548, 8
  store i32 %579, ptr %2, align 8
  br label %583

580:                                              ; preds = %574
  %581 = load ptr, ptr %168, align 8
  %582 = getelementptr i8, ptr %581, i64 8
  store ptr %582, ptr %168, align 8
  br label %583

583:                                              ; preds = %580, %575
  %584 = phi ptr [ %578, %575 ], [ %581, %580 ]
  %585 = load i32, ptr %584, align 4, !tbaa !86
  %586 = sext i32 %585 to i64
  br label %587

587:                                              ; preds = %583, %571, %559, %545, %541, %538, %536, %534, %531, %526, %511
  %588 = phi i64 [ %561, %559 ], [ %573, %571 ], [ %586, %583 ], [ 0, %511 ], [ %527, %526 ], [ %546, %545 ], [ 0, %541 ], [ 0, %538 ], [ %537, %536 ], [ -9223372036854775808, %531 ], [ 9223372036854775807, %534 ]
  %589 = icmp slt i64 %588, 0
  %590 = select i1 %589, i8 45, i8 %473
  %591 = call i64 @llvm.abs.i64(i64 %588, i1 false)
  br label %669

592:                                              ; preds = %503
  br i1 %47, label %629, label %593

593:                                              ; preds = %592
  %594 = load i32, ptr %65, align 8, !tbaa !79
  %595 = load i32, ptr %172, align 4, !tbaa !81
  %596 = icmp sgt i32 %594, %595
  br i1 %596, label %597, label %669

597:                                              ; preds = %593
  %598 = load ptr, ptr %173, align 8, !tbaa !82
  %599 = add nsw i32 %595, 1
  store i32 %599, ptr %172, align 4, !tbaa !81
  %600 = sext i32 %595 to i64
  %601 = getelementptr inbounds ptr, ptr %598, i64 %600
  %602 = load ptr, ptr %601, align 8, !tbaa !36
  %603 = getelementptr inbounds i8, ptr %602, i64 20
  %604 = load i16, ptr %603, align 4, !tbaa !83
  %605 = zext i16 %604 to i32
  %606 = and i32 %605, 36
  %607 = icmp eq i32 %606, 0
  br i1 %607, label %610, label %608

608:                                              ; preds = %597
  %609 = load i64, ptr %602, align 8, !tbaa !30
  br label %669

610:                                              ; preds = %597
  %611 = and i32 %605, 8
  %612 = icmp eq i32 %611, 0
  br i1 %612, label %620, label %613

613:                                              ; preds = %610
  %614 = load double, ptr %602, align 8, !tbaa !30
  %615 = fcmp olt double %614, 0xC3DFFFFFFFFFFFFF
  br i1 %615, label %669, label %616

616:                                              ; preds = %613
  %617 = fcmp ogt double %614, 0x43DFFFFFFFFFFFFF
  br i1 %617, label %669, label %618

618:                                              ; preds = %616
  %619 = fptosi double %614 to i64
  br label %669

620:                                              ; preds = %610
  %621 = and i32 %605, 18
  %622 = icmp eq i32 %621, 0
  br i1 %622, label %669, label %623

623:                                              ; preds = %620
  %624 = getelementptr inbounds i8, ptr %602, i64 8
  %625 = load ptr, ptr %624, align 8, !tbaa !85
  %626 = icmp eq ptr %625, null
  br i1 %626, label %669, label %627

627:                                              ; preds = %623
  %628 = call fastcc i64 @memIntValue(ptr noundef readonly %602)
  br label %669

629:                                              ; preds = %592
  %630 = load i32, ptr %2, align 8
  %631 = icmp ult i32 %630, 41
  switch i8 %505, label %644 [
    i8 0, label %656
    i8 2, label %632
  ]

632:                                              ; preds = %629
  br i1 %631, label %633, label %638

633:                                              ; preds = %632
  %634 = load ptr, ptr %175, align 8
  %635 = zext nneg i32 %630 to i64
  %636 = getelementptr i8, ptr %634, i64 %635
  %637 = add nuw nsw i32 %630, 8
  store i32 %637, ptr %2, align 8
  br label %641

638:                                              ; preds = %632
  %639 = load ptr, ptr %174, align 8
  %640 = getelementptr i8, ptr %639, i64 8
  store ptr %640, ptr %174, align 8
  br label %641

641:                                              ; preds = %638, %633
  %642 = phi ptr [ %636, %633 ], [ %639, %638 ]
  %643 = load i64, ptr %642, align 8, !tbaa !67
  br label %669

644:                                              ; preds = %629
  br i1 %631, label %645, label %650

645:                                              ; preds = %644
  %646 = load ptr, ptr %179, align 8
  %647 = zext nneg i32 %630 to i64
  %648 = getelementptr i8, ptr %646, i64 %647
  %649 = add nuw nsw i32 %630, 8
  store i32 %649, ptr %2, align 8
  br label %653

650:                                              ; preds = %644
  %651 = load ptr, ptr %178, align 8
  %652 = getelementptr i8, ptr %651, i64 8
  store ptr %652, ptr %178, align 8
  br label %653

653:                                              ; preds = %650, %645
  %654 = phi ptr [ %648, %645 ], [ %651, %650 ]
  %655 = load i64, ptr %654, align 8, !tbaa !94
  br label %669

656:                                              ; preds = %629
  br i1 %631, label %657, label %662

657:                                              ; preds = %656
  %658 = load ptr, ptr %177, align 8
  %659 = zext nneg i32 %630 to i64
  %660 = getelementptr i8, ptr %658, i64 %659
  %661 = add nuw nsw i32 %630, 8
  store i32 %661, ptr %2, align 8
  br label %665

662:                                              ; preds = %656
  %663 = load ptr, ptr %176, align 8
  %664 = getelementptr i8, ptr %663, i64 8
  store ptr %664, ptr %176, align 8
  br label %665

665:                                              ; preds = %662, %657
  %666 = phi ptr [ %660, %657 ], [ %663, %662 ]
  %667 = load i32, ptr %666, align 4, !tbaa !86
  %668 = zext i32 %667 to i64
  br label %669

669:                                              ; preds = %665, %653, %641, %627, %623, %620, %618, %616, %613, %608, %593, %587
  %670 = phi i8 [ %590, %587 ], [ 0, %665 ], [ 0, %653 ], [ 0, %641 ], [ 0, %593 ], [ 0, %608 ], [ 0, %613 ], [ 0, %616 ], [ 0, %618 ], [ 0, %620 ], [ 0, %623 ], [ 0, %627 ]
  %671 = phi i64 [ %591, %587 ], [ %668, %665 ], [ %655, %653 ], [ %643, %641 ], [ 0, %593 ], [ %609, %608 ], [ -9223372036854775808, %613 ], [ 9223372036854775807, %616 ], [ %619, %618 ], [ 0, %620 ], [ 0, %623 ], [ %628, %627 ]
  %672 = icmp eq i64 %671, 0
  %673 = icmp eq i8 %470, 0
  br i1 %673, label %679, label %674

674:                                              ; preds = %669
  %675 = icmp ne i8 %670, 0
  %676 = sext i1 %675 to i32
  %677 = add i32 %475, %676
  %678 = call i32 @llvm.smax.i32(i32 %476, i32 %677)
  br label %679

679:                                              ; preds = %674, %669
  %680 = phi i32 [ %476, %669 ], [ %678, %674 ]
  %681 = icmp slt i32 %680, 37
  br i1 %681, label %736, label %682

682:                                              ; preds = %679
  %683 = add nuw i32 %680, 10
  %684 = zext i32 %683 to i64
  %685 = icmp eq i8 %504, 0
  br i1 %685, label %690, label %686

686:                                              ; preds = %682
  %687 = udiv i32 %680, 3
  %688 = zext nneg i32 %687 to i64
  %689 = add nuw nsw i64 %684, %688
  br label %690

690:                                              ; preds = %686, %682
  %691 = phi i64 [ %689, %686 ], [ %684, %682 ]
  %692 = load i8, ptr %180, align 4, !tbaa !96
  %693 = icmp eq i8 %692, 0
  br i1 %693, label %694, label %731

694:                                              ; preds = %690
  %695 = load i32, ptr %181, align 8, !tbaa !76
  %696 = zext i32 %695 to i64
  %697 = icmp sgt i64 %691, %696
  br i1 %697, label %698, label %717

698:                                              ; preds = %694
  %699 = load i32, ptr %182, align 4, !tbaa !97
  %700 = zext i32 %699 to i64
  %701 = icmp sgt i64 %691, %700
  br i1 %701, label %702, label %717

702:                                              ; preds = %698
  store i8 18, ptr %180, align 4, !tbaa !96
  %703 = icmp eq i32 %699, 0
  br i1 %703, label %705, label %704

704:                                              ; preds = %702
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %705

705:                                              ; preds = %704, %702
  %706 = load ptr, ptr %0, align 8, !tbaa !98
  %707 = icmp eq ptr %706, null
  br i1 %707, label %731, label %708

708:                                              ; preds = %705
  %709 = getelementptr inbounds i8, ptr %706, i64 344
  %710 = load ptr, ptr %709, align 8, !tbaa !99
  %711 = icmp eq ptr %710, null
  br i1 %711, label %731, label %712

712:                                              ; preds = %708
  %713 = getelementptr inbounds i8, ptr %710, i64 24
  store i32 18, ptr %713, align 8, !tbaa !105
  %714 = getelementptr inbounds i8, ptr %710, i64 48
  %715 = load i32, ptr %714, align 8, !tbaa !108
  %716 = add nsw i32 %715, 1
  store i32 %716, ptr %714, align 8, !tbaa !108
  br label %731

717:                                              ; preds = %698, %694
  %718 = load ptr, ptr %0, align 8, !tbaa !98
  %719 = icmp eq ptr %718, null
  br i1 %719, label %722, label %720

720:                                              ; preds = %717
  %721 = call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %718, i64 noundef %691)
  br label %724

722:                                              ; preds = %717
  %723 = call fastcc ptr @sqlite3Malloc(i64 noundef %691)
  br label %724

724:                                              ; preds = %722, %720
  %725 = phi ptr [ %721, %720 ], [ %723, %722 ]
  %726 = icmp eq ptr %725, null
  br i1 %726, label %727, label %731

727:                                              ; preds = %724
  store i8 7, ptr %180, align 4, !tbaa !96
  %728 = load i32, ptr %183, align 4, !tbaa !97
  %729 = icmp eq i32 %728, 0
  br i1 %729, label %731, label %730

730:                                              ; preds = %727
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %731

731:                                              ; preds = %730, %727, %724, %712, %708, %705, %690
  %732 = phi ptr [ null, %690 ], [ %725, %724 ], [ null, %705 ], [ null, %708 ], [ null, %712 ], [ %725, %727 ], [ %725, %730 ]
  %733 = icmp eq ptr %732, null
  %734 = trunc nuw i64 %691 to i32
  %735 = select i1 %733, i32 %196, i32 %734
  br i1 %733, label %2628, label %736

736:                                              ; preds = %731, %679
  %737 = phi ptr [ %732, %731 ], [ %42, %679 ]
  %738 = phi i32 [ %735, %731 ], [ 70, %679 ]
  %739 = phi ptr [ %732, %731 ], [ null, %679 ]
  %740 = ptrtoint ptr %737 to i64
  %741 = add nsw i32 %738, -1
  %742 = sext i32 %741 to i64
  %743 = getelementptr inbounds i8, ptr %737, i64 %742
  %744 = icmp eq i8 %499, 15
  br i1 %744, label %745, label %764

745:                                              ; preds = %736
  %746 = urem i64 %671, 10
  %747 = udiv i64 %671, 10
  %748 = icmp ugt i64 %746, 3
  %749 = trunc nuw nsw i64 %746 to i32
  %750 = urem i64 %747, 10
  %751 = icmp eq i64 %750, 1
  %752 = select i1 %748, i1 true, i1 %751
  %753 = select i1 %752, i32 0, i32 %749
  %754 = shl nuw nsw i32 %753, 1
  %755 = or disjoint i32 %754, 1
  %756 = zext nneg i32 %755 to i64
  %757 = getelementptr inbounds [9 x i8], ptr @sqlite3_str_vappendf.zOrd, i64 0, i64 %756
  %758 = load i8, ptr %757, align 1, !tbaa !30
  %759 = getelementptr inbounds i8, ptr %743, i64 -1
  store i8 %758, ptr %759, align 1, !tbaa !30
  %760 = zext nneg i32 %754 to i64
  %761 = getelementptr inbounds [9 x i8], ptr @sqlite3_str_vappendf.zOrd, i64 0, i64 %760
  %762 = load i8, ptr %761, align 1, !tbaa !30
  %763 = getelementptr inbounds i8, ptr %743, i64 -2
  store i8 %762, ptr %763, align 1, !tbaa !30
  br label %764

764:                                              ; preds = %745, %736
  %765 = phi ptr [ %763, %745 ], [ %743, %736 ]
  %766 = ptrtoint ptr %765 to i64
  %767 = getelementptr inbounds i8, ptr %500, i64 4
  %768 = load i8, ptr %767, align 1, !tbaa !109
  %769 = zext i8 %768 to i64
  %770 = getelementptr inbounds [33 x i8], ptr @aDigits, i64 0, i64 %769
  %771 = getelementptr inbounds i8, ptr %500, i64 1
  %772 = load i8, ptr %771, align 1, !tbaa !110
  %773 = zext i8 %772 to i64
  %774 = getelementptr i8, ptr %765, i64 -2
  %775 = add i32 %680, -1
  %776 = trunc i64 %766 to i32
  %777 = add i32 %775, %776
  %778 = trunc i64 %740 to i32
  %779 = add i32 %738, %778
  %780 = sub i32 %777, %779
  br label %781

781:                                              ; preds = %781, %764
  %782 = phi i32 [ %795, %781 ], [ %780, %764 ]
  %783 = phi ptr [ %794, %781 ], [ %774, %764 ]
  %784 = phi i64 [ %793, %781 ], [ 0, %764 ]
  %785 = phi i64 [ %791, %781 ], [ %671, %764 ]
  %786 = phi ptr [ %790, %781 ], [ %765, %764 ]
  %787 = urem i64 %785, %773
  %788 = getelementptr inbounds i8, ptr %770, i64 %787
  %789 = load i8, ptr %788, align 1, !tbaa !30
  %790 = getelementptr inbounds i8, ptr %786, i64 -1
  store i8 %789, ptr %790, align 1, !tbaa !30
  %791 = udiv i64 %785, %773
  %792 = icmp ult i64 %785, %773
  %793 = add i64 %784, 1
  %794 = getelementptr i8, ptr %783, i64 -1
  %795 = add i32 %782, -1
  br i1 %792, label %796, label %781, !llvm.loop !111

796:                                              ; preds = %781
  %797 = ptrtoint ptr %743 to i64
  %798 = ptrtoint ptr %790 to i64
  %799 = sub i64 %797, %798
  %800 = trunc i64 %799 to i32
  %801 = icmp sgt i32 %680, %800
  br i1 %801, label %802, label %820

802:                                              ; preds = %796
  %803 = sub i64 -2, %784
  %804 = getelementptr i8, ptr %765, i64 %803
  %805 = add i32 %680, -1
  %806 = trunc i64 %766 to i32
  %807 = add i32 %805, %806
  %808 = trunc i64 %740 to i32
  %809 = add i32 %738, %808
  %810 = trunc i64 %784 to i32
  %811 = add i32 %809, %810
  %812 = sub i32 %807, %811
  %813 = zext i32 %812 to i64
  %814 = sub nsw i64 0, %813
  %815 = getelementptr i8, ptr %804, i64 %814
  %816 = add nuw nsw i64 %813, 1
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %815, i8 48, i64 %816, i1 false), !tbaa !30
  %817 = zext i32 %782 to i64
  %818 = sub nsw i64 0, %817
  %819 = getelementptr i8, ptr %783, i64 %818
  br label %820

820:                                              ; preds = %802, %796
  %821 = phi i32 [ %800, %796 ], [ %680, %802 ]
  %822 = phi ptr [ %790, %796 ], [ %819, %802 ]
  %823 = icmp eq i8 %504, 0
  br i1 %823, label %857, label %824

824:                                              ; preds = %820
  %825 = add nsw i32 %821, -1
  %826 = sdiv i32 %825, 3
  %827 = srem i32 %825, 3
  %828 = zext nneg i32 %826 to i64
  %829 = sub nsw i64 0, %828
  %830 = getelementptr inbounds i8, ptr %822, i64 %829
  %831 = icmp sgt i32 %821, 3
  br i1 %831, label %832, label %857

832:                                              ; preds = %824
  %833 = add nsw i32 %827, 1
  br label %834

834:                                              ; preds = %851, %832
  %835 = phi i32 [ %855, %851 ], [ 0, %832 ]
  %836 = phi i32 [ %853, %851 ], [ %833, %832 ]
  %837 = phi i32 [ %852, %851 ], [ %826, %832 ]
  %838 = add nsw i32 %835, %837
  %839 = sext i32 %838 to i64
  %840 = getelementptr inbounds i8, ptr %830, i64 %839
  %841 = load i8, ptr %840, align 1, !tbaa !30
  %842 = sext i32 %835 to i64
  %843 = getelementptr inbounds i8, ptr %830, i64 %842
  store i8 %841, ptr %843, align 1, !tbaa !30
  %844 = add nsw i32 %836, -1
  %845 = icmp eq i32 %844, 0
  br i1 %845, label %846, label %851

846:                                              ; preds = %834
  %847 = add nsw i32 %835, 1
  %848 = sext i32 %847 to i64
  %849 = getelementptr inbounds i8, ptr %830, i64 %848
  store i8 %504, ptr %849, align 1, !tbaa !30
  %850 = add nsw i32 %837, -1
  br label %851

851:                                              ; preds = %846, %834
  %852 = phi i32 [ %850, %846 ], [ %837, %834 ]
  %853 = phi i32 [ 3, %846 ], [ %844, %834 ]
  %854 = phi i32 [ %847, %846 ], [ %835, %834 ]
  %855 = add nsw i32 %854, 1
  %856 = icmp sgt i32 %852, 0
  br i1 %856, label %834, label %857, !llvm.loop !112

857:                                              ; preds = %851, %824, %820
  %858 = phi ptr [ %822, %820 ], [ %830, %824 ], [ %830, %851 ]
  %859 = icmp eq i8 %670, 0
  br i1 %859, label %862, label %860

860:                                              ; preds = %857
  %861 = getelementptr inbounds i8, ptr %858, i64 -1
  store i8 %670, ptr %861, align 1, !tbaa !30
  br label %862

862:                                              ; preds = %860, %857
  %863 = phi ptr [ %861, %860 ], [ %858, %857 ]
  %864 = icmp eq i8 %472, 0
  %865 = select i1 %672, i1 true, i1 %864
  br i1 %865, label %881, label %866

866:                                              ; preds = %862
  %867 = getelementptr inbounds i8, ptr %500, i64 5
  %868 = load i8, ptr %867, align 1, !tbaa !113
  switch i8 %868, label %869 [
    i8 0, label %881
    i8 6, label %881
    i8 3, label %881
  ]

869:                                              ; preds = %866
  %870 = zext i8 %868 to i64
  %871 = getelementptr inbounds [7 x i8], ptr @aPrefix, i64 0, i64 %870
  %872 = load i8, ptr %871, align 1, !tbaa !30
  br label %873

873:                                              ; preds = %873, %869
  %874 = phi i8 [ %879, %873 ], [ %872, %869 ]
  %875 = phi ptr [ %877, %873 ], [ %863, %869 ]
  %876 = phi ptr [ %878, %873 ], [ %871, %869 ]
  %877 = getelementptr inbounds i8, ptr %875, i64 -1
  store i8 %874, ptr %877, align 1, !tbaa !30
  %878 = getelementptr inbounds i8, ptr %876, i64 1
  %879 = load i8, ptr %878, align 1, !tbaa !30
  %880 = icmp eq i8 %879, 0
  br i1 %880, label %881, label %873, !llvm.loop !114

881:                                              ; preds = %873, %866, %866, %866, %862
  %882 = phi ptr [ %863, %866 ], [ %863, %862 ], [ %863, %866 ], [ %863, %866 ], [ %877, %873 ]
  %883 = ptrtoint ptr %882 to i64
  %884 = sub i64 %797, %883
  %885 = trunc i64 %884 to i32
  br label %2491

886:                                              ; preds = %498, %498, %498
  call void @llvm.lifetime.start.p0(i64 48, ptr nonnull %43) #16
  br i1 %47, label %915, label %887

887:                                              ; preds = %886
  %888 = load i32, ptr %65, align 8, !tbaa !79
  %889 = load i32, ptr %140, align 4, !tbaa !81
  %890 = icmp sgt i32 %888, %889
  br i1 %890, label %891, label %929

891:                                              ; preds = %887
  %892 = load ptr, ptr %141, align 8, !tbaa !82
  %893 = add nsw i32 %889, 1
  store i32 %893, ptr %140, align 4, !tbaa !81
  %894 = sext i32 %889 to i64
  %895 = getelementptr inbounds ptr, ptr %892, i64 %894
  %896 = load ptr, ptr %895, align 8, !tbaa !36
  %897 = getelementptr inbounds i8, ptr %896, i64 20
  %898 = load i16, ptr %897, align 4, !tbaa !83
  %899 = zext i16 %898 to i32
  %900 = and i32 %899, 8
  %901 = icmp eq i32 %900, 0
  br i1 %901, label %904, label %902

902:                                              ; preds = %891
  %903 = load double, ptr %896, align 8, !tbaa !30
  br label %929

904:                                              ; preds = %891
  %905 = and i32 %899, 36
  %906 = icmp eq i32 %905, 0
  br i1 %906, label %910, label %907

907:                                              ; preds = %904
  %908 = load i64, ptr %896, align 8, !tbaa !30
  %909 = sitofp i64 %908 to double
  br label %929

910:                                              ; preds = %904
  %911 = and i32 %899, 18
  %912 = icmp eq i32 %911, 0
  br i1 %912, label %929, label %913

913:                                              ; preds = %910
  %914 = call fastcc double @memRealValue(ptr noundef readonly %896)
  br label %929

915:                                              ; preds = %886
  %916 = load i32, ptr %142, align 4
  %917 = icmp ult i32 %916, 161
  br i1 %917, label %918, label %923

918:                                              ; preds = %915
  %919 = load ptr, ptr %144, align 8
  %920 = zext nneg i32 %916 to i64
  %921 = getelementptr i8, ptr %919, i64 %920
  %922 = add nuw nsw i32 %916, 16
  store i32 %922, ptr %142, align 4
  br label %926

923:                                              ; preds = %915
  %924 = load ptr, ptr %143, align 8
  %925 = getelementptr i8, ptr %924, i64 8
  store ptr %925, ptr %143, align 8
  br label %926

926:                                              ; preds = %923, %918
  %927 = phi ptr [ %921, %918 ], [ %924, %923 ]
  %928 = load double, ptr %927, align 8, !tbaa !115
  br label %929

929:                                              ; preds = %926, %913, %910, %907, %902, %887
  %930 = phi double [ %928, %926 ], [ 0.000000e+00, %887 ], [ %903, %902 ], [ %909, %907 ], [ %914, %913 ], [ 0.000000e+00, %910 ]
  %931 = icmp slt i32 %476, 0
  %932 = call i32 @llvm.smin.i32(i32 %476, i32 100000000)
  %933 = select i1 %931, i32 6, i32 %932
  switch i8 %499, label %938 [
    i8 1, label %934
    i8 3, label %936
  ]

934:                                              ; preds = %929
  %935 = sub nsw i32 0, %933
  br label %940

936:                                              ; preds = %929
  %937 = call i32 @llvm.umax.i32(i32 %933, i32 1)
  br label %940

938:                                              ; preds = %929
  %939 = add nsw i32 %933, 1
  br label %940

940:                                              ; preds = %938, %936, %934
  %941 = phi i32 [ %935, %934 ], [ %937, %936 ], [ %939, %938 ]
  %942 = phi i32 [ %933, %934 ], [ %937, %936 ], [ %933, %938 ]
  %943 = icmp eq i8 %471, 0
  %944 = select i1 %943, i32 16, i32 26
  store i8 0, ptr %145, align 1, !tbaa !117
  store ptr %146, ptr %147, align 8, !tbaa !119
  %945 = fcmp olt double %930, 0.000000e+00
  br i1 %945, label %946, label %948

946:                                              ; preds = %940
  store i8 45, ptr %43, align 8, !tbaa !120
  %947 = fneg double %930
  br label %951

948:                                              ; preds = %940
  %949 = fcmp oeq double %930, 0.000000e+00
  store i8 43, ptr %43, align 8, !tbaa !120
  br i1 %949, label %950, label %951

950:                                              ; preds = %948
  store i32 1, ptr %148, align 4, !tbaa !121
  store i32 1, ptr %149, align 8, !tbaa !122
  store ptr @.str.46, ptr %147, align 8, !tbaa !119
  br label %1400

951:                                              ; preds = %948, %946
  %952 = phi double [ %947, %946 ], [ %930, %948 ]
  %953 = bitcast double %952 to i64
  %954 = and i64 %953, 9218868437227405312
  %955 = icmp eq i64 %954, 9218868437227405312
  br i1 %955, label %956, label %959

956:                                              ; preds = %951
  %957 = icmp eq i64 %953, 9218868437227405312
  %958 = select i1 %957, i8 1, i8 2
  store i8 %958, ptr %145, align 1, !tbaa !117
  store i32 0, ptr %152, align 4, !tbaa !121
  store i32 0, ptr %153, align 8, !tbaa !122
  br label %1400

959:                                              ; preds = %951
  %960 = load i8, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 10), align 2, !tbaa !62
  %961 = icmp eq i8 %960, 0
  br i1 %961, label %1025, label %962

962:                                              ; preds = %959
  %963 = fpext double %952 to x86_fp80
  %964 = fcmp ult double %952, 1.000000e+19
  br i1 %964, label %967, label %965

965:                                              ; preds = %962
  %966 = fcmp ult x86_fp80 %963, 0xK418A9E9F11C4014DDA7E
  br i1 %966, label %969, label %973

967:                                              ; preds = %962
  %968 = fcmp olt x86_fp80 %963, 0xK3EBCDAB99E59958885C5
  br i1 %968, label %999, label %995

969:                                              ; preds = %973, %965
  %970 = phi i32 [ 0, %965 ], [ %976, %973 ]
  %971 = phi x86_fp80 [ %963, %965 ], [ %977, %973 ]
  %972 = fcmp ult x86_fp80 %971, 0xK405FA18F07D736B90BE5
  br i1 %972, label %979, label %983

973:                                              ; preds = %973, %965
  %974 = phi x86_fp80 [ %977, %973 ], [ %963, %965 ]
  %975 = phi i32 [ %976, %973 ], [ 0, %965 ]
  %976 = add nuw nsw i32 %975, 100
  %977 = fmul x86_fp80 %974, 0xK3EB2DFF9772470297EBD
  %978 = fcmp ult x86_fp80 %977, 0xK418A9E9F11C4014DDA7E
  br i1 %978, label %969, label %973, !llvm.loop !123

979:                                              ; preds = %983, %969
  %980 = phi i32 [ %970, %969 ], [ %986, %983 ]
  %981 = phi x86_fp80 [ %971, %969 ], [ %987, %983 ]
  %982 = fcmp ult x86_fp80 %981, 0xK403E8AC7230489E80000
  br i1 %982, label %1021, label %989

983:                                              ; preds = %983, %969
  %984 = phi x86_fp80 [ %987, %983 ], [ %971, %969 ]
  %985 = phi i32 [ %986, %983 ], [ %970, %969 ]
  %986 = add nuw nsw i32 %985, 10
  %987 = fmul x86_fp80 %984, 0xK3FDDDBE6FECEBDEDD5BF
  %988 = fcmp ult x86_fp80 %987, 0xK405FA18F07D736B90BE5
  br i1 %988, label %979, label %983, !llvm.loop !124

989:                                              ; preds = %989, %979
  %990 = phi x86_fp80 [ %993, %989 ], [ %981, %979 ]
  %991 = phi i32 [ %992, %989 ], [ %980, %979 ]
  %992 = add nuw nsw i32 %991, 1
  %993 = fmul x86_fp80 %990, 0xK3FFBCCCCCCCCCCCCCCCD
  %994 = fcmp ult x86_fp80 %993, 0xK403E8AC7230489E80000
  br i1 %994, label %1021, label %989, !llvm.loop !125

995:                                              ; preds = %999, %967
  %996 = phi i32 [ 0, %967 ], [ %1002, %999 ]
  %997 = phi x86_fp80 [ %963, %967 ], [ %1003, %999 ]
  %998 = fcmp olt x86_fp80 %997, 0xK40169896800000000000
  br i1 %998, label %1009, label %1005

999:                                              ; preds = %999, %967
  %1000 = phi x86_fp80 [ %1003, %999 ], [ %963, %967 ]
  %1001 = phi i32 [ %1002, %999 ], [ 0, %967 ]
  %1002 = add nsw i32 %1001, -100
  %1003 = fmul x86_fp80 %1000, 0xK414B924D692CA61BE758
  %1004 = fcmp olt x86_fp80 %1003, 0xK3EBCDAB99E59958885C5
  br i1 %1004, label %999, label %995, !llvm.loop !126

1005:                                             ; preds = %1009, %995
  %1006 = phi i32 [ %996, %995 ], [ %1012, %1009 ]
  %1007 = phi x86_fp80 [ %997, %995 ], [ %1013, %1009 ]
  %1008 = fcmp olt x86_fp80 %1007, 0xK4037B1A2BC2EC5000000
  br i1 %1008, label %1015, label %1021

1009:                                             ; preds = %1009, %995
  %1010 = phi x86_fp80 [ %1013, %1009 ], [ %997, %995 ]
  %1011 = phi i32 [ %1012, %1009 ], [ %996, %995 ]
  %1012 = add nsw i32 %1011, -10
  %1013 = fmul x86_fp80 %1010, 0xK40209502F90000000000
  %1014 = fcmp olt x86_fp80 %1013, 0xK40169896800000000000
  br i1 %1014, label %1009, label %1005, !llvm.loop !127

1015:                                             ; preds = %1015, %1005
  %1016 = phi x86_fp80 [ %1019, %1015 ], [ %1007, %1005 ]
  %1017 = phi i32 [ %1018, %1015 ], [ %1006, %1005 ]
  %1018 = add nsw i32 %1017, -1
  %1019 = fmul x86_fp80 %1016, 0xK4002A000000000000000
  %1020 = fcmp olt x86_fp80 %1019, 0xK4037B1A2BC2EC5000000
  br i1 %1020, label %1015, label %1021, !llvm.loop !128

1021:                                             ; preds = %1015, %1005, %989, %979
  %1022 = phi i32 [ %1006, %1005 ], [ %980, %979 ], [ %1018, %1015 ], [ %992, %989 ]
  %1023 = phi x86_fp80 [ %1007, %1005 ], [ %981, %979 ], [ %1019, %1015 ], [ %993, %989 ]
  %1024 = fptoui x86_fp80 %1023 to i64
  br label %1308

1025:                                             ; preds = %959
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %40)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %41)
  store double %952, ptr %40, align 16, !tbaa !115
  store double 0.000000e+00, ptr %41, align 8, !tbaa !115
  %1026 = fcmp ogt double %952, 0x43DFFFFFFFFFFFFF
  br i1 %1026, label %1029, label %1027

1027:                                             ; preds = %1025
  %1028 = fcmp olt double %952, 0x2EE665BF1D3E6A8C
  br i1 %1028, label %1166, label %1162

1029:                                             ; preds = %1025
  %1030 = fcmp ogt double %952, 0x58A249AD2594C37C
  br i1 %1030, label %1035, label %1031

1031:                                             ; preds = %1035, %1029
  %1032 = phi i32 [ 0, %1029 ], [ %1038, %1035 ]
  %1033 = load double, ptr %40, align 16
  %1034 = fcmp ogt double %1033, 0x45F2A05F1FFFFFFF
  br i1 %1034, label %1080, label %1076

1035:                                             ; preds = %1035, %1029
  %1036 = phi double [ %1070, %1035 ], [ %952, %1029 ]
  %1037 = phi i32 [ %1038, %1035 ], [ 0, %1029 ]
  %1038 = add nuw nsw i32 %1037, 100
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %34)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %35)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %36)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %37)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %38)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %39)
  %1039 = bitcast double %1036 to i64
  %1040 = and i64 %1039, 9223372036787666944
  %1041 = bitcast i64 %1040 to double
  %1042 = load volatile double, ptr %40, align 16, !tbaa !115
  %1043 = fsub double %1042, %1041
  store volatile double %1043, ptr %34, align 8, !tbaa !115
  store volatile double 0x2951C0A600000000, ptr %35, align 8, !tbaa !115
  %1044 = fmul double %1041, 0x2B2BFF2EE4000000
  store volatile double %1044, ptr %36, align 8, !tbaa !115
  %1045 = load volatile double, ptr %35, align 8, !tbaa !115
  %1046 = load volatile double, ptr %34, align 8, !tbaa !115
  %1047 = fmul double %1046, 0x2B2BFF2EE4000000
  %1048 = call double @llvm.fmuladd.f64(double %1041, double %1045, double %1047)
  store volatile double %1048, ptr %37, align 8, !tbaa !115
  %1049 = load volatile double, ptr %36, align 8, !tbaa !115
  %1050 = load volatile double, ptr %37, align 8, !tbaa !115
  %1051 = fadd double %1049, %1050
  store volatile double %1051, ptr %38, align 8, !tbaa !115
  %1052 = load volatile double, ptr %36, align 8, !tbaa !115
  %1053 = load volatile double, ptr %38, align 8, !tbaa !115
  %1054 = fsub double %1052, %1053
  %1055 = load volatile double, ptr %37, align 8, !tbaa !115
  %1056 = fadd double %1054, %1055
  %1057 = load volatile double, ptr %34, align 8, !tbaa !115
  %1058 = load volatile double, ptr %35, align 8, !tbaa !115
  %1059 = call double @llvm.fmuladd.f64(double %1057, double %1058, double %1056)
  store volatile double %1059, ptr %39, align 8, !tbaa !115
  %1060 = load volatile double, ptr %40, align 16, !tbaa !115
  %1061 = load volatile double, ptr %41, align 8, !tbaa !115
  %1062 = fmul double %1061, 1.000000e-100
  %1063 = call double @llvm.fmuladd.f64(double %1060, double 0xA7B42A68781D46C4, double %1062)
  %1064 = load volatile double, ptr %39, align 8, !tbaa !115
  %1065 = fadd double %1064, %1063
  store volatile double %1065, ptr %39, align 8, !tbaa !115
  %1066 = load volatile double, ptr %38, align 8, !tbaa !115
  %1067 = load volatile double, ptr %39, align 8, !tbaa !115
  %1068 = fadd double %1066, %1067
  store volatile double %1068, ptr %40, align 16, !tbaa !115
  %1069 = load volatile double, ptr %38, align 8, !tbaa !115
  %1070 = load volatile double, ptr %40, align 16
  %1071 = fsub double %1069, %1070
  store volatile double %1071, ptr %41, align 8, !tbaa !115
  %1072 = load volatile double, ptr %39, align 8, !tbaa !115
  %1073 = load volatile double, ptr %41, align 8, !tbaa !115
  %1074 = fadd double %1072, %1073
  store volatile double %1074, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %39)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %38)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %37)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %36)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %35)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %34)
  %1075 = fcmp ogt double %1070, 0x58A249AD2594C37C
  br i1 %1075, label %1035, label %1031, !llvm.loop !129

1076:                                             ; preds = %1080, %1031
  %1077 = phi i32 [ %1032, %1031 ], [ %1083, %1080 ]
  %1078 = load double, ptr %40, align 16
  %1079 = fcmp ogt double %1078, 0x43DFFFFFFFFFFFFF
  br i1 %1079, label %1121, label %1293

1080:                                             ; preds = %1080, %1031
  %1081 = phi double [ %1115, %1080 ], [ %1033, %1031 ]
  %1082 = phi i32 [ %1083, %1080 ], [ %1032, %1031 ]
  %1083 = add nuw nsw i32 %1082, 10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %28)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %29)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %31)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %32)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %33)
  %1084 = bitcast double %1081 to i64
  %1085 = and i64 %1084, 9223372036787666944
  %1086 = bitcast i64 %1085 to double
  %1087 = load volatile double, ptr %40, align 16, !tbaa !115
  %1088 = fsub double %1087, %1086
  store volatile double %1088, ptr %28, align 8, !tbaa !115
  store volatile double 0x3C1D7BDBB0000000, ptr %29, align 8, !tbaa !115
  %1089 = fmul double %1086, 0x3DDB7CDFD8000000
  store volatile double %1089, ptr %30, align 8, !tbaa !115
  %1090 = load volatile double, ptr %29, align 8, !tbaa !115
  %1091 = load volatile double, ptr %28, align 8, !tbaa !115
  %1092 = fmul double %1091, 0x3DDB7CDFD8000000
  %1093 = call double @llvm.fmuladd.f64(double %1086, double %1090, double %1092)
  store volatile double %1093, ptr %31, align 8, !tbaa !115
  %1094 = load volatile double, ptr %30, align 8, !tbaa !115
  %1095 = load volatile double, ptr %31, align 8, !tbaa !115
  %1096 = fadd double %1094, %1095
  store volatile double %1096, ptr %32, align 8, !tbaa !115
  %1097 = load volatile double, ptr %30, align 8, !tbaa !115
  %1098 = load volatile double, ptr %32, align 8, !tbaa !115
  %1099 = fsub double %1097, %1098
  %1100 = load volatile double, ptr %31, align 8, !tbaa !115
  %1101 = fadd double %1099, %1100
  %1102 = load volatile double, ptr %28, align 8, !tbaa !115
  %1103 = load volatile double, ptr %29, align 8, !tbaa !115
  %1104 = call double @llvm.fmuladd.f64(double %1102, double %1103, double %1101)
  store volatile double %1104, ptr %33, align 8, !tbaa !115
  %1105 = load volatile double, ptr %40, align 16, !tbaa !115
  %1106 = load volatile double, ptr %41, align 8, !tbaa !115
  %1107 = fmul double %1106, 1.000000e-10
  %1108 = call double @llvm.fmuladd.f64(double %1105, double 0xBA720A5465DF8D2C, double %1107)
  %1109 = load volatile double, ptr %33, align 8, !tbaa !115
  %1110 = fadd double %1109, %1108
  store volatile double %1110, ptr %33, align 8, !tbaa !115
  %1111 = load volatile double, ptr %32, align 8, !tbaa !115
  %1112 = load volatile double, ptr %33, align 8, !tbaa !115
  %1113 = fadd double %1111, %1112
  store volatile double %1113, ptr %40, align 16, !tbaa !115
  %1114 = load volatile double, ptr %32, align 8, !tbaa !115
  %1115 = load volatile double, ptr %40, align 16
  %1116 = fsub double %1114, %1115
  store volatile double %1116, ptr %41, align 8, !tbaa !115
  %1117 = load volatile double, ptr %33, align 8, !tbaa !115
  %1118 = load volatile double, ptr %41, align 8, !tbaa !115
  %1119 = fadd double %1117, %1118
  store volatile double %1119, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %33)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %32)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %31)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %29)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %28)
  %1120 = fcmp ogt double %1115, 0x45F2A05F1FFFFFFF
  br i1 %1120, label %1080, label %1076, !llvm.loop !130

1121:                                             ; preds = %1121, %1076
  %1122 = phi double [ %1156, %1121 ], [ %1078, %1076 ]
  %1123 = phi i32 [ %1124, %1121 ], [ %1077, %1076 ]
  %1124 = add nuw nsw i32 %1123, 1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %22)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %24)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %25)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %26)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %27)
  %1125 = bitcast double %1122 to i64
  %1126 = and i64 %1125, 9223372036787666944
  %1127 = bitcast i64 %1126 to double
  %1128 = load volatile double, ptr %40, align 16, !tbaa !115
  %1129 = fsub double %1128, %1127
  store volatile double %1129, ptr %22, align 8, !tbaa !115
  store volatile double 0x3DF99999A0000000, ptr %23, align 8, !tbaa !115
  %1130 = fmul double %1127, 0x3FB9999998000000
  store volatile double %1130, ptr %24, align 8, !tbaa !115
  %1131 = load volatile double, ptr %23, align 8, !tbaa !115
  %1132 = load volatile double, ptr %22, align 8, !tbaa !115
  %1133 = fmul double %1132, 0x3FB9999998000000
  %1134 = call double @llvm.fmuladd.f64(double %1127, double %1131, double %1133)
  store volatile double %1134, ptr %25, align 8, !tbaa !115
  %1135 = load volatile double, ptr %24, align 8, !tbaa !115
  %1136 = load volatile double, ptr %25, align 8, !tbaa !115
  %1137 = fadd double %1135, %1136
  store volatile double %1137, ptr %26, align 8, !tbaa !115
  %1138 = load volatile double, ptr %24, align 8, !tbaa !115
  %1139 = load volatile double, ptr %26, align 8, !tbaa !115
  %1140 = fsub double %1138, %1139
  %1141 = load volatile double, ptr %25, align 8, !tbaa !115
  %1142 = fadd double %1140, %1141
  %1143 = load volatile double, ptr %22, align 8, !tbaa !115
  %1144 = load volatile double, ptr %23, align 8, !tbaa !115
  %1145 = call double @llvm.fmuladd.f64(double %1143, double %1144, double %1142)
  store volatile double %1145, ptr %27, align 8, !tbaa !115
  %1146 = load volatile double, ptr %40, align 16, !tbaa !115
  %1147 = load volatile double, ptr %41, align 8, !tbaa !115
  %1148 = fmul double %1147, 1.000000e-01
  %1149 = call double @llvm.fmuladd.f64(double %1146, double 0xBC5999999999999A, double %1148)
  %1150 = load volatile double, ptr %27, align 8, !tbaa !115
  %1151 = fadd double %1150, %1149
  store volatile double %1151, ptr %27, align 8, !tbaa !115
  %1152 = load volatile double, ptr %26, align 8, !tbaa !115
  %1153 = load volatile double, ptr %27, align 8, !tbaa !115
  %1154 = fadd double %1152, %1153
  store volatile double %1154, ptr %40, align 16, !tbaa !115
  %1155 = load volatile double, ptr %26, align 8, !tbaa !115
  %1156 = load volatile double, ptr %40, align 16
  %1157 = fsub double %1155, %1156
  store volatile double %1157, ptr %41, align 8, !tbaa !115
  %1158 = load volatile double, ptr %27, align 8, !tbaa !115
  %1159 = load volatile double, ptr %41, align 8, !tbaa !115
  %1160 = fadd double %1158, %1159
  store volatile double %1160, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %27)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %22)
  %1161 = fcmp ogt double %1156, 0x43DFFFFFFFFFFFFF
  br i1 %1161, label %1121, label %1293, !llvm.loop !131

1162:                                             ; preds = %1166, %1027
  %1163 = phi i32 [ 0, %1027 ], [ %1169, %1166 ]
  %1164 = load double, ptr %40, align 16
  %1165 = fcmp olt double %1164, 0x4195FD7FE1796495
  br i1 %1165, label %1211, label %1207

1166:                                             ; preds = %1166, %1027
  %1167 = phi double [ %1201, %1166 ], [ %952, %1027 ]
  %1168 = phi i32 [ %1169, %1166 ], [ 0, %1027 ]
  %1169 = add nsw i32 %1168, -100
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %16)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %17)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %18)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %21)
  %1170 = bitcast double %1167 to i64
  %1171 = and i64 %1170, -67108864
  %1172 = bitcast i64 %1171 to double
  %1173 = load volatile double, ptr %40, align 16, !tbaa !115
  %1174 = fsub double %1173, %1172
  store volatile double %1174, ptr %16, align 8, !tbaa !115
  store volatile double 0x52F94C37D0000000, ptr %17, align 8, !tbaa !115
  %1175 = fmul double %1172, 0x54B249AD24000000
  store volatile double %1175, ptr %18, align 8, !tbaa !115
  %1176 = load volatile double, ptr %17, align 8, !tbaa !115
  %1177 = load volatile double, ptr %16, align 8, !tbaa !115
  %1178 = fmul double %1177, 0x54B249AD24000000
  %1179 = call double @llvm.fmuladd.f64(double %1172, double %1176, double %1178)
  store volatile double %1179, ptr %19, align 8, !tbaa !115
  %1180 = load volatile double, ptr %18, align 8, !tbaa !115
  %1181 = load volatile double, ptr %19, align 8, !tbaa !115
  %1182 = fadd double %1180, %1181
  store volatile double %1182, ptr %20, align 8, !tbaa !115
  %1183 = load volatile double, ptr %18, align 8, !tbaa !115
  %1184 = load volatile double, ptr %20, align 8, !tbaa !115
  %1185 = fsub double %1183, %1184
  %1186 = load volatile double, ptr %19, align 8, !tbaa !115
  %1187 = fadd double %1185, %1186
  %1188 = load volatile double, ptr %16, align 8, !tbaa !115
  %1189 = load volatile double, ptr %17, align 8, !tbaa !115
  %1190 = call double @llvm.fmuladd.f64(double %1188, double %1189, double %1187)
  store volatile double %1190, ptr %21, align 8, !tbaa !115
  %1191 = load volatile double, ptr %40, align 16, !tbaa !115
  %1192 = load volatile double, ptr %41, align 8, !tbaa !115
  %1193 = fmul double %1192, 1.000000e+100
  %1194 = call double @llvm.fmuladd.f64(double %1191, double 0xD134F4D87B3B31F4, double %1193)
  %1195 = load volatile double, ptr %21, align 8, !tbaa !115
  %1196 = fadd double %1195, %1194
  store volatile double %1196, ptr %21, align 8, !tbaa !115
  %1197 = load volatile double, ptr %20, align 8, !tbaa !115
  %1198 = load volatile double, ptr %21, align 8, !tbaa !115
  %1199 = fadd double %1197, %1198
  store volatile double %1199, ptr %40, align 16, !tbaa !115
  %1200 = load volatile double, ptr %20, align 8, !tbaa !115
  %1201 = load volatile double, ptr %40, align 16
  %1202 = fsub double %1200, %1201
  store volatile double %1202, ptr %41, align 8, !tbaa !115
  %1203 = load volatile double, ptr %21, align 8, !tbaa !115
  %1204 = load volatile double, ptr %41, align 8, !tbaa !115
  %1205 = fadd double %1203, %1204
  store volatile double %1205, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %21)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %18)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %17)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %16)
  %1206 = fcmp olt double %1201, 0x2EE665BF1D3E6A8C
  br i1 %1206, label %1166, label %1162, !llvm.loop !132

1207:                                             ; preds = %1211, %1162
  %1208 = phi i32 [ %1163, %1162 ], [ %1214, %1211 ]
  %1209 = load double, ptr %40, align 16
  %1210 = fcmp olt double %1209, 0x43A9999999999999
  br i1 %1210, label %1252, label %1293

1211:                                             ; preds = %1211, %1162
  %1212 = phi double [ %1246, %1211 ], [ %1164, %1162 ]
  %1213 = phi i32 [ %1214, %1211 ], [ %1163, %1162 ]
  %1214 = add nsw i32 %1213, -10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %12)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %14)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %15)
  %1215 = bitcast double %1212 to i64
  %1216 = and i64 %1215, -67108864
  %1217 = bitcast i64 %1216 to double
  %1218 = load volatile double, ptr %40, align 16, !tbaa !115
  %1219 = fsub double %1218, %1217
  store volatile double %1219, ptr %10, align 8, !tbaa !115
  store volatile double 0.000000e+00, ptr %11, align 8, !tbaa !115
  %1220 = fmul double %1217, 1.000000e+10
  store volatile double %1220, ptr %12, align 8, !tbaa !115
  %1221 = load volatile double, ptr %11, align 8, !tbaa !115
  %1222 = load volatile double, ptr %10, align 8, !tbaa !115
  %1223 = fmul double %1222, 1.000000e+10
  %1224 = call double @llvm.fmuladd.f64(double %1217, double %1221, double %1223)
  store volatile double %1224, ptr %13, align 8, !tbaa !115
  %1225 = load volatile double, ptr %12, align 8, !tbaa !115
  %1226 = load volatile double, ptr %13, align 8, !tbaa !115
  %1227 = fadd double %1225, %1226
  store volatile double %1227, ptr %14, align 8, !tbaa !115
  %1228 = load volatile double, ptr %12, align 8, !tbaa !115
  %1229 = load volatile double, ptr %14, align 8, !tbaa !115
  %1230 = fsub double %1228, %1229
  %1231 = load volatile double, ptr %13, align 8, !tbaa !115
  %1232 = fadd double %1230, %1231
  %1233 = load volatile double, ptr %10, align 8, !tbaa !115
  %1234 = load volatile double, ptr %11, align 8, !tbaa !115
  %1235 = call double @llvm.fmuladd.f64(double %1233, double %1234, double %1232)
  store volatile double %1235, ptr %15, align 8, !tbaa !115
  %1236 = load volatile double, ptr %40, align 16, !tbaa !115
  %1237 = load volatile double, ptr %41, align 8, !tbaa !115
  %1238 = fmul double %1237, 1.000000e+10
  %1239 = call double @llvm.fmuladd.f64(double %1236, double 0.000000e+00, double %1238)
  %1240 = load volatile double, ptr %15, align 8, !tbaa !115
  %1241 = fadd double %1240, %1239
  store volatile double %1241, ptr %15, align 8, !tbaa !115
  %1242 = load volatile double, ptr %14, align 8, !tbaa !115
  %1243 = load volatile double, ptr %15, align 8, !tbaa !115
  %1244 = fadd double %1242, %1243
  store volatile double %1244, ptr %40, align 16, !tbaa !115
  %1245 = load volatile double, ptr %14, align 8, !tbaa !115
  %1246 = load volatile double, ptr %40, align 16
  %1247 = fsub double %1245, %1246
  store volatile double %1247, ptr %41, align 8, !tbaa !115
  %1248 = load volatile double, ptr %15, align 8, !tbaa !115
  %1249 = load volatile double, ptr %41, align 8, !tbaa !115
  %1250 = fadd double %1248, %1249
  store volatile double %1250, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %15)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %14)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %12)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)
  %1251 = fcmp olt double %1246, 0x4195FD7FE1796495
  br i1 %1251, label %1211, label %1207, !llvm.loop !133

1252:                                             ; preds = %1252, %1207
  %1253 = phi double [ %1287, %1252 ], [ %1209, %1207 ]
  %1254 = phi i32 [ %1255, %1252 ], [ %1208, %1207 ]
  %1255 = add nsw i32 %1254, -1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  %1256 = bitcast double %1253 to i64
  %1257 = and i64 %1256, -67108864
  %1258 = bitcast i64 %1257 to double
  %1259 = load volatile double, ptr %40, align 16, !tbaa !115
  %1260 = fsub double %1259, %1258
  store volatile double %1260, ptr %4, align 8, !tbaa !115
  store volatile double 0.000000e+00, ptr %5, align 8, !tbaa !115
  %1261 = fmul double %1258, 1.000000e+01
  store volatile double %1261, ptr %6, align 8, !tbaa !115
  %1262 = load volatile double, ptr %5, align 8, !tbaa !115
  %1263 = load volatile double, ptr %4, align 8, !tbaa !115
  %1264 = fmul double %1263, 1.000000e+01
  %1265 = call double @llvm.fmuladd.f64(double %1258, double %1262, double %1264)
  store volatile double %1265, ptr %7, align 8, !tbaa !115
  %1266 = load volatile double, ptr %6, align 8, !tbaa !115
  %1267 = load volatile double, ptr %7, align 8, !tbaa !115
  %1268 = fadd double %1266, %1267
  store volatile double %1268, ptr %8, align 8, !tbaa !115
  %1269 = load volatile double, ptr %6, align 8, !tbaa !115
  %1270 = load volatile double, ptr %8, align 8, !tbaa !115
  %1271 = fsub double %1269, %1270
  %1272 = load volatile double, ptr %7, align 8, !tbaa !115
  %1273 = fadd double %1271, %1272
  %1274 = load volatile double, ptr %4, align 8, !tbaa !115
  %1275 = load volatile double, ptr %5, align 8, !tbaa !115
  %1276 = call double @llvm.fmuladd.f64(double %1274, double %1275, double %1273)
  store volatile double %1276, ptr %9, align 8, !tbaa !115
  %1277 = load volatile double, ptr %40, align 16, !tbaa !115
  %1278 = load volatile double, ptr %41, align 8, !tbaa !115
  %1279 = fmul double %1278, 1.000000e+01
  %1280 = call double @llvm.fmuladd.f64(double %1277, double 0.000000e+00, double %1279)
  %1281 = load volatile double, ptr %9, align 8, !tbaa !115
  %1282 = fadd double %1281, %1280
  store volatile double %1282, ptr %9, align 8, !tbaa !115
  %1283 = load volatile double, ptr %8, align 8, !tbaa !115
  %1284 = load volatile double, ptr %9, align 8, !tbaa !115
  %1285 = fadd double %1283, %1284
  store volatile double %1285, ptr %40, align 16, !tbaa !115
  %1286 = load volatile double, ptr %8, align 8, !tbaa !115
  %1287 = load volatile double, ptr %40, align 16
  %1288 = fsub double %1286, %1287
  store volatile double %1288, ptr %41, align 8, !tbaa !115
  %1289 = load volatile double, ptr %9, align 8, !tbaa !115
  %1290 = load volatile double, ptr %41, align 8, !tbaa !115
  %1291 = fadd double %1289, %1290
  store volatile double %1291, ptr %41, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  %1292 = fcmp olt double %1287, 0x43A9999999999999
  br i1 %1292, label %1252, label %1293, !llvm.loop !134

1293:                                             ; preds = %1252, %1207, %1121, %1076
  %1294 = phi i32 [ %1077, %1076 ], [ %1208, %1207 ], [ %1124, %1121 ], [ %1255, %1252 ]
  %1295 = load double, ptr %41, align 8, !tbaa !115
  %1296 = fcmp olt double %1295, 0.000000e+00
  %1297 = load double, ptr %40, align 16, !tbaa !115
  %1298 = fptoui double %1297 to i64
  br i1 %1296, label %1299, label %1303

1299:                                             ; preds = %1293
  %1300 = fneg double %1295
  %1301 = fptoui double %1300 to i64
  %1302 = sub i64 %1298, %1301
  br label %1306

1303:                                             ; preds = %1293
  %1304 = fptoui double %1295 to i64
  %1305 = add i64 %1298, %1304
  br label %1306

1306:                                             ; preds = %1303, %1299
  %1307 = phi i64 [ %1302, %1299 ], [ %1305, %1303 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %40)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %41)
  br label %1308

1308:                                             ; preds = %1306, %1021
  %1309 = phi i64 [ %1024, %1021 ], [ %1307, %1306 ]
  %1310 = phi i32 [ %1022, %1021 ], [ %1294, %1306 ]
  %1311 = icmp eq i64 %1309, 0
  br i1 %1311, label %1324, label %1312

1312:                                             ; preds = %1312, %1308
  %1313 = phi i64 [ %1318, %1312 ], [ 23, %1308 ]
  %1314 = phi i64 [ %1320, %1312 ], [ %1309, %1308 ]
  %1315 = urem i64 %1314, 10
  %1316 = trunc nuw nsw i64 %1315 to i8
  %1317 = or disjoint i8 %1316, 48
  %1318 = add nsw i64 %1313, -1
  %1319 = getelementptr inbounds [24 x i8], ptr %146, i64 0, i64 %1313
  store i8 %1317, ptr %1319, align 1, !tbaa !30
  %1320 = udiv i64 %1314, 10
  %1321 = icmp ult i64 %1314, 10
  br i1 %1321, label %1322, label %1312, !llvm.loop !135

1322:                                             ; preds = %1312
  %1323 = trunc nsw i64 %1318 to i32
  br label %1324

1324:                                             ; preds = %1322, %1308
  %1325 = phi i32 [ 23, %1308 ], [ %1323, %1322 ]
  %1326 = sext i32 %1325 to i64
  %1327 = sub i32 23, %1325
  store i32 %1327, ptr %150, align 4, !tbaa !121
  %1328 = add nsw i32 %1327, %1310
  store i32 %1328, ptr %151, align 8, !tbaa !122
  %1329 = icmp slt i32 %941, 1
  br i1 %1329, label %1330, label %1346

1330:                                             ; preds = %1324
  %1331 = sub nsw i32 %1328, %941
  %1332 = icmp eq i32 %1331, 0
  br i1 %1332, label %1333, label %1346

1333:                                             ; preds = %1330
  %1334 = add nsw i32 %1325, 1
  %1335 = sext i32 %1334 to i64
  %1336 = getelementptr inbounds [24 x i8], ptr %146, i64 0, i64 %1335
  %1337 = load i8, ptr %1336, align 1, !tbaa !30
  %1338 = icmp sgt i8 %1337, 52
  br i1 %1338, label %1339, label %1346

1339:                                             ; preds = %1333
  %1340 = add nsw i32 %1325, -1
  %1341 = getelementptr inbounds [24 x i8], ptr %146, i64 0, i64 %1326
  store i8 48, ptr %1341, align 1, !tbaa !30
  %1342 = load i32, ptr %150, align 4, !tbaa !121
  %1343 = add nsw i32 %1342, 1
  store i32 %1343, ptr %150, align 4, !tbaa !121
  %1344 = load i32, ptr %151, align 8, !tbaa !122
  %1345 = add nsw i32 %1344, 1
  store i32 %1345, ptr %151, align 8, !tbaa !122
  br label %1346

1346:                                             ; preds = %1339, %1333, %1330, %1324
  %1347 = phi i32 [ %1340, %1339 ], [ %1325, %1333 ], [ %1325, %1330 ], [ %1325, %1324 ]
  %1348 = phi i32 [ 1, %1339 ], [ 0, %1333 ], [ %1331, %1330 ], [ %941, %1324 ]
  %1349 = icmp sgt i32 %1348, 0
  br i1 %1349, label %1350, label %1383

1350:                                             ; preds = %1346
  %1351 = load i32, ptr %150, align 4, !tbaa !121
  %1352 = icmp slt i32 %1348, %1351
  %1353 = icmp sgt i32 %1351, %944
  %1354 = or i1 %1352, %1353
  br i1 %1354, label %1355, label %1383

1355:                                             ; preds = %1350
  %1356 = add nsw i32 %1347, 1
  %1357 = sext i32 %1356 to i64
  %1358 = getelementptr inbounds [24 x i8], ptr %146, i64 0, i64 %1357
  %1359 = call i32 @llvm.smin.i32(i32 %1348, i32 %944)
  store i32 %1359, ptr %150, align 4, !tbaa !121
  %1360 = zext nneg i32 %1359 to i64
  %1361 = getelementptr inbounds i8, ptr %1358, i64 %1360
  %1362 = load i8, ptr %1361, align 1, !tbaa !30
  %1363 = icmp sgt i8 %1362, 52
  br i1 %1363, label %1364, label %1383

1364:                                             ; preds = %1372, %1355
  %1365 = phi i32 [ %1366, %1372 ], [ %1359, %1355 ]
  %1366 = add nsw i32 %1365, -1
  %1367 = zext nneg i32 %1366 to i64
  %1368 = getelementptr inbounds i8, ptr %1358, i64 %1367
  %1369 = load i8, ptr %1368, align 1, !tbaa !30
  %1370 = add i8 %1369, 1
  store i8 %1370, ptr %1368, align 1, !tbaa !30
  %1371 = icmp slt i8 %1370, 58
  br i1 %1371, label %1383, label %1372

1372:                                             ; preds = %1364
  store i8 48, ptr %1368, align 1, !tbaa !30
  %1373 = icmp eq i32 %1366, 0
  br i1 %1373, label %1374, label %1364, !llvm.loop !136

1374:                                             ; preds = %1372
  %1375 = load ptr, ptr %147, align 8, !tbaa !119
  %1376 = add nsw i32 %1347, -1
  %1377 = sext i32 %1347 to i64
  %1378 = getelementptr inbounds i8, ptr %1375, i64 %1377
  store i8 49, ptr %1378, align 1, !tbaa !30
  %1379 = load i32, ptr %150, align 4, !tbaa !121
  %1380 = add nsw i32 %1379, 1
  store i32 %1380, ptr %150, align 4, !tbaa !121
  %1381 = load i32, ptr %151, align 8, !tbaa !122
  %1382 = add nsw i32 %1381, 1
  store i32 %1382, ptr %151, align 8, !tbaa !122
  br label %1383

1383:                                             ; preds = %1374, %1364, %1355, %1350, %1346
  %1384 = phi i32 [ %1347, %1346 ], [ %1347, %1350 ], [ %1347, %1355 ], [ %1376, %1374 ], [ %1347, %1364 ]
  %1385 = add nsw i32 %1384, 1
  %1386 = sext i32 %1385 to i64
  %1387 = getelementptr inbounds [24 x i8], ptr %146, i64 0, i64 %1386
  store ptr %1387, ptr %147, align 8, !tbaa !119
  %1388 = getelementptr i8, ptr %1387, i64 -1
  %1389 = load i32, ptr %150, align 4, !tbaa !121
  %1390 = icmp sgt i32 %1389, 0
  br i1 %1390, label %1391, label %1400

1391:                                             ; preds = %1397, %1383
  %1392 = phi i32 [ %1398, %1397 ], [ %1389, %1383 ]
  %1393 = zext nneg i32 %1392 to i64
  %1394 = getelementptr i8, ptr %1388, i64 %1393
  %1395 = load i8, ptr %1394, align 1, !tbaa !30
  %1396 = icmp eq i8 %1395, 48
  br i1 %1396, label %1397, label %1400

1397:                                             ; preds = %1391
  %1398 = add nsw i32 %1392, -1
  store i32 %1398, ptr %150, align 4, !tbaa !121
  %1399 = icmp sgt i32 %1392, 1
  br i1 %1399, label %1391, label %1400, !llvm.loop !137

1400:                                             ; preds = %1397, %1391, %1383, %956, %950
  %1401 = load i8, ptr %145, align 1, !tbaa !117
  switch i8 %1401, label %1406 [
    i8 0, label %1421
    i8 2, label %1402
  ]

1402:                                             ; preds = %1400
  %1403 = icmp eq i8 %470, 0
  %1404 = select i1 %1403, ptr @.str.2, ptr @.str.1
  %1405 = select i1 %1403, i32 3, i32 4
  br label %1689

1406:                                             ; preds = %1400
  %1407 = icmp eq i8 %470, 0
  br i1 %1407, label %1410, label %1408

1408:                                             ; preds = %1406
  %1409 = load ptr, ptr %147, align 8, !tbaa !119
  store i8 57, ptr %1409, align 1, !tbaa !30
  store i32 1000, ptr %154, align 8, !tbaa !122
  store i32 1, ptr %155, align 4, !tbaa !121
  br label %1421

1410:                                             ; preds = %1406
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(5) %42, ptr noundef nonnull align 1 dereferenceable(5) @.str.3, i64 5, i1 false)
  %1411 = load i8, ptr %43, align 8, !tbaa !120
  %1412 = icmp eq i8 %1411, 45
  br i1 %1412, label %1416, label %1413

1413:                                             ; preds = %1410
  %1414 = icmp eq i8 %473, 0
  br i1 %1414, label %1416, label %1415

1415:                                             ; preds = %1413
  store i8 %473, ptr %42, align 16, !tbaa !30
  br label %1416

1416:                                             ; preds = %1415, %1413, %1410
  %1417 = phi ptr [ %42, %1410 ], [ %42, %1415 ], [ %163, %1413 ]
  %1418 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %1417) #16
  %1419 = trunc i64 %1418 to i32
  %1420 = and i32 %1419, 1073741823
  br label %1689

1421:                                             ; preds = %1408, %1400
  %1422 = load i8, ptr %43, align 8, !tbaa !120
  %1423 = icmp eq i8 %1422, 45
  %1424 = select i1 %1423, i8 45, i8 %473
  %1425 = load i32, ptr %156, align 8
  %1426 = icmp eq i8 %499, 3
  br i1 %1426, label %1427, label %1437

1427:                                             ; preds = %1421
  %1428 = icmp eq i8 %472, 0
  %1429 = zext i1 %1428 to i8
  %1430 = icmp slt i32 %1425, -3
  %1431 = icmp sgt i32 %1425, %942
  %1432 = select i1 %1430, i1 true, i1 %1431
  %1433 = select i1 %1432, i8 2, i8 1
  %1434 = sub i32 0, %1425
  %1435 = select i1 %1432, i32 -1, i32 %1434
  %1436 = add i32 %1435, %942
  br label %1437

1437:                                             ; preds = %1427, %1421
  %1438 = phi i8 [ %499, %1421 ], [ %1433, %1427 ]
  %1439 = phi i8 [ %471, %1421 ], [ %1429, %1427 ]
  %1440 = phi i32 [ %942, %1421 ], [ %1436, %1427 ]
  %1441 = freeze i32 %1440
  %1442 = icmp eq i8 %1438, 2
  %1443 = add nsw i32 %1425, -1
  %1444 = select i1 %1442, i32 0, i32 %1443
  %1445 = icmp sgt i32 %1444, 0
  %1446 = call i32 @llvm.smax.i32(i32 %1444, i32 0)
  %1447 = zext nneg i32 %1446 to i64
  %1448 = sext i32 %1441 to i64
  %1449 = zext nneg i32 %475 to i64
  %1450 = add nuw nsw i64 %1449, 15
  %1451 = add nsw i64 %1450, %1448
  %1452 = add nsw i64 %1451, %1447
  %1453 = icmp ne i8 %468, 0
  %1454 = select i1 %1453, i1 %1445, i1 false
  br i1 %1454, label %1455, label %1460

1455:                                             ; preds = %1437
  %1456 = add nuw nsw i32 %1444, 2
  %1457 = udiv i32 %1456, 3
  %1458 = zext nneg i32 %1457 to i64
  %1459 = add nsw i64 %1452, %1458
  br label %1460

1460:                                             ; preds = %1455, %1437
  %1461 = phi i64 [ %1459, %1455 ], [ %1452, %1437 ]
  %1462 = icmp sgt i64 %1461, 70
  br i1 %1462, label %1463, label %1507

1463:                                             ; preds = %1460
  %1464 = load i8, ptr %157, align 4, !tbaa !96
  %1465 = icmp eq i8 %1464, 0
  br i1 %1465, label %1466, label %1503

1466:                                             ; preds = %1463
  %1467 = load i32, ptr %158, align 8, !tbaa !76
  %1468 = zext i32 %1467 to i64
  %1469 = icmp sgt i64 %1461, %1468
  br i1 %1469, label %1470, label %1489

1470:                                             ; preds = %1466
  %1471 = load i32, ptr %159, align 4, !tbaa !97
  %1472 = zext i32 %1471 to i64
  %1473 = icmp sgt i64 %1461, %1472
  br i1 %1473, label %1474, label %1489

1474:                                             ; preds = %1470
  store i8 18, ptr %157, align 4, !tbaa !96
  %1475 = icmp eq i32 %1471, 0
  br i1 %1475, label %1477, label %1476

1476:                                             ; preds = %1474
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %1477

1477:                                             ; preds = %1476, %1474
  %1478 = load ptr, ptr %0, align 8, !tbaa !98
  %1479 = icmp eq ptr %1478, null
  br i1 %1479, label %1503, label %1480

1480:                                             ; preds = %1477
  %1481 = getelementptr inbounds i8, ptr %1478, i64 344
  %1482 = load ptr, ptr %1481, align 8, !tbaa !99
  %1483 = icmp eq ptr %1482, null
  br i1 %1483, label %1503, label %1484

1484:                                             ; preds = %1480
  %1485 = getelementptr inbounds i8, ptr %1482, i64 24
  store i32 18, ptr %1485, align 8, !tbaa !105
  %1486 = getelementptr inbounds i8, ptr %1482, i64 48
  %1487 = load i32, ptr %1486, align 8, !tbaa !108
  %1488 = add nsw i32 %1487, 1
  store i32 %1488, ptr %1486, align 8, !tbaa !108
  br label %1503

1489:                                             ; preds = %1470, %1466
  %1490 = load ptr, ptr %0, align 8, !tbaa !98
  %1491 = icmp eq ptr %1490, null
  br i1 %1491, label %1494, label %1492

1492:                                             ; preds = %1489
  %1493 = call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %1490, i64 noundef %1461)
  br label %1496

1494:                                             ; preds = %1489
  %1495 = call fastcc ptr @sqlite3Malloc(i64 noundef %1461)
  br label %1496

1496:                                             ; preds = %1494, %1492
  %1497 = phi ptr [ %1493, %1492 ], [ %1495, %1494 ]
  %1498 = icmp eq ptr %1497, null
  br i1 %1498, label %1499, label %1503

1499:                                             ; preds = %1496
  store i8 7, ptr %157, align 4, !tbaa !96
  %1500 = load i32, ptr %160, align 4, !tbaa !97
  %1501 = icmp eq i32 %1500, 0
  br i1 %1501, label %1503, label %1502

1502:                                             ; preds = %1499
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %1503

1503:                                             ; preds = %1502, %1499, %1496, %1484, %1480, %1477, %1463
  %1504 = phi ptr [ null, %1463 ], [ %1497, %1496 ], [ null, %1477 ], [ null, %1480 ], [ null, %1484 ], [ %1497, %1499 ], [ %1497, %1502 ]
  %1505 = icmp eq ptr %1504, null
  br i1 %1505, label %1507, label %1506

1506:                                             ; preds = %1503
  br label %1507

1507:                                             ; preds = %1506, %1503, %1460
  %1508 = phi ptr [ null, %1503 ], [ null, %1460 ], [ %1504, %1506 ]
  %1509 = phi i1 [ false, %1503 ], [ true, %1460 ], [ true, %1506 ]
  %1510 = phi ptr [ null, %1503 ], [ %42, %1460 ], [ %1504, %1506 ]
  br i1 %1509, label %1511, label %1689

1511:                                             ; preds = %1507
  %1512 = icmp sgt i32 %1441, 0
  %1513 = zext i1 %1512 to i8
  %1514 = or i8 %471, %1513
  %1515 = or i8 %1514, %472
  %1516 = icmp eq i8 %1424, 0
  br i1 %1516, label %1519, label %1517

1517:                                             ; preds = %1511
  %1518 = getelementptr inbounds i8, ptr %1510, i64 1
  store i8 %1424, ptr %1510, align 1, !tbaa !30
  br label %1519

1519:                                             ; preds = %1517, %1511
  %1520 = phi ptr [ %1518, %1517 ], [ %1510, %1511 ]
  %1521 = icmp slt i32 %1444, 0
  br i1 %1521, label %1522, label %1524

1522:                                             ; preds = %1519
  %1523 = getelementptr inbounds i8, ptr %1520, i64 1
  store i8 48, ptr %1520, align 1, !tbaa !30
  br label %1551

1524:                                             ; preds = %1547, %1519
  %1525 = phi ptr [ %1548, %1547 ], [ %1520, %1519 ]
  %1526 = phi i32 [ %1537, %1547 ], [ 0, %1519 ]
  %1527 = phi i32 [ %1549, %1547 ], [ %1444, %1519 ]
  %1528 = load i32, ptr %161, align 4, !tbaa !121
  %1529 = icmp slt i32 %1526, %1528
  br i1 %1529, label %1530, label %1536

1530:                                             ; preds = %1524
  %1531 = load ptr, ptr %147, align 8, !tbaa !119
  %1532 = add nsw i32 %1526, 1
  %1533 = sext i32 %1526 to i64
  %1534 = getelementptr inbounds i8, ptr %1531, i64 %1533
  %1535 = load i8, ptr %1534, align 1, !tbaa !30
  br label %1536

1536:                                             ; preds = %1530, %1524
  %1537 = phi i32 [ %1532, %1530 ], [ %1526, %1524 ]
  %1538 = phi i8 [ %1535, %1530 ], [ 48, %1524 ]
  %1539 = getelementptr inbounds i8, ptr %1525, i64 1
  store i8 %1538, ptr %1525, align 1, !tbaa !30
  br i1 %1453, label %1540, label %1547

1540:                                             ; preds = %1536
  %1541 = urem i32 %1527, 3
  %1542 = icmp eq i32 %1541, 0
  %1543 = icmp sgt i32 %1527, 1
  %1544 = and i1 %1543, %1542
  br i1 %1544, label %1545, label %1547

1545:                                             ; preds = %1540
  %1546 = getelementptr inbounds i8, ptr %1525, i64 2
  store i8 44, ptr %1539, align 1, !tbaa !30
  br label %1547

1547:                                             ; preds = %1545, %1540, %1536
  %1548 = phi ptr [ %1546, %1545 ], [ %1539, %1540 ], [ %1539, %1536 ]
  %1549 = add nsw i32 %1527, -1
  %1550 = icmp sgt i32 %1527, 0
  br i1 %1550, label %1524, label %1551, !llvm.loop !138

1551:                                             ; preds = %1547, %1522
  %1552 = phi i32 [ %1444, %1522 ], [ -1, %1547 ]
  %1553 = phi i32 [ 0, %1522 ], [ %1537, %1547 ]
  %1554 = phi ptr [ %1523, %1522 ], [ %1548, %1547 ]
  %1555 = icmp eq i8 %1515, 0
  br i1 %1555, label %1558, label %1556

1556:                                             ; preds = %1551
  %1557 = getelementptr inbounds i8, ptr %1554, i64 1
  store i8 46, ptr %1554, align 1, !tbaa !30
  br label %1558

1558:                                             ; preds = %1556, %1551
  %1559 = phi ptr [ %1557, %1556 ], [ %1554, %1551 ]
  %1560 = icmp slt i32 %1552, -1
  %1561 = icmp sgt i32 %1441, 0
  %1562 = and i1 %1560, %1561
  br i1 %1562, label %1563, label %1578

1563:                                             ; preds = %1558
  %1564 = add nsw i32 %1441, -1
  %1565 = sub nsw i32 -2, %1552
  %1566 = call i32 @llvm.umin.i32(i32 %1564, i32 %1565)
  %1567 = zext i32 %1566 to i64
  %1568 = add nuw nsw i64 %1567, 1
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %1559, i8 48, i64 %1568, i1 false), !tbaa !30
  %1569 = add nsw i32 %1441, -1
  %1570 = sub nsw i32 -2, %1552
  %1571 = call i32 @llvm.umin.i32(i32 %1569, i32 %1570)
  %1572 = getelementptr i8, ptr %1559, i64 1
  %1573 = call i32 @llvm.umin.i32(i32 %1569, i32 %1570)
  %1574 = zext i32 %1573 to i64
  %1575 = getelementptr i8, ptr %1572, i64 %1574
  %1576 = xor i32 %1571, -1
  %1577 = add i32 %1441, %1576
  br label %1578

1578:                                             ; preds = %1563, %1558
  %1579 = phi i32 [ %1441, %1558 ], [ %1577, %1563 ]
  %1580 = phi ptr [ %1559, %1558 ], [ %1575, %1563 ]
  %1581 = icmp sgt i32 %1579, 0
  br i1 %1581, label %1582, label %1600

1582:                                             ; preds = %1595, %1578
  %1583 = phi i32 [ %1586, %1595 ], [ %1579, %1578 ]
  %1584 = phi ptr [ %1598, %1595 ], [ %1580, %1578 ]
  %1585 = phi i32 [ %1596, %1595 ], [ %1553, %1578 ]
  %1586 = add nsw i32 %1583, -1
  %1587 = load i32, ptr %162, align 4, !tbaa !121
  %1588 = icmp slt i32 %1585, %1587
  br i1 %1588, label %1589, label %1595

1589:                                             ; preds = %1582
  %1590 = load ptr, ptr %147, align 8, !tbaa !119
  %1591 = add nsw i32 %1585, 1
  %1592 = sext i32 %1585 to i64
  %1593 = getelementptr inbounds i8, ptr %1590, i64 %1592
  %1594 = load i8, ptr %1593, align 1, !tbaa !30
  br label %1595

1595:                                             ; preds = %1589, %1582
  %1596 = phi i32 [ %1591, %1589 ], [ %1585, %1582 ]
  %1597 = phi i8 [ %1594, %1589 ], [ 48, %1582 ]
  %1598 = getelementptr inbounds i8, ptr %1584, i64 1
  store i8 %1597, ptr %1584, align 1, !tbaa !30
  %1599 = icmp sgt i32 %1583, 1
  br i1 %1599, label %1582, label %1600, !llvm.loop !139

1600:                                             ; preds = %1595, %1578
  %1601 = phi ptr [ %1580, %1578 ], [ %1598, %1595 ]
  %1602 = icmp ne i8 %1439, 0
  %1603 = icmp ne i8 %1515, 0
  %1604 = select i1 %1602, i1 %1603, i1 false
  br i1 %1604, label %1605, label %1614

1605:                                             ; preds = %1609, %1600
  %1606 = phi ptr [ %1607, %1609 ], [ %1601, %1600 ]
  %1607 = getelementptr inbounds i8, ptr %1606, i64 -1
  %1608 = load i8, ptr %1607, align 1, !tbaa !30
  switch i8 %1608, label %1614 [
    i8 48, label %1609
    i8 46, label %1610
  ]

1609:                                             ; preds = %1605
  store i8 0, ptr %1607, align 1, !tbaa !30
  br label %1605, !llvm.loop !140

1610:                                             ; preds = %1605
  br i1 %943, label %1613, label %1611

1611:                                             ; preds = %1610
  %1612 = getelementptr inbounds i8, ptr %1606, i64 1
  store i8 48, ptr %1606, align 1, !tbaa !30
  br label %1614

1613:                                             ; preds = %1610
  store i8 0, ptr %1607, align 1, !tbaa !30
  br label %1614

1614:                                             ; preds = %1613, %1611, %1605, %1600
  %1615 = phi ptr [ %1612, %1611 ], [ %1607, %1613 ], [ %1601, %1600 ], [ %1606, %1605 ]
  br i1 %1442, label %1616, label %1650

1616:                                             ; preds = %1614
  %1617 = load i32, ptr %156, align 8, !tbaa !122
  %1618 = getelementptr inbounds i8, ptr %500, i64 4
  %1619 = load i8, ptr %1618, align 1, !tbaa !109
  %1620 = zext i8 %1619 to i64
  %1621 = getelementptr inbounds [33 x i8], ptr @aDigits, i64 0, i64 %1620
  %1622 = load i8, ptr %1621, align 1, !tbaa !30
  %1623 = getelementptr inbounds i8, ptr %1615, i64 1
  store i8 %1622, ptr %1615, align 1, !tbaa !30
  %1624 = icmp slt i32 %1617, 1
  br i1 %1624, label %1625, label %1627

1625:                                             ; preds = %1616
  store i8 45, ptr %1623, align 1, !tbaa !30
  %1626 = sub nsw i32 1, %1617
  br label %1629

1627:                                             ; preds = %1616
  %1628 = add nsw i32 %1617, -1
  store i8 43, ptr %1623, align 1, !tbaa !30
  br label %1629

1629:                                             ; preds = %1627, %1625
  %1630 = phi i32 [ %1626, %1625 ], [ %1628, %1627 ]
  %1631 = getelementptr inbounds i8, ptr %1615, i64 2
  %1632 = icmp sgt i32 %1630, 99
  br i1 %1632, label %1633, label %1639

1633:                                             ; preds = %1629
  %1634 = udiv i32 %1630, 100
  %1635 = trunc i32 %1634 to i8
  %1636 = add i8 %1635, 48
  %1637 = getelementptr inbounds i8, ptr %1615, i64 3
  store i8 %1636, ptr %1631, align 1, !tbaa !30
  %1638 = urem i32 %1630, 100
  br label %1639

1639:                                             ; preds = %1633, %1629
  %1640 = phi i32 [ %1638, %1633 ], [ %1630, %1629 ]
  %1641 = phi ptr [ %1637, %1633 ], [ %1631, %1629 ]
  %1642 = udiv i32 %1640, 10
  %1643 = trunc i32 %1642 to i8
  %1644 = add i8 %1643, 48
  %1645 = getelementptr inbounds i8, ptr %1641, i64 1
  store i8 %1644, ptr %1641, align 1, !tbaa !30
  %1646 = urem i32 %1640, 10
  %1647 = trunc nuw nsw i32 %1646 to i8
  %1648 = or disjoint i8 %1647, 48
  %1649 = getelementptr inbounds i8, ptr %1641, i64 2
  store i8 %1648, ptr %1645, align 1, !tbaa !30
  br label %1650

1650:                                             ; preds = %1639, %1614
  %1651 = phi ptr [ %1649, %1639 ], [ %1615, %1614 ]
  store i8 0, ptr %1651, align 1, !tbaa !30
  %1652 = ptrtoint ptr %1651 to i64
  %1653 = ptrtoint ptr %1510 to i64
  %1654 = sub i64 %1652, %1653
  %1655 = trunc i64 %1654 to i32
  %1656 = icmp ne i8 %470, 0
  %1657 = icmp eq i8 %474, 0
  %1658 = select i1 %1656, i1 %1657, i1 false
  %1659 = icmp sgt i32 %475, %1655
  %1660 = select i1 %1658, i1 %1659, i1 false
  br i1 %1660, label %1661, label %1689

1661:                                             ; preds = %1650
  %1662 = icmp slt i32 %1655, 0
  br i1 %1662, label %1676, label %1663

1663:                                             ; preds = %1661
  %1664 = sub nsw i32 %475, %1655
  %1665 = sext i32 %475 to i64
  %1666 = sext i32 %1664 to i64
  %1667 = sext i32 %1664 to i64
  br label %1668

1668:                                             ; preds = %1668, %1663
  %1669 = phi i64 [ %1665, %1663 ], [ %1674, %1668 ]
  %1670 = sub nsw i64 %1669, %1666
  %1671 = getelementptr inbounds i8, ptr %1510, i64 %1670
  %1672 = load i8, ptr %1671, align 1, !tbaa !30
  %1673 = getelementptr inbounds i8, ptr %1510, i64 %1669
  store i8 %1672, ptr %1673, align 1, !tbaa !30
  %1674 = add nsw i64 %1669, -1
  %1675 = icmp sgt i64 %1669, %1667
  br i1 %1675, label %1668, label %1676, !llvm.loop !141

1676:                                             ; preds = %1668, %1661
  %1677 = icmp eq i32 %475, %1655
  br i1 %1677, label %1689, label %1678

1678:                                             ; preds = %1676
  %1679 = icmp ne i8 %1424, 0
  %1680 = zext i1 %1679 to i64
  %1681 = getelementptr i8, ptr %1510, i64 %1680
  %1682 = trunc i64 %1653 to i32
  %1683 = trunc i64 %1652 to i32
  %1684 = xor i32 %1683, -1
  %1685 = add i32 %1684, %1682
  %1686 = add i32 %1685, %475
  %1687 = zext i32 %1686 to i64
  %1688 = add nuw nsw i64 %1687, 1
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %1681, i8 48, i64 %1688, i1 false), !tbaa !30
  br label %1689

1689:                                             ; preds = %1678, %1676, %1650, %1507, %1416, %1402
  %1690 = phi ptr [ null, %1402 ], [ %1508, %1507 ], [ null, %1416 ], [ %1508, %1650 ], [ %1508, %1676 ], [ %1508, %1678 ]
  %1691 = phi i1 [ true, %1402 ], [ false, %1507 ], [ true, %1416 ], [ true, %1650 ], [ true, %1676 ], [ true, %1678 ]
  %1692 = phi i32 [ %1405, %1402 ], [ %197, %1507 ], [ %1420, %1416 ], [ %1655, %1650 ], [ %475, %1676 ], [ %475, %1678 ]
  %1693 = phi ptr [ %1404, %1402 ], [ %1510, %1507 ], [ %1417, %1416 ], [ %1510, %1650 ], [ %1510, %1676 ], [ %1510, %1678 ]
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %43) #16
  br i1 %1691, label %2491, label %2628

1694:                                             ; preds = %498
  br i1 %47, label %1695, label %2491

1695:                                             ; preds = %1694
  %1696 = load i32, ptr %137, align 8, !tbaa !75
  %1697 = load i32, ptr %2, align 8
  %1698 = icmp ult i32 %1697, 41
  br i1 %1698, label %1699, label %1704

1699:                                             ; preds = %1695
  %1700 = load ptr, ptr %139, align 8
  %1701 = zext nneg i32 %1697 to i64
  %1702 = getelementptr i8, ptr %1700, i64 %1701
  %1703 = add nuw nsw i32 %1697, 8
  store i32 %1703, ptr %2, align 8
  br label %1707

1704:                                             ; preds = %1695
  %1705 = load ptr, ptr %138, align 8
  %1706 = getelementptr i8, ptr %1705, i64 8
  store ptr %1706, ptr %138, align 8
  br label %1707

1707:                                             ; preds = %1704, %1699
  %1708 = phi ptr [ %1702, %1699 ], [ %1705, %1704 ]
  %1709 = load ptr, ptr %1708, align 8, !tbaa !36
  store i32 %1696, ptr %1709, align 4, !tbaa !86
  br label %2491

1710:                                             ; preds = %498
  store i8 37, ptr %42, align 16, !tbaa !30
  br label %2491

1711:                                             ; preds = %498
  br i1 %47, label %1758, label %1712

1712:                                             ; preds = %1711
  %1713 = load i32, ptr %65, align 8, !tbaa !79
  %1714 = load i32, ptr %119, align 4, !tbaa !81
  %1715 = icmp sgt i32 %1713, %1714
  br i1 %1715, label %1716, label %1740

1716:                                             ; preds = %1712
  %1717 = load ptr, ptr %120, align 8, !tbaa !82
  %1718 = add nsw i32 %1714, 1
  store i32 %1718, ptr %119, align 4, !tbaa !81
  %1719 = sext i32 %1714 to i64
  %1720 = getelementptr inbounds ptr, ptr %1717, i64 %1719
  %1721 = load ptr, ptr %1720, align 8, !tbaa !36
  %1722 = icmp eq ptr %1721, null
  br i1 %1722, label %1740, label %1723

1723:                                             ; preds = %1716
  %1724 = getelementptr inbounds i8, ptr %1721, i64 20
  %1725 = load i16, ptr %1724, align 4, !tbaa !83
  %1726 = and i16 %1725, 514
  %1727 = icmp eq i16 %1726, 514
  br i1 %1727, label %1728, label %1735

1728:                                             ; preds = %1723
  %1729 = getelementptr inbounds i8, ptr %1721, i64 22
  %1730 = load i8, ptr %1729, align 2, !tbaa !142
  %1731 = icmp eq i8 %1730, 1
  br i1 %1731, label %1732, label %1735

1732:                                             ; preds = %1728
  %1733 = getelementptr inbounds i8, ptr %1721, i64 8
  %1734 = load ptr, ptr %1733, align 8, !tbaa !85
  br label %1740

1735:                                             ; preds = %1728, %1723
  %1736 = and i16 %1725, 1
  %1737 = icmp eq i16 %1736, 0
  br i1 %1737, label %1738, label %1740

1738:                                             ; preds = %1735
  %1739 = call fastcc ptr @valueToText(ptr noundef nonnull %1721, i8 noundef zeroext 1)
  br label %1740

1740:                                             ; preds = %1738, %1735, %1732, %1716, %1712
  %1741 = phi ptr [ null, %1712 ], [ %1734, %1732 ], [ %1739, %1738 ], [ null, %1716 ], [ null, %1735 ]
  %1742 = icmp eq ptr %1741, null
  br i1 %1742, label %1757, label %1743

1743:                                             ; preds = %1740
  %1744 = load i8, ptr %1741, align 1, !tbaa !30
  store i8 %1744, ptr %42, align 16, !tbaa !30
  %1745 = icmp ugt i8 %1744, -65
  br i1 %1745, label %1746, label %1815

1746:                                             ; preds = %1753, %1743
  %1747 = phi i64 [ %1754, %1753 ], [ 1, %1743 ]
  %1748 = phi ptr [ %1749, %1753 ], [ %1741, %1743 ]
  %1749 = getelementptr inbounds i8, ptr %1748, i64 1
  %1750 = load i8, ptr %1749, align 1, !tbaa !30
  %1751 = and i8 %1750, -64
  %1752 = icmp eq i8 %1751, -128
  br i1 %1752, label %1753, label %1813

1753:                                             ; preds = %1746
  %1754 = add nuw nsw i64 %1747, 1
  %1755 = getelementptr inbounds [70 x i8], ptr %42, i64 0, i64 %1747
  store i8 %1750, ptr %1755, align 1, !tbaa !30
  %1756 = icmp eq i64 %1754, 4
  br i1 %1756, label %1815, label %1746

1757:                                             ; preds = %1740
  store i8 0, ptr %42, align 16, !tbaa !30
  br label %1815

1758:                                             ; preds = %1711
  %1759 = load i32, ptr %2, align 8
  %1760 = icmp ult i32 %1759, 41
  br i1 %1760, label %1761, label %1766

1761:                                             ; preds = %1758
  %1762 = load ptr, ptr %122, align 8
  %1763 = zext nneg i32 %1759 to i64
  %1764 = getelementptr i8, ptr %1762, i64 %1763
  %1765 = add nuw nsw i32 %1759, 8
  store i32 %1765, ptr %2, align 8
  br label %1769

1766:                                             ; preds = %1758
  %1767 = load ptr, ptr %121, align 8
  %1768 = getelementptr i8, ptr %1767, i64 8
  store ptr %1768, ptr %121, align 8
  br label %1769

1769:                                             ; preds = %1766, %1761
  %1770 = phi ptr [ %1764, %1761 ], [ %1767, %1766 ]
  %1771 = load i32, ptr %1770, align 4, !tbaa !86
  %1772 = icmp ult i32 %1771, 128
  br i1 %1772, label %1773, label %1775

1773:                                             ; preds = %1769
  %1774 = trunc nuw nsw i32 %1771 to i8
  store i8 %1774, ptr %42, align 16, !tbaa !30
  br label %1815

1775:                                             ; preds = %1769
  %1776 = icmp ult i32 %1771, 2048
  br i1 %1776, label %1777, label %1784

1777:                                             ; preds = %1775
  %1778 = lshr i32 %1771, 6
  %1779 = trunc nuw i32 %1778 to i8
  %1780 = or disjoint i8 %1779, -64
  store i8 %1780, ptr %42, align 16, !tbaa !30
  %1781 = trunc i32 %1771 to i8
  %1782 = and i8 %1781, 63
  %1783 = or disjoint i8 %1782, -128
  store i8 %1783, ptr %128, align 1, !tbaa !30
  br label %1815

1784:                                             ; preds = %1775
  %1785 = icmp ult i32 %1771, 65536
  br i1 %1785, label %1786, label %1797

1786:                                             ; preds = %1784
  %1787 = lshr i32 %1771, 12
  %1788 = trunc nuw i32 %1787 to i8
  %1789 = or disjoint i8 %1788, -32
  store i8 %1789, ptr %42, align 16, !tbaa !30
  %1790 = lshr i32 %1771, 6
  %1791 = trunc i32 %1790 to i8
  %1792 = and i8 %1791, 63
  %1793 = or disjoint i8 %1792, -128
  store i8 %1793, ptr %126, align 1, !tbaa !30
  %1794 = trunc i32 %1771 to i8
  %1795 = and i8 %1794, 63
  %1796 = or disjoint i8 %1795, -128
  store i8 %1796, ptr %127, align 2, !tbaa !30
  br label %1815

1797:                                             ; preds = %1784
  %1798 = lshr i32 %1771, 18
  %1799 = trunc i32 %1798 to i8
  %1800 = and i8 %1799, 7
  %1801 = or disjoint i8 %1800, -16
  store i8 %1801, ptr %42, align 16, !tbaa !30
  %1802 = lshr i32 %1771, 12
  %1803 = trunc i32 %1802 to i8
  %1804 = and i8 %1803, 63
  %1805 = or disjoint i8 %1804, -128
  store i8 %1805, ptr %123, align 1, !tbaa !30
  %1806 = lshr i32 %1771, 6
  %1807 = trunc i32 %1806 to i8
  %1808 = and i8 %1807, 63
  %1809 = or disjoint i8 %1808, -128
  store i8 %1809, ptr %124, align 2, !tbaa !30
  %1810 = trunc i32 %1771 to i8
  %1811 = and i8 %1810, 63
  %1812 = or disjoint i8 %1811, -128
  store i8 %1812, ptr %125, align 1, !tbaa !30
  br label %1815

1813:                                             ; preds = %1746
  %1814 = trunc nuw nsw i64 %1747 to i32
  br label %1815

1815:                                             ; preds = %1813, %1797, %1786, %1777, %1773, %1757, %1753, %1743
  %1816 = phi i32 [ 1, %1743 ], [ 1, %1757 ], [ 1, %1773 ], [ 2, %1777 ], [ 3, %1786 ], [ 4, %1797 ], [ %1814, %1813 ], [ 4, %1753 ]
  %1817 = icmp sgt i32 %476, 1
  br i1 %1817, label %1818, label %2046

1818:                                             ; preds = %1815
  %1819 = add nsw i32 %476, -1
  %1820 = sub nsw i32 %475, %1819
  %1821 = icmp slt i32 %1820, 2
  %1822 = icmp ne i8 %474, 0
  %1823 = select i1 %1821, i1 true, i1 %1822
  br i1 %1823, label %1848, label %1824

1824:                                             ; preds = %1818
  %1825 = add nsw i32 %1820, -1
  %1826 = load i32, ptr %129, align 8, !tbaa !75
  %1827 = zext i32 %1826 to i64
  %1828 = sext i32 %1825 to i64
  %1829 = add nsw i64 %1827, %1828
  %1830 = load i32, ptr %130, align 8, !tbaa !76
  %1831 = zext i32 %1830 to i64
  %1832 = icmp slt i64 %1829, %1831
  br i1 %1832, label %1836, label %1833

1833:                                             ; preds = %1824
  %1834 = call fastcc i32 @sqlite3StrAccumEnlarge(ptr noundef %0, i64 noundef %1828)
  %1835 = icmp slt i32 %1834, 1
  br i1 %1835, label %1848, label %1836

1836:                                             ; preds = %1833, %1824
  %1837 = phi i32 [ %1834, %1833 ], [ %1825, %1824 ]
  %1838 = icmp sgt i32 %1837, 0
  br i1 %1838, label %1839, label %1848

1839:                                             ; preds = %1839, %1836
  %1840 = phi i32 [ %1841, %1839 ], [ %1837, %1836 ]
  %1841 = add nsw i32 %1840, -1
  %1842 = load ptr, ptr %131, align 8, !tbaa !77
  %1843 = load i32, ptr %129, align 8, !tbaa !75
  %1844 = add i32 %1843, 1
  store i32 %1844, ptr %129, align 8, !tbaa !75
  %1845 = zext i32 %1843 to i64
  %1846 = getelementptr inbounds i8, ptr %1842, i64 %1845
  store i8 32, ptr %1846, align 1, !tbaa !30
  %1847 = icmp sgt i32 %1840, 1
  br i1 %1847, label %1839, label %1848, !llvm.loop !143

1848:                                             ; preds = %1839, %1836, %1833, %1818
  %1849 = phi i32 [ %1820, %1818 ], [ 0, %1833 ], [ 0, %1836 ], [ 0, %1839 ]
  %1850 = load i32, ptr %132, align 8, !tbaa !75
  %1851 = add i32 %1850, %1816
  %1852 = load i32, ptr %133, align 8, !tbaa !76
  %1853 = icmp ult i32 %1851, %1852
  br i1 %1853, label %1855, label %1854

1854:                                             ; preds = %1848
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull %42, i32 noundef %1816)
  br label %1860

1855:                                             ; preds = %1848
  store i32 %1851, ptr %132, align 8, !tbaa !75
  %1856 = load ptr, ptr %134, align 8, !tbaa !77
  %1857 = zext i32 %1850 to i64
  %1858 = getelementptr inbounds i8, ptr %1856, i64 %1857
  %1859 = zext nneg i32 %1816 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %1858, ptr noundef nonnull align 16 %42, i64 noundef %1859, i1 noundef false) #16
  br label %1860

1860:                                             ; preds = %1855, %1854
  %1861 = zext nneg i32 %1816 to i64
  br label %1862

1862:                                             ; preds = %1903, %1860
  %1863 = phi i64 [ 1, %1860 ], [ %1904, %1903 ]
  %1864 = phi i32 [ %1819, %1860 ], [ %1905, %1903 ]
  %1865 = icmp sgt i32 %1864, 1
  br i1 %1865, label %1866, label %2046

1866:                                             ; preds = %1862
  %1867 = add nsw i32 %1864, -1
  %1868 = zext nneg i32 %1867 to i64
  %1869 = call i64 @llvm.smin.i64(i64 %1863, i64 %1868)
  %1870 = mul nsw i64 %1869, %1861
  %1871 = load i32, ptr %132, align 8, !tbaa !75
  %1872 = zext i32 %1871 to i64
  %1873 = add nsw i64 %1870, %1872
  %1874 = load i32, ptr %133, align 8, !tbaa !76
  %1875 = zext i32 %1874 to i64
  %1876 = icmp slt i64 %1873, %1875
  br i1 %1876, label %1879, label %1877

1877:                                             ; preds = %1866
  %1878 = call fastcc i32 @sqlite3StrAccumEnlarge(ptr noundef %0, i64 noundef %1870)
  br label %1879

1879:                                             ; preds = %1877, %1866
  %1880 = load i8, ptr %135, align 4, !tbaa !96
  %1881 = icmp eq i8 %1880, 0
  br i1 %1881, label %1882, label %1903

1882:                                             ; preds = %1879
  %1883 = load ptr, ptr %136, align 8, !tbaa !77
  %1884 = load i32, ptr %132, align 8, !tbaa !75
  %1885 = zext i32 %1884 to i64
  %1886 = sub nsw i64 %1885, %1870
  %1887 = getelementptr inbounds i8, ptr %1883, i64 %1886
  %1888 = trunc i64 %1870 to i32
  %1889 = add i32 %1884, %1888
  %1890 = load i32, ptr %133, align 8, !tbaa !76
  %1891 = icmp ult i32 %1889, %1890
  br i1 %1891, label %1893, label %1892

1892:                                             ; preds = %1882
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %1887, i32 noundef %1888)
  br label %1899

1893:                                             ; preds = %1882
  %1894 = icmp eq i32 %1888, 0
  br i1 %1894, label %1899, label %1895

1895:                                             ; preds = %1893
  store i32 %1889, ptr %132, align 8, !tbaa !75
  %1896 = getelementptr inbounds i8, ptr %1883, i64 %1885
  %1897 = shl i64 %1870, 32
  %1898 = ashr exact i64 %1897, 32
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %1896, ptr noundef align 1 %1887, i64 noundef %1898, i1 noundef false) #16
  br label %1899

1899:                                             ; preds = %1895, %1893, %1892
  %1900 = trunc i64 %1869 to i32
  %1901 = sub i32 %1864, %1900
  %1902 = shl nsw i64 %1869, 1
  br label %1903

1903:                                             ; preds = %1899, %1879
  %1904 = phi i64 [ %1902, %1899 ], [ %1869, %1879 ]
  %1905 = phi i32 [ %1901, %1899 ], [ %1864, %1879 ]
  br i1 %1881, label %1862, label %2046

1906:                                             ; preds = %498, %498
  br i1 %47, label %1935, label %1907

1907:                                             ; preds = %1906
  %1908 = load i32, ptr %65, align 8, !tbaa !79
  %1909 = load i32, ptr %110, align 4, !tbaa !81
  %1910 = icmp sgt i32 %1908, %1909
  br i1 %1910, label %1911, label %1949

1911:                                             ; preds = %1907
  %1912 = load ptr, ptr %111, align 8, !tbaa !82
  %1913 = add nsw i32 %1909, 1
  store i32 %1913, ptr %110, align 4, !tbaa !81
  %1914 = sext i32 %1909 to i64
  %1915 = getelementptr inbounds ptr, ptr %1912, i64 %1914
  %1916 = load ptr, ptr %1915, align 8, !tbaa !36
  %1917 = icmp eq ptr %1916, null
  br i1 %1917, label %1949, label %1918

1918:                                             ; preds = %1911
  %1919 = getelementptr inbounds i8, ptr %1916, i64 20
  %1920 = load i16, ptr %1919, align 4, !tbaa !83
  %1921 = and i16 %1920, 514
  %1922 = icmp eq i16 %1921, 514
  br i1 %1922, label %1923, label %1930

1923:                                             ; preds = %1918
  %1924 = getelementptr inbounds i8, ptr %1916, i64 22
  %1925 = load i8, ptr %1924, align 2, !tbaa !142
  %1926 = icmp eq i8 %1925, 1
  br i1 %1926, label %1927, label %1930

1927:                                             ; preds = %1923
  %1928 = getelementptr inbounds i8, ptr %1916, i64 8
  %1929 = load ptr, ptr %1928, align 8, !tbaa !85
  br label %1949

1930:                                             ; preds = %1923, %1918
  %1931 = and i16 %1920, 1
  %1932 = icmp eq i16 %1931, 0
  br i1 %1932, label %1933, label %1949

1933:                                             ; preds = %1930
  %1934 = call fastcc ptr @valueToText(ptr noundef nonnull %1916, i8 noundef zeroext 1)
  br label %1949

1935:                                             ; preds = %1906
  %1936 = load i32, ptr %2, align 8
  %1937 = icmp ult i32 %1936, 41
  br i1 %1937, label %1938, label %1943

1938:                                             ; preds = %1935
  %1939 = load ptr, ptr %113, align 8
  %1940 = zext nneg i32 %1936 to i64
  %1941 = getelementptr i8, ptr %1939, i64 %1940
  %1942 = add nuw nsw i32 %1936, 8
  store i32 %1942, ptr %2, align 8
  br label %1946

1943:                                             ; preds = %1935
  %1944 = load ptr, ptr %112, align 8
  %1945 = getelementptr i8, ptr %1944, i64 8
  store ptr %1945, ptr %112, align 8
  br label %1946

1946:                                             ; preds = %1943, %1938
  %1947 = phi ptr [ %1941, %1938 ], [ %1944, %1943 ]
  %1948 = load ptr, ptr %1947, align 8, !tbaa !36
  br label %1949

1949:                                             ; preds = %1946, %1933, %1930, %1927, %1911, %1907
  %1950 = phi i8 [ %499, %1946 ], [ 5, %1933 ], [ 5, %1930 ], [ 5, %1927 ], [ 5, %1911 ], [ 5, %1907 ]
  %1951 = phi ptr [ %1948, %1946 ], [ %1934, %1933 ], [ null, %1930 ], [ %1929, %1927 ], [ null, %1911 ], [ null, %1907 ]
  %1952 = icmp eq ptr %1951, null
  br i1 %1952, label %1997, label %1953

1953:                                             ; preds = %1949
  %1954 = icmp eq i8 %1950, 6
  br i1 %1954, label %1955, label %1997

1955:                                             ; preds = %1953
  %1956 = load i32, ptr %114, align 8, !tbaa !75
  %1957 = icmp eq i32 %1956, 0
  br i1 %1957, label %1958, label %1997

1958:                                             ; preds = %1955
  %1959 = load i32, ptr %115, align 4, !tbaa !97
  %1960 = icmp ne i32 %1959, 0
  %1961 = icmp eq i32 %475, 0
  %1962 = select i1 %1960, i1 %1961, i1 false
  %1963 = icmp slt i32 %476, 0
  %1964 = select i1 %1962, i1 %1963, i1 false
  br i1 %1964, label %1965, label %1997

1965:                                             ; preds = %1958
  %1966 = load i8, ptr %116, align 4, !tbaa !96
  %1967 = icmp eq i8 %1966, 0
  br i1 %1967, label %1968, label %1997

1968:                                             ; preds = %1965
  store ptr %1951, ptr %117, align 8, !tbaa !77
  %1969 = load ptr, ptr %0, align 8, !tbaa !98
  %1970 = icmp eq ptr %1969, null
  br i1 %1970, label %1987, label %1971

1971:                                             ; preds = %1968
  %1972 = getelementptr inbounds i8, ptr %1969, i64 496
  %1973 = load ptr, ptr %1972, align 8, !tbaa !144
  %1974 = icmp ugt ptr %1973, %1951
  br i1 %1974, label %1975, label %1987

1975:                                             ; preds = %1971
  %1976 = getelementptr inbounds i8, ptr %1969, i64 472
  %1977 = load ptr, ptr %1976, align 8, !tbaa !145
  %1978 = icmp ugt ptr %1977, %1951
  br i1 %1978, label %1979, label %1990

1979:                                             ; preds = %1975
  %1980 = getelementptr inbounds i8, ptr %1969, i64 480
  %1981 = load ptr, ptr %1980, align 8, !tbaa !146
  %1982 = icmp ugt ptr %1981, %1951
  br i1 %1982, label %1987, label %1983

1983:                                             ; preds = %1979
  %1984 = getelementptr inbounds i8, ptr %1969, i64 414
  %1985 = load i16, ptr %1984, align 2, !tbaa !147
  %1986 = zext i16 %1985 to i32
  br label %1990

1987:                                             ; preds = %1979, %1971, %1968
  %1988 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %1989 = call i32 %1988(ptr noundef nonnull %1951) #16
  br label %1990

1990:                                             ; preds = %1987, %1983, %1975
  %1991 = phi i32 [ %1986, %1983 ], [ %1989, %1987 ], [ 128, %1975 ]
  store i32 %1991, ptr %118, align 8, !tbaa !76
  %1992 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %1951) #16
  %1993 = trunc i64 %1992 to i32
  %1994 = and i32 %1993, 2147483647
  store i32 %1994, ptr %114, align 8, !tbaa !75
  %1995 = load i8, ptr %44, align 1, !tbaa !73
  %1996 = or i8 %1995, 4
  store i8 %1996, ptr %44, align 1, !tbaa !73
  br label %2491

1997:                                             ; preds = %1965, %1958, %1955, %1953, %1949
  %1998 = phi ptr [ null, %1953 ], [ null, %1949 ], [ %1951, %1965 ], [ %1951, %1958 ], [ %1951, %1955 ]
  %1999 = phi ptr [ %1951, %1953 ], [ @.str.4, %1949 ], [ %1951, %1965 ], [ %1951, %1958 ], [ %1951, %1955 ]
  %2000 = icmp sgt i32 %476, -1
  br i1 %2000, label %2001, label %2040

2001:                                             ; preds = %1997
  %2002 = icmp eq i8 %471, 0
  %2003 = icmp eq i32 %476, 0
  br i1 %2002, label %2005, label %2004

2004:                                             ; preds = %2001
  br i1 %2003, label %2026, label %2008

2005:                                             ; preds = %2001
  br i1 %2003, label %2046, label %2006

2006:                                             ; preds = %2005
  %2007 = zext nneg i32 %476 to i64
  br label %2032

2008:                                             ; preds = %2023, %2004
  %2009 = phi i32 [ %2011, %2023 ], [ %476, %2004 ]
  %2010 = phi ptr [ %2024, %2023 ], [ %1999, %2004 ]
  %2011 = add nsw i32 %2009, -1
  %2012 = load i8, ptr %2010, align 1, !tbaa !30
  %2013 = icmp eq i8 %2012, 0
  br i1 %2013, label %2026, label %2014

2014:                                             ; preds = %2008
  %2015 = getelementptr inbounds i8, ptr %2010, i64 1
  %2016 = icmp ugt i8 %2012, -65
  br i1 %2016, label %2017, label %2023

2017:                                             ; preds = %2017, %2014
  %2018 = phi ptr [ %2022, %2017 ], [ %2015, %2014 ]
  %2019 = load i8, ptr %2018, align 1, !tbaa !30
  %2020 = and i8 %2019, -64
  %2021 = icmp eq i8 %2020, -128
  %2022 = getelementptr inbounds i8, ptr %2018, i64 1
  br i1 %2021, label %2017, label %2023, !llvm.loop !148

2023:                                             ; preds = %2017, %2014
  %2024 = phi ptr [ %2015, %2014 ], [ %2018, %2017 ]
  %2025 = icmp sgt i32 %2009, 1
  br i1 %2025, label %2008, label %2026, !llvm.loop !149

2026:                                             ; preds = %2023, %2008, %2004
  %2027 = phi ptr [ %1999, %2004 ], [ %2010, %2008 ], [ %2024, %2023 ]
  %2028 = ptrtoint ptr %2027 to i64
  %2029 = ptrtoint ptr %1999 to i64
  %2030 = sub i64 %2028, %2029
  %2031 = trunc i64 %2030 to i32
  br label %2046

2032:                                             ; preds = %2037, %2006
  %2033 = phi i64 [ 0, %2006 ], [ %2038, %2037 ]
  %2034 = getelementptr inbounds i8, ptr %1999, i64 %2033
  %2035 = load i8, ptr %2034, align 1, !tbaa !30
  %2036 = icmp eq i8 %2035, 0
  br i1 %2036, label %2044, label %2037

2037:                                             ; preds = %2032
  %2038 = add nuw nsw i64 %2033, 1
  %2039 = icmp eq i64 %2038, %2007
  br i1 %2039, label %2046, label %2032, !llvm.loop !150

2040:                                             ; preds = %1997
  %2041 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %1999) #16
  %2042 = trunc i64 %2041 to i32
  %2043 = and i32 %2042, 2147483647
  br label %2046

2044:                                             ; preds = %2032
  %2045 = trunc nuw nsw i64 %2033 to i32
  br label %2046

2046:                                             ; preds = %2231, %2044, %2040, %2037, %2026, %2005, %1903, %1862, %1815
  %2047 = phi ptr [ %2232, %2231 ], [ %1998, %2026 ], [ %1998, %2040 ], [ null, %1815 ], [ %1998, %2005 ], [ null, %1862 ], [ null, %1903 ], [ %1998, %2037 ], [ %1998, %2044 ]
  %2048 = phi i8 [ %471, %2231 ], [ 1, %2026 ], [ %471, %2040 ], [ 1, %1815 ], [ 0, %2005 ], [ 1, %1862 ], [ 1, %1903 ], [ 0, %2037 ], [ 0, %2044 ]
  %2049 = phi i32 [ %475, %2231 ], [ %475, %2026 ], [ %475, %2040 ], [ %475, %1815 ], [ %475, %2005 ], [ %1849, %1862 ], [ %1849, %1903 ], [ %475, %2037 ], [ %475, %2044 ]
  %2050 = phi i32 [ %2234, %2231 ], [ %2031, %2026 ], [ %2043, %2040 ], [ %1816, %1815 ], [ 0, %2005 ], [ %1816, %1862 ], [ %1816, %1903 ], [ %2045, %2044 ], [ %476, %2037 ]
  %2051 = phi ptr [ %2235, %2231 ], [ %1999, %2026 ], [ %1999, %2040 ], [ %42, %1815 ], [ %1999, %2005 ], [ %42, %1862 ], [ %42, %1903 ], [ %1999, %2037 ], [ %1999, %2044 ]
  %2052 = icmp ne i8 %2048, 0
  %2053 = icmp sgt i32 %2049, 0
  %2054 = select i1 %2052, i1 %2053, i1 false
  %2055 = icmp sgt i32 %2050, 0
  %2056 = select i1 %2054, i1 %2055, i1 false
  br i1 %2056, label %2057, label %2491

2057:                                             ; preds = %2046
  %2058 = zext nneg i32 %2050 to i64
  br label %2059

2059:                                             ; preds = %2059, %2057
  %2060 = phi i64 [ %2058, %2057 ], [ %2062, %2059 ]
  %2061 = phi i32 [ %2049, %2057 ], [ %2068, %2059 ]
  %2062 = add nsw i64 %2060, -1
  %2063 = getelementptr inbounds i8, ptr %2051, i64 %2062
  %2064 = load i8, ptr %2063, align 1, !tbaa !30
  %2065 = and i8 %2064, -64
  %2066 = icmp eq i8 %2065, -128
  %2067 = zext i1 %2066 to i32
  %2068 = add nuw nsw i32 %2061, %2067
  %2069 = icmp sgt i64 %2060, 1
  br i1 %2069, label %2059, label %2491, !llvm.loop !151

2070:                                             ; preds = %498, %498, %498
  %2071 = icmp eq i8 %499, 14
  %2072 = select i1 %2071, i8 34, i8 39
  br i1 %47, label %2101, label %2073

2073:                                             ; preds = %2070
  %2074 = load i32, ptr %65, align 8, !tbaa !79
  %2075 = load i32, ptr %102, align 4, !tbaa !81
  %2076 = icmp sgt i32 %2074, %2075
  br i1 %2076, label %2077, label %2115

2077:                                             ; preds = %2073
  %2078 = load ptr, ptr %103, align 8, !tbaa !82
  %2079 = add nsw i32 %2075, 1
  store i32 %2079, ptr %102, align 4, !tbaa !81
  %2080 = sext i32 %2075 to i64
  %2081 = getelementptr inbounds ptr, ptr %2078, i64 %2080
  %2082 = load ptr, ptr %2081, align 8, !tbaa !36
  %2083 = icmp eq ptr %2082, null
  br i1 %2083, label %2115, label %2084

2084:                                             ; preds = %2077
  %2085 = getelementptr inbounds i8, ptr %2082, i64 20
  %2086 = load i16, ptr %2085, align 4, !tbaa !83
  %2087 = and i16 %2086, 514
  %2088 = icmp eq i16 %2087, 514
  br i1 %2088, label %2089, label %2096

2089:                                             ; preds = %2084
  %2090 = getelementptr inbounds i8, ptr %2082, i64 22
  %2091 = load i8, ptr %2090, align 2, !tbaa !142
  %2092 = icmp eq i8 %2091, 1
  br i1 %2092, label %2093, label %2096

2093:                                             ; preds = %2089
  %2094 = getelementptr inbounds i8, ptr %2082, i64 8
  %2095 = load ptr, ptr %2094, align 8, !tbaa !85
  br label %2115

2096:                                             ; preds = %2089, %2084
  %2097 = and i16 %2086, 1
  %2098 = icmp eq i16 %2097, 0
  br i1 %2098, label %2099, label %2115

2099:                                             ; preds = %2096
  %2100 = call fastcc ptr @valueToText(ptr noundef nonnull %2082, i8 noundef zeroext 1)
  br label %2115

2101:                                             ; preds = %2070
  %2102 = load i32, ptr %2, align 8
  %2103 = icmp ult i32 %2102, 41
  br i1 %2103, label %2104, label %2109

2104:                                             ; preds = %2101
  %2105 = load ptr, ptr %105, align 8
  %2106 = zext nneg i32 %2102 to i64
  %2107 = getelementptr i8, ptr %2105, i64 %2106
  %2108 = add nuw nsw i32 %2102, 8
  store i32 %2108, ptr %2, align 8
  br label %2112

2109:                                             ; preds = %2101
  %2110 = load ptr, ptr %104, align 8
  %2111 = getelementptr i8, ptr %2110, i64 8
  store ptr %2111, ptr %104, align 8
  br label %2112

2112:                                             ; preds = %2109, %2104
  %2113 = phi ptr [ %2107, %2104 ], [ %2110, %2109 ]
  %2114 = load ptr, ptr %2113, align 8, !tbaa !36
  br label %2115

2115:                                             ; preds = %2112, %2099, %2096, %2093, %2077, %2073
  %2116 = phi ptr [ %2114, %2112 ], [ null, %2073 ], [ %2095, %2093 ], [ %2100, %2099 ], [ null, %2077 ], [ null, %2096 ]
  %2117 = icmp ne ptr %2116, null
  %2118 = icmp eq i8 %499, 10
  %2119 = select i1 %2118, ptr @.str.5, ptr @.str.6
  %2120 = select i1 %2117, ptr %2116, ptr %2119
  %2121 = icmp eq i32 %476, 0
  br i1 %2121, label %2150, label %2122

2122:                                             ; preds = %2115
  %2123 = sext i32 %476 to i64
  %2124 = icmp ne i8 %471, 0
  br label %2125

2125:                                             ; preds = %2145, %2122
  %2126 = phi i64 [ 0, %2122 ], [ %2135, %2145 ]
  %2127 = phi i64 [ %2123, %2122 ], [ %2148, %2145 ]
  %2128 = phi i64 [ 0, %2122 ], [ %2147, %2145 ]
  %2129 = getelementptr inbounds i8, ptr %2120, i64 %2128
  %2130 = load i8, ptr %2129, align 1, !tbaa !30
  %2131 = icmp eq i8 %2130, 0
  br i1 %2131, label %2150, label %2132

2132:                                             ; preds = %2125
  %2133 = icmp eq i8 %2130, %2072
  %2134 = zext i1 %2133 to i64
  %2135 = add nuw nsw i64 %2126, %2134
  %2136 = icmp ugt i8 %2130, -65
  %2137 = and i1 %2124, %2136
  br i1 %2137, label %2138, label %2145

2138:                                             ; preds = %2138, %2132
  %2139 = phi i64 [ %2140, %2138 ], [ %2128, %2132 ]
  %2140 = add nsw i64 %2139, 1
  %2141 = getelementptr inbounds i8, ptr %2120, i64 %2140
  %2142 = load i8, ptr %2141, align 1, !tbaa !30
  %2143 = and i8 %2142, -64
  %2144 = icmp eq i8 %2143, -128
  br i1 %2144, label %2138, label %2145, !llvm.loop !152

2145:                                             ; preds = %2138, %2132
  %2146 = phi i64 [ %2128, %2132 ], [ %2139, %2138 ]
  %2147 = add nsw i64 %2146, 1
  %2148 = add nsw i64 %2127, -1
  %2149 = icmp eq i64 %2148, 0
  br i1 %2149, label %2150, label %2125, !llvm.loop !153

2150:                                             ; preds = %2145, %2125, %2115
  %2151 = phi i64 [ 0, %2115 ], [ %2128, %2125 ], [ %2147, %2145 ]
  %2152 = phi i64 [ 0, %2115 ], [ %2126, %2125 ], [ %2135, %2145 ]
  %2153 = and i1 %2118, %2117
  %2154 = add nsw i64 %2151, 3
  %2155 = add nsw i64 %2154, %2152
  %2156 = icmp sgt i64 %2155, 70
  br i1 %2156, label %2157, label %2200

2157:                                             ; preds = %2150
  %2158 = load i8, ptr %106, align 4, !tbaa !96
  %2159 = icmp eq i8 %2158, 0
  br i1 %2159, label %2160, label %2197

2160:                                             ; preds = %2157
  %2161 = load i32, ptr %107, align 8, !tbaa !76
  %2162 = zext i32 %2161 to i64
  %2163 = icmp sgt i64 %2155, %2162
  br i1 %2163, label %2164, label %2183

2164:                                             ; preds = %2160
  %2165 = load i32, ptr %108, align 4, !tbaa !97
  %2166 = zext i32 %2165 to i64
  %2167 = icmp sgt i64 %2155, %2166
  br i1 %2167, label %2168, label %2183

2168:                                             ; preds = %2164
  store i8 18, ptr %106, align 4, !tbaa !96
  %2169 = icmp eq i32 %2165, 0
  br i1 %2169, label %2171, label %2170

2170:                                             ; preds = %2168
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %2171

2171:                                             ; preds = %2170, %2168
  %2172 = load ptr, ptr %0, align 8, !tbaa !98
  %2173 = icmp eq ptr %2172, null
  br i1 %2173, label %2197, label %2174

2174:                                             ; preds = %2171
  %2175 = getelementptr inbounds i8, ptr %2172, i64 344
  %2176 = load ptr, ptr %2175, align 8, !tbaa !99
  %2177 = icmp eq ptr %2176, null
  br i1 %2177, label %2197, label %2178

2178:                                             ; preds = %2174
  %2179 = getelementptr inbounds i8, ptr %2176, i64 24
  store i32 18, ptr %2179, align 8, !tbaa !105
  %2180 = getelementptr inbounds i8, ptr %2176, i64 48
  %2181 = load i32, ptr %2180, align 8, !tbaa !108
  %2182 = add nsw i32 %2181, 1
  store i32 %2182, ptr %2180, align 8, !tbaa !108
  br label %2197

2183:                                             ; preds = %2164, %2160
  %2184 = load ptr, ptr %0, align 8, !tbaa !98
  %2185 = icmp eq ptr %2184, null
  br i1 %2185, label %2188, label %2186

2186:                                             ; preds = %2183
  %2187 = call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %2184, i64 noundef %2155)
  br label %2190

2188:                                             ; preds = %2183
  %2189 = call fastcc ptr @sqlite3Malloc(i64 noundef %2155)
  br label %2190

2190:                                             ; preds = %2188, %2186
  %2191 = phi ptr [ %2187, %2186 ], [ %2189, %2188 ]
  %2192 = icmp eq ptr %2191, null
  br i1 %2192, label %2193, label %2197

2193:                                             ; preds = %2190
  store i8 7, ptr %106, align 4, !tbaa !96
  %2194 = load i32, ptr %109, align 4, !tbaa !97
  %2195 = icmp eq i32 %2194, 0
  br i1 %2195, label %2197, label %2196

2196:                                             ; preds = %2193
  call void @sqlite3_str_reset(ptr noundef %0)
  br label %2197

2197:                                             ; preds = %2196, %2193, %2190, %2178, %2174, %2171, %2157
  %2198 = phi ptr [ null, %2157 ], [ %2191, %2190 ], [ null, %2171 ], [ null, %2174 ], [ null, %2178 ], [ %2191, %2193 ], [ %2191, %2196 ]
  %2199 = icmp eq ptr %2198, null
  br i1 %2199, label %2231, label %2200

2200:                                             ; preds = %2197, %2150
  %2201 = phi ptr [ %2198, %2197 ], [ null, %2150 ]
  %2202 = phi ptr [ %2198, %2197 ], [ %42, %2150 ]
  br i1 %2153, label %2203, label %2204

2203:                                             ; preds = %2200
  store i8 %2072, ptr %2202, align 1, !tbaa !30
  br label %2204

2204:                                             ; preds = %2203, %2200
  %2205 = phi i64 [ 1, %2203 ], [ 0, %2200 ]
  %2206 = icmp sgt i64 %2151, 0
  br i1 %2206, label %2207, label %2222

2207:                                             ; preds = %2218, %2204
  %2208 = phi i64 [ %2219, %2218 ], [ %2205, %2204 ]
  %2209 = phi i64 [ %2220, %2218 ], [ 0, %2204 ]
  %2210 = getelementptr inbounds i8, ptr %2120, i64 %2209
  %2211 = load i8, ptr %2210, align 1, !tbaa !30
  %2212 = add nsw i64 %2208, 1
  %2213 = getelementptr inbounds i8, ptr %2202, i64 %2208
  store i8 %2211, ptr %2213, align 1, !tbaa !30
  %2214 = icmp eq i8 %2211, %2072
  br i1 %2214, label %2215, label %2218

2215:                                             ; preds = %2207
  %2216 = add nsw i64 %2208, 2
  %2217 = getelementptr inbounds i8, ptr %2202, i64 %2212
  store i8 %2211, ptr %2217, align 1, !tbaa !30
  br label %2218

2218:                                             ; preds = %2215, %2207
  %2219 = phi i64 [ %2216, %2215 ], [ %2212, %2207 ]
  %2220 = add nuw nsw i64 %2209, 1
  %2221 = icmp eq i64 %2220, %2151
  br i1 %2221, label %2222, label %2207, !llvm.loop !154

2222:                                             ; preds = %2218, %2204
  %2223 = phi i64 [ %2205, %2204 ], [ %2219, %2218 ]
  br i1 %2153, label %2224, label %2227

2224:                                             ; preds = %2222
  %2225 = add nsw i64 %2223, 1
  %2226 = getelementptr inbounds i8, ptr %2202, i64 %2223
  store i8 %2072, ptr %2226, align 1, !tbaa !30
  br label %2227

2227:                                             ; preds = %2224, %2222
  %2228 = phi i64 [ %2225, %2224 ], [ %2223, %2222 ]
  %2229 = getelementptr inbounds i8, ptr %2202, i64 %2228
  store i8 0, ptr %2229, align 1, !tbaa !30
  %2230 = trunc i64 %2228 to i32
  br label %2231

2231:                                             ; preds = %2227, %2197
  %2232 = phi ptr [ %2201, %2227 ], [ null, %2197 ]
  %2233 = phi i1 [ true, %2227 ], [ false, %2197 ]
  %2234 = phi i32 [ %2230, %2227 ], [ %197, %2197 ]
  %2235 = phi ptr [ %2202, %2227 ], [ null, %2197 ]
  br i1 %2233, label %2046, label %2628

2236:                                             ; preds = %498
  %2237 = load i8, ptr %44, align 1, !tbaa !73
  %2238 = and i8 %2237, 1
  %2239 = icmp eq i8 %2238, 0
  br i1 %2239, label %2628, label %2240

2240:                                             ; preds = %2236
  %2241 = icmp eq i8 %472, 0
  %2242 = load i32, ptr %2, align 8
  %2243 = icmp ult i32 %2242, 41
  br i1 %2241, label %2302, label %2244

2244:                                             ; preds = %2240
  br i1 %2243, label %2245, label %2250

2245:                                             ; preds = %2244
  %2246 = load ptr, ptr %93, align 8
  %2247 = zext nneg i32 %2242 to i64
  %2248 = getelementptr i8, ptr %2246, i64 %2247
  %2249 = add nuw nsw i32 %2242, 8
  store i32 %2249, ptr %2, align 8
  br label %2253

2250:                                             ; preds = %2244
  %2251 = load ptr, ptr %92, align 8
  %2252 = getelementptr i8, ptr %2251, i64 8
  store ptr %2252, ptr %92, align 8
  br label %2253

2253:                                             ; preds = %2250, %2245
  %2254 = phi ptr [ %2248, %2245 ], [ %2251, %2250 ]
  %2255 = load ptr, ptr %2254, align 8, !tbaa !36
  %2256 = icmp eq ptr %2255, null
  br i1 %2256, label %2491, label %2257

2257:                                             ; preds = %2253
  %2258 = getelementptr inbounds i8, ptr %2255, i64 4
  %2259 = load i32, ptr %2258, align 4, !tbaa !155
  %2260 = and i32 %2259, 2048
  %2261 = icmp eq i32 %2260, 0
  br i1 %2261, label %2262, label %2491

2262:                                             ; preds = %2257
  %2263 = getelementptr inbounds i8, ptr %2255, i64 8
  %2264 = load ptr, ptr %2263, align 8, !tbaa !30
  %2265 = icmp eq ptr %2264, null
  br i1 %2265, label %2270, label %2266

2266:                                             ; preds = %2262
  %2267 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2264) #16
  %2268 = trunc i64 %2267 to i32
  %2269 = and i32 %2268, 1073741823
  br label %2270

2270:                                             ; preds = %2266, %2262
  %2271 = phi i32 [ %2269, %2266 ], [ 0, %2262 ]
  %2272 = load i32, ptr %94, align 8, !tbaa !75
  %2273 = add i32 %2272, %2271
  %2274 = load i32, ptr %95, align 8, !tbaa !76
  %2275 = icmp ult i32 %2273, %2274
  br i1 %2275, label %2277, label %2276

2276:                                             ; preds = %2270
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2264, i32 noundef %2271)
  br label %2284

2277:                                             ; preds = %2270
  %2278 = icmp eq i32 %2271, 0
  br i1 %2278, label %2284, label %2279

2279:                                             ; preds = %2277
  store i32 %2273, ptr %94, align 8, !tbaa !75
  %2280 = load ptr, ptr %96, align 8, !tbaa !77
  %2281 = zext i32 %2272 to i64
  %2282 = getelementptr inbounds i8, ptr %2280, i64 %2281
  %2283 = zext nneg i32 %2271 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2282, ptr noundef align 1 %2264, i64 noundef %2283, i1 noundef false) #16
  br label %2284

2284:                                             ; preds = %2279, %2277, %2276
  %2285 = load ptr, ptr %0, align 8, !tbaa !98
  br label %2286

2286:                                             ; preds = %2296, %2284
  %2287 = phi ptr [ %2298, %2296 ], [ %2255, %2284 ]
  %2288 = getelementptr inbounds i8, ptr %2287, i64 4
  %2289 = load i32, ptr %2288, align 4, !tbaa !155
  %2290 = and i32 %2289, 3
  %2291 = icmp eq i32 %2290, 0
  br i1 %2291, label %2292, label %2296

2292:                                             ; preds = %2286
  %2293 = getelementptr inbounds i8, ptr %2287, i64 52
  %2294 = load i32, ptr %2293, align 4, !tbaa !30
  %2295 = icmp slt i32 %2294, 1
  br i1 %2295, label %2296, label %2300

2296:                                             ; preds = %2292, %2286
  %2297 = getelementptr inbounds i8, ptr %2287, i64 16
  %2298 = load ptr, ptr %2297, align 8, !tbaa !157
  %2299 = icmp eq ptr %2298, null
  br i1 %2299, label %2491, label %2286, !llvm.loop !158

2300:                                             ; preds = %2292
  %2301 = getelementptr inbounds i8, ptr %2285, i64 84
  store i32 %2294, ptr %2301, align 4, !tbaa !159
  br label %2491

2302:                                             ; preds = %2240
  br i1 %2243, label %2303, label %2308

2303:                                             ; preds = %2302
  %2304 = load ptr, ptr %98, align 8
  %2305 = zext nneg i32 %2242 to i64
  %2306 = getelementptr i8, ptr %2304, i64 %2305
  %2307 = add nuw nsw i32 %2242, 8
  store i32 %2307, ptr %2, align 8
  br label %2311

2308:                                             ; preds = %2302
  %2309 = load ptr, ptr %97, align 8
  %2310 = getelementptr i8, ptr %2309, i64 8
  store ptr %2310, ptr %97, align 8
  br label %2311

2311:                                             ; preds = %2308, %2303
  %2312 = phi ptr [ %2306, %2303 ], [ %2309, %2308 ]
  %2313 = load ptr, ptr %2312, align 8, !tbaa !36
  %2314 = icmp eq ptr %2313, null
  br i1 %2314, label %2491, label %2315

2315:                                             ; preds = %2311
  %2316 = getelementptr inbounds i8, ptr %2313, i64 8
  %2317 = load i32, ptr %2316, align 8, !tbaa !160
  %2318 = icmp eq i32 %2317, 0
  br i1 %2318, label %2491, label %2319

2319:                                             ; preds = %2315
  %2320 = load ptr, ptr %2313, align 8, !tbaa !161
  %2321 = load i32, ptr %99, align 8, !tbaa !75
  %2322 = add i32 %2321, %2317
  %2323 = load i32, ptr %100, align 8, !tbaa !76
  %2324 = icmp ult i32 %2322, %2323
  br i1 %2324, label %2326, label %2325

2325:                                             ; preds = %2319
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2320, i32 noundef %2317)
  br label %2331

2326:                                             ; preds = %2319
  store i32 %2322, ptr %99, align 8, !tbaa !75
  %2327 = load ptr, ptr %101, align 8, !tbaa !77
  %2328 = zext i32 %2321 to i64
  %2329 = getelementptr inbounds i8, ptr %2327, i64 %2328
  %2330 = sext i32 %2317 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2329, ptr noundef align 1 %2320, i64 noundef %2330, i1 noundef false) #16
  br label %2331

2331:                                             ; preds = %2326, %2325
  %2332 = load ptr, ptr %0, align 8, !tbaa !98
  %2333 = load ptr, ptr %2313, align 8, !tbaa !161
  %2334 = icmp eq ptr %2332, null
  br i1 %2334, label %2491, label %2335

2335:                                             ; preds = %2331
  %2336 = getelementptr inbounds i8, ptr %2332, i64 84
  %2337 = load i32, ptr %2336, align 4, !tbaa !159
  %2338 = icmp eq i32 %2337, -2
  br i1 %2338, label %2339, label %2491

2339:                                             ; preds = %2335
  %2340 = getelementptr inbounds i8, ptr %2332, i64 344
  %2341 = load ptr, ptr %2340, align 8, !tbaa !99
  %2342 = icmp eq ptr %2341, null
  br i1 %2342, label %2491, label %2343

2343:                                             ; preds = %2339
  %2344 = getelementptr inbounds i8, ptr %2341, i64 344
  %2345 = load ptr, ptr %2344, align 8, !tbaa !162
  %2346 = icmp eq ptr %2345, null
  br i1 %2346, label %2491, label %2347

2347:                                             ; preds = %2343
  %2348 = ptrtoint ptr %2333 to i64
  %2349 = ptrtoint ptr %2345 to i64
  %2350 = icmp ugt ptr %2345, %2333
  br i1 %2350, label %2491, label %2351

2351:                                             ; preds = %2347
  %2352 = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %2345) #16
  %2353 = getelementptr inbounds i8, ptr %2345, i64 %2352
  %2354 = icmp ugt ptr %2353, %2333
  br i1 %2354, label %2355, label %2491

2355:                                             ; preds = %2351
  %2356 = sub i64 %2348, %2349
  %2357 = trunc i64 %2356 to i32
  store i32 %2357, ptr %2336, align 4, !tbaa !159
  br label %2491

2358:                                             ; preds = %498
  %2359 = load i8, ptr %44, align 1, !tbaa !73
  %2360 = and i8 %2359, 1
  %2361 = icmp eq i8 %2360, 0
  br i1 %2361, label %2488, label %2362

2362:                                             ; preds = %2358
  %2363 = load i32, ptr %2, align 8
  %2364 = icmp ult i32 %2363, 41
  br i1 %2364, label %2365, label %2370

2365:                                             ; preds = %2362
  %2366 = load ptr, ptr %78, align 8
  %2367 = zext nneg i32 %2363 to i64
  %2368 = getelementptr i8, ptr %2366, i64 %2367
  %2369 = add nuw nsw i32 %2363, 8
  store i32 %2369, ptr %2, align 8
  br label %2373

2370:                                             ; preds = %2362
  %2371 = load ptr, ptr %77, align 8
  %2372 = getelementptr i8, ptr %2371, i64 8
  store ptr %2372, ptr %77, align 8
  br label %2373

2373:                                             ; preds = %2370, %2365
  %2374 = phi ptr [ %2368, %2365 ], [ %2371, %2370 ]
  %2375 = load ptr, ptr %2374, align 8, !tbaa !36
  %2376 = getelementptr inbounds i8, ptr %2375, i64 24
  %2377 = load ptr, ptr %2376, align 8, !tbaa !163
  %2378 = icmp eq ptr %2377, null
  %2379 = icmp ne i8 %471, 0
  %2380 = select i1 %2378, i1 true, i1 %2379
  br i1 %2380, label %2397, label %2381

2381:                                             ; preds = %2373
  %2382 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2377) #16
  %2383 = trunc i64 %2382 to i32
  %2384 = and i32 %2383, 1073741823
  %2385 = load i32, ptr %79, align 8, !tbaa !75
  %2386 = add i32 %2384, %2385
  %2387 = load i32, ptr %80, align 8, !tbaa !76
  %2388 = icmp ult i32 %2386, %2387
  br i1 %2388, label %2390, label %2389

2389:                                             ; preds = %2381
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2377, i32 noundef %2384)
  br label %2488

2390:                                             ; preds = %2381
  %2391 = icmp eq i32 %2384, 0
  br i1 %2391, label %2488, label %2392

2392:                                             ; preds = %2390
  store i32 %2386, ptr %79, align 8, !tbaa !75
  %2393 = load ptr, ptr %81, align 8, !tbaa !77
  %2394 = zext i32 %2385 to i64
  %2395 = getelementptr inbounds i8, ptr %2393, i64 %2394
  %2396 = and i64 %2382, 1073741823
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2395, ptr noundef align 1 %2377, i64 noundef %2396, i1 noundef false) #16
  br label %2488

2397:                                             ; preds = %2373
  %2398 = getelementptr inbounds i8, ptr %2375, i64 16
  %2399 = load ptr, ptr %2398, align 8, !tbaa !166
  %2400 = icmp eq ptr %2399, null
  br i1 %2400, label %2452, label %2401

2401:                                             ; preds = %2397
  %2402 = getelementptr inbounds i8, ptr %2375, i64 8
  %2403 = load ptr, ptr %2402, align 8, !tbaa !167
  %2404 = icmp eq ptr %2403, null
  br i1 %2404, label %2431, label %2405

2405:                                             ; preds = %2401
  %2406 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2403) #16
  %2407 = trunc i64 %2406 to i32
  %2408 = and i32 %2407, 1073741823
  %2409 = load i32, ptr %82, align 8, !tbaa !75
  %2410 = add i32 %2408, %2409
  %2411 = load i32, ptr %83, align 8, !tbaa !76
  %2412 = icmp ult i32 %2410, %2411
  br i1 %2412, label %2414, label %2413

2413:                                             ; preds = %2405
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull %2403, i32 noundef %2408)
  br label %2421

2414:                                             ; preds = %2405
  %2415 = icmp eq i32 %2408, 0
  br i1 %2415, label %2421, label %2416

2416:                                             ; preds = %2414
  store i32 %2410, ptr %82, align 8, !tbaa !75
  %2417 = load ptr, ptr %84, align 8, !tbaa !77
  %2418 = zext i32 %2409 to i64
  %2419 = getelementptr inbounds i8, ptr %2417, i64 %2418
  %2420 = and i64 %2406, 1073741823
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2419, ptr noundef nonnull align 1 %2403, i64 noundef %2420, i1 noundef false) #16
  br label %2421

2421:                                             ; preds = %2416, %2414, %2413
  %2422 = load i32, ptr %82, align 8, !tbaa !75
  %2423 = add i32 %2422, 1
  %2424 = load i32, ptr %83, align 8, !tbaa !76
  %2425 = icmp ult i32 %2423, %2424
  br i1 %2425, label %2427, label %2426

2426:                                             ; preds = %2421
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull @.str.7, i32 noundef 1)
  br label %2431

2427:                                             ; preds = %2421
  store i32 %2423, ptr %82, align 8, !tbaa !75
  %2428 = load ptr, ptr %85, align 8, !tbaa !77
  %2429 = zext i32 %2422 to i64
  %2430 = getelementptr inbounds i8, ptr %2428, i64 %2429
  store i8 46, ptr %2430, align 1
  br label %2431

2431:                                             ; preds = %2427, %2426, %2401
  %2432 = load ptr, ptr %2398, align 8, !tbaa !166
  %2433 = icmp eq ptr %2432, null
  br i1 %2433, label %2438, label %2434

2434:                                             ; preds = %2431
  %2435 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2432) #16
  %2436 = trunc i64 %2435 to i32
  %2437 = and i32 %2436, 1073741823
  br label %2438

2438:                                             ; preds = %2434, %2431
  %2439 = phi i32 [ %2437, %2434 ], [ 0, %2431 ]
  %2440 = load i32, ptr %86, align 8, !tbaa !75
  %2441 = add i32 %2440, %2439
  %2442 = load i32, ptr %87, align 8, !tbaa !76
  %2443 = icmp ult i32 %2441, %2442
  br i1 %2443, label %2445, label %2444

2444:                                             ; preds = %2438
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2432, i32 noundef %2439)
  br label %2488

2445:                                             ; preds = %2438
  %2446 = icmp eq i32 %2439, 0
  br i1 %2446, label %2488, label %2447

2447:                                             ; preds = %2445
  store i32 %2441, ptr %86, align 8, !tbaa !75
  %2448 = load ptr, ptr %88, align 8, !tbaa !77
  %2449 = zext i32 %2440 to i64
  %2450 = getelementptr inbounds i8, ptr %2448, i64 %2449
  %2451 = zext nneg i32 %2439 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2450, ptr noundef align 1 %2432, i64 noundef %2451, i1 noundef false) #16
  br label %2488

2452:                                             ; preds = %2397
  br i1 %2378, label %2469, label %2453

2453:                                             ; preds = %2452
  %2454 = call i64 @strlen(ptr noundef nonnull readonly dereferenceable(1) %2377) #16
  %2455 = trunc i64 %2454 to i32
  %2456 = and i32 %2455, 1073741823
  %2457 = load i32, ptr %89, align 8, !tbaa !75
  %2458 = add i32 %2456, %2457
  %2459 = load i32, ptr %90, align 8, !tbaa !76
  %2460 = icmp ult i32 %2458, %2459
  br i1 %2460, label %2462, label %2461

2461:                                             ; preds = %2453
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef nonnull %2377, i32 noundef %2456)
  br label %2488

2462:                                             ; preds = %2453
  %2463 = icmp eq i32 %2456, 0
  br i1 %2463, label %2488, label %2464

2464:                                             ; preds = %2462
  store i32 %2458, ptr %89, align 8, !tbaa !75
  %2465 = load ptr, ptr %91, align 8, !tbaa !77
  %2466 = zext i32 %2457 to i64
  %2467 = getelementptr inbounds i8, ptr %2465, i64 %2466
  %2468 = and i64 %2454, 1073741823
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2467, ptr noundef nonnull align 1 %2377, i64 noundef %2468, i1 noundef false) #16
  br label %2488

2469:                                             ; preds = %2452
  %2470 = getelementptr inbounds i8, ptr %2375, i64 40
  %2471 = load ptr, ptr %2470, align 8, !tbaa !168
  %2472 = getelementptr inbounds i8, ptr %2471, i64 4
  %2473 = load i32, ptr %2472, align 4, !tbaa !169
  %2474 = and i32 %2473, 2048
  %2475 = icmp eq i32 %2474, 0
  br i1 %2475, label %2479, label %2476

2476:                                             ; preds = %2469
  %2477 = getelementptr inbounds i8, ptr %2471, i64 16
  %2478 = load i32, ptr %2477, align 8, !tbaa !171
  call void (ptr, ptr, ...) @sqlite3_str_appendf(ptr noundef %0, ptr noundef nonnull @.str.8, i32 noundef %2478)
  br label %2488

2479:                                             ; preds = %2469
  %2480 = and i32 %2473, 1024
  %2481 = icmp eq i32 %2480, 0
  br i1 %2481, label %2485, label %2482

2482:                                             ; preds = %2479
  %2483 = getelementptr inbounds i8, ptr %2375, i64 88
  %2484 = load i32, ptr %2483, align 8, !tbaa !30
  call void (ptr, ptr, ...) @sqlite3_str_appendf(ptr noundef %0, ptr noundef nonnull @.str.9, i32 noundef %2484)
  br label %2488

2485:                                             ; preds = %2479
  %2486 = getelementptr inbounds i8, ptr %2471, i64 16
  %2487 = load i32, ptr %2486, align 8, !tbaa !171
  call void (ptr, ptr, ...) @sqlite3_str_appendf(ptr noundef %0, ptr noundef nonnull @.str.10, i32 noundef %2487)
  br label %2488

2488:                                             ; preds = %2485, %2482, %2476, %2464, %2462, %2461, %2447, %2445, %2444, %2392, %2390, %2389, %2358
  %2489 = phi i32 [ %475, %2358 ], [ 0, %2476 ], [ 0, %2485 ], [ 0, %2482 ], [ 0, %2389 ], [ 0, %2390 ], [ 0, %2392 ], [ 0, %2444 ], [ 0, %2445 ], [ 0, %2447 ], [ 0, %2461 ], [ 0, %2462 ], [ 0, %2464 ]
  %2490 = phi i32 [ %197, %2358 ], [ 0, %2476 ], [ 0, %2485 ], [ 0, %2482 ], [ 0, %2389 ], [ 0, %2390 ], [ 0, %2392 ], [ 0, %2444 ], [ 0, %2445 ], [ 0, %2447 ], [ 0, %2461 ], [ 0, %2462 ], [ 0, %2464 ]
  br i1 %2361, label %2628, label %2491

2491:                                             ; preds = %2488, %2355, %2351, %2347, %2343, %2339, %2335, %2331, %2315, %2311, %2300, %2296, %2257, %2253, %2059, %2046, %1990, %1710, %1707, %1694, %1689, %881
  %2492 = phi i32 [ %196, %2488 ], [ %196, %2046 ], [ %196, %1990 ], [ %196, %1710 ], [ %196, %1689 ], [ %738, %881 ], [ %196, %1707 ], [ %196, %1694 ], [ %196, %2311 ], [ %196, %2315 ], [ %196, %2253 ], [ %196, %2257 ], [ %196, %2300 ], [ %196, %2331 ], [ %196, %2335 ], [ %196, %2339 ], [ %196, %2343 ], [ %196, %2347 ], [ %196, %2351 ], [ %196, %2355 ], [ %196, %2059 ], [ %196, %2296 ]
  %2493 = phi ptr [ null, %2488 ], [ %2047, %2046 ], [ null, %1990 ], [ null, %1710 ], [ %1690, %1689 ], [ %739, %881 ], [ null, %1707 ], [ null, %1694 ], [ null, %2311 ], [ null, %2315 ], [ null, %2253 ], [ null, %2257 ], [ null, %2300 ], [ null, %2331 ], [ null, %2335 ], [ null, %2339 ], [ null, %2343 ], [ null, %2347 ], [ null, %2351 ], [ null, %2355 ], [ %2047, %2059 ], [ null, %2296 ]
  %2494 = phi i32 [ %2489, %2488 ], [ %2049, %2046 ], [ 0, %1990 ], [ %475, %1710 ], [ %475, %1689 ], [ %475, %881 ], [ 0, %1707 ], [ 0, %1694 ], [ 0, %2311 ], [ 0, %2315 ], [ 0, %2253 ], [ 0, %2257 ], [ 0, %2300 ], [ 0, %2331 ], [ 0, %2335 ], [ 0, %2339 ], [ 0, %2343 ], [ 0, %2347 ], [ 0, %2351 ], [ 0, %2355 ], [ %2068, %2059 ], [ 0, %2296 ]
  %2495 = phi i32 [ %2490, %2488 ], [ %2050, %2046 ], [ 0, %1990 ], [ 1, %1710 ], [ %1692, %1689 ], [ %885, %881 ], [ 0, %1707 ], [ 0, %1694 ], [ 0, %2311 ], [ 0, %2315 ], [ 0, %2253 ], [ 0, %2257 ], [ 0, %2300 ], [ 0, %2331 ], [ 0, %2335 ], [ 0, %2339 ], [ 0, %2343 ], [ 0, %2347 ], [ 0, %2351 ], [ 0, %2355 ], [ %2050, %2059 ], [ 0, %2296 ]
  %2496 = phi ptr [ %227, %2488 ], [ %2051, %2046 ], [ %1951, %1990 ], [ %42, %1710 ], [ %1693, %1689 ], [ %882, %881 ], [ %227, %1707 ], [ %227, %1694 ], [ %227, %2311 ], [ %227, %2315 ], [ %227, %2253 ], [ %227, %2257 ], [ %227, %2300 ], [ %227, %2331 ], [ %227, %2335 ], [ %227, %2339 ], [ %227, %2343 ], [ %227, %2347 ], [ %227, %2351 ], [ %227, %2355 ], [ %2051, %2059 ], [ %227, %2296 ]
  %2497 = sub nsw i32 %2494, %2495
  %2498 = icmp sgt i32 %2497, 0
  br i1 %2498, label %2499, label %2571

2499:                                             ; preds = %2491
  %2500 = icmp eq i8 %474, 0
  br i1 %2500, label %2501, label %2536

2501:                                             ; preds = %2499
  %2502 = load i32, ptr %191, align 8, !tbaa !75
  %2503 = zext i32 %2502 to i64
  %2504 = zext nneg i32 %2497 to i64
  %2505 = add nuw nsw i64 %2503, %2504
  %2506 = load i32, ptr %192, align 8, !tbaa !76
  %2507 = zext i32 %2506 to i64
  %2508 = icmp ult i64 %2505, %2507
  br i1 %2508, label %2512, label %2509

2509:                                             ; preds = %2501
  %2510 = call fastcc i32 @sqlite3StrAccumEnlarge(ptr noundef %0, i64 noundef %2504)
  %2511 = icmp slt i32 %2510, 1
  br i1 %2511, label %2523, label %2512

2512:                                             ; preds = %2509, %2501
  %2513 = phi i32 [ %2497, %2501 ], [ %2510, %2509 ]
  br label %2514

2514:                                             ; preds = %2514, %2512
  %2515 = phi i32 [ %2516, %2514 ], [ %2513, %2512 ]
  %2516 = add nsw i32 %2515, -1
  %2517 = load ptr, ptr %193, align 8, !tbaa !77
  %2518 = load i32, ptr %191, align 8, !tbaa !75
  %2519 = add i32 %2518, 1
  store i32 %2519, ptr %191, align 8, !tbaa !75
  %2520 = zext i32 %2518 to i64
  %2521 = getelementptr inbounds i8, ptr %2517, i64 %2520
  store i8 32, ptr %2521, align 1, !tbaa !30
  %2522 = icmp sgt i32 %2515, 1
  br i1 %2522, label %2514, label %2523, !llvm.loop !143

2523:                                             ; preds = %2514, %2509
  %2524 = load i32, ptr %191, align 8, !tbaa !75
  %2525 = add i32 %2524, %2495
  %2526 = load i32, ptr %192, align 8, !tbaa !76
  %2527 = icmp ult i32 %2525, %2526
  br i1 %2527, label %2529, label %2528

2528:                                             ; preds = %2523
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2496, i32 noundef %2495)
  br label %2584

2529:                                             ; preds = %2523
  %2530 = icmp eq i32 %2495, 0
  br i1 %2530, label %2584, label %2531

2531:                                             ; preds = %2529
  store i32 %2525, ptr %191, align 8, !tbaa !75
  %2532 = load ptr, ptr %194, align 8, !tbaa !77
  %2533 = zext i32 %2524 to i64
  %2534 = getelementptr inbounds i8, ptr %2532, i64 %2533
  %2535 = sext i32 %2495 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2534, ptr noundef align 1 %2496, i64 noundef %2535, i1 noundef false) #16
  br label %2584

2536:                                             ; preds = %2499
  %2537 = load i32, ptr %187, align 8, !tbaa !75
  %2538 = add i32 %2537, %2495
  %2539 = load i32, ptr %188, align 8, !tbaa !76
  %2540 = icmp ult i32 %2538, %2539
  br i1 %2540, label %2542, label %2541

2541:                                             ; preds = %2536
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2496, i32 noundef %2495)
  br label %2549

2542:                                             ; preds = %2536
  %2543 = icmp eq i32 %2495, 0
  br i1 %2543, label %2549, label %2544

2544:                                             ; preds = %2542
  store i32 %2538, ptr %187, align 8, !tbaa !75
  %2545 = load ptr, ptr %189, align 8, !tbaa !77
  %2546 = zext i32 %2537 to i64
  %2547 = getelementptr inbounds i8, ptr %2545, i64 %2546
  %2548 = sext i32 %2495 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2547, ptr noundef align 1 %2496, i64 noundef %2548, i1 noundef false) #16
  br label %2549

2549:                                             ; preds = %2544, %2542, %2541
  %2550 = load i32, ptr %187, align 8, !tbaa !75
  %2551 = zext i32 %2550 to i64
  %2552 = zext nneg i32 %2497 to i64
  %2553 = add nuw nsw i64 %2551, %2552
  %2554 = load i32, ptr %188, align 8, !tbaa !76
  %2555 = zext i32 %2554 to i64
  %2556 = icmp ult i64 %2553, %2555
  br i1 %2556, label %2560, label %2557

2557:                                             ; preds = %2549
  %2558 = call fastcc i32 @sqlite3StrAccumEnlarge(ptr noundef %0, i64 noundef %2552)
  %2559 = icmp slt i32 %2558, 1
  br i1 %2559, label %2584, label %2560

2560:                                             ; preds = %2557, %2549
  %2561 = phi i32 [ %2497, %2549 ], [ %2558, %2557 ]
  br label %2562

2562:                                             ; preds = %2562, %2560
  %2563 = phi i32 [ %2564, %2562 ], [ %2561, %2560 ]
  %2564 = add nsw i32 %2563, -1
  %2565 = load ptr, ptr %190, align 8, !tbaa !77
  %2566 = load i32, ptr %187, align 8, !tbaa !75
  %2567 = add i32 %2566, 1
  store i32 %2567, ptr %187, align 8, !tbaa !75
  %2568 = zext i32 %2566 to i64
  %2569 = getelementptr inbounds i8, ptr %2565, i64 %2568
  store i8 32, ptr %2569, align 1, !tbaa !30
  %2570 = icmp sgt i32 %2563, 1
  br i1 %2570, label %2562, label %2584, !llvm.loop !143

2571:                                             ; preds = %2491
  %2572 = load i32, ptr %184, align 8, !tbaa !75
  %2573 = add i32 %2572, %2495
  %2574 = load i32, ptr %185, align 8, !tbaa !76
  %2575 = icmp ult i32 %2573, %2574
  br i1 %2575, label %2577, label %2576

2576:                                             ; preds = %2571
  call fastcc void @enlargeAndAppend(ptr noundef %0, ptr noundef %2496, i32 noundef %2495)
  br label %2584

2577:                                             ; preds = %2571
  %2578 = icmp eq i32 %2495, 0
  br i1 %2578, label %2584, label %2579

2579:                                             ; preds = %2577
  store i32 %2573, ptr %184, align 8, !tbaa !75
  %2580 = load ptr, ptr %186, align 8, !tbaa !77
  %2581 = zext i32 %2572 to i64
  %2582 = getelementptr inbounds i8, ptr %2580, i64 %2581
  %2583 = sext i32 %2495 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %2582, ptr noundef align 1 %2496, i64 noundef %2583, i1 noundef false) #16
  br label %2584

2584:                                             ; preds = %2579, %2577, %2576, %2562, %2557, %2531, %2529, %2528
  %2585 = icmp eq ptr %2493, null
  br i1 %2585, label %2626, label %2586

2586:                                             ; preds = %2584
  %2587 = load ptr, ptr %0, align 8, !tbaa !98
  %2588 = icmp eq ptr %2587, null
  br i1 %2588, label %2612, label %2589

2589:                                             ; preds = %2586
  %2590 = getelementptr inbounds i8, ptr %2587, i64 488
  %2591 = load ptr, ptr %2590, align 8, !tbaa !172
  %2592 = icmp ugt ptr %2591, %2493
  br i1 %2592, label %2593, label %2607

2593:                                             ; preds = %2589
  %2594 = getelementptr inbounds i8, ptr %2587, i64 472
  %2595 = load ptr, ptr %2594, align 8, !tbaa !145
  %2596 = icmp ugt ptr %2595, %2493
  br i1 %2596, label %2600, label %2597

2597:                                             ; preds = %2593
  %2598 = getelementptr inbounds i8, ptr %2587, i64 464
  %2599 = load ptr, ptr %2598, align 8, !tbaa !173
  store ptr %2599, ptr %2493, align 8, !tbaa !174
  store ptr %2493, ptr %2598, align 8, !tbaa !173
  br label %2626

2600:                                             ; preds = %2593
  %2601 = getelementptr inbounds i8, ptr %2587, i64 480
  %2602 = load ptr, ptr %2601, align 8, !tbaa !146
  %2603 = icmp ugt ptr %2602, %2493
  br i1 %2603, label %2607, label %2604

2604:                                             ; preds = %2600
  %2605 = getelementptr inbounds i8, ptr %2587, i64 448
  %2606 = load ptr, ptr %2605, align 8, !tbaa !176
  store ptr %2606, ptr %2493, align 8, !tbaa !174
  store ptr %2493, ptr %2605, align 8, !tbaa !176
  br label %2626

2607:                                             ; preds = %2600, %2589
  %2608 = getelementptr inbounds i8, ptr %2587, i64 768
  %2609 = load ptr, ptr %2608, align 8, !tbaa !177
  %2610 = icmp eq ptr %2609, null
  br i1 %2610, label %2612, label %2611

2611:                                             ; preds = %2607
  call fastcc void @measureAllocationSize(ptr noundef nonnull %2587, ptr noundef nonnull %2493)
  br label %2626

2612:                                             ; preds = %2607, %2586
  %2613 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %2614 = icmp eq i32 %2613, 0
  br i1 %2614, label %2624, label %2615

2615:                                             ; preds = %2612
  %2616 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %2617 = call i32 %2616(ptr noundef nonnull %2493) #16
  %2618 = sext i32 %2617 to i64
  %2619 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %2620 = sub nsw i64 %2619, %2618
  store i64 %2620, ptr @sqlite3Stat, align 8, !tbaa !67
  %2621 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %2622 = add nsw i64 %2621, -1
  store i64 %2622, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %2623 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %2623(ptr noundef nonnull %2493) #16
  br label %2626

2624:                                             ; preds = %2612
  %2625 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %2625(ptr noundef nonnull %2493) #16
  br label %2626

2626:                                             ; preds = %2624, %2615, %2611, %2604, %2597, %2584
  %2627 = getelementptr inbounds i8, ptr %485, i64 1
  br label %195, !llvm.loop !178

2628:                                             ; preds = %2488, %2236, %2231, %1689, %731, %498, %240, %239, %223, %195
  call void @llvm.lifetime.end.p0(i64 70, ptr nonnull %42) #16
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @sqlite3StrAccumEnlarge(ptr nocapture noundef %0, i64 noundef %1) unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %0, i64 28
  %4 = load i8, ptr %3, align 4, !tbaa !96
  %5 = icmp eq i8 %4, 0
  br i1 %5, label %6, label %147

6:                                                ; preds = %2
  %7 = getelementptr inbounds i8, ptr %0, i64 20
  %8 = load i32, ptr %7, align 4, !tbaa !97
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %29

10:                                               ; preds = %6
  store i8 18, ptr %3, align 4, !tbaa !96
  %11 = load ptr, ptr %0, align 8, !tbaa !98
  %12 = icmp eq ptr %11, null
  br i1 %12, label %22, label %13

13:                                               ; preds = %10
  %14 = getelementptr inbounds i8, ptr %11, i64 344
  %15 = load ptr, ptr %14, align 8, !tbaa !99
  %16 = icmp eq ptr %15, null
  br i1 %16, label %22, label %17

17:                                               ; preds = %13
  %18 = getelementptr inbounds i8, ptr %15, i64 24
  store i32 18, ptr %18, align 8, !tbaa !105
  %19 = getelementptr inbounds i8, ptr %15, i64 48
  %20 = load i32, ptr %19, align 8, !tbaa !108
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %19, align 8, !tbaa !108
  br label %22

22:                                               ; preds = %17, %13, %10
  %23 = getelementptr inbounds i8, ptr %0, i64 16
  %24 = load i32, ptr %23, align 8, !tbaa !76
  %25 = getelementptr inbounds i8, ptr %0, i64 24
  %26 = load i32, ptr %25, align 8, !tbaa !75
  %27 = xor i32 %26, -1
  %28 = add i32 %24, %27
  br label %147

29:                                               ; preds = %6
  %30 = getelementptr inbounds i8, ptr %0, i64 29
  %31 = load i8, ptr %30, align 1, !tbaa !73
  %32 = and i8 %31, 4
  %33 = icmp eq i8 %32, 0
  br i1 %33, label %37, label %34

34:                                               ; preds = %29
  %35 = getelementptr inbounds i8, ptr %0, i64 8
  %36 = load ptr, ptr %35, align 8, !tbaa !77
  br label %37

37:                                               ; preds = %34, %29
  %38 = phi ptr [ %36, %34 ], [ null, %29 ]
  %39 = getelementptr inbounds i8, ptr %0, i64 24
  %40 = load i32, ptr %39, align 8, !tbaa !75
  %41 = zext i32 %40 to i64
  %42 = add i64 %1, 1
  %43 = add i64 %42, %41
  %44 = add nsw i64 %43, %41
  %45 = zext i32 %8 to i64
  %46 = icmp sgt i64 %44, %45
  %47 = select i1 %46, i64 %43, i64 %44
  %48 = icmp sgt i64 %47, %45
  br i1 %48, label %49, label %65

49:                                               ; preds = %37
  tail call void @sqlite3_str_reset(ptr noundef %0)
  store i8 18, ptr %3, align 4, !tbaa !96
  %50 = load i32, ptr %7, align 4, !tbaa !97
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %53, label %52

52:                                               ; preds = %49
  tail call void @sqlite3_str_reset(ptr noundef %0)
  br label %53

53:                                               ; preds = %52, %49
  %54 = load ptr, ptr %0, align 8, !tbaa !98
  %55 = icmp eq ptr %54, null
  br i1 %55, label %143, label %56

56:                                               ; preds = %53
  %57 = getelementptr inbounds i8, ptr %54, i64 344
  %58 = load ptr, ptr %57, align 8, !tbaa !99
  %59 = icmp eq ptr %58, null
  br i1 %59, label %143, label %60

60:                                               ; preds = %56
  %61 = getelementptr inbounds i8, ptr %58, i64 24
  store i32 18, ptr %61, align 8, !tbaa !105
  %62 = getelementptr inbounds i8, ptr %58, i64 48
  %63 = load i32, ptr %62, align 8, !tbaa !108
  %64 = add nsw i32 %63, 1
  store i32 %64, ptr %62, align 8, !tbaa !108
  br label %143

65:                                               ; preds = %37
  %66 = trunc i64 %47 to i32
  %67 = getelementptr inbounds i8, ptr %0, i64 16
  store i32 %66, ptr %67, align 8, !tbaa !76
  %68 = load ptr, ptr %0, align 8, !tbaa !98
  %69 = icmp eq ptr %68, null
  %70 = and i64 %47, 4294967295
  br i1 %69, label %96, label %71

71:                                               ; preds = %65
  %72 = icmp eq ptr %38, null
  br i1 %72, label %73, label %75

73:                                               ; preds = %71
  %74 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %68, i64 noundef %70)
  br label %98

75:                                               ; preds = %71
  %76 = getelementptr inbounds i8, ptr %68, i64 488
  %77 = load ptr, ptr %76, align 8, !tbaa !172
  %78 = icmp ugt ptr %77, %38
  br i1 %78, label %79, label %94

79:                                               ; preds = %75
  %80 = getelementptr inbounds i8, ptr %68, i64 472
  %81 = load ptr, ptr %80, align 8, !tbaa !145
  %82 = icmp ugt ptr %81, %38
  br i1 %82, label %85, label %83

83:                                               ; preds = %79
  %84 = icmp ult i64 %70, 129
  br i1 %84, label %98, label %94

85:                                               ; preds = %79
  %86 = getelementptr inbounds i8, ptr %68, i64 480
  %87 = load ptr, ptr %86, align 8, !tbaa !146
  %88 = icmp ugt ptr %87, %38
  br i1 %88, label %94, label %89

89:                                               ; preds = %85
  %90 = getelementptr inbounds i8, ptr %68, i64 414
  %91 = load i16, ptr %90, align 2, !tbaa !147
  %92 = zext i16 %91 to i64
  %93 = icmp ugt i64 %70, %92
  br i1 %93, label %94, label %98

94:                                               ; preds = %89, %85, %83, %75
  %95 = tail call fastcc ptr @dbReallocFinish(ptr noundef nonnull %68, ptr noundef nonnull %38, i64 noundef %70)
  br label %98

96:                                               ; preds = %65
  %97 = tail call fastcc ptr @sqlite3Realloc(ptr noundef %38, i64 noundef %70)
  br label %98

98:                                               ; preds = %96, %94, %89, %83, %73
  %99 = phi ptr [ %97, %96 ], [ %74, %73 ], [ %95, %94 ], [ %38, %83 ], [ %38, %89 ]
  %100 = icmp eq ptr %99, null
  br i1 %100, label %139, label %101

101:                                              ; preds = %98
  %102 = load i8, ptr %30, align 1, !tbaa !73
  %103 = and i8 %102, 4
  %104 = icmp eq i8 %103, 0
  br i1 %104, label %105, label %112

105:                                              ; preds = %101
  %106 = load i32, ptr %39, align 8, !tbaa !75
  %107 = icmp eq i32 %106, 0
  br i1 %107, label %112, label %108

108:                                              ; preds = %105
  %109 = getelementptr inbounds i8, ptr %0, i64 8
  %110 = load ptr, ptr %109, align 8, !tbaa !77
  %111 = zext i32 %106 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 %99, ptr noundef align 1 %110, i64 noundef %111, i1 noundef false) #16
  br label %112

112:                                              ; preds = %108, %105, %101
  %113 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr %99, ptr %113, align 8, !tbaa !77
  %114 = load ptr, ptr %0, align 8, !tbaa !98
  %115 = icmp eq ptr %114, null
  br i1 %115, label %132, label %116

116:                                              ; preds = %112
  %117 = getelementptr inbounds i8, ptr %114, i64 496
  %118 = load ptr, ptr %117, align 8, !tbaa !144
  %119 = icmp ugt ptr %118, %99
  br i1 %119, label %120, label %132

120:                                              ; preds = %116
  %121 = getelementptr inbounds i8, ptr %114, i64 472
  %122 = load ptr, ptr %121, align 8, !tbaa !145
  %123 = icmp ugt ptr %122, %99
  br i1 %123, label %124, label %135

124:                                              ; preds = %120
  %125 = getelementptr inbounds i8, ptr %114, i64 480
  %126 = load ptr, ptr %125, align 8, !tbaa !146
  %127 = icmp ugt ptr %126, %99
  br i1 %127, label %132, label %128

128:                                              ; preds = %124
  %129 = getelementptr inbounds i8, ptr %114, i64 414
  %130 = load i16, ptr %129, align 2, !tbaa !147
  %131 = zext i16 %130 to i32
  br label %135

132:                                              ; preds = %124, %116, %112
  %133 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %134 = tail call i32 %133(ptr noundef nonnull %99) #16
  br label %135

135:                                              ; preds = %132, %128, %120
  %136 = phi i32 [ %131, %128 ], [ %134, %132 ], [ 128, %120 ]
  store i32 %136, ptr %67, align 8, !tbaa !76
  %137 = load i8, ptr %30, align 1, !tbaa !73
  %138 = or i8 %137, 4
  store i8 %138, ptr %30, align 1, !tbaa !73
  br label %143

139:                                              ; preds = %98
  tail call void @sqlite3_str_reset(ptr noundef nonnull %0)
  store i8 7, ptr %3, align 4, !tbaa !96
  %140 = load i32, ptr %7, align 4, !tbaa !97
  %141 = icmp eq i32 %140, 0
  br i1 %141, label %143, label %142

142:                                              ; preds = %139
  tail call void @sqlite3_str_reset(ptr noundef nonnull %0)
  br label %143

143:                                              ; preds = %142, %139, %135, %60, %56, %53
  %144 = phi i1 [ true, %135 ], [ false, %53 ], [ false, %56 ], [ false, %60 ], [ false, %139 ], [ false, %142 ]
  %145 = trunc i64 %1 to i32
  %146 = select i1 %144, i32 %145, i32 0
  br label %147

147:                                              ; preds = %143, %22, %2
  %148 = phi i32 [ %28, %22 ], [ 0, %2 ], [ %146, %143 ]
  ret i32 %148
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_str_appendf(ptr noundef %0, ptr noundef %1, ...) local_unnamed_addr #1 {
  %3 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #16
  call void @llvm.va_start.p0(ptr nonnull %3)
  call void @sqlite3_str_vappendf(ptr noundef %0, ptr noundef %1, ptr noundef nonnull %3)
  call void @llvm.va_end.p0(ptr %3)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #16
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @enlargeAndAppend(ptr nocapture noundef %0, ptr nocapture noundef readonly %1, i32 noundef %2) unnamed_addr #4 {
  %4 = sext i32 %2 to i64
  %5 = tail call fastcc i32 @sqlite3StrAccumEnlarge(ptr noundef %0, i64 noundef %4)
  %6 = icmp sgt i32 %5, 0
  br i1 %6, label %7, label %17

7:                                                ; preds = %3
  %8 = getelementptr inbounds i8, ptr %0, i64 8
  %9 = load ptr, ptr %8, align 8, !tbaa !77
  %10 = getelementptr inbounds i8, ptr %0, i64 24
  %11 = load i32, ptr %10, align 8, !tbaa !75
  %12 = zext i32 %11 to i64
  %13 = getelementptr inbounds i8, ptr %9, i64 %12
  %14 = zext nneg i32 %5 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %13, ptr noundef align 1 %1, i64 noundef %14, i1 noundef false) #16
  %15 = load i32, ptr %10, align 8, !tbaa !75
  %16 = add i32 %15, %5
  store i32 %16, ptr %10, align 8, !tbaa !75
  br label %17

17:                                               ; preds = %7, %3
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_str_reset(ptr nocapture noundef %0) local_unnamed_addr #1 {
  %2 = getelementptr inbounds i8, ptr %0, i64 29
  %3 = load i8, ptr %2, align 1, !tbaa !73
  %4 = and i8 %3, 4
  %5 = icmp eq i8 %4, 0
  br i1 %5, label %53, label %6

6:                                                ; preds = %1
  %7 = load ptr, ptr %0, align 8, !tbaa !98
  %8 = getelementptr inbounds i8, ptr %0, i64 8
  %9 = load ptr, ptr %8, align 8, !tbaa !77
  %10 = icmp eq ptr %9, null
  br i1 %10, label %50, label %11

11:                                               ; preds = %6
  %12 = icmp eq ptr %7, null
  br i1 %12, label %36, label %13

13:                                               ; preds = %11
  %14 = getelementptr inbounds i8, ptr %7, i64 488
  %15 = load ptr, ptr %14, align 8, !tbaa !172
  %16 = icmp ugt ptr %15, %9
  br i1 %16, label %17, label %31

17:                                               ; preds = %13
  %18 = getelementptr inbounds i8, ptr %7, i64 472
  %19 = load ptr, ptr %18, align 8, !tbaa !145
  %20 = icmp ugt ptr %19, %9
  br i1 %20, label %24, label %21

21:                                               ; preds = %17
  %22 = getelementptr inbounds i8, ptr %7, i64 464
  %23 = load ptr, ptr %22, align 8, !tbaa !173
  store ptr %23, ptr %9, align 8, !tbaa !174
  store ptr %9, ptr %22, align 8, !tbaa !173
  br label %50

24:                                               ; preds = %17
  %25 = getelementptr inbounds i8, ptr %7, i64 480
  %26 = load ptr, ptr %25, align 8, !tbaa !146
  %27 = icmp ugt ptr %26, %9
  br i1 %27, label %31, label %28

28:                                               ; preds = %24
  %29 = getelementptr inbounds i8, ptr %7, i64 448
  %30 = load ptr, ptr %29, align 8, !tbaa !176
  store ptr %30, ptr %9, align 8, !tbaa !174
  store ptr %9, ptr %29, align 8, !tbaa !176
  br label %50

31:                                               ; preds = %24, %13
  %32 = getelementptr inbounds i8, ptr %7, i64 768
  %33 = load ptr, ptr %32, align 8, !tbaa !177
  %34 = icmp eq ptr %33, null
  br i1 %34, label %36, label %35

35:                                               ; preds = %31
  tail call fastcc void @measureAllocationSize(ptr noundef nonnull %7, ptr noundef nonnull %9)
  br label %50

36:                                               ; preds = %31, %11
  %37 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %38 = icmp eq i32 %37, 0
  br i1 %38, label %48, label %39

39:                                               ; preds = %36
  %40 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %41 = tail call i32 %40(ptr noundef nonnull %9) #16
  %42 = sext i32 %41 to i64
  %43 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %44 = sub nsw i64 %43, %42
  store i64 %44, ptr @sqlite3Stat, align 8, !tbaa !67
  %45 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %46 = add nsw i64 %45, -1
  store i64 %46, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %47 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %47(ptr noundef nonnull %9) #16
  br label %50

48:                                               ; preds = %36
  %49 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %49(ptr noundef nonnull %9) #16
  br label %50

50:                                               ; preds = %48, %39, %35, %28, %21, %6
  %51 = load i8, ptr %2, align 1, !tbaa !73
  %52 = and i8 %51, -5
  store i8 %52, ptr %2, align 1, !tbaa !73
  br label %53

53:                                               ; preds = %50, %1
  %54 = getelementptr inbounds i8, ptr %0, i64 16
  store i32 0, ptr %54, align 8, !tbaa !76
  %55 = getelementptr inbounds i8, ptr %0, i64 24
  store i32 0, ptr %55, align 8, !tbaa !75
  %56 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr null, ptr %56, align 8, !tbaa !77
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #5

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_log(i32 noundef %0, ptr noundef %1, ...) local_unnamed_addr #1 {
  %3 = alloca %struct.sqlite3_str, align 8
  %4 = alloca [210 x i8], align 16
  %5 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #16
  %6 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 376), align 8, !tbaa !179
  %7 = icmp eq ptr %6, null
  br i1 %7, label %34, label %8

8:                                                ; preds = %2
  call void @llvm.va_start.p0(ptr nonnull %5)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #16
  call void @llvm.lifetime.start.p0(i64 210, ptr nonnull %4) #16
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  store ptr %4, ptr %9, align 8, !tbaa !77
  store ptr null, ptr %3, align 8, !tbaa !98
  %10 = getelementptr inbounds i8, ptr %3, i64 16
  store i32 210, ptr %10, align 8, !tbaa !76
  %11 = getelementptr inbounds i8, ptr %3, i64 20
  %12 = getelementptr inbounds i8, ptr %3, i64 29
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(10) %11, i8 0, i64 10, i1 false)
  call void @sqlite3_str_vappendf(ptr noundef nonnull %3, ptr noundef %1, ptr noundef nonnull %5)
  %13 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 376), align 8, !tbaa !179
  %14 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 384), align 8, !tbaa !180
  %15 = load ptr, ptr %9, align 8, !tbaa !77
  %16 = icmp eq ptr %15, null
  br i1 %16, label %30, label %17

17:                                               ; preds = %8
  %18 = getelementptr inbounds i8, ptr %3, i64 24
  %19 = load i32, ptr %18, align 8, !tbaa !75
  %20 = zext i32 %19 to i64
  %21 = getelementptr inbounds i8, ptr %15, i64 %20
  store i8 0, ptr %21, align 1, !tbaa !30
  %22 = load i32, ptr %11, align 4, !tbaa !97
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %30, label %24

24:                                               ; preds = %17
  %25 = load i8, ptr %12, align 1, !tbaa !73
  %26 = and i8 %25, 4
  %27 = icmp eq i8 %26, 0
  br i1 %27, label %28, label %30

28:                                               ; preds = %24
  %29 = call fastcc ptr @strAccumFinishRealloc(ptr noundef nonnull %3)
  br label %32

30:                                               ; preds = %24, %17, %8
  %31 = load ptr, ptr %9, align 8, !tbaa !77
  br label %32

32:                                               ; preds = %30, %28
  %33 = phi ptr [ %31, %30 ], [ %29, %28 ]
  call void %13(ptr noundef %14, i32 noundef %0, ptr noundef %33) #16
  call void @llvm.lifetime.end.p0(i64 210, ptr nonnull %4) #16
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #16
  call void @llvm.va_end.p0(ptr %5)
  br label %34

34:                                               ; preds = %32, %2
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #16
  ret void
}

; Function Attrs: nounwind ssp uwtable
define void @sqlite3_randomness(i32 noundef %0, ptr noundef %1) local_unnamed_addr #1 {
  %3 = alloca [16 x i32], align 16
  %4 = tail call i32 @sqlite3_initialize()
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %224

6:                                                ; preds = %2
  %7 = icmp slt i32 %0, 1
  %8 = icmp eq ptr %1, null
  %9 = or i1 %7, %8
  br i1 %9, label %10, label %11

10:                                               ; preds = %6
  store i32 0, ptr @sqlite3Prng, align 4, !tbaa !86
  br label %224

11:                                               ; preds = %6
  %12 = load i32, ptr @sqlite3Prng, align 4, !tbaa !86
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %31

14:                                               ; preds = %11
  %15 = tail call i32 @sqlite3_initialize()
  %16 = icmp ne i32 %15, 0
  %17 = load ptr, ptr @vfsList, align 8
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(16) @sqlite3Prng, ptr noundef nonnull align 16 dereferenceable(16) @sqlite3_randomness.chacha20_init, i64 16, i1 false)
  %18 = icmp eq ptr %17, null
  %19 = select i1 %16, i1 true, i1 %18
  br i1 %19, label %20, label %21

20:                                               ; preds = %14
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(44) getelementptr inbounds (i8, ptr @sqlite3Prng, i64 16), i8 0, i64 44, i1 false)
  br label %29

21:                                               ; preds = %14
  %22 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 432), align 8
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %25, label %24

24:                                               ; preds = %21
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(44) getelementptr inbounds (i8, ptr @sqlite3Prng, i64 16), i8 noundef 0, i64 noundef 44, i1 noundef false) #16
  store i32 %22, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 16), align 4
  br label %29

25:                                               ; preds = %21
  %26 = getelementptr inbounds i8, ptr %17, i64 104
  %27 = load ptr, ptr %26, align 8, !tbaa !181
  %28 = tail call i32 %27(ptr noundef %17, i32 noundef 44, ptr noundef nonnull getelementptr inbounds (i8, ptr @sqlite3Prng, i64 16)) #16
  br label %29

29:                                               ; preds = %25, %24, %20
  %30 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 48), align 4, !tbaa !86
  store i32 %30, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 60), align 4, !tbaa !86
  store i32 0, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 48), align 4, !tbaa !86
  store i8 0, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  br label %31

31:                                               ; preds = %29, %11
  %32 = load i8, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  %33 = zext i8 %32 to i32
  %34 = icmp slt i32 %33, %0
  br i1 %34, label %35, label %51

35:                                               ; preds = %31
  %36 = getelementptr inbounds i8, ptr %3, i64 16
  %37 = getelementptr inbounds i8, ptr %3, i64 48
  %38 = getelementptr inbounds i8, ptr %3, i64 32
  %39 = getelementptr inbounds i8, ptr %3, i64 20
  %40 = getelementptr inbounds i8, ptr %3, i64 4
  %41 = getelementptr inbounds i8, ptr %3, i64 52
  %42 = getelementptr inbounds i8, ptr %3, i64 36
  %43 = getelementptr inbounds i8, ptr %3, i64 24
  %44 = getelementptr inbounds i8, ptr %3, i64 8
  %45 = getelementptr inbounds i8, ptr %3, i64 56
  %46 = getelementptr inbounds i8, ptr %3, i64 40
  %47 = getelementptr inbounds i8, ptr %3, i64 28
  %48 = getelementptr inbounds i8, ptr %3, i64 12
  %49 = getelementptr inbounds i8, ptr %3, i64 60
  %50 = getelementptr inbounds i8, ptr %3, i64 44
  br label %62

51:                                               ; preds = %222, %31
  %52 = phi ptr [ %1, %31 ], [ %75, %222 ]
  %53 = phi i32 [ %0, %31 ], [ %76, %222 ]
  %54 = phi i32 [ %33, %31 ], [ 64, %222 ]
  %55 = sub nsw i32 %54, %53
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds [64 x i8], ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 64), i64 0, i64 %56
  %58 = sext i32 %53 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %52, ptr noundef nonnull align 1 %57, i64 noundef %58, i1 noundef false) #16
  %59 = load i8, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  %60 = trunc i32 %53 to i8
  %61 = sub i8 %59, %60
  store i8 %61, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  br label %224

62:                                               ; preds = %222, %35
  %63 = phi i8 [ %32, %35 ], [ 64, %222 ]
  %64 = phi i32 [ %0, %35 ], [ %76, %222 ]
  %65 = phi ptr [ %1, %35 ], [ %75, %222 ]
  %66 = icmp eq i8 %63, 0
  br i1 %66, label %74, label %67

67:                                               ; preds = %62
  %68 = zext i8 %63 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %65, ptr noundef nonnull align 4 getelementptr inbounds (i8, ptr @sqlite3Prng, i64 64), i64 noundef %68, i1 noundef false) #16
  %69 = load i8, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  %70 = zext i8 %69 to i32
  %71 = sub nsw i32 %64, %70
  %72 = zext i8 %69 to i64
  %73 = getelementptr inbounds i8, ptr %65, i64 %72
  br label %74

74:                                               ; preds = %67, %62
  %75 = phi ptr [ %73, %67 ], [ %65, %62 ]
  %76 = phi i32 [ %71, %67 ], [ %64, %62 ]
  %77 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 48), align 4, !tbaa !86
  %78 = add i32 %77, 1
  store i32 %78, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 48), align 4, !tbaa !86
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %3) #16
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %3, ptr noundef nonnull align 4 dereferenceable(64) @sqlite3Prng, i64 64, i1 false)
  %79 = load i32, ptr %36, align 16, !tbaa !86
  %80 = load i32, ptr %3, align 16, !tbaa !86
  %81 = load i32, ptr %37, align 16, !tbaa !86
  %82 = load i32, ptr %38, align 16, !tbaa !86
  %83 = load i32, ptr %39, align 4, !tbaa !86
  %84 = load i32, ptr %40, align 4, !tbaa !86
  %85 = load i32, ptr %41, align 4, !tbaa !86
  %86 = load i32, ptr %42, align 4, !tbaa !86
  %87 = load i32, ptr %43, align 8, !tbaa !86
  %88 = load i32, ptr %44, align 8, !tbaa !86
  %89 = load i32, ptr %45, align 8, !tbaa !86
  %90 = load i32, ptr %46, align 8, !tbaa !86
  %91 = load i32, ptr %47, align 4, !tbaa !86
  %92 = load i32, ptr %48, align 4, !tbaa !86
  %93 = load i32, ptr %49, align 4, !tbaa !86
  %94 = load i32, ptr %50, align 4, !tbaa !86
  br label %96

95:                                               ; preds = %96
  store i32 %209, ptr %36, align 16, !tbaa !86
  store i32 %168, ptr %3, align 16, !tbaa !86
  store i32 %182, ptr %37, align 16, !tbaa !86
  store i32 %195, ptr %38, align 16, !tbaa !86
  store i32 %173, ptr %39, align 4, !tbaa !86
  store i32 %180, ptr %40, align 4, !tbaa !86
  store i32 %194, ptr %41, align 4, !tbaa !86
  store i32 %207, ptr %42, align 4, !tbaa !86
  store i32 %185, ptr %43, align 8, !tbaa !86
  store i32 %192, ptr %44, align 8, !tbaa !86
  store i32 %206, ptr %45, align 8, !tbaa !86
  store i32 %171, ptr %46, align 8, !tbaa !86
  store i32 %197, ptr %47, align 4, !tbaa !86
  store i32 %204, ptr %48, align 4, !tbaa !86
  store i32 %170, ptr %49, align 4, !tbaa !86
  store i32 %183, ptr %50, align 4, !tbaa !86
  br label %212

96:                                               ; preds = %96, %74
  %97 = phi i32 [ 0, %74 ], [ %210, %96 ]
  %98 = phi i32 [ %79, %74 ], [ %209, %96 ]
  %99 = phi i32 [ %80, %74 ], [ %168, %96 ]
  %100 = phi i32 [ %81, %74 ], [ %182, %96 ]
  %101 = phi i32 [ %82, %74 ], [ %195, %96 ]
  %102 = phi i32 [ %83, %74 ], [ %173, %96 ]
  %103 = phi i32 [ %84, %74 ], [ %180, %96 ]
  %104 = phi i32 [ %85, %74 ], [ %194, %96 ]
  %105 = phi i32 [ %86, %74 ], [ %207, %96 ]
  %106 = phi i32 [ %87, %74 ], [ %185, %96 ]
  %107 = phi i32 [ %88, %74 ], [ %192, %96 ]
  %108 = phi i32 [ %89, %74 ], [ %206, %96 ]
  %109 = phi i32 [ %90, %74 ], [ %171, %96 ]
  %110 = phi i32 [ %91, %74 ], [ %197, %96 ]
  %111 = phi i32 [ %92, %74 ], [ %204, %96 ]
  %112 = phi i32 [ %93, %74 ], [ %170, %96 ]
  %113 = phi i32 [ %94, %74 ], [ %183, %96 ]
  %114 = add i32 %99, %98
  %115 = xor i32 %100, %114
  %116 = tail call i32 @llvm.fshl.i32(i32 %115, i32 %115, i32 16)
  %117 = add i32 %116, %101
  %118 = xor i32 %117, %98
  %119 = tail call i32 @llvm.fshl.i32(i32 %118, i32 %118, i32 12)
  %120 = add i32 %119, %114
  %121 = xor i32 %120, %116
  %122 = tail call i32 @llvm.fshl.i32(i32 %121, i32 %121, i32 8)
  %123 = add i32 %122, %117
  %124 = xor i32 %123, %119
  %125 = tail call i32 @llvm.fshl.i32(i32 %124, i32 %124, i32 7)
  %126 = add i32 %103, %102
  %127 = xor i32 %104, %126
  %128 = tail call i32 @llvm.fshl.i32(i32 %127, i32 %127, i32 16)
  %129 = add i32 %128, %105
  %130 = xor i32 %129, %102
  %131 = tail call i32 @llvm.fshl.i32(i32 %130, i32 %130, i32 12)
  %132 = add i32 %131, %126
  %133 = xor i32 %132, %128
  %134 = tail call i32 @llvm.fshl.i32(i32 %133, i32 %133, i32 8)
  %135 = add i32 %134, %129
  %136 = xor i32 %135, %131
  %137 = tail call i32 @llvm.fshl.i32(i32 %136, i32 %136, i32 7)
  %138 = add i32 %107, %106
  %139 = xor i32 %108, %138
  %140 = tail call i32 @llvm.fshl.i32(i32 %139, i32 %139, i32 16)
  %141 = add i32 %140, %109
  %142 = xor i32 %141, %106
  %143 = tail call i32 @llvm.fshl.i32(i32 %142, i32 %142, i32 12)
  %144 = add i32 %143, %138
  %145 = xor i32 %144, %140
  %146 = tail call i32 @llvm.fshl.i32(i32 %145, i32 %145, i32 8)
  %147 = add i32 %146, %141
  %148 = xor i32 %147, %143
  %149 = tail call i32 @llvm.fshl.i32(i32 %148, i32 %148, i32 7)
  %150 = add i32 %111, %110
  %151 = xor i32 %112, %150
  %152 = tail call i32 @llvm.fshl.i32(i32 %151, i32 %151, i32 16)
  %153 = add i32 %152, %113
  %154 = xor i32 %153, %110
  %155 = tail call i32 @llvm.fshl.i32(i32 %154, i32 %154, i32 12)
  %156 = add i32 %155, %150
  %157 = xor i32 %156, %152
  %158 = tail call i32 @llvm.fshl.i32(i32 %157, i32 %157, i32 8)
  %159 = add i32 %158, %153
  %160 = xor i32 %159, %155
  %161 = tail call i32 @llvm.fshl.i32(i32 %160, i32 %160, i32 7)
  %162 = add i32 %137, %120
  %163 = xor i32 %158, %162
  %164 = tail call i32 @llvm.fshl.i32(i32 %163, i32 %163, i32 16)
  %165 = add i32 %164, %147
  %166 = xor i32 %165, %137
  %167 = tail call i32 @llvm.fshl.i32(i32 %166, i32 %166, i32 12)
  %168 = add i32 %167, %162
  %169 = xor i32 %168, %164
  %170 = tail call i32 @llvm.fshl.i32(i32 %169, i32 %169, i32 8)
  %171 = add i32 %170, %165
  %172 = xor i32 %171, %167
  %173 = tail call i32 @llvm.fshl.i32(i32 %172, i32 %172, i32 7)
  %174 = add i32 %149, %132
  %175 = xor i32 %174, %122
  %176 = tail call i32 @llvm.fshl.i32(i32 %175, i32 %175, i32 16)
  %177 = add i32 %176, %159
  %178 = xor i32 %177, %149
  %179 = tail call i32 @llvm.fshl.i32(i32 %178, i32 %178, i32 12)
  %180 = add i32 %179, %174
  %181 = xor i32 %180, %176
  %182 = tail call i32 @llvm.fshl.i32(i32 %181, i32 %181, i32 8)
  %183 = add i32 %182, %177
  %184 = xor i32 %183, %179
  %185 = tail call i32 @llvm.fshl.i32(i32 %184, i32 %184, i32 7)
  %186 = add i32 %161, %144
  %187 = xor i32 %186, %134
  %188 = tail call i32 @llvm.fshl.i32(i32 %187, i32 %187, i32 16)
  %189 = add i32 %188, %123
  %190 = xor i32 %189, %161
  %191 = tail call i32 @llvm.fshl.i32(i32 %190, i32 %190, i32 12)
  %192 = add i32 %191, %186
  %193 = xor i32 %192, %188
  %194 = tail call i32 @llvm.fshl.i32(i32 %193, i32 %193, i32 8)
  %195 = add i32 %194, %189
  %196 = xor i32 %195, %191
  %197 = tail call i32 @llvm.fshl.i32(i32 %196, i32 %196, i32 7)
  %198 = add i32 %156, %125
  %199 = xor i32 %198, %146
  %200 = tail call i32 @llvm.fshl.i32(i32 %199, i32 %199, i32 16)
  %201 = add i32 %200, %135
  %202 = xor i32 %201, %125
  %203 = tail call i32 @llvm.fshl.i32(i32 %202, i32 %202, i32 12)
  %204 = add i32 %203, %198
  %205 = xor i32 %204, %200
  %206 = tail call i32 @llvm.fshl.i32(i32 %205, i32 %205, i32 8)
  %207 = add i32 %206, %201
  %208 = xor i32 %207, %203
  %209 = tail call i32 @llvm.fshl.i32(i32 %208, i32 %208, i32 7)
  %210 = add nuw nsw i32 %97, 1
  %211 = icmp eq i32 %210, 10
  br i1 %211, label %95, label %96, !llvm.loop !184

212:                                              ; preds = %212, %95
  %213 = phi i64 [ 0, %95 ], [ %220, %212 ]
  %214 = getelementptr inbounds [16 x i32], ptr %3, i64 0, i64 %213
  %215 = load i32, ptr %214, align 4, !tbaa !86
  %216 = getelementptr inbounds i32, ptr @sqlite3Prng, i64 %213
  %217 = load i32, ptr %216, align 4, !tbaa !86
  %218 = add i32 %217, %215
  %219 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 64), i64 %213
  store i32 %218, ptr %219, align 4, !tbaa !86
  %220 = add nuw nsw i64 %213, 1
  %221 = icmp eq i64 %220, 16
  br i1 %221, label %222, label %212, !llvm.loop !185

222:                                              ; preds = %212
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %3) #16
  store i8 64, ptr getelementptr inbounds (i8, ptr @sqlite3Prng, i64 128), align 4, !tbaa !182
  %223 = icmp sgt i32 %76, 64
  br i1 %223, label %62, label %51, !llvm.loop !186

224:                                              ; preds = %51, %10, %2
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #6

; Function Attrs: nounwind ssp uwtable
define noundef i32 @sqlite3_os_init() local_unnamed_addr #1 {
  br label %1

1:                                                ; preds = %37, %0
  %2 = phi i64 [ 0, %0 ], [ %38, %37 ]
  %3 = getelementptr inbounds [9 x %struct.sqlite3_vfs], ptr @sqlite3_os_init.aVfs, i64 0, i64 %2
  %4 = icmp eq i64 %2, 0
  %5 = tail call i32 @sqlite3_initialize()
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %37

7:                                                ; preds = %1
  %8 = load ptr, ptr @vfsList, align 8, !tbaa !36
  %9 = icmp eq ptr %8, %3
  br i1 %9, label %22, label %10

10:                                               ; preds = %7
  %11 = icmp eq ptr %8, null
  br i1 %11, label %26, label %12

12:                                               ; preds = %12, %10
  %13 = phi ptr [ %15, %12 ], [ %8, %10 ]
  %14 = getelementptr inbounds i8, ptr %13, i64 16
  %15 = load ptr, ptr %14, align 8, !tbaa !63
  %16 = icmp eq ptr %15, null
  %17 = icmp eq ptr %15, %3
  %18 = or i1 %16, %17
  br i1 %18, label %19, label %12, !llvm.loop !64

19:                                               ; preds = %12
  br i1 %17, label %20, label %26

20:                                               ; preds = %19
  %21 = getelementptr inbounds i8, ptr %13, i64 16
  br label %22

22:                                               ; preds = %20, %7
  %23 = phi ptr [ %21, %20 ], [ @vfsList, %7 ]
  %24 = getelementptr inbounds i8, ptr %3, i64 16
  %25 = load ptr, ptr %24, align 8, !tbaa !63
  store ptr %25, ptr %23, align 8, !tbaa !36
  br label %26

26:                                               ; preds = %22, %19, %10
  %27 = load ptr, ptr @vfsList, align 8
  %28 = icmp eq ptr %27, null
  %29 = select i1 %4, i1 true, i1 %28
  br i1 %29, label %33, label %30

30:                                               ; preds = %26
  %31 = getelementptr inbounds i8, ptr %27, i64 16
  %32 = load ptr, ptr %31, align 8, !tbaa !63
  br label %33

33:                                               ; preds = %30, %26
  %34 = phi ptr [ %32, %30 ], [ %27, %26 ]
  %35 = phi ptr [ %31, %30 ], [ @vfsList, %26 ]
  %36 = getelementptr inbounds i8, ptr %3, i64 16
  store ptr %34, ptr %36, align 8, !tbaa !63
  store ptr %3, ptr %35, align 8, !tbaa !36
  br label %37

37:                                               ; preds = %33, %1
  %38 = add nuw nsw i64 %2, 1
  %39 = icmp eq i64 %38, 9
  br i1 %39, label %40, label %1, !llvm.loop !187

40:                                               ; preds = %37
  %41 = tail call ptr @getenv(ptr noundef nonnull @.str.121)
  store ptr %41, ptr @azTempDirs, align 16, !tbaa !36
  %42 = tail call ptr @getenv(ptr noundef nonnull @.str.122)
  store ptr %42, ptr getelementptr inbounds (i8, ptr @azTempDirs, i64 8), align 8, !tbaa !36
  ret i32 0
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @backupOnePage(ptr nocapture noundef readonly %0, i32 noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) unnamed_addr #1 {
  %5 = alloca ptr, align 8
  %6 = getelementptr inbounds i8, ptr %0, i64 8
  %7 = load ptr, ptr %6, align 8, !tbaa !188
  %8 = getelementptr inbounds i8, ptr %7, i64 8
  %9 = load ptr, ptr %8, align 8, !tbaa !190
  %10 = load ptr, ptr %9, align 8, !tbaa !193
  %11 = getelementptr inbounds i8, ptr %0, i64 40
  %12 = load ptr, ptr %11, align 8, !tbaa !195
  %13 = getelementptr inbounds i8, ptr %12, i64 8
  %14 = load ptr, ptr %13, align 8, !tbaa !190
  %15 = getelementptr inbounds i8, ptr %14, i64 52
  %16 = load i32, ptr %15, align 4, !tbaa !196
  %17 = zext i32 %1 to i64
  %18 = sext i32 %16 to i64
  %19 = mul nsw i64 %18, %17
  %20 = icmp sgt i32 %16, 0
  br i1 %20, label %21, label %155

21:                                               ; preds = %4
  %22 = sub nsw i64 %19, %18
  %23 = getelementptr inbounds i8, ptr %9, i64 52
  %24 = load i32, ptr %23, align 4, !tbaa !196
  %25 = tail call i32 @llvm.smin.i32(i32 %16, i32 %24)
  %26 = sext i32 %24 to i64
  %27 = getelementptr inbounds i8, ptr %10, i64 272
  %28 = sext i32 %25 to i64
  %29 = icmp eq i32 %3, 0
  br label %30

30:                                               ; preds = %149, %21
  %31 = phi i64 [ %22, %21 ], [ %151, %149 ]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #16
  store ptr null, ptr %5, align 8, !tbaa !36
  %32 = sdiv i64 %31, %26
  %33 = srem i64 %31, %26
  %34 = trunc i64 %32 to i32
  %35 = load i32, ptr @sqlite3PendingByte, align 4, !tbaa !86
  %36 = load ptr, ptr %6, align 8, !tbaa !188
  %37 = getelementptr inbounds i8, ptr %36, i64 8
  %38 = load ptr, ptr %37, align 8, !tbaa !190
  %39 = getelementptr inbounds i8, ptr %38, i64 52
  %40 = load i32, ptr %39, align 4, !tbaa !196
  %41 = udiv i32 %35, %40
  %42 = icmp eq i32 %41, %34
  br i1 %42, label %149, label %43

43:                                               ; preds = %30
  %44 = add i32 %34, 1
  %45 = load ptr, ptr %27, align 8, !tbaa !197
  %46 = call i32 %45(ptr noundef %10, i32 noundef %44, ptr noundef nonnull %5, i32 noundef 0) #16
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %48, label %115

48:                                               ; preds = %43
  %49 = load ptr, ptr %5, align 8, !tbaa !36
  %50 = getelementptr inbounds i8, ptr %49, i64 40
  %51 = load ptr, ptr %50, align 8, !tbaa !199
  %52 = getelementptr inbounds i8, ptr %49, i64 52
  %53 = load i16, ptr %52, align 4, !tbaa !201
  %54 = and i16 %53, 4
  %55 = icmp eq i16 %54, 0
  br i1 %55, label %68, label %56

56:                                               ; preds = %48
  %57 = getelementptr inbounds i8, ptr %51, i64 32
  %58 = load i32, ptr %57, align 8, !tbaa !202
  %59 = getelementptr inbounds i8, ptr %49, i64 48
  %60 = load i32, ptr %59, align 8, !tbaa !203
  %61 = icmp ult i32 %58, %60
  br i1 %61, label %68, label %62

62:                                               ; preds = %56
  %63 = getelementptr inbounds i8, ptr %51, i64 128
  %64 = load i32, ptr %63, align 8, !tbaa !204
  %65 = icmp eq i32 %64, 0
  br i1 %65, label %83, label %66

66:                                               ; preds = %62
  %67 = call fastcc i32 @subjournalPageIfRequired(ptr noundef %49)
  br label %83

68:                                               ; preds = %56, %48
  %69 = getelementptr inbounds i8, ptr %51, i64 48
  %70 = load i32, ptr %69, align 8, !tbaa !205
  %71 = icmp eq i32 %70, 0
  br i1 %71, label %72, label %83

72:                                               ; preds = %68
  %73 = getelementptr inbounds i8, ptr %51, i64 184
  %74 = load i32, ptr %73, align 8, !tbaa !206
  %75 = getelementptr inbounds i8, ptr %51, i64 200
  %76 = load i64, ptr %75, align 8, !tbaa !207
  %77 = trunc i64 %76 to i32
  %78 = icmp ugt i32 %74, %77
  br i1 %78, label %79, label %81

79:                                               ; preds = %72
  %80 = call fastcc i32 @pagerWriteLargeSector(ptr noundef %49)
  br label %83

81:                                               ; preds = %72
  %82 = call fastcc i32 @pager_write(ptr noundef %49)
  br label %83

83:                                               ; preds = %81, %79, %68, %66, %62
  %84 = phi i32 [ %67, %66 ], [ %80, %79 ], [ %82, %81 ], [ 0, %62 ], [ %70, %68 ]
  %85 = icmp eq i32 %84, 0
  br i1 %85, label %86, label %115

86:                                               ; preds = %83
  %87 = srem i64 %31, %18
  %88 = getelementptr inbounds i8, ptr %2, i64 %87
  %89 = load ptr, ptr %5, align 8, !tbaa !36
  %90 = getelementptr inbounds i8, ptr %89, i64 8
  %91 = load ptr, ptr %90, align 8, !tbaa !208
  %92 = getelementptr inbounds i8, ptr %91, i64 %33
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %92, ptr noundef align 1 %88, i64 noundef %28, i1 noundef false) #16
  %93 = load ptr, ptr %5, align 8, !tbaa !36
  %94 = getelementptr inbounds i8, ptr %93, i64 16
  %95 = load ptr, ptr %94, align 8, !tbaa !209
  store i8 0, ptr %95, align 1, !tbaa !30
  %96 = icmp eq i64 %31, 0
  %97 = and i1 %29, %96
  br i1 %97, label %98, label %115

98:                                               ; preds = %86
  %99 = getelementptr inbounds i8, ptr %92, i64 28
  %100 = load ptr, ptr %11, align 8, !tbaa !195
  %101 = getelementptr inbounds i8, ptr %100, i64 8
  %102 = load ptr, ptr %101, align 8, !tbaa !190
  %103 = getelementptr inbounds i8, ptr %102, i64 64
  %104 = load i32, ptr %103, align 8, !tbaa !210
  %105 = lshr i32 %104, 24
  %106 = trunc nuw i32 %105 to i8
  store i8 %106, ptr %99, align 1, !tbaa !30
  %107 = lshr i32 %104, 16
  %108 = trunc i32 %107 to i8
  %109 = getelementptr inbounds i8, ptr %92, i64 29
  store i8 %108, ptr %109, align 1, !tbaa !30
  %110 = lshr i32 %104, 8
  %111 = trunc i32 %110 to i8
  %112 = getelementptr inbounds i8, ptr %92, i64 30
  store i8 %111, ptr %112, align 1, !tbaa !30
  %113 = trunc i32 %104 to i8
  %114 = getelementptr inbounds i8, ptr %92, i64 31
  store i8 %113, ptr %114, align 1, !tbaa !30
  br label %115

115:                                              ; preds = %98, %86, %83, %43
  %116 = phi i32 [ %84, %83 ], [ %46, %43 ], [ 0, %98 ], [ 0, %86 ]
  %117 = load ptr, ptr %5, align 8, !tbaa !36
  %118 = icmp eq ptr %117, null
  br i1 %118, label %149, label %119

119:                                              ; preds = %115
  %120 = getelementptr inbounds i8, ptr %117, i64 52
  %121 = load i16, ptr %120, align 4, !tbaa !201
  %122 = and i16 %121, 32
  %123 = icmp eq i16 %122, 0
  br i1 %123, label %148, label %124

124:                                              ; preds = %119
  %125 = getelementptr inbounds i8, ptr %117, i64 40
  %126 = load ptr, ptr %125, align 8, !tbaa !199
  %127 = getelementptr inbounds i8, ptr %126, i64 152
  %128 = load i32, ptr %127, align 8, !tbaa !211
  %129 = add nsw i32 %128, -1
  store i32 %129, ptr %127, align 8, !tbaa !211
  %130 = getelementptr inbounds i8, ptr %126, i64 168
  %131 = load ptr, ptr %130, align 8, !tbaa !212
  %132 = getelementptr inbounds i8, ptr %117, i64 32
  store ptr %131, ptr %132, align 8, !tbaa !213
  store ptr %117, ptr %130, align 8, !tbaa !212
  %133 = getelementptr inbounds i8, ptr %126, i64 72
  %134 = load ptr, ptr %133, align 8, !tbaa !214
  %135 = getelementptr inbounds i8, ptr %117, i64 48
  %136 = load i32, ptr %135, align 8, !tbaa !203
  %137 = add i32 %136, -1
  %138 = zext i32 %137 to i64
  %139 = getelementptr inbounds i8, ptr %126, i64 200
  %140 = load i64, ptr %139, align 8, !tbaa !207
  %141 = mul nsw i64 %140, %138
  %142 = getelementptr inbounds i8, ptr %117, i64 8
  %143 = load ptr, ptr %142, align 8, !tbaa !208
  %144 = load ptr, ptr %134, align 8, !tbaa !215
  %145 = getelementptr inbounds i8, ptr %144, i64 144
  %146 = load ptr, ptr %145, align 8, !tbaa !217
  %147 = call i32 %146(ptr noundef nonnull %134, i64 noundef %141, ptr noundef %143) #16
  br label %149

148:                                              ; preds = %119
  call fastcc void @sqlite3PcacheRelease(ptr noundef nonnull %117)
  br label %149

149:                                              ; preds = %148, %124, %115, %30
  %150 = phi i32 [ 0, %30 ], [ %116, %115 ], [ %116, %124 ], [ %116, %148 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #16
  %151 = add nsw i64 %31, %26
  %152 = icmp eq i32 %150, 0
  %153 = icmp slt i64 %151, %19
  %154 = select i1 %152, i1 %153, i1 false
  br i1 %154, label %30, label %155, !llvm.loop !219

155:                                              ; preds = %149, %4
  %156 = phi i32 [ 0, %4 ], [ %150, %149 ]
  ret i32 %156
}

; Function Attrs: nounwind ssp uwtable
define hidden void @sqlite3ErrorMsg(ptr nocapture noundef %0, ptr noundef %1, ...) unnamed_addr #1 {
  %3 = alloca [70 x i8], align 16
  %4 = alloca %struct.sqlite3_str, align 8
  %5 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #16
  %6 = load ptr, ptr %0, align 8, !tbaa !220
  %7 = getelementptr inbounds i8, ptr %6, i64 84
  store i32 -2, ptr %7, align 4, !tbaa !159
  call void @llvm.va_start.p0(ptr nonnull %5)
  call void @llvm.lifetime.start.p0(i64 70, ptr nonnull %3) #16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #16
  %8 = getelementptr inbounds i8, ptr %6, i64 136
  %9 = load i32, ptr %8, align 8, !tbaa !86
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr %3, ptr %10, align 8, !tbaa !77
  store ptr %6, ptr %4, align 8, !tbaa !98
  %11 = getelementptr inbounds i8, ptr %4, i64 16
  store i32 70, ptr %11, align 8, !tbaa !76
  %12 = getelementptr inbounds i8, ptr %4, i64 20
  store i32 %9, ptr %12, align 4, !tbaa !97
  %13 = getelementptr inbounds i8, ptr %4, i64 24
  store i32 0, ptr %13, align 8, !tbaa !75
  %14 = getelementptr inbounds i8, ptr %4, i64 28
  store i8 0, ptr %14, align 4, !tbaa !96
  %15 = getelementptr inbounds i8, ptr %4, i64 29
  store i8 1, ptr %15, align 1, !tbaa !73
  call void @sqlite3_str_vappendf(ptr noundef nonnull %4, ptr noundef %1, ptr noundef nonnull %5)
  %16 = load ptr, ptr %10, align 8, !tbaa !77
  %17 = icmp eq ptr %16, null
  br i1 %17, label %30, label %18

18:                                               ; preds = %2
  %19 = load i32, ptr %13, align 8, !tbaa !75
  %20 = zext i32 %19 to i64
  %21 = getelementptr inbounds i8, ptr %16, i64 %20
  store i8 0, ptr %21, align 1, !tbaa !30
  %22 = load i32, ptr %12, align 4, !tbaa !97
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %30, label %24

24:                                               ; preds = %18
  %25 = load i8, ptr %15, align 1, !tbaa !73
  %26 = and i8 %25, 4
  %27 = icmp eq i8 %26, 0
  br i1 %27, label %28, label %30

28:                                               ; preds = %24
  %29 = call fastcc ptr @strAccumFinishRealloc(ptr noundef nonnull %4)
  br label %32

30:                                               ; preds = %24, %18, %2
  %31 = load ptr, ptr %10, align 8, !tbaa !77
  br label %32

32:                                               ; preds = %30, %28
  %33 = phi ptr [ %31, %30 ], [ %29, %28 ]
  %34 = load i8, ptr %14, align 4, !tbaa !96
  %35 = icmp eq i8 %34, 7
  br i1 %35, label %36, label %73

36:                                               ; preds = %32
  %37 = getelementptr inbounds i8, ptr %6, i64 103
  %38 = load i8, ptr %37, align 1, !tbaa !221
  %39 = icmp eq i8 %38, 0
  br i1 %39, label %40, label %73

40:                                               ; preds = %36
  %41 = getelementptr inbounds i8, ptr %6, i64 104
  %42 = load i8, ptr %41, align 8, !tbaa !222
  %43 = icmp eq i8 %42, 0
  br i1 %43, label %44, label %73

44:                                               ; preds = %40
  store i8 1, ptr %37, align 1, !tbaa !221
  %45 = getelementptr inbounds i8, ptr %6, i64 220
  %46 = load i32, ptr %45, align 4, !tbaa !223
  %47 = icmp sgt i32 %46, 0
  br i1 %47, label %48, label %50

48:                                               ; preds = %44
  %49 = getelementptr inbounds i8, ptr %6, i64 400
  store atomic volatile i32 1, ptr %49 monotonic, align 8
  br label %50

50:                                               ; preds = %48, %44
  %51 = getelementptr inbounds i8, ptr %6, i64 408
  %52 = load i32, ptr %51, align 8, !tbaa !224
  %53 = add i32 %52, 1
  store i32 %53, ptr %51, align 8, !tbaa !224
  %54 = getelementptr inbounds i8, ptr %6, i64 412
  store i16 0, ptr %54, align 4, !tbaa !225
  %55 = getelementptr inbounds i8, ptr %6, i64 344
  %56 = load ptr, ptr %55, align 8, !tbaa !99
  %57 = icmp eq ptr %56, null
  br i1 %57, label %73, label %58

58:                                               ; preds = %50
  call void (ptr, ptr, ...) @sqlite3ErrorMsg(ptr noundef nonnull %56, ptr noundef nonnull @.str.146)
  %59 = load ptr, ptr %55, align 8, !tbaa !99
  %60 = getelementptr inbounds i8, ptr %59, i64 24
  store i32 7, ptr %60, align 8, !tbaa !105
  %61 = getelementptr inbounds i8, ptr %59, i64 264
  %62 = load ptr, ptr %61, align 8, !tbaa !226
  %63 = icmp eq ptr %62, null
  br i1 %63, label %73, label %64

64:                                               ; preds = %64, %58
  %65 = phi ptr [ %71, %64 ], [ %62, %58 ]
  %66 = getelementptr inbounds i8, ptr %65, i64 48
  %67 = load i32, ptr %66, align 8, !tbaa !108
  %68 = add nsw i32 %67, 1
  store i32 %68, ptr %66, align 8, !tbaa !108
  %69 = getelementptr inbounds i8, ptr %65, i64 24
  store i32 7, ptr %69, align 8, !tbaa !105
  %70 = getelementptr inbounds i8, ptr %65, i64 264
  %71 = load ptr, ptr %70, align 8, !tbaa !226
  %72 = icmp eq ptr %71, null
  br i1 %72, label %73, label %64, !llvm.loop !227

73:                                               ; preds = %64, %58, %50, %40, %36, %32
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #16
  call void @llvm.lifetime.end.p0(i64 70, ptr nonnull %3) #16
  call void @llvm.va_end.p0(ptr %5)
  %74 = load i32, ptr %7, align 4, !tbaa !159
  %75 = icmp slt i32 %74, -1
  br i1 %75, label %76, label %77

76:                                               ; preds = %73
  store i32 -1, ptr %7, align 4, !tbaa !159
  br label %77

77:                                               ; preds = %76, %73
  %78 = getelementptr inbounds i8, ptr %6, i64 107
  %79 = load i8, ptr %78, align 1, !tbaa !228
  %80 = icmp eq i8 %79, 0
  br i1 %80, label %131, label %81

81:                                               ; preds = %77
  %82 = icmp eq ptr %33, null
  br i1 %82, label %122, label %83

83:                                               ; preds = %81
  %84 = icmp eq ptr %6, null
  br i1 %84, label %108, label %85

85:                                               ; preds = %83
  %86 = getelementptr inbounds i8, ptr %6, i64 488
  %87 = load ptr, ptr %86, align 8, !tbaa !172
  %88 = icmp ugt ptr %87, %33
  br i1 %88, label %89, label %103

89:                                               ; preds = %85
  %90 = getelementptr inbounds i8, ptr %6, i64 472
  %91 = load ptr, ptr %90, align 8, !tbaa !145
  %92 = icmp ugt ptr %91, %33
  br i1 %92, label %96, label %93

93:                                               ; preds = %89
  %94 = getelementptr inbounds i8, ptr %6, i64 464
  %95 = load ptr, ptr %94, align 8, !tbaa !173
  store ptr %95, ptr %33, align 8, !tbaa !174
  store ptr %33, ptr %94, align 8, !tbaa !173
  br label %122

96:                                               ; preds = %89
  %97 = getelementptr inbounds i8, ptr %6, i64 480
  %98 = load ptr, ptr %97, align 8, !tbaa !146
  %99 = icmp ugt ptr %98, %33
  br i1 %99, label %103, label %100

100:                                              ; preds = %96
  %101 = getelementptr inbounds i8, ptr %6, i64 448
  %102 = load ptr, ptr %101, align 8, !tbaa !176
  store ptr %102, ptr %33, align 8, !tbaa !174
  store ptr %33, ptr %101, align 8, !tbaa !176
  br label %122

103:                                              ; preds = %96, %85
  %104 = getelementptr inbounds i8, ptr %6, i64 768
  %105 = load ptr, ptr %104, align 8, !tbaa !177
  %106 = icmp eq ptr %105, null
  br i1 %106, label %108, label %107

107:                                              ; preds = %103
  call fastcc void @measureAllocationSize(ptr noundef nonnull %6, ptr noundef nonnull %33)
  br label %122

108:                                              ; preds = %103, %83
  %109 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %110 = icmp eq i32 %109, 0
  br i1 %110, label %120, label %111

111:                                              ; preds = %108
  %112 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %113 = call i32 %112(ptr noundef nonnull %33) #16
  %114 = sext i32 %113 to i64
  %115 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %116 = sub nsw i64 %115, %114
  store i64 %116, ptr @sqlite3Stat, align 8, !tbaa !67
  %117 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %118 = add nsw i64 %117, -1
  store i64 %118, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %119 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %119(ptr noundef nonnull %33) #16
  br label %122

120:                                              ; preds = %108
  %121 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %121(ptr noundef nonnull %33) #16
  br label %122

122:                                              ; preds = %120, %111, %107, %100, %93, %81
  %123 = getelementptr inbounds i8, ptr %6, i64 103
  %124 = load i8, ptr %123, align 1, !tbaa !221
  %125 = icmp eq i8 %124, 0
  br i1 %125, label %180, label %126

126:                                              ; preds = %122
  %127 = getelementptr inbounds i8, ptr %0, i64 48
  %128 = load i32, ptr %127, align 8, !tbaa !108
  %129 = add nsw i32 %128, 1
  store i32 %129, ptr %127, align 8, !tbaa !108
  %130 = getelementptr inbounds i8, ptr %0, i64 24
  store i32 7, ptr %130, align 8, !tbaa !105
  br label %180

131:                                              ; preds = %77
  %132 = getelementptr inbounds i8, ptr %0, i64 48
  %133 = load i32, ptr %132, align 8, !tbaa !108
  %134 = add nsw i32 %133, 1
  store i32 %134, ptr %132, align 8, !tbaa !108
  %135 = getelementptr inbounds i8, ptr %0, i64 8
  %136 = load ptr, ptr %135, align 8, !tbaa !229
  %137 = icmp eq ptr %136, null
  br i1 %137, label %177, label %138

138:                                              ; preds = %131
  %139 = icmp eq ptr %6, null
  br i1 %139, label %163, label %140

140:                                              ; preds = %138
  %141 = getelementptr inbounds i8, ptr %6, i64 488
  %142 = load ptr, ptr %141, align 8, !tbaa !172
  %143 = icmp ugt ptr %142, %136
  br i1 %143, label %144, label %158

144:                                              ; preds = %140
  %145 = getelementptr inbounds i8, ptr %6, i64 472
  %146 = load ptr, ptr %145, align 8, !tbaa !145
  %147 = icmp ugt ptr %146, %136
  br i1 %147, label %151, label %148

148:                                              ; preds = %144
  %149 = getelementptr inbounds i8, ptr %6, i64 464
  %150 = load ptr, ptr %149, align 8, !tbaa !173
  store ptr %150, ptr %136, align 8, !tbaa !174
  store ptr %136, ptr %149, align 8, !tbaa !173
  br label %177

151:                                              ; preds = %144
  %152 = getelementptr inbounds i8, ptr %6, i64 480
  %153 = load ptr, ptr %152, align 8, !tbaa !146
  %154 = icmp ugt ptr %153, %136
  br i1 %154, label %158, label %155

155:                                              ; preds = %151
  %156 = getelementptr inbounds i8, ptr %6, i64 448
  %157 = load ptr, ptr %156, align 8, !tbaa !176
  store ptr %157, ptr %136, align 8, !tbaa !174
  store ptr %136, ptr %156, align 8, !tbaa !176
  br label %177

158:                                              ; preds = %151, %140
  %159 = getelementptr inbounds i8, ptr %6, i64 768
  %160 = load ptr, ptr %159, align 8, !tbaa !177
  %161 = icmp eq ptr %160, null
  br i1 %161, label %163, label %162

162:                                              ; preds = %158
  call fastcc void @measureAllocationSize(ptr noundef nonnull %6, ptr noundef nonnull %136)
  br label %177

163:                                              ; preds = %158, %138
  %164 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %165 = icmp eq i32 %164, 0
  br i1 %165, label %175, label %166

166:                                              ; preds = %163
  %167 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %168 = call i32 %167(ptr noundef nonnull %136) #16
  %169 = sext i32 %168 to i64
  %170 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %171 = sub nsw i64 %170, %169
  store i64 %171, ptr @sqlite3Stat, align 8, !tbaa !67
  %172 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %173 = add nsw i64 %172, -1
  store i64 %173, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %174 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %174(ptr noundef nonnull %136) #16
  br label %177

175:                                              ; preds = %163
  %176 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %176(ptr noundef nonnull %136) #16
  br label %177

177:                                              ; preds = %175, %166, %162, %155, %148, %131
  store ptr %33, ptr %135, align 8, !tbaa !229
  %178 = getelementptr inbounds i8, ptr %0, i64 24
  store i32 1, ptr %178, align 8, !tbaa !105
  %179 = getelementptr inbounds i8, ptr %0, i64 408
  store ptr null, ptr %179, align 8, !tbaa !230
  br label %180

180:                                              ; preds = %177, %126, %122
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #16
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define hidden fastcc range(i32 0, 2) i32 @hasHighPrecisionDouble(i32 noundef %0) unnamed_addr #7 {
  %2 = add nsw i32 %0, 1
  %3 = sitofp i32 %2 to double
  %4 = tail call double @llvm.fmuladd.f64(double %3, double 1.000000e-01, double 1.000000e+00)
  %5 = fpext double %4 to x86_fp80
  %6 = tail call double @llvm.fmuladd.f64(double %3, double 2.500000e+01, double 1.000000e+18)
  %7 = fpext double %6 to x86_fp80
  %8 = fadd x86_fp80 %5, %7
  %9 = fcmp une x86_fp80 %8, %7
  %10 = zext i1 %9 to i32
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @sqlite3_config(i32 noundef %0, ...) local_unnamed_addr #1 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #16
  %3 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 340), align 4, !tbaa !6
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %13, label %5

5:                                                ; preds = %1
  %6 = icmp ugt i32 %0, 63
  br i1 %6, label %12, label %7

7:                                                ; preds = %5
  %8 = zext nneg i32 %0 to i64
  %9 = shl nuw i64 1, %8
  %10 = and i64 %9, 16842752
  %11 = icmp eq i64 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %7, %5
  tail call void (i32, ptr, ...) @sqlite3_log(i32 noundef 21, ptr noundef nonnull @.str.81, ptr noundef nonnull @.str.1323, i32 noundef 180223, ptr noundef nonnull getelementptr inbounds (i8, ptr @.str.45, i64 20))
  br label %384

13:                                               ; preds = %7, %1
  call void @llvm.va_start.p0(ptr nonnull %2)
  switch i32 %0, label %381 [
    i32 4, label %14
    i32 5, label %30
    i32 9, label %51
    i32 27, label %67
    i32 7, label %84
    i32 24, label %130
    i32 14, label %382
    i32 15, label %146
    i32 18, label %147
    i32 19, label %163
    i32 13, label %184
    i32 16, label %215
    i32 17, label %248
    i32 20, label %265
    i32 22, label %282
    i32 25, label %317
    i32 26, label %333
    i32 29, label %349
    i32 30, label %365
  ]

14:                                               ; preds = %13
  %15 = load i32, ptr %2, align 16
  %16 = icmp ult i32 %15, 41
  br i1 %16, label %17, label %23

17:                                               ; preds = %14
  %18 = getelementptr inbounds i8, ptr %2, i64 16
  %19 = load ptr, ptr %18, align 16
  %20 = zext nneg i32 %15 to i64
  %21 = getelementptr i8, ptr %19, i64 %20
  %22 = add nuw nsw i32 %15, 8
  store i32 %22, ptr %2, align 16
  br label %27

23:                                               ; preds = %14
  %24 = getelementptr inbounds i8, ptr %2, i64 8
  %25 = load ptr, ptr %24, align 8
  %26 = getelementptr i8, ptr %25, i64 8
  store ptr %26, ptr %24, align 8
  br label %27

27:                                               ; preds = %23, %17
  %28 = phi ptr [ %21, %17 ], [ %25, %23 ]
  %29 = load ptr, ptr %28, align 8, !tbaa !36
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(64) getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), ptr noundef nonnull align 8 dereferenceable(64) %29, i64 64, i1 false), !tbaa.struct !231
  br label %382

30:                                               ; preds = %13
  %31 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), align 8, !tbaa !18
  %32 = icmp eq ptr %31, null
  br i1 %32, label %33, label %35

33:                                               ; preds = %30
  %34 = call i32 (i32, ...) @sqlite3_config(i32 noundef 4, ptr noundef nonnull @sqlite3MemSetDefault.defaultMethods)
  br label %35

35:                                               ; preds = %33, %30
  %36 = load i32, ptr %2, align 16
  %37 = icmp ult i32 %36, 41
  br i1 %37, label %38, label %44

38:                                               ; preds = %35
  %39 = getelementptr inbounds i8, ptr %2, i64 16
  %40 = load ptr, ptr %39, align 16
  %41 = zext nneg i32 %36 to i64
  %42 = getelementptr i8, ptr %40, i64 %41
  %43 = add nuw nsw i32 %36, 8
  store i32 %43, ptr %2, align 16
  br label %48

44:                                               ; preds = %35
  %45 = getelementptr inbounds i8, ptr %2, i64 8
  %46 = load ptr, ptr %45, align 8
  %47 = getelementptr i8, ptr %46, i64 8
  store ptr %47, ptr %45, align 8
  br label %48

48:                                               ; preds = %44, %38
  %49 = phi ptr [ %42, %38 ], [ %46, %44 ]
  %50 = load ptr, ptr %49, align 8, !tbaa !36
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(64) %50, ptr noundef nonnull align 8 dereferenceable(64) getelementptr inbounds (i8, ptr @sqlite3Config, i64 32), i64 64, i1 false), !tbaa.struct !231
  br label %382

51:                                               ; preds = %13
  %52 = load i32, ptr %2, align 16
  %53 = icmp ult i32 %52, 41
  br i1 %53, label %54, label %60

54:                                               ; preds = %51
  %55 = getelementptr inbounds i8, ptr %2, i64 16
  %56 = load ptr, ptr %55, align 16
  %57 = zext nneg i32 %52 to i64
  %58 = getelementptr i8, ptr %56, i64 %57
  %59 = add nuw nsw i32 %52, 8
  store i32 %59, ptr %2, align 16
  br label %64

60:                                               ; preds = %51
  %61 = getelementptr inbounds i8, ptr %2, i64 8
  %62 = load ptr, ptr %61, align 8
  %63 = getelementptr i8, ptr %62, i64 8
  store ptr %63, ptr %61, align 8
  br label %64

64:                                               ; preds = %60, %54
  %65 = phi ptr [ %58, %54 ], [ %62, %60 ]
  %66 = load i32, ptr %65, align 4, !tbaa !86
  store i32 %66, ptr @sqlite3Config, align 8, !tbaa !65
  br label %382

67:                                               ; preds = %13
  %68 = load i32, ptr %2, align 16
  %69 = icmp ult i32 %68, 41
  br i1 %69, label %70, label %76

70:                                               ; preds = %67
  %71 = getelementptr inbounds i8, ptr %2, i64 16
  %72 = load ptr, ptr %71, align 16
  %73 = zext nneg i32 %68 to i64
  %74 = getelementptr i8, ptr %72, i64 %73
  %75 = add nuw nsw i32 %68, 8
  store i32 %75, ptr %2, align 16
  br label %80

76:                                               ; preds = %67
  %77 = getelementptr inbounds i8, ptr %2, i64 8
  %78 = load ptr, ptr %77, align 8
  %79 = getelementptr i8, ptr %78, i64 8
  store ptr %79, ptr %77, align 8
  br label %80

80:                                               ; preds = %76, %70
  %81 = phi ptr [ %74, %70 ], [ %78, %76 ]
  %82 = load i32, ptr %81, align 4, !tbaa !86
  %83 = trunc i32 %82 to i8
  store i8 %83, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 8), align 8, !tbaa !232
  br label %382

84:                                               ; preds = %13
  %85 = load i32, ptr %2, align 16
  %86 = icmp ult i32 %85, 41
  br i1 %86, label %87, label %93

87:                                               ; preds = %84
  %88 = getelementptr inbounds i8, ptr %2, i64 16
  %89 = load ptr, ptr %88, align 16
  %90 = zext nneg i32 %85 to i64
  %91 = getelementptr i8, ptr %89, i64 %90
  %92 = add nuw nsw i32 %85, 8
  store i32 %92, ptr %2, align 16
  br label %97

93:                                               ; preds = %84
  %94 = getelementptr inbounds i8, ptr %2, i64 8
  %95 = load ptr, ptr %94, align 8
  %96 = getelementptr i8, ptr %95, i64 8
  store ptr %96, ptr %94, align 8
  br label %97

97:                                               ; preds = %93, %87
  %98 = phi ptr [ %91, %87 ], [ %95, %93 ]
  %99 = load ptr, ptr %98, align 8, !tbaa !36
  store ptr %99, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 312), align 8, !tbaa !21
  %100 = load i32, ptr %2, align 16
  %101 = icmp ult i32 %100, 41
  br i1 %101, label %102, label %108

102:                                              ; preds = %97
  %103 = getelementptr inbounds i8, ptr %2, i64 16
  %104 = load ptr, ptr %103, align 16
  %105 = zext nneg i32 %100 to i64
  %106 = getelementptr i8, ptr %104, i64 %105
  %107 = add nuw nsw i32 %100, 8
  store i32 %107, ptr %2, align 16
  br label %112

108:                                              ; preds = %97
  %109 = getelementptr inbounds i8, ptr %2, i64 8
  %110 = load ptr, ptr %109, align 8
  %111 = getelementptr i8, ptr %110, i64 8
  store ptr %111, ptr %109, align 8
  br label %112

112:                                              ; preds = %108, %102
  %113 = phi ptr [ %106, %102 ], [ %110, %108 ]
  %114 = load i32, ptr %113, align 4, !tbaa !86
  store i32 %114, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 320), align 8, !tbaa !22
  %115 = load i32, ptr %2, align 16
  %116 = icmp ult i32 %115, 41
  br i1 %116, label %117, label %123

117:                                              ; preds = %112
  %118 = getelementptr inbounds i8, ptr %2, i64 16
  %119 = load ptr, ptr %118, align 16
  %120 = zext nneg i32 %115 to i64
  %121 = getelementptr i8, ptr %119, i64 %120
  %122 = add nuw nsw i32 %115, 8
  store i32 %122, ptr %2, align 16
  br label %127

123:                                              ; preds = %112
  %124 = getelementptr inbounds i8, ptr %2, i64 8
  %125 = load ptr, ptr %124, align 8
  %126 = getelementptr i8, ptr %125, i64 8
  store ptr %126, ptr %124, align 8
  br label %127

127:                                              ; preds = %123, %117
  %128 = phi ptr [ %121, %117 ], [ %125, %123 ]
  %129 = load i32, ptr %128, align 4, !tbaa !86
  store i32 %129, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 324), align 4, !tbaa !50
  br label %382

130:                                              ; preds = %13
  %131 = load i32, ptr %2, align 16
  %132 = icmp ult i32 %131, 41
  br i1 %132, label %133, label %139

133:                                              ; preds = %130
  %134 = getelementptr inbounds i8, ptr %2, i64 16
  %135 = load ptr, ptr %134, align 16
  %136 = zext nneg i32 %131 to i64
  %137 = getelementptr i8, ptr %135, i64 %136
  %138 = add nuw nsw i32 %131, 8
  store i32 %138, ptr %2, align 16
  br label %143

139:                                              ; preds = %130
  %140 = getelementptr inbounds i8, ptr %2, i64 8
  %141 = load ptr, ptr %140, align 8
  %142 = getelementptr i8, ptr %141, i64 8
  store ptr %142, ptr %140, align 8
  br label %143

143:                                              ; preds = %139, %133
  %144 = phi ptr [ %137, %133 ], [ %141, %139 ]
  %145 = load ptr, ptr %144, align 8, !tbaa !36
  store i32 272, ptr %145, align 4, !tbaa !86
  br label %382

146:                                              ; preds = %13
  br label %382

147:                                              ; preds = %13
  %148 = load i32, ptr %2, align 16
  %149 = icmp ult i32 %148, 41
  br i1 %149, label %150, label %156

150:                                              ; preds = %147
  %151 = getelementptr inbounds i8, ptr %2, i64 16
  %152 = load ptr, ptr %151, align 16
  %153 = zext nneg i32 %148 to i64
  %154 = getelementptr i8, ptr %152, i64 %153
  %155 = add nuw nsw i32 %148, 8
  store i32 %155, ptr %2, align 16
  br label %160

156:                                              ; preds = %147
  %157 = getelementptr inbounds i8, ptr %2, i64 8
  %158 = load ptr, ptr %157, align 8
  %159 = getelementptr i8, ptr %158, i64 8
  store ptr %159, ptr %157, align 8
  br label %160

160:                                              ; preds = %156, %150
  %161 = phi ptr [ %154, %150 ], [ %158, %156 ]
  %162 = load ptr, ptr %161, align 8, !tbaa !36
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(104) getelementptr inbounds (i8, ptr @sqlite3Config, i64 168), ptr noundef nonnull align 8 dereferenceable(104) %162, i64 104, i1 false), !tbaa.struct !233
  br label %382

163:                                              ; preds = %13
  %164 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 184), align 8, !tbaa !39
  %165 = icmp eq ptr %164, null
  br i1 %165, label %166, label %168

166:                                              ; preds = %163
  %167 = call i32 (i32, ...) @sqlite3_config(i32 noundef 18, ptr noundef nonnull @sqlite3PCacheSetDefault.defaultMethods)
  br label %168

168:                                              ; preds = %166, %163
  %169 = load i32, ptr %2, align 16
  %170 = icmp ult i32 %169, 41
  br i1 %170, label %171, label %177

171:                                              ; preds = %168
  %172 = getelementptr inbounds i8, ptr %2, i64 16
  %173 = load ptr, ptr %172, align 16
  %174 = zext nneg i32 %169 to i64
  %175 = getelementptr i8, ptr %173, i64 %174
  %176 = add nuw nsw i32 %169, 8
  store i32 %176, ptr %2, align 16
  br label %181

177:                                              ; preds = %168
  %178 = getelementptr inbounds i8, ptr %2, i64 8
  %179 = load ptr, ptr %178, align 8
  %180 = getelementptr i8, ptr %179, i64 8
  store ptr %180, ptr %178, align 8
  br label %181

181:                                              ; preds = %177, %171
  %182 = phi ptr [ %175, %171 ], [ %179, %177 ]
  %183 = load ptr, ptr %182, align 8, !tbaa !36
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(104) %183, ptr noundef nonnull align 8 dereferenceable(104) getelementptr inbounds (i8, ptr @sqlite3Config, i64 168), i64 104, i1 false), !tbaa.struct !233
  br label %382

184:                                              ; preds = %13
  %185 = load i32, ptr %2, align 16
  %186 = icmp ult i32 %185, 41
  br i1 %186, label %187, label %193

187:                                              ; preds = %184
  %188 = getelementptr inbounds i8, ptr %2, i64 16
  %189 = load ptr, ptr %188, align 16
  %190 = zext nneg i32 %185 to i64
  %191 = getelementptr i8, ptr %189, i64 %190
  %192 = add nuw nsw i32 %185, 8
  store i32 %192, ptr %2, align 16
  br label %197

193:                                              ; preds = %184
  %194 = getelementptr inbounds i8, ptr %2, i64 8
  %195 = load ptr, ptr %194, align 8
  %196 = getelementptr i8, ptr %195, i64 8
  store ptr %196, ptr %194, align 8
  br label %197

197:                                              ; preds = %193, %187
  %198 = phi ptr [ %191, %187 ], [ %195, %193 ]
  %199 = load i32, ptr %198, align 4, !tbaa !86
  store i32 %199, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 20), align 4, !tbaa !234
  %200 = load i32, ptr %2, align 16
  %201 = icmp ult i32 %200, 41
  br i1 %201, label %202, label %208

202:                                              ; preds = %197
  %203 = getelementptr inbounds i8, ptr %2, i64 16
  %204 = load ptr, ptr %203, align 16
  %205 = zext nneg i32 %200 to i64
  %206 = getelementptr i8, ptr %204, i64 %205
  %207 = add nuw nsw i32 %200, 8
  store i32 %207, ptr %2, align 16
  br label %212

208:                                              ; preds = %197
  %209 = getelementptr inbounds i8, ptr %2, i64 8
  %210 = load ptr, ptr %209, align 8
  %211 = getelementptr i8, ptr %210, i64 8
  store ptr %211, ptr %209, align 8
  br label %212

212:                                              ; preds = %208, %202
  %213 = phi ptr [ %206, %202 ], [ %210, %208 ]
  %214 = load i32, ptr %213, align 4, !tbaa !86
  store i32 %214, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 24), align 8, !tbaa !235
  br label %382

215:                                              ; preds = %13
  %216 = load i32, ptr %2, align 16
  %217 = icmp ult i32 %216, 41
  br i1 %217, label %218, label %224

218:                                              ; preds = %215
  %219 = getelementptr inbounds i8, ptr %2, i64 16
  %220 = load ptr, ptr %219, align 16
  %221 = zext nneg i32 %216 to i64
  %222 = getelementptr i8, ptr %220, i64 %221
  %223 = add nuw nsw i32 %216, 8
  store i32 %223, ptr %2, align 16
  br label %228

224:                                              ; preds = %215
  %225 = getelementptr inbounds i8, ptr %2, i64 8
  %226 = load ptr, ptr %225, align 8
  %227 = getelementptr i8, ptr %226, i64 8
  store ptr %227, ptr %225, align 8
  br label %228

228:                                              ; preds = %224, %218
  %229 = phi ptr [ %222, %218 ], [ %226, %224 ]
  %230 = load ptr, ptr %229, align 8, !tbaa !36
  %231 = load i32, ptr %2, align 16
  %232 = icmp ult i32 %231, 41
  br i1 %232, label %233, label %239

233:                                              ; preds = %228
  %234 = getelementptr inbounds i8, ptr %2, i64 16
  %235 = load ptr, ptr %234, align 16
  %236 = zext nneg i32 %231 to i64
  %237 = getelementptr i8, ptr %235, i64 %236
  %238 = add nuw nsw i32 %231, 8
  store i32 %238, ptr %2, align 16
  br label %243

239:                                              ; preds = %228
  %240 = getelementptr inbounds i8, ptr %2, i64 8
  %241 = load ptr, ptr %240, align 8
  %242 = getelementptr i8, ptr %241, i64 8
  store ptr %242, ptr %240, align 8
  br label %243

243:                                              ; preds = %239, %233
  %244 = phi ptr [ %237, %233 ], [ %241, %239 ]
  %245 = load ptr, ptr %244, align 8, !tbaa !36
  %246 = ptrtoint ptr %230 to i64
  store atomic i64 %246, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 376) monotonic, align 8
  %247 = ptrtoint ptr %245 to i64
  store atomic i64 %247, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 384) monotonic, align 8
  br label %382

248:                                              ; preds = %13
  %249 = load i32, ptr %2, align 16
  %250 = icmp ult i32 %249, 41
  br i1 %250, label %251, label %257

251:                                              ; preds = %248
  %252 = getelementptr inbounds i8, ptr %2, i64 16
  %253 = load ptr, ptr %252, align 16
  %254 = zext nneg i32 %249 to i64
  %255 = getelementptr i8, ptr %253, i64 %254
  %256 = add nuw nsw i32 %249, 8
  store i32 %256, ptr %2, align 16
  br label %261

257:                                              ; preds = %248
  %258 = getelementptr inbounds i8, ptr %2, i64 8
  %259 = load ptr, ptr %258, align 8
  %260 = getelementptr i8, ptr %259, i64 8
  store ptr %260, ptr %258, align 8
  br label %261

261:                                              ; preds = %257, %251
  %262 = phi ptr [ %255, %251 ], [ %259, %257 ]
  %263 = load i32, ptr %262, align 4, !tbaa !86
  %264 = trunc i32 %263 to i8
  store atomic i8 %264, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 6) monotonic, align 2
  br label %382

265:                                              ; preds = %13
  %266 = load i32, ptr %2, align 16
  %267 = icmp ult i32 %266, 41
  br i1 %267, label %268, label %274

268:                                              ; preds = %265
  %269 = getelementptr inbounds i8, ptr %2, i64 16
  %270 = load ptr, ptr %269, align 16
  %271 = zext nneg i32 %266 to i64
  %272 = getelementptr i8, ptr %270, i64 %271
  %273 = add nuw nsw i32 %266, 8
  store i32 %273, ptr %2, align 16
  br label %278

274:                                              ; preds = %265
  %275 = getelementptr inbounds i8, ptr %2, i64 8
  %276 = load ptr, ptr %275, align 8
  %277 = getelementptr i8, ptr %276, i64 8
  store ptr %277, ptr %275, align 8
  br label %278

278:                                              ; preds = %274, %268
  %279 = phi ptr [ %272, %268 ], [ %276, %274 ]
  %280 = load i32, ptr %279, align 4, !tbaa !86
  %281 = trunc i32 %280 to i8
  store i8 %281, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 7), align 1, !tbaa !236
  br label %382

282:                                              ; preds = %13
  %283 = load i32, ptr %2, align 16
  %284 = icmp ult i32 %283, 41
  br i1 %284, label %285, label %291

285:                                              ; preds = %282
  %286 = getelementptr inbounds i8, ptr %2, i64 16
  %287 = load ptr, ptr %286, align 16
  %288 = zext nneg i32 %283 to i64
  %289 = getelementptr i8, ptr %287, i64 %288
  %290 = add nuw nsw i32 %283, 8
  store i32 %290, ptr %2, align 16
  br label %295

291:                                              ; preds = %282
  %292 = getelementptr inbounds i8, ptr %2, i64 8
  %293 = load ptr, ptr %292, align 8
  %294 = getelementptr i8, ptr %293, i64 8
  store ptr %294, ptr %292, align 8
  br label %295

295:                                              ; preds = %291, %285
  %296 = phi ptr [ %289, %285 ], [ %293, %291 ]
  %297 = load i64, ptr %296, align 8, !tbaa !67
  %298 = load i32, ptr %2, align 16
  %299 = icmp ult i32 %298, 41
  br i1 %299, label %300, label %306

300:                                              ; preds = %295
  %301 = getelementptr inbounds i8, ptr %2, i64 16
  %302 = load ptr, ptr %301, align 16
  %303 = zext nneg i32 %298 to i64
  %304 = getelementptr i8, ptr %302, i64 %303
  %305 = add nuw nsw i32 %298, 8
  store i32 %305, ptr %2, align 16
  br label %310

306:                                              ; preds = %295
  %307 = getelementptr inbounds i8, ptr %2, i64 8
  %308 = load ptr, ptr %307, align 8
  %309 = getelementptr i8, ptr %308, i64 8
  store ptr %309, ptr %307, align 8
  br label %310

310:                                              ; preds = %306, %300
  %311 = phi ptr [ %304, %300 ], [ %308, %306 ]
  %312 = load i64, ptr %311, align 8, !tbaa !67
  %313 = call i64 @llvm.umin.i64(i64 %312, i64 2147418112)
  %314 = call i64 @llvm.smax.i64(i64 %297, i64 0)
  %315 = icmp sgt i64 %297, %313
  %316 = select i1 %315, i64 %313, i64 %314
  store i64 %313, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 304), align 8, !tbaa !237
  store i64 %316, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 296), align 8, !tbaa !238
  br label %382

317:                                              ; preds = %13
  %318 = load i32, ptr %2, align 16
  %319 = icmp ult i32 %318, 41
  br i1 %319, label %320, label %326

320:                                              ; preds = %317
  %321 = getelementptr inbounds i8, ptr %2, i64 16
  %322 = load ptr, ptr %321, align 16
  %323 = zext nneg i32 %318 to i64
  %324 = getelementptr i8, ptr %322, i64 %323
  %325 = add nuw nsw i32 %318, 8
  store i32 %325, ptr %2, align 16
  br label %330

326:                                              ; preds = %317
  %327 = getelementptr inbounds i8, ptr %2, i64 8
  %328 = load ptr, ptr %327, align 8
  %329 = getelementptr i8, ptr %328, i64 8
  store ptr %329, ptr %327, align 8
  br label %330

330:                                              ; preds = %326, %320
  %331 = phi ptr [ %324, %320 ], [ %328, %326 ]
  %332 = load i32, ptr %331, align 4, !tbaa !86
  store i32 %332, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 336), align 8, !tbaa !239
  br label %382

333:                                              ; preds = %13
  %334 = load i32, ptr %2, align 16
  %335 = icmp ult i32 %334, 41
  br i1 %335, label %336, label %342

336:                                              ; preds = %333
  %337 = getelementptr inbounds i8, ptr %2, i64 16
  %338 = load ptr, ptr %337, align 16
  %339 = zext nneg i32 %334 to i64
  %340 = getelementptr i8, ptr %338, i64 %339
  %341 = add nuw nsw i32 %334, 8
  store i32 %341, ptr %2, align 16
  br label %346

342:                                              ; preds = %333
  %343 = getelementptr inbounds i8, ptr %2, i64 8
  %344 = load ptr, ptr %343, align 8
  %345 = getelementptr i8, ptr %344, i64 8
  store ptr %345, ptr %343, align 8
  br label %346

346:                                              ; preds = %342, %336
  %347 = phi ptr [ %340, %336 ], [ %344, %342 ]
  %348 = load i32, ptr %347, align 4, !tbaa !86
  store i32 %348, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 28), align 4, !tbaa !240
  br label %382

349:                                              ; preds = %13
  %350 = load i32, ptr %2, align 16
  %351 = icmp ult i32 %350, 41
  br i1 %351, label %352, label %358

352:                                              ; preds = %349
  %353 = getelementptr inbounds i8, ptr %2, i64 16
  %354 = load ptr, ptr %353, align 16
  %355 = zext nneg i32 %350 to i64
  %356 = getelementptr i8, ptr %354, i64 %355
  %357 = add nuw nsw i32 %350, 8
  store i32 %357, ptr %2, align 16
  br label %362

358:                                              ; preds = %349
  %359 = getelementptr inbounds i8, ptr %2, i64 8
  %360 = load ptr, ptr %359, align 8
  %361 = getelementptr i8, ptr %360, i64 8
  store ptr %361, ptr %359, align 8
  br label %362

362:                                              ; preds = %358, %352
  %363 = phi ptr [ %356, %352 ], [ %360, %358 ]
  %364 = load i64, ptr %363, align 8, !tbaa !67
  store i64 %364, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 392), align 8, !tbaa !241
  br label %382

365:                                              ; preds = %13
  %366 = load i32, ptr %2, align 16
  %367 = icmp ult i32 %366, 41
  br i1 %367, label %368, label %374

368:                                              ; preds = %365
  %369 = getelementptr inbounds i8, ptr %2, i64 16
  %370 = load ptr, ptr %369, align 16
  %371 = zext nneg i32 %366 to i64
  %372 = getelementptr i8, ptr %370, i64 %371
  %373 = add nuw nsw i32 %366, 8
  store i32 %373, ptr %2, align 16
  br label %378

374:                                              ; preds = %365
  %375 = getelementptr inbounds i8, ptr %2, i64 8
  %376 = load ptr, ptr %375, align 8
  %377 = getelementptr i8, ptr %376, i64 8
  store ptr %377, ptr %375, align 8
  br label %378

378:                                              ; preds = %374, %368
  %379 = phi ptr [ %372, %368 ], [ %376, %374 ]
  %380 = load ptr, ptr %379, align 8, !tbaa !36
  store i32 0, ptr %380, align 4, !tbaa !86
  br label %382

381:                                              ; preds = %13
  br label %382

382:                                              ; preds = %381, %378, %362, %346, %330, %310, %278, %261, %243, %212, %181, %160, %146, %143, %127, %80, %64, %48, %27, %13
  %383 = phi i32 [ 1, %381 ], [ 0, %378 ], [ 0, %362 ], [ 0, %346 ], [ 0, %330 ], [ 0, %310 ], [ 0, %278 ], [ 0, %261 ], [ 0, %243 ], [ 0, %212 ], [ 0, %181 ], [ 0, %160 ], [ 1, %146 ], [ 0, %13 ], [ 0, %143 ], [ 0, %127 ], [ 0, %80 ], [ 0, %64 ], [ 0, %48 ], [ 0, %27 ]
  call void @llvm.va_end.p0(ptr %2)
  br label %384

384:                                              ; preds = %382, %12
  %385 = phi i32 [ 21, %12 ], [ %383, %382 ]
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #16
  ret i32 %385
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @measureAllocationSize(ptr noundef readonly %0, ptr noundef %1) unnamed_addr #4 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %20, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds i8, ptr %0, i64 496
  %6 = load ptr, ptr %5, align 8, !tbaa !144
  %7 = icmp ugt ptr %6, %1
  br i1 %7, label %8, label %20

8:                                                ; preds = %4
  %9 = getelementptr inbounds i8, ptr %0, i64 472
  %10 = load ptr, ptr %9, align 8, !tbaa !145
  %11 = icmp ugt ptr %10, %1
  br i1 %11, label %12, label %23

12:                                               ; preds = %8
  %13 = getelementptr inbounds i8, ptr %0, i64 480
  %14 = load ptr, ptr %13, align 8, !tbaa !146
  %15 = icmp ugt ptr %14, %1
  br i1 %15, label %20, label %16

16:                                               ; preds = %12
  %17 = getelementptr inbounds i8, ptr %0, i64 414
  %18 = load i16, ptr %17, align 2, !tbaa !147
  %19 = zext i16 %18 to i32
  br label %23

20:                                               ; preds = %12, %4, %2
  %21 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %22 = tail call i32 %21(ptr noundef %1) #16
  br label %23

23:                                               ; preds = %20, %16, %8
  %24 = phi i32 [ %19, %16 ], [ %22, %20 ], [ 128, %8 ]
  %25 = getelementptr inbounds i8, ptr %0, i64 768
  %26 = load ptr, ptr %25, align 8, !tbaa !177
  %27 = load i32, ptr %26, align 4, !tbaa !86
  %28 = add nsw i32 %27, %24
  store i32 %28, ptr %26, align 4, !tbaa !86
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc ptr @sqlite3DbMallocRawNN(ptr noundef %0, i64 noundef %1) unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %0, i64 412
  %4 = load i16, ptr %3, align 4, !tbaa !225
  %5 = zext i16 %4 to i64
  %6 = icmp ult i64 %5, %1
  br i1 %6, label %7, label %21

7:                                                ; preds = %2
  %8 = getelementptr inbounds i8, ptr %0, i64 408
  %9 = load i32, ptr %8, align 8, !tbaa !224
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %15

11:                                               ; preds = %7
  %12 = getelementptr inbounds i8, ptr %0, i64 428
  %13 = load i32, ptr %12, align 4, !tbaa !86
  %14 = add i32 %13, 1
  store i32 %14, ptr %12, align 4, !tbaa !86
  br label %19

15:                                               ; preds = %7
  %16 = getelementptr inbounds i8, ptr %0, i64 103
  %17 = load i8, ptr %16, align 1, !tbaa !221
  %18 = icmp eq i8 %17, 0
  br i1 %18, label %19, label %64

19:                                               ; preds = %15, %11
  %20 = tail call fastcc ptr @dbMallocRawFinish(ptr noundef %0, i64 noundef %1)
  br label %64

21:                                               ; preds = %2
  %22 = icmp ult i64 %1, 129
  br i1 %22, label %23, label %41

23:                                               ; preds = %21
  %24 = getelementptr inbounds i8, ptr %0, i64 464
  %25 = load ptr, ptr %24, align 8, !tbaa !173
  %26 = icmp eq ptr %25, null
  br i1 %26, label %32, label %27

27:                                               ; preds = %23
  %28 = load ptr, ptr %25, align 8, !tbaa !174
  store ptr %28, ptr %24, align 8, !tbaa !173
  %29 = getelementptr inbounds i8, ptr %0, i64 424
  %30 = load i32, ptr %29, align 8, !tbaa !86
  %31 = add i32 %30, 1
  store i32 %31, ptr %29, align 8, !tbaa !86
  br label %64

32:                                               ; preds = %23
  %33 = getelementptr inbounds i8, ptr %0, i64 456
  %34 = load ptr, ptr %33, align 8, !tbaa !242
  %35 = icmp eq ptr %34, null
  br i1 %35, label %41, label %36

36:                                               ; preds = %32
  %37 = load ptr, ptr %34, align 8, !tbaa !174
  store ptr %37, ptr %33, align 8, !tbaa !242
  %38 = getelementptr inbounds i8, ptr %0, i64 424
  %39 = load i32, ptr %38, align 8, !tbaa !86
  %40 = add i32 %39, 1
  store i32 %40, ptr %38, align 8, !tbaa !86
  br label %64

41:                                               ; preds = %32, %21
  %42 = getelementptr inbounds i8, ptr %0, i64 448
  %43 = load ptr, ptr %42, align 8, !tbaa !176
  %44 = icmp eq ptr %43, null
  br i1 %44, label %50, label %45

45:                                               ; preds = %41
  %46 = load ptr, ptr %43, align 8, !tbaa !174
  store ptr %46, ptr %42, align 8, !tbaa !176
  %47 = getelementptr inbounds i8, ptr %0, i64 424
  %48 = load i32, ptr %47, align 8, !tbaa !86
  %49 = add i32 %48, 1
  store i32 %49, ptr %47, align 8, !tbaa !86
  br label %64

50:                                               ; preds = %41
  %51 = getelementptr inbounds i8, ptr %0, i64 440
  %52 = load ptr, ptr %51, align 8, !tbaa !243
  %53 = icmp eq ptr %52, null
  br i1 %53, label %59, label %54

54:                                               ; preds = %50
  %55 = load ptr, ptr %52, align 8, !tbaa !174
  store ptr %55, ptr %51, align 8, !tbaa !243
  %56 = getelementptr inbounds i8, ptr %0, i64 424
  %57 = load i32, ptr %56, align 8, !tbaa !86
  %58 = add i32 %57, 1
  store i32 %58, ptr %56, align 8, !tbaa !86
  br label %64

59:                                               ; preds = %50
  %60 = getelementptr inbounds i8, ptr %0, i64 432
  %61 = load i32, ptr %60, align 8, !tbaa !86
  %62 = add i32 %61, 1
  store i32 %62, ptr %60, align 8, !tbaa !86
  %63 = tail call fastcc ptr @dbMallocRawFinish(ptr noundef %0, i64 noundef %1)
  br label %64

64:                                               ; preds = %59, %54, %45, %36, %27, %19, %15
  %65 = phi ptr [ %20, %19 ], [ %25, %27 ], [ %34, %36 ], [ %43, %45 ], [ %52, %54 ], [ %63, %59 ], [ null, %15 ]
  ret ptr %65
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc ptr @dbReallocFinish(ptr noundef %0, ptr noundef %1, i64 noundef %2) unnamed_addr #4 {
  %4 = getelementptr inbounds i8, ptr %0, i64 103
  %5 = load i8, ptr %4, align 1, !tbaa !221
  %6 = icmp eq i8 %5, 0
  br i1 %6, label %7, label %105

7:                                                ; preds = %3
  %8 = getelementptr inbounds i8, ptr %0, i64 480
  %9 = load ptr, ptr %8, align 8, !tbaa !146
  %10 = icmp ugt ptr %9, %1
  br i1 %10, label %66, label %11

11:                                               ; preds = %7
  %12 = getelementptr inbounds i8, ptr %0, i64 496
  %13 = load ptr, ptr %12, align 8, !tbaa !144
  %14 = icmp ugt ptr %13, %1
  br i1 %14, label %15, label %66

15:                                               ; preds = %11
  %16 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef %0, i64 noundef %2)
  %17 = icmp eq ptr %16, null
  br i1 %17, label %105, label %18

18:                                               ; preds = %15
  %19 = getelementptr inbounds i8, ptr %0, i64 472
  %20 = load ptr, ptr %19, align 8, !tbaa !145
  %21 = icmp ugt ptr %20, %1
  br i1 %21, label %22, label %26

22:                                               ; preds = %18
  %23 = getelementptr inbounds i8, ptr %0, i64 414
  %24 = load i16, ptr %23, align 2, !tbaa !147
  %25 = zext i16 %24 to i64
  br label %26

26:                                               ; preds = %22, %18
  %27 = phi i64 [ %25, %22 ], [ 128, %18 ]
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 %16, ptr noundef align 1 %1, i64 noundef %27, i1 noundef false) #16
  %28 = icmp eq ptr %1, null
  br i1 %28, label %105, label %29

29:                                               ; preds = %26
  %30 = icmp eq ptr %0, null
  br i1 %30, label %52, label %31

31:                                               ; preds = %29
  %32 = getelementptr inbounds i8, ptr %0, i64 488
  %33 = load ptr, ptr %32, align 8, !tbaa !172
  %34 = icmp ugt ptr %33, %1
  br i1 %34, label %35, label %47

35:                                               ; preds = %31
  %36 = load ptr, ptr %19, align 8, !tbaa !145
  %37 = icmp ugt ptr %36, %1
  br i1 %37, label %41, label %38

38:                                               ; preds = %35
  %39 = getelementptr inbounds i8, ptr %0, i64 464
  %40 = load ptr, ptr %39, align 8, !tbaa !173
  store ptr %40, ptr %1, align 8, !tbaa !174
  store ptr %1, ptr %39, align 8, !tbaa !173
  br label %105

41:                                               ; preds = %35
  %42 = load ptr, ptr %8, align 8, !tbaa !146
  %43 = icmp ugt ptr %42, %1
  br i1 %43, label %47, label %44

44:                                               ; preds = %41
  %45 = getelementptr inbounds i8, ptr %0, i64 448
  %46 = load ptr, ptr %45, align 8, !tbaa !176
  store ptr %46, ptr %1, align 8, !tbaa !174
  store ptr %1, ptr %45, align 8, !tbaa !176
  br label %105

47:                                               ; preds = %41, %31
  %48 = getelementptr inbounds i8, ptr %0, i64 768
  %49 = load ptr, ptr %48, align 8, !tbaa !177
  %50 = icmp eq ptr %49, null
  br i1 %50, label %52, label %51

51:                                               ; preds = %47
  tail call fastcc void @measureAllocationSize(ptr noundef nonnull %0, ptr noundef nonnull %1)
  br label %105

52:                                               ; preds = %47, %29
  %53 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %54 = icmp eq i32 %53, 0
  br i1 %54, label %64, label %55

55:                                               ; preds = %52
  %56 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %57 = tail call i32 %56(ptr noundef nonnull %1) #16
  %58 = sext i32 %57 to i64
  %59 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %60 = sub nsw i64 %59, %58
  store i64 %60, ptr @sqlite3Stat, align 8, !tbaa !67
  %61 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %62 = add nsw i64 %61, -1
  store i64 %62, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %63 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %63(ptr noundef nonnull %1) #16
  br label %105

64:                                               ; preds = %52
  %65 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %65(ptr noundef nonnull %1) #16
  br label %105

66:                                               ; preds = %11, %7
  %67 = tail call fastcc ptr @sqlite3Realloc(ptr noundef %1, i64 noundef %2)
  %68 = icmp eq ptr %67, null
  br i1 %68, label %69, label %105

69:                                               ; preds = %66
  %70 = load i8, ptr %4, align 1, !tbaa !221
  %71 = icmp eq i8 %70, 0
  br i1 %71, label %72, label %105

72:                                               ; preds = %69
  %73 = getelementptr inbounds i8, ptr %0, i64 104
  %74 = load i8, ptr %73, align 8, !tbaa !222
  %75 = icmp eq i8 %74, 0
  br i1 %75, label %76, label %105

76:                                               ; preds = %72
  store i8 1, ptr %4, align 1, !tbaa !221
  %77 = getelementptr inbounds i8, ptr %0, i64 220
  %78 = load i32, ptr %77, align 4, !tbaa !223
  %79 = icmp sgt i32 %78, 0
  br i1 %79, label %80, label %82

80:                                               ; preds = %76
  %81 = getelementptr inbounds i8, ptr %0, i64 400
  store atomic volatile i32 1, ptr %81 monotonic, align 8
  br label %82

82:                                               ; preds = %80, %76
  %83 = getelementptr inbounds i8, ptr %0, i64 408
  %84 = load i32, ptr %83, align 8, !tbaa !224
  %85 = add i32 %84, 1
  store i32 %85, ptr %83, align 8, !tbaa !224
  %86 = getelementptr inbounds i8, ptr %0, i64 412
  store i16 0, ptr %86, align 4, !tbaa !225
  %87 = getelementptr inbounds i8, ptr %0, i64 344
  %88 = load ptr, ptr %87, align 8, !tbaa !99
  %89 = icmp eq ptr %88, null
  br i1 %89, label %105, label %90

90:                                               ; preds = %82
  tail call void (ptr, ptr, ...) @sqlite3ErrorMsg(ptr noundef nonnull %88, ptr noundef nonnull @.str.146)
  %91 = load ptr, ptr %87, align 8, !tbaa !99
  %92 = getelementptr inbounds i8, ptr %91, i64 24
  store i32 7, ptr %92, align 8, !tbaa !105
  %93 = getelementptr inbounds i8, ptr %91, i64 264
  %94 = load ptr, ptr %93, align 8, !tbaa !226
  %95 = icmp eq ptr %94, null
  br i1 %95, label %105, label %96

96:                                               ; preds = %96, %90
  %97 = phi ptr [ %103, %96 ], [ %94, %90 ]
  %98 = getelementptr inbounds i8, ptr %97, i64 48
  %99 = load i32, ptr %98, align 8, !tbaa !108
  %100 = add nsw i32 %99, 1
  store i32 %100, ptr %98, align 8, !tbaa !108
  %101 = getelementptr inbounds i8, ptr %97, i64 24
  store i32 7, ptr %101, align 8, !tbaa !105
  %102 = getelementptr inbounds i8, ptr %97, i64 264
  %103 = load ptr, ptr %102, align 8, !tbaa !226
  %104 = icmp eq ptr %103, null
  br i1 %104, label %105, label %96, !llvm.loop !227

105:                                              ; preds = %96, %90, %82, %72, %69, %66, %64, %55, %51, %44, %38, %26, %15, %3
  %106 = phi ptr [ null, %15 ], [ %67, %66 ], [ null, %3 ], [ %16, %26 ], [ %16, %38 ], [ %16, %44 ], [ %16, %51 ], [ %16, %55 ], [ %16, %64 ], [ null, %69 ], [ null, %72 ], [ null, %82 ], [ null, %90 ], [ null, %96 ]
  ret ptr %106
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc ptr @dbMallocRawFinish(ptr noundef %0, i64 noundef %1) unnamed_addr #4 {
  %3 = tail call fastcc ptr @sqlite3Malloc(i64 noundef %1)
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %42

5:                                                ; preds = %2
  %6 = getelementptr inbounds i8, ptr %0, i64 103
  %7 = load i8, ptr %6, align 1, !tbaa !221
  %8 = icmp eq i8 %7, 0
  br i1 %8, label %9, label %42

9:                                                ; preds = %5
  %10 = getelementptr inbounds i8, ptr %0, i64 104
  %11 = load i8, ptr %10, align 8, !tbaa !222
  %12 = icmp eq i8 %11, 0
  br i1 %12, label %13, label %42

13:                                               ; preds = %9
  store i8 1, ptr %6, align 1, !tbaa !221
  %14 = getelementptr inbounds i8, ptr %0, i64 220
  %15 = load i32, ptr %14, align 4, !tbaa !223
  %16 = icmp sgt i32 %15, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %13
  %18 = getelementptr inbounds i8, ptr %0, i64 400
  store atomic volatile i32 1, ptr %18 monotonic, align 8
  br label %19

19:                                               ; preds = %17, %13
  %20 = getelementptr inbounds i8, ptr %0, i64 408
  %21 = load i32, ptr %20, align 8, !tbaa !224
  %22 = add i32 %21, 1
  store i32 %22, ptr %20, align 8, !tbaa !224
  %23 = getelementptr inbounds i8, ptr %0, i64 412
  store i16 0, ptr %23, align 4, !tbaa !225
  %24 = getelementptr inbounds i8, ptr %0, i64 344
  %25 = load ptr, ptr %24, align 8, !tbaa !99
  %26 = icmp eq ptr %25, null
  br i1 %26, label %42, label %27

27:                                               ; preds = %19
  tail call void (ptr, ptr, ...) @sqlite3ErrorMsg(ptr noundef nonnull %25, ptr noundef nonnull @.str.146)
  %28 = load ptr, ptr %24, align 8, !tbaa !99
  %29 = getelementptr inbounds i8, ptr %28, i64 24
  store i32 7, ptr %29, align 8, !tbaa !105
  %30 = getelementptr inbounds i8, ptr %28, i64 264
  %31 = load ptr, ptr %30, align 8, !tbaa !226
  %32 = icmp eq ptr %31, null
  br i1 %32, label %42, label %33

33:                                               ; preds = %33, %27
  %34 = phi ptr [ %40, %33 ], [ %31, %27 ]
  %35 = getelementptr inbounds i8, ptr %34, i64 48
  %36 = load i32, ptr %35, align 8, !tbaa !108
  %37 = add nsw i32 %36, 1
  store i32 %37, ptr %35, align 8, !tbaa !108
  %38 = getelementptr inbounds i8, ptr %34, i64 24
  store i32 7, ptr %38, align 8, !tbaa !105
  %39 = getelementptr inbounds i8, ptr %34, i64 264
  %40 = load ptr, ptr %39, align 8, !tbaa !226
  %41 = icmp eq ptr %40, null
  br i1 %41, label %42, label %33, !llvm.loop !227

42:                                               ; preds = %33, %27, %19, %9, %5, %2
  ret ptr %3
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc ptr @strAccumFinishRealloc(ptr nocapture noundef %0) unnamed_addr #4 {
  %2 = load ptr, ptr %0, align 8, !tbaa !98
  %3 = getelementptr inbounds i8, ptr %0, i64 24
  %4 = load i32, ptr %3, align 8, !tbaa !75
  %5 = add i32 %4, 1
  %6 = zext i32 %5 to i64
  %7 = icmp eq ptr %2, null
  br i1 %7, label %10, label %8

8:                                                ; preds = %1
  %9 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %2, i64 noundef %6)
  br label %12

10:                                               ; preds = %1
  %11 = tail call fastcc ptr @sqlite3Malloc(i64 noundef %6)
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi ptr [ %9, %8 ], [ %11, %10 ]
  %14 = icmp eq ptr %13, null
  br i1 %14, label %24, label %15

15:                                               ; preds = %12
  %16 = getelementptr inbounds i8, ptr %0, i64 8
  %17 = load ptr, ptr %16, align 8, !tbaa !77
  %18 = load i32, ptr %3, align 8, !tbaa !75
  %19 = add i32 %18, 1
  %20 = zext i32 %19 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 %13, ptr noundef align 1 %17, i64 noundef %20, i1 noundef false) #16
  %21 = getelementptr inbounds i8, ptr %0, i64 29
  %22 = load i8, ptr %21, align 1, !tbaa !73
  %23 = or i8 %22, 4
  store i8 %23, ptr %21, align 1, !tbaa !73
  br label %30

24:                                               ; preds = %12
  %25 = getelementptr inbounds i8, ptr %0, i64 28
  store i8 7, ptr %25, align 4, !tbaa !96
  %26 = getelementptr inbounds i8, ptr %0, i64 20
  %27 = load i32, ptr %26, align 4, !tbaa !97
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %30, label %29

29:                                               ; preds = %24
  tail call void @sqlite3_str_reset(ptr noundef nonnull %0)
  br label %30

30:                                               ; preds = %29, %24, %15
  %31 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr %13, ptr %31, align 8, !tbaa !77
  ret ptr %13
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #8

; Function Attrs: nofree nounwind memory(read)
declare noundef ptr @getenv(ptr nocapture noundef) local_unnamed_addr #9

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @sqlite3PcacheRelease(ptr noundef %0) unnamed_addr #4 {
  %2 = getelementptr inbounds i8, ptr %0, i64 24
  %3 = load ptr, ptr %2, align 8, !tbaa !244
  %4 = getelementptr inbounds i8, ptr %3, i64 24
  %5 = load i64, ptr %4, align 8, !tbaa !245
  %6 = add nsw i64 %5, -1
  store i64 %6, ptr %4, align 8, !tbaa !245
  %7 = getelementptr inbounds i8, ptr %0, i64 56
  %8 = load i64, ptr %7, align 8, !tbaa !247
  %9 = add nsw i64 %8, -1
  store i64 %9, ptr %7, align 8, !tbaa !247
  %10 = icmp eq i64 %9, 0
  br i1 %10, label %11, label %68

11:                                               ; preds = %1
  %12 = getelementptr inbounds i8, ptr %0, i64 52
  %13 = load i16, ptr %12, align 4, !tbaa !201
  %14 = and i16 %13, 1
  %15 = icmp eq i16 %14, 0
  br i1 %15, label %25, label %16

16:                                               ; preds = %11
  %17 = getelementptr inbounds i8, ptr %3, i64 48
  %18 = load i8, ptr %17, align 8, !tbaa !248
  %19 = icmp eq i8 %18, 0
  br i1 %19, label %68, label %20

20:                                               ; preds = %16
  %21 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 232), align 8, !tbaa !249
  %22 = getelementptr inbounds i8, ptr %3, i64 72
  %23 = load ptr, ptr %22, align 8, !tbaa !250
  %24 = load ptr, ptr %0, align 8, !tbaa !251
  tail call void %21(ptr noundef %23, ptr noundef %24, i32 noundef 0) #16
  br label %68

25:                                               ; preds = %11
  %26 = getelementptr inbounds i8, ptr %3, i64 16
  %27 = load ptr, ptr %26, align 8, !tbaa !252
  %28 = icmp eq ptr %27, %0
  br i1 %28, label %29, label %32

29:                                               ; preds = %25
  %30 = getelementptr inbounds i8, ptr %0, i64 72
  %31 = load ptr, ptr %30, align 8, !tbaa !253
  store ptr %31, ptr %26, align 8, !tbaa !252
  br label %32

32:                                               ; preds = %29, %25
  %33 = getelementptr inbounds i8, ptr %0, i64 64
  %34 = load ptr, ptr %33, align 8, !tbaa !254
  %35 = icmp eq ptr %34, null
  %36 = getelementptr inbounds i8, ptr %0, i64 72
  %37 = load ptr, ptr %36, align 8, !tbaa !253
  %38 = getelementptr inbounds i8, ptr %3, i64 8
  %39 = getelementptr inbounds i8, ptr %34, i64 72
  %40 = select i1 %35, ptr %38, ptr %39
  store ptr %37, ptr %40, align 8, !tbaa !36
  %41 = getelementptr inbounds i8, ptr %0, i64 72
  %42 = load ptr, ptr %41, align 8, !tbaa !253
  %43 = icmp eq ptr %42, null
  br i1 %43, label %46, label %44

44:                                               ; preds = %32
  %45 = getelementptr inbounds i8, ptr %42, i64 64
  store ptr %34, ptr %45, align 8, !tbaa !254
  br label %49

46:                                               ; preds = %32
  store ptr %34, ptr %3, align 8, !tbaa !255
  br i1 %35, label %47, label %49

47:                                               ; preds = %46
  %48 = getelementptr inbounds i8, ptr %3, i64 49
  store i8 2, ptr %48, align 1, !tbaa !256
  br label %49

49:                                               ; preds = %47, %46, %44
  store ptr null, ptr %41, align 8, !tbaa !253
  %50 = load ptr, ptr %3, align 8, !tbaa !255
  store ptr %50, ptr %33, align 8, !tbaa !254
  %51 = icmp eq ptr %50, null
  br i1 %51, label %54, label %52

52:                                               ; preds = %49
  %53 = getelementptr inbounds i8, ptr %50, i64 72
  store ptr %0, ptr %53, align 8, !tbaa !253
  br label %61

54:                                               ; preds = %49
  %55 = getelementptr inbounds i8, ptr %3, i64 8
  store ptr %0, ptr %55, align 8, !tbaa !257
  %56 = getelementptr inbounds i8, ptr %3, i64 48
  %57 = load i8, ptr %56, align 8, !tbaa !248
  %58 = icmp eq i8 %57, 0
  br i1 %58, label %61, label %59

59:                                               ; preds = %54
  %60 = getelementptr inbounds i8, ptr %3, i64 49
  store i8 1, ptr %60, align 1, !tbaa !256
  br label %61

61:                                               ; preds = %59, %54, %52
  store ptr %0, ptr %3, align 8, !tbaa !255
  %62 = load ptr, ptr %26, align 8, !tbaa !252
  %63 = icmp eq ptr %62, null
  %64 = and i16 %13, 8
  %65 = icmp eq i16 %64, 0
  %66 = and i1 %65, %63
  br i1 %66, label %67, label %68

67:                                               ; preds = %61
  store ptr %0, ptr %26, align 8, !tbaa !252
  br label %68

68:                                               ; preds = %67, %61, %20, %16, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @subjournalPageIfRequired(ptr nocapture noundef readonly %0) unnamed_addr #1 {
  %2 = alloca [4 x i8], align 1
  %3 = getelementptr inbounds i8, ptr %0, i64 40
  %4 = load ptr, ptr %3, align 8, !tbaa !199
  %5 = getelementptr inbounds i8, ptr %0, i64 48
  %6 = load i32, ptr %5, align 8, !tbaa !203
  %7 = getelementptr inbounds i8, ptr %4, i64 128
  %8 = load i32, ptr %7, align 8, !tbaa !204
  %9 = icmp sgt i32 %8, 0
  br i1 %9, label %10, label %194

10:                                               ; preds = %1
  %11 = getelementptr inbounds i8, ptr %4, i64 120
  %12 = load ptr, ptr %11, align 8, !tbaa !258
  %13 = add i32 %6, -1
  %14 = zext nneg i32 %8 to i64
  br label %15

15:                                               ; preds = %87, %10
  %16 = phi i64 [ 1, %10 ], [ %90, %87 ]
  %17 = phi i64 [ 0, %10 ], [ %88, %87 ]
  %18 = getelementptr inbounds %struct.PagerSavepoint, ptr %12, i64 %17
  %19 = getelementptr inbounds i8, ptr %18, i64 24
  %20 = load i32, ptr %19, align 8, !tbaa !259
  %21 = icmp ult i32 %20, %6
  br i1 %21, label %87, label %22

22:                                               ; preds = %15
  %23 = getelementptr inbounds i8, ptr %18, i64 16
  %24 = load ptr, ptr %23, align 8, !tbaa !261
  %25 = load i32, ptr %24, align 8, !tbaa !262
  %26 = icmp ult i32 %13, %25
  br i1 %26, label %27, label %75

27:                                               ; preds = %34, %22
  %28 = phi ptr [ %40, %34 ], [ %24, %22 ]
  %29 = phi i32 [ %36, %34 ], [ %13, %22 ]
  %30 = freeze i32 %29
  %31 = getelementptr inbounds i8, ptr %28, i64 8
  %32 = load i32, ptr %31, align 8, !tbaa !264
  %33 = icmp eq i32 %32, 0
  br i1 %33, label %42, label %34

34:                                               ; preds = %27
  %35 = udiv i32 %30, %32
  %36 = urem i32 %30, %32
  %37 = getelementptr inbounds i8, ptr %28, i64 16
  %38 = zext i32 %35 to i64
  %39 = getelementptr inbounds [62 x ptr], ptr %37, i64 0, i64 %38
  %40 = load ptr, ptr %39, align 8, !tbaa !30
  %41 = icmp eq ptr %40, null
  br i1 %41, label %75, label %27

42:                                               ; preds = %27
  %43 = load i32, ptr %28, align 8, !tbaa !262
  %44 = icmp ult i32 %43, 3969
  br i1 %44, label %45, label %55

45:                                               ; preds = %42
  %46 = getelementptr inbounds i8, ptr %28, i64 16
  %47 = lshr i32 %30, 3
  %48 = zext nneg i32 %47 to i64
  %49 = getelementptr inbounds [496 x i8], ptr %46, i64 0, i64 %48
  %50 = load i8, ptr %49, align 1, !tbaa !30
  %51 = zext i8 %50 to i32
  %52 = and i32 %30, 7
  %53 = lshr i32 %51, %52
  %54 = and i32 %53, 1
  br label %75

55:                                               ; preds = %42
  %56 = add i32 %30, 1
  %57 = urem i32 %30, 124
  %58 = getelementptr inbounds i8, ptr %28, i64 16
  %59 = zext nneg i32 %57 to i64
  %60 = getelementptr inbounds [124 x i32], ptr %58, i64 0, i64 %59
  %61 = load i32, ptr %60, align 4, !tbaa !30
  %62 = icmp eq i32 %61, 0
  br i1 %62, label %75, label %63

63:                                               ; preds = %67, %55
  %64 = phi i32 [ %73, %67 ], [ %61, %55 ]
  %65 = phi i32 [ %70, %67 ], [ %57, %55 ]
  %66 = icmp eq i32 %64, %56
  br i1 %66, label %75, label %67

67:                                               ; preds = %63
  %68 = add i32 %65, 1
  %69 = icmp eq i32 %68, 124
  %70 = select i1 %69, i32 0, i32 %68
  %71 = zext nneg i32 %70 to i64
  %72 = getelementptr inbounds [124 x i32], ptr %58, i64 0, i64 %71
  %73 = load i32, ptr %72, align 4, !tbaa !30
  %74 = icmp eq i32 %73, 0
  br i1 %74, label %75, label %63, !llvm.loop !265

75:                                               ; preds = %67, %63, %55, %45, %34, %22
  %76 = phi i32 [ %54, %45 ], [ 0, %22 ], [ 0, %55 ], [ 1, %63 ], [ 0, %67 ], [ 0, %34 ]
  %77 = icmp eq i32 %76, 0
  br i1 %77, label %78, label %87

78:                                               ; preds = %75
  %79 = trunc nuw nsw i64 %17 to i32
  %80 = add nuw nsw i32 %79, 1
  %81 = icmp slt i32 %80, %8
  br i1 %81, label %82, label %91

82:                                               ; preds = %82, %78
  %83 = phi i64 [ %85, %82 ], [ %16, %78 ]
  %84 = getelementptr inbounds %struct.PagerSavepoint, ptr %12, i64 %83, i32 5
  store i32 0, ptr %84, align 8, !tbaa !266
  %85 = add nuw nsw i64 %83, 1
  %86 = icmp eq i64 %85, %14
  br i1 %86, label %91, label %82, !llvm.loop !267

87:                                               ; preds = %75, %15
  %88 = add nuw nsw i64 %17, 1
  %89 = icmp eq i64 %88, %14
  %90 = add nuw nsw i64 %16, 1
  br i1 %89, label %194, label %15, !llvm.loop !268

91:                                               ; preds = %82, %78
  %92 = getelementptr inbounds i8, ptr %4, i64 9
  %93 = load i8, ptr %92, align 1, !tbaa !269
  %94 = icmp eq i8 %93, 2
  br i1 %94, label %163, label %95

95:                                               ; preds = %91
  %96 = getelementptr inbounds i8, ptr %4, i64 88
  %97 = load ptr, ptr %96, align 8, !tbaa !270
  %98 = load ptr, ptr %97, align 8, !tbaa !215
  %99 = icmp eq ptr %98, null
  br i1 %99, label %100, label %124

100:                                              ; preds = %95
  %101 = icmp eq i8 %93, 4
  br i1 %101, label %107, label %102

102:                                              ; preds = %100
  %103 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 28), align 4, !tbaa !240
  %104 = getelementptr inbounds i8, ptr %4, i64 26
  %105 = load i8, ptr %104, align 2, !tbaa !271
  %106 = icmp eq i8 %105, 0
  br i1 %106, label %108, label %107

107:                                              ; preds = %102, %100
  br label %108

108:                                              ; preds = %107, %102
  %109 = phi i32 [ -1, %107 ], [ %103, %102 ]
  %110 = load ptr, ptr %4, align 8, !tbaa !272
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(80) %97, i8 noundef 0, i64 noundef 80, i1 noundef false) #16
  %111 = icmp eq i32 %109, 0
  br i1 %111, label %112, label %116

112:                                              ; preds = %108
  %113 = getelementptr inbounds i8, ptr %110, i64 40
  %114 = load ptr, ptr %113, align 8, !tbaa !273
  %115 = tail call i32 %114(ptr noundef %110, ptr noundef null, ptr noundef nonnull %97, i32 noundef 8222, ptr noundef null) #16
  br label %124

116:                                              ; preds = %108
  %117 = icmp sgt i32 %109, 0
  %118 = getelementptr inbounds i8, ptr %97, i64 8
  %119 = select i1 %117, i32 %109, i32 1016
  store i32 %119, ptr %118, align 8, !tbaa !274
  store ptr @MemJournalMethods, ptr %97, align 8, !tbaa !215
  %120 = getelementptr inbounds i8, ptr %97, i64 12
  store i32 %109, ptr %120, align 4, !tbaa !277
  %121 = getelementptr inbounds i8, ptr %97, i64 56
  store i32 8222, ptr %121, align 8, !tbaa !278
  %122 = getelementptr inbounds i8, ptr %97, i64 72
  store ptr null, ptr %122, align 8, !tbaa !279
  %123 = getelementptr inbounds i8, ptr %97, i64 64
  store ptr %110, ptr %123, align 8, !tbaa !280
  br label %124

124:                                              ; preds = %116, %112, %95
  %125 = phi i32 [ 0, %95 ], [ %115, %112 ], [ 0, %116 ]
  %126 = icmp eq i32 %125, 0
  br i1 %126, label %127, label %163

127:                                              ; preds = %124
  %128 = getelementptr inbounds i8, ptr %0, i64 8
  %129 = load ptr, ptr %128, align 8, !tbaa !208
  %130 = getelementptr inbounds i8, ptr %4, i64 60
  %131 = load i32, ptr %130, align 4, !tbaa !281
  %132 = zext i32 %131 to i64
  %133 = getelementptr inbounds i8, ptr %4, i64 200
  %134 = load i64, ptr %133, align 8, !tbaa !207
  %135 = add nsw i64 %134, 4
  %136 = mul nsw i64 %135, %132
  %137 = load ptr, ptr %96, align 8, !tbaa !270
  %138 = load i32, ptr %5, align 8, !tbaa !203
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #16
  %139 = lshr i32 %138, 24
  %140 = trunc nuw i32 %139 to i8
  store i8 %140, ptr %2, align 1, !tbaa !30
  %141 = lshr i32 %138, 16
  %142 = trunc i32 %141 to i8
  %143 = getelementptr inbounds i8, ptr %2, i64 1
  store i8 %142, ptr %143, align 1, !tbaa !30
  %144 = lshr i32 %138, 8
  %145 = trunc i32 %144 to i8
  %146 = getelementptr inbounds i8, ptr %2, i64 2
  store i8 %145, ptr %146, align 1, !tbaa !30
  %147 = trunc i32 %138 to i8
  %148 = getelementptr inbounds i8, ptr %2, i64 3
  store i8 %147, ptr %148, align 1, !tbaa !30
  %149 = load ptr, ptr %137, align 8, !tbaa !215
  %150 = getelementptr inbounds i8, ptr %149, i64 24
  %151 = load ptr, ptr %150, align 8, !tbaa !282
  %152 = call i32 %151(ptr noundef nonnull %137, ptr noundef nonnull %2, i32 noundef 4, i64 noundef %136) #16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #16
  %153 = icmp eq i32 %152, 0
  br i1 %153, label %154, label %163

154:                                              ; preds = %127
  %155 = load ptr, ptr %96, align 8, !tbaa !270
  %156 = load i64, ptr %133, align 8, !tbaa !207
  %157 = trunc i64 %156 to i32
  %158 = add nsw i64 %136, 4
  %159 = load ptr, ptr %155, align 8, !tbaa !215
  %160 = getelementptr inbounds i8, ptr %159, i64 24
  %161 = load ptr, ptr %160, align 8, !tbaa !282
  %162 = call i32 %161(ptr noundef nonnull %155, ptr noundef %129, i32 noundef %157, i64 noundef %158) #16
  br label %163

163:                                              ; preds = %154, %127, %124, %91
  %164 = phi i32 [ %125, %124 ], [ 0, %91 ], [ %162, %154 ], [ %152, %127 ]
  %165 = icmp eq i32 %164, 0
  br i1 %165, label %166, label %194

166:                                              ; preds = %163
  %167 = getelementptr inbounds i8, ptr %4, i64 60
  %168 = load i32, ptr %167, align 4, !tbaa !281
  %169 = add i32 %168, 1
  store i32 %169, ptr %167, align 4, !tbaa !281
  %170 = load i32, ptr %5, align 8, !tbaa !203
  %171 = load i32, ptr %7, align 8, !tbaa !204
  %172 = icmp sgt i32 %171, 0
  br i1 %172, label %173, label %194

173:                                              ; preds = %166
  %174 = getelementptr inbounds i8, ptr %4, i64 120
  br label %175

175:                                              ; preds = %188, %173
  %176 = phi i64 [ 0, %173 ], [ %190, %188 ]
  %177 = phi i32 [ 0, %173 ], [ %189, %188 ]
  %178 = load ptr, ptr %174, align 8, !tbaa !258
  %179 = getelementptr inbounds %struct.PagerSavepoint, ptr %178, i64 %176
  %180 = getelementptr inbounds i8, ptr %179, i64 24
  %181 = load i32, ptr %180, align 8, !tbaa !259
  %182 = icmp ult i32 %181, %170
  br i1 %182, label %188, label %183

183:                                              ; preds = %175
  %184 = getelementptr inbounds i8, ptr %179, i64 16
  %185 = load ptr, ptr %184, align 8, !tbaa !261
  %186 = call fastcc i32 @sqlite3BitvecSet(ptr noundef %185, i32 noundef %170)
  %187 = or i32 %186, %177
  br label %188

188:                                              ; preds = %183, %175
  %189 = phi i32 [ %187, %183 ], [ %177, %175 ]
  %190 = add nuw nsw i64 %176, 1
  %191 = load i32, ptr %7, align 8, !tbaa !204
  %192 = sext i32 %191 to i64
  %193 = icmp slt i64 %190, %192
  br i1 %193, label %175, label %194, !llvm.loop !283

194:                                              ; preds = %188, %166, %163, %87, %1
  %195 = phi i32 [ %164, %163 ], [ 0, %166 ], [ 0, %1 ], [ %189, %188 ], [ 0, %87 ]
  ret i32 %195
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @sqlite3JournalOpen(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3, i32 noundef %4) unnamed_addr #1 {
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(80) %2, i8 noundef 0, i64 noundef 80, i1 noundef false) #16
  %6 = icmp eq i32 %4, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %5
  %8 = getelementptr inbounds i8, ptr %0, i64 40
  %9 = load ptr, ptr %8, align 8, !tbaa !273
  %10 = and i32 %3, 17334143
  %11 = tail call i32 %9(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %10, ptr noundef null) #16
  br label %20

12:                                               ; preds = %5
  %13 = icmp sgt i32 %4, 0
  %14 = getelementptr inbounds i8, ptr %2, i64 8
  %15 = select i1 %13, i32 %4, i32 1016
  store i32 %15, ptr %14, align 8, !tbaa !274
  store ptr @MemJournalMethods, ptr %2, align 8, !tbaa !215
  %16 = getelementptr inbounds i8, ptr %2, i64 12
  store i32 %4, ptr %16, align 4, !tbaa !277
  %17 = getelementptr inbounds i8, ptr %2, i64 56
  store i32 %3, ptr %17, align 8, !tbaa !278
  %18 = getelementptr inbounds i8, ptr %2, i64 72
  store ptr %1, ptr %18, align 8, !tbaa !279
  %19 = getelementptr inbounds i8, ptr %2, i64 64
  store ptr %0, ptr %19, align 8, !tbaa !280
  br label %20

20:                                               ; preds = %12, %7
  %21 = phi i32 [ %11, %7 ], [ 0, %12 ]
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @sqlite3BitvecSet(ptr noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp eq ptr %0, null
  br i1 %3, label %120, label %4

4:                                                ; preds = %2
  %5 = add i32 %1, -1
  br label %6

6:                                                ; preds = %30, %4
  %7 = phi i32 [ %5, %4 ], [ %17, %30 ]
  %8 = phi ptr [ %0, %4 ], [ %32, %30 ]
  %9 = load i32, ptr %8, align 8, !tbaa !262
  %10 = icmp ugt i32 %9, 3968
  br i1 %10, label %11, label %33

11:                                               ; preds = %6
  %12 = getelementptr inbounds i8, ptr %8, i64 8
  %13 = load i32, ptr %12, align 8, !tbaa !264
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %33, label %15

15:                                               ; preds = %11
  %16 = udiv i32 %7, %13
  %17 = urem i32 %7, %13
  %18 = getelementptr inbounds i8, ptr %8, i64 16
  %19 = zext i32 %16 to i64
  %20 = getelementptr inbounds [62 x ptr], ptr %18, i64 0, i64 %19
  %21 = load ptr, ptr %20, align 8, !tbaa !30
  %22 = icmp eq ptr %21, null
  br i1 %22, label %23, label %27

23:                                               ; preds = %15
  %24 = tail call fastcc ptr @sqlite3Malloc(i64 noundef 512)
  %25 = icmp eq ptr %24, null
  br i1 %25, label %29, label %26

26:                                               ; preds = %23
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(512) %24, i8 noundef 0, i64 noundef 512, i1 noundef false) #16
  store i32 %13, ptr %24, align 8, !tbaa !262
  store ptr %24, ptr %20, align 8, !tbaa !30
  br label %27

27:                                               ; preds = %26, %15
  %28 = load ptr, ptr %20, align 8, !tbaa !30
  br label %30

29:                                               ; preds = %23
  store ptr %24, ptr %20, align 8, !tbaa !30
  br label %30

30:                                               ; preds = %29, %27
  %31 = phi i1 [ true, %27 ], [ false, %29 ]
  %32 = phi ptr [ %28, %27 ], [ %8, %29 ]
  br i1 %31, label %6, label %120, !llvm.loop !284

33:                                               ; preds = %11, %6
  %34 = icmp ult i32 %9, 3969
  %35 = getelementptr inbounds i8, ptr %8, i64 16
  br i1 %34, label %36, label %45

36:                                               ; preds = %33
  %37 = and i32 %7, 7
  %38 = shl nuw nsw i32 1, %37
  %39 = lshr i32 %7, 3
  %40 = zext nneg i32 %39 to i64
  %41 = getelementptr inbounds [496 x i8], ptr %35, i64 0, i64 %40
  %42 = load i8, ptr %41, align 1, !tbaa !30
  %43 = trunc nuw i32 %38 to i8
  %44 = or i8 %42, %43
  store i8 %44, ptr %41, align 1, !tbaa !30
  br label %120

45:                                               ; preds = %33
  %46 = add i32 %7, 1
  %47 = urem i32 %7, 124
  %48 = zext nneg i32 %47 to i64
  %49 = getelementptr inbounds [124 x i32], ptr %35, i64 0, i64 %48
  %50 = load i32, ptr %49, align 4, !tbaa !30
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %52, label %56

52:                                               ; preds = %45
  %53 = getelementptr inbounds i8, ptr %8, i64 4
  %54 = load i32, ptr %53, align 4, !tbaa !285
  %55 = icmp ult i32 %54, 123
  br i1 %55, label %113, label %70

56:                                               ; preds = %62, %45
  %57 = phi i32 [ %65, %62 ], [ %47, %45 ]
  %58 = zext i32 %57 to i64
  %59 = getelementptr inbounds [124 x i32], ptr %35, i64 0, i64 %58
  %60 = load i32, ptr %59, align 4, !tbaa !30
  %61 = icmp eq i32 %60, %46
  br i1 %61, label %120, label %62

62:                                               ; preds = %56
  %63 = add i32 %57, 1
  %64 = icmp ugt i32 %63, 123
  %65 = select i1 %64, i32 0, i32 %63
  %66 = zext i32 %65 to i64
  %67 = getelementptr inbounds [124 x i32], ptr %35, i64 0, i64 %66
  %68 = load i32, ptr %67, align 4, !tbaa !30
  %69 = icmp eq i32 %68, 0
  br i1 %69, label %70, label %56, !llvm.loop !286

70:                                               ; preds = %62, %52
  %71 = phi i32 [ %47, %52 ], [ %65, %62 ]
  %72 = getelementptr inbounds i8, ptr %8, i64 4
  %73 = load i32, ptr %72, align 4, !tbaa !285
  %74 = icmp ugt i32 %73, 61
  br i1 %74, label %75, label %113

75:                                               ; preds = %70
  %76 = tail call fastcc ptr @sqlite3Malloc(i64 noundef 496)
  %77 = icmp eq ptr %76, null
  br i1 %77, label %120, label %78

78:                                               ; preds = %75
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(496) %76, ptr noundef nonnull align 1 dereferenceable(496) %35, i64 noundef 496, i1 noundef false) #16
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(496) %35, i8 noundef 0, i64 noundef 496, i1 noundef false) #16
  %79 = load i32, ptr %8, align 8, !tbaa !262
  %80 = zext i32 %79 to i64
  %81 = add nuw nsw i64 %80, 61
  %82 = udiv i64 %81, 62
  %83 = trunc nuw nsw i64 %82 to i32
  %84 = getelementptr inbounds i8, ptr %8, i64 8
  store i32 %83, ptr %84, align 8, !tbaa !264
  %85 = tail call fastcc i32 @sqlite3BitvecSet(ptr noundef nonnull %8, i32 noundef %46)
  br label %86

86:                                               ; preds = %95, %78
  %87 = phi i64 [ 0, %78 ], [ %97, %95 ]
  %88 = phi i32 [ %85, %78 ], [ %96, %95 ]
  %89 = getelementptr inbounds i32, ptr %76, i64 %87
  %90 = load i32, ptr %89, align 4, !tbaa !86
  %91 = icmp eq i32 %90, 0
  br i1 %91, label %95, label %92

92:                                               ; preds = %86
  %93 = tail call fastcc i32 @sqlite3BitvecSet(ptr noundef nonnull %8, i32 noundef %90)
  %94 = or i32 %93, %88
  br label %95

95:                                               ; preds = %92, %86
  %96 = phi i32 [ %94, %92 ], [ %88, %86 ]
  %97 = add nuw nsw i64 %87, 1
  %98 = icmp eq i64 %97, 124
  br i1 %98, label %99, label %86, !llvm.loop !287

99:                                               ; preds = %95
  %100 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %101 = icmp eq i32 %100, 0
  br i1 %101, label %111, label %102

102:                                              ; preds = %99
  %103 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %104 = tail call i32 %103(ptr noundef nonnull %76) #16
  %105 = sext i32 %104 to i64
  %106 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %107 = sub nsw i64 %106, %105
  store i64 %107, ptr @sqlite3Stat, align 8, !tbaa !67
  %108 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %109 = add nsw i64 %108, -1
  store i64 %109, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %110 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %110(ptr noundef nonnull %76) #16
  br label %120

111:                                              ; preds = %99
  %112 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %112(ptr noundef nonnull %76) #16
  br label %120

113:                                              ; preds = %70, %52
  %114 = phi i32 [ %71, %70 ], [ %47, %52 ]
  %115 = getelementptr inbounds i8, ptr %8, i64 4
  %116 = load i32, ptr %115, align 4, !tbaa !285
  %117 = add i32 %116, 1
  store i32 %117, ptr %115, align 4, !tbaa !285
  %118 = zext i32 %114 to i64
  %119 = getelementptr inbounds [124 x i32], ptr %35, i64 0, i64 %118
  store i32 %46, ptr %119, align 4, !tbaa !30
  br label %120

120:                                              ; preds = %113, %111, %102, %75, %56, %36, %30, %2
  %121 = phi i32 [ 0, %36 ], [ 0, %113 ], [ 0, %2 ], [ 7, %75 ], [ %96, %102 ], [ %96, %111 ], [ 0, %56 ], [ 7, %30 ]
  ret i32 %121
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @backupUpdate(ptr nocapture noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2) unnamed_addr #4 {
  br label %4

4:                                                ; preds = %22, %3
  %5 = phi ptr [ %0, %3 ], [ %24, %22 ]
  %6 = getelementptr inbounds i8, ptr %5, i64 48
  %7 = load i32, ptr %6, align 8, !tbaa !288
  switch i32 %7, label %8 [
    i32 5, label %11
    i32 0, label %11
  ]

8:                                                ; preds = %4
  %9 = icmp ne i32 %7, 6
  %10 = zext i1 %9 to i32
  br label %11

11:                                               ; preds = %8, %4, %4
  %12 = phi i32 [ 0, %4 ], [ %10, %8 ], [ 0, %4 ]
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %22

14:                                               ; preds = %11
  %15 = getelementptr inbounds i8, ptr %5, i64 24
  %16 = load i32, ptr %15, align 8, !tbaa !289
  %17 = icmp ugt i32 %16, %1
  br i1 %17, label %18, label %22

18:                                               ; preds = %14
  %19 = tail call fastcc i32 @backupOnePage(ptr noundef %5, i32 noundef %1, ptr noundef %2, i32 noundef 1)
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %22, label %21

21:                                               ; preds = %18
  store i32 %19, ptr %6, align 8, !tbaa !288
  br label %22

22:                                               ; preds = %21, %18, %14, %11
  %23 = getelementptr inbounds i8, ptr %5, i64 64
  %24 = load ptr, ptr %23, align 8, !tbaa !290
  %25 = icmp eq ptr %24, null
  br i1 %25, label %26, label %4, !llvm.loop !291

26:                                               ; preds = %22
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @writeJournalHdr(ptr noundef %0) unnamed_addr #1 {
  %2 = getelementptr inbounds i8, ptr %0, i64 280
  %3 = load ptr, ptr %2, align 8, !tbaa !292
  %4 = getelementptr inbounds i8, ptr %0, i64 200
  %5 = load i64, ptr %4, align 8, !tbaa !207
  %6 = trunc i64 %5 to i32
  %7 = getelementptr inbounds i8, ptr %0, i64 184
  %8 = load i32, ptr %7, align 8, !tbaa !206
  %9 = tail call i32 @llvm.umin.i32(i32 %8, i32 %6)
  %10 = getelementptr inbounds i8, ptr %0, i64 128
  %11 = load i32, ptr %10, align 8, !tbaa !204
  %12 = icmp sgt i32 %11, 0
  br i1 %12, label %13, label %28

13:                                               ; preds = %1
  %14 = getelementptr inbounds i8, ptr %0, i64 120
  %15 = load ptr, ptr %14, align 8, !tbaa !258
  %16 = getelementptr inbounds i8, ptr %0, i64 96
  %17 = zext nneg i32 %11 to i64
  br label %18

18:                                               ; preds = %25, %13
  %19 = phi i64 [ 0, %13 ], [ %26, %25 ]
  %20 = getelementptr inbounds %struct.PagerSavepoint, ptr %15, i64 %19, i32 1
  %21 = load i64, ptr %20, align 8, !tbaa !293
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %23, label %25

23:                                               ; preds = %18
  %24 = load i64, ptr %16, align 8, !tbaa !294
  store i64 %24, ptr %20, align 8, !tbaa !293
  br label %25

25:                                               ; preds = %23, %18
  %26 = add nuw nsw i64 %19, 1
  %27 = icmp eq i64 %26, %17
  br i1 %27, label %28, label %18, !llvm.loop !295

28:                                               ; preds = %25, %1
  %29 = getelementptr inbounds i8, ptr %0, i64 96
  %30 = load i64, ptr %29, align 8, !tbaa !294
  %31 = icmp eq i64 %30, 0
  br i1 %31, label %38, label %32

32:                                               ; preds = %28
  %33 = add nsw i64 %30, -1
  %34 = zext i32 %8 to i64
  %35 = sdiv i64 %33, %34
  %36 = add nsw i64 %35, 1
  %37 = mul nsw i64 %36, %34
  br label %38

38:                                               ; preds = %32, %28
  %39 = phi i64 [ %37, %32 ], [ 0, %28 ]
  store i64 %39, ptr %29, align 8, !tbaa !294
  %40 = getelementptr inbounds i8, ptr %0, i64 104
  store i64 %39, ptr %40, align 8, !tbaa !296
  %41 = getelementptr inbounds i8, ptr %0, i64 11
  %42 = load i8, ptr %41, align 1, !tbaa !297
  %43 = icmp eq i8 %42, 0
  br i1 %43, label %44, label %59

44:                                               ; preds = %38
  %45 = getelementptr inbounds i8, ptr %0, i64 9
  %46 = load i8, ptr %45, align 1, !tbaa !269
  %47 = icmp eq i8 %46, 4
  br i1 %47, label %59, label %48

48:                                               ; preds = %44
  %49 = getelementptr inbounds i8, ptr %0, i64 72
  %50 = load ptr, ptr %49, align 8, !tbaa !214
  %51 = load ptr, ptr %50, align 8, !tbaa !215
  %52 = icmp eq ptr %51, null
  br i1 %52, label %61, label %53

53:                                               ; preds = %48
  %54 = getelementptr inbounds i8, ptr %51, i64 96
  %55 = load ptr, ptr %54, align 8, !tbaa !298
  %56 = tail call i32 %55(ptr noundef nonnull %50) #16
  %57 = and i32 %56, 512
  %58 = icmp eq i32 %57, 0
  br i1 %58, label %61, label %59

59:                                               ; preds = %53, %44, %38
  store i64 -2926318169871755815, ptr %3, align 1
  %60 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 -1, ptr %60, align 1
  br label %62

61:                                               ; preds = %53, %48
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(12) %3, i8 noundef 0, i64 noundef 12, i1 noundef false) #16
  br label %62

62:                                               ; preds = %61, %59
  %63 = getelementptr inbounds i8, ptr %0, i64 9
  %64 = load i8, ptr %63, align 1, !tbaa !269
  %65 = icmp eq i8 %64, 4
  br i1 %65, label %68, label %66

66:                                               ; preds = %62
  %67 = getelementptr inbounds i8, ptr %0, i64 56
  tail call void @sqlite3_randomness(i32 noundef 4, ptr noundef nonnull %67)
  br label %68

68:                                               ; preds = %66, %62
  %69 = getelementptr inbounds i8, ptr %3, i64 12
  %70 = getelementptr inbounds i8, ptr %0, i64 56
  %71 = load i32, ptr %70, align 8, !tbaa !299
  %72 = lshr i32 %71, 24
  %73 = trunc nuw i32 %72 to i8
  store i8 %73, ptr %69, align 1, !tbaa !30
  %74 = lshr i32 %71, 16
  %75 = trunc i32 %74 to i8
  %76 = getelementptr inbounds i8, ptr %3, i64 13
  store i8 %75, ptr %76, align 1, !tbaa !30
  %77 = lshr i32 %71, 8
  %78 = trunc i32 %77 to i8
  %79 = getelementptr inbounds i8, ptr %3, i64 14
  store i8 %78, ptr %79, align 1, !tbaa !30
  %80 = trunc i32 %71 to i8
  %81 = getelementptr inbounds i8, ptr %3, i64 15
  store i8 %80, ptr %81, align 1, !tbaa !30
  %82 = getelementptr inbounds i8, ptr %3, i64 16
  %83 = getelementptr inbounds i8, ptr %0, i64 36
  %84 = load i32, ptr %83, align 4, !tbaa !300
  %85 = lshr i32 %84, 24
  %86 = trunc nuw i32 %85 to i8
  store i8 %86, ptr %82, align 1, !tbaa !30
  %87 = lshr i32 %84, 16
  %88 = trunc i32 %87 to i8
  %89 = getelementptr inbounds i8, ptr %3, i64 17
  store i8 %88, ptr %89, align 1, !tbaa !30
  %90 = lshr i32 %84, 8
  %91 = trunc i32 %90 to i8
  %92 = getelementptr inbounds i8, ptr %3, i64 18
  store i8 %91, ptr %92, align 1, !tbaa !30
  %93 = trunc i32 %84 to i8
  %94 = getelementptr inbounds i8, ptr %3, i64 19
  store i8 %93, ptr %94, align 1, !tbaa !30
  %95 = getelementptr inbounds i8, ptr %3, i64 20
  %96 = load i32, ptr %7, align 8, !tbaa !206
  %97 = lshr i32 %96, 24
  %98 = trunc nuw i32 %97 to i8
  store i8 %98, ptr %95, align 1, !tbaa !30
  %99 = lshr i32 %96, 16
  %100 = trunc i32 %99 to i8
  %101 = getelementptr inbounds i8, ptr %3, i64 21
  store i8 %100, ptr %101, align 1, !tbaa !30
  %102 = lshr i32 %96, 8
  %103 = trunc i32 %102 to i8
  %104 = getelementptr inbounds i8, ptr %3, i64 22
  store i8 %103, ptr %104, align 1, !tbaa !30
  %105 = trunc i32 %96 to i8
  %106 = getelementptr inbounds i8, ptr %3, i64 23
  store i8 %105, ptr %106, align 1, !tbaa !30
  %107 = getelementptr inbounds i8, ptr %3, i64 24
  %108 = load i64, ptr %4, align 8, !tbaa !207
  %109 = lshr i64 %108, 24
  %110 = trunc i64 %109 to i8
  store i8 %110, ptr %107, align 1, !tbaa !30
  %111 = lshr i64 %108, 16
  %112 = trunc i64 %111 to i8
  %113 = getelementptr inbounds i8, ptr %3, i64 25
  store i8 %112, ptr %113, align 1, !tbaa !30
  %114 = lshr i64 %108, 8
  %115 = trunc i64 %114 to i8
  %116 = getelementptr inbounds i8, ptr %3, i64 26
  store i8 %115, ptr %116, align 1, !tbaa !30
  %117 = trunc i64 %108 to i8
  %118 = getelementptr inbounds i8, ptr %3, i64 27
  store i8 %117, ptr %118, align 1, !tbaa !30
  %119 = getelementptr inbounds i8, ptr %3, i64 28
  %120 = zext i32 %9 to i64
  %121 = add nsw i64 %120, -28
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 %119, i8 noundef 0, i64 noundef %121, i1 noundef false) #16
  %122 = getelementptr inbounds i8, ptr %0, i64 80
  %123 = load i32, ptr %7, align 8, !tbaa !206
  %124 = icmp eq i32 %123, 0
  br i1 %124, label %140, label %129

125:                                              ; preds = %129
  %126 = add i32 %130, %9
  %127 = load i32, ptr %7, align 8, !tbaa !206
  %128 = icmp ult i32 %126, %127
  br i1 %128, label %129, label %140, !llvm.loop !301

129:                                              ; preds = %125, %68
  %130 = phi i32 [ %126, %125 ], [ 0, %68 ]
  %131 = load ptr, ptr %122, align 8, !tbaa !302
  %132 = load i64, ptr %29, align 8, !tbaa !294
  %133 = load ptr, ptr %131, align 8, !tbaa !215
  %134 = getelementptr inbounds i8, ptr %133, i64 24
  %135 = load ptr, ptr %134, align 8, !tbaa !282
  %136 = tail call i32 %135(ptr noundef nonnull %131, ptr noundef %3, i32 noundef %9, i64 noundef %132) #16
  %137 = load i64, ptr %29, align 8, !tbaa !294
  %138 = add nsw i64 %137, %120
  store i64 %138, ptr %29, align 8, !tbaa !294
  %139 = icmp eq i32 %136, 0
  br i1 %139, label %125, label %140, !llvm.loop !301

140:                                              ; preds = %129, %125, %68
  %141 = phi i32 [ 0, %68 ], [ %136, %129 ], [ %136, %125 ]
  ret i32 %141
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc ptr @sqlite3PagerLookup(ptr nocapture noundef readonly %0, i32 noundef %1) unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %0, i64 288
  %4 = load ptr, ptr %3, align 8, !tbaa !303
  %5 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 224), align 8, !tbaa !304
  %6 = getelementptr inbounds i8, ptr %4, i64 72
  %7 = load ptr, ptr %6, align 8, !tbaa !250
  %8 = tail call ptr %5(ptr noundef %7, i32 noundef %1, i32 noundef 0) #16
  %9 = icmp eq ptr %8, null
  br i1 %9, label %25, label %10

10:                                               ; preds = %2
  %11 = load ptr, ptr %3, align 8, !tbaa !303
  %12 = getelementptr inbounds i8, ptr %8, i64 8
  %13 = load ptr, ptr %12, align 8, !tbaa !305
  %14 = load ptr, ptr %13, align 8, !tbaa !251
  %15 = icmp eq ptr %14, null
  br i1 %15, label %16, label %18

16:                                               ; preds = %10
  %17 = tail call fastcc ptr @pcacheFetchFinishWithInit(ptr noundef %11, i32 noundef %1, ptr noundef nonnull %8)
  br label %25

18:                                               ; preds = %10
  %19 = getelementptr inbounds i8, ptr %11, i64 24
  %20 = load i64, ptr %19, align 8, !tbaa !245
  %21 = add nsw i64 %20, 1
  store i64 %21, ptr %19, align 8, !tbaa !245
  %22 = getelementptr inbounds i8, ptr %13, i64 56
  %23 = load i64, ptr %22, align 8, !tbaa !247
  %24 = add nsw i64 %23, 1
  store i64 %24, ptr %22, align 8, !tbaa !247
  br label %25

25:                                               ; preds = %18, %16, %2
  %26 = phi ptr [ null, %2 ], [ %13, %18 ], [ %17, %16 ]
  ret ptr %26
}

; Function Attrs: nofree noinline nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define hidden fastcc ptr @pcacheFetchFinishWithInit(ptr noundef %0, i32 noundef %1, ptr noundef %2) unnamed_addr #10 {
  br label %4

4:                                                ; preds = %4, %3
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = load ptr, ptr %5, align 8, !tbaa !305
  %7 = getelementptr inbounds i8, ptr %6, i64 32
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(48) %7, i8 noundef 0, i64 noundef 48, i1 noundef false) #16
  store ptr %2, ptr %6, align 8, !tbaa !251
  %8 = load ptr, ptr %2, align 8, !tbaa !306
  %9 = getelementptr inbounds i8, ptr %6, i64 8
  store ptr %8, ptr %9, align 8, !tbaa !208
  %10 = getelementptr inbounds i8, ptr %6, i64 80
  %11 = getelementptr inbounds i8, ptr %6, i64 16
  store ptr %10, ptr %11, align 8, !tbaa !209
  store i64 0, ptr %10, align 1
  %12 = getelementptr inbounds i8, ptr %6, i64 24
  store ptr %0, ptr %12, align 8, !tbaa !244
  %13 = getelementptr inbounds i8, ptr %6, i64 48
  store i32 %1, ptr %13, align 8, !tbaa !203
  %14 = getelementptr inbounds i8, ptr %6, i64 52
  store i16 1, ptr %14, align 4, !tbaa !201
  %15 = load ptr, ptr %5, align 8, !tbaa !305
  %16 = load ptr, ptr %15, align 8, !tbaa !251
  %17 = icmp eq ptr %16, null
  br i1 %17, label %4, label %18

18:                                               ; preds = %4
  %19 = getelementptr inbounds i8, ptr %0, i64 24
  %20 = load i64, ptr %19, align 8, !tbaa !245
  %21 = add nsw i64 %20, 1
  store i64 %21, ptr %19, align 8, !tbaa !245
  %22 = getelementptr inbounds i8, ptr %15, i64 56
  %23 = load i64, ptr %22, align 8, !tbaa !247
  %24 = add nsw i64 %23, 1
  store i64 %24, ptr %22, align 8, !tbaa !247
  ret ptr %15
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @sqlite3BitvecDestroy(ptr noundef %0) unnamed_addr #1 {
  %2 = icmp eq ptr %0, null
  br i1 %2, label %28, label %3

3:                                                ; preds = %1
  %4 = getelementptr inbounds i8, ptr %0, i64 8
  %5 = load i32, ptr %4, align 8, !tbaa !264
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %15, label %7

7:                                                ; preds = %3
  %8 = getelementptr inbounds i8, ptr %0, i64 16
  br label %9

9:                                                ; preds = %9, %7
  %10 = phi i64 [ 0, %7 ], [ %13, %9 ]
  %11 = getelementptr inbounds [62 x ptr], ptr %8, i64 0, i64 %10
  %12 = load ptr, ptr %11, align 8, !tbaa !30
  tail call fastcc void @sqlite3BitvecDestroy(ptr noundef %12)
  %13 = add nuw nsw i64 %10, 1
  %14 = icmp eq i64 %13, 62
  br i1 %14, label %15, label %9, !llvm.loop !307

15:                                               ; preds = %9, %3
  %16 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %26, label %18

18:                                               ; preds = %15
  %19 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %20 = tail call i32 %19(ptr noundef nonnull %0) #16
  %21 = sext i32 %20 to i64
  %22 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %23 = sub nsw i64 %22, %21
  store i64 %23, ptr @sqlite3Stat, align 8, !tbaa !67
  %24 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %25 = add nsw i64 %24, -1
  store i64 %25, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  br label %26

26:                                               ; preds = %18, %15
  %27 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %27(ptr noundef nonnull %0) #16
  br label %28

28:                                               ; preds = %26, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @pager_playback_one_page(ptr noundef %0, ptr nocapture noundef %1, ptr noundef %2, i32 noundef %3, i32 noundef %4) unnamed_addr #1 {
  %6 = alloca [4 x i8], align 1
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #16
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #16
  %9 = getelementptr inbounds i8, ptr %0, i64 280
  %10 = load ptr, ptr %9, align 8, !tbaa !292
  %11 = icmp eq i32 %3, 0
  %12 = select i1 %11, i64 88, i64 80
  %13 = getelementptr inbounds i8, ptr %0, i64 %12
  %14 = load ptr, ptr %13, align 8, !tbaa !36
  %15 = load i64, ptr %1, align 8, !tbaa !67
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6) #16
  %16 = load ptr, ptr %14, align 8, !tbaa !215
  %17 = getelementptr inbounds i8, ptr %16, i64 16
  %18 = load ptr, ptr %17, align 8, !tbaa !308
  %19 = call i32 %18(ptr noundef nonnull %14, ptr noundef nonnull %6, i32 noundef 4, i64 noundef %15) #16
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %39

21:                                               ; preds = %5
  %22 = load i8, ptr %6, align 1, !tbaa !30
  %23 = zext i8 %22 to i32
  %24 = shl nuw i32 %23, 24
  %25 = getelementptr inbounds i8, ptr %6, i64 1
  %26 = load i8, ptr %25, align 1, !tbaa !30
  %27 = zext i8 %26 to i32
  %28 = shl nuw nsw i32 %27, 16
  %29 = or disjoint i32 %28, %24
  %30 = getelementptr inbounds i8, ptr %6, i64 2
  %31 = load i8, ptr %30, align 1, !tbaa !30
  %32 = zext i8 %31 to i32
  %33 = shl nuw nsw i32 %32, 8
  %34 = or disjoint i32 %29, %33
  %35 = getelementptr inbounds i8, ptr %6, i64 3
  %36 = load i8, ptr %35, align 1, !tbaa !30
  %37 = zext i8 %36 to i32
  %38 = or disjoint i32 %34, %37
  br label %39

39:                                               ; preds = %21, %5
  %40 = phi i32 [ %38, %21 ], [ undef, %5 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6) #16
  br i1 %20, label %41, label %258

41:                                               ; preds = %39
  %42 = getelementptr inbounds i8, ptr %0, i64 200
  %43 = load i64, ptr %42, align 8, !tbaa !207
  %44 = trunc i64 %43 to i32
  %45 = load i64, ptr %1, align 8, !tbaa !67
  %46 = add nsw i64 %45, 4
  %47 = load ptr, ptr %14, align 8, !tbaa !215
  %48 = getelementptr inbounds i8, ptr %47, i64 16
  %49 = load ptr, ptr %48, align 8, !tbaa !308
  %50 = call i32 %49(ptr noundef nonnull %14, ptr noundef %10, i32 noundef %44, i64 noundef %46) #16
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %52, label %258

52:                                               ; preds = %41
  %53 = load i64, ptr %42, align 8, !tbaa !207
  %54 = shl nuw nsw i32 %3, 2
  %55 = load i64, ptr %1, align 8, !tbaa !67
  %56 = add nuw i32 %54, 4
  %57 = zext i32 %56 to i64
  %58 = add i64 %53, %57
  %59 = add nsw i64 %58, %55
  store i64 %59, ptr %1, align 8, !tbaa !67
  %60 = icmp eq i32 %40, 0
  br i1 %60, label %258, label %61

61:                                               ; preds = %52
  %62 = getelementptr inbounds i8, ptr %0, i64 192
  %63 = load i32, ptr %62, align 8, !tbaa !309
  %64 = icmp eq i32 %40, %63
  br i1 %64, label %258, label %65

65:                                               ; preds = %61
  %66 = getelementptr inbounds i8, ptr %0, i64 32
  %67 = load i32, ptr %66, align 8, !tbaa !202
  %68 = icmp ugt i32 %40, %67
  br i1 %68, label %258, label %69

69:                                               ; preds = %65
  %70 = icmp eq ptr %2, null
  br i1 %70, label %123, label %71

71:                                               ; preds = %69
  %72 = add i32 %40, -1
  %73 = load i32, ptr %2, align 8, !tbaa !262
  %74 = icmp ult i32 %72, %73
  br i1 %74, label %75, label %123

75:                                               ; preds = %82, %71
  %76 = phi ptr [ %88, %82 ], [ %2, %71 ]
  %77 = phi i32 [ %84, %82 ], [ %72, %71 ]
  %78 = freeze i32 %77
  %79 = getelementptr inbounds i8, ptr %76, i64 8
  %80 = load i32, ptr %79, align 8, !tbaa !264
  %81 = icmp eq i32 %80, 0
  br i1 %81, label %90, label %82

82:                                               ; preds = %75
  %83 = udiv i32 %78, %80
  %84 = urem i32 %78, %80
  %85 = getelementptr inbounds i8, ptr %76, i64 16
  %86 = zext i32 %83 to i64
  %87 = getelementptr inbounds [62 x ptr], ptr %85, i64 0, i64 %86
  %88 = load ptr, ptr %87, align 8, !tbaa !30
  %89 = icmp eq ptr %88, null
  br i1 %89, label %123, label %75

90:                                               ; preds = %75
  %91 = load i32, ptr %76, align 8, !tbaa !262
  %92 = icmp ult i32 %91, 3969
  br i1 %92, label %93, label %103

93:                                               ; preds = %90
  %94 = getelementptr inbounds i8, ptr %76, i64 16
  %95 = lshr i32 %78, 3
  %96 = zext nneg i32 %95 to i64
  %97 = getelementptr inbounds [496 x i8], ptr %94, i64 0, i64 %96
  %98 = load i8, ptr %97, align 1, !tbaa !30
  %99 = zext i8 %98 to i32
  %100 = and i32 %78, 7
  %101 = lshr i32 %99, %100
  %102 = and i32 %101, 1
  br label %123

103:                                              ; preds = %90
  %104 = add i32 %78, 1
  %105 = urem i32 %78, 124
  %106 = getelementptr inbounds i8, ptr %76, i64 16
  %107 = zext nneg i32 %105 to i64
  %108 = getelementptr inbounds [124 x i32], ptr %106, i64 0, i64 %107
  %109 = load i32, ptr %108, align 4, !tbaa !30
  %110 = icmp eq i32 %109, 0
  br i1 %110, label %123, label %111

111:                                              ; preds = %115, %103
  %112 = phi i32 [ %121, %115 ], [ %109, %103 ]
  %113 = phi i32 [ %118, %115 ], [ %105, %103 ]
  %114 = icmp eq i32 %112, %104
  br i1 %114, label %123, label %115

115:                                              ; preds = %111
  %116 = add i32 %113, 1
  %117 = icmp eq i32 %116, 124
  %118 = select i1 %117, i32 0, i32 %116
  %119 = zext nneg i32 %118 to i64
  %120 = getelementptr inbounds [124 x i32], ptr %106, i64 0, i64 %119
  %121 = load i32, ptr %120, align 4, !tbaa !30
  %122 = icmp eq i32 %121, 0
  br i1 %122, label %123, label %111, !llvm.loop !265

123:                                              ; preds = %115, %111, %103, %93, %82, %71, %69
  %124 = phi i32 [ 0, %69 ], [ %102, %93 ], [ 0, %71 ], [ 0, %103 ], [ 1, %111 ], [ 0, %115 ], [ 0, %82 ]
  %125 = icmp eq i32 %124, 0
  br i1 %125, label %126, label %258

126:                                              ; preds = %123
  br i1 %11, label %155, label %127

127:                                              ; preds = %126
  %128 = add nsw i64 %59, -4
  %129 = call fastcc i32 @read32bits(ptr noundef nonnull %14, i64 noundef %128, ptr noundef nonnull %8)
  %130 = icmp eq i32 %129, 0
  br i1 %130, label %131, label %258

131:                                              ; preds = %127
  %132 = icmp eq i32 %4, 0
  br i1 %132, label %133, label %155

133:                                              ; preds = %131
  %134 = getelementptr inbounds i8, ptr %0, i64 56
  %135 = load i32, ptr %134, align 8, !tbaa !299
  %136 = load i64, ptr %42, align 8, !tbaa !207
  %137 = trunc i64 %136 to i32
  %138 = add i32 %137, -200
  %139 = icmp sgt i32 %138, 0
  br i1 %139, label %140, label %151

140:                                              ; preds = %133
  %141 = zext nneg i32 %138 to i64
  br label %142

142:                                              ; preds = %142, %140
  %143 = phi i64 [ %141, %140 ], [ %149, %142 ]
  %144 = phi i32 [ %135, %140 ], [ %148, %142 ]
  %145 = getelementptr inbounds i8, ptr %10, i64 %143
  %146 = load i8, ptr %145, align 1, !tbaa !30
  %147 = zext i8 %146 to i32
  %148 = add i32 %144, %147
  %149 = add nsw i64 %143, -200
  %150 = icmp sgt i64 %143, 200
  br i1 %150, label %142, label %151, !llvm.loop !310

151:                                              ; preds = %142, %133
  %152 = phi i32 [ %135, %133 ], [ %148, %142 ]
  %153 = load i32, ptr %8, align 4, !tbaa !86
  %154 = icmp eq i32 %152, %153
  br i1 %154, label %155, label %258

155:                                              ; preds = %151, %131, %126
  br i1 %70, label %159, label %156

156:                                              ; preds = %155
  %157 = call fastcc i32 @sqlite3BitvecSet(ptr noundef nonnull %2, i32 noundef %40)
  %158 = icmp eq i32 %157, 0
  br i1 %158, label %159, label %258

159:                                              ; preds = %156, %155
  %160 = icmp eq i32 %40, 1
  br i1 %160, label %161, label %171

161:                                              ; preds = %159
  %162 = getelementptr inbounds i8, ptr %0, i64 178
  %163 = load i16, ptr %162, align 2, !tbaa !311
  %164 = sext i16 %163 to i32
  %165 = getelementptr inbounds i8, ptr %10, i64 20
  %166 = load i8, ptr %165, align 1, !tbaa !30
  %167 = zext i8 %166 to i32
  %168 = icmp eq i32 %164, %167
  br i1 %168, label %171, label %169

169:                                              ; preds = %161
  %170 = zext i8 %166 to i16
  store i16 %170, ptr %162, align 2, !tbaa !311
  br label %171

171:                                              ; preds = %169, %161, %159
  %172 = getelementptr inbounds i8, ptr %0, i64 296
  %173 = load ptr, ptr %172, align 8, !tbaa !312
  %174 = icmp eq ptr %173, null
  br i1 %174, label %175, label %177

175:                                              ; preds = %171
  %176 = call fastcc ptr @sqlite3PagerLookup(ptr noundef %0, i32 noundef %40)
  br label %177

177:                                              ; preds = %175, %171
  %178 = phi ptr [ %176, %175 ], [ null, %171 ]
  store ptr %178, ptr %7, align 8, !tbaa !36
  br i1 %11, label %188, label %179

179:                                              ; preds = %177
  %180 = getelementptr inbounds i8, ptr %0, i64 11
  %181 = load i8, ptr %180, align 1, !tbaa !297
  %182 = icmp eq i8 %181, 0
  br i1 %182, label %183, label %195

183:                                              ; preds = %179
  %184 = load i64, ptr %1, align 8, !tbaa !67
  %185 = getelementptr inbounds i8, ptr %0, i64 104
  %186 = load i64, ptr %185, align 8, !tbaa !296
  %187 = icmp sle i64 %184, %186
  br label %195

188:                                              ; preds = %177
  %189 = icmp eq ptr %178, null
  br i1 %189, label %195, label %190

190:                                              ; preds = %188
  %191 = getelementptr inbounds i8, ptr %178, i64 52
  %192 = load i16, ptr %191, align 4, !tbaa !201
  %193 = and i16 %192, 8
  %194 = icmp eq i16 %193, 0
  br label %195

195:                                              ; preds = %190, %188, %183, %179
  %196 = phi i1 [ true, %179 ], [ %187, %183 ], [ true, %188 ], [ %194, %190 ]
  %197 = getelementptr inbounds i8, ptr %0, i64 72
  %198 = load ptr, ptr %197, align 8, !tbaa !214
  %199 = load ptr, ptr %198, align 8, !tbaa !215
  %200 = icmp eq ptr %199, null
  br i1 %200, label %227, label %201

201:                                              ; preds = %195
  %202 = getelementptr inbounds i8, ptr %0, i64 21
  %203 = load i8, ptr %202, align 1, !tbaa !313
  %204 = icmp ugt i8 %203, 3
  br i1 %204, label %208, label %205

205:                                              ; preds = %201
  %206 = icmp eq i8 %203, 0
  %207 = select i1 %206, i1 %196, i1 false
  br i1 %207, label %209, label %227

208:                                              ; preds = %201
  br i1 %196, label %209, label %227

209:                                              ; preds = %208, %205
  %210 = add i32 %40, -1
  %211 = zext i32 %210 to i64
  %212 = load i64, ptr %42, align 8, !tbaa !207
  %213 = mul nsw i64 %212, %211
  %214 = trunc i64 %212 to i32
  %215 = getelementptr inbounds i8, ptr %199, i64 24
  %216 = load ptr, ptr %215, align 8, !tbaa !282
  %217 = call i32 %216(ptr noundef nonnull %198, ptr noundef %10, i32 noundef %214, i64 noundef %213) #16
  %218 = getelementptr inbounds i8, ptr %0, i64 40
  %219 = load i32, ptr %218, align 8, !tbaa !314
  %220 = icmp ugt i32 %40, %219
  br i1 %220, label %221, label %222

221:                                              ; preds = %209
  store i32 %40, ptr %218, align 8, !tbaa !314
  br label %222

222:                                              ; preds = %221, %209
  %223 = getelementptr inbounds i8, ptr %0, i64 112
  %224 = load ptr, ptr %223, align 8, !tbaa !315
  %225 = icmp eq ptr %224, null
  br i1 %225, label %242, label %226

226:                                              ; preds = %222
  call fastcc void @backupUpdate(ptr noundef nonnull %224, i32 noundef %40, ptr noundef readonly %10)
  br label %242

227:                                              ; preds = %208, %205, %195
  %228 = icmp eq ptr %178, null
  %229 = select i1 %11, i1 %228, i1 false
  br i1 %229, label %230, label %242

230:                                              ; preds = %227
  %231 = getelementptr inbounds i8, ptr %0, i64 25
  %232 = load i8, ptr %231, align 1, !tbaa !316
  %233 = or i8 %232, 2
  store i8 %233, ptr %231, align 1, !tbaa !316
  %234 = getelementptr inbounds i8, ptr %0, i64 272
  %235 = load ptr, ptr %234, align 8, !tbaa !197
  %236 = call i32 %235(ptr noundef %0, i32 noundef %40, ptr noundef nonnull %7, i32 noundef 1) #16
  %237 = load i8, ptr %231, align 1, !tbaa !316
  %238 = and i8 %237, -3
  store i8 %238, ptr %231, align 1, !tbaa !316
  %239 = icmp eq i32 %236, 0
  br i1 %239, label %240, label %258

240:                                              ; preds = %230
  %241 = load ptr, ptr %7, align 8, !tbaa !36
  call fastcc void @sqlite3PcacheMakeDirty(ptr noundef %241)
  br label %242

242:                                              ; preds = %240, %227, %226, %222
  %243 = phi i32 [ 0, %240 ], [ 0, %227 ], [ %217, %226 ], [ %217, %222 ]
  %244 = load ptr, ptr %7, align 8, !tbaa !36
  %245 = icmp eq ptr %244, null
  br i1 %245, label %258, label %246

246:                                              ; preds = %242
  %247 = getelementptr inbounds i8, ptr %244, i64 8
  %248 = load ptr, ptr %247, align 8, !tbaa !208
  %249 = load i64, ptr %42, align 8, !tbaa !207
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %248, ptr noundef align 1 %10, i64 noundef %249, i1 noundef false) #16
  %250 = getelementptr inbounds i8, ptr %0, i64 264
  %251 = load ptr, ptr %250, align 8, !tbaa !317
  %252 = load ptr, ptr %7, align 8, !tbaa !36
  call void %251(ptr noundef %252) #16
  br i1 %160, label %253, label %256

253:                                              ; preds = %246
  %254 = getelementptr inbounds i8, ptr %0, i64 136
  %255 = getelementptr inbounds i8, ptr %248, i64 24
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %254, ptr noundef nonnull align 1 dereferenceable(16) %255, i64 noundef 16, i1 noundef false) #16
  br label %256

256:                                              ; preds = %253, %246
  %257 = load ptr, ptr %7, align 8, !tbaa !36
  call fastcc void @sqlite3PcacheRelease(ptr noundef %257)
  br label %258

258:                                              ; preds = %256, %242, %230, %156, %151, %127, %123, %65, %61, %52, %41, %39
  %259 = phi i32 [ %19, %39 ], [ %50, %41 ], [ 101, %61 ], [ 101, %52 ], [ 0, %123 ], [ 0, %65 ], [ %129, %127 ], [ 101, %151 ], [ %157, %156 ], [ %236, %230 ], [ %243, %256 ], [ %243, %242 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #16
  ret i32 %259
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @read32bits(ptr noundef %0, i64 noundef %1, ptr nocapture noundef writeonly %2) unnamed_addr #1 {
  %4 = alloca [4 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #16
  %5 = load ptr, ptr %0, align 8, !tbaa !215
  %6 = getelementptr inbounds i8, ptr %5, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !308
  %8 = call i32 %7(ptr noundef nonnull %0, ptr noundef nonnull %4, i32 noundef 4, i64 noundef %1) #16
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %28

10:                                               ; preds = %3
  %11 = load i8, ptr %4, align 1, !tbaa !30
  %12 = zext i8 %11 to i32
  %13 = shl nuw i32 %12, 24
  %14 = getelementptr inbounds i8, ptr %4, i64 1
  %15 = load i8, ptr %14, align 1, !tbaa !30
  %16 = zext i8 %15 to i32
  %17 = shl nuw nsw i32 %16, 16
  %18 = or disjoint i32 %17, %13
  %19 = getelementptr inbounds i8, ptr %4, i64 2
  %20 = load i8, ptr %19, align 1, !tbaa !30
  %21 = zext i8 %20 to i32
  %22 = shl nuw nsw i32 %21, 8
  %23 = or disjoint i32 %18, %22
  %24 = getelementptr inbounds i8, ptr %4, i64 3
  %25 = load i8, ptr %24, align 1, !tbaa !30
  %26 = zext i8 %25 to i32
  %27 = or disjoint i32 %23, %26
  store i32 %27, ptr %2, align 4, !tbaa !86
  br label %28

28:                                               ; preds = %10, %3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #16
  ret i32 %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, inaccessiblemem: none) uwtable
define hidden fastcc void @sqlite3PcacheMakeDirty(ptr noundef %0) unnamed_addr #11 {
  %2 = getelementptr inbounds i8, ptr %0, i64 52
  %3 = load i16, ptr %2, align 4, !tbaa !201
  %4 = and i16 %3, 17
  %5 = icmp eq i16 %4, 0
  br i1 %5, label %35, label %6

6:                                                ; preds = %1
  %7 = and i16 %3, -17
  store i16 %7, ptr %2, align 4, !tbaa !201
  %8 = and i16 %3, 1
  %9 = icmp eq i16 %8, 0
  br i1 %9, label %35, label %10

10:                                               ; preds = %6
  %11 = xor i16 %7, 3
  store i16 %11, ptr %2, align 4, !tbaa !201
  %12 = getelementptr inbounds i8, ptr %0, i64 24
  %13 = load ptr, ptr %12, align 8, !tbaa !244
  %14 = getelementptr inbounds i8, ptr %0, i64 72
  store ptr null, ptr %14, align 8, !tbaa !253
  %15 = load ptr, ptr %13, align 8, !tbaa !255
  %16 = getelementptr inbounds i8, ptr %0, i64 64
  store ptr %15, ptr %16, align 8, !tbaa !254
  %17 = icmp eq ptr %15, null
  br i1 %17, label %20, label %18

18:                                               ; preds = %10
  %19 = getelementptr inbounds i8, ptr %15, i64 72
  store ptr %0, ptr %19, align 8, !tbaa !253
  br label %27

20:                                               ; preds = %10
  %21 = getelementptr inbounds i8, ptr %13, i64 8
  store ptr %0, ptr %21, align 8, !tbaa !257
  %22 = getelementptr inbounds i8, ptr %13, i64 48
  %23 = load i8, ptr %22, align 8, !tbaa !248
  %24 = icmp eq i8 %23, 0
  br i1 %24, label %27, label %25

25:                                               ; preds = %20
  %26 = getelementptr inbounds i8, ptr %13, i64 49
  store i8 1, ptr %26, align 1, !tbaa !256
  br label %27

27:                                               ; preds = %25, %20, %18
  store ptr %0, ptr %13, align 8, !tbaa !255
  %28 = getelementptr inbounds i8, ptr %13, i64 16
  %29 = load ptr, ptr %28, align 8, !tbaa !252
  %30 = icmp eq ptr %29, null
  %31 = and i16 %3, 8
  %32 = icmp eq i16 %31, 0
  %33 = and i1 %32, %30
  br i1 %33, label %34, label %35

34:                                               ; preds = %27
  store ptr %0, ptr %28, align 8, !tbaa !252
  br label %35

35:                                               ; preds = %34, %27, %6, %1
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc range(i32 13, 12) i32 @databaseIsUnmoved(ptr nocapture noundef readonly %0) unnamed_addr #1 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #16
  store i32 0, ptr %2, align 4, !tbaa !86
  %3 = getelementptr inbounds i8, ptr %0, i64 16
  %4 = load i8, ptr %3, align 8, !tbaa !318
  %5 = icmp eq i8 %4, 0
  br i1 %5, label %6, label %28

6:                                                ; preds = %1
  %7 = getelementptr inbounds i8, ptr %0, i64 32
  %8 = load i32, ptr %7, align 8, !tbaa !202
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %28, label %10

10:                                               ; preds = %6
  %11 = getelementptr inbounds i8, ptr %0, i64 72
  %12 = load ptr, ptr %11, align 8, !tbaa !214
  %13 = load ptr, ptr %12, align 8, !tbaa !215
  %14 = icmp eq ptr %13, null
  br i1 %14, label %19, label %15

15:                                               ; preds = %10
  %16 = getelementptr inbounds i8, ptr %13, i64 80
  %17 = load ptr, ptr %16, align 8, !tbaa !319
  %18 = call i32 %17(ptr noundef nonnull %12, i32 noundef 20, ptr noundef nonnull %2) #16
  br label %19

19:                                               ; preds = %15, %10
  %20 = phi i32 [ %18, %15 ], [ 12, %10 ]
  %21 = icmp eq i32 %20, 12
  br i1 %21, label %28, label %22

22:                                               ; preds = %19
  %23 = icmp eq i32 %20, 0
  %24 = load i32, ptr %2, align 4
  %25 = icmp ne i32 %24, 0
  %26 = select i1 %23, i1 %25, i1 false
  %27 = select i1 %26, i32 1032, i32 %20
  br label %28

28:                                               ; preds = %22, %19, %6, %1
  %29 = phi i32 [ 0, %1 ], [ 0, %6 ], [ %27, %22 ], [ 0, %19 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #16
  ret i32 %29
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc i32 @pagerWriteLargeSector(ptr nocapture noundef readonly %0) unnamed_addr #4 {
  %2 = alloca ptr, align 8
  %3 = getelementptr inbounds i8, ptr %0, i64 40
  %4 = load ptr, ptr %3, align 8, !tbaa !199
  %5 = getelementptr inbounds i8, ptr %4, i64 184
  %6 = load i32, ptr %5, align 8, !tbaa !206
  %7 = zext i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %4, i64 200
  %9 = load i64, ptr %8, align 8, !tbaa !207
  %10 = sdiv i64 %7, %9
  %11 = trunc i64 %10 to i32
  %12 = getelementptr inbounds i8, ptr %4, i64 25
  %13 = load i8, ptr %12, align 1, !tbaa !316
  %14 = or i8 %13, 4
  store i8 %14, ptr %12, align 1, !tbaa !316
  %15 = getelementptr inbounds i8, ptr %0, i64 48
  %16 = load i32, ptr %15, align 8, !tbaa !203
  %17 = add i32 %16, -1
  %18 = sub i32 0, %11
  %19 = and i32 %17, %18
  %20 = add i32 %19, 1
  %21 = getelementptr inbounds i8, ptr %4, i64 32
  %22 = load i32, ptr %21, align 8, !tbaa !202
  %23 = icmp ugt i32 %16, %22
  br i1 %23, label %24, label %26

24:                                               ; preds = %1
  %25 = sub i32 %16, %19
  br label %31

26:                                               ; preds = %1
  %27 = add i32 %19, %11
  %28 = icmp ugt i32 %27, %22
  %29 = sub i32 %22, %19
  %30 = select i1 %28, i32 %29, i32 %11
  br label %31

31:                                               ; preds = %26, %24
  %32 = phi i32 [ %25, %24 ], [ %30, %26 ]
  %33 = icmp sgt i32 %32, 0
  br i1 %33, label %34, label %214

34:                                               ; preds = %31
  %35 = getelementptr inbounds i8, ptr %4, i64 64
  %36 = getelementptr inbounds i8, ptr %4, i64 288
  %37 = getelementptr inbounds i8, ptr %4, i64 192
  %38 = getelementptr inbounds i8, ptr %4, i64 272
  br label %39

39:                                               ; preds = %204, %34
  %40 = phi i32 [ 0, %34 ], [ %207, %204 ]
  %41 = phi i32 [ 0, %34 ], [ %205, %204 ]
  %42 = add i32 %40, %20
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #16
  %43 = load i32, ptr %15, align 8, !tbaa !203
  %44 = icmp eq i32 %42, %43
  br i1 %44, label %103, label %45

45:                                               ; preds = %39
  %46 = load ptr, ptr %35, align 8, !tbaa !320
  %47 = icmp eq ptr %46, null
  br i1 %47, label %100, label %48

48:                                               ; preds = %45
  %49 = add i32 %40, %19
  %50 = load i32, ptr %46, align 8, !tbaa !262
  %51 = icmp ult i32 %49, %50
  br i1 %51, label %52, label %100

52:                                               ; preds = %59, %48
  %53 = phi ptr [ %65, %59 ], [ %46, %48 ]
  %54 = phi i32 [ %61, %59 ], [ %49, %48 ]
  %55 = freeze i32 %54
  %56 = getelementptr inbounds i8, ptr %53, i64 8
  %57 = load i32, ptr %56, align 8, !tbaa !264
  %58 = icmp eq i32 %57, 0
  br i1 %58, label %67, label %59

59:                                               ; preds = %52
  %60 = udiv i32 %55, %57
  %61 = urem i32 %55, %57
  %62 = getelementptr inbounds i8, ptr %53, i64 16
  %63 = zext i32 %60 to i64
  %64 = getelementptr inbounds [62 x ptr], ptr %62, i64 0, i64 %63
  %65 = load ptr, ptr %64, align 8, !tbaa !30
  %66 = icmp eq ptr %65, null
  br i1 %66, label %100, label %52

67:                                               ; preds = %52
  %68 = load i32, ptr %53, align 8, !tbaa !262
  %69 = icmp ult i32 %68, 3969
  br i1 %69, label %70, label %80

70:                                               ; preds = %67
  %71 = getelementptr inbounds i8, ptr %53, i64 16
  %72 = lshr i32 %55, 3
  %73 = zext nneg i32 %72 to i64
  %74 = getelementptr inbounds [496 x i8], ptr %71, i64 0, i64 %73
  %75 = load i8, ptr %74, align 1, !tbaa !30
  %76 = zext i8 %75 to i32
  %77 = and i32 %55, 7
  %78 = lshr i32 %76, %77
  %79 = and i32 %78, 1
  br label %100

80:                                               ; preds = %67
  %81 = add i32 %55, 1
  %82 = urem i32 %55, 124
  %83 = getelementptr inbounds i8, ptr %53, i64 16
  %84 = zext nneg i32 %82 to i64
  %85 = getelementptr inbounds [124 x i32], ptr %83, i64 0, i64 %84
  %86 = load i32, ptr %85, align 4, !tbaa !30
  %87 = icmp eq i32 %86, 0
  br i1 %87, label %100, label %88

88:                                               ; preds = %92, %80
  %89 = phi i32 [ %98, %92 ], [ %86, %80 ]
  %90 = phi i32 [ %95, %92 ], [ %82, %80 ]
  %91 = icmp eq i32 %89, %81
  br i1 %91, label %100, label %92

92:                                               ; preds = %88
  %93 = add i32 %90, 1
  %94 = icmp eq i32 %93, 124
  %95 = select i1 %94, i32 0, i32 %93
  %96 = zext nneg i32 %95 to i64
  %97 = getelementptr inbounds [124 x i32], ptr %83, i64 0, i64 %96
  %98 = load i32, ptr %97, align 4, !tbaa !30
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %100, label %88, !llvm.loop !265

100:                                              ; preds = %92, %88, %80, %70, %59, %48, %45
  %101 = phi i32 [ 0, %45 ], [ %79, %70 ], [ 0, %48 ], [ 0, %80 ], [ 1, %88 ], [ 0, %92 ], [ 0, %59 ]
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %103, label %146

103:                                              ; preds = %100, %39
  %104 = load i32, ptr %37, align 8, !tbaa !309
  %105 = icmp eq i32 %42, %104
  br i1 %105, label %204, label %106

106:                                              ; preds = %103
  %107 = load ptr, ptr %38, align 8, !tbaa !197
  %108 = call i32 %107(ptr noundef %4, i32 noundef %42, ptr noundef nonnull %2, i32 noundef 0) #16
  %109 = icmp eq i32 %108, 0
  br i1 %109, label %110, label %204

110:                                              ; preds = %106
  %111 = load ptr, ptr %2, align 8, !tbaa !36
  %112 = call fastcc i32 @pager_write(ptr noundef %111)
  %113 = load ptr, ptr %2, align 8, !tbaa !36
  %114 = getelementptr inbounds i8, ptr %113, i64 52
  %115 = load i16, ptr %114, align 4, !tbaa !201
  %116 = and i16 %115, 8
  %117 = icmp eq i16 %116, 0
  %118 = select i1 %117, i32 %41, i32 1
  %119 = and i16 %115, 32
  %120 = icmp eq i16 %119, 0
  br i1 %120, label %145, label %121

121:                                              ; preds = %110
  %122 = getelementptr inbounds i8, ptr %113, i64 40
  %123 = load ptr, ptr %122, align 8, !tbaa !199
  %124 = getelementptr inbounds i8, ptr %123, i64 152
  %125 = load i32, ptr %124, align 8, !tbaa !211
  %126 = add nsw i32 %125, -1
  store i32 %126, ptr %124, align 8, !tbaa !211
  %127 = getelementptr inbounds i8, ptr %123, i64 168
  %128 = load ptr, ptr %127, align 8, !tbaa !212
  %129 = getelementptr inbounds i8, ptr %113, i64 32
  store ptr %128, ptr %129, align 8, !tbaa !213
  store ptr %113, ptr %127, align 8, !tbaa !212
  %130 = getelementptr inbounds i8, ptr %123, i64 72
  %131 = load ptr, ptr %130, align 8, !tbaa !214
  %132 = getelementptr inbounds i8, ptr %113, i64 48
  %133 = load i32, ptr %132, align 8, !tbaa !203
  %134 = add i32 %133, -1
  %135 = zext i32 %134 to i64
  %136 = getelementptr inbounds i8, ptr %123, i64 200
  %137 = load i64, ptr %136, align 8, !tbaa !207
  %138 = mul nsw i64 %137, %135
  %139 = getelementptr inbounds i8, ptr %113, i64 8
  %140 = load ptr, ptr %139, align 8, !tbaa !208
  %141 = load ptr, ptr %131, align 8, !tbaa !215
  %142 = getelementptr inbounds i8, ptr %141, i64 144
  %143 = load ptr, ptr %142, align 8, !tbaa !217
  %144 = call i32 %143(ptr noundef nonnull %131, i64 noundef %138, ptr noundef %140) #16
  br label %204

145:                                              ; preds = %110
  call fastcc void @sqlite3PcacheRelease(ptr noundef %113)
  br label %204

146:                                              ; preds = %100
  %147 = load ptr, ptr %36, align 8, !tbaa !303
  %148 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 224), align 8, !tbaa !304
  %149 = getelementptr inbounds i8, ptr %147, i64 72
  %150 = load ptr, ptr %149, align 8, !tbaa !250
  %151 = call ptr %148(ptr noundef %150, i32 noundef %42, i32 noundef 0) #16
  %152 = icmp eq ptr %151, null
  br i1 %152, label %168, label %153

153:                                              ; preds = %146
  %154 = load ptr, ptr %36, align 8, !tbaa !303
  %155 = getelementptr inbounds i8, ptr %151, i64 8
  %156 = load ptr, ptr %155, align 8, !tbaa !305
  %157 = load ptr, ptr %156, align 8, !tbaa !251
  %158 = icmp eq ptr %157, null
  br i1 %158, label %159, label %161

159:                                              ; preds = %153
  %160 = call fastcc ptr @pcacheFetchFinishWithInit(ptr noundef %154, i32 noundef %42, ptr noundef nonnull %151)
  br label %168

161:                                              ; preds = %153
  %162 = getelementptr inbounds i8, ptr %154, i64 24
  %163 = load i64, ptr %162, align 8, !tbaa !245
  %164 = add nsw i64 %163, 1
  store i64 %164, ptr %162, align 8, !tbaa !245
  %165 = getelementptr inbounds i8, ptr %156, i64 56
  %166 = load i64, ptr %165, align 8, !tbaa !247
  %167 = add nsw i64 %166, 1
  store i64 %167, ptr %165, align 8, !tbaa !247
  br label %168

168:                                              ; preds = %161, %159, %146
  %169 = phi ptr [ null, %146 ], [ %156, %161 ], [ %160, %159 ]
  store ptr %169, ptr %2, align 8, !tbaa !36
  %170 = icmp eq ptr %169, null
  br i1 %170, label %204, label %171

171:                                              ; preds = %168
  %172 = getelementptr inbounds i8, ptr %169, i64 52
  %173 = load i16, ptr %172, align 4, !tbaa !201
  %174 = and i16 %173, 8
  %175 = icmp eq i16 %174, 0
  %176 = select i1 %175, i32 %41, i32 1
  %177 = and i16 %173, 32
  %178 = icmp eq i16 %177, 0
  br i1 %178, label %203, label %179

179:                                              ; preds = %171
  %180 = getelementptr inbounds i8, ptr %169, i64 40
  %181 = load ptr, ptr %180, align 8, !tbaa !199
  %182 = getelementptr inbounds i8, ptr %181, i64 152
  %183 = load i32, ptr %182, align 8, !tbaa !211
  %184 = add nsw i32 %183, -1
  store i32 %184, ptr %182, align 8, !tbaa !211
  %185 = getelementptr inbounds i8, ptr %181, i64 168
  %186 = load ptr, ptr %185, align 8, !tbaa !212
  %187 = getelementptr inbounds i8, ptr %169, i64 32
  store ptr %186, ptr %187, align 8, !tbaa !213
  store ptr %169, ptr %185, align 8, !tbaa !212
  %188 = getelementptr inbounds i8, ptr %181, i64 72
  %189 = load ptr, ptr %188, align 8, !tbaa !214
  %190 = getelementptr inbounds i8, ptr %169, i64 48
  %191 = load i32, ptr %190, align 8, !tbaa !203
  %192 = add i32 %191, -1
  %193 = zext i32 %192 to i64
  %194 = getelementptr inbounds i8, ptr %181, i64 200
  %195 = load i64, ptr %194, align 8, !tbaa !207
  %196 = mul nsw i64 %195, %193
  %197 = getelementptr inbounds i8, ptr %169, i64 8
  %198 = load ptr, ptr %197, align 8, !tbaa !208
  %199 = load ptr, ptr %189, align 8, !tbaa !215
  %200 = getelementptr inbounds i8, ptr %199, i64 144
  %201 = load ptr, ptr %200, align 8, !tbaa !217
  %202 = call i32 %201(ptr noundef nonnull %189, i64 noundef %196, ptr noundef %198) #16
  br label %204

203:                                              ; preds = %171
  call fastcc void @sqlite3PcacheRelease(ptr noundef nonnull %169)
  br label %204

204:                                              ; preds = %203, %179, %168, %145, %121, %106, %103
  %205 = phi i32 [ %41, %106 ], [ %41, %103 ], [ %41, %168 ], [ %118, %121 ], [ %118, %145 ], [ %176, %179 ], [ %176, %203 ]
  %206 = phi i32 [ %108, %106 ], [ 0, %103 ], [ 0, %168 ], [ %112, %121 ], [ %112, %145 ], [ 0, %179 ], [ 0, %203 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #16
  %207 = add nuw nsw i32 %40, 1
  %208 = icmp slt i32 %207, %32
  %209 = icmp eq i32 %206, 0
  %210 = select i1 %208, i1 %209, i1 false
  br i1 %210, label %39, label %211, !llvm.loop !321

211:                                              ; preds = %204
  %212 = icmp ne i32 %205, 0
  %213 = select i1 %209, i1 %212, i1 false
  br label %214

214:                                              ; preds = %211, %31
  %215 = phi i32 [ 0, %31 ], [ %206, %211 ]
  %216 = phi i1 [ false, %31 ], [ %213, %211 ]
  %217 = icmp sgt i32 %32, 0
  %218 = and i1 %216, %217
  br i1 %218, label %219, label %282

219:                                              ; preds = %214
  %220 = getelementptr inbounds i8, ptr %4, i64 288
  br label %221

221:                                              ; preds = %279, %219
  %222 = phi i32 [ 0, %219 ], [ %280, %279 ]
  %223 = add i32 %222, %20
  %224 = load ptr, ptr %220, align 8, !tbaa !303
  %225 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 224), align 8, !tbaa !304
  %226 = getelementptr inbounds i8, ptr %224, i64 72
  %227 = load ptr, ptr %226, align 8, !tbaa !250
  %228 = call ptr %225(ptr noundef %227, i32 noundef %223, i32 noundef 0) #16
  %229 = icmp eq ptr %228, null
  br i1 %229, label %245, label %230

230:                                              ; preds = %221
  %231 = load ptr, ptr %220, align 8, !tbaa !303
  %232 = getelementptr inbounds i8, ptr %228, i64 8
  %233 = load ptr, ptr %232, align 8, !tbaa !305
  %234 = load ptr, ptr %233, align 8, !tbaa !251
  %235 = icmp eq ptr %234, null
  br i1 %235, label %236, label %238

236:                                              ; preds = %230
  %237 = call fastcc ptr @pcacheFetchFinishWithInit(ptr noundef %231, i32 noundef %223, ptr noundef nonnull %228)
  br label %245

238:                                              ; preds = %230
  %239 = getelementptr inbounds i8, ptr %231, i64 24
  %240 = load i64, ptr %239, align 8, !tbaa !245
  %241 = add nsw i64 %240, 1
  store i64 %241, ptr %239, align 8, !tbaa !245
  %242 = getelementptr inbounds i8, ptr %233, i64 56
  %243 = load i64, ptr %242, align 8, !tbaa !247
  %244 = add nsw i64 %243, 1
  store i64 %244, ptr %242, align 8, !tbaa !247
  br label %245

245:                                              ; preds = %238, %236, %221
  %246 = phi ptr [ null, %221 ], [ %233, %238 ], [ %237, %236 ]
  %247 = icmp eq ptr %246, null
  br i1 %247, label %279, label %248

248:                                              ; preds = %245
  %249 = getelementptr inbounds i8, ptr %246, i64 52
  %250 = load i16, ptr %249, align 4, !tbaa !201
  %251 = or i16 %250, 8
  store i16 %251, ptr %249, align 4, !tbaa !201
  %252 = and i16 %250, 32
  %253 = icmp eq i16 %252, 0
  br i1 %253, label %278, label %254

254:                                              ; preds = %248
  %255 = getelementptr inbounds i8, ptr %246, i64 40
  %256 = load ptr, ptr %255, align 8, !tbaa !199
  %257 = getelementptr inbounds i8, ptr %256, i64 152
  %258 = load i32, ptr %257, align 8, !tbaa !211
  %259 = add nsw i32 %258, -1
  store i32 %259, ptr %257, align 8, !tbaa !211
  %260 = getelementptr inbounds i8, ptr %256, i64 168
  %261 = load ptr, ptr %260, align 8, !tbaa !212
  %262 = getelementptr inbounds i8, ptr %246, i64 32
  store ptr %261, ptr %262, align 8, !tbaa !213
  store ptr %246, ptr %260, align 8, !tbaa !212
  %263 = getelementptr inbounds i8, ptr %256, i64 72
  %264 = load ptr, ptr %263, align 8, !tbaa !214
  %265 = getelementptr inbounds i8, ptr %246, i64 48
  %266 = load i32, ptr %265, align 8, !tbaa !203
  %267 = add i32 %266, -1
  %268 = zext i32 %267 to i64
  %269 = getelementptr inbounds i8, ptr %256, i64 200
  %270 = load i64, ptr %269, align 8, !tbaa !207
  %271 = mul nsw i64 %270, %268
  %272 = getelementptr inbounds i8, ptr %246, i64 8
  %273 = load ptr, ptr %272, align 8, !tbaa !208
  %274 = load ptr, ptr %264, align 8, !tbaa !215
  %275 = getelementptr inbounds i8, ptr %274, i64 144
  %276 = load ptr, ptr %275, align 8, !tbaa !217
  %277 = call i32 %276(ptr noundef nonnull %264, i64 noundef %271, ptr noundef %273) #16
  br label %279

278:                                              ; preds = %248
  call fastcc void @sqlite3PcacheRelease(ptr noundef nonnull %246)
  br label %279

279:                                              ; preds = %278, %254, %245
  %280 = add nuw nsw i32 %222, 1
  %281 = icmp eq i32 %280, %32
  br i1 %281, label %282, label %221, !llvm.loop !322

282:                                              ; preds = %279, %214
  %283 = load i8, ptr %12, align 1, !tbaa !316
  %284 = and i8 %283, -5
  store i8 %284, ptr %12, align 1, !tbaa !316
  ret i32 %215
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @pager_write(ptr noundef %0) unnamed_addr #1 {
  %2 = getelementptr inbounds i8, ptr %0, i64 40
  %3 = load ptr, ptr %2, align 8, !tbaa !199
  %4 = getelementptr inbounds i8, ptr %3, i64 21
  %5 = load i8, ptr %4, align 1, !tbaa !313
  %6 = icmp eq i8 %5, 2
  br i1 %6, label %7, label %74

7:                                                ; preds = %1
  %8 = load ptr, ptr %3, align 8, !tbaa !272
  %9 = getelementptr inbounds i8, ptr %3, i64 48
  %10 = load i32, ptr %9, align 8, !tbaa !205
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %71

12:                                               ; preds = %7
  %13 = getelementptr inbounds i8, ptr %3, i64 296
  %14 = load ptr, ptr %13, align 8, !tbaa !312
  %15 = icmp eq ptr %14, null
  br i1 %15, label %16, label %61

16:                                               ; preds = %12
  %17 = getelementptr inbounds i8, ptr %3, i64 9
  %18 = load i8, ptr %17, align 1, !tbaa !269
  %19 = icmp eq i8 %18, 2
  br i1 %19, label %61, label %20

20:                                               ; preds = %16
  %21 = getelementptr inbounds i8, ptr %3, i64 32
  %22 = load i32, ptr %21, align 8, !tbaa !202
  %23 = tail call fastcc ptr @sqlite3Malloc(i64 noundef 512)
  %24 = icmp eq ptr %23, null
  br i1 %24, label %69, label %25

25:                                               ; preds = %20
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(512) %23, i8 noundef 0, i64 noundef 512, i1 noundef false) #16
  store i32 %22, ptr %23, align 8, !tbaa !262
  %26 = getelementptr inbounds i8, ptr %3, i64 64
  store ptr %23, ptr %26, align 8, !tbaa !320
  %27 = getelementptr inbounds i8, ptr %3, i64 80
  %28 = load ptr, ptr %27, align 8, !tbaa !302
  %29 = load ptr, ptr %28, align 8, !tbaa !215
  %30 = icmp eq ptr %29, null
  br i1 %30, label %31, label %53

31:                                               ; preds = %25
  %32 = load i8, ptr %17, align 1, !tbaa !269
  %33 = icmp eq i8 %32, 4
  br i1 %33, label %34, label %39

34:                                               ; preds = %31
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(80) %28, i8 noundef 0, i64 noundef 80, i1 noundef false) #16
  %35 = getelementptr inbounds i8, ptr %28, i64 8
  store i32 1016, ptr %35, align 8, !tbaa !274
  store ptr @MemJournalMethods, ptr %28, align 8, !tbaa !215
  %36 = getelementptr inbounds i8, ptr %28, i64 12
  store i32 -1, ptr %36, align 4, !tbaa !277
  %37 = getelementptr inbounds i8, ptr %28, i64 56
  store i32 0, ptr %37, align 8, !tbaa !278
  %38 = getelementptr inbounds i8, ptr %28, i64 64
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %38, i8 0, i64 16, i1 false)
  br label %53

39:                                               ; preds = %31
  %40 = getelementptr inbounds i8, ptr %3, i64 16
  %41 = load i8, ptr %40, align 8, !tbaa !318
  %42 = load i32, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 28), align 4
  %43 = tail call fastcc i32 @databaseIsUnmoved(ptr noundef nonnull %3)
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %45, label %53

45:                                               ; preds = %39
  %46 = icmp eq i8 %41, 0
  %47 = select i1 %46, i32 0, i32 %42
  %48 = select i1 %46, i32 2054, i32 4126
  %49 = getelementptr inbounds i8, ptr %3, i64 224
  %50 = load ptr, ptr %49, align 8, !tbaa !323
  %51 = load ptr, ptr %27, align 8, !tbaa !302
  %52 = tail call fastcc i32 @sqlite3JournalOpen(ptr noundef %8, ptr noundef %50, ptr noundef %51, i32 noundef %48, i32 noundef %47)
  br label %53

53:                                               ; preds = %45, %39, %34, %25
  %54 = phi i32 [ 0, %25 ], [ 0, %34 ], [ %52, %45 ], [ %43, %39 ]
  %55 = icmp eq i32 %54, 0
  br i1 %55, label %56, label %61

56:                                               ; preds = %53
  %57 = getelementptr inbounds i8, ptr %3, i64 52
  store i32 0, ptr %57, align 4, !tbaa !324
  %58 = getelementptr inbounds i8, ptr %3, i64 96
  %59 = getelementptr inbounds i8, ptr %3, i64 24
  store i8 0, ptr %59, align 8, !tbaa !325
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %58, i8 0, i64 16, i1 false)
  %60 = tail call fastcc i32 @writeJournalHdr(ptr noundef nonnull %3)
  br label %61

61:                                               ; preds = %56, %53, %16, %12
  %62 = phi i32 [ 0, %12 ], [ %60, %56 ], [ %54, %53 ], [ 0, %16 ]
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %68, label %64

64:                                               ; preds = %61
  %65 = getelementptr inbounds i8, ptr %3, i64 64
  %66 = load ptr, ptr %65, align 8, !tbaa !320
  tail call fastcc void @sqlite3BitvecDestroy(ptr noundef %66)
  store ptr null, ptr %65, align 8, !tbaa !320
  %67 = getelementptr inbounds i8, ptr %3, i64 96
  store i64 0, ptr %67, align 8, !tbaa !294
  br label %71

68:                                               ; preds = %61
  store i8 3, ptr %4, align 1, !tbaa !313
  br label %71

69:                                               ; preds = %20
  %70 = getelementptr inbounds i8, ptr %3, i64 64
  store ptr %23, ptr %70, align 8, !tbaa !320
  br label %71

71:                                               ; preds = %69, %68, %64, %7
  %72 = phi i32 [ %10, %7 ], [ %62, %68 ], [ %62, %64 ], [ 7, %69 ]
  %73 = icmp eq i32 %72, 0
  br i1 %73, label %74, label %196

74:                                               ; preds = %71, %1
  %75 = getelementptr inbounds i8, ptr %0, i64 52
  %76 = load i16, ptr %75, align 4, !tbaa !201
  %77 = and i16 %76, 17
  %78 = icmp eq i16 %77, 0
  br i1 %78, label %108, label %79

79:                                               ; preds = %74
  %80 = and i16 %76, -17
  store i16 %80, ptr %75, align 4, !tbaa !201
  %81 = and i16 %76, 1
  %82 = icmp eq i16 %81, 0
  br i1 %82, label %108, label %83

83:                                               ; preds = %79
  %84 = xor i16 %80, 3
  store i16 %84, ptr %75, align 4, !tbaa !201
  %85 = getelementptr inbounds i8, ptr %0, i64 24
  %86 = load ptr, ptr %85, align 8, !tbaa !244
  %87 = getelementptr inbounds i8, ptr %0, i64 72
  store ptr null, ptr %87, align 8, !tbaa !253
  %88 = load ptr, ptr %86, align 8, !tbaa !255
  %89 = getelementptr inbounds i8, ptr %0, i64 64
  store ptr %88, ptr %89, align 8, !tbaa !254
  %90 = icmp eq ptr %88, null
  br i1 %90, label %93, label %91

91:                                               ; preds = %83
  %92 = getelementptr inbounds i8, ptr %88, i64 72
  store ptr %0, ptr %92, align 8, !tbaa !253
  br label %100

93:                                               ; preds = %83
  %94 = getelementptr inbounds i8, ptr %86, i64 8
  store ptr %0, ptr %94, align 8, !tbaa !257
  %95 = getelementptr inbounds i8, ptr %86, i64 48
  %96 = load i8, ptr %95, align 8, !tbaa !248
  %97 = icmp eq i8 %96, 0
  br i1 %97, label %100, label %98

98:                                               ; preds = %93
  %99 = getelementptr inbounds i8, ptr %86, i64 49
  store i8 1, ptr %99, align 1, !tbaa !256
  br label %100

100:                                              ; preds = %98, %93, %91
  store ptr %0, ptr %86, align 8, !tbaa !255
  %101 = getelementptr inbounds i8, ptr %86, i64 16
  %102 = load ptr, ptr %101, align 8, !tbaa !252
  %103 = icmp eq ptr %102, null
  %104 = and i16 %76, 8
  %105 = icmp eq i16 %104, 0
  %106 = and i1 %105, %103
  br i1 %106, label %107, label %108

107:                                              ; preds = %100
  store ptr %0, ptr %101, align 8, !tbaa !252
  br label %108

108:                                              ; preds = %107, %100, %79, %74
  %109 = getelementptr inbounds i8, ptr %3, i64 64
  %110 = load ptr, ptr %109, align 8, !tbaa !320
  %111 = icmp eq ptr %110, null
  br i1 %111, label %180, label %112

112:                                              ; preds = %108
  %113 = getelementptr inbounds i8, ptr %0, i64 48
  %114 = load i32, ptr %113, align 8, !tbaa !203
  %115 = add i32 %114, -1
  %116 = load i32, ptr %110, align 8, !tbaa !262
  %117 = icmp ult i32 %115, %116
  br i1 %117, label %118, label %167

118:                                              ; preds = %125, %112
  %119 = phi ptr [ %131, %125 ], [ %110, %112 ]
  %120 = phi i32 [ %127, %125 ], [ %115, %112 ]
  %121 = freeze i32 %120
  %122 = getelementptr inbounds i8, ptr %119, i64 8
  %123 = load i32, ptr %122, align 8, !tbaa !264
  %124 = icmp eq i32 %123, 0
  br i1 %124, label %133, label %125

125:                                              ; preds = %118
  %126 = udiv i32 %121, %123
  %127 = urem i32 %121, %123
  %128 = getelementptr inbounds i8, ptr %119, i64 16
  %129 = zext i32 %126 to i64
  %130 = getelementptr inbounds [62 x ptr], ptr %128, i64 0, i64 %129
  %131 = load ptr, ptr %130, align 8, !tbaa !30
  %132 = icmp eq ptr %131, null
  br i1 %132, label %167, label %118

133:                                              ; preds = %118
  %134 = load i32, ptr %119, align 8, !tbaa !262
  %135 = icmp ult i32 %134, 3969
  br i1 %135, label %136, label %147

136:                                              ; preds = %133
  %137 = getelementptr inbounds i8, ptr %119, i64 16
  %138 = lshr i32 %121, 3
  %139 = zext nneg i32 %138 to i64
  %140 = getelementptr inbounds [496 x i8], ptr %137, i64 0, i64 %139
  %141 = load i8, ptr %140, align 1, !tbaa !30
  %142 = zext i8 %141 to i32
  %143 = and i32 %121, 7
  %144 = shl nuw nsw i32 1, %143
  %145 = and i32 %144, %142
  %146 = icmp eq i32 %145, 0
  br i1 %146, label %167, label %180

147:                                              ; preds = %133
  %148 = add i32 %121, 1
  %149 = urem i32 %121, 124
  %150 = getelementptr inbounds i8, ptr %119, i64 16
  %151 = zext nneg i32 %149 to i64
  %152 = getelementptr inbounds [124 x i32], ptr %150, i64 0, i64 %151
  %153 = load i32, ptr %152, align 4, !tbaa !30
  %154 = icmp eq i32 %153, 0
  br i1 %154, label %167, label %155

155:                                              ; preds = %159, %147
  %156 = phi i32 [ %165, %159 ], [ %153, %147 ]
  %157 = phi i32 [ %162, %159 ], [ %149, %147 ]
  %158 = icmp eq i32 %156, %148
  br i1 %158, label %180, label %159

159:                                              ; preds = %155
  %160 = add i32 %157, 1
  %161 = icmp eq i32 %160, 124
  %162 = select i1 %161, i32 0, i32 %160
  %163 = zext nneg i32 %162 to i64
  %164 = getelementptr inbounds [124 x i32], ptr %150, i64 0, i64 %163
  %165 = load i32, ptr %164, align 4, !tbaa !30
  %166 = icmp eq i32 %165, 0
  br i1 %166, label %167, label %155, !llvm.loop !265

167:                                              ; preds = %159, %147, %136, %125, %112
  %168 = getelementptr inbounds i8, ptr %3, i64 36
  %169 = load i32, ptr %168, align 4, !tbaa !300
  %170 = icmp ugt i32 %114, %169
  br i1 %170, label %174, label %171

171:                                              ; preds = %167
  %172 = tail call fastcc i32 @pagerAddPageToRollbackJournal(ptr noundef %0)
  %173 = icmp eq i32 %172, 0
  br i1 %173, label %180, label %196

174:                                              ; preds = %167
  %175 = load i8, ptr %4, align 1, !tbaa !313
  %176 = icmp eq i8 %175, 4
  br i1 %176, label %180, label %177

177:                                              ; preds = %174
  %178 = load i16, ptr %75, align 4, !tbaa !201
  %179 = or i16 %178, 8
  store i16 %179, ptr %75, align 4, !tbaa !201
  br label %180

180:                                              ; preds = %177, %174, %171, %155, %136, %108
  %181 = load i16, ptr %75, align 4, !tbaa !201
  %182 = or i16 %181, 4
  store i16 %182, ptr %75, align 4, !tbaa !201
  %183 = getelementptr inbounds i8, ptr %3, i64 128
  %184 = load i32, ptr %183, align 8, !tbaa !204
  %185 = icmp sgt i32 %184, 0
  br i1 %185, label %186, label %188

186:                                              ; preds = %180
  %187 = tail call fastcc i32 @subjournalPageIfRequired(ptr noundef %0)
  br label %188

188:                                              ; preds = %186, %180
  %189 = phi i32 [ %187, %186 ], [ 0, %180 ]
  %190 = getelementptr inbounds i8, ptr %3, i64 32
  %191 = load i32, ptr %190, align 8, !tbaa !202
  %192 = getelementptr inbounds i8, ptr %0, i64 48
  %193 = load i32, ptr %192, align 8, !tbaa !203
  %194 = icmp ult i32 %191, %193
  br i1 %194, label %195, label %196

195:                                              ; preds = %188
  store i32 %193, ptr %190, align 8, !tbaa !202
  br label %196

196:                                              ; preds = %195, %188, %171, %71
  %197 = phi i32 [ %72, %71 ], [ %172, %171 ], [ %189, %195 ], [ %189, %188 ]
  ret i32 %197
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc i32 @pagerAddPageToRollbackJournal(ptr nocapture noundef %0) unnamed_addr #4 {
  %2 = alloca [4 x i8], align 1
  %3 = alloca [4 x i8], align 1
  %4 = getelementptr inbounds i8, ptr %0, i64 40
  %5 = load ptr, ptr %4, align 8, !tbaa !199
  %6 = getelementptr inbounds i8, ptr %5, i64 96
  %7 = load i64, ptr %6, align 8, !tbaa !294
  %8 = getelementptr inbounds i8, ptr %0, i64 8
  %9 = load ptr, ptr %8, align 8, !tbaa !208
  %10 = getelementptr inbounds i8, ptr %5, i64 56
  %11 = load i32, ptr %10, align 8, !tbaa !299
  %12 = getelementptr inbounds i8, ptr %5, i64 200
  %13 = load i64, ptr %12, align 8, !tbaa !207
  %14 = trunc i64 %13 to i32
  %15 = add i32 %14, -200
  %16 = icmp sgt i32 %15, 0
  br i1 %16, label %17, label %28

17:                                               ; preds = %1
  %18 = zext nneg i32 %15 to i64
  br label %19

19:                                               ; preds = %19, %17
  %20 = phi i64 [ %18, %17 ], [ %26, %19 ]
  %21 = phi i32 [ %11, %17 ], [ %25, %19 ]
  %22 = getelementptr inbounds i8, ptr %9, i64 %20
  %23 = load i8, ptr %22, align 1, !tbaa !30
  %24 = zext i8 %23 to i32
  %25 = add i32 %21, %24
  %26 = add nsw i64 %20, -200
  %27 = icmp sgt i64 %20, 200
  br i1 %27, label %19, label %28, !llvm.loop !310

28:                                               ; preds = %19, %1
  %29 = phi i32 [ %11, %1 ], [ %25, %19 ]
  %30 = getelementptr inbounds i8, ptr %0, i64 52
  %31 = load i16, ptr %30, align 4, !tbaa !201
  %32 = or i16 %31, 8
  store i16 %32, ptr %30, align 4, !tbaa !201
  %33 = getelementptr inbounds i8, ptr %5, i64 80
  %34 = load ptr, ptr %33, align 8, !tbaa !302
  %35 = getelementptr inbounds i8, ptr %0, i64 48
  %36 = load i32, ptr %35, align 8, !tbaa !203
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #16
  %37 = lshr i32 %36, 24
  %38 = trunc nuw i32 %37 to i8
  store i8 %38, ptr %3, align 1, !tbaa !30
  %39 = lshr i32 %36, 16
  %40 = trunc i32 %39 to i8
  %41 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 %40, ptr %41, align 1, !tbaa !30
  %42 = lshr i32 %36, 8
  %43 = trunc i32 %42 to i8
  %44 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 %43, ptr %44, align 1, !tbaa !30
  %45 = trunc i32 %36 to i8
  %46 = getelementptr inbounds i8, ptr %3, i64 3
  store i8 %45, ptr %46, align 1, !tbaa !30
  %47 = load ptr, ptr %34, align 8, !tbaa !215
  %48 = getelementptr inbounds i8, ptr %47, i64 24
  %49 = load ptr, ptr %48, align 8, !tbaa !282
  %50 = call i32 %49(ptr noundef nonnull %34, ptr noundef nonnull %3, i32 noundef 4, i64 noundef %7) #16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #16
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %52, label %122

52:                                               ; preds = %28
  %53 = load ptr, ptr %33, align 8, !tbaa !302
  %54 = load i64, ptr %12, align 8, !tbaa !207
  %55 = trunc i64 %54 to i32
  %56 = add nsw i64 %7, 4
  %57 = load ptr, ptr %53, align 8, !tbaa !215
  %58 = getelementptr inbounds i8, ptr %57, i64 24
  %59 = load ptr, ptr %58, align 8, !tbaa !282
  %60 = call i32 %59(ptr noundef nonnull %53, ptr noundef %9, i32 noundef %55, i64 noundef %56) #16
  %61 = icmp eq i32 %60, 0
  br i1 %61, label %62, label %122

62:                                               ; preds = %52
  %63 = load ptr, ptr %33, align 8, !tbaa !302
  %64 = load i64, ptr %12, align 8, !tbaa !207
  %65 = add i64 %7, 4
  %66 = add i64 %65, %64
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #16
  %67 = lshr i32 %29, 24
  %68 = trunc nuw i32 %67 to i8
  store i8 %68, ptr %2, align 1, !tbaa !30
  %69 = lshr i32 %29, 16
  %70 = trunc i32 %69 to i8
  %71 = getelementptr inbounds i8, ptr %2, i64 1
  store i8 %70, ptr %71, align 1, !tbaa !30
  %72 = lshr i32 %29, 8
  %73 = trunc i32 %72 to i8
  %74 = getelementptr inbounds i8, ptr %2, i64 2
  store i8 %73, ptr %74, align 1, !tbaa !30
  %75 = trunc i32 %29 to i8
  %76 = getelementptr inbounds i8, ptr %2, i64 3
  store i8 %75, ptr %76, align 1, !tbaa !30
  %77 = load ptr, ptr %63, align 8, !tbaa !215
  %78 = getelementptr inbounds i8, ptr %77, i64 24
  %79 = load ptr, ptr %78, align 8, !tbaa !282
  %80 = call i32 %79(ptr noundef nonnull %63, ptr noundef nonnull %2, i32 noundef 4, i64 noundef %66) #16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #16
  %81 = icmp eq i32 %80, 0
  br i1 %81, label %82, label %122

82:                                               ; preds = %62
  %83 = load i64, ptr %12, align 8, !tbaa !207
  %84 = add nsw i64 %83, 8
  %85 = load i64, ptr %6, align 8, !tbaa !294
  %86 = add nsw i64 %84, %85
  store i64 %86, ptr %6, align 8, !tbaa !294
  %87 = getelementptr inbounds i8, ptr %5, i64 52
  %88 = load i32, ptr %87, align 4, !tbaa !324
  %89 = add nsw i32 %88, 1
  store i32 %89, ptr %87, align 4, !tbaa !324
  %90 = getelementptr inbounds i8, ptr %5, i64 64
  %91 = load ptr, ptr %90, align 8, !tbaa !320
  %92 = load i32, ptr %35, align 8, !tbaa !203
  %93 = call fastcc i32 @sqlite3BitvecSet(ptr noundef %91, i32 noundef %92)
  %94 = load i32, ptr %35, align 8, !tbaa !203
  %95 = getelementptr inbounds i8, ptr %5, i64 128
  %96 = load i32, ptr %95, align 8, !tbaa !204
  %97 = icmp sgt i32 %96, 0
  br i1 %97, label %98, label %119

98:                                               ; preds = %82
  %99 = getelementptr inbounds i8, ptr %5, i64 120
  br label %100

100:                                              ; preds = %113, %98
  %101 = phi i64 [ 0, %98 ], [ %115, %113 ]
  %102 = phi i32 [ 0, %98 ], [ %114, %113 ]
  %103 = load ptr, ptr %99, align 8, !tbaa !258
  %104 = getelementptr inbounds %struct.PagerSavepoint, ptr %103, i64 %101
  %105 = getelementptr inbounds i8, ptr %104, i64 24
  %106 = load i32, ptr %105, align 8, !tbaa !259
  %107 = icmp ult i32 %106, %94
  br i1 %107, label %113, label %108

108:                                              ; preds = %100
  %109 = getelementptr inbounds i8, ptr %104, i64 16
  %110 = load ptr, ptr %109, align 8, !tbaa !261
  %111 = call fastcc i32 @sqlite3BitvecSet(ptr noundef %110, i32 noundef %94)
  %112 = or i32 %111, %102
  br label %113

113:                                              ; preds = %108, %100
  %114 = phi i32 [ %112, %108 ], [ %102, %100 ]
  %115 = add nuw nsw i64 %101, 1
  %116 = load i32, ptr %95, align 8, !tbaa !204
  %117 = sext i32 %116 to i64
  %118 = icmp slt i64 %115, %117
  br i1 %118, label %100, label %119, !llvm.loop !283

119:                                              ; preds = %113, %82
  %120 = phi i32 [ 0, %82 ], [ %114, %113 ]
  %121 = or i32 %120, %93
  br label %122

122:                                              ; preds = %119, %62, %52, %28
  %123 = phi i32 [ %121, %119 ], [ %50, %28 ], [ %60, %52 ], [ %80, %62 ]
  ret i32 %123
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @vdbeMemClear(ptr noundef %0) unnamed_addr #4 {
  %2 = getelementptr inbounds i8, ptr %0, i64 20
  %3 = load i16, ptr %2, align 4, !tbaa !83
  %4 = and i16 %3, -28672
  %5 = icmp eq i16 %4, 0
  br i1 %5, label %7, label %6

6:                                                ; preds = %1
  tail call fastcc void @vdbeMemClearExternAndSetNull(ptr noundef %0)
  br label %7

7:                                                ; preds = %6, %1
  %8 = getelementptr inbounds i8, ptr %0, i64 32
  %9 = load i32, ptr %8, align 8, !tbaa !326
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %57, label %11

11:                                               ; preds = %7
  %12 = getelementptr inbounds i8, ptr %0, i64 24
  %13 = load ptr, ptr %12, align 8, !tbaa !327
  %14 = getelementptr inbounds i8, ptr %0, i64 40
  %15 = load ptr, ptr %14, align 8, !tbaa !328
  %16 = icmp eq ptr %13, null
  br i1 %16, label %40, label %17

17:                                               ; preds = %11
  %18 = getelementptr inbounds i8, ptr %13, i64 488
  %19 = load ptr, ptr %18, align 8, !tbaa !172
  %20 = icmp ugt ptr %19, %15
  br i1 %20, label %21, label %35

21:                                               ; preds = %17
  %22 = getelementptr inbounds i8, ptr %13, i64 472
  %23 = load ptr, ptr %22, align 8, !tbaa !145
  %24 = icmp ugt ptr %23, %15
  br i1 %24, label %28, label %25

25:                                               ; preds = %21
  %26 = getelementptr inbounds i8, ptr %13, i64 464
  %27 = load ptr, ptr %26, align 8, !tbaa !173
  store ptr %27, ptr %15, align 8, !tbaa !174
  store ptr %15, ptr %26, align 8, !tbaa !173
  br label %56

28:                                               ; preds = %21
  %29 = getelementptr inbounds i8, ptr %13, i64 480
  %30 = load ptr, ptr %29, align 8, !tbaa !146
  %31 = icmp ugt ptr %30, %15
  br i1 %31, label %35, label %32

32:                                               ; preds = %28
  %33 = getelementptr inbounds i8, ptr %13, i64 448
  %34 = load ptr, ptr %33, align 8, !tbaa !176
  store ptr %34, ptr %15, align 8, !tbaa !174
  store ptr %15, ptr %33, align 8, !tbaa !176
  br label %56

35:                                               ; preds = %28, %17
  %36 = getelementptr inbounds i8, ptr %13, i64 768
  %37 = load ptr, ptr %36, align 8, !tbaa !177
  %38 = icmp eq ptr %37, null
  br i1 %38, label %40, label %39

39:                                               ; preds = %35
  tail call fastcc void @measureAllocationSize(ptr noundef nonnull %13, ptr noundef %15)
  br label %56

40:                                               ; preds = %35, %11
  %41 = icmp eq ptr %15, null
  br i1 %41, label %56, label %42

42:                                               ; preds = %40
  %43 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %54, label %45

45:                                               ; preds = %42
  %46 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %47 = tail call i32 %46(ptr noundef nonnull %15) #16
  %48 = sext i32 %47 to i64
  %49 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %50 = sub nsw i64 %49, %48
  store i64 %50, ptr @sqlite3Stat, align 8, !tbaa !67
  %51 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %52 = add nsw i64 %51, -1
  store i64 %52, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %53 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %53(ptr noundef nonnull %15) #16
  br label %56

54:                                               ; preds = %42
  %55 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %55(ptr noundef nonnull %15) #16
  br label %56

56:                                               ; preds = %54, %45, %40, %39, %32, %25
  store i32 0, ptr %8, align 8, !tbaa !326
  br label %57

57:                                               ; preds = %56, %7
  %58 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr null, ptr %58, align 8, !tbaa !85
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @vdbeMemClearExternAndSetNull(ptr noundef %0) unnamed_addr #4 {
  %2 = getelementptr inbounds i8, ptr %0, i64 20
  %3 = load i16, ptr %2, align 4, !tbaa !83
  %4 = icmp sgt i16 %3, -1
  br i1 %4, label %8, label %5

5:                                                ; preds = %1
  %6 = load ptr, ptr %0, align 8, !tbaa !30
  %7 = tail call fastcc i32 @sqlite3VdbeMemFinalize(ptr noundef nonnull %0, ptr noundef %6)
  br label %8

8:                                                ; preds = %5, %1
  %9 = load i16, ptr %2, align 4, !tbaa !83
  %10 = and i16 %9, 4096
  %11 = icmp eq i16 %10, 0
  br i1 %11, label %17, label %12

12:                                               ; preds = %8
  %13 = getelementptr inbounds i8, ptr %0, i64 48
  %14 = load ptr, ptr %13, align 8, !tbaa !329
  %15 = getelementptr inbounds i8, ptr %0, i64 8
  %16 = load ptr, ptr %15, align 8, !tbaa !85
  tail call void %14(ptr noundef %16) #16
  br label %17

17:                                               ; preds = %12, %8
  store i16 1, ptr %2, align 4, !tbaa !83
  ret void
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc i32 @sqlite3VdbeMemFinalize(ptr noundef %0, ptr noundef %1) unnamed_addr #1 {
  %3 = alloca %struct.sqlite3_context, align 8
  %4 = alloca %struct.sqlite3_value, align 8
  call void @llvm.lifetime.start.p0(i64 56, ptr nonnull %3) #16
  call void @llvm.lifetime.start.p0(i64 56, ptr nonnull %4) #16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(56) %3, i8 0, i64 56, i1 false)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(56) %4, i8 0, i64 56, i1 false)
  %5 = getelementptr inbounds i8, ptr %4, i64 20
  store i16 1, ptr %5, align 4, !tbaa !83
  %6 = getelementptr inbounds i8, ptr %0, i64 24
  %7 = load ptr, ptr %6, align 8, !tbaa !327
  %8 = getelementptr inbounds i8, ptr %4, i64 24
  store ptr %7, ptr %8, align 8, !tbaa !327
  store ptr %4, ptr %3, align 8, !tbaa !330
  %9 = getelementptr inbounds i8, ptr %3, i64 16
  store ptr %0, ptr %9, align 8, !tbaa !332
  %10 = getelementptr inbounds i8, ptr %3, i64 8
  store ptr %1, ptr %10, align 8, !tbaa !333
  %11 = getelementptr inbounds i8, ptr %7, i64 100
  %12 = load i8, ptr %11, align 4, !tbaa !334
  %13 = getelementptr inbounds i8, ptr %3, i64 40
  store i8 %12, ptr %13, align 8, !tbaa !335
  %14 = getelementptr inbounds i8, ptr %1, i64 32
  %15 = load ptr, ptr %14, align 8, !tbaa !336
  call void %15(ptr noundef nonnull %3) #16
  %16 = getelementptr inbounds i8, ptr %0, i64 32
  %17 = load i32, ptr %16, align 8, !tbaa !326
  %18 = icmp sgt i32 %17, 0
  br i1 %18, label %19, label %63

19:                                               ; preds = %2
  %20 = load ptr, ptr %6, align 8, !tbaa !327
  %21 = getelementptr inbounds i8, ptr %0, i64 40
  %22 = load ptr, ptr %21, align 8, !tbaa !328
  %23 = icmp eq ptr %20, null
  br i1 %23, label %47, label %24

24:                                               ; preds = %19
  %25 = getelementptr inbounds i8, ptr %20, i64 488
  %26 = load ptr, ptr %25, align 8, !tbaa !172
  %27 = icmp ugt ptr %26, %22
  br i1 %27, label %28, label %42

28:                                               ; preds = %24
  %29 = getelementptr inbounds i8, ptr %20, i64 472
  %30 = load ptr, ptr %29, align 8, !tbaa !145
  %31 = icmp ugt ptr %30, %22
  br i1 %31, label %35, label %32

32:                                               ; preds = %28
  %33 = getelementptr inbounds i8, ptr %20, i64 464
  %34 = load ptr, ptr %33, align 8, !tbaa !173
  store ptr %34, ptr %22, align 8, !tbaa !174
  store ptr %22, ptr %33, align 8, !tbaa !173
  br label %63

35:                                               ; preds = %28
  %36 = getelementptr inbounds i8, ptr %20, i64 480
  %37 = load ptr, ptr %36, align 8, !tbaa !146
  %38 = icmp ugt ptr %37, %22
  br i1 %38, label %42, label %39

39:                                               ; preds = %35
  %40 = getelementptr inbounds i8, ptr %20, i64 448
  %41 = load ptr, ptr %40, align 8, !tbaa !176
  store ptr %41, ptr %22, align 8, !tbaa !174
  store ptr %22, ptr %40, align 8, !tbaa !176
  br label %63

42:                                               ; preds = %35, %24
  %43 = getelementptr inbounds i8, ptr %20, i64 768
  %44 = load ptr, ptr %43, align 8, !tbaa !177
  %45 = icmp eq ptr %44, null
  br i1 %45, label %47, label %46

46:                                               ; preds = %42
  call fastcc void @measureAllocationSize(ptr noundef nonnull %20, ptr noundef %22)
  br label %63

47:                                               ; preds = %42, %19
  %48 = icmp eq ptr %22, null
  br i1 %48, label %63, label %49

49:                                               ; preds = %47
  %50 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %61, label %52

52:                                               ; preds = %49
  %53 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %54 = call i32 %53(ptr noundef nonnull %22) #16
  %55 = sext i32 %54 to i64
  %56 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %57 = sub nsw i64 %56, %55
  store i64 %57, ptr @sqlite3Stat, align 8, !tbaa !67
  %58 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %59 = add nsw i64 %58, -1
  store i64 %59, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %60 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %60(ptr noundef nonnull %22) #16
  br label %63

61:                                               ; preds = %49
  %62 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  call void %62(ptr noundef nonnull %22) #16
  br label %63

63:                                               ; preds = %61, %52, %47, %46, %39, %32, %2
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(56) %0, ptr noundef nonnull align 8 dereferenceable(56) %4, i64 noundef 56, i1 noundef false) #16
  %64 = getelementptr inbounds i8, ptr %3, i64 36
  %65 = load i32, ptr %64, align 4, !tbaa !337
  call void @llvm.lifetime.end.p0(i64 56, ptr nonnull %4) #16
  call void @llvm.lifetime.end.p0(i64 56, ptr nonnull %3) #16
  ret i32 %65
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc range(i32 0, 8) i32 @sqlite3VdbeMemGrow(ptr noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #4 {
  %4 = getelementptr inbounds i8, ptr %0, i64 32
  %5 = load i32, ptr %4, align 8, !tbaa !326
  %6 = icmp sgt i32 %5, 0
  %7 = icmp ne i32 %2, 0
  %8 = and i1 %7, %6
  br i1 %8, label %9, label %110

9:                                                ; preds = %3
  %10 = getelementptr inbounds i8, ptr %0, i64 8
  %11 = load ptr, ptr %10, align 8, !tbaa !85
  %12 = getelementptr inbounds i8, ptr %0, i64 40
  %13 = load ptr, ptr %12, align 8, !tbaa !328
  %14 = icmp eq ptr %11, %13
  br i1 %14, label %15, label %110

15:                                               ; preds = %9
  %16 = getelementptr inbounds i8, ptr %0, i64 24
  %17 = load ptr, ptr %16, align 8, !tbaa !327
  %18 = icmp eq ptr %17, null
  %19 = sext i32 %1 to i64
  br i1 %18, label %87, label %20

20:                                               ; preds = %15
  %21 = icmp eq ptr %11, null
  br i1 %21, label %22, label %24

22:                                               ; preds = %20
  %23 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %17, i64 noundef %19)
  br label %45

24:                                               ; preds = %20
  %25 = getelementptr inbounds i8, ptr %17, i64 488
  %26 = load ptr, ptr %25, align 8, !tbaa !172
  %27 = icmp ugt ptr %26, %11
  br i1 %27, label %28, label %43

28:                                               ; preds = %24
  %29 = getelementptr inbounds i8, ptr %17, i64 472
  %30 = load ptr, ptr %29, align 8, !tbaa !145
  %31 = icmp ugt ptr %30, %11
  br i1 %31, label %34, label %32

32:                                               ; preds = %28
  %33 = icmp ult i32 %1, 129
  br i1 %33, label %45, label %43

34:                                               ; preds = %28
  %35 = getelementptr inbounds i8, ptr %17, i64 480
  %36 = load ptr, ptr %35, align 8, !tbaa !146
  %37 = icmp ugt ptr %36, %11
  br i1 %37, label %43, label %38

38:                                               ; preds = %34
  %39 = getelementptr inbounds i8, ptr %17, i64 414
  %40 = load i16, ptr %39, align 2, !tbaa !147
  %41 = zext i16 %40 to i64
  %42 = icmp ult i64 %41, %19
  br i1 %42, label %43, label %45

43:                                               ; preds = %38, %34, %32, %24
  %44 = tail call fastcc ptr @dbReallocFinish(ptr noundef nonnull %17, ptr noundef nonnull %11, i64 noundef %19)
  br label %45

45:                                               ; preds = %43, %38, %32, %22
  %46 = phi ptr [ %23, %22 ], [ %44, %43 ], [ %11, %32 ], [ %11, %38 ]
  %47 = icmp ne ptr %46, null
  %48 = or i1 %21, %47
  br i1 %48, label %86, label %49

49:                                               ; preds = %45
  %50 = getelementptr inbounds i8, ptr %17, i64 488
  %51 = load ptr, ptr %50, align 8, !tbaa !172
  %52 = icmp ugt ptr %51, %11
  br i1 %52, label %53, label %67

53:                                               ; preds = %49
  %54 = getelementptr inbounds i8, ptr %17, i64 472
  %55 = load ptr, ptr %54, align 8, !tbaa !145
  %56 = icmp ugt ptr %55, %11
  br i1 %56, label %60, label %57

57:                                               ; preds = %53
  %58 = getelementptr inbounds i8, ptr %17, i64 464
  %59 = load ptr, ptr %58, align 8, !tbaa !173
  store ptr %59, ptr %11, align 8, !tbaa !174
  store ptr %11, ptr %58, align 8, !tbaa !173
  br label %86

60:                                               ; preds = %53
  %61 = getelementptr inbounds i8, ptr %17, i64 480
  %62 = load ptr, ptr %61, align 8, !tbaa !146
  %63 = icmp ugt ptr %62, %11
  br i1 %63, label %67, label %64

64:                                               ; preds = %60
  %65 = getelementptr inbounds i8, ptr %17, i64 448
  %66 = load ptr, ptr %65, align 8, !tbaa !176
  store ptr %66, ptr %11, align 8, !tbaa !174
  store ptr %11, ptr %65, align 8, !tbaa !176
  br label %86

67:                                               ; preds = %60, %49
  %68 = getelementptr inbounds i8, ptr %17, i64 768
  %69 = load ptr, ptr %68, align 8, !tbaa !177
  %70 = icmp eq ptr %69, null
  br i1 %70, label %72, label %71

71:                                               ; preds = %67
  tail call fastcc void @measureAllocationSize(ptr noundef nonnull %17, ptr noundef nonnull %11)
  br label %86

72:                                               ; preds = %67
  %73 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %74 = icmp eq i32 %73, 0
  br i1 %74, label %84, label %75

75:                                               ; preds = %72
  %76 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %77 = tail call i32 %76(ptr noundef nonnull %11) #16
  %78 = sext i32 %77 to i64
  %79 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %80 = sub nsw i64 %79, %78
  store i64 %80, ptr @sqlite3Stat, align 8, !tbaa !67
  %81 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %82 = add nsw i64 %81, -1
  store i64 %82, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %83 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %83(ptr noundef nonnull %11) #16
  br label %86

84:                                               ; preds = %72
  %85 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %85(ptr noundef nonnull %11) #16
  br label %86

86:                                               ; preds = %84, %75, %71, %64, %57, %45
  store ptr %46, ptr %12, align 8, !tbaa !328
  br label %108

87:                                               ; preds = %15
  %88 = tail call fastcc ptr @sqlite3Realloc(ptr noundef %11, i64 noundef %19)
  store ptr %88, ptr %12, align 8, !tbaa !328
  %89 = icmp eq ptr %88, null
  br i1 %89, label %90, label %106

90:                                               ; preds = %87
  %91 = load ptr, ptr %10, align 8, !tbaa !85
  %92 = icmp eq ptr %91, null
  br i1 %92, label %106, label %93

93:                                               ; preds = %90
  %94 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %95 = icmp eq i32 %94, 0
  br i1 %95, label %104, label %96

96:                                               ; preds = %93
  %97 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %98 = tail call i32 %97(ptr noundef nonnull %91) #16
  %99 = sext i32 %98 to i64
  %100 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %101 = sub nsw i64 %100, %99
  store i64 %101, ptr @sqlite3Stat, align 8, !tbaa !67
  %102 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %103 = add nsw i64 %102, -1
  store i64 %103, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  br label %104

104:                                              ; preds = %96, %93
  %105 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %105(ptr noundef nonnull %91) #16
  br label %106

106:                                              ; preds = %104, %90, %87
  %107 = load ptr, ptr %12, align 8, !tbaa !328
  br label %108

108:                                              ; preds = %106, %86
  %109 = phi ptr [ %107, %106 ], [ %46, %86 ]
  store ptr %109, ptr %10, align 8, !tbaa !85
  br label %169

110:                                              ; preds = %9, %3
  br i1 %6, label %111, label %156

111:                                              ; preds = %110
  %112 = getelementptr inbounds i8, ptr %0, i64 24
  %113 = load ptr, ptr %112, align 8, !tbaa !327
  %114 = getelementptr inbounds i8, ptr %0, i64 40
  %115 = load ptr, ptr %114, align 8, !tbaa !328
  %116 = icmp eq ptr %113, null
  br i1 %116, label %140, label %117

117:                                              ; preds = %111
  %118 = getelementptr inbounds i8, ptr %113, i64 488
  %119 = load ptr, ptr %118, align 8, !tbaa !172
  %120 = icmp ugt ptr %119, %115
  br i1 %120, label %121, label %135

121:                                              ; preds = %117
  %122 = getelementptr inbounds i8, ptr %113, i64 472
  %123 = load ptr, ptr %122, align 8, !tbaa !145
  %124 = icmp ugt ptr %123, %115
  br i1 %124, label %128, label %125

125:                                              ; preds = %121
  %126 = getelementptr inbounds i8, ptr %113, i64 464
  %127 = load ptr, ptr %126, align 8, !tbaa !173
  store ptr %127, ptr %115, align 8, !tbaa !174
  store ptr %115, ptr %126, align 8, !tbaa !173
  br label %156

128:                                              ; preds = %121
  %129 = getelementptr inbounds i8, ptr %113, i64 480
  %130 = load ptr, ptr %129, align 8, !tbaa !146
  %131 = icmp ugt ptr %130, %115
  br i1 %131, label %135, label %132

132:                                              ; preds = %128
  %133 = getelementptr inbounds i8, ptr %113, i64 448
  %134 = load ptr, ptr %133, align 8, !tbaa !176
  store ptr %134, ptr %115, align 8, !tbaa !174
  store ptr %115, ptr %133, align 8, !tbaa !176
  br label %156

135:                                              ; preds = %128, %117
  %136 = getelementptr inbounds i8, ptr %113, i64 768
  %137 = load ptr, ptr %136, align 8, !tbaa !177
  %138 = icmp eq ptr %137, null
  br i1 %138, label %140, label %139

139:                                              ; preds = %135
  tail call fastcc void @measureAllocationSize(ptr noundef nonnull %113, ptr noundef %115)
  br label %156

140:                                              ; preds = %135, %111
  %141 = icmp eq ptr %115, null
  br i1 %141, label %156, label %142

142:                                              ; preds = %140
  %143 = load i32, ptr @sqlite3Config, align 8, !tbaa !65
  %144 = icmp eq i32 %143, 0
  br i1 %144, label %154, label %145

145:                                              ; preds = %142
  %146 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %147 = tail call i32 %146(ptr noundef nonnull %115) #16
  %148 = sext i32 %147 to i64
  %149 = load i64, ptr @sqlite3Stat, align 8, !tbaa !67
  %150 = sub nsw i64 %149, %148
  store i64 %150, ptr @sqlite3Stat, align 8, !tbaa !67
  %151 = load i64, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %152 = add nsw i64 %151, -1
  store i64 %152, ptr getelementptr inbounds (i8, ptr @sqlite3Stat, i64 72), align 8, !tbaa !67
  %153 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %153(ptr noundef nonnull %115) #16
  br label %156

154:                                              ; preds = %142
  %155 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 40), align 8, !tbaa !71
  tail call void %155(ptr noundef nonnull %115) #16
  br label %156

156:                                              ; preds = %154, %145, %140, %139, %132, %125, %110
  %157 = getelementptr inbounds i8, ptr %0, i64 24
  %158 = load ptr, ptr %157, align 8, !tbaa !327
  %159 = sext i32 %1 to i64
  %160 = icmp eq ptr %158, null
  br i1 %160, label %163, label %161

161:                                              ; preds = %156
  %162 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %158, i64 noundef %159)
  br label %165

163:                                              ; preds = %156
  %164 = tail call fastcc ptr @sqlite3Malloc(i64 noundef %159)
  br label %165

165:                                              ; preds = %163, %161
  %166 = phi ptr [ %162, %161 ], [ %164, %163 ]
  %167 = getelementptr inbounds i8, ptr %0, i64 40
  store ptr %166, ptr %167, align 8, !tbaa !328
  %168 = icmp eq i32 %2, 0
  br label %169

169:                                              ; preds = %165, %108
  %170 = phi i1 [ true, %108 ], [ %168, %165 ]
  %171 = getelementptr inbounds i8, ptr %0, i64 40
  %172 = load ptr, ptr %171, align 8, !tbaa !328
  %173 = icmp eq ptr %172, null
  br i1 %173, label %174, label %183

174:                                              ; preds = %169
  %175 = getelementptr inbounds i8, ptr %0, i64 20
  %176 = load i16, ptr %175, align 4, !tbaa !83
  %177 = and i16 %176, -28672
  %178 = icmp eq i16 %177, 0
  br i1 %178, label %180, label %179

179:                                              ; preds = %174
  tail call fastcc void @vdbeMemClearExternAndSetNull(ptr noundef %0)
  br label %181

180:                                              ; preds = %174
  store i16 1, ptr %175, align 4, !tbaa !83
  br label %181

181:                                              ; preds = %180, %179
  %182 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr null, ptr %182, align 8, !tbaa !85
  store i32 0, ptr %4, align 8, !tbaa !326
  br label %232

183:                                              ; preds = %169
  %184 = getelementptr inbounds i8, ptr %0, i64 24
  %185 = load ptr, ptr %184, align 8, !tbaa !327
  %186 = icmp eq ptr %185, null
  br i1 %186, label %203, label %187

187:                                              ; preds = %183
  %188 = getelementptr inbounds i8, ptr %185, i64 496
  %189 = load ptr, ptr %188, align 8, !tbaa !144
  %190 = icmp ugt ptr %189, %172
  br i1 %190, label %191, label %203

191:                                              ; preds = %187
  %192 = getelementptr inbounds i8, ptr %185, i64 472
  %193 = load ptr, ptr %192, align 8, !tbaa !145
  %194 = icmp ugt ptr %193, %172
  br i1 %194, label %195, label %206

195:                                              ; preds = %191
  %196 = getelementptr inbounds i8, ptr %185, i64 480
  %197 = load ptr, ptr %196, align 8, !tbaa !146
  %198 = icmp ugt ptr %197, %172
  br i1 %198, label %203, label %199

199:                                              ; preds = %195
  %200 = getelementptr inbounds i8, ptr %185, i64 414
  %201 = load i16, ptr %200, align 2, !tbaa !147
  %202 = zext i16 %201 to i32
  br label %206

203:                                              ; preds = %195, %187, %183
  %204 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %205 = tail call i32 %204(ptr noundef nonnull %172) #16
  br label %206

206:                                              ; preds = %203, %199, %191
  %207 = phi i32 [ %202, %199 ], [ %205, %203 ], [ 128, %191 ]
  store i32 %207, ptr %4, align 8, !tbaa !326
  br i1 %170, label %217, label %208

208:                                              ; preds = %206
  %209 = getelementptr inbounds i8, ptr %0, i64 8
  %210 = load ptr, ptr %209, align 8, !tbaa !85
  %211 = icmp eq ptr %210, null
  br i1 %211, label %217, label %212

212:                                              ; preds = %208
  %213 = load ptr, ptr %171, align 8, !tbaa !328
  %214 = getelementptr inbounds i8, ptr %0, i64 16
  %215 = load i32, ptr %214, align 8, !tbaa !338
  %216 = sext i32 %215 to i64
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %213, ptr noundef nonnull align 1 %210, i64 noundef %216, i1 noundef false) #16
  br label %217

217:                                              ; preds = %212, %208, %206
  %218 = getelementptr inbounds i8, ptr %0, i64 20
  %219 = load i16, ptr %218, align 4, !tbaa !83
  %220 = and i16 %219, 4096
  %221 = icmp eq i16 %220, 0
  br i1 %221, label %227, label %222

222:                                              ; preds = %217
  %223 = getelementptr inbounds i8, ptr %0, i64 48
  %224 = load ptr, ptr %223, align 8, !tbaa !329
  %225 = getelementptr inbounds i8, ptr %0, i64 8
  %226 = load ptr, ptr %225, align 8, !tbaa !85
  tail call void %224(ptr noundef %226) #16
  br label %227

227:                                              ; preds = %222, %217
  %228 = load ptr, ptr %171, align 8, !tbaa !328
  %229 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr %228, ptr %229, align 8, !tbaa !85
  %230 = load i16, ptr %218, align 4, !tbaa !83
  %231 = and i16 %230, -28673
  store i16 %231, ptr %218, align 4, !tbaa !83
  br label %232

232:                                              ; preds = %227, %181
  %233 = phi i32 [ 7, %181 ], [ 0, %227 ]
  ret i32 %233
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc ptr @valueToText(ptr noundef %0, i8 noundef zeroext %1) unnamed_addr #4 {
  %3 = getelementptr inbounds i8, ptr %0, i64 20
  %4 = load i16, ptr %3, align 4, !tbaa !83
  %5 = zext i16 %4 to i32
  %6 = and i32 %5, 18
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %112, label %8

8:                                                ; preds = %2
  %9 = and i32 %5, 1024
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %37, label %11

11:                                               ; preds = %8
  %12 = getelementptr inbounds i8, ptr %0, i64 16
  %13 = load i32, ptr %12, align 8, !tbaa !338
  %14 = load i32, ptr %0, align 8, !tbaa !30
  %15 = add nsw i32 %14, %13
  %16 = icmp slt i32 %15, 1
  br i1 %16, label %17, label %20

17:                                               ; preds = %11
  %18 = and i16 %4, 16
  %19 = icmp eq i16 %18, 0
  br i1 %19, label %37, label %20

20:                                               ; preds = %17, %11
  %21 = phi i32 [ %15, %11 ], [ 1, %17 ]
  %22 = tail call fastcc i32 @sqlite3VdbeMemGrow(ptr noundef nonnull %0, i32 noundef %21, i32 noundef 1)
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %24, label %143

24:                                               ; preds = %20
  %25 = getelementptr inbounds i8, ptr %0, i64 8
  %26 = load ptr, ptr %25, align 8, !tbaa !85
  %27 = load i32, ptr %12, align 8, !tbaa !338
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds i8, ptr %26, i64 %28
  %30 = load i32, ptr %0, align 8, !tbaa !30
  %31 = sext i32 %30 to i64
  tail call void @llvm.memset.p0.i64(ptr noundef align 1 %29, i8 noundef 0, i64 noundef %31, i1 noundef false) #16
  %32 = load i32, ptr %0, align 8, !tbaa !30
  %33 = load i32, ptr %12, align 8, !tbaa !338
  %34 = add nsw i32 %33, %32
  store i32 %34, ptr %12, align 8, !tbaa !338
  %35 = load i16, ptr %3, align 4, !tbaa !83
  %36 = and i16 %35, -1537
  store i16 %36, ptr %3, align 4, !tbaa !83
  br label %37

37:                                               ; preds = %24, %17, %8
  %38 = load i16, ptr %3, align 4, !tbaa !83
  %39 = or i16 %38, 2
  store i16 %39, ptr %3, align 4, !tbaa !83
  %40 = getelementptr inbounds i8, ptr %0, i64 22
  %41 = load i8, ptr %40, align 2, !tbaa !142
  %42 = zext i8 %41 to i32
  %43 = zext i8 %1 to i32
  %44 = and i32 %43, 247
  %45 = icmp eq i32 %44, %42
  br i1 %45, label %49, label %46

46:                                               ; preds = %37
  %47 = trunc nuw i32 %44 to i8
  %48 = tail call fastcc i32 @sqlite3VdbeMemTranslate(ptr noundef %0, i8 noundef zeroext %47)
  br label %49

49:                                               ; preds = %46, %37
  %50 = and i32 %43, 8
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %106, label %52

52:                                               ; preds = %49
  %53 = getelementptr inbounds i8, ptr %0, i64 8
  %54 = load ptr, ptr %53, align 8, !tbaa !85
  %55 = ptrtoint ptr %54 to i64
  %56 = and i64 %55, 1
  %57 = icmp eq i64 %56, 0
  br i1 %57, label %106, label %58

58:                                               ; preds = %52
  %59 = load i16, ptr %3, align 4, !tbaa !83
  %60 = zext i16 %59 to i32
  %61 = and i32 %60, 18
  %62 = icmp eq i32 %61, 0
  br i1 %62, label %103, label %63

63:                                               ; preds = %58
  %64 = and i32 %60, 1024
  %65 = icmp eq i32 %64, 0
  br i1 %65, label %91, label %66

66:                                               ; preds = %63
  %67 = getelementptr inbounds i8, ptr %0, i64 16
  %68 = load i32, ptr %67, align 8, !tbaa !338
  %69 = load i32, ptr %0, align 8, !tbaa !30
  %70 = add nsw i32 %69, %68
  %71 = icmp slt i32 %70, 1
  br i1 %71, label %72, label %75

72:                                               ; preds = %66
  %73 = and i16 %59, 16
  %74 = icmp eq i16 %73, 0
  br i1 %74, label %91, label %75

75:                                               ; preds = %72, %66
  %76 = phi i32 [ %70, %66 ], [ 1, %72 ]
  %77 = tail call fastcc i32 @sqlite3VdbeMemGrow(ptr noundef nonnull %0, i32 noundef %76, i32 noundef 1)
  %78 = icmp eq i32 %77, 0
  br i1 %78, label %79, label %143

79:                                               ; preds = %75
  %80 = load ptr, ptr %53, align 8, !tbaa !85
  %81 = load i32, ptr %67, align 8, !tbaa !338
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds i8, ptr %80, i64 %82
  %84 = load i32, ptr %0, align 8, !tbaa !30
  %85 = sext i32 %84 to i64
  tail call void @llvm.memset.p0.i64(ptr noundef align 1 %83, i8 noundef 0, i64 noundef %85, i1 noundef false) #16
  %86 = load i32, ptr %0, align 8, !tbaa !30
  %87 = load i32, ptr %67, align 8, !tbaa !338
  %88 = add nsw i32 %87, %86
  store i32 %88, ptr %67, align 8, !tbaa !338
  %89 = load i16, ptr %3, align 4, !tbaa !83
  %90 = and i16 %89, -1537
  store i16 %90, ptr %3, align 4, !tbaa !83
  br label %91

91:                                               ; preds = %79, %72, %63
  %92 = getelementptr inbounds i8, ptr %0, i64 32
  %93 = load i32, ptr %92, align 8, !tbaa !326
  %94 = icmp eq i32 %93, 0
  br i1 %94, label %100, label %95

95:                                               ; preds = %91
  %96 = load ptr, ptr %53, align 8, !tbaa !85
  %97 = getelementptr inbounds i8, ptr %0, i64 40
  %98 = load ptr, ptr %97, align 8, !tbaa !328
  %99 = icmp eq ptr %96, %98
  br i1 %99, label %103, label %100

100:                                              ; preds = %95, %91
  %101 = tail call fastcc i32 @vdbeMemAddTerminator(ptr noundef %0)
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %103, label %143

103:                                              ; preds = %100, %95, %58
  %104 = load i16, ptr %3, align 4, !tbaa !83
  %105 = and i16 %104, -16385
  store i16 %105, ptr %3, align 4, !tbaa !83
  br label %106

106:                                              ; preds = %103, %52, %49
  %107 = load i16, ptr %3, align 4, !tbaa !83
  %108 = and i16 %107, 514
  %109 = icmp eq i16 %108, 2
  br i1 %109, label %110, label %135

110:                                              ; preds = %106
  %111 = tail call fastcc i32 @vdbeMemAddTerminator(ptr noundef %0)
  br label %135

112:                                              ; preds = %2
  %113 = getelementptr inbounds i8, ptr %0, i64 32
  %114 = load i32, ptr %113, align 8, !tbaa !326
  %115 = icmp slt i32 %114, 32
  br i1 %115, label %116, label %119

116:                                              ; preds = %112
  %117 = tail call fastcc i32 @sqlite3VdbeMemGrow(ptr noundef %0, i32 noundef 32, i32 noundef 0)
  %118 = icmp eq i32 %117, 0
  br i1 %118, label %126, label %124

119:                                              ; preds = %112
  %120 = getelementptr inbounds i8, ptr %0, i64 40
  %121 = load ptr, ptr %120, align 8, !tbaa !328
  %122 = getelementptr inbounds i8, ptr %0, i64 8
  store ptr %121, ptr %122, align 8, !tbaa !85
  %123 = and i16 %4, 45
  store i16 %123, ptr %3, align 4, !tbaa !83
  br label %126

124:                                              ; preds = %116
  %125 = getelementptr inbounds i8, ptr %0, i64 22
  store i8 0, ptr %125, align 2, !tbaa !142
  br label %135

126:                                              ; preds = %119, %116
  %127 = getelementptr inbounds i8, ptr %0, i64 8
  %128 = load ptr, ptr %127, align 8, !tbaa !85
  tail call fastcc void @vdbeMemRenderNum(ptr noundef %128, ptr noundef %0)
  %129 = getelementptr inbounds i8, ptr %0, i64 22
  store i8 1, ptr %129, align 2, !tbaa !142
  %130 = load i16, ptr %3, align 4, !tbaa !83
  %131 = or i16 %130, 514
  store i16 %131, ptr %3, align 4, !tbaa !83
  %132 = icmp eq i8 %1, 1
  br i1 %132, label %135, label %133

133:                                              ; preds = %126
  %134 = tail call fastcc i32 @sqlite3VdbeMemTranslate(ptr noundef %0, i8 noundef zeroext %1)
  br label %135

135:                                              ; preds = %133, %126, %124, %110, %106
  %136 = getelementptr inbounds i8, ptr %0, i64 22
  %137 = load i8, ptr %136, align 2, !tbaa !142
  %138 = and i8 %1, -9
  %139 = icmp eq i8 %137, %138
  br i1 %139, label %140, label %143

140:                                              ; preds = %135
  %141 = getelementptr inbounds i8, ptr %0, i64 8
  %142 = load ptr, ptr %141, align 8, !tbaa !85
  br label %143

143:                                              ; preds = %140, %135, %100, %75, %20
  %144 = phi ptr [ %142, %140 ], [ null, %135 ], [ null, %20 ], [ null, %75 ], [ null, %100 ]
  ret ptr %144
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc range(i32 0, 8) i32 @vdbeMemAddTerminator(ptr noundef %0) unnamed_addr #4 {
  %2 = getelementptr inbounds i8, ptr %0, i64 16
  %3 = load i32, ptr %2, align 8, !tbaa !338
  %4 = add nsw i32 %3, 3
  %5 = tail call fastcc i32 @sqlite3VdbeMemGrow(ptr noundef %0, i32 noundef %4, i32 noundef 1)
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %26

7:                                                ; preds = %1
  %8 = getelementptr inbounds i8, ptr %0, i64 8
  %9 = load ptr, ptr %8, align 8, !tbaa !85
  %10 = load i32, ptr %2, align 8, !tbaa !338
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds i8, ptr %9, i64 %11
  store i8 0, ptr %12, align 1, !tbaa !30
  %13 = load ptr, ptr %8, align 8, !tbaa !85
  %14 = load i32, ptr %2, align 8, !tbaa !338
  %15 = sext i32 %14 to i64
  %16 = getelementptr i8, ptr %13, i64 %15
  %17 = getelementptr i8, ptr %16, i64 1
  store i8 0, ptr %17, align 1, !tbaa !30
  %18 = load ptr, ptr %8, align 8, !tbaa !85
  %19 = load i32, ptr %2, align 8, !tbaa !338
  %20 = sext i32 %19 to i64
  %21 = getelementptr i8, ptr %18, i64 %20
  %22 = getelementptr i8, ptr %21, i64 2
  store i8 0, ptr %22, align 1, !tbaa !30
  %23 = getelementptr inbounds i8, ptr %0, i64 20
  %24 = load i16, ptr %23, align 4, !tbaa !83
  %25 = or i16 %24, 512
  store i16 %25, ptr %23, align 4, !tbaa !83
  br label %26

26:                                               ; preds = %7, %1
  %27 = phi i32 [ 0, %7 ], [ 7, %1 ]
  ret i32 %27
}

; Function Attrs: nounwind ssp uwtable
define hidden fastcc void @vdbeMemRenderNum(ptr noundef %0, ptr nocapture noundef %1) unnamed_addr #1 {
  %3 = alloca [22 x i8], align 16
  %4 = alloca %struct.sqlite3_str, align 8
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #16
  %5 = getelementptr inbounds i8, ptr %1, i64 20
  %6 = load i16, ptr %5, align 4, !tbaa !83
  %7 = and i16 %6, 4
  %8 = icmp eq i16 %7, 0
  br i1 %8, label %43, label %9

9:                                                ; preds = %2
  %10 = load i64, ptr %1, align 8, !tbaa !30
  call void @llvm.lifetime.start.p0(i64 22, ptr nonnull %3) #16
  %11 = icmp slt i64 %10, 0
  %12 = tail call i64 @llvm.abs.i64(i64 %10, i1 false)
  %13 = getelementptr inbounds i8, ptr %3, i64 21
  store i8 0, ptr %13, align 1, !tbaa !30
  %14 = urem i64 %12, 10
  %15 = trunc nuw nsw i64 %14 to i8
  %16 = or disjoint i8 %15, 48
  %17 = getelementptr inbounds i8, ptr %3, i64 20
  store i8 %16, ptr %17, align 4, !tbaa !30
  %18 = icmp ult i64 %12, 10
  br i1 %18, label %31, label %19

19:                                               ; preds = %19, %9
  %20 = phi i64 [ %23, %19 ], [ 20, %9 ]
  %21 = phi i64 [ %22, %19 ], [ %12, %9 ]
  %22 = udiv i64 %21, 10
  %23 = add nsw i64 %20, -1
  %24 = urem i64 %22, 10
  %25 = trunc nuw nsw i64 %24 to i8
  %26 = or disjoint i8 %25, 48
  %27 = getelementptr inbounds [22 x i8], ptr %3, i64 0, i64 %23
  store i8 %26, ptr %27, align 1, !tbaa !30
  %28 = icmp ult i64 %21, 100
  br i1 %28, label %29, label %19, !llvm.loop !339

29:                                               ; preds = %19
  %30 = trunc nsw i64 %23 to i32
  br label %31

31:                                               ; preds = %29, %9
  %32 = phi i32 [ 20, %9 ], [ %30, %29 ]
  br i1 %11, label %33, label %37

33:                                               ; preds = %31
  %34 = add nsw i32 %32, -1
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [22 x i8], ptr %3, i64 0, i64 %35
  store i8 45, ptr %36, align 1, !tbaa !30
  br label %37

37:                                               ; preds = %33, %31
  %38 = phi i32 [ %34, %33 ], [ %32, %31 ]
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds [22 x i8], ptr %3, i64 0, i64 %39
  %41 = sub nsw i64 22, %39
  call void @llvm.memcpy.p0.p0.i64(ptr noundef align 1 %0, ptr noundef nonnull align 1 %40, i64 noundef %41, i1 noundef false) #16
  %42 = sub i32 21, %38
  call void @llvm.lifetime.end.p0(i64 22, ptr nonnull %3) #16
  br label %60

43:                                               ; preds = %2
  %44 = getelementptr inbounds i8, ptr %4, i64 8
  store ptr %0, ptr %44, align 8, !tbaa !77
  store ptr null, ptr %4, align 8, !tbaa !98
  %45 = getelementptr inbounds i8, ptr %4, i64 16
  store i32 32, ptr %45, align 8, !tbaa !76
  %46 = getelementptr inbounds i8, ptr %4, i64 20
  %47 = getelementptr inbounds i8, ptr %4, i64 24
  %48 = and i16 %6, 32
  %49 = icmp eq i16 %48, 0
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(10) %46, i8 0, i64 10, i1 false)
  br i1 %49, label %53, label %50

50:                                               ; preds = %43
  %51 = load i64, ptr %1, align 8, !tbaa !30
  %52 = sitofp i64 %51 to double
  br label %55

53:                                               ; preds = %43
  %54 = load double, ptr %1, align 8, !tbaa !30
  br label %55

55:                                               ; preds = %53, %50
  %56 = phi double [ %52, %50 ], [ %54, %53 ]
  call void (ptr, ptr, ...) @sqlite3_str_appendf(ptr noundef nonnull %4, ptr noundef nonnull @.str.144, double noundef %56)
  %57 = load i32, ptr %47, align 8, !tbaa !75
  %58 = zext i32 %57 to i64
  %59 = getelementptr inbounds i8, ptr %0, i64 %58
  store i8 0, ptr %59, align 1, !tbaa !30
  br label %60

60:                                               ; preds = %55, %37
  %61 = phi i32 [ %57, %55 ], [ %42, %37 ]
  %62 = getelementptr inbounds i8, ptr %1, i64 16
  store i32 %61, ptr %62, align 8, !tbaa !338
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #16
  ret void
}

; Function Attrs: nofree noinline norecurse nounwind ssp uwtable
define hidden fastcc double @memRealValue(ptr nocapture noundef readonly %0) unnamed_addr #12 {
  %2 = alloca double, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #16
  store double 0.000000e+00, ptr %2, align 8, !tbaa !115
  %3 = getelementptr inbounds i8, ptr %0, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !85
  %5 = getelementptr inbounds i8, ptr %0, i64 16
  %6 = load i32, ptr %5, align 8, !tbaa !338
  %7 = getelementptr inbounds i8, ptr %0, i64 22
  %8 = load i8, ptr %7, align 2, !tbaa !142
  %9 = call fastcc i32 @sqlite3AtoF(ptr noundef %4, ptr noundef nonnull %2, i32 noundef %6, i8 noundef zeroext %8)
  %10 = load double, ptr %2, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #16
  ret double %10
}

; Function Attrs: nofree norecurse nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: readwrite) uwtable
define hidden fastcc range(i32 -1, -2147483648) i32 @sqlite3AtoF(ptr noundef readonly %0, ptr nocapture noundef %1, i32 noundef %2, i8 noundef zeroext %3) unnamed_addr #13 {
  %5 = alloca double, align 8
  %6 = alloca double, align 8
  %7 = alloca double, align 8
  %8 = alloca double, align 8
  %9 = alloca double, align 8
  %10 = alloca double, align 8
  %11 = alloca double, align 8
  %12 = alloca double, align 8
  %13 = alloca double, align 8
  %14 = alloca double, align 8
  %15 = alloca double, align 8
  %16 = alloca double, align 8
  %17 = alloca double, align 8
  %18 = alloca double, align 8
  %19 = alloca double, align 8
  %20 = alloca double, align 8
  %21 = alloca double, align 8
  %22 = alloca double, align 8
  %23 = alloca double, align 8
  %24 = alloca double, align 8
  %25 = alloca double, align 8
  %26 = alloca double, align 8
  %27 = alloca double, align 8
  %28 = alloca double, align 8
  %29 = alloca double, align 8
  %30 = alloca double, align 8
  %31 = alloca double, align 8
  %32 = alloca double, align 8
  %33 = alloca double, align 8
  %34 = alloca double, align 8
  %35 = alloca double, align 8
  %36 = alloca double, align 8
  %37 = alloca double, align 8
  %38 = alloca double, align 8
  %39 = alloca double, align 8
  %40 = alloca double, align 8
  %41 = alloca double, align 16
  %42 = alloca double, align 8
  store double 0.000000e+00, ptr %1, align 8, !tbaa !115
  %43 = icmp eq i32 %2, 0
  br i1 %43, label %668, label %44

44:                                               ; preds = %4
  %45 = zext i8 %3 to i32
  %46 = icmp eq i8 %3, 1
  br i1 %46, label %74, label %47

47:                                               ; preds = %44
  %48 = and i32 %2, -2
  %49 = sub nsw i32 3, %45
  %50 = icmp slt i32 %49, %48
  br i1 %50, label %51, label %67

51:                                               ; preds = %47
  %52 = sub nsw i32 3, %45
  %53 = sext i32 %52 to i64
  %54 = sext i32 %48 to i64
  br label %55

55:                                               ; preds = %60, %51
  %56 = phi i64 [ %53, %51 ], [ %61, %60 ]
  %57 = getelementptr inbounds i8, ptr %0, i64 %56
  %58 = load i8, ptr %57, align 1, !tbaa !30
  %59 = icmp eq i8 %58, 0
  br i1 %59, label %60, label %63

60:                                               ; preds = %55
  %61 = add nsw i64 %56, 2
  %62 = icmp slt i64 %61, %54
  br i1 %62, label %55, label %63, !llvm.loop !340

63:                                               ; preds = %60, %55
  %64 = phi i64 [ %56, %55 ], [ %61, %60 ]
  %65 = phi i32 [ -100, %55 ], [ 1, %60 ]
  %66 = trunc i64 %64 to i32
  br label %67

67:                                               ; preds = %63, %47
  %68 = phi i32 [ %49, %47 ], [ %66, %63 ]
  %69 = phi i32 [ 1, %47 ], [ %65, %63 ]
  %70 = xor i32 %68, 1
  %71 = and i32 %45, 1
  %72 = zext nneg i32 %71 to i64
  %73 = getelementptr inbounds i8, ptr %0, i64 %72
  br label %74

74:                                               ; preds = %67, %44
  %75 = phi i64 [ 2, %67 ], [ 1, %44 ]
  %76 = phi i32 [ %70, %67 ], [ %2, %44 ]
  %77 = phi i32 [ %69, %67 ], [ 1, %44 ]
  %78 = phi ptr [ %73, %67 ], [ %0, %44 ]
  %79 = sext i32 %76 to i64
  %80 = getelementptr inbounds i8, ptr %0, i64 %79
  %81 = icmp ult ptr %78, %80
  br i1 %81, label %82, label %668

82:                                               ; preds = %74
  %83 = load i8, ptr %78, align 1, !tbaa !30
  %84 = zext i8 %83 to i64
  %85 = getelementptr inbounds [256 x i8], ptr @sqlite3CtypeMap, i64 0, i64 %84
  %86 = load i8, ptr %85, align 1, !tbaa !30
  %87 = and i8 %86, 1
  %88 = icmp eq i8 %87, 0
  br i1 %88, label %100, label %96

89:                                               ; preds = %96
  %90 = load i8, ptr %98, align 1, !tbaa !30
  %91 = zext i8 %90 to i64
  %92 = getelementptr inbounds [256 x i8], ptr @sqlite3CtypeMap, i64 0, i64 %91
  %93 = load i8, ptr %92, align 1, !tbaa !30
  %94 = and i8 %93, 1
  %95 = icmp eq i8 %94, 0
  br i1 %95, label %100, label %96, !llvm.loop !341

96:                                               ; preds = %89, %82
  %97 = phi ptr [ %98, %89 ], [ %78, %82 ]
  %98 = getelementptr inbounds i8, ptr %97, i64 %75
  %99 = icmp ult ptr %98, %80
  br i1 %99, label %89, label %668, !llvm.loop !341

100:                                              ; preds = %89, %82
  %101 = phi i1 [ %81, %82 ], [ %99, %89 ]
  %102 = phi ptr [ %78, %82 ], [ %98, %89 ]
  br i1 %101, label %103, label %668

103:                                              ; preds = %100
  %104 = load i8, ptr %102, align 1, !tbaa !30
  %105 = icmp eq i8 %104, 45
  %106 = icmp eq i8 %104, 43
  %107 = or i1 %105, %106
  %108 = select i1 %107, i64 %75, i64 0
  %109 = getelementptr inbounds i8, ptr %102, i64 %108
  %110 = icmp ult ptr %109, %80
  br i1 %110, label %111, label %251

111:                                              ; preds = %103
  %112 = load i8, ptr %109, align 1, !tbaa !30
  %113 = zext i8 %112 to i64
  %114 = add nsw i64 %113, -58
  %115 = icmp ult i64 %114, -10
  br i1 %115, label %151, label %121

116:                                              ; preds = %147
  %117 = load i8, ptr %149, align 1, !tbaa !30
  %118 = zext i8 %117 to i64
  %119 = add nsw i64 %118, -58
  %120 = icmp ult i64 %119, -10
  br i1 %120, label %151, label %121, !llvm.loop !342

121:                                              ; preds = %116, %111
  %122 = phi i8 [ %117, %116 ], [ %112, %111 ]
  %123 = phi i64 [ %130, %116 ], [ 0, %111 ]
  %124 = phi i32 [ %148, %116 ], [ 0, %111 ]
  %125 = phi i32 [ %132, %116 ], [ 0, %111 ]
  %126 = phi ptr [ %149, %116 ], [ %109, %111 ]
  %127 = mul i64 %123, 10
  %128 = sext i8 %122 to i64
  %129 = add i64 %127, -48
  %130 = add i64 %129, %128
  %131 = getelementptr inbounds i8, ptr %126, i64 %75
  %132 = add nuw nsw i32 %125, 1
  %133 = icmp ugt i64 %130, 1844674407370955159
  %134 = icmp ult ptr %131, %80
  %135 = select i1 %133, i1 %134, i1 false
  br i1 %135, label %136, label %147

136:                                              ; preds = %143, %121
  %137 = phi ptr [ %144, %143 ], [ %131, %121 ]
  %138 = phi i32 [ %145, %143 ], [ %124, %121 ]
  %139 = load i8, ptr %137, align 1, !tbaa !30
  %140 = zext i8 %139 to i64
  %141 = add nsw i64 %140, -58
  %142 = icmp ult i64 %141, -10
  br i1 %142, label %147, label %143

143:                                              ; preds = %136
  %144 = getelementptr inbounds i8, ptr %137, i64 %75
  %145 = add nsw i32 %138, 1
  %146 = icmp ult ptr %144, %80
  br i1 %146, label %136, label %147, !llvm.loop !343

147:                                              ; preds = %143, %136, %121
  %148 = phi i32 [ %124, %121 ], [ %138, %136 ], [ %145, %143 ]
  %149 = phi ptr [ %131, %121 ], [ %137, %136 ], [ %144, %143 ]
  %150 = icmp ult ptr %149, %80
  br i1 %150, label %116, label %251, !llvm.loop !342

151:                                              ; preds = %116, %111
  %152 = phi i1 [ %110, %111 ], [ %150, %116 ]
  %153 = phi ptr [ %109, %111 ], [ %149, %116 ]
  %154 = phi i32 [ 0, %111 ], [ %132, %116 ]
  %155 = phi i32 [ 0, %111 ], [ %148, %116 ]
  %156 = phi i64 [ 0, %111 ], [ %130, %116 ]
  br i1 %152, label %157, label %251

157:                                              ; preds = %151
  %158 = load i8, ptr %153, align 1, !tbaa !30
  %159 = icmp eq i8 %158, 46
  br i1 %159, label %160, label %188

160:                                              ; preds = %157
  %161 = add nsw i32 %77, 1
  %162 = getelementptr inbounds i8, ptr %153, i64 %75
  %163 = icmp ult ptr %162, %80
  br i1 %163, label %164, label %188

164:                                              ; preds = %182, %160
  %165 = phi ptr [ %186, %182 ], [ %162, %160 ]
  %166 = phi i32 [ %185, %182 ], [ %154, %160 ]
  %167 = phi i32 [ %184, %182 ], [ %155, %160 ]
  %168 = phi i64 [ %183, %182 ], [ %156, %160 ]
  %169 = load i8, ptr %165, align 1, !tbaa !30
  %170 = zext i8 %169 to i64
  %171 = add nsw i64 %170, -58
  %172 = icmp ult i64 %171, -10
  br i1 %172, label %188, label %173

173:                                              ; preds = %164
  %174 = icmp ult i64 %168, 1844674407370955160
  br i1 %174, label %175, label %182

175:                                              ; preds = %173
  %176 = mul nuw i64 %168, 10
  %177 = sext i8 %169 to i64
  %178 = add i64 %176, -48
  %179 = add i64 %178, %177
  %180 = add nsw i32 %167, -1
  %181 = add nsw i32 %166, 1
  br label %182

182:                                              ; preds = %175, %173
  %183 = phi i64 [ %179, %175 ], [ %168, %173 ]
  %184 = phi i32 [ %180, %175 ], [ %167, %173 ]
  %185 = phi i32 [ %181, %175 ], [ %166, %173 ]
  %186 = getelementptr inbounds i8, ptr %165, i64 %75
  %187 = icmp ult ptr %186, %80
  br i1 %187, label %164, label %188, !llvm.loop !344

188:                                              ; preds = %182, %164, %160, %157
  %189 = phi i64 [ %156, %157 ], [ %156, %160 ], [ %168, %164 ], [ %183, %182 ]
  %190 = phi i32 [ %155, %157 ], [ %155, %160 ], [ %167, %164 ], [ %184, %182 ]
  %191 = phi i32 [ %154, %157 ], [ %154, %160 ], [ %166, %164 ], [ %185, %182 ]
  %192 = phi i32 [ %77, %157 ], [ %161, %160 ], [ %161, %164 ], [ %161, %182 ]
  %193 = phi ptr [ %153, %157 ], [ %162, %160 ], [ %165, %164 ], [ %186, %182 ]
  %194 = icmp ult ptr %193, %80
  br i1 %194, label %195, label %251

195:                                              ; preds = %188
  %196 = load i8, ptr %193, align 1, !tbaa !30
  switch i8 %196, label %233 [
    i8 101, label %197
    i8 69, label %197
  ]

197:                                              ; preds = %195, %195
  %198 = getelementptr inbounds i8, ptr %193, i64 %75
  %199 = add nsw i32 %192, 1
  %200 = icmp ult ptr %198, %80
  br i1 %200, label %201, label %251

201:                                              ; preds = %197
  %202 = load i8, ptr %198, align 1, !tbaa !30
  switch i8 %202, label %207 [
    i8 45, label %203
    i8 43, label %205
  ]

203:                                              ; preds = %201
  %204 = getelementptr inbounds i8, ptr %198, i64 %75
  br label %207

205:                                              ; preds = %201
  %206 = getelementptr inbounds i8, ptr %198, i64 %75
  br label %207

207:                                              ; preds = %205, %203, %201
  %208 = phi i32 [ -1, %203 ], [ 1, %205 ], [ 1, %201 ]
  %209 = phi ptr [ %204, %203 ], [ %206, %205 ], [ %198, %201 ]
  %210 = icmp ult ptr %209, %80
  br i1 %210, label %211, label %233

211:                                              ; preds = %207
  %212 = load i8, ptr %209, align 1, !tbaa !30
  %213 = zext i8 %212 to i64
  %214 = add nsw i64 %213, -58
  %215 = icmp ult i64 %214, -10
  br i1 %215, label %233, label %221

216:                                              ; preds = %221
  %217 = load i8, ptr %231, align 1, !tbaa !30
  %218 = zext i8 %217 to i64
  %219 = add nsw i64 %218, -58
  %220 = icmp ult i64 %219, -10
  br i1 %220, label %233, label %221, !llvm.loop !345

221:                                              ; preds = %216, %211
  %222 = phi i8 [ %217, %216 ], [ %212, %211 ]
  %223 = phi i32 [ %230, %216 ], [ 0, %211 ]
  %224 = phi ptr [ %231, %216 ], [ %209, %211 ]
  %225 = icmp slt i32 %223, 10000
  %226 = mul nsw i32 %223, 10
  %227 = sext i8 %222 to i32
  %228 = add i32 %226, -48
  %229 = add i32 %228, %227
  %230 = select i1 %225, i32 %229, i32 10000
  %231 = getelementptr inbounds i8, ptr %224, i64 %75
  %232 = icmp ult ptr %231, %80
  br i1 %232, label %216, label %233, !llvm.loop !345

233:                                              ; preds = %221, %216, %211, %207, %195
  %234 = phi i32 [ 1, %195 ], [ %208, %207 ], [ %208, %211 ], [ %208, %221 ], [ %208, %216 ]
  %235 = phi i32 [ 0, %195 ], [ 0, %207 ], [ 0, %211 ], [ %230, %221 ], [ %230, %216 ]
  %236 = phi i32 [ 1, %195 ], [ 0, %207 ], [ 0, %211 ], [ 1, %221 ], [ 1, %216 ]
  %237 = phi i32 [ %192, %195 ], [ %199, %207 ], [ %199, %211 ], [ %199, %221 ], [ %199, %216 ]
  %238 = phi ptr [ %193, %195 ], [ %209, %207 ], [ %209, %211 ], [ %231, %221 ], [ %231, %216 ]
  %239 = icmp ult ptr %238, %80
  br i1 %239, label %240, label %251

240:                                              ; preds = %248, %233
  %241 = phi ptr [ %249, %248 ], [ %238, %233 ]
  %242 = load i8, ptr %241, align 1, !tbaa !30
  %243 = zext i8 %242 to i64
  %244 = getelementptr inbounds [256 x i8], ptr @sqlite3CtypeMap, i64 0, i64 %243
  %245 = load i8, ptr %244, align 1, !tbaa !30
  %246 = and i8 %245, 1
  %247 = icmp eq i8 %246, 0
  br i1 %247, label %251, label %248

248:                                              ; preds = %240
  %249 = getelementptr inbounds i8, ptr %241, i64 %75
  %250 = icmp ult ptr %249, %80
  br i1 %250, label %240, label %251, !llvm.loop !346

251:                                              ; preds = %248, %240, %233, %197, %188, %151, %147, %103
  %252 = phi i64 [ %156, %151 ], [ %189, %188 ], [ %189, %197 ], [ %189, %233 ], [ 0, %103 ], [ %189, %240 ], [ %189, %248 ], [ %130, %147 ]
  %253 = phi i32 [ %155, %151 ], [ %190, %188 ], [ %190, %197 ], [ %190, %233 ], [ 0, %103 ], [ %190, %240 ], [ %190, %248 ], [ %148, %147 ]
  %254 = phi i32 [ 1, %151 ], [ 1, %188 ], [ 1, %197 ], [ %234, %233 ], [ 1, %103 ], [ %234, %240 ], [ %234, %248 ], [ 1, %147 ]
  %255 = phi i32 [ 0, %151 ], [ 0, %188 ], [ 0, %197 ], [ %235, %233 ], [ 0, %103 ], [ %235, %240 ], [ %235, %248 ], [ 0, %147 ]
  %256 = phi i32 [ 1, %151 ], [ 1, %188 ], [ 0, %197 ], [ %236, %233 ], [ 1, %103 ], [ %236, %240 ], [ %236, %248 ], [ 1, %147 ]
  %257 = phi i32 [ %154, %151 ], [ %191, %188 ], [ %191, %197 ], [ %191, %233 ], [ 0, %103 ], [ %191, %240 ], [ %191, %248 ], [ %132, %147 ]
  %258 = phi i32 [ %77, %151 ], [ %192, %188 ], [ %199, %197 ], [ %237, %233 ], [ %77, %103 ], [ %237, %240 ], [ %237, %248 ], [ %77, %147 ]
  %259 = phi ptr [ %153, %151 ], [ %193, %188 ], [ %198, %197 ], [ %238, %233 ], [ %109, %103 ], [ %249, %248 ], [ %241, %240 ], [ %149, %147 ]
  %260 = icmp eq i64 %252, 0
  br i1 %260, label %261, label %263

261:                                              ; preds = %251
  %262 = select i1 %105, double -0.000000e+00, double 0.000000e+00
  br label %651

263:                                              ; preds = %251
  %264 = mul nsw i32 %255, %254
  %265 = add nsw i32 %264, %253
  %266 = icmp sgt i32 %265, 0
  %267 = icmp ult i64 %252, 1844674407370955161
  %268 = and i1 %266, %267
  br i1 %268, label %276, label %269

269:                                              ; preds = %276, %263
  %270 = phi i64 [ %252, %263 ], [ %279, %276 ]
  %271 = phi i32 [ %265, %263 ], [ %280, %276 ]
  %272 = icmp slt i32 %271, 0
  %273 = urem i64 %270, 10
  %274 = icmp eq i64 %273, 0
  %275 = select i1 %272, i1 %274, i1 false
  br i1 %275, label %284, label %293

276:                                              ; preds = %276, %263
  %277 = phi i32 [ %280, %276 ], [ %265, %263 ]
  %278 = phi i64 [ %279, %276 ], [ %252, %263 ]
  %279 = mul nuw i64 %278, 10
  %280 = add nsw i32 %277, -1
  %281 = icmp sgt i32 %277, 1
  %282 = icmp ult i64 %278, 184467440737095517
  %283 = select i1 %281, i1 %282, i1 false
  br i1 %283, label %276, label %269, !llvm.loop !347

284:                                              ; preds = %284, %269
  %285 = phi i32 [ %288, %284 ], [ %271, %269 ]
  %286 = phi i64 [ %287, %284 ], [ %270, %269 ]
  %287 = udiv i64 %286, 10
  %288 = add nsw i32 %285, 1
  %289 = icmp slt i32 %285, -1
  %290 = urem i64 %287, 10
  %291 = icmp eq i64 %290, 0
  %292 = select i1 %289, i1 %291, i1 false
  br i1 %292, label %284, label %293, !llvm.loop !348

293:                                              ; preds = %284, %269
  %294 = phi i64 [ %270, %269 ], [ %287, %284 ]
  %295 = phi i32 [ %271, %269 ], [ %288, %284 ]
  %296 = icmp eq i32 %295, 0
  br i1 %296, label %297, label %299

297:                                              ; preds = %293
  %298 = uitofp i64 %294 to double
  store double %298, ptr %1, align 8, !tbaa !115
  br label %647

299:                                              ; preds = %293
  %300 = load i8, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 10), align 2, !tbaa !62
  %301 = icmp eq i8 %300, 0
  br i1 %301, label %366, label %302

302:                                              ; preds = %299
  %303 = uitofp i64 %294 to x86_fp80
  %304 = icmp sgt i32 %295, 0
  br i1 %304, label %307, label %305

305:                                              ; preds = %302
  %306 = icmp slt i32 %295, -99
  br i1 %306, label %339, label %335

307:                                              ; preds = %302
  %308 = icmp sgt i32 %295, 99
  br i1 %308, label %313, label %309

309:                                              ; preds = %313, %307
  %310 = phi i32 [ %295, %307 ], [ %316, %313 ]
  %311 = phi x86_fp80 [ %303, %307 ], [ %317, %313 ]
  %312 = icmp sgt i32 %310, 9
  br i1 %312, label %323, label %319

313:                                              ; preds = %313, %307
  %314 = phi x86_fp80 [ %317, %313 ], [ %303, %307 ]
  %315 = phi i32 [ %316, %313 ], [ %295, %307 ]
  %316 = add nsw i32 %315, -100
  %317 = fmul x86_fp80 %314, 0xK414B924D692CA61BE758
  %318 = icmp sgt i32 %315, 199
  br i1 %318, label %313, label %309, !llvm.loop !349

319:                                              ; preds = %323, %309
  %320 = phi i32 [ %310, %309 ], [ %326, %323 ]
  %321 = phi x86_fp80 [ %311, %309 ], [ %327, %323 ]
  %322 = icmp sgt i32 %320, 0
  br i1 %322, label %329, label %361

323:                                              ; preds = %323, %309
  %324 = phi x86_fp80 [ %327, %323 ], [ %311, %309 ]
  %325 = phi i32 [ %326, %323 ], [ %310, %309 ]
  %326 = add nsw i32 %325, -10
  %327 = fmul x86_fp80 %324, 0xK40209502F90000000000
  %328 = icmp sgt i32 %325, 19
  br i1 %328, label %323, label %319, !llvm.loop !350

329:                                              ; preds = %329, %319
  %330 = phi x86_fp80 [ %333, %329 ], [ %321, %319 ]
  %331 = phi i32 [ %332, %329 ], [ %320, %319 ]
  %332 = add nsw i32 %331, -1
  %333 = fmul x86_fp80 %330, 0xK4002A000000000000000
  %334 = icmp sgt i32 %331, 1
  br i1 %334, label %329, label %361, !llvm.loop !351

335:                                              ; preds = %339, %305
  %336 = phi i32 [ %295, %305 ], [ %342, %339 ]
  %337 = phi x86_fp80 [ %303, %305 ], [ %343, %339 ]
  %338 = icmp slt i32 %336, -9
  br i1 %338, label %349, label %345

339:                                              ; preds = %339, %305
  %340 = phi x86_fp80 [ %343, %339 ], [ %303, %305 ]
  %341 = phi i32 [ %342, %339 ], [ %295, %305 ]
  %342 = add nsw i32 %341, 100
  %343 = fmul x86_fp80 %340, 0xK3EB2DFF9772470297EBD
  %344 = icmp slt i32 %341, -199
  br i1 %344, label %339, label %335, !llvm.loop !352

345:                                              ; preds = %349, %335
  %346 = phi i32 [ %336, %335 ], [ %352, %349 ]
  %347 = phi x86_fp80 [ %337, %335 ], [ %353, %349 ]
  %348 = icmp slt i32 %346, 0
  br i1 %348, label %355, label %361

349:                                              ; preds = %349, %335
  %350 = phi x86_fp80 [ %353, %349 ], [ %337, %335 ]
  %351 = phi i32 [ %352, %349 ], [ %336, %335 ]
  %352 = add nsw i32 %351, 10
  %353 = fmul x86_fp80 %350, 0xK3FDDDBE6FECEBDEDD5BF
  %354 = icmp slt i32 %351, -19
  br i1 %354, label %349, label %345, !llvm.loop !353

355:                                              ; preds = %355, %345
  %356 = phi x86_fp80 [ %359, %355 ], [ %347, %345 ]
  %357 = phi i32 [ %358, %355 ], [ %346, %345 ]
  %358 = add i32 %357, 1
  %359 = fmul x86_fp80 %356, 0xK3FFBCCCCCCCCCCCCCCCD
  %360 = icmp eq i32 %358, 0
  br i1 %360, label %361, label %355, !llvm.loop !354

361:                                              ; preds = %355, %345, %329, %319
  %362 = phi x86_fp80 [ %321, %319 ], [ %347, %345 ], [ %333, %329 ], [ %359, %355 ]
  %363 = fcmp ogt x86_fp80 %362, 0xK43FEFFFFFFFFFFFFF800
  %364 = fptrunc x86_fp80 %362 to double
  %365 = select i1 %363, double 0x7FF0000000000000, double %364
  store double %365, ptr %1, align 8, !tbaa !115
  br label %647

366:                                              ; preds = %299
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %41)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %42)
  %367 = uitofp i64 %294 to double
  store double %367, ptr %41, align 16, !tbaa !115
  %368 = fptoui double %367 to i64
  %369 = icmp ult i64 %294, %368
  br i1 %369, label %373, label %370

370:                                              ; preds = %366
  %371 = sub i64 %294, %368
  %372 = uitofp i64 %371 to double
  br label %377

373:                                              ; preds = %366
  %374 = sub i64 %368, %294
  %375 = uitofp i64 %374 to double
  %376 = fneg double %375
  br label %377

377:                                              ; preds = %373, %370
  %378 = phi double [ %372, %370 ], [ %376, %373 ]
  store double %378, ptr %42, align 8, !tbaa !115
  %379 = icmp sgt i32 %295, 0
  br i1 %379, label %382, label %380

380:                                              ; preds = %377
  %381 = icmp slt i32 %295, -99
  br i1 %381, label %513, label %510

382:                                              ; preds = %377
  %383 = icmp sgt i32 %295, 99
  br i1 %383, label %387, label %384

384:                                              ; preds = %387, %382
  %385 = phi i32 [ %295, %382 ], [ %389, %387 ]
  %386 = icmp sgt i32 %385, 9
  br i1 %386, label %430, label %427

387:                                              ; preds = %387, %382
  %388 = phi i32 [ %389, %387 ], [ %295, %382 ]
  %389 = add nsw i32 %388, -100
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %35)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %36)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %37)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %38)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %39)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %40)
  %390 = load i64, ptr %41, align 16
  %391 = and i64 %390, -67108864
  %392 = bitcast i64 %391 to double
  %393 = load volatile double, ptr %41, align 16, !tbaa !115
  %394 = fsub double %393, %392
  store volatile double %394, ptr %35, align 8, !tbaa !115
  store volatile double 0x52F94C37D0000000, ptr %36, align 8, !tbaa !115
  %395 = fmul double %392, 0x54B249AD24000000
  store volatile double %395, ptr %37, align 8, !tbaa !115
  %396 = load volatile double, ptr %36, align 8, !tbaa !115
  %397 = load volatile double, ptr %35, align 8, !tbaa !115
  %398 = fmul double %397, 0x54B249AD24000000
  %399 = tail call double @llvm.fmuladd.f64(double %392, double %396, double %398)
  store volatile double %399, ptr %38, align 8, !tbaa !115
  %400 = load volatile double, ptr %37, align 8, !tbaa !115
  %401 = load volatile double, ptr %38, align 8, !tbaa !115
  %402 = fadd double %400, %401
  store volatile double %402, ptr %39, align 8, !tbaa !115
  %403 = load volatile double, ptr %37, align 8, !tbaa !115
  %404 = load volatile double, ptr %39, align 8, !tbaa !115
  %405 = fsub double %403, %404
  %406 = load volatile double, ptr %38, align 8, !tbaa !115
  %407 = fadd double %405, %406
  %408 = load volatile double, ptr %35, align 8, !tbaa !115
  %409 = load volatile double, ptr %36, align 8, !tbaa !115
  %410 = tail call double @llvm.fmuladd.f64(double %408, double %409, double %407)
  store volatile double %410, ptr %40, align 8, !tbaa !115
  %411 = load volatile double, ptr %41, align 16, !tbaa !115
  %412 = load volatile double, ptr %42, align 8, !tbaa !115
  %413 = fmul double %412, 1.000000e+100
  %414 = tail call double @llvm.fmuladd.f64(double %411, double 0xD134F4D87B3B31F4, double %413)
  %415 = load volatile double, ptr %40, align 8, !tbaa !115
  %416 = fadd double %415, %414
  store volatile double %416, ptr %40, align 8, !tbaa !115
  %417 = load volatile double, ptr %39, align 8, !tbaa !115
  %418 = load volatile double, ptr %40, align 8, !tbaa !115
  %419 = fadd double %417, %418
  store volatile double %419, ptr %41, align 16, !tbaa !115
  %420 = load volatile double, ptr %39, align 8, !tbaa !115
  %421 = load volatile double, ptr %41, align 16, !tbaa !115
  %422 = fsub double %420, %421
  store volatile double %422, ptr %42, align 8, !tbaa !115
  %423 = load volatile double, ptr %40, align 8, !tbaa !115
  %424 = load volatile double, ptr %42, align 8, !tbaa !115
  %425 = fadd double %423, %424
  store volatile double %425, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %40)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %39)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %38)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %37)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %36)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %35)
  %426 = icmp sgt i32 %388, 199
  br i1 %426, label %387, label %384, !llvm.loop !355

427:                                              ; preds = %430, %384
  %428 = phi i32 [ %385, %384 ], [ %432, %430 ]
  %429 = icmp sgt i32 %428, 0
  br i1 %429, label %470, label %636

430:                                              ; preds = %430, %384
  %431 = phi i32 [ %432, %430 ], [ %385, %384 ]
  %432 = add nsw i32 %431, -10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %29)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %31)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %32)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %33)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %34)
  %433 = load i64, ptr %41, align 16
  %434 = and i64 %433, -67108864
  %435 = bitcast i64 %434 to double
  %436 = load volatile double, ptr %41, align 16, !tbaa !115
  %437 = fsub double %436, %435
  store volatile double %437, ptr %29, align 8, !tbaa !115
  store volatile double 0.000000e+00, ptr %30, align 8, !tbaa !115
  %438 = fmul double %435, 1.000000e+10
  store volatile double %438, ptr %31, align 8, !tbaa !115
  %439 = load volatile double, ptr %30, align 8, !tbaa !115
  %440 = load volatile double, ptr %29, align 8, !tbaa !115
  %441 = fmul double %440, 1.000000e+10
  %442 = tail call double @llvm.fmuladd.f64(double %435, double %439, double %441)
  store volatile double %442, ptr %32, align 8, !tbaa !115
  %443 = load volatile double, ptr %31, align 8, !tbaa !115
  %444 = load volatile double, ptr %32, align 8, !tbaa !115
  %445 = fadd double %443, %444
  store volatile double %445, ptr %33, align 8, !tbaa !115
  %446 = load volatile double, ptr %31, align 8, !tbaa !115
  %447 = load volatile double, ptr %33, align 8, !tbaa !115
  %448 = fsub double %446, %447
  %449 = load volatile double, ptr %32, align 8, !tbaa !115
  %450 = fadd double %448, %449
  %451 = load volatile double, ptr %29, align 8, !tbaa !115
  %452 = load volatile double, ptr %30, align 8, !tbaa !115
  %453 = tail call double @llvm.fmuladd.f64(double %451, double %452, double %450)
  store volatile double %453, ptr %34, align 8, !tbaa !115
  %454 = load volatile double, ptr %41, align 16, !tbaa !115
  %455 = load volatile double, ptr %42, align 8, !tbaa !115
  %456 = fmul double %455, 1.000000e+10
  %457 = tail call double @llvm.fmuladd.f64(double %454, double 0.000000e+00, double %456)
  %458 = load volatile double, ptr %34, align 8, !tbaa !115
  %459 = fadd double %458, %457
  store volatile double %459, ptr %34, align 8, !tbaa !115
  %460 = load volatile double, ptr %33, align 8, !tbaa !115
  %461 = load volatile double, ptr %34, align 8, !tbaa !115
  %462 = fadd double %460, %461
  store volatile double %462, ptr %41, align 16, !tbaa !115
  %463 = load volatile double, ptr %33, align 8, !tbaa !115
  %464 = load volatile double, ptr %41, align 16, !tbaa !115
  %465 = fsub double %463, %464
  store volatile double %465, ptr %42, align 8, !tbaa !115
  %466 = load volatile double, ptr %34, align 8, !tbaa !115
  %467 = load volatile double, ptr %42, align 8, !tbaa !115
  %468 = fadd double %466, %467
  store volatile double %468, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %34)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %33)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %32)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %31)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %29)
  %469 = icmp sgt i32 %431, 19
  br i1 %469, label %430, label %427, !llvm.loop !356

470:                                              ; preds = %470, %427
  %471 = phi i32 [ %472, %470 ], [ %428, %427 ]
  %472 = add nsw i32 %471, -1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %24)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %25)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %26)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %27)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %28)
  %473 = load i64, ptr %41, align 16
  %474 = and i64 %473, -67108864
  %475 = bitcast i64 %474 to double
  %476 = load volatile double, ptr %41, align 16, !tbaa !115
  %477 = fsub double %476, %475
  store volatile double %477, ptr %23, align 8, !tbaa !115
  store volatile double 0.000000e+00, ptr %24, align 8, !tbaa !115
  %478 = fmul double %475, 1.000000e+01
  store volatile double %478, ptr %25, align 8, !tbaa !115
  %479 = load volatile double, ptr %24, align 8, !tbaa !115
  %480 = load volatile double, ptr %23, align 8, !tbaa !115
  %481 = fmul double %480, 1.000000e+01
  %482 = tail call double @llvm.fmuladd.f64(double %475, double %479, double %481)
  store volatile double %482, ptr %26, align 8, !tbaa !115
  %483 = load volatile double, ptr %25, align 8, !tbaa !115
  %484 = load volatile double, ptr %26, align 8, !tbaa !115
  %485 = fadd double %483, %484
  store volatile double %485, ptr %27, align 8, !tbaa !115
  %486 = load volatile double, ptr %25, align 8, !tbaa !115
  %487 = load volatile double, ptr %27, align 8, !tbaa !115
  %488 = fsub double %486, %487
  %489 = load volatile double, ptr %26, align 8, !tbaa !115
  %490 = fadd double %488, %489
  %491 = load volatile double, ptr %23, align 8, !tbaa !115
  %492 = load volatile double, ptr %24, align 8, !tbaa !115
  %493 = tail call double @llvm.fmuladd.f64(double %491, double %492, double %490)
  store volatile double %493, ptr %28, align 8, !tbaa !115
  %494 = load volatile double, ptr %41, align 16, !tbaa !115
  %495 = load volatile double, ptr %42, align 8, !tbaa !115
  %496 = fmul double %495, 1.000000e+01
  %497 = tail call double @llvm.fmuladd.f64(double %494, double 0.000000e+00, double %496)
  %498 = load volatile double, ptr %28, align 8, !tbaa !115
  %499 = fadd double %498, %497
  store volatile double %499, ptr %28, align 8, !tbaa !115
  %500 = load volatile double, ptr %27, align 8, !tbaa !115
  %501 = load volatile double, ptr %28, align 8, !tbaa !115
  %502 = fadd double %500, %501
  store volatile double %502, ptr %41, align 16, !tbaa !115
  %503 = load volatile double, ptr %27, align 8, !tbaa !115
  %504 = load volatile double, ptr %41, align 16, !tbaa !115
  %505 = fsub double %503, %504
  store volatile double %505, ptr %42, align 8, !tbaa !115
  %506 = load volatile double, ptr %28, align 8, !tbaa !115
  %507 = load volatile double, ptr %42, align 8, !tbaa !115
  %508 = fadd double %506, %507
  store volatile double %508, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %28)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %27)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %23)
  %509 = icmp sgt i32 %471, 1
  br i1 %509, label %470, label %636, !llvm.loop !357

510:                                              ; preds = %513, %380
  %511 = phi i32 [ %295, %380 ], [ %515, %513 ]
  %512 = icmp slt i32 %511, -9
  br i1 %512, label %556, label %553

513:                                              ; preds = %513, %380
  %514 = phi i32 [ %515, %513 ], [ %295, %380 ]
  %515 = add nsw i32 %514, 100
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %17)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %18)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %21)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %22)
  %516 = load i64, ptr %41, align 16
  %517 = and i64 %516, -67108864
  %518 = bitcast i64 %517 to double
  %519 = load volatile double, ptr %41, align 16, !tbaa !115
  %520 = fsub double %519, %518
  store volatile double %520, ptr %17, align 8, !tbaa !115
  store volatile double 0x2951C0A600000000, ptr %18, align 8, !tbaa !115
  %521 = fmul double %518, 0x2B2BFF2EE4000000
  store volatile double %521, ptr %19, align 8, !tbaa !115
  %522 = load volatile double, ptr %18, align 8, !tbaa !115
  %523 = load volatile double, ptr %17, align 8, !tbaa !115
  %524 = fmul double %523, 0x2B2BFF2EE4000000
  %525 = tail call double @llvm.fmuladd.f64(double %518, double %522, double %524)
  store volatile double %525, ptr %20, align 8, !tbaa !115
  %526 = load volatile double, ptr %19, align 8, !tbaa !115
  %527 = load volatile double, ptr %20, align 8, !tbaa !115
  %528 = fadd double %526, %527
  store volatile double %528, ptr %21, align 8, !tbaa !115
  %529 = load volatile double, ptr %19, align 8, !tbaa !115
  %530 = load volatile double, ptr %21, align 8, !tbaa !115
  %531 = fsub double %529, %530
  %532 = load volatile double, ptr %20, align 8, !tbaa !115
  %533 = fadd double %531, %532
  %534 = load volatile double, ptr %17, align 8, !tbaa !115
  %535 = load volatile double, ptr %18, align 8, !tbaa !115
  %536 = tail call double @llvm.fmuladd.f64(double %534, double %535, double %533)
  store volatile double %536, ptr %22, align 8, !tbaa !115
  %537 = load volatile double, ptr %41, align 16, !tbaa !115
  %538 = load volatile double, ptr %42, align 8, !tbaa !115
  %539 = fmul double %538, 1.000000e-100
  %540 = tail call double @llvm.fmuladd.f64(double %537, double 0xA7B42A68781D46C4, double %539)
  %541 = load volatile double, ptr %22, align 8, !tbaa !115
  %542 = fadd double %541, %540
  store volatile double %542, ptr %22, align 8, !tbaa !115
  %543 = load volatile double, ptr %21, align 8, !tbaa !115
  %544 = load volatile double, ptr %22, align 8, !tbaa !115
  %545 = fadd double %543, %544
  store volatile double %545, ptr %41, align 16, !tbaa !115
  %546 = load volatile double, ptr %21, align 8, !tbaa !115
  %547 = load volatile double, ptr %41, align 16, !tbaa !115
  %548 = fsub double %546, %547
  store volatile double %548, ptr %42, align 8, !tbaa !115
  %549 = load volatile double, ptr %22, align 8, !tbaa !115
  %550 = load volatile double, ptr %42, align 8, !tbaa !115
  %551 = fadd double %549, %550
  store volatile double %551, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %22)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %21)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %18)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %17)
  %552 = icmp slt i32 %514, -199
  br i1 %552, label %513, label %510, !llvm.loop !358

553:                                              ; preds = %556, %510
  %554 = phi i32 [ %511, %510 ], [ %558, %556 ]
  %555 = icmp slt i32 %554, 0
  br i1 %555, label %596, label %636

556:                                              ; preds = %556, %510
  %557 = phi i32 [ %558, %556 ], [ %511, %510 ]
  %558 = add nsw i32 %557, 10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %12)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %14)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %15)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %16)
  %559 = load i64, ptr %41, align 16
  %560 = and i64 %559, -67108864
  %561 = bitcast i64 %560 to double
  %562 = load volatile double, ptr %41, align 16, !tbaa !115
  %563 = fsub double %562, %561
  store volatile double %563, ptr %11, align 8, !tbaa !115
  store volatile double 0x3C1D7BDBB0000000, ptr %12, align 8, !tbaa !115
  %564 = fmul double %561, 0x3DDB7CDFD8000000
  store volatile double %564, ptr %13, align 8, !tbaa !115
  %565 = load volatile double, ptr %12, align 8, !tbaa !115
  %566 = load volatile double, ptr %11, align 8, !tbaa !115
  %567 = fmul double %566, 0x3DDB7CDFD8000000
  %568 = tail call double @llvm.fmuladd.f64(double %561, double %565, double %567)
  store volatile double %568, ptr %14, align 8, !tbaa !115
  %569 = load volatile double, ptr %13, align 8, !tbaa !115
  %570 = load volatile double, ptr %14, align 8, !tbaa !115
  %571 = fadd double %569, %570
  store volatile double %571, ptr %15, align 8, !tbaa !115
  %572 = load volatile double, ptr %13, align 8, !tbaa !115
  %573 = load volatile double, ptr %15, align 8, !tbaa !115
  %574 = fsub double %572, %573
  %575 = load volatile double, ptr %14, align 8, !tbaa !115
  %576 = fadd double %574, %575
  %577 = load volatile double, ptr %11, align 8, !tbaa !115
  %578 = load volatile double, ptr %12, align 8, !tbaa !115
  %579 = tail call double @llvm.fmuladd.f64(double %577, double %578, double %576)
  store volatile double %579, ptr %16, align 8, !tbaa !115
  %580 = load volatile double, ptr %41, align 16, !tbaa !115
  %581 = load volatile double, ptr %42, align 8, !tbaa !115
  %582 = fmul double %581, 1.000000e-10
  %583 = tail call double @llvm.fmuladd.f64(double %580, double 0xBA720A5465DF8D2C, double %582)
  %584 = load volatile double, ptr %16, align 8, !tbaa !115
  %585 = fadd double %584, %583
  store volatile double %585, ptr %16, align 8, !tbaa !115
  %586 = load volatile double, ptr %15, align 8, !tbaa !115
  %587 = load volatile double, ptr %16, align 8, !tbaa !115
  %588 = fadd double %586, %587
  store volatile double %588, ptr %41, align 16, !tbaa !115
  %589 = load volatile double, ptr %15, align 8, !tbaa !115
  %590 = load volatile double, ptr %41, align 16, !tbaa !115
  %591 = fsub double %589, %590
  store volatile double %591, ptr %42, align 8, !tbaa !115
  %592 = load volatile double, ptr %16, align 8, !tbaa !115
  %593 = load volatile double, ptr %42, align 8, !tbaa !115
  %594 = fadd double %592, %593
  store volatile double %594, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %16)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %15)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %14)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %12)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %11)
  %595 = icmp slt i32 %557, -19
  br i1 %595, label %556, label %553, !llvm.loop !359

596:                                              ; preds = %596, %553
  %597 = phi i32 [ %598, %596 ], [ %554, %553 ]
  %598 = add i32 %597, 1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)
  %599 = load i64, ptr %41, align 16
  %600 = and i64 %599, -67108864
  %601 = bitcast i64 %600 to double
  %602 = load volatile double, ptr %41, align 16, !tbaa !115
  %603 = fsub double %602, %601
  store volatile double %603, ptr %5, align 8, !tbaa !115
  store volatile double 0x3DF99999A0000000, ptr %6, align 8, !tbaa !115
  %604 = fmul double %601, 0x3FB9999998000000
  store volatile double %604, ptr %7, align 8, !tbaa !115
  %605 = load volatile double, ptr %6, align 8, !tbaa !115
  %606 = load volatile double, ptr %5, align 8, !tbaa !115
  %607 = fmul double %606, 0x3FB9999998000000
  %608 = tail call double @llvm.fmuladd.f64(double %601, double %605, double %607)
  store volatile double %608, ptr %8, align 8, !tbaa !115
  %609 = load volatile double, ptr %7, align 8, !tbaa !115
  %610 = load volatile double, ptr %8, align 8, !tbaa !115
  %611 = fadd double %609, %610
  store volatile double %611, ptr %9, align 8, !tbaa !115
  %612 = load volatile double, ptr %7, align 8, !tbaa !115
  %613 = load volatile double, ptr %9, align 8, !tbaa !115
  %614 = fsub double %612, %613
  %615 = load volatile double, ptr %8, align 8, !tbaa !115
  %616 = fadd double %614, %615
  %617 = load volatile double, ptr %5, align 8, !tbaa !115
  %618 = load volatile double, ptr %6, align 8, !tbaa !115
  %619 = tail call double @llvm.fmuladd.f64(double %617, double %618, double %616)
  store volatile double %619, ptr %10, align 8, !tbaa !115
  %620 = load volatile double, ptr %41, align 16, !tbaa !115
  %621 = load volatile double, ptr %42, align 8, !tbaa !115
  %622 = fmul double %621, 1.000000e-01
  %623 = tail call double @llvm.fmuladd.f64(double %620, double 0xBC5999999999999A, double %622)
  %624 = load volatile double, ptr %10, align 8, !tbaa !115
  %625 = fadd double %624, %623
  store volatile double %625, ptr %10, align 8, !tbaa !115
  %626 = load volatile double, ptr %9, align 8, !tbaa !115
  %627 = load volatile double, ptr %10, align 8, !tbaa !115
  %628 = fadd double %626, %627
  store volatile double %628, ptr %41, align 16, !tbaa !115
  %629 = load volatile double, ptr %9, align 8, !tbaa !115
  %630 = load volatile double, ptr %41, align 16, !tbaa !115
  %631 = fsub double %629, %630
  store volatile double %631, ptr %42, align 8, !tbaa !115
  %632 = load volatile double, ptr %10, align 8, !tbaa !115
  %633 = load volatile double, ptr %42, align 8, !tbaa !115
  %634 = fadd double %632, %633
  store volatile double %634, ptr %42, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  %635 = icmp eq i32 %598, 0
  br i1 %635, label %636, label %596, !llvm.loop !360

636:                                              ; preds = %596, %553, %470, %427
  %637 = load double, ptr %41, align 16, !tbaa !115
  %638 = load double, ptr %42, align 8, !tbaa !115
  %639 = fadd double %637, %638
  %640 = bitcast double %639 to i64
  %641 = and i64 %640, 9218868437227405312
  %642 = icmp ne i64 %641, 9218868437227405312
  %643 = and i64 %640, 4503599627370495
  %644 = icmp eq i64 %643, 0
  %645 = or i1 %642, %644
  %646 = select i1 %645, double %639, double 0x7FF0000000000000
  store double %646, ptr %1, align 8, !tbaa !115
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %41)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %42)
  br label %647

647:                                              ; preds = %636, %361, %297
  br i1 %105, label %648, label %653

648:                                              ; preds = %647
  %649 = load double, ptr %1, align 8, !tbaa !115
  %650 = fneg double %649
  br label %651

651:                                              ; preds = %648, %261
  %652 = phi double [ %650, %648 ], [ %262, %261 ]
  store double %652, ptr %1, align 8, !tbaa !115
  br label %653

653:                                              ; preds = %651, %647
  %654 = icmp eq ptr %259, %80
  %655 = icmp sgt i32 %257, 0
  %656 = select i1 %654, i1 %655, i1 false
  %657 = icmp ne i32 %256, 0
  %658 = and i1 %657, %656
  %659 = icmp sgt i32 %258, 0
  %660 = select i1 %658, i1 %659, i1 false
  br i1 %660, label %668, label %661

661:                                              ; preds = %653
  %662 = icmp sgt i32 %258, 1
  br i1 %662, label %663, label %667

663:                                              ; preds = %661
  %664 = icmp eq i32 %258, 3
  %665 = or i1 %657, %664
  %666 = select i1 %665, i1 %655, i1 false
  br i1 %666, label %668, label %667

667:                                              ; preds = %663, %661
  br label %668

668:                                              ; preds = %667, %663, %653, %100, %96, %74, %4
  %669 = phi i32 [ 0, %667 ], [ 0, %4 ], [ 0, %100 ], [ %258, %653 ], [ -1, %663 ], [ 0, %74 ], [ 0, %96 ]
  ret i32 %669
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable
define hidden fastcc i64 @memIntValue(ptr nocapture noundef readonly %0) unnamed_addr #14 {
  %2 = alloca i64, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #16
  store i64 0, ptr %2, align 8, !tbaa !67
  %3 = getelementptr inbounds i8, ptr %0, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !85
  %5 = getelementptr inbounds i8, ptr %0, i64 16
  %6 = load i32, ptr %5, align 8, !tbaa !338
  %7 = getelementptr inbounds i8, ptr %0, i64 22
  %8 = load i8, ptr %7, align 2, !tbaa !142
  %9 = call fastcc i32 @sqlite3Atoi64(ptr noundef %4, ptr noundef nonnull %2, i32 noundef %6, i8 noundef zeroext %8)
  %10 = load i64, ptr %2, align 8, !tbaa !67
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #16
  ret i64 %10
}

; Function Attrs: nofree norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable
define hidden fastcc range(i32 -1, 4) i32 @sqlite3Atoi64(ptr noundef readonly %0, ptr nocapture noundef writeonly %1, i32 noundef %2, i8 noundef zeroext %3) unnamed_addr #15 {
  %5 = zext i8 %3 to i32
  %6 = icmp eq i8 %3, 1
  br i1 %6, label %37, label %7

7:                                                ; preds = %4
  %8 = and i32 %2, -2
  %9 = sub nsw i32 3, %5
  %10 = icmp slt i32 %9, %8
  br i1 %10, label %11, label %30

11:                                               ; preds = %7
  %12 = sub nsw i32 3, %5
  %13 = sext i32 %12 to i64
  %14 = sext i32 %8 to i64
  %15 = getelementptr inbounds i8, ptr %0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !30
  %17 = icmp eq i8 %16, 0
  br i1 %17, label %22, label %30

18:                                               ; preds = %22
  %19 = getelementptr inbounds i8, ptr %0, i64 %25
  %20 = load i8, ptr %19, align 1, !tbaa !30
  %21 = icmp eq i8 %20, 0
  br i1 %21, label %22, label %28, !llvm.loop !361

22:                                               ; preds = %18, %11
  %23 = phi i32 [ %26, %18 ], [ %9, %11 ]
  %24 = phi i64 [ %25, %18 ], [ %13, %11 ]
  %25 = add nsw i64 %24, 2
  %26 = add nsw i32 %23, 2
  %27 = icmp slt i64 %25, %14
  br i1 %27, label %18, label %30, !llvm.loop !361

28:                                               ; preds = %18
  %29 = trunc nsw i64 %25 to i32
  br label %30

30:                                               ; preds = %28, %22, %11, %7
  %31 = phi i32 [ %9, %7 ], [ %29, %28 ], [ %12, %11 ], [ %26, %22 ]
  %32 = phi i1 [ %10, %7 ], [ %27, %28 ], [ %10, %11 ], [ %27, %22 ]
  %33 = xor i32 %31, 1
  %34 = and i32 %5, 1
  %35 = zext nneg i32 %34 to i64
  %36 = getelementptr inbounds i8, ptr %0, i64 %35
  br label %37

37:                                               ; preds = %30, %4
  %38 = phi ptr [ %36, %30 ], [ %0, %4 ]
  %39 = phi i32 [ 2, %30 ], [ 1, %4 ]
  %40 = phi i1 [ %32, %30 ], [ false, %4 ]
  %41 = phi i32 [ %33, %30 ], [ %2, %4 ]
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds i8, ptr %0, i64 %42
  %44 = icmp ult ptr %38, %43
  br i1 %44, label %45, label %65

45:                                               ; preds = %37
  %46 = zext nneg i32 %39 to i64
  br label %47

47:                                               ; preds = %55, %45
  %48 = phi ptr [ %38, %45 ], [ %56, %55 ]
  %49 = load i8, ptr %48, align 1, !tbaa !30
  %50 = zext i8 %49 to i64
  %51 = getelementptr inbounds [256 x i8], ptr @sqlite3CtypeMap, i64 0, i64 %50
  %52 = load i8, ptr %51, align 1, !tbaa !30
  %53 = and i8 %52, 1
  %54 = icmp eq i8 %53, 0
  br i1 %54, label %58, label %55

55:                                               ; preds = %47
  %56 = getelementptr inbounds i8, ptr %48, i64 %46
  %57 = icmp ult ptr %56, %43
  br i1 %57, label %47, label %65, !llvm.loop !362

58:                                               ; preds = %47
  switch i8 %49, label %65 [
    i8 45, label %59
    i8 43, label %62
  ]

59:                                               ; preds = %58
  %60 = zext nneg i32 %39 to i64
  %61 = getelementptr inbounds i8, ptr %48, i64 %60
  br label %65

62:                                               ; preds = %58
  %63 = zext nneg i32 %39 to i64
  %64 = getelementptr inbounds i8, ptr %48, i64 %63
  br label %65

65:                                               ; preds = %62, %59, %58, %55, %37
  %66 = phi ptr [ %61, %59 ], [ %64, %62 ], [ %48, %58 ], [ %38, %37 ], [ %56, %55 ]
  %67 = phi i1 [ false, %59 ], [ true, %62 ], [ true, %58 ], [ true, %37 ], [ true, %55 ]
  %68 = icmp ult ptr %66, %43
  br i1 %68, label %69, label %78

69:                                               ; preds = %65
  %70 = zext nneg i32 %39 to i64
  br label %71

71:                                               ; preds = %75, %69
  %72 = phi ptr [ %66, %69 ], [ %76, %75 ]
  %73 = load i8, ptr %72, align 1, !tbaa !30
  %74 = icmp eq i8 %73, 48
  br i1 %74, label %75, label %78

75:                                               ; preds = %71
  %76 = getelementptr inbounds i8, ptr %72, i64 %70
  %77 = icmp ult ptr %76, %43
  br i1 %77, label %71, label %78, !llvm.loop !363

78:                                               ; preds = %75, %71, %65
  %79 = phi ptr [ %66, %65 ], [ %72, %71 ], [ %76, %75 ]
  %80 = icmp uge ptr %79, %43
  br i1 %80, label %106, label %81

81:                                               ; preds = %78
  %82 = zext nneg i32 %39 to i64
  %83 = load i8, ptr %79, align 1, !tbaa !30
  %84 = add i8 %83, -48
  %85 = icmp ult i8 %84, 10
  br i1 %85, label %91, label %106

86:                                               ; preds = %91
  %87 = getelementptr inbounds i8, ptr %79, i64 %100
  %88 = load i8, ptr %87, align 1, !tbaa !30
  %89 = add i8 %88, -48
  %90 = icmp ult i8 %89, 10
  br i1 %90, label %91, label %104, !llvm.loop !364

91:                                               ; preds = %86, %81
  %92 = phi i8 [ %88, %86 ], [ %83, %81 ]
  %93 = phi i64 [ %99, %86 ], [ 0, %81 ]
  %94 = phi i32 [ %101, %86 ], [ 0, %81 ]
  %95 = phi i64 [ %100, %86 ], [ 0, %81 ]
  %96 = zext nneg i8 %92 to i64
  %97 = mul i64 %93, 10
  %98 = add i64 %97, -48
  %99 = add i64 %98, %96
  %100 = add nuw nsw i64 %95, %82
  %101 = add nuw nsw i32 %94, %39
  %102 = getelementptr inbounds i8, ptr %79, i64 %100
  %103 = icmp uge ptr %102, %43
  br i1 %103, label %106, label %86, !llvm.loop !364

104:                                              ; preds = %86
  %105 = trunc nuw nsw i64 %100 to i32
  br label %106

106:                                              ; preds = %104, %91, %81, %78
  %107 = phi i64 [ 0, %78 ], [ %99, %104 ], [ 0, %81 ], [ %99, %91 ]
  %108 = phi i32 [ 0, %78 ], [ %105, %104 ], [ 0, %81 ], [ %101, %91 ]
  %109 = phi i1 [ %80, %78 ], [ %103, %104 ], [ %80, %81 ], [ %103, %91 ]
  %110 = icmp slt i64 %107, 0
  %111 = select i1 %67, i64 9223372036854775807, i64 -9223372036854775808
  %112 = sub nsw i64 0, %107
  %113 = select i1 %67, i64 %107, i64 %112
  %114 = select i1 %110, i64 %111, i64 %113
  store i64 %114, ptr %1, align 8, !tbaa !67
  %115 = icmp eq i32 %108, 0
  %116 = icmp eq ptr %66, %79
  %117 = and i1 %115, %116
  br i1 %117, label %137, label %118

118:                                              ; preds = %106
  %119 = or i1 %40, %109
  %120 = zext i1 %40 to i32
  br i1 %119, label %137, label %121

121:                                              ; preds = %118
  %122 = zext i32 %108 to i64
  %123 = zext nneg i32 %39 to i64
  br label %124

124:                                              ; preds = %133, %121
  %125 = phi i64 [ %122, %121 ], [ %134, %133 ]
  %126 = getelementptr inbounds i8, ptr %79, i64 %125
  %127 = load i8, ptr %126, align 1, !tbaa !30
  %128 = zext i8 %127 to i64
  %129 = getelementptr inbounds [256 x i8], ptr @sqlite3CtypeMap, i64 0, i64 %128
  %130 = load i8, ptr %129, align 1, !tbaa !30
  %131 = and i8 %130, 1
  %132 = icmp eq i8 %131, 0
  br i1 %132, label %137, label %133

133:                                              ; preds = %124
  %134 = add nuw nsw i64 %125, %123
  %135 = getelementptr inbounds i8, ptr %79, i64 %134
  %136 = icmp ult ptr %135, %43
  br i1 %136, label %124, label %137, !llvm.loop !365

137:                                              ; preds = %133, %124, %118, %106
  %138 = phi i32 [ -1, %106 ], [ %120, %118 ], [ 0, %133 ], [ 1, %124 ]
  %139 = mul nuw nsw i32 %39, 19
  %140 = icmp ult i32 %108, %139
  br i1 %140, label %176, label %141

141:                                              ; preds = %137
  %142 = icmp ugt i32 %108, %139
  br i1 %142, label %168, label %143

143:                                              ; preds = %141
  %144 = zext nneg i32 %39 to i64
  br label %145

145:                                              ; preds = %145, %143
  %146 = phi i64 [ 0, %143 ], [ %152, %145 ]
  %147 = mul nuw nsw i64 %146, %144
  %148 = getelementptr inbounds i8, ptr %79, i64 %147
  %149 = load i8, ptr %148, align 1, !tbaa !30
  %150 = getelementptr inbounds i8, ptr @.str.145, i64 %146
  %151 = load i8, ptr %150, align 1, !tbaa !30
  %152 = add nuw nsw i64 %146, 1
  %153 = icmp eq i8 %149, %151
  %154 = icmp ult i64 %146, 17
  %155 = and i1 %154, %153
  br i1 %155, label %145, label %156, !llvm.loop !366

156:                                              ; preds = %145
  %157 = sext i8 %151 to i32
  %158 = sext i8 %149 to i32
  %159 = sub nsw i32 %158, %157
  %160 = mul nsw i32 %159, 10
  br i1 %153, label %161, label %168

161:                                              ; preds = %156
  %162 = mul nuw nsw i32 %39, 18
  %163 = zext nneg i32 %162 to i64
  %164 = getelementptr inbounds i8, ptr %79, i64 %163
  %165 = load i8, ptr %164, align 1, !tbaa !30
  %166 = sext i8 %165 to i32
  %167 = add nsw i32 %166, -56
  br label %168

168:                                              ; preds = %161, %156, %141
  %169 = phi i32 [ 1, %141 ], [ %167, %161 ], [ %160, %156 ]
  %170 = icmp slt i32 %169, 0
  br i1 %170, label %176, label %171

171:                                              ; preds = %168
  %172 = select i1 %67, i64 9223372036854775807, i64 -9223372036854775808
  store i64 %172, ptr %1, align 8, !tbaa !67
  %173 = icmp eq i32 %169, 0
  %174 = select i1 %67, i32 3, i32 %138
  %175 = select i1 %173, i32 %174, i32 2
  br label %176

176:                                              ; preds = %171, %168, %137
  %177 = phi i32 [ %138, %137 ], [ %138, %168 ], [ %175, %171 ]
  ret i32 %177
}

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc range(i32 0, 8) i32 @sqlite3VdbeMemTranslate(ptr noundef %0, i8 noundef zeroext %1) unnamed_addr #4 {
  %3 = getelementptr inbounds i8, ptr %0, i64 22
  %4 = load i8, ptr %3, align 2, !tbaa !142
  %5 = icmp ne i8 %4, 1
  %6 = icmp ne i8 %1, 1
  %7 = and i1 %6, %5
  br i1 %7, label %8, label %75

8:                                                ; preds = %2
  %9 = getelementptr inbounds i8, ptr %0, i64 20
  %10 = load i16, ptr %9, align 4, !tbaa !83
  %11 = zext i16 %10 to i32
  %12 = and i32 %11, 18
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %56, label %14

14:                                               ; preds = %8
  %15 = and i32 %11, 1024
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %43, label %17

17:                                               ; preds = %14
  %18 = getelementptr inbounds i8, ptr %0, i64 16
  %19 = load i32, ptr %18, align 8, !tbaa !338
  %20 = load i32, ptr %0, align 8, !tbaa !30
  %21 = add nsw i32 %20, %19
  %22 = icmp slt i32 %21, 1
  br i1 %22, label %23, label %26

23:                                               ; preds = %17
  %24 = and i16 %10, 16
  %25 = icmp eq i16 %24, 0
  br i1 %25, label %43, label %26

26:                                               ; preds = %23, %17
  %27 = phi i32 [ %21, %17 ], [ 1, %23 ]
  %28 = tail call fastcc i32 @sqlite3VdbeMemGrow(ptr noundef nonnull %0, i32 noundef %27, i32 noundef 1)
  %29 = icmp eq i32 %28, 0
  br i1 %29, label %30, label %490

30:                                               ; preds = %26
  %31 = getelementptr inbounds i8, ptr %0, i64 8
  %32 = load ptr, ptr %31, align 8, !tbaa !85
  %33 = load i32, ptr %18, align 8, !tbaa !338
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds i8, ptr %32, i64 %34
  %36 = load i32, ptr %0, align 8, !tbaa !30
  %37 = sext i32 %36 to i64
  tail call void @llvm.memset.p0.i64(ptr noundef align 1 %35, i8 noundef 0, i64 noundef %37, i1 noundef false) #16
  %38 = load i32, ptr %0, align 8, !tbaa !30
  %39 = load i32, ptr %18, align 8, !tbaa !338
  %40 = add nsw i32 %39, %38
  store i32 %40, ptr %18, align 8, !tbaa !338
  %41 = load i16, ptr %9, align 4, !tbaa !83
  %42 = and i16 %41, -1537
  store i16 %42, ptr %9, align 4, !tbaa !83
  br label %43

43:                                               ; preds = %30, %23, %14
  %44 = getelementptr inbounds i8, ptr %0, i64 32
  %45 = load i32, ptr %44, align 8, !tbaa !326
  %46 = icmp eq i32 %45, 0
  br i1 %46, label %53, label %47

47:                                               ; preds = %43
  %48 = getelementptr inbounds i8, ptr %0, i64 8
  %49 = load ptr, ptr %48, align 8, !tbaa !85
  %50 = getelementptr inbounds i8, ptr %0, i64 40
  %51 = load ptr, ptr %50, align 8, !tbaa !328
  %52 = icmp eq ptr %49, %51
  br i1 %52, label %56, label %53

53:                                               ; preds = %47, %43
  %54 = tail call fastcc i32 @vdbeMemAddTerminator(ptr noundef %0)
  %55 = icmp eq i32 %54, 0
  br i1 %55, label %56, label %490

56:                                               ; preds = %53, %47, %8
  %57 = load i16, ptr %9, align 4, !tbaa !83
  %58 = and i16 %57, -16385
  store i16 %58, ptr %9, align 4, !tbaa !83
  %59 = getelementptr inbounds i8, ptr %0, i64 8
  %60 = load ptr, ptr %59, align 8, !tbaa !85
  %61 = getelementptr inbounds i8, ptr %0, i64 16
  %62 = load i32, ptr %61, align 8, !tbaa !338
  %63 = and i32 %62, -2
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds i8, ptr %60, i64 %64
  %66 = icmp sgt i32 %63, 0
  br i1 %66, label %67, label %74

67:                                               ; preds = %67, %56
  %68 = phi ptr [ %72, %67 ], [ %60, %56 ]
  %69 = load i8, ptr %68, align 1, !tbaa !30
  %70 = getelementptr inbounds i8, ptr %68, i64 1
  %71 = load i8, ptr %70, align 1, !tbaa !30
  store i8 %71, ptr %68, align 1, !tbaa !30
  %72 = getelementptr inbounds i8, ptr %68, i64 2
  store i8 %69, ptr %70, align 1, !tbaa !30
  %73 = icmp ult ptr %72, %65
  br i1 %73, label %67, label %74, !llvm.loop !367

74:                                               ; preds = %67, %56
  store i8 %1, ptr %3, align 2, !tbaa !142
  br label %490

75:                                               ; preds = %2
  %76 = icmp eq i8 %1, 1
  %77 = getelementptr inbounds i8, ptr %0, i64 16
  %78 = load i32, ptr %77, align 8, !tbaa !338
  br i1 %76, label %79, label %84

79:                                               ; preds = %75
  %80 = and i32 %78, -2
  store i32 %80, ptr %77, align 8, !tbaa !338
  %81 = sext i32 %80 to i64
  %82 = shl nsw i64 %81, 1
  %83 = or disjoint i64 %82, 1
  br label %88

84:                                               ; preds = %75
  %85 = sext i32 %78 to i64
  %86 = shl nsw i64 %85, 1
  %87 = add nsw i64 %86, 2
  br label %88

88:                                               ; preds = %84, %79
  %89 = phi i64 [ %83, %79 ], [ %87, %84 ]
  %90 = getelementptr inbounds i8, ptr %0, i64 8
  %91 = load ptr, ptr %90, align 8, !tbaa !85
  %92 = getelementptr inbounds i8, ptr %0, i64 16
  %93 = load i32, ptr %92, align 8, !tbaa !338
  %94 = sext i32 %93 to i64
  %95 = getelementptr inbounds i8, ptr %91, i64 %94
  %96 = getelementptr inbounds i8, ptr %0, i64 24
  %97 = load ptr, ptr %96, align 8, !tbaa !327
  %98 = icmp eq ptr %97, null
  br i1 %98, label %101, label %99

99:                                               ; preds = %88
  %100 = tail call fastcc ptr @sqlite3DbMallocRawNN(ptr noundef nonnull %97, i64 noundef %89)
  br label %103

101:                                              ; preds = %88
  %102 = tail call fastcc ptr @sqlite3Malloc(i64 noundef %89)
  br label %103

103:                                              ; preds = %101, %99
  %104 = phi ptr [ %100, %99 ], [ %102, %101 ]
  %105 = icmp eq ptr %104, null
  br i1 %105, label %490, label %106

106:                                              ; preds = %103
  %107 = load i8, ptr %3, align 2, !tbaa !142
  switch i8 %107, label %110 [
    i8 1, label %112
    i8 2, label %108
  ]

108:                                              ; preds = %106
  %109 = icmp sgt i32 %93, 0
  br i1 %109, label %267, label %445

110:                                              ; preds = %106
  %111 = icmp sgt i32 %93, 0
  br i1 %111, label %356, label %445

112:                                              ; preds = %106
  %113 = icmp eq i8 %1, 2
  %114 = icmp sgt i32 %93, 0
  br i1 %113, label %116, label %115

115:                                              ; preds = %112
  br i1 %114, label %189, label %260

116:                                              ; preds = %112
  br i1 %114, label %117, label %260

117:                                              ; preds = %186, %116
  %118 = phi ptr [ %157, %186 ], [ %91, %116 ]
  %119 = phi ptr [ %187, %186 ], [ %104, %116 ]
  %120 = getelementptr inbounds i8, ptr %118, i64 1
  %121 = load i8, ptr %118, align 1, !tbaa !30
  %122 = zext i8 %121 to i32
  %123 = icmp ugt i8 %121, -65
  br i1 %123, label %124, label %155

124:                                              ; preds = %117
  %125 = add nsw i32 %122, -192
  %126 = zext nneg i32 %125 to i64
  %127 = getelementptr inbounds [64 x i8], ptr @sqlite3Utf8Trans1, i64 0, i64 %126
  %128 = load i8, ptr %127, align 1, !tbaa !30
  %129 = zext i8 %128 to i32
  %130 = icmp eq ptr %120, %95
  br i1 %130, label %144, label %131

131:                                              ; preds = %138, %124
  %132 = phi ptr [ %140, %138 ], [ %120, %124 ]
  %133 = phi i32 [ %142, %138 ], [ %129, %124 ]
  %134 = load i8, ptr %132, align 1, !tbaa !30
  %135 = zext i8 %134 to i32
  %136 = and i32 %135, 192
  %137 = icmp eq i32 %136, 128
  br i1 %137, label %138, label %144

138:                                              ; preds = %131
  %139 = shl i32 %133, 6
  %140 = getelementptr inbounds i8, ptr %132, i64 1
  %141 = and i32 %135, 63
  %142 = or disjoint i32 %141, %139
  %143 = icmp eq ptr %140, %95
  br i1 %143, label %144, label %131, !llvm.loop !368

144:                                              ; preds = %138, %131, %124
  %145 = phi i32 [ %129, %124 ], [ %133, %131 ], [ %142, %138 ]
  %146 = phi ptr [ %120, %124 ], [ %132, %131 ], [ %140, %138 ]
  %147 = icmp ult i32 %145, 128
  %148 = and i32 %145, -2048
  %149 = icmp eq i32 %148, 55296
  %150 = or i1 %147, %149
  %151 = and i32 %145, -2
  %152 = icmp eq i32 %151, 65534
  %153 = or i1 %152, %150
  %154 = select i1 %153, i32 65533, i32 %145
  br label %155

155:                                              ; preds = %144, %117
  %156 = phi i32 [ %122, %117 ], [ %154, %144 ]
  %157 = phi ptr [ %120, %117 ], [ %146, %144 ]
  %158 = icmp ult i32 %156, 65536
  br i1 %158, label %159, label %165

159:                                              ; preds = %155
  %160 = trunc i32 %156 to i8
  %161 = getelementptr inbounds i8, ptr %119, i64 1
  store i8 %160, ptr %119, align 1, !tbaa !30
  %162 = lshr i32 %156, 8
  %163 = trunc nuw i32 %162 to i8
  %164 = getelementptr inbounds i8, ptr %119, i64 2
  store i8 %163, ptr %161, align 1, !tbaa !30
  br label %186

165:                                              ; preds = %155
  %166 = lshr i32 %156, 10
  %167 = and i32 %166, 63
  %168 = add i32 %156, -65536
  %169 = lshr i32 %168, 10
  %170 = and i32 %169, 192
  %171 = or disjoint i32 %170, %167
  %172 = trunc nuw i32 %171 to i8
  %173 = getelementptr inbounds i8, ptr %119, i64 1
  store i8 %172, ptr %119, align 1, !tbaa !30
  %174 = lshr i32 %168, 18
  %175 = trunc i32 %174 to i8
  %176 = and i8 %175, 3
  %177 = or disjoint i8 %176, -40
  %178 = getelementptr inbounds i8, ptr %119, i64 2
  store i8 %177, ptr %173, align 1, !tbaa !30
  %179 = trunc i32 %156 to i8
  %180 = getelementptr inbounds i8, ptr %119, i64 3
  store i8 %179, ptr %178, align 1, !tbaa !30
  %181 = lshr i32 %156, 8
  %182 = trunc i32 %181 to i8
  %183 = and i8 %182, 3
  %184 = or disjoint i8 %183, -36
  %185 = getelementptr inbounds i8, ptr %119, i64 4
  store i8 %184, ptr %180, align 1, !tbaa !30
  br label %186

186:                                              ; preds = %165, %159
  %187 = phi ptr [ %164, %159 ], [ %185, %165 ]
  %188 = icmp ult ptr %157, %95
  br i1 %188, label %117, label %260, !llvm.loop !369

189:                                              ; preds = %254, %115
  %190 = phi ptr [ %229, %254 ], [ %91, %115 ]
  %191 = phi ptr [ %258, %254 ], [ %104, %115 ]
  %192 = getelementptr inbounds i8, ptr %190, i64 1
  %193 = load i8, ptr %190, align 1, !tbaa !30
  %194 = zext i8 %193 to i32
  %195 = icmp ugt i8 %193, -65
  br i1 %195, label %196, label %227

196:                                              ; preds = %189
  %197 = add nsw i32 %194, -192
  %198 = zext nneg i32 %197 to i64
  %199 = getelementptr inbounds [64 x i8], ptr @sqlite3Utf8Trans1, i64 0, i64 %198
  %200 = load i8, ptr %199, align 1, !tbaa !30
  %201 = zext i8 %200 to i32
  %202 = icmp eq ptr %192, %95
  br i1 %202, label %216, label %203

203:                                              ; preds = %210, %196
  %204 = phi ptr [ %212, %210 ], [ %192, %196 ]
  %205 = phi i32 [ %214, %210 ], [ %201, %196 ]
  %206 = load i8, ptr %204, align 1, !tbaa !30
  %207 = zext i8 %206 to i32
  %208 = and i32 %207, 192
  %209 = icmp eq i32 %208, 128
  br i1 %209, label %210, label %216

210:                                              ; preds = %203
  %211 = shl i32 %205, 6
  %212 = getelementptr inbounds i8, ptr %204, i64 1
  %213 = and i32 %207, 63
  %214 = or disjoint i32 %213, %211
  %215 = icmp eq ptr %212, %95
  br i1 %215, label %216, label %203, !llvm.loop !370

216:                                              ; preds = %210, %203, %196
  %217 = phi i32 [ %201, %196 ], [ %205, %203 ], [ %214, %210 ]
  %218 = phi ptr [ %192, %196 ], [ %204, %203 ], [ %212, %210 ]
  %219 = icmp ult i32 %217, 128
  %220 = and i32 %217, -2048
  %221 = icmp eq i32 %220, 55296
  %222 = or i1 %219, %221
  %223 = and i32 %217, -2
  %224 = icmp eq i32 %223, 65534
  %225 = or i1 %224, %222
  %226 = select i1 %225, i32 65533, i32 %217
  br label %227

227:                                              ; preds = %216, %189
  %228 = phi i32 [ %194, %189 ], [ %226, %216 ]
  %229 = phi ptr [ %192, %189 ], [ %218, %216 ]
  %230 = icmp ult i32 %228, 65536
  br i1 %230, label %231, label %235

231:                                              ; preds = %227
  %232 = lshr i32 %228, 8
  %233 = trunc nuw i32 %232 to i8
  %234 = getelementptr inbounds i8, ptr %191, i64 1
  store i8 %233, ptr %191, align 1, !tbaa !30
  br label %254

235:                                              ; preds = %227
  %236 = add i32 %228, -65536
  %237 = lshr i32 %236, 18
  %238 = trunc i32 %237 to i8
  %239 = and i8 %238, 3
  %240 = or disjoint i8 %239, -40
  %241 = getelementptr inbounds i8, ptr %191, i64 1
  store i8 %240, ptr %191, align 1, !tbaa !30
  %242 = lshr i32 %228, 10
  %243 = and i32 %242, 63
  %244 = lshr i32 %236, 10
  %245 = and i32 %244, 192
  %246 = or disjoint i32 %245, %243
  %247 = trunc nuw i32 %246 to i8
  %248 = getelementptr inbounds i8, ptr %191, i64 2
  store i8 %247, ptr %241, align 1, !tbaa !30
  %249 = lshr i32 %228, 8
  %250 = trunc i32 %249 to i8
  %251 = and i8 %250, 3
  %252 = or disjoint i8 %251, -36
  %253 = getelementptr inbounds i8, ptr %191, i64 3
  store i8 %252, ptr %248, align 1, !tbaa !30
  br label %254

254:                                              ; preds = %235, %231
  %255 = phi i64 [ 4, %235 ], [ 2, %231 ]
  %256 = phi ptr [ %253, %235 ], [ %234, %231 ]
  %257 = trunc i32 %228 to i8
  %258 = getelementptr inbounds i8, ptr %191, i64 %255
  store i8 %257, ptr %256, align 1, !tbaa !30
  %259 = icmp ult ptr %229, %95
  br i1 %259, label %189, label %260, !llvm.loop !371

260:                                              ; preds = %254, %186, %116, %115
  %261 = phi ptr [ %104, %116 ], [ %104, %115 ], [ %187, %186 ], [ %258, %254 ]
  %262 = ptrtoint ptr %261 to i64
  %263 = ptrtoint ptr %104 to i64
  %264 = sub i64 %262, %263
  %265 = trunc i64 %264 to i32
  store i32 %265, ptr %92, align 8, !tbaa !338
  %266 = getelementptr inbounds i8, ptr %261, i64 1
  store i8 0, ptr %261, align 1, !tbaa !30
  br label %451

267:                                              ; preds = %353, %108
  %268 = phi ptr [ %301, %353 ], [ %91, %108 ]
  %269 = phi ptr [ %354, %353 ], [ %104, %108 ]
  %270 = getelementptr inbounds i8, ptr %268, i64 1
  %271 = load i8, ptr %268, align 1, !tbaa !30
  %272 = zext i8 %271 to i32
  %273 = getelementptr inbounds i8, ptr %268, i64 2
  %274 = load i8, ptr %270, align 1, !tbaa !30
  %275 = zext i8 %274 to i32
  %276 = shl nuw nsw i32 %275, 8
  %277 = or disjoint i32 %276, %272
  %278 = and i8 %274, -8
  %279 = icmp eq i8 %278, -40
  %280 = icmp ult ptr %273, %95
  %281 = select i1 %279, i1 %280, i1 false
  br i1 %281, label %282, label %299

282:                                              ; preds = %267
  %283 = getelementptr inbounds i8, ptr %268, i64 3
  %284 = load i8, ptr %273, align 1, !tbaa !30
  %285 = zext i8 %284 to i32
  %286 = getelementptr inbounds i8, ptr %268, i64 4
  %287 = load i8, ptr %283, align 1, !tbaa !30
  %288 = zext i8 %287 to i32
  %289 = shl nuw nsw i32 %288, 8
  %290 = and i32 %289, 768
  %291 = shl nuw nsw i32 %272, 10
  %292 = and i32 %291, 64512
  %293 = shl nuw nsw i32 %277, 10
  %294 = and i32 %293, 983040
  %295 = or disjoint i32 %292, 65536
  %296 = add nuw nsw i32 %295, %294
  %297 = or disjoint i32 %296, %285
  %298 = or disjoint i32 %297, %290
  br label %299

299:                                              ; preds = %282, %267
  %300 = phi i32 [ %298, %282 ], [ %277, %267 ]
  %301 = phi ptr [ %286, %282 ], [ %273, %267 ]
  %302 = icmp ult i32 %300, 128
  br i1 %302, label %303, label %306

303:                                              ; preds = %299
  %304 = trunc nuw nsw i32 %300 to i8
  %305 = getelementptr inbounds i8, ptr %269, i64 1
  store i8 %304, ptr %269, align 1, !tbaa !30
  br label %353

306:                                              ; preds = %299
  %307 = icmp ult i32 %300, 2048
  br i1 %307, label %308, label %317

308:                                              ; preds = %306
  %309 = lshr i32 %300, 6
  %310 = trunc nuw i32 %309 to i8
  %311 = or disjoint i8 %310, -64
  %312 = getelementptr inbounds i8, ptr %269, i64 1
  store i8 %311, ptr %269, align 1, !tbaa !30
  %313 = trunc i32 %300 to i8
  %314 = and i8 %313, 63
  %315 = or disjoint i8 %314, -128
  %316 = getelementptr inbounds i8, ptr %269, i64 2
  store i8 %315, ptr %312, align 1, !tbaa !30
  br label %353

317:                                              ; preds = %306
  %318 = icmp ult i32 %300, 65536
  br i1 %318, label %319, label %333

319:                                              ; preds = %317
  %320 = lshr i32 %300, 12
  %321 = trunc nuw i32 %320 to i8
  %322 = or disjoint i8 %321, -32
  %323 = getelementptr inbounds i8, ptr %269, i64 1
  store i8 %322, ptr %269, align 1, !tbaa !30
  %324 = lshr i32 %300, 6
  %325 = trunc i32 %324 to i8
  %326 = and i8 %325, 63
  %327 = or disjoint i8 %326, -128
  %328 = getelementptr inbounds i8, ptr %269, i64 2
  store i8 %327, ptr %323, align 1, !tbaa !30
  %329 = trunc i32 %300 to i8
  %330 = and i8 %329, 63
  %331 = or disjoint i8 %330, -128
  %332 = getelementptr inbounds i8, ptr %269, i64 3
  store i8 %331, ptr %328, align 1, !tbaa !30
  br label %353

333:                                              ; preds = %317
  %334 = lshr i32 %300, 18
  %335 = trunc nuw nsw i32 %334 to i8
  %336 = and i8 %335, 7
  %337 = or disjoint i8 %336, -16
  %338 = getelementptr inbounds i8, ptr %269, i64 1
  store i8 %337, ptr %269, align 1, !tbaa !30
  %339 = lshr i32 %300, 12
  %340 = trunc i32 %339 to i8
  %341 = and i8 %340, 63
  %342 = or disjoint i8 %341, -128
  %343 = getelementptr inbounds i8, ptr %269, i64 2
  store i8 %342, ptr %338, align 1, !tbaa !30
  %344 = lshr i32 %300, 6
  %345 = trunc i32 %344 to i8
  %346 = and i8 %345, 63
  %347 = or disjoint i8 %346, -128
  %348 = getelementptr inbounds i8, ptr %269, i64 3
  store i8 %347, ptr %343, align 1, !tbaa !30
  %349 = trunc i32 %300 to i8
  %350 = and i8 %349, 63
  %351 = or disjoint i8 %350, -128
  %352 = getelementptr inbounds i8, ptr %269, i64 4
  store i8 %351, ptr %348, align 1, !tbaa !30
  br label %353

353:                                              ; preds = %333, %319, %308, %303
  %354 = phi ptr [ %305, %303 ], [ %316, %308 ], [ %332, %319 ], [ %352, %333 ]
  %355 = icmp ult ptr %301, %95
  br i1 %355, label %267, label %445, !llvm.loop !372

356:                                              ; preds = %442, %110
  %357 = phi ptr [ %390, %442 ], [ %91, %110 ]
  %358 = phi ptr [ %443, %442 ], [ %104, %110 ]
  %359 = getelementptr inbounds i8, ptr %357, i64 1
  %360 = load i8, ptr %357, align 1, !tbaa !30
  %361 = zext i8 %360 to i32
  %362 = shl nuw nsw i32 %361, 8
  %363 = getelementptr inbounds i8, ptr %357, i64 2
  %364 = load i8, ptr %359, align 1, !tbaa !30
  %365 = zext i8 %364 to i32
  %366 = or disjoint i32 %362, %365
  %367 = and i8 %360, -8
  %368 = icmp eq i8 %367, -40
  %369 = icmp ult ptr %363, %95
  %370 = select i1 %368, i1 %369, i1 false
  br i1 %370, label %371, label %388

371:                                              ; preds = %356
  %372 = getelementptr inbounds i8, ptr %357, i64 3
  %373 = load i8, ptr %363, align 1, !tbaa !30
  %374 = zext i8 %373 to i32
  %375 = shl nuw nsw i32 %374, 8
  %376 = getelementptr inbounds i8, ptr %357, i64 4
  %377 = load i8, ptr %372, align 1, !tbaa !30
  %378 = zext i8 %377 to i32
  %379 = and i32 %375, 768
  %380 = shl nuw nsw i32 %365, 10
  %381 = and i32 %380, 64512
  %382 = shl nuw nsw i32 %366, 10
  %383 = and i32 %382, 983040
  %384 = or disjoint i32 %381, 65536
  %385 = add nuw nsw i32 %384, %383
  %386 = or disjoint i32 %385, %378
  %387 = or disjoint i32 %386, %379
  br label %388

388:                                              ; preds = %371, %356
  %389 = phi i32 [ %387, %371 ], [ %366, %356 ]
  %390 = phi ptr [ %376, %371 ], [ %363, %356 ]
  %391 = icmp ult i32 %389, 128
  br i1 %391, label %392, label %395

392:                                              ; preds = %388
  %393 = trunc nuw nsw i32 %389 to i8
  %394 = getelementptr inbounds i8, ptr %358, i64 1
  store i8 %393, ptr %358, align 1, !tbaa !30
  br label %442

395:                                              ; preds = %388
  %396 = icmp ult i32 %389, 2048
  br i1 %396, label %397, label %406

397:                                              ; preds = %395
  %398 = lshr i32 %389, 6
  %399 = trunc nuw i32 %398 to i8
  %400 = or disjoint i8 %399, -64
  %401 = getelementptr inbounds i8, ptr %358, i64 1
  store i8 %400, ptr %358, align 1, !tbaa !30
  %402 = trunc i32 %389 to i8
  %403 = and i8 %402, 63
  %404 = or disjoint i8 %403, -128
  %405 = getelementptr inbounds i8, ptr %358, i64 2
  store i8 %404, ptr %401, align 1, !tbaa !30
  br label %442

406:                                              ; preds = %395
  %407 = icmp ult i32 %389, 65536
  br i1 %407, label %408, label %422

408:                                              ; preds = %406
  %409 = lshr i32 %389, 12
  %410 = trunc nuw i32 %409 to i8
  %411 = or disjoint i8 %410, -32
  %412 = getelementptr inbounds i8, ptr %358, i64 1
  store i8 %411, ptr %358, align 1, !tbaa !30
  %413 = lshr i32 %389, 6
  %414 = trunc i32 %413 to i8
  %415 = and i8 %414, 63
  %416 = or disjoint i8 %415, -128
  %417 = getelementptr inbounds i8, ptr %358, i64 2
  store i8 %416, ptr %412, align 1, !tbaa !30
  %418 = trunc i32 %389 to i8
  %419 = and i8 %418, 63
  %420 = or disjoint i8 %419, -128
  %421 = getelementptr inbounds i8, ptr %358, i64 3
  store i8 %420, ptr %417, align 1, !tbaa !30
  br label %442

422:                                              ; preds = %406
  %423 = lshr i32 %389, 18
  %424 = trunc nuw nsw i32 %423 to i8
  %425 = and i8 %424, 7
  %426 = or disjoint i8 %425, -16
  %427 = getelementptr inbounds i8, ptr %358, i64 1
  store i8 %426, ptr %358, align 1, !tbaa !30
  %428 = lshr i32 %389, 12
  %429 = trunc i32 %428 to i8
  %430 = and i8 %429, 63
  %431 = or disjoint i8 %430, -128
  %432 = getelementptr inbounds i8, ptr %358, i64 2
  store i8 %431, ptr %427, align 1, !tbaa !30
  %433 = lshr i32 %389, 6
  %434 = trunc i32 %433 to i8
  %435 = and i8 %434, 63
  %436 = or disjoint i8 %435, -128
  %437 = getelementptr inbounds i8, ptr %358, i64 3
  store i8 %436, ptr %432, align 1, !tbaa !30
  %438 = trunc i32 %389 to i8
  %439 = and i8 %438, 63
  %440 = or disjoint i8 %439, -128
  %441 = getelementptr inbounds i8, ptr %358, i64 4
  store i8 %440, ptr %437, align 1, !tbaa !30
  br label %442

442:                                              ; preds = %422, %408, %397, %392
  %443 = phi ptr [ %394, %392 ], [ %405, %397 ], [ %421, %408 ], [ %441, %422 ]
  %444 = icmp ult ptr %390, %95
  br i1 %444, label %356, label %445, !llvm.loop !373

445:                                              ; preds = %442, %353, %110, %108
  %446 = phi ptr [ %104, %110 ], [ %104, %108 ], [ %443, %442 ], [ %354, %353 ]
  %447 = ptrtoint ptr %446 to i64
  %448 = ptrtoint ptr %104 to i64
  %449 = sub i64 %447, %448
  %450 = trunc i64 %449 to i32
  store i32 %450, ptr %92, align 8, !tbaa !338
  br label %451

451:                                              ; preds = %445, %260
  %452 = phi ptr [ %266, %260 ], [ %446, %445 ]
  store i8 0, ptr %452, align 1, !tbaa !30
  %453 = getelementptr inbounds i8, ptr %0, i64 20
  %454 = load i16, ptr %453, align 4, !tbaa !83
  %455 = and i16 %454, 2109
  %456 = or disjoint i16 %455, 514
  %457 = and i16 %454, -28672
  %458 = icmp eq i16 %457, 0
  br i1 %458, label %459, label %463

459:                                              ; preds = %451
  %460 = getelementptr inbounds i8, ptr %0, i64 32
  %461 = load i32, ptr %460, align 8, !tbaa !326
  %462 = icmp eq i32 %461, 0
  br i1 %462, label %464, label %463

463:                                              ; preds = %459, %451
  tail call fastcc void @vdbeMemClear(ptr noundef %0)
  br label %464

464:                                              ; preds = %463, %459
  store i16 %456, ptr %453, align 4, !tbaa !83
  store i8 %1, ptr %3, align 2, !tbaa !142
  store ptr %104, ptr %90, align 8, !tbaa !85
  %465 = getelementptr inbounds i8, ptr %0, i64 40
  store ptr %104, ptr %465, align 8, !tbaa !328
  %466 = load ptr, ptr %96, align 8, !tbaa !327
  %467 = icmp eq ptr %466, null
  br i1 %467, label %484, label %468

468:                                              ; preds = %464
  %469 = getelementptr inbounds i8, ptr %466, i64 496
  %470 = load ptr, ptr %469, align 8, !tbaa !144
  %471 = icmp ugt ptr %470, %104
  br i1 %471, label %472, label %484

472:                                              ; preds = %468
  %473 = getelementptr inbounds i8, ptr %466, i64 472
  %474 = load ptr, ptr %473, align 8, !tbaa !145
  %475 = icmp ugt ptr %474, %104
  br i1 %475, label %476, label %487

476:                                              ; preds = %472
  %477 = getelementptr inbounds i8, ptr %466, i64 480
  %478 = load ptr, ptr %477, align 8, !tbaa !146
  %479 = icmp ugt ptr %478, %104
  br i1 %479, label %484, label %480

480:                                              ; preds = %476
  %481 = getelementptr inbounds i8, ptr %466, i64 414
  %482 = load i16, ptr %481, align 2, !tbaa !147
  %483 = zext i16 %482 to i32
  br label %487

484:                                              ; preds = %476, %468, %464
  %485 = load ptr, ptr getelementptr inbounds (i8, ptr @sqlite3Config, i64 56), align 8, !tbaa !70
  %486 = tail call i32 %485(ptr noundef nonnull %104) #16
  br label %487

487:                                              ; preds = %484, %480, %472
  %488 = phi i32 [ %483, %480 ], [ %486, %484 ], [ 128, %472 ]
  %489 = getelementptr inbounds i8, ptr %0, i64 32
  store i32 %488, ptr %489, align 8, !tbaa !326
  br label %490

490:                                              ; preds = %487, %103, %74, %53, %26
  %491 = phi i32 [ 7, %103 ], [ 0, %74 ], [ 0, %487 ], [ 7, %26 ], [ 7, %53 ]
  ret i32 %491
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smax.i64(i64, i64) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.smin.i64(i64, i64) #8

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.abs.i64(i64, i1 immarg) #8

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn memory(argmem: read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind willreturn }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #9 = { nofree nounwind memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #10 = { nofree noinline nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #11 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #12 = { nofree noinline norecurse nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #13 = { nofree norecurse nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #14 = { nofree noinline norecurse nosync nounwind ssp memory(readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #15 = { nofree norecurse nosync nounwind ssp memory(read, argmem: readwrite, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #16 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 340}
!7 = !{!"Sqlite3Config", !8, i64 0, !9, i64 4, !9, i64 5, !9, i64 6, !9, i64 7, !9, i64 8, !9, i64 9, !9, i64 10, !8, i64 12, !8, i64 16, !8, i64 20, !8, i64 24, !8, i64 28, !11, i64 32, !13, i64 96, !14, i64 168, !12, i64 272, !8, i64 280, !8, i64 284, !8, i64 288, !15, i64 296, !15, i64 304, !12, i64 312, !8, i64 320, !8, i64 324, !8, i64 328, !8, i64 332, !8, i64 336, !8, i64 340, !8, i64 344, !8, i64 348, !8, i64 352, !8, i64 356, !8, i64 360, !12, i64 368, !12, i64 376, !12, i64 384, !15, i64 392, !12, i64 400, !8, i64 408, !12, i64 416, !8, i64 424, !8, i64 428, !8, i64 432}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!"sqlite3_mem_methods", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56}
!12 = !{!"any pointer", !9, i64 0}
!13 = !{!"sqlite3_mutex_methods", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64}
!14 = !{!"sqlite3_pcache_methods2", !8, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !12, i64 96}
!15 = !{!"long long", !9, i64 0}
!16 = !{!7, !8, i64 348}
!17 = !{!7, !8, i64 352}
!18 = !{!7, !12, i64 32}
!19 = !{!20, !12, i64 0}
!20 = !{!"Mem0Global", !12, i64 0, !15, i64 8, !15, i64 16, !8, i64 24}
!21 = !{!7, !12, i64 312}
!22 = !{!7, !8, i64 320}
!23 = !{!7, !12, i64 72}
!24 = !{!7, !12, i64 88}
!25 = !{!7, !12, i64 368}
!26 = !{!7, !8, i64 360}
!27 = !{!7, !8, i64 344}
!28 = !{!29, !12, i64 56}
!29 = !{!"FuncDef", !9, i64 0, !8, i64 4, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !9, i64 64}
!30 = !{!9, !9, i64 0}
!31 = distinct !{!31, !32}
!32 = !{!"llvm.loop.unroll.disable"}
!33 = distinct !{!33, !34, !32}
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!29, !12, i64 16}
!36 = !{!12, !12, i64 0}
!37 = distinct !{!37, !34, !32}
!38 = !{!7, !8, i64 356}
!39 = !{!7, !12, i64 184}
!40 = !{!7, !12, i64 176}
!41 = !{!42, !8, i64 4}
!42 = !{!"sqlite3_vfs", !8, i64 0, !8, i64 4, !8, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !12, i64 112, !12, i64 120, !12, i64 128, !12, i64 136, !12, i64 144, !12, i64 152, !12, i64 160}
!43 = !{!42, !12, i64 32}
!44 = !{!45, !8, i64 80}
!45 = !{!"PCacheGlobal", !46, i64 0, !8, i64 80, !8, i64 84, !8, i64 88, !8, i64 92, !8, i64 96, !8, i64 100, !12, i64 104, !12, i64 112, !12, i64 120, !12, i64 128, !8, i64 136, !8, i64 140}
!46 = !{!"PGroup", !12, i64 0, !8, i64 8, !8, i64 12, !8, i64 16, !8, i64 20, !47, i64 24}
!47 = !{!"PgHdr1", !48, i64 0, !8, i64 16, !49, i64 20, !49, i64 22, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48}
!48 = !{!"sqlite3_pcache_page", !12, i64 0, !12, i64 8}
!49 = !{!"short", !9, i64 0}
!50 = !{!7, !8, i64 324}
!51 = !{!45, !8, i64 92}
!52 = !{!45, !8, i64 136}
!53 = !{!45, !8, i64 96}
!54 = !{!45, !8, i64 100}
!55 = !{!45, !12, i64 104}
!56 = !{!45, !12, i64 128}
!57 = !{!45, !8, i64 140}
!58 = !{!59, !12, i64 0}
!59 = !{!"PgFreeslot", !12, i64 0}
!60 = distinct !{!60, !34, !32}
!61 = !{!45, !12, i64 112}
!62 = !{!7, !9, i64 10}
!63 = !{!42, !12, i64 16}
!64 = distinct !{!64, !34, !32}
!65 = !{!7, !8, i64 0}
!66 = !{!7, !12, i64 64}
!67 = !{!15, !15, i64 0}
!68 = !{!20, !15, i64 8}
!69 = !{!20, !15, i64 16}
!70 = !{!7, !12, i64 56}
!71 = !{!7, !12, i64 40}
!72 = !{!7, !12, i64 48}
!73 = !{!74, !9, i64 29}
!74 = !{!"sqlite3_str", !12, i64 0, !12, i64 8, !8, i64 16, !8, i64 20, !8, i64 24, !9, i64 28, !9, i64 29}
!75 = !{!74, !8, i64 24}
!76 = !{!74, !8, i64 16}
!77 = !{!74, !12, i64 8}
!78 = distinct !{!78, !34, !32}
!79 = !{!80, !8, i64 0}
!80 = !{!"PrintfArguments", !8, i64 0, !8, i64 4, !12, i64 8}
!81 = !{!80, !8, i64 4}
!82 = !{!80, !12, i64 8}
!83 = !{!84, !49, i64 20}
!84 = !{!"sqlite3_value", !9, i64 0, !12, i64 8, !8, i64 16, !49, i64 20, !9, i64 22, !9, i64 23, !12, i64 24, !8, i64 32, !8, i64 36, !12, i64 40, !12, i64 48}
!85 = !{!84, !12, i64 8}
!86 = !{!8, !8, i64 0}
!87 = distinct !{!87, !34, !32}
!88 = distinct !{!88, !34, !32}
!89 = distinct !{!89, !34, !32}
!90 = !{!91, !9, i64 0}
!91 = !{!"et_info", !9, i64 0, !9, i64 1, !9, i64 2, !9, i64 3, !9, i64 4, !9, i64 5}
!92 = !{!91, !9, i64 3}
!93 = !{!91, !9, i64 2}
!94 = !{!95, !95, i64 0}
!95 = !{!"long", !9, i64 0}
!96 = !{!74, !9, i64 28}
!97 = !{!74, !8, i64 20}
!98 = !{!74, !12, i64 0}
!99 = !{!100, !12, i64 344}
!100 = !{!"sqlite3", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !8, i64 40, !8, i64 44, !15, i64 48, !15, i64 56, !15, i64 64, !8, i64 72, !8, i64 76, !8, i64 80, !8, i64 84, !8, i64 88, !8, i64 92, !8, i64 96, !9, i64 100, !9, i64 101, !9, i64 102, !9, i64 103, !9, i64 104, !9, i64 105, !9, i64 106, !9, i64 107, !9, i64 108, !9, i64 109, !9, i64 110, !9, i64 111, !9, i64 112, !9, i64 113, !8, i64 116, !15, i64 120, !15, i64 128, !9, i64 136, !8, i64 184, !101, i64 192, !8, i64 208, !8, i64 212, !8, i64 216, !8, i64 220, !8, i64 224, !8, i64 228, !12, i64 232, !9, i64 240, !12, i64 248, !12, i64 256, !12, i64 264, !12, i64 272, !12, i64 280, !12, i64 288, !12, i64 296, !12, i64 304, !12, i64 312, !12, i64 320, !12, i64 328, !12, i64 336, !12, i64 344, !12, i64 352, !12, i64 360, !12, i64 368, !12, i64 376, !12, i64 384, !12, i64 392, !9, i64 400, !102, i64 408, !12, i64 504, !12, i64 512, !12, i64 520, !12, i64 528, !8, i64 536, !8, i64 540, !103, i64 544, !12, i64 568, !12, i64 576, !12, i64 584, !103, i64 592, !103, i64 616, !104, i64 640, !9, i64 664, !12, i64 728, !8, i64 736, !8, i64 740, !8, i64 744, !8, i64 748, !15, i64 752, !15, i64 760, !12, i64 768, !12, i64 776}
!101 = !{!"sqlite3InitInfo", !8, i64 0, !9, i64 4, !9, i64 5, !8, i64 6, !8, i64 6, !8, i64 6, !12, i64 8}
!102 = !{!"Lookaside", !8, i64 0, !49, i64 4, !49, i64 6, !9, i64 8, !8, i64 12, !9, i64 16, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88}
!103 = !{!"Hash", !8, i64 0, !8, i64 4, !12, i64 8, !12, i64 16}
!104 = !{!"BusyHandler", !12, i64 0, !12, i64 8, !8, i64 16}
!105 = !{!106, !8, i64 24}
!106 = !{!"Parse", !12, i64 0, !12, i64 8, !12, i64 16, !8, i64 24, !9, i64 28, !9, i64 29, !9, i64 30, !9, i64 31, !9, i64 32, !9, i64 33, !9, i64 34, !9, i64 35, !9, i64 36, !9, i64 37, !9, i64 38, !9, i64 39, !8, i64 40, !8, i64 44, !8, i64 48, !8, i64 52, !8, i64 56, !8, i64 60, !8, i64 64, !8, i64 68, !8, i64 72, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !107, i64 112, !8, i64 128, !8, i64 132, !8, i64 136, !8, i64 140, !8, i64 144, !8, i64 148, !8, i64 152, !8, i64 156, !12, i64 160, !12, i64 168, !12, i64 176, !12, i64 184, !12, i64 192, !12, i64 200, !9, i64 208, !8, i64 216, !8, i64 220, !49, i64 224, !9, i64 226, !9, i64 227, !9, i64 228, !9, i64 229, !9, i64 232, !12, i64 264, !107, i64 272, !107, i64 288, !49, i64 304, !9, i64 306, !9, i64 307, !9, i64 308, !8, i64 312, !8, i64 316, !8, i64 320, !12, i64 328, !12, i64 336, !12, i64 344, !12, i64 352, !12, i64 360, !12, i64 368, !12, i64 376, !107, i64 384, !12, i64 400, !12, i64 408, !12, i64 416}
!107 = !{!"Token", !12, i64 0, !8, i64 8}
!108 = !{!106, !8, i64 48}
!109 = !{!91, !9, i64 4}
!110 = !{!91, !9, i64 1}
!111 = distinct !{!111, !34, !32}
!112 = distinct !{!112, !34, !32}
!113 = !{!91, !9, i64 5}
!114 = distinct !{!114, !34, !32}
!115 = !{!116, !116, i64 0}
!116 = !{!"double", !9, i64 0}
!117 = !{!118, !9, i64 1}
!118 = !{!"FpDecode", !9, i64 0, !9, i64 1, !8, i64 4, !8, i64 8, !12, i64 16, !9, i64 24}
!119 = !{!118, !12, i64 16}
!120 = !{!118, !9, i64 0}
!121 = !{!118, !8, i64 4}
!122 = !{!118, !8, i64 8}
!123 = distinct !{!123, !34, !32}
!124 = distinct !{!124, !34, !32}
!125 = distinct !{!125, !34, !32}
!126 = distinct !{!126, !34, !32}
!127 = distinct !{!127, !34, !32}
!128 = distinct !{!128, !34, !32}
!129 = distinct !{!129, !34, !32}
!130 = distinct !{!130, !34, !32}
!131 = distinct !{!131, !34, !32}
!132 = distinct !{!132, !34, !32}
!133 = distinct !{!133, !34, !32}
!134 = distinct !{!134, !34, !32}
!135 = distinct !{!135, !34, !32}
!136 = distinct !{!136, !32}
!137 = distinct !{!137, !34, !32}
!138 = distinct !{!138, !34, !32}
!139 = distinct !{!139, !34, !32}
!140 = distinct !{!140, !34, !32}
!141 = distinct !{!141, !34, !32}
!142 = !{!84, !9, i64 22}
!143 = distinct !{!143, !34, !32}
!144 = !{!100, !12, i64 496}
!145 = !{!100, !12, i64 472}
!146 = !{!100, !12, i64 480}
!147 = !{!100, !49, i64 414}
!148 = distinct !{!148, !34, !32}
!149 = distinct !{!149, !34, !32}
!150 = distinct !{!150, !34, !32}
!151 = distinct !{!151, !34, !32}
!152 = distinct !{!152, !34, !32}
!153 = distinct !{!153, !34, !32}
!154 = distinct !{!154, !34, !32}
!155 = !{!156, !8, i64 4}
!156 = !{!"Expr", !9, i64 0, !9, i64 1, !9, i64 2, !8, i64 4, !9, i64 8, !12, i64 16, !12, i64 24, !9, i64 32, !8, i64 40, !8, i64 44, !49, i64 48, !49, i64 50, !9, i64 52, !12, i64 56, !9, i64 64}
!157 = !{!156, !12, i64 16}
!158 = distinct !{!158, !34, !32}
!159 = !{!100, !8, i64 84}
!160 = !{!107, !8, i64 8}
!161 = !{!107, !12, i64 0}
!162 = !{!106, !12, i64 344}
!163 = !{!164, !12, i64 24}
!164 = !{!"SrcItem", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !8, i64 48, !8, i64 52, !8, i64 56, !165, i64 60, !8, i64 64, !9, i64 72, !15, i64 80, !9, i64 88, !9, i64 96}
!165 = !{!"", !9, i64 0, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 1, !8, i64 2, !8, i64 2, !8, i64 2, !8, i64 2, !8, i64 2, !8, i64 2, !8, i64 2}
!166 = !{!164, !12, i64 16}
!167 = !{!164, !12, i64 8}
!168 = !{!164, !12, i64 40}
!169 = !{!170, !8, i64 4}
!170 = !{!"Select", !9, i64 0, !49, i64 2, !8, i64 4, !8, i64 8, !8, i64 12, !8, i64 16, !9, i64 20, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !12, i64 112, !12, i64 120}
!171 = !{!170, !8, i64 16}
!172 = !{!100, !12, i64 488}
!173 = !{!100, !12, i64 464}
!174 = !{!175, !12, i64 0}
!175 = !{!"LookasideSlot", !12, i64 0}
!176 = !{!100, !12, i64 448}
!177 = !{!100, !12, i64 768}
!178 = distinct !{!178, !34, !32}
!179 = !{!7, !12, i64 376}
!180 = !{!7, !12, i64 384}
!181 = !{!42, !12, i64 104}
!182 = !{!183, !9, i64 128}
!183 = !{!"sqlite3PrngType", !9, i64 0, !9, i64 64, !9, i64 128}
!184 = distinct !{!184, !34, !32}
!185 = distinct !{!185, !34, !32}
!186 = distinct !{!186, !32}
!187 = distinct !{!187, !34, !32}
!188 = !{!189, !12, i64 8}
!189 = !{!"sqlite3_backup", !12, i64 0, !12, i64 8, !8, i64 16, !8, i64 20, !8, i64 24, !12, i64 32, !12, i64 40, !8, i64 48, !8, i64 52, !8, i64 56, !8, i64 60, !12, i64 64}
!190 = !{!191, !12, i64 8}
!191 = !{!"Btree", !12, i64 0, !12, i64 8, !9, i64 16, !9, i64 17, !9, i64 18, !9, i64 19, !8, i64 20, !8, i64 24, !8, i64 28, !12, i64 32, !12, i64 40, !192, i64 48}
!192 = !{!"BtLock", !12, i64 0, !8, i64 8, !9, i64 12, !12, i64 16}
!193 = !{!194, !12, i64 0}
!194 = !{!"BtShared", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !9, i64 32, !9, i64 33, !9, i64 34, !9, i64 35, !9, i64 36, !9, i64 37, !9, i64 38, !49, i64 40, !49, i64 42, !49, i64 44, !49, i64 46, !49, i64 48, !8, i64 52, !8, i64 56, !8, i64 60, !8, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !12, i64 96, !8, i64 104, !12, i64 112, !12, i64 120, !12, i64 128, !12, i64 136, !8, i64 144}
!195 = !{!189, !12, i64 40}
!196 = !{!194, !8, i64 52}
!197 = !{!198, !12, i64 272}
!198 = !{!"Pager", !12, i64 0, !9, i64 8, !9, i64 9, !9, i64 10, !9, i64 11, !9, i64 12, !9, i64 13, !9, i64 14, !9, i64 15, !9, i64 16, !9, i64 17, !9, i64 18, !9, i64 19, !9, i64 20, !9, i64 21, !9, i64 22, !9, i64 23, !9, i64 24, !9, i64 25, !9, i64 26, !9, i64 27, !9, i64 28, !8, i64 32, !8, i64 36, !8, i64 40, !8, i64 44, !8, i64 48, !8, i64 52, !8, i64 56, !8, i64 60, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !15, i64 96, !15, i64 104, !12, i64 112, !12, i64 120, !8, i64 128, !8, i64 132, !9, i64 136, !8, i64 152, !15, i64 160, !12, i64 168, !49, i64 176, !49, i64 178, !8, i64 180, !8, i64 184, !8, i64 188, !8, i64 192, !15, i64 200, !15, i64 208, !12, i64 216, !12, i64 224, !12, i64 232, !12, i64 240, !9, i64 248, !12, i64 264, !12, i64 272, !12, i64 280, !12, i64 288, !12, i64 296, !12, i64 304}
!199 = !{!200, !12, i64 40}
!200 = !{!"PgHdr", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !8, i64 48, !49, i64 52, !15, i64 56, !12, i64 64, !12, i64 72}
!201 = !{!200, !49, i64 52}
!202 = !{!198, !8, i64 32}
!203 = !{!200, !8, i64 48}
!204 = !{!198, !8, i64 128}
!205 = !{!198, !8, i64 48}
!206 = !{!198, !8, i64 184}
!207 = !{!198, !15, i64 200}
!208 = !{!200, !12, i64 8}
!209 = !{!200, !12, i64 16}
!210 = !{!194, !8, i64 64}
!211 = !{!198, !8, i64 152}
!212 = !{!198, !12, i64 168}
!213 = !{!200, !12, i64 32}
!214 = !{!198, !12, i64 72}
!215 = !{!216, !12, i64 0}
!216 = !{!"sqlite3_file", !12, i64 0}
!217 = !{!218, !12, i64 144}
!218 = !{!"sqlite3_io_methods", !8, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !12, i64 32, !12, i64 40, !12, i64 48, !12, i64 56, !12, i64 64, !12, i64 72, !12, i64 80, !12, i64 88, !12, i64 96, !12, i64 104, !12, i64 112, !12, i64 120, !12, i64 128, !12, i64 136, !12, i64 144}
!219 = distinct !{!219, !34, !32}
!220 = !{!106, !12, i64 0}
!221 = !{!100, !9, i64 103}
!222 = !{!100, !9, i64 104}
!223 = !{!100, !8, i64 220}
!224 = !{!100, !8, i64 408}
!225 = !{!100, !49, i64 412}
!226 = !{!106, !12, i64 264}
!227 = distinct !{!227, !34, !32}
!228 = !{!100, !9, i64 107}
!229 = !{!106, !12, i64 8}
!230 = !{!106, !12, i64 408}
!231 = !{i64 0, i64 8, !36, i64 8, i64 8, !36, i64 16, i64 8, !36, i64 24, i64 8, !36, i64 32, i64 8, !36, i64 40, i64 8, !36, i64 48, i64 8, !36, i64 56, i64 8, !36}
!232 = !{!7, !9, i64 8}
!233 = !{i64 0, i64 4, !86, i64 8, i64 8, !36, i64 16, i64 8, !36, i64 24, i64 8, !36, i64 32, i64 8, !36, i64 40, i64 8, !36, i64 48, i64 8, !36, i64 56, i64 8, !36, i64 64, i64 8, !36, i64 72, i64 8, !36, i64 80, i64 8, !36, i64 88, i64 8, !36, i64 96, i64 8, !36}
!234 = !{!7, !8, i64 20}
!235 = !{!7, !8, i64 24}
!236 = !{!7, !9, i64 7}
!237 = !{!7, !15, i64 304}
!238 = !{!7, !15, i64 296}
!239 = !{!7, !8, i64 336}
!240 = !{!7, !8, i64 28}
!241 = !{!7, !15, i64 392}
!242 = !{!100, !12, i64 456}
!243 = !{!100, !12, i64 440}
!244 = !{!200, !12, i64 24}
!245 = !{!246, !15, i64 24}
!246 = !{!"PCache", !12, i64 0, !12, i64 8, !12, i64 16, !15, i64 24, !8, i64 32, !8, i64 36, !8, i64 40, !8, i64 44, !9, i64 48, !9, i64 49, !12, i64 56, !12, i64 64, !12, i64 72}
!247 = !{!200, !15, i64 56}
!248 = !{!246, !9, i64 48}
!249 = !{!7, !12, i64 232}
!250 = !{!246, !12, i64 72}
!251 = !{!200, !12, i64 0}
!252 = !{!246, !12, i64 16}
!253 = !{!200, !12, i64 72}
!254 = !{!200, !12, i64 64}
!255 = !{!246, !12, i64 0}
!256 = !{!246, !9, i64 49}
!257 = !{!246, !12, i64 8}
!258 = !{!198, !12, i64 120}
!259 = !{!260, !8, i64 24}
!260 = !{!"PagerSavepoint", !15, i64 0, !15, i64 8, !12, i64 16, !8, i64 24, !8, i64 28, !8, i64 32, !9, i64 36}
!261 = !{!260, !12, i64 16}
!262 = !{!263, !8, i64 0}
!263 = !{!"Bitvec", !8, i64 0, !8, i64 4, !8, i64 8, !9, i64 16}
!264 = !{!263, !8, i64 8}
!265 = distinct !{!265, !34, !32}
!266 = !{!260, !8, i64 32}
!267 = distinct !{!267, !34, !32}
!268 = distinct !{!268, !34, !32}
!269 = !{!198, !9, i64 9}
!270 = !{!198, !12, i64 88}
!271 = !{!198, !9, i64 26}
!272 = !{!198, !12, i64 0}
!273 = !{!42, !12, i64 40}
!274 = !{!275, !8, i64 8}
!275 = !{!"MemJournal", !12, i64 0, !8, i64 8, !8, i64 12, !12, i64 16, !276, i64 24, !276, i64 40, !8, i64 56, !12, i64 64, !12, i64 72}
!276 = !{!"FilePoint", !15, i64 0, !12, i64 8}
!277 = !{!275, !8, i64 12}
!278 = !{!275, !8, i64 56}
!279 = !{!275, !12, i64 72}
!280 = !{!275, !12, i64 64}
!281 = !{!198, !8, i64 60}
!282 = !{!218, !12, i64 24}
!283 = distinct !{!283, !34, !32}
!284 = distinct !{!284, !34, !32}
!285 = !{!263, !8, i64 4}
!286 = distinct !{!286, !34, !32}
!287 = distinct !{!287, !34, !32}
!288 = !{!189, !8, i64 48}
!289 = !{!189, !8, i64 24}
!290 = !{!189, !12, i64 64}
!291 = distinct !{!291, !34, !32}
!292 = !{!198, !12, i64 280}
!293 = !{!260, !15, i64 8}
!294 = !{!198, !15, i64 96}
!295 = distinct !{!295, !34, !32}
!296 = !{!198, !15, i64 104}
!297 = !{!198, !9, i64 11}
!298 = !{!218, !12, i64 96}
!299 = !{!198, !8, i64 56}
!300 = !{!198, !8, i64 36}
!301 = distinct !{!301, !34, !32}
!302 = !{!198, !12, i64 80}
!303 = !{!198, !12, i64 288}
!304 = !{!7, !12, i64 224}
!305 = !{!48, !12, i64 8}
!306 = !{!48, !12, i64 0}
!307 = distinct !{!307, !34, !32}
!308 = !{!218, !12, i64 16}
!309 = !{!198, !8, i64 192}
!310 = distinct !{!310, !34, !32}
!311 = !{!198, !49, i64 178}
!312 = !{!198, !12, i64 296}
!313 = !{!198, !9, i64 21}
!314 = !{!198, !8, i64 40}
!315 = !{!198, !12, i64 112}
!316 = !{!198, !9, i64 25}
!317 = !{!198, !12, i64 264}
!318 = !{!198, !9, i64 16}
!319 = !{!218, !12, i64 80}
!320 = !{!198, !12, i64 64}
!321 = distinct !{!321, !34, !32}
!322 = distinct !{!322, !34, !32}
!323 = !{!198, !12, i64 224}
!324 = !{!198, !8, i64 52}
!325 = !{!198, !9, i64 24}
!326 = !{!84, !8, i64 32}
!327 = !{!84, !12, i64 24}
!328 = !{!84, !12, i64 40}
!329 = !{!84, !12, i64 48}
!330 = !{!331, !12, i64 0}
!331 = !{!"sqlite3_context", !12, i64 0, !12, i64 8, !12, i64 16, !12, i64 24, !8, i64 32, !8, i64 36, !9, i64 40, !9, i64 41, !9, i64 42, !9, i64 48}
!332 = !{!331, !12, i64 16}
!333 = !{!331, !12, i64 8}
!334 = !{!100, !9, i64 100}
!335 = !{!331, !9, i64 40}
!336 = !{!29, !12, i64 32}
!337 = !{!331, !8, i64 36}
!338 = !{!84, !8, i64 16}
!339 = distinct !{!339, !32}
!340 = distinct !{!340, !34, !32}
!341 = distinct !{!341, !34, !32}
!342 = distinct !{!342, !34, !32}
!343 = distinct !{!343, !34, !32}
!344 = distinct !{!344, !34, !32}
!345 = distinct !{!345, !34, !32}
!346 = distinct !{!346, !34, !32}
!347 = distinct !{!347, !34, !32}
!348 = distinct !{!348, !34, !32}
!349 = distinct !{!349, !34, !32}
!350 = distinct !{!350, !34, !32}
!351 = distinct !{!351, !34, !32}
!352 = distinct !{!352, !34, !32}
!353 = distinct !{!353, !34, !32}
!354 = distinct !{!354, !34, !32}
!355 = distinct !{!355, !34, !32}
!356 = distinct !{!356, !34, !32}
!357 = distinct !{!357, !34, !32}
!358 = distinct !{!358, !34, !32}
!359 = distinct !{!359, !34, !32}
!360 = distinct !{!360, !34, !32}
!361 = distinct !{!361, !34, !32}
!362 = distinct !{!362, !34, !32}
!363 = distinct !{!363, !34, !32}
!364 = distinct !{!364, !34, !32}
!365 = distinct !{!365, !34, !32}
!366 = distinct !{!366, !34, !32}
!367 = distinct !{!367, !34, !32}
!368 = distinct !{!368, !34, !32}
!369 = distinct !{!369, !34, !32}
!370 = distinct !{!370, !34, !32}
!371 = distinct !{!371, !34, !32}
!372 = distinct !{!372, !34, !32}
!373 = distinct !{!373, !34, !32}
