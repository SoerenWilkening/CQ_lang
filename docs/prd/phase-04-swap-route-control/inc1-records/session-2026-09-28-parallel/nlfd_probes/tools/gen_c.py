#!/usr/bin/env python3
"""gen_c.py — the C-level probes of bd nlfd / bd ev3m (2-TU where the callee is a
library: <n>.c is the CQ TU, <n>.lib.c the classical TU, built by tools/build.sh with
the run_slice_multi.sh recipe). Twins are HAND-INLINED single TUs (<n>T.c). Every
probe reads its runtime value from argv (bd 46oo). Writes ../src/<n>*.c and
../src/pairs_c.txt."""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "src")

K19 = """#include <stdlib.h>
{decl}
int main(int c, char **v) {{
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5); int p = q * 3; int r = {call}; int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7);
  return cq_measure(q) + cq_measure(r);
}}
"""

W_RET = """#include <stdlib.h>
{decl}
__attribute__((noinline)) int f(int m, int k) {{
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  {ret}
}}
int main(int c, char **v) {{ int m = atoi(v[1]); return f(m, m); }}
"""

LIB_HDR = "static volatile int K = 7;\n"
H2_IGN = "__attribute__((noinline)) int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }\n"

P = {}
# mtl: musttail forward of a LIVE quantum argument (h2 reads it) — the clone's
# Bennett wrap copies out after the call; ORACLE aborts (verifier, exit 134).
P["mtl"] = (K19.format(decl="int h(int a, int k);", call="h(p, m)"),
            "__attribute__((noinline)) int h2(int a, int k) { return k + a; }\n"
            "int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }\n")
P["mtlN"] = (K19.format(decl="int h(int a, int k);", call="h(p, m)"),
             "__attribute__((noinline)) int h2(int a, int k) { return k + a; }\n"
             "int h(int a, int k) { return h2(a, k); }\n")
P["mtlT"] = (K19.format(decl="", call="m + p"), None)
# ev1: bd ev3m's own example — a forwarder h(a,k){musttail return h2(a,k);} with h2
# ignoring a, called from a quantum function that RETURNS the result (3jru shape).
P["ev1"] = (W_RET.format(decl="int h(int a, int k);", ret="return h(p, k);"),
            LIB_HDR + H2_IGN + "int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }\n")
P["ev1N"] = (W_RET.format(decl="int h(int a, int k);", ret="return h(p, k);"),
             LIB_HDR + H2_IGN + "int h(int a, int k) { return h2(a, k); }\n")
P["ev1T"] = (W_RET.format(decl="", ret="return k + 1;"), None)
# ev2: a nested musttail chain h -> h2 -> h3 (h3 ignores a), reached by a module-level
# musttail in the returning quantum function.
P["ev2"] = (W_RET.format(decl="int h(int a, int k);",
                         ret="__attribute__((musttail)) return h(p, k);"),
            LIB_HDR +
            "__attribute__((noinline)) int h3(int a, int k) { if (a > 3) (void)K; return k + 1; }\n"
            "__attribute__((noinline)) int h2(int a, int k) { __attribute__((musttail)) return h3(a, k); }\n"
            "int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }\n")
P["ev2T"] = (W_RET.format(decl="", ret="return k + 1;"), None)
# ev4: a musttail forward two levels below main: main -> g (plain) -> h (musttail) -> h2.
P["ev4"] = (K19.format(decl="int g(int a, int k);", call="g(p, m)"),
            LIB_HDR + H2_IGN +
            "__attribute__((noinline)) int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }\n"
            "int g(int a, int k) { return h(a, k) + 1; }\n")
P["ev4T"] = (K19.format(decl="", call="m + 2"), None)
# ev6: the forwarder computes on a before forwarding (the dropped operand is an
# INSTRUCTION of the forwarder, its cone deleted).
P["ev6"] = (W_RET.format(decl="int h(int a, int k);", ret="return h(p, k);"),
            LIB_HDR + H2_IGN +
            "int h(int a, int k) { int t = a * 5; __attribute__((musttail)) return h2(t, k); }\n")
P["ev6T"] = (W_RET.format(decl="", ret="return k + 1;"), None)
# ev7: a musttail call with one DEAD and one LIVE quantum slot (partial drop): h2
# ignores a and reads b; r = m + q is quantum and measured.
P["ev7"] = (K19.replace("int r = {call};", "int r = h(p, q, m);").format(
                decl="int h(int a, int b, int k);", call=""),
            LIB_HDR +
            "__attribute__((noinline)) int h2(int a, int b, int k) { if (a > 3) (void)K; return k + b; }\n"
            "int h(int a, int b, int k) { __attribute__((musttail)) return h2(a, b, k); }\n")
P["ev7N"] = (K19.replace("int r = {call};", "int r = h(p, q, m);").format(
                 decl="int h(int a, int b, int k);", call=""),
             LIB_HDR +
             "__attribute__((noinline)) int h2(int a, int b, int k) { if (a > 3) (void)K; return k + b; }\n"
             "int h(int a, int b, int k) { return h2(a, b, k); }\n")
P["ev7T"] = (K19.format(decl="", call="m + q"), None)
# ev8: the module-level musttail of a LIVE quantum argument (w returns k + p: a quantum
# value returned — the twin declines at 3jru too).
P["ev8"] = (W_RET.format(decl="int h2(int a, int k);",
                         ret="__attribute__((musttail)) return h2(p, k);"),
            "__attribute__((noinline)) int h2(int a, int k) { return k + a; }\n")
P["ev8T"] = (W_RET.format(decl="", ret="return k + p;"), None)

# ev9: bd rhk5's shape reached THROUGH ev3m — a clone call `g(q, k)` between the
# derived chain `p = q*3` and its phase consumer, in a function that musttail-
# returns `h2(p, ...)` with `h2` ignoring `p`. ORACLE: 3jru decline (the musttail
# read of `p`). ev9N (plain `tail`) compiles on the ORACLE into rhk5's warned
# stream; ev9T is the hand-inlined twin.
RHK = """#include <stdlib.h>
int g(int a, int k); int h2(int a, int k);
__attribute__((noinline)) int f(int m, int k) {{
  int q = cq_theta(m & 7, .5); int p = q * 3; int t = g(q, k); int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); int z = cq_measure(q) + cq_measure(t);
  {ret}
}}
int main(int c, char **v) {{ int m = atoi(v[1]); return f(m, m); }}
"""
RHK_LIB = (LIB_HDR + "__attribute__((noinline)) int g(int a, int k) { return a + k; }\n" + H2_IGN)
P["ev9"] = (RHK.format(ret="__attribute__((musttail)) return h2(p, z);"), RHK_LIB)
P["ev9N"] = (RHK.format(ret="return h2(p, z);"), RHK_LIB)
P["ev9T"] = ("""#include <stdlib.h>
__attribute__((noinline)) int f(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int t = q + k; int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); int z = cq_measure(q) + cq_measure(t);
  return z + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
""", None)

for n, (c, lib) in P.items():
    open(os.path.join(SRC, n + ".c"), "w").write(c)
    lp = os.path.join(SRC, n + ".lib.c")
    if lib is not None:
        open(lp, "w").write(lib)
    elif os.path.exists(lp):
        os.remove(lp)

pairs = """mtl mtlT
mtl mtlN
mtlN mtlT
ev1 ev1T
ev1N ev1T
ev2 ev2T
ev4 ev4T
ev6 ev6T
ev7 ev7T
ev7 ev7N
ev8 ev8T
ev9 ev9T
ev9 ev9N
ev9N ev9T
ev7N ev7T
mt3 mt3T
mt3N mt3T
mt2N mt2T
"""
open(os.path.join(SRC, "pairs_c.txt"), "w").write(pairs)
print(len(P), "probes")
