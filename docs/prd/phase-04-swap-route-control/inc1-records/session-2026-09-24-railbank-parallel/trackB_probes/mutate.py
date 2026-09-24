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

MUTANTS = [
    ("M0-null", OL, "void declineRecordedStaleQuantumReaders(Module &M, TaintSet &taint) {\n",
     "void declineRecordedStaleQuantumReaders(Module &M, TaintSet &taint) {\n  // null-control mutant: comment only\n"),
    ("M1-hop-off", OL, "const bool Hopped = railBankParkedRails(Rec, Seeds);",
     "const bool Hopped = false; (void)&railBankParkedRails;"),
    ("M2-const-seeds", RB, "      if (!isa<Constant>(R))\n        Out.push_back(R);",
     "      Out.push_back(R);"),
    ("M3-delta-rec-only", OL, "            InDelta = InDelta || Delta->count(S) != 0;",
     "            (void)S;"),
    ("M4-self-exempt-when-hopped", OL, "        if (!Hopped)\n          if (auto *CI = dyn_cast<CallInst>(&I))",
     "        if (true)\n          if (auto *CI = dyn_cast<CallInst>(&I))"),
    ("M5-no-gep-hop", RB, "      if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) ||\n          isa<AddrSpaceCastInst>(U)) {",
     "      if (isa<BitCastInst>(U) ||\n          isa<AddrSpaceCastInst>(U)) {"),
    ("M6-no-cast-peel", RB, "  if (auto *C = dyn_cast<CastInst>(SV))\n    if (CellT && C->getDestTy() == CellT && C->getSrcTy()->isIntegerTy())\n      return C->getOperand(0);\n  return SV;",
     "  (void)CellT;\n  return SV;"),
    ("M7-G7e-admits-store", AL, "  const auto *CI = dyn_cast<CallInst>(UI);\n  if (!CI)\n    return false;  // (e) plain-IR use / still-unlowered tainted opcode.",
     "  const auto *CI = dyn_cast<CallInst>(UI);\n  if (!CI)\n    return isa<StoreInst>(UI);  // MUTANT"),
    ("M8-naive-backward-closure", OL, "        if (Seeds.empty()) {\n          // Not a bank read at all",
     "        if (Hopped) { unsigned N0 = Seeds.size(); for (unsigned K = 0; K < N0; ++K) if (auto *PN = dyn_cast<PHINode>(Seeds[K])) { for (Value *In : PN->incoming_values()) if (!isa<Constant>(In)) Seeds.push_back(In); } else if (auto *SL = dyn_cast<SelectInst>(Seeds[K])) { for (Value *In : {SL->getTrueValue(), SL->getFalseValue()}) if (!isa<Constant>(In)) Seeds.push_back(In); } }\n        if (Seeds.empty()) {\n          // Not a bank read at all"),
    ("M9-fence-positionfree", OL, "                                    /*RequireEmitDominance=*/false))\n          taint.StaleQuantumReaders.emplace_back(&I);",
     "                                    /*RequireEmitDominance=*/true))\n          taint.StaleQuantumReaders.emplace_back(&I);"),
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
            if re.search(r"VIOLATION|TRACE-MISMATCH|OVER-DECLINE", l) and l.startswith("  ")]
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
