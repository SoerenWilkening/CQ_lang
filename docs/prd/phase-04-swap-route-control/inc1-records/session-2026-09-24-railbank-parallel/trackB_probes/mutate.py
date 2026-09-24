#!/usr/bin/env python3
"""Source-mutation matrix for bd xdu2.1 (Track B). Each mutant: apply one exact
replacement, rebuild CQPass+cq-opt (-j3), run ONLY the owned tests, restore via
`git checkout -- <file>`. Prints the denominator and MISSED count."""
import pathlib, re, subprocess, sys, json

WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
LLVM = "/usr/local/opt/llvm@19/bin"
OL = "ir-pass/src/OpcodeLowering.cpp"
RB = "ir-pass/src/RailBankPromote.cpp"
AL = "ir-pass/src/ArithLowering.cpp"
LL = "ir-pass/src/LoopLowering.cpp"
WW = "ir-pass/src/WireWalk.cpp"

MUTANTS = [
    ("N0-null", LL, "  // ── THE MEMORY HOP FOR THIS FENCE (bd `xdu2.1`, Rule-13 round-2 finding F-1,\n",
     "  // null-control mutant (comment only)\n  // ── THE MEMORY HOP FOR THIS FENCE (bd `xdu2.1`, Rule-13 round-2 finding F-1,\n"),
    ("N1-hop-removed", LL, "    if (railBankCellReadsOf(V, CellReads))\n",
     "    if (false && railBankCellReadsOf(V, CellReads))\n"),
    ("N2-no-cast-user", RB, "    if (isa<CastInst>(U))\n      for (User *CU : U->users())\n        consider(CU);\n",
     "    (void)0;\n"),
    ("N3-name-load-not-measure", LL, "          if (LD->hasOneUse())\n            if (auto *R = dyn_cast<Instruction>(*LD->user_begin()))\n              return R;\n",
     ""),
    ("N4-bank-refresh-reverted", LL, "        if (railGateBetween(Def, LD, Gates, /*DefRefreshes=*/false)) {",
     "        if (railGateBetween(Def, LD, Gates, Refreshes)) {"),
    ("N5-bank-refresh-true", LL, "        if (railGateBetween(Def, LD, Gates, /*DefRefreshes=*/false)) {",
     "        if (railGateBetween(Def, LD, Gates, true)) {"),
    ("N8-cellread-bit-off", OL, "                                    /*SeedIsCellRead=*/Hopped))",
     "                                    /*SeedIsCellRead=*/false))"),
    ("N9-cellread-leg2-kept", WW, "  if (SeedIsCellRead)\n    return false;\n", ""),
    ("N6-walker-no-gep", RB, "      if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) ||",
     "      if (isa<BitCastInst>(U) ||"),
    ("N7-first-load-only", LL, "      for (LoadInst *LD : CellReads)\n",
     "      for (LoadInst *LD : ArrayRef<LoadInst *>(CellReads).take_front(1))\n"),
]



def sh(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd or WT, text=True, capture_output=True)


def owned():
    lit = sh(["lit", "ir-pass/test", "--filter", "railbank_stale|stale_reader|reader_predates"], cwd=WT / "build")
    lf = re.findall(r"^(?:FAIL|XPASS|UNRESOLVED): CQ IR-pass :: (\S+)", lit.stdout, re.M)
    lp = re.search(r"Passed\s*:\s*(\d+)", lit.stdout)
    mx = sh(["python3", "tests/e2e/run_railbank_dynamic_matrix.py", f"{LLVM}/clang", "build/ir-pass/cq-opt",
             "build/ir-pass/libCQPass.so", "include", "tests/e2e/railbank_stale_matrix.c",
             "build/runtime/libcq_runtime.a", "build/runtime/libcq_templates.a"])
    mfail = sorted(set(re.findall(r"^(CASE=\d+|TWIN \d+/\d+)", mx.stderr, re.M)))
    tw = sh(["python3", "tools/railbank_register_twin_gate.py", "--build", "build",
             "--pairs", "tools/railbank_twin_pairs", "--include", "include"])
    tbad = [l.split()[0] for l in tw.stdout.splitlines()
            if re.search(r"VIOLATION|TRACE-MISMATCH", l) and l.startswith("  ")]
    return {"lit_fail": lf, "lit_pass": lp.group(1) if lp else "?", "matrix_fail": mfail,
            "matrix_summary": mx.stdout.strip(), "twin_bad": tbad, "twin_rc": tw.returncode}


only = sys.argv[1:]
rows = []
for name, f, old, new in MUTANTS:
    if only and name not in only:
        continue
    p = WT / f
    src = p.read_text()
    n = src.count(old)
    if n != 1:
        rows.append((name, f"NOT APPLIED (matches={n})"))
        print(name, "NOT APPLIED", n, flush=True)
        continue
    p.write_text(src.replace(old, new))
    try:
        b = sh(["cmake", "--build", "build", "-j3", "--target", "CQPass", "cq-opt"])
        if b.returncode:
            rows.append((name, "BUILD FAILED: " + b.stdout[-400:]))
            print(name, "BUILD FAILED", b.stdout[-800:], flush=True)
            continue
        r = owned()
        det = bool(r["lit_fail"] or r["matrix_fail"] or r["twin_bad"] or r["twin_rc"])
        rows.append((name, ("KILLED " if det else "MISSED ") + json.dumps(r)))
        print(name, "KILLED" if det else "MISSED", json.dumps(r), flush=True)
    finally:
        sh(["git", "checkout", "--", f])
b = sh(["cmake", "--build", "build", "-j3", "--target", "CQPass", "cq-opt"])
h = sh(["shasum", "-a", "256", "build/ir-pass/cq-opt"]).stdout[:16]
print("restored build rc", b.returncode, "cq-opt", h)
killed = sum(1 for _, v in rows if v.startswith("KILLED"))
missed = sum(1 for _, v in rows if v.startswith("MISSED"))
print(f"mutants={len(rows)} killed={killed} missed={missed} other={len(rows)-killed-missed}")
