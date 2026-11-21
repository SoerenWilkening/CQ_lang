#!/bin/zsh
# The string root group of the lowered libc (experiments/build_lib.sh's recipe), built with build-m7 and build: the
# IR compared; then programs linking the archive and the platform libc: a plain strlen is the native one (slen_c),
# a quantum one the lowered clone (slen_q). Outputs in out/libc/.
set -u
T=${0:A:h}
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
E=/Users/sorenwilkening/Desktop/Projects/CQ_lang/experiments
NM=/usr/local/opt/llvm@19/bin/llvm-nm
O=$T/out/libc; mkdir -p $O
export CQ_BUNDLE_MANIFEST=$E/lib/bundle/manifest.json
R=$W/bundle/roots/string.roots
for b in build-m7 build; do
  CQ_BUILD_DIR=$W/$b $W/driver/cqcc --cq-lib --cq-roots $R -S -o $O/string.$b.ll 2> $O/string.$b.err
  CQ_BUILD_DIR=$W/$b $W/driver/cqcc --cq-lib --cq-roots $R -o $O/libq_string.$b.a 2>> $O/string.$b.err
done
cmp -s $O/string.build-m7.ll $O/string.build.ll && echo "string group IR: identical (build-m7, build)" || echo "string group IR: DIFFERS"
echo "defined, not __cq_q_: [$($NM --defined-only --extern-only --format=just-symbols $O/libq_string.build.a | grep -v ':$' | grep -v '^___cq_q_' | tr '\n' ' ')]"
echo "undefined C names (the rows' keys, the platform libc's): $($NM -u --format=just-symbols $O/libq_string.build.a | grep -v '^_cq\|^___cq\|:$' | sort -u | tr '\n' ' ')"
cat > $O/slen_c.c <<'EOF'
/* Quantum data, but no QUANTUM cell and strlen's actuals classical: the C call, the platform's strlen. */
#include <string.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
char S[16] = "hello, world";
int main(int argc, char **argv) {
  (void)argv;
  long k = 7;
  cq_theta(&k, 0.0);
  size_t a = strlen(S + (argc > 99));
  return (int)(cq_measure(k) * 16 + (long)a);
}
EOF
cat > $O/slen_q.c <<'EOF'
/* strlen of an address rail: the lowered clone __cq_q_strlen_1_t from the archive. S + 7 is "hij": within K = 4 trips. */
#include <string.h>
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
char S[16] = "abcdefghij";
int main(int argc, char **argv) {
  (void)argc; (void)argv;
  long k = 7;
  cq_theta(&k, 0.0);
  return (int)cq_measure((long)strlen(S + (k & 7)));
}
EOF
# Pre-existing (build-m7 alike): the string group keys a row by the platform's wcswcs, which macOS's libc lacks.
printf '#include <wchar.h>\nwchar_t *wcswcs(const wchar_t *h, const wchar_t *n) { return wcsstr(h, n); }\n' > $O/wcswcs.c
/usr/local/opt/llvm@19/bin/clang -O1 -c $O/wcswcs.c -o $O/wcswcs.o
for p in slen_c slen_q; do
  /usr/local/opt/llvm@19/bin/clang -O1 -DNATIVE $O/$p.c -o $O/native_$p; $O/native_$p; echo "== $p native: exit $?"
  CQ_BUILD_DIR=$W/build $W/driver/cqcc $O/$p.c --cq-roots $R -S -o $O/$p.ll 2> $O/$p.err
  echo "   calls of strlen in main: $(awk '/^define .*@main\(/,/^}/' $O/$p.ll | grep -o "call [^@]*@[a-z_0-9]*strlen[a-z_0-9]*(" | sort | uniq -c | tr '\n' ' ')"
  for b in build-m7 build; do
    CQ_BUILD_DIR=$W/build $W/driver/cqcc $O/$p.c --cq-roots $R --no-softfloat --backend $O/libq_string.$b.a --backend $O/wcswcs.o \
      --backend -L${T:h}/backend --backend -lcq_backend --backend -lcq_gates_replay --backend -Wl,-why_load -o $O/$p.$b 2>> $O/$p.err
    if [ -x $O/$p.$b ]; then $O/$p.$b; echo "   lowered, archive of $b: exit $?"
    else echo "   lowered, archive of $b: link failed: $(grep -A1 'Undefined\|duplicate' $O/$p.err | tail -2 | tr '\n' ' ')"; fi
  done
done
