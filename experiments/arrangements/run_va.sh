#!/bin/zsh
# The variadic root: a rail fixed actual (va_prog, 10_t + block) and a rail only among the variadic actuals (va_prog2,
# all-ones 110_t + block).
T=${0:A:h}
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
cd $T
export LIB=va_lib ROOTS='vsum\n'
for P in va_prog va_prog2; do
  /usr/local/opt/llvm@19/bin/clang -O1 -DNATIVE $P.c va_lib.c -o native_$P
  echo "== $P native $(./native_$P)"
  PROG=$P zsh build.sh new $W/build replay
  awk '/^define .*@main\(/,/^}/' out/$P-new-replay/prog.ll | grep -o "call [^@]*@[a-z_0-9]*vsum[a-z_0-9]*(" | sort | uniq -c
done
nm out/va_prog2-new-replay/libq.a | grep " T "
