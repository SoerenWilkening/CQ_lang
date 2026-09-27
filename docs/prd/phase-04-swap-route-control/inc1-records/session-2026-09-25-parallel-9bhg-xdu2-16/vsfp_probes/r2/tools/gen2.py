#!/usr/bin/env python3
"""bd vsfp ROUND 2 fixture bodies. Same recipe as gen.py (tests/e2e/run_slice_multi.sh:
caller `-include CQ.h`, each lib plain C, all `clang -O1`, then llvm-link). A lib list
may be EMPTY (single-TU program). Every <k> has a hand-inlined / fenv-intended twin
<k>T built the same way, so each fixture's stream can be checked against its twin."""
import pathlib
import subprocess

H = pathlib.Path(__file__).parent
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8"
L = "/usr/local/opt/llvm@19/bin"
I = "#include <stdlib.h>\n"
HK = "int h(int a, int k) { return k + 1; }\n"
BSEL = "int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n"
BSEL_T = "int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b); }\n"
HGWX = "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }\n"
HGWX_T = "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }\n"
S3D = "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = h(r, m); q = cq_theta(q, .7); return u + cq_measure(q); }\n"
S3D_T = "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int u = m + 1; q = cq_theta(q, .7); return u + cq_measure(q); }\n"
KPURE = "__attribute__((const)) int K(int x) { return x * 3 + 1; }\n"
KLOOP = "int K(int x) { int s = 0; for (int i = 0; i < x; ++i) s += i; return s; }\n"
F = {
    # r1A F-VA-1 / bd ctz4 — naked callees (DAE refuses them; so must the drop)
    "naked_kept": (I + "int ident(int a);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = ident(m * 3); return r + cq_measure(q); }\n",
                   ["__attribute__((naked, noinline)) int ident(int a) { __asm__(\"movl %edi, %eax\\n\\tret\"); }\n"]),
    "naked_quantum": (I + "int ident(int a);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = ident(q); return r + cq_measure(q); }\n",
                      ["__attribute__((naked, noinline)) int ident(int a) { __asm__(\"movl %edi, %eax\\n\\tret\"); }\n"]),
    # r1A F-VA-2 / bd m1gi — dead LLVM intrinsics in the dropped operand's cone
    "dead_smax": (I + "int h(int a, int k);\n__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p > n ? p : n, m); b = cq_theta(b, .7); return t + cq_measure(b); }\nint main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }\n", [HK]),
    "dead_smaxT": (I + "__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b); }\nint main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }\n", []),
    "dead_abs": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : -4; int t = h(__builtin_abs(p), m); b = cq_theta(b, .7); return t + cq_measure(b); }\n", [HK]),
    "dead_absT": (I + BSEL_T, []),
    "dead_ctpop": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); unsigned q = cq_theta((unsigned)(m & 255), .5); int n = __builtin_popcount(q); int t = h(n, m); q = cq_theta(q, .7); return t + cq_measure(q); }\n", [HK]),
    "dead_ctpopT": (I + "int main(int c, char **v) { int m = atoi(v[1]); unsigned q = cq_theta((unsigned)(m & 255), .5); int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    # r1A F-VA-3 — a dead loop-carried value cycle
    "dead_loop_cycle": (I + "#include <stdbool.h>\nint h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int a = 5; int s = m; bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; if (b0[i]) s -= 7; } int t = h(s, m); return t + cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a); }\n", [HK]),
    "dead_loop_cycleT": (I + "#include <stdbool.h>\nint main(int c, char **v) { int m = atoi(v[1]); int a = 5; int s = m; bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; if (b0[i]) s -= 7; } int t = m + 1; return t + cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a); }\n", []),
    # r1A F-VA-4 — an arm the deletion empties (no phi; and a two-entry phi)
    "emptied_arm": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m; if (q > 3) p = 100 / n; int t = h(p, m); q = cq_theta(q, .7); return t + cq_measure(q); }\n", [HK]),
    "emptied_armT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m; if (q > 3) p = 100 / n; int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    "emptied_arm_phi": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m, s = 7; if (q > 3) { p = 100 / n; s = 5; } int t = h(p, m); return t + cq_measure(s) + cq_measure(q); }\n", [HK]),
    "emptied_arm_phiT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m, s = 7; if (q > 3) { p = 100 / n; s = 5; } int t = m + 1; return t + cq_measure(s) + cq_measure(q); }\n", []),
    # r1A F-VA-5 — a module that DEFINES the reserved front-end symbol: the angle stays
    "reserved_symbol_angle": (I + "int main(int c, char **v) { int m = atoi(v[1]); double th = atof(v[2]); int q = cq_theta(m & 7, th); return cq_measure(q); }\n", ["int cq_theta_si32(int x, double a) { return x; }\n"]),
    # r1B F-VB-1 / bd a8q5 — volatile residue spellings (the fenv twin drops the line)
    "volatile_char": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { volatile char z = a; return k + 1; }\n"]),
    "volatile_charT": (I + BSEL_T, []),
    "volatile_derived": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { volatile int z = a * 3; return k + 1; }\n"]),
    "volatile_double": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { volatile double z = a; return k + 1; }\n"]),
    "volatile_two_stores": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { volatile int z = a; z = a + 1; return k + 1; }\n"]),
    "volatile_promoted_residue": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { volatile char z = a; char w = z; return k + 1 + (w - w); }\n"]),
    "volatile_round2_arm": (I + "int K(int x); int h(int a, int k);\n" + S3D, [KPURE + "int h(int a, int k) { volatile char z = a; return k + 1; }\n"]),
    "volatile_round2_armT": (I + S3D_T, []),
    "volatile_hgwx": (I + "int h(int a, int k);\n" + HGWX, ["int h(int a, int k) { volatile char z = a; return k + 1; }\n"]),
    "volatile_hgwxT": (I + HGWX_T, []),
    "volatile_promoted_bool": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int t = h(b, m); return t + cq_measure(b); }\n", ["int h(int a, int k) { volatile int z = a; return k + 1; }\n"]),
    "volatile_promoted_boolT": (I + "int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int t = m + 1; return t + cq_measure(b); }\n", []),
    "volatile_stale_attrs": (I + "int h(int a, int b, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int t = h(q, p, m); int u = q + 6; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r) + cq_measure(p); }\n", ["int h(int a, int b, int k) { volatile int z = a; return b * 3 + k; }\n"]),
    "volatile_stale_attrsT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int u = q + 6; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r) + cq_measure(p); }\n", []),
    # bd qjoc — no clone at all
    "qjoc_select": (I + "int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; volatile int z = p; int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b); }\n", []),
    "qjoc_selectT": (I + BSEL_T, []),
    "qjoc_template": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = q * 3; volatile int z = p; int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    "qjoc_templateT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    # the dead-call seeds: an unused clone call; a dead pure call in a dead arm; a loopy (not provably terminating) K
    "dead_clone_call": (I + "int h(int a, int b, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); int t = h(q, p, m); p = cq_theta(p, .4); return cq_measure(q) + cq_measure(p); }\n", ["int h(int a, int b, int k) { return a + b * 3 + k; }\n"]),
    "dead_clone_callT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); p = cq_theta(p, .4); return cq_measure(q) + cq_measure(p); }\n", []),
    "dead_classical_call_arm": (I + "int K(int x); int h(int a, int k);\n" + S3D, [KPURE + HK]),
    "dead_classical_call_armT": (I + S3D_T, []),
    "loopy_classical_call_arm": (I + "int K(int x); int h(int a, int k);\n" + S3D, [KLOOP + HK]),
    "loopy_classical_call_armT": (I + "int K(int x);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = m + 1; q = cq_theta(q, .7); return u + cq_measure(q) + 0 * r; }\n", [KLOOP]),
    "opaque_classical_call_arm": (I + "int K(int x); int h(int a, int k);\n" + S3D, ["int ext_k(int x);\nint K(int x) { return ext_k(x) + 1; }\n" + HK]),
    "opaque_classical_call_armT": (I + "int K(int x);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = m + 1; q = cq_theta(q, .7); return u + cq_measure(q) + 0 * r; }\n", ["int ext_k(int x);\nint K(int x) { return ext_k(x) + 1; }\n"]),
    "reserved_symbol_theta_kept": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int t = h(q, m); return t; }\n", ["int cq_theta_si32(int x, double a) { return x; }\nint h(int a, int k) { return k + 1; }\n"]),
    "nested4": (I + "int o4(int a, int b);\nint main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = o4(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }\n",
                ["int m4(int a, int b);\nint o4(int a, int b) { return m4(a, b) * 2 + b; }\n", "int n4(int a, int b);\nint m4(int a, int b) { return n4(a, b) + 3; }\n", "int i4(int a, int b);\nint n4(int a, int b) { return i4(a, b) - 1; }\n", "int i4(int a, int k) { return k + 1; }\n"]),
    "dead_loopy_call": (I + "int h(int a, int k);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); q = cq_theta(q, .7); return cq_measure(q); }\n", ["int h(int a, int k) { volatile int z = a; unsigned x = (unsigned)k; while (x != 7u) x = x * 3u + 1u; return (int)x; }\n"]),
    "local_promoted_residue": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); volatile char z = q; char w = z; int t = m + 1 + (w - w); q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    "local_promoted_residueT": (I + "int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }\n", []),
    "volatile_arm_const": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { if (a > 3) { volatile int z = 1; } return k + 1; }\n"]),
    "volatile_arm_value": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { if (a > 3) { volatile int z = a; } return k + 1; }\n"]),
    "volatile_arm_constfold": (I + "int h(int a, int k);\n" + BSEL, ["int h(int a, int k) { int w = 0; if (a > 3) { volatile int z = 1; w = z; } return k + 1 + (w - w); }\n"]),
    "dead_pure_call": (I + "int h(int a, int k); int k2(int a, int b); int k3(int a);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = k2(q, 3); int s = k3(m); int t = h(p + s, m); return t + cq_measure(q); }\n", ["int h(int a, int k) { return k + 1; }\nint k2(int a, int b) { return a * b; }\nint g_k3;\nint k3(int a) { g_k3 += a; return a; }\n"]),
    "dead_pure_callT": (I + "int k3(int a);\nint main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int s = k3(m); int t = m + 1; return t + cq_measure(q); }\n", ["int g_k3;\nint k3(int a) { g_k3 += a; return a; }\n"]),
}


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(" ".join(cmd) + "\n" + r.stderr)


for k, (c, libs) in F.items():
    (H / f"{k}.c").write_text(c)
    run([f"{L}/clang", f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(H / f"{k}.c"), "-o", str(H / f"{k}.caller.ll")])
    parts = [str(H / f"{k}.caller.ll")]
    for i, lt in enumerate(libs):
        sfx = "" if i == 0 else str(i + 1)
        (H / f"{k}.lib{sfx}.c").write_text(lt)
        run([f"{L}/clang", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(H / f"{k}.lib{sfx}.c"), "-o", str(H / f"{k}.lib{sfx}.ll")])
        parts.append(str(H / f"{k}.lib{sfx}.ll"))
    for i in range(len(libs), 3):
        sfx = "" if i == 0 else str(i + 1)
        (H / f"{k}.lib{sfx}.c").unlink(missing_ok=True)
    run([f"{L}/llvm-link", "-S"] + parts + ["-o", str(H / f"{k}.s1.ll")])
print(len(F), "built")
