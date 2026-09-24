#!/usr/bin/env python3
"""Forward-hop attack: an in-loop park AFTER a rail-relabelling Ry, reaching the
reader fence (railBankParkedRails + findNonDiagonalWireGate)."""
import pathlib
P = pathlib.Path(__file__).parent / "probes5"; P.mkdir(exist_ok=True)
HEAD = "#include <stdlib.h>\nint main(int argc, char **argv) {\n  int n = atoi(argv[1]); if (n <= 0) return 1;\n"
TAIL = "  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);\n  return s + cq_measure(q) + cq_measure(r);\n}\n"
PRE = "  int q = cq_theta(argc, 0.5); int r = cq_theta(argc + 1, 0.2); int b[n]; int s = 0;\n"
V = {
 "v1_ry_other_cond": "  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q = cq_theta(q, 0.3); b[k] = q; }\n",
 "v2_ctrl_ry_arm": "  for (int k = 0; k < n; ++k) { if (r > k) q = cq_theta(q, 0.3); b[k] = q; }\n",
 "v3_ry_no_region": "  for (int k = 0; k < n; ++k) { q = cq_theta(q, 0.3); b[k] = q; }\n",
 "v4_ry_then_xor_park": "  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q = cq_theta(q, 0.3); q ^= 1; b[k] = q; }\n",
 "v5_park_then_ry": "  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); b[k] = q; q = cq_theta(q, 0.3); }\n",
 "v6_fresh_theta_per_trip_then_ry_q": "  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); int t = cq_theta(q, 0.3); b[k] = t; }\n",
}
for n, body in V.items():
    (P / f"{n}.bank.c").write_text(HEAD + PRE + body + TAIL)
# bool-condition in-loop controlled Ry (the wx8g shape) with a park after it
(P / "v7_bool_ctrl_ry_park.bank.c").write_text(HEAD + """  int q = cq_theta(argc, 0.5); _Bool r = cq_theta((_Bool)0, 0.2); int b[n]; int s = 0;
  for (int k = 0; k < n; ++k) { if (r) q = cq_theta(q, 0.3); b[k] = q; }
""" + TAIL)
print(len(list(P.iterdir())))
