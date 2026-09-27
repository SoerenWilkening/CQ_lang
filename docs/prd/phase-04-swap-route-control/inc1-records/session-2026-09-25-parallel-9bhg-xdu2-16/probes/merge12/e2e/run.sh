#!/bin/bash
# A C spelling for e2e-spec-classical-return that still reaches bd 9bhg's path after
# bd vsfp: a musttail call keeps the callee's parameter (r5/r6_vsfp's mt2/mm1 shape).
cd "$(dirname "$0")"
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
cat > e.lib.c <<'EOF'
static volatile int K = 7;
int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }
EOF
cat > e.c <<'EOF'
int h2(int a, int k);
__attribute__((noinline)) int f(int m, int k) {
    int q = cq_theta(m, .5);
    int z = cq_measure(q);
    __attribute__((musttail)) return h2(q, k + z);
}
int main(void) {
    int q2 = cq_theta(5, .25);
    int s = q2 + f(3, 3);
    (void) cq_measure(s);
    return 0;
}
EOF
cat > eT.c <<'EOF'
__attribute__((noinline)) int f(int m, int k) {
    int q = cq_theta(m, .5);
    int z = cq_measure(q);
    return k + z + 1;
}
int main(void) {
    int q2 = cq_theta(5, .25);
    int s = q2 + f(3, 3);
    (void) cq_measure(s);
    return 0;
}
EOF
"$L/clang" -O1 -emit-llvm -S -Wno-everything e.lib.c -o e.lib.ll
"$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything e.c -o e.caller.ll
"$L/llvm-link" -S e.caller.ll e.lib.ll -o e.s1.ll
"$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything eT.c -o eT.s1.ll
for m in e eT; do
  for t in m12 main_c113 new3; do
    CQ_DEADARG_DBG=1 "$S/frozen/cq-opt.$t" -passes=cq-lowering -S "$m.s1.ll" -o "$m.$t.s2.ll" 2> "$m.$t.err"
    echo "$m $t rc=$? drops=$(grep -c CQ_DEADARG "$m.$t.err") warn=$(grep -c 'warning:' "$m.$t.err") $(grep -o 'error: .*' "$m.$t.err" | head -1 | cut -c1-100)"
  done
  "$L/clang" -Wno-everything "$m.m12.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$m.exe" 2>/dev/null
  "./$m.exe" > "$m.trace"; echo "exit=$?" >> "$m.trace"
  printf '2b %s: ' "$m"; python3 "$W/tools/free_pairing_check.py" "$m.m12.s2.ll" | tail -1 | sed 's/.*file(s), //'
done
cmp -s e.trace eT.trace && echo "e vs eT: TRACE-IDENT" || diff e.trace eT.trace
cat e.trace
grep -n "__cq_q_h2\|define i32 @f" e.m12.s2.ll | head
