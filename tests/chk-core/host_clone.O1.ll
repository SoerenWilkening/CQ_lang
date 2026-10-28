; the C-level declarations of host_clone.ll's callees: exp and pow as clang -O1 writes them (intrinsics)
target triple = "x86_64-apple-macosx16.0.0"
declare double @llvm.exp.f64(double)
declare double @llvm.pow.f64(double, double)
declare double @atan2(double noundef, double noundef) local_unnamed_addr
