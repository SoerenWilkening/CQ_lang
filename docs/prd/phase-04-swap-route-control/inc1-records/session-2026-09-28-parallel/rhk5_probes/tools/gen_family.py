#!/usr/bin/env python3
"""gen_family.py — the bd rhk5 derived probe family (subject + hand-inlined twin + lib).

Every subject is a 2-TU program (`NAME.c` + `NAME.lib.c`, llvm-linked exactly as
tests/e2e/run_slice_multi.sh does) and every twin (`NAMET.c`) is the same program with
the callee written inline — the definition of the correct circuit. Runtime inputs come
from `atoi(argv[1])` (bd 46oo: never a constant `main`).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'src')

L0 = "int h(int a, int k) { return k + 1; }"
PI = "3.14159"

# (name, lib, decls, subject body, twin body, note)
FAM = [
    ("f02", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, p); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = p + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "clone READS the chain rail p (an OWNED rail's consumer)"),
    ("f03", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, u); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = u + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "clone READS the chain's condition rail u"),
    ("f04", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); int t = h(m + 1, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s) + cq_measure(t); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; int t = q + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s) + cq_measure(t); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "two clone calls in the interval"),
    ("f05", "__attribute__((noinline)) int g(int k) { return k * 5; }\nint h(int a, int k) { return g(k) + 1; }",
     "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q * 5 + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "NESTED clone (inner clone call + its _unc twin in the reverse)"),
    ("f06", "int h(int a, int k) { return k; }", "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "IDENTITY clone (returns its parameter: copy-out source)"),
    ("f07", "int h(int a, int k) { return k > 3 ? k : 0; }", "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q > 3 ? q : 0; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "clone with a SELECT (controlled copy of the parameter)"),
    ("f08", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; q = cq_theta(q, .3); int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; q = cq_theta(q, .3); int s = q + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "a NON-DIAGONAL gate on q between the chain and the call"),
    ("f09", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = m; if (u == 10) {{ cq_phi({PI}); s = h(m, q); }} int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = m; if (u == 10) {{ cq_phi({PI}); s = q + 1; }} int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "the call INSIDE the kickback arm"),
    ("f10", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int s = h(m, q); if (u > 12) cq_phi(0.25); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int s = q + 1; if (u > 12) cq_phi(0.25); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "chain consumed TWICE (two kickbacks), call between them"),
    ("f11", "int h(int a, short k) { return k + 1; }", "int h(int a, short k);",
     f"short q = cq_theta((short)(m & 7), .5); short p = q * 3; short u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"short q = cq_theta((short)(m & 7), .5); short p = q * 3; short u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "narrow PARAMETER width (short k, int return)"),
    ("f12", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int s = h(m, q); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int s = q + 1; int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "CONTROL: call BEFORE the chain (clean on the oracle)"),
    ("f13", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int s = h(m, q); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi({PI}); int s = q + 1; int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "CONTROL: call AFTER the kickback (d5, clean on the oracle)"),
    ("f14", L0, "int h(int a, int k);",
     f"int acc = 0; for (int i = 0; i < m; i++) {{ int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); acc += cq_measure(s); q = cq_theta(q, .7); acc += cq_measure(q); }} return acc;",
     f"int acc = 0; for (int i = 0; i < m; i++) {{ int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); acc += cq_measure(s); q = cq_theta(q, .7); acc += cq_measure(q); }} return acc;",
     "ROLLED loop (iteration-local)"),
    ("f15", "int h(int a, int k) { return a * k + 1; }", "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(p, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = p * q + 1; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "Q+Q clone reading the chain rail AND the parent"),
    ("f16", "static const int T[8] = {3, 1, 4, 1, 5, 9, 2, 6};\nint h(int a, int k) { return T[k & 7]; }",
     "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"static const int T[8] = {{3, 1, 4, 1, 5, 9, 2, 6}}; int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = T[q & 7]; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "clone with a QROM read indexed by the parameter"),
    ("f17", "int h(int a, int k) { return (k * 5 + 3) ^ 6; }", "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = (q * 5 + 3) ^ 6; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "MULTI-template clone body (no single-line contraction)"),
    ("f18", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); return cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); return cq_measure(q);",
     "the clone result is DEAD"),
    ("f19", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); int mq = cq_measure(q); return mq + cq_measure(s);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); int mq = cq_measure(q); return mq + cq_measure(s);",
     "the clone result is measured AFTER the Ry (d3's order)"),
    ("f20", "int h(int a, int k) { return k + 1; }", "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); q = q + 5; q = cq_theta(q, .7); return cq_measure(s) + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); q = q + 5; q = cq_theta(q, .7); return cq_measure(s) + cq_measure(q);",
     "an M-C `q += 5` after the kickback (the late in-place round's plan)"),
    ("f21", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) {{ int p = q * 3; int u = p ^ q; int s = h(m, q); if (u == 10) cq_phi({PI}); acc += cq_measure(s); }} q = cq_theta(q, .7); return acc + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) {{ int p = q * 3; int u = p ^ q; int s = q + 1; if (u == 10) cq_phi({PI}); acc += cq_measure(s); }} q = cq_theta(q, .7); return acc + cq_measure(q);",
     "ROLLED loop, register outside: chain + clone call + kickback per trip"),
    ("f22", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) {{ int p = q * 3; int u = p ^ q; int s = h(m, p); if (u == 10) cq_phi({PI}); acc += cq_measure(s); }} q = cq_theta(q, .7); return acc + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int acc = 0; for (int i = 0; i < m; i++) {{ int p = q * 3; int u = p ^ q; int s = p + 1; if (u == 10) cq_phi({PI}); acc += cq_measure(s); }} q = cq_theta(q, .7); return acc + cq_measure(q);",
     "ROLLED loop, the clone CONSUMES the per-trip chain rail"),
    ("f23", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int acc = 0; for (int i = 0; i < m; i++) {{ int s = h(m, p); acc += cq_measure(s); }} int u = p ^ q; if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); return acc + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int acc = 0; for (int i = 0; i < m; i++) {{ int s = p + 1; acc += cq_measure(s); }} int u = p ^ q; if (u == 10) cq_phi({PI}); q = cq_theta(q, .7); return acc + cq_measure(q);",
     "a clone consumer INSIDE a loop of a rail minted OUTSIDE it (multiplicity)"),
    # ── adversarial members ────────────────────────────────────────────────
    ("n01", "int h(int a, _Bool b, int k) { return b ? 0 : k; }", "int h(int a, _Bool b, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; _Bool cb = q > 5; int s = h(m, cb, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; _Bool cb = q > 5; int s = cb ? 0 : q; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "a clone whose select is keyed on a _Bool PARAMETER (a ¬flag bracket would WRITE it)"),
    ("n02", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; q = cq_theta(q, .3); int s = h(m, q); int w = u + 1; int ms = cq_measure(s) + cq_measure(w); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; q = cq_theta(q, .3); int s = q + 1; int w = u + 1; int ms = cq_measure(s) + cq_measure(w); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "a Ry on the borrowed parent AND a clone call in the discharge window (L4: the Ry must still refuse)"),
    ("n03", L0, "int h(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = h(m, q); int w = u + 1; int ms = cq_measure(s) + cq_measure(w); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = q + 1; int w = u + 1; int ms = cq_measure(s) + cq_measure(w); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "no control flow at all: the chain's consumer is a measured template (interior, not a kickback)"),
    ("n04", "int h(int a, int k) { return k + 1; }\nint g(int a, int k) { return h(a, k) * 2; }", "int g(int a, int k);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = g(m, q); if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     f"int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int s = (q + 1) * 2; if (u == 10) cq_phi({PI}); int ms = cq_measure(s); q = cq_theta(q, .7); return ms + cq_measure(q);",
     "a lib-internal call (inlined by -O1 in the lib TU)"),
]


def main():
    os.makedirs(SRC, exist_ok=True)
    for name, lib, decls, body, twin, note in FAM:
        with open(os.path.join(SRC, name + '.lib.c'), 'w') as f:
            f.write(f"/* {name} lib — {note} */\n{lib}\n")
        with open(os.path.join(SRC, name + '.c'), 'w') as f:
            f.write(f"/* {name} — {note} */\n#include <stdlib.h>\n{decls}\n"
                    f"int main(int c, char **v) {{ int m = atoi(v[1]); {body} }}\n")
        with open(os.path.join(SRC, name + 'T.c'), 'w') as f:
            f.write(f"/* {name}T — hand-inlined twin of {name} */\n#include <stdlib.h>\n"
                    f"int main(int c, char **v) {{ int m = atoi(v[1]); {twin} }}\n")
    print(' '.join(n for n, *_ in FAM))


if __name__ == '__main__':
    main()
