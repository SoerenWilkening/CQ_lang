#!/usr/bin/env python3
"""Permanent mutants of checker/rt/tmpl_bits.c (cq-w0-tmpl-bits).

Each mutant is one textual change to the family source that breaks a CR §2 / BACKEND_ABI §2
semantic. The differential harness, built against the mutated source and run with --first, must
reject every one; a mutant it accepts means the test lost its power. A mutant whose anchor text is
missing fails too (the source moved; update the anchor, never drop the mutant).
"""
import argparse
import os
import subprocess
import sys
import tempfile

MUTANTS = [
    ("ctlz(0) = W - 1", "while (n < W && !tb_bit(a, W - 1", "while (n < W - 1 && !tb_bit(a, W - 1"),
    ("cttz(0) = 0", "while (n < W && !tb_bit(a, (uint32_t)n))", "while (n && n < W && !tb_bit(a, (uint32_t)n))"),
    ("amount mod W reads the low word only", "r = ((r << 64) | x[i]) % W;", "r = (i == 0) ? x[0] % W : r;"),
    ("amount masked to 5 bits (x86 r/m8 count, not mod W)", "tb_shl(r, a, tb_mod(b, W), W);",
     "tb_shl(r, a, tb_mod(b, W) & 31, W);"),
    ("amount >= W gives 0 (BJ constant shift, overridden by §2)", "tb_shr(r, a, tb_mod(b, W), W, 0);",
     "tb_shr(r, a, (b[0] >= W || nw > 1 ? W : tb_mod(b, W)), W, 0);"),
    ("ashr fills with 0", "tb_shr(r, a, tb_mod(b, W), W, tb_bit(a, W - 1));", "tb_shr(r, a, tb_mod(b, W), W, 0);"),
    ("fshr by 0 returns a", "    tb_shr(r, b, s, W, 0);\n", "    if (!s) { memcpy(r, a, nw * 8); break; }\n    tb_shr(r, b, s, W, 0);\n"),
    ("fshl swaps a and b", "    tb_shl(r, a, s, W);\n    if (s) {\n      tb_shr(u, b, W - s, W, 0);",
     "    tb_shl(r, b, s, W);\n    if (s) {\n      tb_shr(u, a, W - s, W, 0);"),
    ("operand bits above W not ignored", "    r[nw - 1] &= ((uint64_t)1 << (W % TB_WBITS)) - 1;", "    (void)0;"),
    ("bswap reverses bits", "(W / 8 - 1 - i / 8) * 8 + i % 8", "(W / 8 - 1 - i / 8) * 8 + (7 - i % 8)"),
    ("ctpop drops bit 63 of each word", "__builtin_popcountll(a[i])", "__builtin_popcountll(a[i] & 0x7fffffffffffffffull)"),
    ("or computed as xor", "r[i] = a[i] | b[i];", "r[i] = a[i] ^ b[i];"),
    ("result top word left unwritten", "  memcpy(out->w, r, nw * sizeof *r);",
     "  memcpy(out->w, r, (nw > 1 ? nw - 1 : nw) * sizeof *r);"),
    ("bswap accepted at W = 8 (W % 16 != 0)", "if (op == TB_BSWAP && W % 16) {", "if (op == TB_BSWAP && W % 8) {"),
    ("foreign op is a violation, not CQE_OP_NOT_MINE", "  if (k < 0)\n    return CQE_OP_NOT_MINE;",
     "  if (k < 0) {\n    cqe_fail(\"x\");\n    return -1;\n  }"),
    ("handler overwrites the core-owned out->kind", "  memcpy(out->w, r, nw * sizeof *r);", "  out->kind = 'f';\n  memcpy(out->w, r, nw * sizeof *r);"),
    ("arity unchecked", "if (nargs != tb_ops[k].arity) {", "if (nargs < tb_ops[k].arity) {"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", required=True)
    ap.add_argument("--src", required=True)
    ap.add_argument("--harness", required=True)
    ap.add_argument("--gen", required=True, help="directory holding native.o and native.h")
    ap.add_argument("--rt", required=True, help="checker/rt (cqe.h)")
    a = ap.parse_args()
    src = open(a.src).read()
    bad = 0
    with tempfile.TemporaryDirectory() as td:
        for i, (what, old, new) in enumerate(MUTANTS):
            if src.count(old) != 1:
                print(f"ANCHOR MISSING ({src.count(old)} hits): {what}")
                bad += 1
                continue
            m = os.path.join(td, f"m{i}.c")
            exe = os.path.join(td, f"m{i}")
            open(m, "w").write(src.replace(old, new))
            subprocess.run([a.clang, "-O1", "-std=c17", "-w", "-I", a.rt, "-I", a.gen, a.harness, m,
                            os.path.join(a.gen, "native.o"), "-o", exe], check=True)
            r = subprocess.run([exe, "--first"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
            first = (r.stderr.strip().splitlines() or [""])[0][:100]
            if r.returncode == 0:
                print(f"SURVIVED: {what}")
                bad += 1
            else:
                print(f"killed: {what}: {first}")
    print(f"tmpl-bits mutants: {len(MUTANTS)} total, {len(MUTANTS) - bad} killed, {bad} survived or missing")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
