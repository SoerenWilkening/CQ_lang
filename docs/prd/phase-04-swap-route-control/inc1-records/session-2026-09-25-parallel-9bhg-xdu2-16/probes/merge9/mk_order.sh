#!/bin/bash
# Slot-order probes: a lift over a spec-CLASSICAL base (d88e fires) in a function
# whose RETURN is a spec-QUANTUM result (the late 3jru ask would fire), and twins.
set -e
cd "$(dirname "$0")/p"
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cat > ordM.lib.c <<'EOF'
int hc(int a, int k) { return k + 1; }
int hq(int a, int k) { return a + k; }
EOF
cat > ordM.c <<'EOF'
#include <stdlib.h>
int hc(int a, int k); int hq(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = hc(q, m); int t2 = hq(q, m + 2); int r = t; if (m > 3) r = cq_theta(t, .2); return t2 + cq_measure(r); }
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
EOF
# twin: hc inlined as its classical value; hq kept (still a spec site in the twin)
cat > ordMT.lib.c <<'EOF'
int hq(int a, int k) { return a + k; }
EOF
cat > ordMT.c <<'EOF'
#include <stdlib.h>
int hq(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int t2 = hq(q, m + 2); int r = t; if (m > 3) r = cq_theta(t, .2); return t2 + cq_measure(r); }
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
EOF
# control: the same without the lift (so only the late 3jru ask can fire)
cp -f ordM.lib.c ordN.lib.c
cat > ordN.c <<'EOF'
#include <stdlib.h>
int hc(int a, int k); int hq(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = hc(q, m); int t2 = hq(q, m + 2); return t2 + t; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
EOF
for b in ordM ordMT ordN; do
  "$L/clang" -O1 -emit-llvm -S "$b.lib.c" -o "$b.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$b.c" -o "$b.caller.ll"
  "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll"
done
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen
set +e
for b in ordM ordMT ordN; do
  for t in main983 new3 main_ba80 merged; do
    "$S/cq-opt.$t" -passes=cq-lowering -S "$b.s1.ll" -o /dev/null 2> "$b.$t.ord.err"
    printf '%-6s %-10s rc=%s %s\n' "$b" "$t" "$?" "$(grep -o 'in function.*' "$b.$t.ord.err" | head -1)"
  done
done
cmp ordM.merged.ord.err ordMT.merged.ord.err && echo "ordM vs twin on merged: stderr BYTE-IDENTICAL"
