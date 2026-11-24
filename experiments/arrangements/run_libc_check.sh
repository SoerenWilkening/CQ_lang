#!/bin/zsh
# run_libc_check.sh <dir with libq_*.a> [<second dir> ...]: smoke test of a lowered libc. One small program per
# root group calls a library function on quantum data; its exit code on the replay backend, linked with each
# archive set, is compared with the native program's. Outputs in out/libcchk/.
set -u
T=${0:A:h}; W=${T:h:h}; E=${T:h}
C=/usr/local/opt/llvm@19/bin/clang
O=$T/out/libcchk; mkdir -p $O
H='#include <string.h>\n#include <stdlib.h>\n#include <stdio.h>\nint toupper(int); int isdigit(int);\n#include <math.h>\n#include <complex.h>\n#include <wchar.h>\n#include <time.h>\n#ifdef NATIVE\n#define cq_theta(p, a) ((void)0)\n#define cq_measure(x) (x)\n#endif\n'
prog() { printf "$H%s\n" "$2" > $O/$1.c; }
prog strlen  'char S[16] = "abcdefghij"; int main(void) { long k = 7; cq_theta(&k, 0.0); return (int)cq_measure((long)strlen(S + (k & 7))); }'
prog strchr  'char S[8] = "abcd"; int main(void) { long c = 99; cq_theta(&c, 0.0); return (int)cq_measure((long)(strchr(S, (int)c) - S)); }'
prog memcmp  'char A[4] = "abd", B[4] = "abc"; int main(void) { long k = 3; cq_theta(&k, 0.0); return (int)cq_measure((long)(memcmp(A, B, (size_t)k) > 0)) + 4; }'
# toupper on its own header: macOS's <wchar.h> pulls in its <ctype.h>, which turns toupper into the host's __toupper.
printf '#ifdef NATIVE\n#define cq_theta(p, a) ((void)0)\n#define cq_measure(x) (x)\n#endif\nint toupper(int);\nint main(void) { long c = 113; cq_theta(&c, 0.0); return (int)cq_measure((long)toupper((int)c)); }\n' > $O/toupper.c
prog atoi    'char S[8] = "x2"; int main(void) { long c = 52; cq_theta(&c, 0.0); S[0] = (char)c; return (int)cq_measure((long)atoi(S)); }'
prog labs    'int main(void) { long v = -77; cq_theta(&v, 0.0); ldiv_t d = ldiv(labs(v), 5); return (int)cq_measure(d.quot * 4 + d.rem); }'
prog ldexp   'int main(void) { double x = 1.5; cq_theta(&x, 0.0); int e; double m = frexp(ldexp(x, 3), &e); return (int)cq_measure((long)(m * 64.0) + e); }'
prog cbrt    'int main(void) { double x = 27.0; cq_theta(&x, 0.0); return (int)cq_measure((long)(cbrt(x) * 10.0 + 0.5)); }'
prog cabs    'int main(void) { double x = 3.0; cq_theta(&x, 0.0); double complex z = x + 4.0 * I; return (int)cq_measure((long)(cabs(z) * 7.0 + 0.5)); }'
prog wctomb  'int main(void) { long c = 65; cq_theta(&c, 0.0); char b[8] = {0}; int n = wctomb(b, (wchar_t)c); return (int)cq_measure((long)(n * 100 + b[0])); }'
prog snprintf 'int main(void) { long v = 57; cq_theta(&v, 0.0); char b[8] = {0}; int n = snprintf(b, 8, "%ld", v); return (int)cq_measure((long)(n * 100 + b[1])); }'
prog gmtime  'int main(void) { time_t t = 86400L * 465; cq_theta(&t, 0.0); struct tm *r = gmtime(&t); return (int)cq_measure((long)(r->tm_year + r->tm_mon)); }'
printf '#include <wchar.h>\nwchar_t *wcswcs(const wchar_t *h, const wchar_t *n) { return wcsstr(h, n); }\n' > $O/wcswcs.c
$C -O1 -c $O/wcswcs.c -o $O/wcswcs.o
i=0; for d in "$@"; do i=$((i+1)); libtool -static -o $O/libqc.$i.a $d/libq_*.a 2>/dev/null; done
fail=0
for p in strlen strchr memcmp toupper atoi labs ldexp cbrt cabs wctomb snprintf gmtime; do
  $C -O1 -w -DNATIVE $O/$p.c -o $O/native_$p -lm; $O/native_$p; n=$?
  line="$p native=$n"
  i=0; for d in "$@"; do i=$((i+1))
    rm -f $O/$p.$i
    $W/driver/cqcc $O/$p.c --cq-roots $E/lib/libc.roots --backend $O/libqc.$i.a --backend $O/wcswcs.o \
      --backend -L$E/lib/backend-replay --backend -lcq_backend --backend -lcq_gates_replay --backend -Wl,-undefined,dynamic_lookup -o $O/$p.$i > $O/$p.$i.err 2>&1
    if [ -x $O/$p.$i ]; then perl -e 'alarm 300; exec @ARGV' $O/$p.$i > $O/$p.$i.out 2>&1; r=$?; else r="nolink"; fi
    line="$line lib$i=$r"; [ "$r" = "$n" ] || fail=$((fail+1))
  done
  echo $line
done
echo "mismatches: $fail"
