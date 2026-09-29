#!/usr/bin/env python3
"""z0re twin sources.

Each pair <b>C / <b>T: C is the SPEC-CLASSICAL SIDE DOOR (t = h(q, m) through a
second TU whose h READS its first argument through a volatile local — the only
C spelling of bd z0re's side door that survives bd vsfp's dead-argument drop,
per the vsfp note on z0re), T is the HAND-INLINED TWIN (t = m + 1). The z0re
ruling says both must ACCEPT with the same circuit.

The loop pairs <b>C / <b>T are ROLLED vs HAND-UNROLLED (no side door).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
os.makedirs(SRC, exist_ok=True)

HDR = "#include <stdlib.h>\n"
LIB_I = "int h(int a, int k) { volatile int z = a; (void)z; return k + 1; }\n"
LIB_D = ("double h(double a, double k) { volatile double z = a; (void)z; "
         "return k + 1.0; }\n")

# name -> (body with T_EXPR placeholder, is_fp)
SIDE = {
    # d88e l12 — the runtime-seed prep under a compare.
    "l12": ("int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); "
            "int t = T_EXPR; int q2 = cq_theta(n, .3); int r = t; "
            "if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q2);", False),
    # d88e l17 — the same under a bare _Bool rail condition.
    "l17": ("int m = atoi(v[1]); int q = cq_theta(m, .5); int t = T_EXPR; int r = t; "
            "_Bool b = cq_theta((_Bool)0, .3); if (b) r = cq_theta(t, .2); "
            "return cq_measure(r) + cq_measure(b);", False),
    # d88e a02 — prep whose condition reads the spec site's own argument register.
    "a02": ("int m = atoi(v[1]); int q = cq_theta(m, .5); int t = T_EXPR; int r = t; "
            "if (q > 3) r = cq_theta(t, .7); return cq_measure(r) + cq_measure(q);", False),
    # d88e a01 — the untainted-base Ry-stem angle select.
    "a01": ("int m = atoi(v[1]); int q = cq_theta(m, .5); int t = T_EXPR; int r; "
            "if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2); "
            "return cq_measure(r) + cq_measure(q);", False),
    # r1A r03 — prep then a CLASSICAL one-register lift on the prepped rail.
    "r03": ("int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = T_EXPR; "
            "int q2 = cq_theta(n, .3); int r = t; if (q2 > 3) r = cq_theta(t, .2); "
            "int s = r; if (m > 5) s = cq_theta(r, .4); "
            "return cq_measure(s) + cq_measure(q2);", False),
    # r1B zc — prep then an in-place add on the prepped rail.
    "zc": ("int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=T_EXPR; "
           "int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); int u=r+1; "
           "return cq_measure(u)+cq_measure(q2);", False),
    # r1B zf — prep then a SECOND tainted-condition Ry arm on the prepped rail.
    "zf": ("int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=T_EXPR; "
           "int q2=cq_theta(n,.3); int q3=cq_theta(n+1,.6); int r=t; "
           "if (q2>3) r=cq_theta(t,.2); int s=r; if (q3>2) s=cq_theta(r,.4); "
           "return cq_measure(s)+cq_measure(q2)+cq_measure(q3);", False),
    # r1B zj — prep then an unconditional Ry on the prepped rail.
    "zj": ("int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=T_EXPR; "
           "int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); "
           "int w=cq_theta(r,.9); return cq_measure(w)+cq_measure(q2);", False),
    # r1B zk — prep then a classical lift whose base is the hoisted gate.
    "zk": ("int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=T_EXPR; "
           "int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); "
           "if (m>2) r=cq_theta(r,.9); return cq_measure(r)+cq_measure(q2);", False),
    # r1B zm — the angle select then a classical lift.
    "zm": ("int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=T_EXPR; "
           "int q2=cq_theta(n,.3); int r=t; if (q2>3) r=cq_theta(t,.2); "
           "else r=cq_theta(t,.5); int s=r; if (m>1) s=cq_theta(r,.1); "
           "return cq_measure(s)+cq_measure(q2);", False),
    # r1B zxd — the f64 width.
    "zxd": ("double m=atof(v[1]); int n=atoi(v[2]); double q=cq_theta(m,.5); "
            "double t=T_EXPR; int q2=cq_theta(n,.3); double r=t; "
            "if (q2>3) r=cq_theta(t,.2); return (int)cq_measure(r)+cq_measure(q2);", True),
}

LOOPS = {
    # rolled vs hand-unrolled: a loop-VARIANT runtime seed (s + k), iteration-local.
    "lv": (
        "int m = atoi(v[1]), s = atoi(v[2]); int acc = 0; "
        "for (int k = 0; k < 3; k++) { int q = cq_theta(m + k, .5); int r = s + k; "
        "if (q > k) r = cq_theta(s + k, .2); acc += cq_measure(r); } return acc;",
        "int m = atoi(v[1]), s = atoi(v[2]); int acc = 0; "
        "{ int q = cq_theta(m + 0, .5); int r = s + 0; if (q > 0) r = cq_theta(s + 0, .2); acc += cq_measure(r); } "
        "{ int q = cq_theta(m + 1, .5); int r = s + 1; if (q > 1) r = cq_theta(s + 1, .2); acc += cq_measure(r); } "
        "{ int q = cq_theta(m + 2, .5); int r = s + 2; if (q > 2) r = cq_theta(s + 2, .2); acc += cq_measure(r); } "
        "return acc;"),
    # rolled vs hand-unrolled: a loop-INVARIANT runtime seed.
    "li": (
        "int m = atoi(v[1]), s = atoi(v[2]); int acc = 0; "
        "for (int k = 0; k < 3; k++) { int q = cq_theta(m + k, .5); int r = s; "
        "if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); } return acc;",
        "int m = atoi(v[1]), s = atoi(v[2]); int acc = 0; "
        "{ int q = cq_theta(m + 0, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); } "
        "{ int q = cq_theta(m + 1, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); } "
        "{ int q = cq_theta(m + 2, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); } "
        "return acc;"),
}


def w(name, text):
    with open(os.path.join(SRC, name), "w") as f:
        f.write(text)


for b, (body, fp) in SIDE.items():
    ty = "double" if fp else "int"
    w(f"{b}C.c", HDR + f"{ty} h({ty} a, {ty} k);\n"
      f"int main(int c, char **v) {{ {body.replace('T_EXPR', 'h(q, m)')} }}\n")
    w(f"{b}C.lib.c", LIB_D if fp else LIB_I)
    w(f"{b}T.c", HDR + f"int main(int c, char **v) {{ "
      f"{body.replace('T_EXPR', '(m + 1.0)' if fp else '(m + 1)')} }}\n")

for b, (rolled, unrolled) in LOOPS.items():
    w(f"{b}C.c", HDR + f"int main(int c, char **v) {{ {rolled} }}\n")
    w(f"{b}T.c", HDR + f"int main(int c, char **v) {{ {unrolled} }}\n")

print(f"wrote {len(SIDE)} side-door pairs and {len(LOOPS)} loop pairs into {SRC}",
      file=sys.stderr)
