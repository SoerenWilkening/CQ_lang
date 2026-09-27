define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
entry:
  %argv1 = getelementptr inbounds i8, ptr %1, i64 8
  %s = load ptr, ptr %argv1, align 8, !tbaa !6
  %m = tail call i32 @atoi(ptr nocapture noundef %s)
  %q = tail call i32 @cq_theta_si32(i32 noundef %m, double noundef 5.000000e-01) #4
  br label %def

use:                                              ; preds = %def
  %u = tail call i32 @g(i32 noundef %t) #4
  %r = tail call i32 @cq_measure_si32(i32 noundef %u) #4
  ret i32 %r

def:                                              ; preds = %entry
  %t = tail call i32 @h(i32 noundef %q, i32 noundef %m) #4
  br label %use
}
