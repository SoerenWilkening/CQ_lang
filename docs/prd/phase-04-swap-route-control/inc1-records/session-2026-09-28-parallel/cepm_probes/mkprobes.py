#!/usr/bin/env python3
"""mkprobes.py — write the cepm/3zr4 probe sources into src/ and print the member list.

Each member is a pair <b>C (the subject: calls a library function in ANOTHER TU) and
<b>T (its hand-inlined twin). `<name>C.libs` / `<name>T.libs` list the library SETS the
member links; gen.sh compiles every src/<set>.lib*.c as its OWN TU and llvm-links them.

THE READING CALLEE. bd cepm's residual after bd vsfp is "a callee that READS its
quantum argument yet returns a classical value". Every earlier spelling (h(a,k)=k+1)
IGNORES the argument, and vsfp's dead-argument drop makes those classical from the
start. A pure callee can keep a parameter LIVE only through a liveness ROOT
(DeadValueLiveness.h): a terminator (a branch — which clang -O1 deletes when both
arms are empty) or a call whose purity the pass cannot prove. The latter is reachable
from C with a callee in ANOTHER TU whose own callee is in yet ANOTHER TU (so -O1
infers no memory(none)/willreturn for it, and its body contains a call, so the body
rule does not clear it either). Two families:

  "v" (primary, exact twins) — h(a,k){ g(a); return k+1; } with g VOID:
       g(a){ f2(a); }, f2(a){ return f3(a)+1; }, f3(a){ return a*3; }   (4 TUs)
       g's clone is self-contained (Bennett forward + reverse, no result), so the
       hand-inlined twin `g(q); t = m + 1;` emits the SAME gates.
  "i" (secondary) — h(a,k){ g(a); return k+1; } with g returning int:
       g(a){ return f2(a)+1; }, f2(a){ return a*3; }                    (3 TUs)
       The hand-inlined twin's top-level `g(q)` has an UNUSED quantum result that the
       spine leaves allocated (the ruled `live derived record` warning class), while
       h's clone discharges g's rail in its own Bennett wrap. So C and T differ by
       exactly g's reverse block: a known twin-side leak, not a defect of C.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
os.makedirs(SRC, exist_ok=True)

LIBS = {
    # family "v"
    "vh": "/* h READS a (a call to g, an external here) and returns the CLASSICAL k + 1. */\n"
          "void g(int a);\nint h(int a, int k) { g(a); return k + 1; }\n",
    "vg": "/* f2 is an external here: -O1 keeps the unused call and infers nothing. */\n"
          "int f2(int a);\nvoid g(int a) { f2(a); }\n",
    "vf2": "/* f3 is an external here: f2 gets no memory(none)/willreturn, so a call to f2\n"
           "   is a liveness ROOT of the pass. */\nint f3(int a);\nint f2(int a) { return f3(a) + 1; }\n",
    "vf3": "int f3(int a) { return a * 3; }\n",
    # family "i"
    "ih": "int g(int a);\nint h(int a, int k) { g(a); return k + 1; }\n",
    "ig": "int f2(int a);\nint g(int a) { return f2(a) + 1; }\n",
    "if2": "int f2(int a) { return a * 3; }\n",
    # other callees
    "ign": "int h(int a, int k) { return k + 1; }\n",                                 # IGNORES a
    "vl": "int h(int a, int k) { volatile int z = a; return k + 1; }\n",            # local volatile
    "vgl": "static volatile int z;\nint h(int a, int k) { z = a; return k + 1; }\n",  # global volatile
    "qh": "void g(int a);\nint h(int a, int k) { g(a); return a + k; }\n",          # quantum return
    "ph": "void g(int a);\nint h(int a, int k) { g(a); return k > 3 ? a : k; }\n",  # quantum on some paths
    "mem": "int G;\nint h(int a, int k) { G = a; return k + 1; }\n",                  # escapes through memory
    "x3": "int ext_f(int a) { return a * 7 + 2; }\nint g2(int a, int b) { return a * b + 1; }\n",
    "rh2": "int h(int a, int k);\nint h2(int a, int k) { int u = h(a, k); return u * 2; }\n",
    "g3": "int g3(int x) { return x * 2 + 1; }\n",
    "g4": "int g4(int a, int b) { return a * b + 1; }\n",
    "rec": "int h(int a, int k) { if (k <= 0) return 1; return h(a, k - 1) + 1; }\n",  # recursion
}

FAM = {
    "v": dict(C=["vh", "vg", "vf2", "vf3"], T=["vg", "vf2", "vf3"], G="void g(int a);\n"),
    "i": dict(C=["ih", "ig", "if2"], T=["ig", "if2"], G="int g(int a);\n"),
}
HDR = "#include <stdlib.h>\n"
M = "int m = atoi(v[1]); int n = atoi(v[2]); "
H = "int h(int a, int k);\n"
MEMBERS = []


def mem(name, cdecl, cmain, tdecl, tmain, clibs, tlibs):
    MEMBERS.append((name, cdecl, cmain, tdecl, tmain, clibs, tlibs))


def reading(name, cmain, tmain, cextra="", textra="", xlibs=(), families=("v", "i")):
    """A member whose C calls h(q, ·) (a READING callee returning classical) and whose
    T is h hand-inlined: `g(q); t = <k> + 1;`. Emitted once per family, the "i"
    family with an `i` suffix."""
    for fam in families:
        f = FAM[fam]
        mem(name + ("" if fam == "v" else "i"), H + cextra, cmain, f["G"] + textra, tmain,
            f["C"] + list(xlibs), f["T"] + list(xlibs))


# ---- cepm: a same-function consumer of t = h(q, m) -------------------------------
reading("br", "int q = cq_theta(m, .5); int t = h(q, m); if (t > 3) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; if (t > 3) q = cq_theta(q, .2); return cq_measure(q);")
reading("sel", "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);")
reading("ph1", "int q = cq_theta(m, .5); int t = h(q, m); if (t > n) cq_phi(0.3); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; if (t > n) cq_phi(0.3); return cq_measure(q);")
reading("ar", "int q = cq_theta(m, .5); int t = h(q, m); int u = t * 3 + n; return cq_measure(q) + u;",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int u = t * 3 + n; return cq_measure(q) + u;")
reading("l19", "int q = cq_theta(m, .5); int t = h(q, m); int r = cq_theta(t, .1); int r2 = r; if (m > 3) r2 = cq_theta(r, .2); return cq_measure(r2) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int r = cq_theta(t, .1); int r2 = r; if (m > 3) r2 = cq_theta(r, .2); return cq_measure(r2) + cq_measure(q);")
reading("a04", "int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 8; i++) { if (h(q, i + m) > 5) break; acc += i; } return acc + cq_measure(q);",
        "int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 8; i++) { g(q); if (i + m + 1 > 5) break; acc += i; } return acc + cq_measure(q);")
reading("a03", "int q = cq_theta(m, .5); int b[4]; for (int i = 0; i < 4; i++) b[i] = h(q, i); int s = 0; for (int i = 0; i < 4; i++) s += cq_measure(b[i]); return s + cq_measure(q);",
        "int q = cq_theta(m, .5); int b[4]; for (int i = 0; i < 4; i++) { g(q); b[i] = i + 1; } int s = 0; for (int i = 0; i < 4; i++) s += cq_measure(b[i]); return s + cq_measure(q);")
reading("l04", "return f(m);", "return f(m);",
        cextra="__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); int s = cq_measure(r); return t + s + cq_measure(q); }\n",
        textra="__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); g(q); int t = m + 1; int r = t; if (m > 3) r = cq_theta(t, .2); int s = cq_measure(r); return t + s + cq_measure(q); }\n")
reading("rt9", "int x = f(m); int q2 = cq_theta(n, .4); if (x > 5) q2 = cq_theta(q2, .3); return cq_measure(q2);",
        "int x = f(m); int q2 = cq_theta(n, .4); if (x > 5) q2 = cq_theta(q2, .3); return cq_measure(q2);",
        cextra="__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t + cq_measure(q); }\n",
        textra="__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); g(q); int t = m + 1; return t + cq_measure(q); }\n")
reading("yc", "int q = cq_theta(m, .5); int t = h(q, m); if (g3(t) > 3) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; if (g3(t) > 3) q = cq_theta(q, .2); return cq_measure(q);",
        cextra="int g3(int x);\n", textra="int g3(int x);\n", xlibs=["g3"])
reading("yb", "int q = cq_theta(m, .5); int t = h(q, m); int u = g4(t, q); return cq_measure(u) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int u = g4(t, q); return cq_measure(u) + cq_measure(q);",
        cextra="int g4(int a, int b);\n", textra="int g4(int a, int b);\n", xlibs=["g4"])
# a trailing NON-DIAGONAL gate on q after the call (family "i": the twin's leak, warned)
reading("lk", "int q = cq_theta(m, .5); int t = h(q, m); q = cq_theta(q, .3); return cq_measure(q) + t;",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; q = cq_theta(q, .3); return cq_measure(q) + t;")
# the result under a QUANTUM condition (inside a value arm / a phase arm / a select)
reading("va", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = h(q, m); return cq_measure(y) + cq_measure(q);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) { g(q); y = m + 1; } return cq_measure(y) + cq_measure(q);")
reading("pa", "int q = cq_theta(m, .5); if (q > 5) { int t = h(q, m); if (t > n) cq_phi(0.4); } return cq_measure(q);",
        "int q = cq_theta(m, .5); if (q > 5) { g(q); int t = m + 1; if (t > n) cq_phi(0.4); } return cq_measure(q);")
# inner classical-returning clone: h2(a,k) = h(a,k)*2 — the prediction goes THROUGH h's
# result (conservative), so this stays an over-decline (l3oi) after the change.
reading("in2", "int q = cq_theta(m, .5); int t = h2(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = (m + 1) * 2; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
        cextra="int h2(int a, int k);\n", xlibs=["rh2"])

# the result as a rotation ANGLE (classical after the change; a tainted-angle decline before)
reading("ang", "int q = cq_theta(m, .5); int t = h(q, m); q = cq_theta(q, t * 0.1); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; q = cq_theta(q, t * 0.1); return cq_measure(q);", families=("v",))
# two sites, the second reading the first's (classical) result: a cache hit on one clone
reading("ch", "int q = cq_theta(m, .5); int t1 = h(q, m); int t2 = h(q, t1); if (t2 > n) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t1 = m + 1; g(q); int t2 = t1 + 1; if (t2 > n) q = cq_theta(q, .2); return cq_measure(q);", families=("v",))
# the result muxed by a CLASSICAL-condition phi
reading("cph", "int q = cq_theta(m, .5); int t = 0; if (n > 3) t = h(q, m); if (t > 4) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); int t = 0; if (n > 3) { g(q); t = m + 1; } if (t > 4) q = cq_theta(q, .2); return cq_measure(q);", families=("v",))
# the result UNUSED (the call kept only because h is a liveness root)
reading("un", "int q = cq_theta(m, .5); h(q, m); q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); q = cq_theta(q, .2); return cq_measure(q);", families=("v",))
# an fp CLASSICAL return (cloneFor keeps the fp signature: the same predictor decides it)
LIBS["vhf"] = "void g(int a);\ndouble hf(int a, double k) { g(a); return k * 2.0; }\n"
mem("fp", "double hf(int a, double k);\n",
    "int q = cq_theta(m, .5); double t = hf(q, (double)m); if (t > 7.0) q = cq_theta(q, .2); return cq_measure(q);",
    FAM["v"]["G"], "int q = cq_theta(m, .5); g(q); double t = (double)m * 2.0; if (t > 7.0) q = cq_theta(q, .2); return cq_measure(q);",
    ["vhf"] + FAM["v"]["T"], FAM["v"]["T"])
# L1: the mask GROWS in round 2 — h(q, y) with y a 6.5 merge %out. Round 1: mask 01,
# classical; round 2: mask 11, the return (k + 1 over y) is quantum. The twin's t = y + 1
# is tainted in round 2 as well.
X3b = "int ext_f(int a);\n"
reading("r2g", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int u = t * 2; return cq_measure(u) + cq_measure(q) + cq_measure(y);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int u = t * 2; return cq_measure(u) + cq_measure(q) + cq_measure(y);",
        cextra=X3b, textra=X3b, xlibs=["x3"], families=("v",))
reading("r2b", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q) + cq_measure(y);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q) + cq_measure(y);",
        cextra=X3b, textra=X3b, xlibs=["x3"], families=("v",))

# r2b + a trailing NON-DIAGONAL gate on the register the round-2 clone copied out of
reading("r2d", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); y = cq_theta(y, .3); return cq_measure(q2) + cq_measure(q) + cq_measure(y);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); y = cq_theta(y, .3); return cq_measure(q2) + cq_measure(q) + cq_measure(y);",
        cextra=X3b, textra=X3b, xlibs=["x3"], families=("v",))
# L1: the mask grows in round 2 and the result bounds a LOOP (lowerLoops runs in round 1)
reading("r2l", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int acc = 0; for (int i = 0; i < 8; i++) { if (t > i) break; acc += i; } return acc + cq_measure(q) + cq_measure(y);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int acc = 0; for (int i = 0; i < 8; i++) { if (t > i) break; acc += i; } return acc + cq_measure(q) + cq_measure(y);",
        cextra=X3b, textra=X3b, xlibs=["x3"], families=("v",))
# a CONSTANT-trip loop whose body holds the site (the unroll prepass's U7 asks instruction
# taint: the oracle unrolled on the tainted accumulator; now nothing in C's loop is tainted,
# while the twin's void `g(q)` call still is)
reading("lp", "int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 4; i++) acc += h(q, i + m); if (acc > n) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 4; i++) { g(q); acc += i + m + 1; } if (acc > n) q = cq_theta(q, .2); return cq_measure(q);", families=("v",))
# the site's quantum argument is a TEMPLATE rail (`p = q * 3`): the clone call is a consumer
# the uncompute spine must recognise before discharging `p`
reading("tp", "int q = cq_theta(m, .5); int p = q * 3; int t = h(p, m); if (t > 3) q = cq_theta(q, .2); return cq_measure(q);",
        "int q = cq_theta(m, .5); int p = q * 3; g(p); int t = m + 1; if (t > 3) q = cq_theta(q, .2); return cq_measure(q);", families=("v",))
# the result STORED under a QUANTUM condition (the guarded-store arm)
reading("gs", "int q = cq_theta(m, .5); if (q > 5) G = h(q, m); return cq_measure(q) + G;",
        "int q = cq_theta(m, .5); if (q > 5) { g(q); G = m + 1; } return cq_measure(q) + G;",
        cextra="int G;\n", textra="int G;\n", families=("v",))
# bd z0re's side-door programs (d88e l12/l17/a02/a01), respelled with the READING callee: on
# the oracle `t` is conservatively tainted and the arm is classified as an in-place Ry on the
# "register" `t` (the side door); with `t` classical they take the DIRECT path (a runtime-seed
# state prep / an untainted-base angle select), which bd z0re (a) is admitting in parallel.
reading("zl12", "int q = cq_theta(m, .5); int t = h(q, m); int q2 = cq_theta(n, .3); int r = t; if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q2);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int q2 = cq_theta(n, .3); int r = t; if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q2);", families=("v",))
reading("zl17", "int q = cq_theta(m, .5); int t = h(q, m); int r = t; _Bool b = cq_theta((_Bool)0, .3); if (b) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(b);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int r = t; _Bool b = cq_theta((_Bool)0, .3); if (b) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(b);", families=("v",))
reading("za02", "int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (q > 3) r = cq_theta(t, .7); return cq_measure(r) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int r = t; if (q > 3) r = cq_theta(t, .7); return cq_measure(r) + cq_measure(q);", families=("v",))
reading("za01", "int q = cq_theta(m, .5); int t = h(q, m); int r; if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int r; if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q);", families=("v",))
# ---- ROUND 2 (Rule-13 r1A F-r1A-1, r1B F-r1B-2): the reviewers' probes, respelled ----
# r6a: F's ret is a 6.5 %out (a 3jru crossing in round 2) — declineQuantumReturnCalls owns it.
# r6b: F holds a cq_theta but returns a MEASURED classical value — the callee seed over-declined it.
# (lib TUs include CQ.h explicitly; gen.sh passes -I include to every TU.)
LIBS["rfa"] = ('#include "CQ.h"\nint ext_f(int a);\n'
               "int F(int n) { int r = cq_theta(n, .3); int y = 0; if (r > 5) y = ext_f(7); return y; }\n")
LIBS["rfb"] = '#include "CQ.h"\nint F(int n) { int r = cq_theta(n, .3); return n + cq_measure(r); }\n'
for nm, lib in (("r6a", "rfa"), ("r6b", "rfb")):
    reading(nm, "int q = cq_theta(m, .5); int y = F(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
            "int q = cq_theta(m, .5); int y = F(n); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
            cextra="int F(int n);\n", textra="int F(int n);\n", xlibs=["x3", lib], families=("v",))
# lpp: a tainted branch in a loop body that does NOT select the header φ `i`; lpq: its loop-invariant control.
reading("lpp", "int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { int t = h(q, i + m); if (q > t) cq_phi(0.2); } return cq_measure(q);",
        "int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { g(q); int t = i + m + 1; if (q > t) cq_phi(0.2); } return cq_measure(q);", families=("v",))
reading("lpq", "int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { int t = h(q, m); if (q > t + i) cq_phi(0.2); } return cq_measure(q);",
        "int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { g(q); int t = m + 1; if (q > t + i) cq_phi(0.2); } return cq_measure(q);", families=("v",))

# ---- ROUND 3 (Rule-13 r2 F-r2-4): the INDIRECT-call half of the removed callee seed, and lpp with a
# runtime trip count. fp1: fp → {F (holds cq_theta, measured return), G}; fp3: fp → {G, G2}, both classical.
LIBS["fm"] = '#include "CQ.h"\nint F(int n) { int r = cq_theta(n, .3); return n + cq_measure(r); }\nint G(int n) { return n * 5 + 1; }\n'
LIBS["gg"] = "int G(int n) { return n * 5 + 1; }\nint G2(int n) { return n - 3; }\n"
reading("fp1", "int (*fp)(int) = (m > 4) ? F : G; int q = cq_theta(m, .5); int y = fp(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
        "int (*fp)(int) = (m > 4) ? F : G; int q = cq_theta(m, .5); int y = fp(n); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
        cextra="int F(int n); int G(int n);\n", textra="int F(int n); int G(int n);\n", xlibs=["fm"], families=("v",))
reading("fp3", "int (*fp)(int) = (m > 4) ? G : G2; int q = cq_theta(m, .5); int y = fp(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
        "int (*fp)(int) = (m > 4) ? G : G2; int q = cq_theta(m, .5); int y = fp(n); g(q); int t = y + 1; int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q);",
        cextra="int G(int n); int G2(int n);\n", textra="int G(int n); int G2(int n);\n", xlibs=["gg"], families=("v",))
reading("l3", "int q = cq_theta(m, .5); for (int i = 0; i < n; i++) { int t = h(q, i + m); if (q > t) cq_phi(0.2); } return cq_measure(q);",
        "int q = cq_theta(m, .5); for (int i = 0; i < n; i++) { g(q); int t = i + m + 1; if (q > t) cq_phi(0.2); } return cq_measure(q);", families=("v",))

# the result PRINTED (an IO sink with a classical argument)
reading("pr", "int q = cq_theta(m, .5); int t = h(q, m); printf(\"%d\\n\", t); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; printf(\"%d\\n\", t); return cq_measure(q);",
        cextra="#include <stdio.h>\n", textra="#include <stdio.h>\n", families=("v",))
# the same leak class with a ROUND-1 quantum-returning clone (h returns a + k), unaffected
# by the change: its behaviour is the oracle's
mem("nq2", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; q = cq_theta(q, .3); return cq_measure(r) + cq_measure(q);",
    V_G := FAM["v"]["G"], "int q = cq_theta(m, .5); g(q); int t = q + m; int r = m; if (t > 3) r = m + 5; q = cq_theta(q, .3); return cq_measure(r) + cq_measure(q);",
    ["qh"] + FAM["v"]["T"], FAM["v"]["T"])
# a predicted-classical site INSIDE a phase (kickback) arm, result unused
reading("pk", "int q = cq_theta(m, .5); if (q > 5) { h(q, m); cq_phi(0.4); } return cq_measure(q);",
        "int q = cq_theta(m, .5); if (q > 5) { g(q); cq_phi(0.4); } return cq_measure(q);", families=("v",))
# a predicted-classical site INSIDE a phase arm, result read by the arm's own angle
reading("pk2", "int q = cq_theta(m, .5); if (q > 5) { int t = h(q, m); cq_phi(t * 0.1); } return cq_measure(q);",
        "int q = cq_theta(m, .5); if (q > 5) { g(q); int t = m + 1; cq_phi(t * 0.1); } return cq_measure(q);", families=("v",))
# M-C: the classical result added to the register the clone READ (bd hgwx's j02 shape,
# with a callee that READS q so vsfp's drop does not apply)
reading("j2", "int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; u = cq_theta(u, .3); return cq_measure(u);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; int u = t + q; u = cq_theta(u, .3); return cq_measure(u);", families=("v",))
# the result as a SWITCH scrutinee and as a LOOP trip count
reading("sw", "int q = cq_theta(m, .5); int t = h(q, m); switch (t) { case 4: q = cq_theta(q, .2); break; case 6: q = cq_theta(q, .3); break; default: break; } return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; switch (t) { case 4: q = cq_theta(q, .2); break; case 6: q = cq_theta(q, .3); break; default: break; } return cq_measure(q);", families=("v",))
reading("ld", "int q = cq_theta(m, .5); int t = h(q, m); for (int i = 0; i < t; i++) q = cq_theta(q, .1); return cq_measure(q);",
        "int q = cq_theta(m, .5); g(q); int t = m + 1; for (int i = 0; i < t; i++) q = cq_theta(q, .1); return cq_measure(q);", families=("v",))

# ---- other spellings of "reads q, returns classical" (the brief's volatile idea) ----
mem("selvl", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    "", "int q = cq_theta(m, .5); int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["vl"], [])
mem("selvg", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    "static volatile int z;\n", "int q = cq_theta(m, .5); z = q; int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["vgl"], [])
mem("selig", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    "", "int q = cq_theta(m, .5); int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["ign"], [])

# ---- negatives: the result is genuinely quantum, on all or some paths, or via memory ----
V = FAM["v"]
mem("nq", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    V["G"], "int q = cq_theta(m, .5); g(q); int t = q + m; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["qh"] + V["T"], V["T"])
mem("np", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    V["G"], "int q = cq_theta(m, .5); g(q); int t = m > 3 ? q : m; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["ph"] + V["T"], V["T"])
mem("nm", H + "extern int G;\n", "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q) + cq_measure(G);",
    "int G;\n", "int q = cq_theta(m, .5); G = q; int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q) + cq_measure(G);",
    ["mem"], [])
mem("nr", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    "", "int q = cq_theta(m, .5); int t = m + 1; int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["rec"], [])
# recursion that the READ survives: h reads a (g root) and returns the classical k2(k),
# k2 recursive on k only — scanBody's cycle rule declines h whatever the prediction.
LIBS["rec2"] = ("void g(int a);\nint k2(int k) { if (k <= 1) return k; return k2(k - 1) + k2(k - 2); }\n"
                "int h(int a, int k) { g(a); return k2(k); }\n")
LIBS["rec2t"] = "int k2(int k) { if (k <= 1) return k; return k2(k - 1) + k2(k - 2); }\n"
# the TAIL-recursive spelling -O1 turns into a LOOP (no recursion left): a cepm member
LIBS["rec3"] = ("void g(int a);\nint k3(int k) { if (k <= 0) return 1; return k3(k - 1) + 2; }\n"
                "int h(int a, int k) { g(a); return k3(k); }\n")
LIBS["rec3t"] = "int k3(int k) { if (k <= 0) return 1; return k3(k - 1) + 2; }\n"
mem("nr2", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    FAM["v"]["G"] + "int k2(int k);\n", "int q = cq_theta(m, .5); g(q); int t = k2(m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["rec2"] + FAM["v"]["T"], ["rec2t"] + FAM["v"]["T"])
mem("tre", H, "int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    FAM["v"]["G"] + "int k3(int k);\n", "int q = cq_theta(m, .5); g(q); int t = k3(m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    ["rec3"] + FAM["v"]["T"], ["rec3t"] + FAM["v"]["T"])
# a DECLARED-ONLY callee (no body in the module): never predicted, kMsgUnknownCallee
mem("nd", "int hx(int a, int k);\n", "int q = cq_theta(m, .5); int t = hx(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    "int hx(int a, int k);\n", "int q = cq_theta(m, .5); int t = hx(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q);",
    [], [])

# ---- 3zr4: a round-2 site h(y, m) (y a 6.5 merge %out), read by a round-1 site g2(t, q) ----
X3 = "int ext_f(int a);\nint g2(int a, int b);\n"
reading("z3", "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(y, m); int u = g2(t, q); return cq_measure(u) + cq_measure(q) + cq_measure(y);",
        "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(y); int t = m + 1; int u = g2(t, q); return cq_measure(u) + cq_measure(q) + cq_measure(y);",
        cextra=X3, textra=X3, xlibs=["x3"])
# the bead's ORIGINAL 3zr4 repro (h IGNORES a): vsfp's drop applies on the oracle.
mem("z3ig", H + X3,
    "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(y, m); int u = g2(t, q); return cq_measure(u) + cq_measure(q) + cq_measure(y);",
    X3,
    "int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = m + 1; int u = g2(t, q); return cq_measure(u) + cq_measure(q) + cq_measure(y);",
    ["ign", "x3"], ["x3"])

for lib, body in LIBS.items():
    with open(os.path.join(SRC, f"{lib}.lib1.c"), "w") as f:
        f.write(body)
for (name, cdecl, cmain, tdecl, tmain, clibs, tlibs) in MEMBERS:
    for side, decl, body, libs in (("C", cdecl, cmain, clibs), ("T", tdecl, tmain, tlibs)):
        with open(os.path.join(SRC, f"{name}{side}.c"), "w") as f:
            f.write(HDR + decl + "int main(int c, char **v) { " + M + body + " }\n")
        with open(os.path.join(SRC, f"{name}{side}.libs"), "w") as f:
            f.write("".join(l + "\n" for l in libs))
print(" ".join(m[0] for m in MEMBERS))
