; ModuleID = 'a'@x = global i32 0
define i32 @main() {
  %v = load i32, ptr @x
  ret i32 %v
}
