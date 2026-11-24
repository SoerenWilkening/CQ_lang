; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/c2fe462d-a1bf-43b2-9ac5-1f1cc83a57bb/scratchpad/sf/sf.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%"class.std::__1::basic_istream<char>::sentry" = type { i8 }
%"class.Stockfish::Option" = type { %"class.std::__1::basic_string", %"class.std::__1::basic_string", %"class.std::__1::basic_string", i32, i32, i64, [8 x i8], %"class.std::__1::function.117", ptr, [8 x i8] }
%"class.std::__1::basic_string" = type { %"class.std::__1::__compressed_pair.1" }
%"class.std::__1::__compressed_pair.1" = type { %"struct.std::__1::__compressed_pair_elem.2" }
%"struct.std::__1::__compressed_pair_elem.2" = type { %"union.std::__1::basic_string<char>::__rep" }
%"union.std::__1::basic_string<char>::__rep" = type { %"struct.std::__1::basic_string<char>::__long" }
%"struct.std::__1::basic_string<char>::__long" = type { %struct.anon.3, i64, ptr }
%struct.anon.3 = type { i64 }
%"class.std::__1::function.117" = type { %"class.std::__1::__function::__value_func.121" }
%"class.std::__1::__function::__value_func.121" = type { %"struct.std::__1::aligned_storage<24>::type", ptr, [8 x i8] }
%"struct.std::__1::aligned_storage<24>::type" = type { [32 x i8] }

@_ZN9Stockfish10Tablebases14MaxCardinalityE = external local_unnamed_addr global i32, align 4
@.str.313 = external hidden unnamed_addr constant [17 x i8], align 1
@.str.3.314 = external hidden unnamed_addr constant [17 x i8], align 1
@.str.4.315 = external hidden unnamed_addr constant [17 x i8], align 1
@_ZN9Stockfish8PopCnt16E = external local_unnamed_addr global [65536 x i8], align 16
@_ZSt7nothrow = external global %"class.std::__1::basic_istream<char>::sentry", align 1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #1

; Function Attrs: nobuiltin nounwind
declare void @_ZdlPvm(ptr noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #3

; Function Attrs: nobuiltin nounwind allocsize(0)
declare noalias noundef ptr @_ZnwmRKSt9nothrow_t(i64 noundef, ptr noundef nonnull align 1 dereferenceable(1)) local_unnamed_addr #4

; Function Attrs: nobuiltin nounwind
declare void @_ZdlPv(ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind ssp uwtable
declare noundef zeroext i1 @_ZN9Stockfish10Tablebases10root_probeERNS_8PositionERNSt3__16vectorINS_6Search8RootMoveENS3_9allocatorIS6_EEEEbb(ptr noundef nonnull align 8 dereferenceable(865), ptr nocapture noundef nonnull readonly align 8 dereferenceable(24), i1 noundef zeroext, i1 noundef zeroext) local_unnamed_addr #5

; Function Attrs: mustprogress nounwind ssp uwtable
declare noundef zeroext i1 @_ZN9Stockfish10Tablebases14root_probe_wdlERNS_8PositionERNSt3__16vectorINS_6Search8RootMoveENS3_9allocatorIS6_EEEEb(ptr noundef nonnull align 8 dereferenceable(865), ptr nocapture noundef nonnull readonly align 8 dereferenceable(24), i1 noundef zeroext) local_unnamed_addr #5

; Function Attrs: mustprogress nounwind ssp uwtable
define { i64, i32 } @_ZN9Stockfish10Tablebases15rank_root_movesERKNS_10OptionsMapERNS_8PositionERNSt3__16vectorINS_6Search8RootMoveENS6_9allocatorIS9_EEEEb(ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(865) %1, ptr nocapture noundef nonnull readonly align 8 dereferenceable(24) %2, i1 noundef zeroext %3) local_unnamed_addr #5 {
  %5 = alloca %"class.Stockfish::Option", align 16
  %6 = alloca %"class.std::__1::basic_string", align 8
  %7 = alloca %"class.Stockfish::Option", align 16
  %8 = alloca %"class.std::__1::basic_string", align 8
  %9 = alloca %"class.Stockfish::Option", align 16
  %10 = alloca %"class.std::__1::basic_string", align 8
  %11 = alloca %"class.Stockfish::Option", align 16
  %12 = alloca %"class.std::__1::basic_string", align 8
  %13 = alloca %"class.Stockfish::Option", align 16
  %14 = alloca %"class.std::__1::basic_string", align 8
  %15 = load ptr, ptr %2, align 8, !tbaa !6
  %16 = getelementptr inbounds i8, ptr %2, i64 8
  %17 = load ptr, ptr %16, align 8, !tbaa !13
  %18 = icmp eq ptr %15, %17
  br i1 %18, label %365, label %19

19:                                               ; preds = %4
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %5) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %6) #6
  store i8 32, ptr %6, align 8
  %20 = getelementptr inbounds i8, ptr %6, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %20, ptr noundef nonnull align 1 dereferenceable(16) @.str.313, i64 16, i1 false)
  %21 = getelementptr inbounds i8, ptr %6, i64 17
  store i8 0, ptr %21, align 1, !tbaa !14
  call void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind nonnull writable sret(%"class.Stockfish::Option") align 16 %5, ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(24) %6) #6
  %22 = call noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152) %5) #6
  %23 = icmp ne i32 %22, 0
  %24 = getelementptr inbounds i8, ptr %5, i64 96
  %25 = getelementptr inbounds i8, ptr %5, i64 128
  %26 = load ptr, ptr %25, align 16, !tbaa !15
  %27 = icmp eq ptr %26, %24
  br i1 %27, label %30, label %28

28:                                               ; preds = %19
  %29 = icmp eq ptr %26, null
  br i1 %29, label %35, label %30

30:                                               ; preds = %28, %19
  %31 = phi i64 [ 32, %19 ], [ 40, %28 ]
  %32 = load ptr, ptr %26, align 8, !tbaa !18
  %33 = getelementptr inbounds i8, ptr %32, i64 %31
  %34 = load ptr, ptr %33, align 8
  call void %34(ptr noundef nonnull align 8 dereferenceable(8) %26) #6
  br label %35

35:                                               ; preds = %30, %28
  %36 = getelementptr inbounds i8, ptr %5, i64 48
  %37 = load i8, ptr %36, align 16
  %38 = and i8 %37, 1
  %39 = icmp eq i8 %38, 0
  br i1 %39, label %45, label %40

40:                                               ; preds = %35
  %41 = getelementptr inbounds i8, ptr %5, i64 64
  %42 = load ptr, ptr %41, align 16, !tbaa !14
  %43 = load i64, ptr %36, align 16
  %44 = and i64 %43, -2
  call void @_ZdlPvm(ptr noundef %42, i64 noundef %44) #7
  br label %45

45:                                               ; preds = %40, %35
  %46 = getelementptr inbounds i8, ptr %5, i64 24
  %47 = load i8, ptr %46, align 8
  %48 = and i8 %47, 1
  %49 = icmp eq i8 %48, 0
  br i1 %49, label %55, label %50

50:                                               ; preds = %45
  %51 = getelementptr inbounds i8, ptr %5, i64 40
  %52 = load ptr, ptr %51, align 8, !tbaa !14
  %53 = load i64, ptr %46, align 8
  %54 = and i64 %53, -2
  call void @_ZdlPvm(ptr noundef %52, i64 noundef %54) #7
  br label %55

55:                                               ; preds = %50, %45
  %56 = load i8, ptr %5, align 16
  %57 = and i8 %56, 1
  %58 = icmp eq i8 %57, 0
  br i1 %58, label %64, label %59

59:                                               ; preds = %55
  %60 = getelementptr inbounds i8, ptr %5, i64 16
  %61 = load ptr, ptr %60, align 16, !tbaa !14
  %62 = load i64, ptr %5, align 16
  %63 = and i64 %62, -2
  call void @_ZdlPvm(ptr noundef %61, i64 noundef %63) #7
  br label %64

64:                                               ; preds = %59, %55
  %65 = load i8, ptr %6, align 8
  %66 = and i8 %65, 1
  %67 = icmp eq i8 %66, 0
  br i1 %67, label %73, label %68

68:                                               ; preds = %64
  %69 = getelementptr inbounds i8, ptr %6, i64 16
  %70 = load ptr, ptr %69, align 8, !tbaa !14
  %71 = load i64, ptr %6, align 8
  %72 = and i64 %71, -2
  call void @_ZdlPvm(ptr noundef %70, i64 noundef %72) #7
  br label %73

73:                                               ; preds = %68, %64
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %6) #6
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %5) #6
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %7) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %8) #6
  store i8 32, ptr %8, align 8
  %74 = getelementptr inbounds i8, ptr %8, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %74, ptr noundef nonnull align 1 dereferenceable(16) @.str.3.314, i64 16, i1 false)
  %75 = getelementptr inbounds i8, ptr %8, i64 17
  store i8 0, ptr %75, align 1, !tbaa !14
  call void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind nonnull writable sret(%"class.Stockfish::Option") align 16 %7, ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(24) %8) #6
  %76 = call noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152) %7) #6
  %77 = getelementptr inbounds i8, ptr %7, i64 96
  %78 = getelementptr inbounds i8, ptr %7, i64 128
  %79 = load ptr, ptr %78, align 16, !tbaa !15
  %80 = icmp eq ptr %79, %77
  br i1 %80, label %83, label %81

81:                                               ; preds = %73
  %82 = icmp eq ptr %79, null
  br i1 %82, label %88, label %83

83:                                               ; preds = %81, %73
  %84 = phi i64 [ 32, %73 ], [ 40, %81 ]
  %85 = load ptr, ptr %79, align 8, !tbaa !18
  %86 = getelementptr inbounds i8, ptr %85, i64 %84
  %87 = load ptr, ptr %86, align 8
  call void %87(ptr noundef nonnull align 8 dereferenceable(8) %79) #6
  br label %88

88:                                               ; preds = %83, %81
  %89 = getelementptr inbounds i8, ptr %7, i64 48
  %90 = load i8, ptr %89, align 16
  %91 = and i8 %90, 1
  %92 = icmp eq i8 %91, 0
  br i1 %92, label %98, label %93

93:                                               ; preds = %88
  %94 = getelementptr inbounds i8, ptr %7, i64 64
  %95 = load ptr, ptr %94, align 16, !tbaa !14
  %96 = load i64, ptr %89, align 16
  %97 = and i64 %96, -2
  call void @_ZdlPvm(ptr noundef %95, i64 noundef %97) #7
  br label %98

98:                                               ; preds = %93, %88
  %99 = getelementptr inbounds i8, ptr %7, i64 24
  %100 = load i8, ptr %99, align 8
  %101 = and i8 %100, 1
  %102 = icmp eq i8 %101, 0
  br i1 %102, label %108, label %103

103:                                              ; preds = %98
  %104 = getelementptr inbounds i8, ptr %7, i64 40
  %105 = load ptr, ptr %104, align 8, !tbaa !14
  %106 = load i64, ptr %99, align 8
  %107 = and i64 %106, -2
  call void @_ZdlPvm(ptr noundef %105, i64 noundef %107) #7
  br label %108

108:                                              ; preds = %103, %98
  %109 = load i8, ptr %7, align 16
  %110 = and i8 %109, 1
  %111 = icmp eq i8 %110, 0
  br i1 %111, label %117, label %112

112:                                              ; preds = %108
  %113 = getelementptr inbounds i8, ptr %7, i64 16
  %114 = load ptr, ptr %113, align 16, !tbaa !14
  %115 = load i64, ptr %7, align 16
  %116 = and i64 %115, -2
  call void @_ZdlPvm(ptr noundef %114, i64 noundef %116) #7
  br label %117

117:                                              ; preds = %112, %108
  %118 = load i8, ptr %8, align 8
  %119 = and i8 %118, 1
  %120 = icmp eq i8 %119, 0
  br i1 %120, label %126, label %121

121:                                              ; preds = %117
  %122 = getelementptr inbounds i8, ptr %8, i64 16
  %123 = load ptr, ptr %122, align 8, !tbaa !14
  %124 = load i64, ptr %8, align 8
  %125 = and i64 %124, -2
  call void @_ZdlPvm(ptr noundef %123, i64 noundef %125) #7
  br label %126

126:                                              ; preds = %121, %117
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %8) #6
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %7) #6
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %9) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %10) #6
  store i8 32, ptr %10, align 8
  %127 = getelementptr inbounds i8, ptr %10, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %127, ptr noundef nonnull align 1 dereferenceable(16) @.str.4.315, i64 16, i1 false)
  %128 = getelementptr inbounds i8, ptr %10, i64 17
  store i8 0, ptr %128, align 1, !tbaa !14
  call void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind nonnull writable sret(%"class.Stockfish::Option") align 16 %9, ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(24) %10) #6
  %129 = call noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152) %9) #6
  %130 = getelementptr inbounds i8, ptr %9, i64 96
  %131 = getelementptr inbounds i8, ptr %9, i64 128
  %132 = load ptr, ptr %131, align 16, !tbaa !15
  %133 = icmp eq ptr %132, %130
  br i1 %133, label %136, label %134

134:                                              ; preds = %126
  %135 = icmp eq ptr %132, null
  br i1 %135, label %141, label %136

136:                                              ; preds = %134, %126
  %137 = phi i64 [ 32, %126 ], [ 40, %134 ]
  %138 = load ptr, ptr %132, align 8, !tbaa !18
  %139 = getelementptr inbounds i8, ptr %138, i64 %137
  %140 = load ptr, ptr %139, align 8
  call void %140(ptr noundef nonnull align 8 dereferenceable(8) %132) #6
  br label %141

141:                                              ; preds = %136, %134
  %142 = getelementptr inbounds i8, ptr %9, i64 48
  %143 = load i8, ptr %142, align 16
  %144 = and i8 %143, 1
  %145 = icmp eq i8 %144, 0
  br i1 %145, label %151, label %146

146:                                              ; preds = %141
  %147 = getelementptr inbounds i8, ptr %9, i64 64
  %148 = load ptr, ptr %147, align 16, !tbaa !14
  %149 = load i64, ptr %142, align 16
  %150 = and i64 %149, -2
  call void @_ZdlPvm(ptr noundef %148, i64 noundef %150) #7
  br label %151

151:                                              ; preds = %146, %141
  %152 = getelementptr inbounds i8, ptr %9, i64 24
  %153 = load i8, ptr %152, align 8
  %154 = and i8 %153, 1
  %155 = icmp eq i8 %154, 0
  br i1 %155, label %161, label %156

156:                                              ; preds = %151
  %157 = getelementptr inbounds i8, ptr %9, i64 40
  %158 = load ptr, ptr %157, align 8, !tbaa !14
  %159 = load i64, ptr %152, align 8
  %160 = and i64 %159, -2
  call void @_ZdlPvm(ptr noundef %158, i64 noundef %160) #7
  br label %161

161:                                              ; preds = %156, %151
  %162 = load i8, ptr %9, align 16
  %163 = and i8 %162, 1
  %164 = icmp eq i8 %163, 0
  br i1 %164, label %170, label %165

165:                                              ; preds = %161
  %166 = getelementptr inbounds i8, ptr %9, i64 16
  %167 = load ptr, ptr %166, align 16, !tbaa !14
  %168 = load i64, ptr %9, align 16
  %169 = and i64 %168, -2
  call void @_ZdlPvm(ptr noundef %167, i64 noundef %169) #7
  br label %170

170:                                              ; preds = %165, %161
  %171 = load i8, ptr %10, align 8
  %172 = and i8 %171, 1
  %173 = icmp eq i8 %172, 0
  br i1 %173, label %179, label %174

174:                                              ; preds = %170
  %175 = getelementptr inbounds i8, ptr %10, i64 16
  %176 = load ptr, ptr %175, align 8, !tbaa !14
  %177 = load i64, ptr %10, align 8
  %178 = and i64 %177, -2
  call void @_ZdlPvm(ptr noundef %176, i64 noundef %178) #7
  br label %179

179:                                              ; preds = %174, %170
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %10) #6
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %9) #6
  %180 = load i32, ptr @_ZN9Stockfish10Tablebases14MaxCardinalityE, align 4, !tbaa !20
  %181 = icmp sgt i32 %129, %180
  %182 = call i32 @llvm.smin.i32(i32 %129, i32 %180)
  %183 = select i1 %181, i32 0, i32 %76
  %184 = getelementptr inbounds i8, ptr %1, i64 256
  %185 = load i64, ptr %184, align 8, !tbaa !22
  %186 = lshr i64 %185, 16
  %187 = lshr i64 %185, 32
  %188 = lshr i64 %185, 48
  %189 = and i64 %185, 65535
  %190 = getelementptr inbounds [65536 x i8], ptr @_ZN9Stockfish8PopCnt16E, i64 0, i64 %189
  %191 = load i8, ptr %190, align 1, !tbaa !14
  %192 = zext i8 %191 to i32
  %193 = and i64 %186, 65535
  %194 = getelementptr inbounds [65536 x i8], ptr @_ZN9Stockfish8PopCnt16E, i64 0, i64 %193
  %195 = load i8, ptr %194, align 1, !tbaa !14
  %196 = zext i8 %195 to i32
  %197 = add nuw nsw i32 %196, %192
  %198 = and i64 %187, 65535
  %199 = getelementptr inbounds [65536 x i8], ptr @_ZN9Stockfish8PopCnt16E, i64 0, i64 %198
  %200 = load i8, ptr %199, align 1, !tbaa !14
  %201 = zext i8 %200 to i32
  %202 = add nuw nsw i32 %197, %201
  %203 = getelementptr inbounds [65536 x i8], ptr @_ZN9Stockfish8PopCnt16E, i64 0, i64 %188
  %204 = load i8, ptr %203, align 1, !tbaa !14
  %205 = zext i8 %204 to i32
  %206 = add nuw nsw i32 %202, %205
  %207 = icmp slt i32 %182, %206
  br i1 %207, label %327, label %208

208:                                              ; preds = %179
  %209 = getelementptr inbounds i8, ptr %1, i64 848
  %210 = load ptr, ptr %209, align 8, !tbaa !24
  %211 = getelementptr inbounds i8, ptr %210, i64 24
  %212 = load i32, ptr %211, align 8, !tbaa !28
  %213 = and i32 %212, 15
  %214 = icmp eq i32 %213, 0
  br i1 %214, label %215, label %327

215:                                              ; preds = %208
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %11) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %12) #6
  store i8 32, ptr %12, align 8
  %216 = getelementptr inbounds i8, ptr %12, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %216, ptr noundef nonnull align 1 dereferenceable(16) @.str.313, i64 16, i1 false)
  %217 = getelementptr inbounds i8, ptr %12, i64 17
  store i8 0, ptr %217, align 1, !tbaa !14
  call void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind nonnull writable sret(%"class.Stockfish::Option") align 16 %11, ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(24) %12) #6
  %218 = call noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152) %11) #6
  %219 = icmp ne i32 %218, 0
  %220 = call noundef zeroext i1 @_ZN9Stockfish10Tablebases10root_probeERNS_8PositionERNSt3__16vectorINS_6Search8RootMoveENS3_9allocatorIS6_EEEEbb(ptr noundef nonnull align 8 dereferenceable(865) %1, ptr noundef nonnull align 8 dereferenceable(24) %2, i1 noundef zeroext %219, i1 noundef zeroext %3)
  %221 = getelementptr inbounds i8, ptr %11, i64 96
  %222 = getelementptr inbounds i8, ptr %11, i64 128
  %223 = load ptr, ptr %222, align 16, !tbaa !15
  %224 = icmp eq ptr %223, %221
  br i1 %224, label %227, label %225

225:                                              ; preds = %215
  %226 = icmp eq ptr %223, null
  br i1 %226, label %232, label %227

227:                                              ; preds = %225, %215
  %228 = phi i64 [ 32, %215 ], [ 40, %225 ]
  %229 = load ptr, ptr %223, align 8, !tbaa !18
  %230 = getelementptr inbounds i8, ptr %229, i64 %228
  %231 = load ptr, ptr %230, align 8
  call void %231(ptr noundef nonnull align 8 dereferenceable(8) %223) #6
  br label %232

232:                                              ; preds = %227, %225
  %233 = getelementptr inbounds i8, ptr %11, i64 48
  %234 = load i8, ptr %233, align 16
  %235 = and i8 %234, 1
  %236 = icmp eq i8 %235, 0
  br i1 %236, label %242, label %237

237:                                              ; preds = %232
  %238 = getelementptr inbounds i8, ptr %11, i64 64
  %239 = load ptr, ptr %238, align 16, !tbaa !14
  %240 = load i64, ptr %233, align 16
  %241 = and i64 %240, -2
  call void @_ZdlPvm(ptr noundef %239, i64 noundef %241) #7
  br label %242

242:                                              ; preds = %237, %232
  %243 = getelementptr inbounds i8, ptr %11, i64 24
  %244 = load i8, ptr %243, align 8
  %245 = and i8 %244, 1
  %246 = icmp eq i8 %245, 0
  br i1 %246, label %252, label %247

247:                                              ; preds = %242
  %248 = getelementptr inbounds i8, ptr %11, i64 40
  %249 = load ptr, ptr %248, align 8, !tbaa !14
  %250 = load i64, ptr %243, align 8
  %251 = and i64 %250, -2
  call void @_ZdlPvm(ptr noundef %249, i64 noundef %251) #7
  br label %252

252:                                              ; preds = %247, %242
  %253 = load i8, ptr %11, align 16
  %254 = and i8 %253, 1
  %255 = icmp eq i8 %254, 0
  br i1 %255, label %261, label %256

256:                                              ; preds = %252
  %257 = getelementptr inbounds i8, ptr %11, i64 16
  %258 = load ptr, ptr %257, align 16, !tbaa !14
  %259 = load i64, ptr %11, align 16
  %260 = and i64 %259, -2
  call void @_ZdlPvm(ptr noundef %258, i64 noundef %260) #7
  br label %261

261:                                              ; preds = %256, %252
  %262 = load i8, ptr %12, align 8
  %263 = and i8 %262, 1
  %264 = icmp eq i8 %263, 0
  br i1 %264, label %270, label %265

265:                                              ; preds = %261
  %266 = getelementptr inbounds i8, ptr %12, i64 16
  %267 = load ptr, ptr %266, align 8, !tbaa !14
  %268 = load i64, ptr %12, align 8
  %269 = and i64 %268, -2
  call void @_ZdlPvm(ptr noundef %267, i64 noundef %269) #7
  br label %270

270:                                              ; preds = %265, %261
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %12) #6
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %11) #6
  br i1 %220, label %327, label %271

271:                                              ; preds = %270
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %13) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %14) #6
  store i8 32, ptr %14, align 8
  %272 = getelementptr inbounds i8, ptr %14, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(16) %272, ptr noundef nonnull align 1 dereferenceable(16) @.str.313, i64 16, i1 false)
  %273 = getelementptr inbounds i8, ptr %14, i64 17
  store i8 0, ptr %273, align 1, !tbaa !14
  call void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind nonnull writable sret(%"class.Stockfish::Option") align 16 %13, ptr noundef nonnull align 16 dereferenceable(80) %0, ptr noundef nonnull align 8 dereferenceable(24) %14) #6
  %274 = call noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152) %13) #6
  %275 = icmp ne i32 %274, 0
  %276 = call noundef zeroext i1 @_ZN9Stockfish10Tablebases14root_probe_wdlERNS_8PositionERNSt3__16vectorINS_6Search8RootMoveENS3_9allocatorIS6_EEEEb(ptr noundef nonnull align 8 dereferenceable(865) %1, ptr noundef nonnull align 8 dereferenceable(24) %2, i1 noundef zeroext %275)
  %277 = getelementptr inbounds i8, ptr %13, i64 96
  %278 = getelementptr inbounds i8, ptr %13, i64 128
  %279 = load ptr, ptr %278, align 16, !tbaa !15
  %280 = icmp eq ptr %279, %277
  br i1 %280, label %283, label %281

281:                                              ; preds = %271
  %282 = icmp eq ptr %279, null
  br i1 %282, label %288, label %283

283:                                              ; preds = %281, %271
  %284 = phi i64 [ 32, %271 ], [ 40, %281 ]
  %285 = load ptr, ptr %279, align 8, !tbaa !18
  %286 = getelementptr inbounds i8, ptr %285, i64 %284
  %287 = load ptr, ptr %286, align 8
  call void %287(ptr noundef nonnull align 8 dereferenceable(8) %279) #6
  br label %288

288:                                              ; preds = %283, %281
  %289 = getelementptr inbounds i8, ptr %13, i64 48
  %290 = load i8, ptr %289, align 16
  %291 = and i8 %290, 1
  %292 = icmp eq i8 %291, 0
  br i1 %292, label %298, label %293

293:                                              ; preds = %288
  %294 = getelementptr inbounds i8, ptr %13, i64 64
  %295 = load ptr, ptr %294, align 16, !tbaa !14
  %296 = load i64, ptr %289, align 16
  %297 = and i64 %296, -2
  call void @_ZdlPvm(ptr noundef %295, i64 noundef %297) #7
  br label %298

298:                                              ; preds = %293, %288
  %299 = getelementptr inbounds i8, ptr %13, i64 24
  %300 = load i8, ptr %299, align 8
  %301 = and i8 %300, 1
  %302 = icmp eq i8 %301, 0
  br i1 %302, label %308, label %303

303:                                              ; preds = %298
  %304 = getelementptr inbounds i8, ptr %13, i64 40
  %305 = load ptr, ptr %304, align 8, !tbaa !14
  %306 = load i64, ptr %299, align 8
  %307 = and i64 %306, -2
  call void @_ZdlPvm(ptr noundef %305, i64 noundef %307) #7
  br label %308

308:                                              ; preds = %303, %298
  %309 = load i8, ptr %13, align 16
  %310 = and i8 %309, 1
  %311 = icmp eq i8 %310, 0
  br i1 %311, label %317, label %312

312:                                              ; preds = %308
  %313 = getelementptr inbounds i8, ptr %13, i64 16
  %314 = load ptr, ptr %313, align 16, !tbaa !14
  %315 = load i64, ptr %13, align 16
  %316 = and i64 %315, -2
  call void @_ZdlPvm(ptr noundef %314, i64 noundef %316) #7
  br label %317

317:                                              ; preds = %312, %308
  %318 = load i8, ptr %14, align 8
  %319 = and i8 %318, 1
  %320 = icmp eq i8 %319, 0
  br i1 %320, label %326, label %321

321:                                              ; preds = %317
  %322 = getelementptr inbounds i8, ptr %14, i64 16
  %323 = load ptr, ptr %322, align 8, !tbaa !14
  %324 = load i64, ptr %14, align 8
  %325 = and i64 %324, -2
  call void @_ZdlPvm(ptr noundef %323, i64 noundef %325) #7
  br label %326

326:                                              ; preds = %321, %317
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %14) #6
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %13) #6
  br label %327

327:                                              ; preds = %326, %270, %208, %179
  %328 = phi i1 [ false, %179 ], [ false, %208 ], [ %220, %270 ], [ %276, %326 ]
  %329 = phi i1 [ true, %179 ], [ true, %208 ], [ true, %270 ], [ false, %326 ]
  %330 = load ptr, ptr %2, align 8, !tbaa !6
  %331 = load ptr, ptr %16, align 8, !tbaa !13
  br i1 %328, label %332, label %358

332:                                              ; preds = %327
  %333 = ptrtoint ptr %331 to i64
  %334 = ptrtoint ptr %330 to i64
  %335 = sub i64 %333, %334
  %336 = ashr exact i64 %335, 6
  %337 = icmp sgt i64 %336, 0
  br i1 %337, label %338, label %346

338:                                              ; preds = %343, %332
  %339 = phi i64 [ %344, %343 ], [ %336, %332 ]
  %340 = shl nuw nsw i64 %339, 6
  %341 = call noalias noundef ptr @_ZnwmRKSt9nothrow_t(i64 noundef %340, ptr noundef nonnull align 1 dereferenceable(1) @_ZSt7nothrow) #8
  %342 = icmp eq ptr %341, null
  br i1 %342, label %343, label %346

343:                                              ; preds = %338
  %344 = lshr i64 %339, 1
  %345 = icmp ult i64 %339, 2
  br i1 %345, label %346, label %338, !llvm.loop !35

346:                                              ; preds = %343, %338, %332
  %347 = phi ptr [ null, %332 ], [ %341, %338 ], [ %341, %343 ]
  %348 = phi i64 [ 0, %332 ], [ 0, %343 ], [ %339, %338 ]
  call fastcc void @"_ZNSt3__113__stable_sortINS_17_ClassicAlgPolicyERZN9Stockfish10Tablebases15rank_root_movesERKNS2_10OptionsMapERNS2_8PositionERNS_6vectorINS2_6Search8RootMoveENS_9allocatorISB_EEEEbE3$_0NS_11__wrap_iterIPSB_EEEEvT1_SL_T0_NS_15iterator_traitsISL_E15difference_typeEPNSO_10value_typeEl"(ptr %330, ptr %331, i64 noundef %336, ptr noundef %347, i64 noundef %348)
  %349 = icmp eq ptr %347, null
  br i1 %349, label %351, label %350

350:                                              ; preds = %346
  call void @_ZdlPv(ptr noundef %347) #7
  br label %351

351:                                              ; preds = %350, %346
  br i1 %329, label %357, label %352

352:                                              ; preds = %351
  %353 = load ptr, ptr %2, align 8, !tbaa !6
  %354 = getelementptr inbounds i8, ptr %353, i64 36
  %355 = load i32, ptr %354, align 4, !tbaa !38
  %356 = icmp slt i32 %355, 1
  br i1 %356, label %357, label %365

357:                                              ; preds = %352, %351
  br label %365

358:                                              ; preds = %327
  %359 = icmp eq ptr %330, %331
  br i1 %359, label %365, label %360

360:                                              ; preds = %360, %358
  %361 = phi ptr [ %363, %360 ], [ %330, %358 ]
  %362 = getelementptr inbounds i8, ptr %361, i64 32
  store i32 0, ptr %362, align 8, !tbaa !43
  %363 = getelementptr inbounds i8, ptr %361, i64 64
  %364 = icmp eq ptr %363, %331
  br i1 %364, label %365, label %360, !llvm.loop !44

365:                                              ; preds = %360, %358, %357, %352, %4
  %366 = phi i1 [ false, %4 ], [ %23, %357 ], [ %23, %352 ], [ %23, %358 ], [ %23, %360 ]
  %367 = phi i1 [ false, %4 ], [ %328, %357 ], [ %328, %352 ], [ %328, %358 ], [ %328, %360 ]
  %368 = phi i32 [ 0, %4 ], [ 0, %357 ], [ %182, %352 ], [ %182, %358 ], [ %182, %360 ]
  %369 = phi i32 [ 0, %4 ], [ %183, %357 ], [ %183, %352 ], [ %183, %358 ], [ %183, %360 ]
  %370 = select i1 %366, i64 1099511627776, i64 0
  %371 = select i1 %367, i64 4294967296, i64 0
  %372 = or disjoint i64 %371, %370
  %373 = zext i32 %368 to i64
  %374 = or disjoint i64 %372, %373
  %375 = insertvalue { i64, i32 } poison, i64 %374, 0
  %376 = insertvalue { i64, i32 } %375, i32 %369, 1
  ret { i64, i32 } %376
}

; Function Attrs: mustprogress nounwind ssp uwtable
declare hidden fastcc void @"_ZNSt3__113__stable_sortINS_17_ClassicAlgPolicyERZN9Stockfish10Tablebases15rank_root_movesERKNS2_10OptionsMapERNS2_8PositionERNS_6vectorINS2_6Search8RootMoveENS_9allocatorISB_EEEEbE3$_0NS_11__wrap_iterIPSB_EEEEvT1_SL_T0_NS_15iterator_traitsISL_E15difference_typeEPNSO_10value_typeEl"(ptr, ptr, i64 noundef, ptr noundef, i64 noundef) unnamed_addr #5

; Function Attrs: mustprogress nounwind ssp uwtable
declare void @_ZNK9Stockfish10OptionsMapixERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(ptr dead_on_unwind noalias writable sret(%"class.Stockfish::Option") align 16, ptr noundef nonnull align 16 dereferenceable(80), ptr noundef nonnull align 8 dereferenceable(24)) local_unnamed_addr #5 align 2

; Function Attrs: mustprogress nounwind ssp uwtable
declare noundef i32 @_ZNK9Stockfish6OptioncviEv(ptr noundef nonnull align 16 dereferenceable(152)) local_unnamed_addr #5 align 2

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nobuiltin nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nobuiltin nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { builtin nounwind }
attributes #8 = { nounwind allocsize(0) }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !8, i64 0}
!7 = !{!"_ZTSNSt3__16vectorIN9Stockfish6Search8RootMoveENS_9allocatorIS3_EEEE", !8, i64 0, !8, i64 8, !11, i64 16}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C++ TBAA"}
!11 = !{!"_ZTSNSt3__117__compressed_pairIPN9Stockfish6Search8RootMoveENS_9allocatorIS3_EEEE", !12, i64 0}
!12 = !{!"_ZTSNSt3__122__compressed_pair_elemIPN9Stockfish6Search8RootMoveELi0ELb0EEE", !8, i64 0}
!13 = !{!7, !8, i64 8}
!14 = !{!9, !9, i64 0}
!15 = !{!16, !8, i64 32}
!16 = !{!"_ZTSNSt3__110__function12__value_funcIFNS_8optionalINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEEERKN9Stockfish6OptionEEEE", !17, i64 0, !8, i64 32}
!17 = !{!"_ZTSNSt3__115aligned_storageILm24ELm16EE4typeE", !9, i64 0}
!18 = !{!19, !19, i64 0}
!19 = !{!"vtable pointer", !10, i64 0}
!20 = !{!21, !21, i64 0}
!21 = !{!"int", !9, i64 0}
!22 = !{!23, !23, i64 0}
!23 = !{!"long long", !9, i64 0}
!24 = !{!25, !8, i64 848}
!25 = !{!"_ZTSN9Stockfish8PositionE", !9, i64 0, !9, i64 256, !9, i64 320, !9, i64 336, !9, i64 400, !9, i64 656, !9, i64 720, !8, i64 848, !21, i64 856, !26, i64 860, !27, i64 864}
!26 = !{!"_ZTSN9Stockfish5ColorE", !9, i64 0}
!27 = !{!"bool", !9, i64 0}
!28 = !{!29, !21, i64 24}
!29 = !{!"_ZTSN9Stockfish9StateInfoE", !23, i64 0, !23, i64 8, !9, i64 16, !21, i64 24, !21, i64 28, !21, i64 32, !30, i64 36, !23, i64 40, !23, i64 48, !8, i64 56, !9, i64 64, !9, i64 80, !9, i64 96, !31, i64 160, !21, i64 164, !32, i64 192, !33, i64 12608, !34, i64 13248}
!30 = !{!"_ZTSN9Stockfish6SquareE", !9, i64 0}
!31 = !{!"_ZTSN9Stockfish5PieceE", !9, i64 0}
!32 = !{!"_ZTSN9Stockfish4Eval4NNUE11AccumulatorILj3072EEE", !9, i64 0, !9, i64 12288, !9, i64 12352}
!33 = !{!"_ZTSN9Stockfish4Eval4NNUE11AccumulatorILj128EEE", !9, i64 0, !9, i64 512, !9, i64 576}
!34 = !{!"_ZTSN9Stockfish10DirtyPieceE", !21, i64 0, !9, i64 4, !9, i64 16, !9, i64 28}
!35 = distinct !{!35, !36, !37}
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !{!39, !21, i64 36}
!39 = !{!"_ZTSN9Stockfish6Search8RootMoveE", !23, i64 0, !21, i64 8, !21, i64 12, !21, i64 16, !21, i64 20, !27, i64 24, !27, i64 25, !21, i64 28, !21, i64 32, !21, i64 36, !40, i64 40}
!40 = !{!"_ZTSNSt3__16vectorIN9Stockfish4MoveENS_9allocatorIS2_EEEE", !8, i64 0, !8, i64 8, !41, i64 16}
!41 = !{!"_ZTSNSt3__117__compressed_pairIPN9Stockfish4MoveENS_9allocatorIS2_EEEE", !42, i64 0}
!42 = !{!"_ZTSNSt3__122__compressed_pair_elemIPN9Stockfish4MoveELi0ELb0EEE", !8, i64 0}
!43 = !{!39, !21, i64 32}
!44 = distinct !{!44, !37}
