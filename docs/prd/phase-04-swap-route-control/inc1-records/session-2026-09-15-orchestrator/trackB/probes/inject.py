#!/usr/bin/env python3
"""Track B injection (mutation) matrix for bd `xdu2` W1's SECOND HALF.

Each mutant is a one-line-scale edit to the PASS SOURCE that breaks one thing
the increment claims.  For each: apply, rebuild BOTH targets, run the gates,
restore, report which gate caught it.

INSTRUMENT DISCIPLINE, because this project's instruments fail by reporting a
pass (`CLAUDE.md` L10):
  * the gates are `lit` and `ctest` THEMSELVES, never a hand-rolled FileCheck —
    "a harness that runs a weaker command than lit measures itself, not the
    fixtures" (a matrix once reported 45 MISSED that way, by dropping the RUN
    line's `--implicit-check-not` flags);
  * a mutant whose EDIT DOES NOT APPLY is a HOLE, not a pass: it exits non-zero
    and is reported as `EDIT-FAILED`, never as `n/a` and never as CAUGHT;
  * a mutant whose build FAILS is reported as `BUILD-FAILED`, never as CAUGHT —
    a compile error is not a test catching anything;
  * MISSED is printed with a count and a non-zero exit, so a silent matrix
    cannot look like a clean one.

Usage:  python3 .../probes/inject.py            (all mutants)
        python3 .../probes/inject.py M1 M4      (a subset)
Run from the worktree root.
"""
import os, re, subprocess, sys

ROOT = os.getcwd()
LIT_FILTER = "railbank"
CTEST_FILTER = r"^e2e-(slice-)?railbank"

# (id, file, old, new, what it breaks)
MUTANTS = [
    ("M1", "ir-pass/src/TaintPropagation.cpp",
     "        if (railBankOfPointer(LD->getPointerOperand()) &&\n"
     "            out.Tainted.insert(LD).second)\n"
     "          Worklist.push_back(LD);",
     "        if (false && railBankOfPointer(LD->getPointerOperand()) &&\n"
     "            out.Tainted.insert(LD).second)\n"
     "          Worklist.push_back(LD);",
     "PIECE 1 REMOVED — the bank load stops being tainted. THE SILENT MISCOMPILE: "
     "three written cq_measure calls emit nothing."),

    ("M2", "ir-pass/src/TaintPropagation.cpp",
     "            if (isRailBankAlloca(BShape.Alloca))\n              continue;",
     "            if (true || isRailBankAlloca(BShape.Alloca))\n              continue;",
     "THE MINT CONJUNCT DROPPED — `Bank` accepts whether or not the record was "
     "minted, so a bank the mark stage never claimed compiles with untainted loads."),

    ("M3", "ir-pass/src/RailBankPromote.cpp",
     "  AI->setAllocatedType(NewArr);",
     "  (void)NewArr;  // MUTANT M3",
     "TYPE REWRITE PASS 1 SKIPPED — the object keeps its [N x cell] type while "
     "i32 handles are stored into it. `opt -verify` CANNOT SEE THIS."),

    ("M4", "ir-pass/src/RailBankPromote.cpp",
     "    if (G->getSourceElementType() == OldArr)\n      G->setSourceElementType(NewArr);\n"
     "    else if (G->getSourceElementType() == OldArr->getElementType())\n      G->setSourceElementType(I32);",
     "    if (G->getSourceElementType() == OldArr)\n      G->setSourceElementType(NewArr);\n"
     "    else if (G->getSourceElementType() == OldArr->getElementType())\n      (void)I32;  // MUTANT M4",
     "TYPE REWRITE PASS 2, FLAT ELEMENT FORM SKIPPED — a `getelementptr i8` over "
     "an i32 bank strides by ONE BYTE and reads the wrong cell."),

    ("M5", "ir-pass/src/TaintPropagation.cpp",
     "  declineUnallowedRailBankReaders(M, taint);",
     "  (void)0;  // MUTANT M5",
     "PIECE 3 (D5) REMOVED — every consumer of a bank load is admitted."),

    ("M6", "ir-pass/src/ChainWalk.cpp",
     "  if (railStoredToRailBank(Handle))\n    return false;",
     "  if (false && railStoredToRailBank(Handle))\n    return false;",
     "THE D1 SPINE DOOR REMOVED — a rail parked in a bank cell is nominated as a "
     "dead terminal again. Only visible OUTSIDE `main`."),

    ("M7", "ir-pass/src/RailBankPromote.cpp",
     "  if (auto *P = dyn_cast<PHINode>(Final)) {\n    Type *RailTy = nullptr;",
     "  if (auto *P = (PHINode *)nullptr) {\n    Type *RailTy = nullptr;",
     "THE CAST SINK (PASS G) DISABLED — the `_Bool` storage cast stays in the "
     "region arm and the merge phi stays at the CELL type."),

    ("M8", "ir-pass/src/RailBankPromote.cpp",
     "  for (Instruction *Init : Inits) {\n    Init->eraseFromParent();\n  }",
     "  for (Instruction *Init : Inits) {\n    (void)Init;  // MUTANT M8\n  }",
     "THE INITIALIZER IS KEPT AT ITS OLD LENGTH — a 3-byte zero fill now covers "
     "part of a 12-byte object. ⚠ EXPECTED MISSED, AND NOT A HOLE: C6 TOTALITY "
     "says every cell is stored before any cell is loaded, so a short fill is "
     "never observed. This mutant is NOT A DEFECT; it is the control for M8b."),

    ("M8b", "ir-pass/src/RailBankPromote.cpp",
     "  for (Instruction *Init : Inits) {\n    Init->eraseFromParent();\n  }",
     "  for (Instruction *Init : Inits) {\n"
     "    if (auto *MS = dyn_cast<MemSetInst>(Init)) {\n"
     "      MS->setLength(ConstantInt::get(Type::getInt64Ty(Ctx),\n"
     "                   DL.getTypeAllocSize(NewArr).getFixedValue()));\n"
     "      continue;\n"
     "    }\n"
     "    Init->eraseFromParent();\n  }",
     "THE INITIALIZER IS RESCALED RATHER THAN DELETED — THE HAZARD THE DELETION "
     "IS ACTUALLY ABOUT. A rescaled memset writes handle `0` into every cell, and "
     "handle 0 IS A LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`)."),

    ("M9", "ir-pass/src/RailBankPromote.cpp",
     "    if (TR->getOperand(0) != LD || !TR->hasOneUse() || TR->getType() != RailTy)",
     "    if (TR->getOperand(0) != LD || !TR->hasOneUse())",
     "D5's WIDTH CONJUNCT DROPPED — a `trunc` to any width is read as the storage "
     "cast, so a user-written truncation's GATE is dropped and an i32 rail is "
     "measured at i16."),

    ("M10", "ir-pass/src/RailBankPromote.cpp",
     "      if (auto *TR = dyn_cast<TruncInst>(U))\n        if (TR->getType() == RailTy) {",
     "      if (auto *TR = dyn_cast<TruncInst>(U))\n        if (true) {",
     "THE TYPE REWRITE'S HALF OF THE WIDTH FENCE DROPPED — PASS 5 erases any "
     "`trunc` off a bank load, not only the storage one. ⚠ EXPECTED MISSED while "
     "D5 holds: the two spellings are one fence and D5 refuses the input first."),
]


def run(cmd, **kw):
    return subprocess.run(cmd, shell=True, cwd=ROOT, capture_output=True, text=True, **kw)


def gates():
    """The gates, run as the suite runs them. Returns (ok, summary)."""
    lit = run(f"cd build && lit ir-pass/test --filter '{LIT_FILTER}' 2>&1 | tail -6")
    litout = lit.stdout
    litfail = 0
    m = re.search(r"Failed\s*:\s*(\d+)", litout)
    if m:
        litfail = int(m.group(1))
    ct = run(f"ctest --test-dir build -R '{CTEST_FILTER}' -j2 2>&1 | tail -4")
    ctout = ct.stdout
    ctfail = 0
    m = re.search(r"(\d+) tests failed", ctout)
    if m:
        ctfail = int(m.group(1))
    m2 = re.search(r"(\d+)% tests passed, (\d+) tests failed", ctout)
    if m2:
        ctfail = int(m2.group(2))
    names = []
    if litfail:
        f = run(f"cd build && lit ir-pass/test --filter '{LIT_FILTER}' 2>&1 | grep '^  CQ IR-pass'")
        names += [l.strip() for l in f.stdout.strip().split("\n") if l.strip()]
    if ctfail:
        f = run(f"ctest --test-dir build -R '{CTEST_FILTER}' -j2 2>&1 | grep -E '^\\s*[0-9]+ - '")
        names += [l.strip() for l in f.stdout.strip().split("\n") if l.strip()]
    return (litfail + ctfail) > 0, f"lit_fail={litfail} ctest_fail={ctfail}", names


def build():
    r = run("cmake --build build -j2 --target CQPass cq-opt 2>&1 | tail -20")
    bad = re.search(r"\berror\b|\bError\b", r.stdout)
    return bad is None, r.stdout[-1500:]


def main():
    want = sys.argv[1:]
    sel = [m for m in MUTANTS if not want or m[0] in want]
    # ⚠ THE `0 mutations, MISSED 0` HOLE, CLOSED BY CONSTRUCTION (`CLAUDE.md` L10:
    # an injection matrix once printed exactly that when invoked with no fixture
    # argument, and it read like a clean run). An empty selection is a HARNESS
    # ERROR, never a pass.
    if not sel:
        print("EMPTY SELECTION: %r matches no mutant id — this is a harness "
              "error, not a clean matrix." % (want,))
        return 2
    rows = []
    missed = 0
    for mid, path, old, new, what in sel:
        src = open(path).read()
        if src.count(old) != 1:
            print(f"{mid}: EDIT-FAILED (anchor occurs {src.count(old)}x in {path})")
            rows.append((mid, "EDIT-FAILED", what, []))
            missed += 1
            continue
        open(path, "w").write(src.replace(old, new))
        try:
            ok, blog = build()
            if not ok:
                print(f"{mid}: BUILD-FAILED\n{blog}")
                rows.append((mid, "BUILD-FAILED", what, []))
                missed += 1
                continue
            caught, summary, names = gates()
            rows.append((mid, "CAUGHT" if caught else "MISSED", what, names))
            if not caught:
                missed += 1
            print(f"{mid}: {'CAUGHT' if caught else 'MISSED'}  {summary}")
            for n in names[:8]:
                print("      by", n)
        finally:
            open(path, "w").write(src)
    ok, blog = build()
    if not ok:
        print("RESTORE BUILD FAILED\n" + blog)
        return 2
    print("\n=== INJECTION MATRIX ===")
    for mid, verdict, what, names in rows:
        print(f"{mid:4} {verdict:12} {what}")
        for n in names[:4]:
            print(f"     caught by: {n}")
    print(f"\n{len(rows)} mutations, MISSED {missed}")
    return 1 if missed else 0


if __name__ == "__main__":
    sys.exit(main())
