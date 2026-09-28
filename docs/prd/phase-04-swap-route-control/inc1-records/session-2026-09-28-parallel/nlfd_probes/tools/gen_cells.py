#!/usr/bin/env python3
"""gen_cells.py — the (null-safe? x musttail? x recorded-dead? x operand) interaction
table for bd nlfd / bd ev3m, as hand-written IR subjects and HAND-INLINED IR twins.

Writes ../src/cells/<name>.ll (subject) and ../src/cells/<name>T.ll (twin), and
../src/cells/pairs.txt ("cells/<name> cells/<name>T" per line) for pairs.sh.

Two families.

INNER ("i_*") — the slot under test is INSIDE a clone. The caller is r2B's `k19` main:
    q = cq_theta(m & 7, .5); p = q * 3; r = h(p, m); u = p ^ q;
    if (u == 10) cq_phi(pi); q2 = cq_theta(q, .7); return measure(q2) + measure(r);
  `h` is cloned (its slot 0 is quantum) and calls `h2` with X in slot 0:
    OP  arg : X = %a                 (a parameter forwarded)
        inst: X = %a * 5             (a quantum instruction on the parameter)
    MT  mt  : `musttail call`, else `tail call`
    NS  ns  : h2's param 0 plain `noundef` (null-safe)
        nn  : h2's param 0 also carries "cq.probe.opaque" (a string attribute —
              NOT null-safe; IR-only: clang -O1 never emits one on an int param)
    RD  cd  : h2 reads x ONLY in an empty diamond (`if (x > 3) {}`): the pre-specialize
              drop sees a live branch; the CLONE's flatten kills it (recorded dead)
        pd  : h2 never reads x (dead before specialize — the drop's own case)
        lv  : h2 returns k + x (a real read; the clone returns quantum)
  Twin: `r` hand-inlined — m + 1 (cd/pd), m + p (lv/arg), m + 5p (lv/inst).

MODULE ("m_*") — the slot under test is in a USER function (r6 `mm1`'s shape, bd ev3m):
    w(m, k) { q = cq_theta(m & 7, .5); p = q * 3; u = p ^ q; if (u == 10) cq_phi(pi);
              return h2(X, k); }            (X = p | p * 5; musttail | tail)
    main: return w(m, m)
  Twin: w returns k + 1 (cd/pd), k + X (lv).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "src", "cells")
os.makedirs(OUT, exist_ok=True)

HDR = """target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
"""

def h2_def(ns, rd):
    attr = ' "cq.probe.opaque"' if ns == "nn" else ""
    if rd == "cd":
        body = """  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %f
t:
  br label %f
f:
  %r = add nsw i32 %k, 1
  ret i32 %r"""
    elif rd == "pd":
        body = """  %r = add nsw i32 %k, 1
  ret i32 %r"""
    else:  # lv
        body = """  %r = add nsw i32 %k, %x
  ret i32 %r"""
    return f"""define i32 @h2(i32 noundef{attr} %x, i32 noundef %k) noinline {{
e:
{body}
}}
"""

def call_h2(mt, xname):
    kw = "musttail call" if mt == "mt" else "tail call"
    return f"  %r = {kw} i32 @h2(i32 noundef {xname}, i32 noundef %k)\n  ret i32 %r"

def inner_subject(op, mt, ns, rd):
    x = "%a" if op == "arg" else "%t"
    pre = "" if op == "arg" else "  %t = mul nsw i32 %a, 5\n"
    h = f"""define i32 @h(i32 noundef %a, i32 noundef %k) {{
e:
{pre}{call_h2(mt, x)}
}}
"""
    main = """define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %r = call i32 @h(i32 noundef %p, i32 noundef %m)
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}
"""
    return HDR + "\n" + main + "\n" + h + "\n" + h2_def(ns, rd)

def inner_twin(op, rd):
    if rd in ("cd", "pd"):
        r = "  %r = add nsw i32 %m, 1\n"
    elif op == "arg":
        r = "  %r = add nsw i32 %m, %p\n"
    else:
        r = "  %t = mul nsw i32 %p, 5\n  %r = add nsw i32 %m, %t\n"
    return HDR + f"""
define i32 @main(i32 noundef %argc, ptr noundef %argv) {{
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %m7 = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
{r}  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
  %q2 = call i32 @cq_theta_si32(i32 noundef %q, double noundef 0x3FE6666666666666)
  %z = call i32 @cq_measure_si32(i32 noundef %q2)
  %zr = call i32 @cq_measure_si32(i32 noundef %r)
  %s = add nsw i32 %z, %zr
  ret i32 %s
}}
"""

W_PRE = """  %m7 = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 noundef %m7, double noundef 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %ph, label %j
ph:
  call void @cq_phi(double noundef 3.141590e+00)
  br label %j
j:
"""

MAIN_W = """define i32 @main(i32 noundef %argc, ptr noundef %argv) {
e:
  %a1p = getelementptr inbounds ptr, ptr %argv, i64 1
  %a1 = load ptr, ptr %a1p
  %m = call i32 @atoi(ptr noundef %a1)
  %r = call i32 @w(i32 noundef %m, i32 noundef %m)
  ret i32 %r
}
"""

def module_subject(op, mt, ns, rd):
    pre = "" if op == "arg" else "  %t = mul nsw i32 %p, 5\n"
    x = "%p" if op == "arg" else "%t"
    kw = "musttail call" if mt == "mt" else "tail call"
    w = f"""define i32 @w(i32 noundef %m, i32 noundef %k) noinline {{
e:
{W_PRE}{pre}  %r = {kw} i32 @h2(i32 noundef {x}, i32 noundef %k)
  ret i32 %r
}}
"""
    return HDR + "\n" + MAIN_W + "\n" + w + "\n" + h2_def(ns, rd)

def module_twin(op, rd):
    if rd in ("cd", "pd"):
        r = "  %r = add nsw i32 %k, 1\n"
    elif op == "arg":
        r = "  %r = add nsw i32 %k, %p\n"
    else:
        r = "  %t = mul nsw i32 %p, 5\n  %r = add nsw i32 %k, %t\n"
    w = f"""define i32 @w(i32 noundef %m, i32 noundef %k) noinline {{
e:
{W_PRE}{r}  ret i32 %r
}}
"""
    return HDR + "\n" + MAIN_W + "\n" + w

pairs = []
for fam in ("i", "m"):
    for op in ("arg", "inst"):
        for mt in ("mt", "tc"):
            for ns in ("ns", "nn"):
                for rd in ("cd", "pd", "lv"):
                    n = f"{fam}_{op}_{mt}_{ns}_{rd}"
                    tn = f"{fam}T_{op}_{rd}"
                    if fam == "i":
                        s, t = inner_subject(op, mt, ns, rd), inner_twin(op, rd)
                    else:
                        s, t = module_subject(op, mt, ns, rd), module_twin(op, rd)
                    with open(os.path.join(OUT, n + ".ll"), "w") as f:
                        f.write(s)
                    with open(os.path.join(OUT, tn + ".ll"), "w") as f:
                        f.write(t)
                    pairs.append(f"cells/{n} cells/{tn}")
with open(os.path.join(OUT, "pairs.txt"), "w") as f:
    f.write("\n".join(pairs) + "\n")
print(len(pairs), "cells")

# ── the EXTRA ("x_*") probes: the fence's precision controls, the nested form, the
#    strip, and the handle-mask conjunct. Same k19 main (`inner_subject`'s), h/h2 vary.
MAIN_K19 = inner_subject("arg", "tc", "ns", "cd").split("define i32 @h(")[0]
H2_CD_NN = h2_def("nn", "cd")
X = {}
# x_inst_live: the inner non-null-safe dead slot's INSTRUCTION operand is ALSO read by
# a live root (the return) — value-live, so the fence must NOT fire. r = m + 1 + 5p.
X["x_inst_live"] = (MAIN_K19 + """define i32 @h(i32 noundef %a, i32 noundef %k) {
e:
  %t = mul nsw i32 %a, 5
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %k)
  %s = add nsw i32 %r, %t
  ret i32 %s
}
""" + "\n" + H2_CD_NN, "  %t = mul nsw i32 %p, 5\n  %r1 = add nsw i32 %m, 1\n  %r = add nsw i32 %r1, %t\n")
# x_nested_arg: TWO non-null-safe levels, an ARGUMENT forwarded at each:
#   main -> g(p, m) -> h(a "opaque") -> h2(x "opaque", branch-only read). r = m + 1.
X["x_nested_arg"] = (MAIN_K19.replace("@h(i32 noundef %p", "@g(i32 noundef %p") + """define i32 @g(i32 noundef %a, i32 noundef %k) noinline {
e:
  %r = tail call i32 @h(i32 noundef %a, i32 noundef %k)
  ret i32 %r
}

define i32 @h(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) noinline {
e:
  %r = tail call i32 @h2(i32 noundef %a, i32 noundef %k)
  ret i32 %r
}
""" + "\n" + H2_CD_NN, "  %r = add nsw i32 %m, 1\n")
# x_arg_range: sa1's shape plus `range` on the inner non-null-safe slot (callee
# param AND call site) — the strip pin: the neutralised 0 arrives there.
X["x_arg_range"] = (MAIN_K19 + """define i32 @h(i32 noundef %a, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef range(i32 1, 100) %a, i32 noundef %k)
  ret i32 %r
}
""" + "\n" + H2_CD_NN.replace('i32 noundef "cq.probe.opaque" %x',
                               'i32 noundef range(i32 1, 100) "cq.probe.opaque" %x'),
    "  %r = add nsw i32 %m, 1\n")
# x_classical_inst: the non-null-safe dead slot carries a CLASSICAL instruction
# (`c + 1`, c a classical parameter) beside a quantum slot the inner callee READS —
# the handle-mask conjunct: no decline. r = m + p (quantum, measured).
X["x_classical_inst"] = (MAIN_K19.replace("@h(i32 noundef %p, i32 noundef %m)",
                                          "@h(i32 noundef %p, i32 noundef %m, i32 noundef %m)")
    + """define i32 @h(i32 noundef %a, i32 noundef %c, i32 noundef %k) {
e:
  %t = add nsw i32 %c, 1
  %r = tail call i32 @h2(i32 noundef %t, i32 noundef %a, i32 noundef %k)
  ret i32 %r
}

define i32 @h2(i32 noundef "cq.probe.opaque" %x, i32 noundef %y, i32 noundef %k) noinline {
e:
  %r = add nsw i32 %k, %y
  ret i32 %r
}
""", "  %r = add nsw i32 %m, %p\n")
# x_outer_nn: sa1's shape with the OUTER slot not null-safe too (a string attribute on
# `h`'s parameter 0): the record now calls it dead (bd nlfd), so the module-level
# resolution's step 1 sees a recorded-dead, NOT rewritable slot with a QUANTUM operand and
# declines — where the ORACLE accepted with bd tzfa's phantom read. r = m + 1.
X["x_outer_nn"] = (MAIN_K19 + """define i32 @h(i32 noundef "cq.probe.opaque" %a, i32 noundef %k) {
e:
  %r = tail call i32 @h2(i32 noundef %a, i32 noundef %k)
  ret i32 %r
}
""" + "\n" + H2_CD_NN, "  %r = add nsw i32 %m, 1\n")
xp = []
for n, (s, r) in X.items():
    open(os.path.join(OUT, n + ".ll"), "w").write(s)
    t = inner_twin("arg", "cd").replace("  %r = add nsw i32 %m, 1\n", r)
    open(os.path.join(OUT, n + "T.ll"), "w").write(t)
    xp.append(f"cells/{n} cells/{n}T")
with open(os.path.join(OUT, "pairs_x.txt"), "w") as f:
    f.write("\n".join(xp) + "\n")
