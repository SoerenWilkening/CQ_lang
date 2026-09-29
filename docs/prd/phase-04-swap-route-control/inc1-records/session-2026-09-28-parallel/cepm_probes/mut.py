#!/usr/bin/env python3
"""mut.py [build|run] [M...] — the bd cepm / bd 3zr4 mutation matrix.
build: for each mutant, patch the source (exact string replace, asserted unique), build
       ONLY the `cq-opt` target, copy the binary to $S/cepm/mut/cq-opt.<M>, restore the
       source. The restored tree is rebuilt at the end and its hash printed (must equal
       the subject's).
run:   fixrun.py each mutant binary over every ir-pass/test/*.ll and diff its verdicts
       against the SUBJECT's ($S/cepm/mut/base.txt, from cq-opt.subj1): KILLED = a fixture
       the subject passes and the mutant fails."""
import os
import shutil
import subprocess
import sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
S = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
     "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad")
D = os.path.dirname(os.path.abspath(__file__))
MD = os.path.join(S, "cepm", "mut")
os.makedirs(MD, exist_ok=True)
SC = "ir-pass/src/SpecializeClone.cpp"
SP = "ir-pass/src/Specialization.cpp"
AC = "ir-pass/src/ArmClassify.cpp"
TP = "ir-pass/src/TaintPropagation.cpp"
RET = "  return !predictReturnTainted(Callee, Mask);\n}"
GUARD = "    if (Rec.ReturnTainted && !ResultWasTainted)\n"
MUT = {
    "N0": [(SC, "      Callee->arg_size() > kSpecMaxArity)\n    return false;",
            "      Callee->arg_size() > kSpecMaxArity ||\n      Callee->getName().size() > 1000000000u)\n    return false;")],
    "M1": [(SC, RET, "  (void)Mask;\n  return false;\n}")],
    "M2": [(SC, "  if (CI.getType()->isVoidTy() ||\n", "  if (false ||\n")],
    "M3": [(SC, '  if (N.starts_with("cq_") || N.starts_with("__cq_") || N.starts_with("cqrt_"))\n    return false;',
            "  (void)N;")],
    "M4": [(SC, "      !Callee->hasExactDefinition() || Callee->isVarArg())", "      Callee->isVarArg())")],
    "M5": [(SP, GUARD, "    if (false)\n")],
    "M6": [(SC, RET, "  (void)Mask;\n  return true;\n}")],
    "M7": [(SC, RET, "  (void)Mask;\n  return true;\n}"), (SP, GUARD, "    if (false)\n")],
    "M8": [(AC, "      Taint.Tainted.count(Call) || readsTaintedValue(*Call, Taint))",
            "      Taint.Tainted.count(Call))")],
    # ---- round 1b (the settle step, the sticky rule, LaterTaintOracle) ----
    "N1": [(TP, "    if (Flip.empty())\n      return;", "    if (Flip.empty() || Flip.size() > 1000000000u)\n      return;")],
    "R1": [(TP, "  settleSpecPredictions(ThetaFns, PhiFns, MeasureFns, out, skipRuntimeCalls);\n}",
            "  (void)0;\n}")],
    "R2": [(TP, "        if (Recorded && out.SpecPredictedClassical.lookup(CI) <", "        if (false && Recorded && out.SpecPredictedClassical.lookup(CI) <")],
    "R3": [(TP, "  settleSpecPredictions(ThetaFns, PhiFns, MeasureFns, out, skipRuntimeCalls);\n}", "  (void)0;\n}"),
           (TP, "        if (Recorded && out.SpecPredictedClassical.lookup(CI) <", "        if (false && Recorded && out.SpecPredictedClassical.lookup(CI) <")],
    "R4": [(TP, "      if (condGrows(terminatorCondition(M), Seen))\n        return true;\n      SmallPtrSet<BasicBlock *, 16> Vis;",
            "      if (false)\n        return true;\n      SmallPtrSet<BasicBlock *, 16> Vis;"),
           (TP, "        if (condGrows(terminatorCondition(X), Seen))\n          return true;\n        if (X == Top)",
            "        if (false)\n          return true;\n        if (X == Top)")],
    "R5": [(TP, "    if (T.Tainted.count(C))\n      return true;  // a tainted decider", "    if (false)\n      return true;  // a tainted decider")],
    "R6": [(TP, "      if (G && !G->isDeclaration() && calleeMayYieldQuantum(G))", "      if (false && G && !G->isDeclaration() && calleeMayYieldQuantum(G))")],
    # ---- round 2 (selectsIncoming; the callee seed removed). Base: round-2 subject. ----
    "N2": [(TP, "    if (Sets.empty())\n      return false;", "    if (Sets.empty() || Sets.size() > 1000000000u)\n      return false;")],
    "S1": [(TP, "    if (!C || !selectsIncoming(X, M))", "    if (!C)")],
    "S2": [(TP, "    if (!C || !selectsIncoming(X, M))", "    if (!C || true)")],
    "S3": [(TP, "      if (E.size() != 1)\n        return true;", "      if (E.size() > 1)\n        return true;"),
           (TP, "      if (*E.begin() != *Sets.front().begin())",
            "      if (!E.empty() && !Sets.front().empty() && *E.begin() != *Sets.front().begin())")],
    "S4": [(TP, "      if (*E.begin() != *Sets.front().begin())", "      if (false && *E.begin() != *Sets.front().begin())")],
    "S5": [(TP, "      if (E.size() != 1)\n        return true;", "      if (E.empty())\n        return true;")],
    "S6": [(TP, "  static constexpr unsigned kSelectBudget = 4096;", "  static constexpr unsigned kSelectBudget = 0;")],
    # ---- round 3: Rule-13 r2's C1 (no climb past the φ block's direct predecessors) ----
    "C1": [(TP, "        if (X == Top)\n          continue;\n        WL.append(pred_begin(X), pred_end(X));",
            "        if (X == Top)\n          continue;\n        (void)0;")],
    # R8: re-add ONLY the indirect-call half of the removed seed (Rule-13 r2 F-r2-4)
    "R8": [(TP, "    for (Value *Op : I->operands())\n      if (walk(Op, Seen))\n        return true;\n    return false;\n  }\n};",
            "    if (auto *CB = dyn_cast<CallBase>(I))\n"
            "      if (!CB->getCalledFunction() && !CB->isInlineAsm())\n"
            "        return true;\n"
            "    for (Value *Op : I->operands())\n      if (walk(Op, Seen))\n        return true;\n    return false;\n  }\n};")],
    "R7": [(TP, "    for (Value *Op : I->operands())\n      if (walk(Op, Seen))\n        return true;\n    return false;\n  }\n};",
            "    if (auto *CB = dyn_cast<CallBase>(I))\n"
            "      if (const Function *G = CB->getCalledFunction(); G && !G->isDeclaration())\n"
            "        for (const BasicBlock &BB : *G)\n"
            "          for (const Instruction &J : BB)\n"
            "            if (const auto *CJ = dyn_cast<CallInst>(&J);\n"
            "                CJ && T.ThetaCalls.contains(const_cast<CallInst *>(CJ)))\n"
            "              return true;\n"
            "    for (Value *Op : I->operands())\n      if (walk(Op, Seen))\n        return true;\n    return false;\n  }\n};")],
}


def build(names):
    for m in names:
        saved = {}
        for f, old, new in MUT[m]:
            p = os.path.join(W, f)
            s = saved.get(p) or open(p).read()
            saved.setdefault(p, s)
            cur = open(p).read()
            assert cur.count(old) == 1, (m, f, cur.count(old))
            open(p, "w").write(cur.replace(old, new))
        try:
            r = subprocess.run(["cmake", "--build", os.path.join(W, "build"), "--target", "cq-opt", "-j4"],
                               capture_output=True, text=True)
            if r.returncode:
                print(m, "BUILD FAILED\n", r.stdout[-3000:], r.stderr[-2000:])
            else:
                shutil.copyfile(os.path.join(W, "build/ir-pass/cq-opt"), os.path.join(MD, "cq-opt." + m))
                os.chmod(os.path.join(MD, "cq-opt." + m), 0o755)
                h = subprocess.run(["shasum", "-a", "256", os.path.join(MD, "cq-opt." + m)],
                                   capture_output=True, text=True).stdout[:24]
                print(m, "built", h, flush=True)
        finally:
            for p, s in saved.items():
                open(p, "w").write(s)
    r = subprocess.run(["cmake", "--build", os.path.join(W, "build"), "--target", "CQPass", "cq-opt",
                        "cq-opt-debugalloc", "cq-scrub-selftest", "-j4"], capture_output=True, text=True)
    h = subprocess.run(["shasum", "-a", "256", os.path.join(W, "build/ir-pass/cq-opt")],
                       capture_output=True, text=True).stdout[:24]
    print("restored build rc", r.returncode, "cq-opt", h)


def verdicts(path):
    return dict(l.split()[::-1] for l in open(path) if l.strip())


def run(names):
    """`MUT_SUBSET=<file>` restricts the fixtures to that list (subset.py); verdict
    files are written as <M>.txt (whole corpus) or <M>.sub.txt (subset). An existing
    verdict file is REPORTED, not re-run."""
    import glob
    sub = os.environ.get("MUT_SUBSET")
    fx = ([l.strip() for l in open(sub) if l.strip()] if sub
          else sorted(glob.glob(os.path.join(W, "ir-pass/test/*.ll"))))
    tag = ".sub.txt" if sub else ".txt"
    # MUT_BASE=<tag>: the subject binary is $S/cepm/cq-opt.<tag>, its verdicts base.<tag>.txt
    # (default: subj1 / base.txt, round 1).
    btag = os.environ.get("MUT_BASE")
    base = os.path.join(MD, f"base.{btag}.txt" if btag else "base.txt")
    if not os.path.exists(base):
        subprocess.run(["python3", os.path.join(D, "fixrun.py"),
                        os.path.join(S, "cepm/cq-opt." + (btag or "subj1")), base] + fx)
    b = verdicts(base)
    if sub:
        keep = {os.path.basename(f) for f in fx}
        b = {k: x for k, x in b.items() if k in keep}
    print(f"denominator: {len(b)} fixtures ({'subset ' + sub if sub else 'whole corpus'})", flush=True)
    for m in names:
        out = os.path.join(MD, m + tag)
        if not os.path.exists(out):
            subprocess.run(["python3", os.path.join(D, "fixrun.py"), os.path.join(MD, "cq-opt." + m), out] + fx)
        v = verdicts(out)
        killed = sorted(k for k in b if b[k] in ("PASS", "XFAIL") and v.get(k) != b[k])
        other = sorted(k for k in b if b[k] not in ("PASS", "XFAIL") and v.get(k) != b[k])
        print(f"{m}: {'KILLED' if killed else 'MISSED'} ({len(killed)} fixtures)"
              + (f"; other moves {len(other)}" if other else ""))
        for k in killed[:40]:
            print("   ", k, b[k], "->", v.get(k))


if __name__ == "__main__":
    mode = sys.argv[1]
    names = sys.argv[2:] or list(MUT)
    (build if mode == "build" else run)(names)
