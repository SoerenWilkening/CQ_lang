; control_classical_call_arm_twin_accept_verify_chain70.ll — ACCEPT (bd dm7f.21, R11 round 2 F-A).
; The over-decline the 64-round verification cap made reachable from ordinary
; two-file C (the reviewer's cap_g.c / cap_main_70.c, each TU at clang 19 -O1,
; llvm-linked, target attributes trimmed, R8):
;   cap_g.c:    int G(int v) { return v; }
;   cap_main.c: __attribute__((const)) int G(int v);
;               __attribute__((noinline)) int F(unsigned x, unsigned p) {
;                 int c = (int)((x >> p) & 255u); int acc = 0;
;                 { int v = G(c) + 1; acc ^= v; c = v & 255; }   // x 70 stages
;                 return acc; }
;               int ex(unsigned x, unsigned p) { int q = 0; cq_theta(&q, 0.0); int y = q;
;                 if (q > 3) y = F(x, p); return cq_measure(y); }
; `@G` gets an inferred `returned`, so each stage's `nsw` is proven, on the
; original body, through the previous stage's `@G` argument. Once the twin freezes
; that argument the proof fails, and the loss moved forward one stage per
; verification round: at 70 stages the snapshot a141ab77 builder hit its 64-round
; cap and the emitter failed loudly although the claim had accepted. The cap is
; gone (each round edits at least one of finitely many sites, `editSites`), and
; the plan now counts a call whose `returned` argument it froze as possibly poison
; at once, so the first plan already freezes all 70 `@G` arguments and the `ret`
; (CQ_SPECSAFE_DBG: rounds=0).
; ANALYTIC (R2): on a UB-free execution of the source's `F(x, p)` every stage's
; argument is defined (it is passed to `@G`'s `noundef` parameter), so every
; freeze is the identity; otherwise UB in the source or never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK-COUNT-70: tail call i32 @G(i32 noundef %.fr{{[0-9]*}})
; CHECK:       %.fr70 = freeze i32 %283
; CHECK-NEXT:  ret i32 %.fr70

define i32 @F(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = lshr i32 %0, %1
  %4 = and i32 %3, 255
  %5 = tail call i32 @G(i32 noundef %4) #4
  %6 = add nsw i32 %5, 1
  %7 = and i32 %6, 255
  %8 = tail call i32 @G(i32 noundef %7) #4
  %9 = add nsw i32 %8, 1
  %10 = and i32 %9, 255
  %11 = tail call i32 @G(i32 noundef %10) #4
  %12 = add nsw i32 %11, 1
  %13 = and i32 %12, 255
  %14 = tail call i32 @G(i32 noundef %13) #4
  %15 = add nsw i32 %14, 1
  %16 = and i32 %15, 255
  %17 = tail call i32 @G(i32 noundef %16) #4
  %18 = add nsw i32 %17, 1
  %19 = and i32 %18, 255
  %20 = tail call i32 @G(i32 noundef %19) #4
  %21 = add nsw i32 %20, 1
  %22 = and i32 %21, 255
  %23 = tail call i32 @G(i32 noundef %22) #4
  %24 = add nsw i32 %23, 1
  %25 = and i32 %24, 255
  %26 = tail call i32 @G(i32 noundef %25) #4
  %27 = add nsw i32 %26, 1
  %28 = and i32 %27, 255
  %29 = tail call i32 @G(i32 noundef %28) #4
  %30 = add nsw i32 %29, 1
  %31 = and i32 %30, 255
  %32 = tail call i32 @G(i32 noundef %31) #4
  %33 = add nsw i32 %32, 1
  %34 = and i32 %33, 255
  %35 = tail call i32 @G(i32 noundef %34) #4
  %36 = add nsw i32 %35, 1
  %37 = and i32 %36, 255
  %38 = tail call i32 @G(i32 noundef %37) #4
  %39 = add nsw i32 %38, 1
  %40 = and i32 %39, 255
  %41 = tail call i32 @G(i32 noundef %40) #4
  %42 = add nsw i32 %41, 1
  %43 = and i32 %42, 255
  %44 = tail call i32 @G(i32 noundef %43) #4
  %45 = add nsw i32 %44, 1
  %46 = and i32 %45, 255
  %47 = tail call i32 @G(i32 noundef %46) #4
  %48 = add nsw i32 %47, 1
  %49 = and i32 %48, 255
  %50 = tail call i32 @G(i32 noundef %49) #4
  %51 = add nsw i32 %50, 1
  %52 = and i32 %51, 255
  %53 = tail call i32 @G(i32 noundef %52) #4
  %54 = add nsw i32 %53, 1
  %55 = and i32 %54, 255
  %56 = tail call i32 @G(i32 noundef %55) #4
  %57 = add nsw i32 %56, 1
  %58 = and i32 %57, 255
  %59 = tail call i32 @G(i32 noundef %58) #4
  %60 = add nsw i32 %59, 1
  %61 = and i32 %60, 255
  %62 = tail call i32 @G(i32 noundef %61) #4
  %63 = add nsw i32 %62, 1
  %64 = and i32 %63, 255
  %65 = tail call i32 @G(i32 noundef %64) #4
  %66 = add nsw i32 %65, 1
  %67 = and i32 %66, 255
  %68 = tail call i32 @G(i32 noundef %67) #4
  %69 = add nsw i32 %68, 1
  %70 = and i32 %69, 255
  %71 = tail call i32 @G(i32 noundef %70) #4
  %72 = add nsw i32 %71, 1
  %73 = and i32 %72, 255
  %74 = tail call i32 @G(i32 noundef %73) #4
  %75 = add nsw i32 %74, 1
  %76 = and i32 %75, 255
  %77 = tail call i32 @G(i32 noundef %76) #4
  %78 = add nsw i32 %77, 1
  %79 = and i32 %78, 255
  %80 = tail call i32 @G(i32 noundef %79) #4
  %81 = add nsw i32 %80, 1
  %82 = and i32 %81, 255
  %83 = tail call i32 @G(i32 noundef %82) #4
  %84 = add nsw i32 %83, 1
  %85 = and i32 %84, 255
  %86 = tail call i32 @G(i32 noundef %85) #4
  %87 = add nsw i32 %86, 1
  %88 = and i32 %87, 255
  %89 = tail call i32 @G(i32 noundef %88) #4
  %90 = add nsw i32 %89, 1
  %91 = and i32 %90, 255
  %92 = tail call i32 @G(i32 noundef %91) #4
  %93 = add nsw i32 %92, 1
  %94 = and i32 %93, 255
  %95 = tail call i32 @G(i32 noundef %94) #4
  %96 = add nsw i32 %95, 1
  %97 = and i32 %96, 255
  %98 = tail call i32 @G(i32 noundef %97) #4
  %99 = add nsw i32 %98, 1
  %100 = and i32 %99, 255
  %101 = tail call i32 @G(i32 noundef %100) #4
  %102 = add nsw i32 %101, 1
  %103 = and i32 %102, 255
  %104 = tail call i32 @G(i32 noundef %103) #4
  %105 = add nsw i32 %104, 1
  %106 = and i32 %105, 255
  %107 = tail call i32 @G(i32 noundef %106) #4
  %108 = add nsw i32 %107, 1
  %109 = and i32 %108, 255
  %110 = tail call i32 @G(i32 noundef %109) #4
  %111 = add nsw i32 %110, 1
  %112 = and i32 %111, 255
  %113 = tail call i32 @G(i32 noundef %112) #4
  %114 = add nsw i32 %113, 1
  %115 = and i32 %114, 255
  %116 = tail call i32 @G(i32 noundef %115) #4
  %117 = add nsw i32 %116, 1
  %118 = and i32 %117, 255
  %119 = tail call i32 @G(i32 noundef %118) #4
  %120 = add nsw i32 %119, 1
  %121 = and i32 %120, 255
  %122 = tail call i32 @G(i32 noundef %121) #4
  %123 = add nsw i32 %122, 1
  %124 = and i32 %123, 255
  %125 = tail call i32 @G(i32 noundef %124) #4
  %126 = add nsw i32 %125, 1
  %127 = and i32 %126, 255
  %128 = tail call i32 @G(i32 noundef %127) #4
  %129 = add nsw i32 %128, 1
  %130 = and i32 %129, 255
  %131 = tail call i32 @G(i32 noundef %130) #4
  %132 = add nsw i32 %131, 1
  %133 = and i32 %132, 255
  %134 = tail call i32 @G(i32 noundef %133) #4
  %135 = add nsw i32 %134, 1
  %136 = and i32 %135, 255
  %137 = tail call i32 @G(i32 noundef %136) #4
  %138 = add nsw i32 %137, 1
  %139 = and i32 %138, 255
  %140 = tail call i32 @G(i32 noundef %139) #4
  %141 = add nsw i32 %140, 1
  %142 = and i32 %141, 255
  %143 = tail call i32 @G(i32 noundef %142) #4
  %144 = add nsw i32 %143, 1
  %145 = and i32 %144, 255
  %146 = tail call i32 @G(i32 noundef %145) #4
  %147 = add nsw i32 %146, 1
  %148 = and i32 %147, 255
  %149 = tail call i32 @G(i32 noundef %148) #4
  %150 = add nsw i32 %149, 1
  %151 = and i32 %150, 255
  %152 = tail call i32 @G(i32 noundef %151) #4
  %153 = add nsw i32 %152, 1
  %154 = and i32 %153, 255
  %155 = tail call i32 @G(i32 noundef %154) #4
  %156 = add nsw i32 %155, 1
  %157 = and i32 %156, 255
  %158 = tail call i32 @G(i32 noundef %157) #4
  %159 = add nsw i32 %158, 1
  %160 = and i32 %159, 255
  %161 = tail call i32 @G(i32 noundef %160) #4
  %162 = add nsw i32 %161, 1
  %163 = and i32 %162, 255
  %164 = tail call i32 @G(i32 noundef %163) #4
  %165 = add nsw i32 %164, 1
  %166 = and i32 %165, 255
  %167 = tail call i32 @G(i32 noundef %166) #4
  %168 = add nsw i32 %167, 1
  %169 = and i32 %168, 255
  %170 = tail call i32 @G(i32 noundef %169) #4
  %171 = add nsw i32 %170, 1
  %172 = and i32 %171, 255
  %173 = tail call i32 @G(i32 noundef %172) #4
  %174 = add nsw i32 %173, 1
  %175 = and i32 %174, 255
  %176 = tail call i32 @G(i32 noundef %175) #4
  %177 = add nsw i32 %176, 1
  %178 = and i32 %177, 255
  %179 = tail call i32 @G(i32 noundef %178) #4
  %180 = add nsw i32 %179, 1
  %181 = and i32 %180, 255
  %182 = tail call i32 @G(i32 noundef %181) #4
  %183 = add nsw i32 %182, 1
  %184 = and i32 %183, 255
  %185 = tail call i32 @G(i32 noundef %184) #4
  %186 = add nsw i32 %185, 1
  %187 = and i32 %186, 255
  %188 = tail call i32 @G(i32 noundef %187) #4
  %189 = add nsw i32 %188, 1
  %190 = and i32 %189, 255
  %191 = tail call i32 @G(i32 noundef %190) #4
  %192 = add nsw i32 %191, 1
  %193 = and i32 %192, 255
  %194 = tail call i32 @G(i32 noundef %193) #4
  %195 = add nsw i32 %194, 1
  %196 = and i32 %195, 255
  %197 = tail call i32 @G(i32 noundef %196) #4
  %198 = add nsw i32 %197, 1
  %199 = and i32 %198, 255
  %200 = tail call i32 @G(i32 noundef %199) #4
  %201 = add nsw i32 %200, 1
  %202 = and i32 %201, 255
  %203 = tail call i32 @G(i32 noundef %202) #4
  %204 = add nsw i32 %203, 1
  %205 = and i32 %204, 255
  %206 = tail call i32 @G(i32 noundef %205) #4
  %207 = add nsw i32 %206, 1
  %208 = and i32 %207, 255
  %209 = tail call i32 @G(i32 noundef %208) #4
  %210 = add nsw i32 %209, 1
  %211 = and i32 %210, 255
  %212 = tail call i32 @G(i32 noundef %211) #4
  %213 = add nsw i32 %212, 1
  %214 = and i32 %213, -256
  %215 = xor i32 %6, %214
  %216 = xor i32 %215, %9
  %217 = xor i32 %216, %12
  %218 = xor i32 %217, %15
  %219 = xor i32 %218, %18
  %220 = xor i32 %219, %21
  %221 = xor i32 %220, %24
  %222 = xor i32 %221, %27
  %223 = xor i32 %222, %30
  %224 = xor i32 %223, %33
  %225 = xor i32 %224, %36
  %226 = xor i32 %225, %39
  %227 = xor i32 %226, %42
  %228 = xor i32 %227, %45
  %229 = xor i32 %228, %48
  %230 = xor i32 %229, %51
  %231 = xor i32 %230, %54
  %232 = xor i32 %231, %57
  %233 = xor i32 %232, %60
  %234 = xor i32 %233, %63
  %235 = xor i32 %234, %66
  %236 = xor i32 %235, %69
  %237 = xor i32 %236, %72
  %238 = xor i32 %237, %75
  %239 = xor i32 %238, %78
  %240 = xor i32 %239, %81
  %241 = xor i32 %240, %84
  %242 = xor i32 %241, %87
  %243 = xor i32 %242, %90
  %244 = xor i32 %243, %93
  %245 = xor i32 %244, %96
  %246 = xor i32 %245, %99
  %247 = xor i32 %246, %102
  %248 = xor i32 %247, %105
  %249 = xor i32 %248, %108
  %250 = xor i32 %249, %111
  %251 = xor i32 %250, %114
  %252 = xor i32 %251, %117
  %253 = xor i32 %252, %120
  %254 = xor i32 %253, %123
  %255 = xor i32 %254, %126
  %256 = xor i32 %255, %129
  %257 = xor i32 %256, %132
  %258 = xor i32 %257, %135
  %259 = xor i32 %258, %138
  %260 = xor i32 %259, %141
  %261 = xor i32 %260, %144
  %262 = xor i32 %261, %147
  %263 = xor i32 %262, %150
  %264 = xor i32 %263, %153
  %265 = xor i32 %264, %156
  %266 = xor i32 %265, %159
  %267 = xor i32 %266, %162
  %268 = xor i32 %267, %165
  %269 = xor i32 %268, %168
  %270 = xor i32 %269, %171
  %271 = xor i32 %270, %174
  %272 = xor i32 %271, %177
  %273 = xor i32 %272, %180
  %274 = xor i32 %273, %183
  %275 = xor i32 %274, %186
  %276 = xor i32 %275, %189
  %277 = xor i32 %276, %192
  %278 = xor i32 %277, %195
  %279 = xor i32 %278, %198
  %280 = xor i32 %279, %201
  %281 = xor i32 %280, %204
  %282 = xor i32 %281, %207
  %283 = xor i32 %282, %210
  ret i32 %283
}

define i32 @ex(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #5
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @F(i32 noundef %0, i32 noundef %1)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define noundef i32 @G(i32 noundef returned %0) local_unnamed_addr #3 {
  ret i32 %0
}

attributes #0 = { mustprogress nofree noinline nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #4 = { nounwind willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
