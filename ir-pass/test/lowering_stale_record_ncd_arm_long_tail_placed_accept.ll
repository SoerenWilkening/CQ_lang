; lowering_stale_record_ncd_arm_long_tail_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.1, batch 053 round-1 finding F1): the cross-block placement
; asks "can the read's block run again without the slot's block" EXACTLY, so a long
; classical tail after the read does not refuse it.
;
;   volatile int g;
;   __attribute__((noinline)) void ext(int i) { g = i; }
;   int main(int argc, char **argv) {
;     int q = argc; cq_theta(&q, .5);
;     int s = 0;
;     if (argc > 3) { int q2 = q; cq_theta(&q2, .3); s = (int)cq_measure(q2); }  // the staling gate, in a classical arm
;     int m1 = (int)cq_measure(q * 3);   // stale `q * 3` after the merge
;     if (argc > 11) ext(11);            // ... 40 such lines, argc > 11 .. argc > 50:
;     ...                                //     a tail of 80 blocks after the read
;     if (argc > 50) ext(50);
;     return m1 + s;
;   }
;
; (`argc > N` rather than `argc == N`: -O1 folds an `==` chain into one `switch`,
; which keeps the CFG under LLVM's 32-block cap.) The draft asked the repeat question
; with `isPotentiallyReachableFromMany(succ(B), B, {D}, &DT)`, which with an exclusion
; set drops the dominator tree and answers "reachable" past 32 explored blocks.
; MEASURED (batch-053 L3, the draft's call restored in a scratch build): this module
; declined `cq opcode lowering: operand predates a non-diagonal gate` and its 2-line
; tail placed. `blockReachesAvoiding` (StaleReadRegion.h) walks the CFG uncapped.
; The `mul` template is emitted before the arm's branch, as in
; lowering_stale_record_ncd_arm_placed_accept.ll; the warning is the same lyyf
; live-record class (the source keeps the copy `q * 3` across the arm's Ry on `q`).
; The reviewer's spelling (`cq_measure(q2)` after the tail, a merge phi of `q2`) now
; passes this fence and then declines at the one-register merge-phi lift, a SECOND
; capped reachability in TaintPropagation.cpp (follow-up, outside this lane's files).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN %s < %t.err
; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: icmp sgt i32 %0, 3
; CHECK-NEXT: %[[M:[a-z_0-9]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: br i1
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[M]])
; CHECK:      call void @ext(i32 noundef 50)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = global i32 0, align 4

define void @ext(i32 noundef %0) local_unnamed_addr #0 {
  store volatile i32 %0, ptr @g, align 4
  ret void
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %4 = icmp sgt i32 %0, 3
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %7, %5 ], [ 0, %2 ]
  %10 = mul nsw i32 %3, 3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = icmp sgt i32 %0, 11
  br i1 %12, label %13, label %14

13:                                               ; preds = %8
  tail call void @ext(i32 noundef 11)
  br label %14

14:                                               ; preds = %13, %8
  %15 = icmp sgt i32 %0, 12
  br i1 %15, label %16, label %17

16:                                               ; preds = %14
  tail call void @ext(i32 noundef 12)
  br label %17

17:                                               ; preds = %16, %14
  %18 = icmp sgt i32 %0, 13
  br i1 %18, label %19, label %20

19:                                               ; preds = %17
  tail call void @ext(i32 noundef 13)
  br label %20

20:                                               ; preds = %19, %17
  %21 = icmp sgt i32 %0, 14
  br i1 %21, label %22, label %23

22:                                               ; preds = %20
  tail call void @ext(i32 noundef 14)
  br label %23

23:                                               ; preds = %22, %20
  %24 = icmp sgt i32 %0, 15
  br i1 %24, label %25, label %26

25:                                               ; preds = %23
  tail call void @ext(i32 noundef 15)
  br label %26

26:                                               ; preds = %25, %23
  %27 = icmp sgt i32 %0, 16
  br i1 %27, label %28, label %29

28:                                               ; preds = %26
  tail call void @ext(i32 noundef 16)
  br label %29

29:                                               ; preds = %28, %26
  %30 = icmp sgt i32 %0, 17
  br i1 %30, label %31, label %32

31:                                               ; preds = %29
  tail call void @ext(i32 noundef 17)
  br label %32

32:                                               ; preds = %31, %29
  %33 = icmp sgt i32 %0, 18
  br i1 %33, label %34, label %35

34:                                               ; preds = %32
  tail call void @ext(i32 noundef 18)
  br label %35

35:                                               ; preds = %34, %32
  %36 = icmp sgt i32 %0, 19
  br i1 %36, label %37, label %38

37:                                               ; preds = %35
  tail call void @ext(i32 noundef 19)
  br label %38

38:                                               ; preds = %37, %35
  %39 = icmp sgt i32 %0, 20
  br i1 %39, label %40, label %41

40:                                               ; preds = %38
  tail call void @ext(i32 noundef 20)
  br label %41

41:                                               ; preds = %40, %38
  %42 = icmp sgt i32 %0, 21
  br i1 %42, label %43, label %44

43:                                               ; preds = %41
  tail call void @ext(i32 noundef 21)
  br label %44

44:                                               ; preds = %43, %41
  %45 = icmp sgt i32 %0, 22
  br i1 %45, label %46, label %47

46:                                               ; preds = %44
  tail call void @ext(i32 noundef 22)
  br label %47

47:                                               ; preds = %46, %44
  %48 = icmp sgt i32 %0, 23
  br i1 %48, label %49, label %50

49:                                               ; preds = %47
  tail call void @ext(i32 noundef 23)
  br label %50

50:                                               ; preds = %49, %47
  %51 = icmp sgt i32 %0, 24
  br i1 %51, label %52, label %53

52:                                               ; preds = %50
  tail call void @ext(i32 noundef 24)
  br label %53

53:                                               ; preds = %52, %50
  %54 = icmp sgt i32 %0, 25
  br i1 %54, label %55, label %56

55:                                               ; preds = %53
  tail call void @ext(i32 noundef 25)
  br label %56

56:                                               ; preds = %55, %53
  %57 = icmp sgt i32 %0, 26
  br i1 %57, label %58, label %59

58:                                               ; preds = %56
  tail call void @ext(i32 noundef 26)
  br label %59

59:                                               ; preds = %58, %56
  %60 = icmp sgt i32 %0, 27
  br i1 %60, label %61, label %62

61:                                               ; preds = %59
  tail call void @ext(i32 noundef 27)
  br label %62

62:                                               ; preds = %61, %59
  %63 = icmp sgt i32 %0, 28
  br i1 %63, label %64, label %65

64:                                               ; preds = %62
  tail call void @ext(i32 noundef 28)
  br label %65

65:                                               ; preds = %64, %62
  %66 = icmp sgt i32 %0, 29
  br i1 %66, label %67, label %68

67:                                               ; preds = %65
  tail call void @ext(i32 noundef 29)
  br label %68

68:                                               ; preds = %67, %65
  %69 = icmp sgt i32 %0, 30
  br i1 %69, label %70, label %71

70:                                               ; preds = %68
  tail call void @ext(i32 noundef 30)
  br label %71

71:                                               ; preds = %70, %68
  %72 = icmp sgt i32 %0, 31
  br i1 %72, label %73, label %74

73:                                               ; preds = %71
  tail call void @ext(i32 noundef 31)
  br label %74

74:                                               ; preds = %73, %71
  %75 = icmp sgt i32 %0, 32
  br i1 %75, label %76, label %77

76:                                               ; preds = %74
  tail call void @ext(i32 noundef 32)
  br label %77

77:                                               ; preds = %76, %74
  %78 = icmp sgt i32 %0, 33
  br i1 %78, label %79, label %80

79:                                               ; preds = %77
  tail call void @ext(i32 noundef 33)
  br label %80

80:                                               ; preds = %79, %77
  %81 = icmp sgt i32 %0, 34
  br i1 %81, label %82, label %83

82:                                               ; preds = %80
  tail call void @ext(i32 noundef 34)
  br label %83

83:                                               ; preds = %82, %80
  %84 = icmp sgt i32 %0, 35
  br i1 %84, label %85, label %86

85:                                               ; preds = %83
  tail call void @ext(i32 noundef 35)
  br label %86

86:                                               ; preds = %85, %83
  %87 = icmp sgt i32 %0, 36
  br i1 %87, label %88, label %89

88:                                               ; preds = %86
  tail call void @ext(i32 noundef 36)
  br label %89

89:                                               ; preds = %88, %86
  %90 = icmp sgt i32 %0, 37
  br i1 %90, label %91, label %92

91:                                               ; preds = %89
  tail call void @ext(i32 noundef 37)
  br label %92

92:                                               ; preds = %91, %89
  %93 = icmp sgt i32 %0, 38
  br i1 %93, label %94, label %95

94:                                               ; preds = %92
  tail call void @ext(i32 noundef 38)
  br label %95

95:                                               ; preds = %94, %92
  %96 = icmp sgt i32 %0, 39
  br i1 %96, label %97, label %98

97:                                               ; preds = %95
  tail call void @ext(i32 noundef 39)
  br label %98

98:                                               ; preds = %97, %95
  %99 = icmp sgt i32 %0, 40
  br i1 %99, label %100, label %101

100:                                              ; preds = %98
  tail call void @ext(i32 noundef 40)
  br label %101

101:                                              ; preds = %100, %98
  %102 = icmp sgt i32 %0, 41
  br i1 %102, label %103, label %104

103:                                              ; preds = %101
  tail call void @ext(i32 noundef 41)
  br label %104

104:                                              ; preds = %103, %101
  %105 = icmp sgt i32 %0, 42
  br i1 %105, label %106, label %107

106:                                              ; preds = %104
  tail call void @ext(i32 noundef 42)
  br label %107

107:                                              ; preds = %106, %104
  %108 = icmp sgt i32 %0, 43
  br i1 %108, label %109, label %110

109:                                              ; preds = %107
  tail call void @ext(i32 noundef 43)
  br label %110

110:                                              ; preds = %109, %107
  %111 = icmp sgt i32 %0, 44
  br i1 %111, label %112, label %113

112:                                              ; preds = %110
  tail call void @ext(i32 noundef 44)
  br label %113

113:                                              ; preds = %112, %110
  %114 = icmp sgt i32 %0, 45
  br i1 %114, label %115, label %116

115:                                              ; preds = %113
  tail call void @ext(i32 noundef 45)
  br label %116

116:                                              ; preds = %115, %113
  %117 = icmp sgt i32 %0, 46
  br i1 %117, label %118, label %119

118:                                              ; preds = %116
  tail call void @ext(i32 noundef 46)
  br label %119

119:                                              ; preds = %118, %116
  %120 = icmp sgt i32 %0, 47
  br i1 %120, label %121, label %122

121:                                              ; preds = %119
  tail call void @ext(i32 noundef 47)
  br label %122

122:                                              ; preds = %121, %119
  %123 = icmp sgt i32 %0, 48
  br i1 %123, label %124, label %125

124:                                              ; preds = %122
  tail call void @ext(i32 noundef 48)
  br label %125

125:                                              ; preds = %124, %122
  %126 = icmp sgt i32 %0, 49
  br i1 %126, label %127, label %128

127:                                              ; preds = %125
  tail call void @ext(i32 noundef 49)
  br label %128

128:                                              ; preds = %127, %125
  %129 = icmp sgt i32 %0, 50
  br i1 %129, label %130, label %131

130:                                              ; preds = %128
  tail call void @ext(i32 noundef 50)
  br label %131

131:                                              ; preds = %130, %128
  %132 = add nsw i32 %11, %9
  ret i32 %132
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { nofree noinline norecurse nounwind memory(readwrite, argmem: none) }
attributes #1 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
