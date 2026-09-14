; ModuleID = 'r20_acyclic_nondominated_phi.ll'
source_filename = "r20_acyclic_nondominated_phi.ll"

define i32 @example() {
entry:
  br label %Y

Y:                                                ; preds = %entry
  br label %J

J:                                                ; preds = %Y
  %s = add nsw i32 0, 0
  ret i32 %s
}
