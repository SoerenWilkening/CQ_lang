#!/bin/zsh
# A library function called through a function pointer the program took (native address) with a quantum actual.
T=${0:A:h}
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
cd $T
export LIB=qlib ROOTS='evaluate\nsum\n' PROG=fptr
/usr/local/opt/llvm@19/bin/clang -O1 -DNATIVE fptr.c qlib.c -o native_fptr
echo "== fptr native $(./native_fptr)"
zsh build.sh new $W/build replay
echo "   indirect calls in main:"
awk '/^define .*@main\(/,/^}/' out/fptr-new-replay/prog.ll | grep -o "@__cq_clone_resolve\|call [^@]*@[a-z_0-9]*sum[a-z_0-9]*(\|call i64 %[0-9]*(" | sort | uniq -c
echo "   row key in the lowered library:"
grep -o 'call void @__cq_clone_register(ptr @[^,]*' out/fptr-new-replay/lib.ll
