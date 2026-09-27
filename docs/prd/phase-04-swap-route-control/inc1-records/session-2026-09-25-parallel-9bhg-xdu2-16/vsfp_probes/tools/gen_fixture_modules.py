#!/usr/bin/env python3
"""Generate the bd vsfp lit-fixture bodies: every <k>.c + <k>.lib.c is compiled
exactly as tests/e2e/run_slice_multi.sh does (caller `-include CQ.h`, lib plain C,
both `clang -O1`) and llvm-linked into <k>.s1.ll."""
import pathlib
import subprocess

H = pathlib.Path(__file__).parent
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8"
L = "/usr/local/opt/llvm@19/bin"
LIB = "int h(int a, int k) { return k + 1; }\n"
F = {
    "boolsel": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n", LIB),
    "boolsel_provisional": ("#include <stdlib.h>\nint h(int a, int k);\n__attribute__((noinline)) int f(int m) { _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b + 1; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\nint main(int c, char **v) { return f(atoi(v[1])); }\n", LIB),
    "classical_call_arm": ("#include <stdlib.h>\nint K(int x); int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = h(r, m); q = cq_theta(q, .7); return u + cq_measure(q); }\n", "__attribute__((const)) int K(int x) { return x * 3 + 1; }\n" + LIB),
    "inplace_mc": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }\n", LIB),
    "nested": ("#include <stdlib.h>\nint out3(int a, int b);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = out3(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n", ["int in1(int a, int k);\nint out3(int a, int b) { return in1(a, b) * 2 + b; }\n", "int in1(int a, int k) { return k + 1; }\n"]),
    "quantum_clone_dead_slot": ("#include <stdlib.h>\nint h3(int a, int b, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int q = cq_theta(m, .3); int t = h3(p, q, m); b = cq_theta(b, .7); return cq_measure(t) + cq_measure(b); }\n", "int h3(int a, int b, int k) { return b + k; }\n"),
    "quantum_clone_control": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return cq_measure(t) + cq_measure(b); }\n", "int h(int a, int k) { return a + k; }\n"),
    "scrubbed_handle_branch": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r); }\n", LIB),
    "statepred_runtime_seed": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int q2 = cq_theta(n, .3); int r = t; if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q2); }\n", LIB),
    "fp": ("#include <stdlib.h>\nint hf(double a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); double d = cq_theta((double)m, .5); double e = d * 2.0; int t = hf(e, m); d = cq_theta(d, .7); return t + (int)cq_measure(d); }\n", "int hf(double a, int k) { return k + 1; }\n"),
    "theta_source_exempt": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t) * 100 + cq_measure(q); }\n", "int h(int a, int k) { volatile int z = a; return k + 1; }\n"),
    "derived_exempt_negative": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n", "int h(int a, int k) { volatile int z = a; return k + 1; }\n"),
    "theta_source_inplace_mc": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }\n", "int h(int a, int k) { volatile int z = a; return k + 1; }\n"),
    "theta_kept": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); return t; }\n", "int h(int a, int k) { return k + 1; }\n"),
    "weak_callee": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n", "__attribute__((weak)) int h(int a, int k) { return k + 1; }\n"),
    "quantum_reader_unsettled": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }\n", "int h(int a, int k) { return a + k; }\n"),
    "quantum_reader_outofplace": ("#include <stdlib.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = q + 5; int r = cq_theta(u, .2); return cq_measure(r) + cq_measure(t); }\n", "int h(int a, int k) { return a * 3 + k; }\n"),
    "pure_call_kept": ("#include <stdlib.h>\nint h(int a, int k); int k2(int a, int b);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = k2(q, 3); int t = h(p, m); return t + cq_measure(q); }\n", "int h(int a, int k) { return k + 1; }\nint k2(int a, int b) { return a * b; }\n"),
    "pure_call_keptT": ("#include <stdlib.h>\nint k2(int a, int b);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = k2(q, 3); int t = m + 1; return t + cq_measure(q); }\n", "int k2(int a, int b) { return a * b; }\n"),
}


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stderr)


for k, (c, l) in F.items():
    libs = l if isinstance(l, list) else [l]
    (H / f"{k}.c").write_text(c)
    run([f"{L}/clang", f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(H / f"{k}.c"), "-o", str(H / f"{k}.caller.ll")])
    parts = [str(H / f"{k}.caller.ll")]
    for i, lt in enumerate(libs):
        sfx = "" if i == 0 else str(i + 1)
        (H / f"{k}.lib{sfx}.c").write_text(lt)
        run([f"{L}/clang", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(H / f"{k}.lib{sfx}.c"), "-o", str(H / f"{k}.lib{sfx}.ll")])
        parts.append(str(H / f"{k}.lib{sfx}.ll"))
    run([f"{L}/llvm-link", "-S"] + parts + ["-o", str(H / f"{k}.s1.ll")])
print(len(F), "built")
