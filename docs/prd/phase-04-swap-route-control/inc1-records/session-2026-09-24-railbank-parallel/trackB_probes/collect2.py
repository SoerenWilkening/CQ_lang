#!/usr/bin/env python3
"""Collect the Rule-13 round-2 reviewer probes into probes2/ as bank/reg pairs,
add Track-B variants, and snapshot the pre-fix cq-opt."""
import pathlib, shutil
SP = pathlib.Path(__file__).parent
R = SP.parent / "reviewB_r2"
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
P = SP / "probes2"; P.mkdir(exist_ok=True)
shutil.copyfile(WT / "build/ir-pass/cq-opt", SP / "cq-opt.base")
(SP / "cq-opt.base").chmod(0o755)
BANK = ["P1_bank", "P1_bank_ry", "P1_bank_fixed", "P1_legit", "r_qx33_bank", "r_qx3n_bank",
        "r_qxk3_bank", "r_qxkn_bank", "r_qp33_bank", "r_qp3n_bank", "P1_bank_nophi", "P1_bool",
        "f1_break_bank", "f2_break_bank_ry", "g1_abort_bank", "g2_abort_bank_ry",
        "n4_percell_then_xor_inloop", "n3_prep_measure_then_relabel_inloop"]
REG = {"P1_reg": "P1_bank", "P1_reg_ry": "P1_bank_ry", "r_qx33_reg": "r_qx33_bank",
       "r_qx3n_reg": "r_qx3n_bank", "r_qxk3_reg": "r_qxk3_bank", "r_qxkn_reg": "r_qxkn_bank",
       "r_qp33_reg": "r_qp33_bank", "r_qp3n_reg": "r_qp3n_bank", "f1_break_reg": "f1_break_bank",
       "g1_abort_reg": "g1_abort_bank"}
for b in BANK:
    shutil.copyfile(R / f"{b}.c", P / f"{b}.bank.c")
for r, b in REG.items():
    shutil.copyfile(R / f"{r}.c", P / f"{b}.reg.c")
# Track-B variants: bool cells (storage-cast user), add instead of xor, fixed
# bank with a constant-trip xor loop, two stores (park the rail into two banks),
# and the legit order on a fixed bank.
V = {
 "t1_bool_xor_loop.bank.c": """__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 _Bool q = cq_theta((_Bool)seed, 0.5); _Bool b[n]; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < n; ++i) b[i] = q;
 for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 1; }
 for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
""",
 "t2_add_loop.bank.c": """__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = cq_theta(seed, 0.5); int b[n]; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < n; ++i) b[i] = q;
 for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q += 5; }
 for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
""",
 "t2_add_loop.reg.c": """__attribute__((noinline)) int slice(int n, int seed) { if (n <= 1) return 0;
 int q = cq_theta(seed, 0.5); int c = q; int s = 0; int r = cq_theta(seed, .2);
 for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q += 5; }
 for (int i = 0; i < n; ++i) s += cq_measure(c);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
""",
 "t3_fixed_const_trip.bank.c": """__attribute__((noinline)) int slice(int seed) {
 int q = cq_theta(seed, 0.5); int b[3]; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < 3; ++i) b[i] = q;
 #pragma clang loop unroll(disable)
 for (int k = 0; k < 3; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
 for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
""",
 "t4_legit_fixed.bank.c": """__attribute__((noinline)) int slice(int seed) {
 int q = cq_theta(seed, 0.5); int b[3]; int s = 0; int r = cq_theta(seed, .2);
 for (int i = 0; i < 3; ++i) b[i] = q;
 for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
 #pragma clang loop unroll(disable)
 for (int k = 0; k < 3; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
 return s + cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
""",
 "t5_legit_ry.bank.c": """#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = cq_theta(argc, 0.5); int b[n]; int s = 0; int r = cq_theta(argc+1, .2);
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
  return s + cq_measure(q) + cq_measure(r);
}
""",
}
for n, t in V.items():
    (P / n).write_text(t)
print(len(list(P.iterdir())), "probe files")
