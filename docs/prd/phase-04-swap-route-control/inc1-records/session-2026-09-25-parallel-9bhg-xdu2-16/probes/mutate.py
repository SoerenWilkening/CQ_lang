#!/usr/bin/env python3
"""Source-mutation matrix for bd 9bhg. For each mutant: apply the textual patch(es)
(each pattern must occur EXACTLY the stated number of times, else the mutant is
reported INVALID and not run), rebuild `cq-opt`, run the FULL ir-pass lit suite,
record the failing fixtures, restore the pristine sources. The first mutant is a
NULL (a semantically dead change that still alters the binary): it must move 0.

  mutate.py [NAME ...]      (default: all)
"""
import pathlib
import re
import shutil
import subprocess
import sys

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
P = pathlib.Path(__file__).resolve().parent
TP = "ir-pass/src/TaintPropagation.cpp"
SP = "ir-pass/src/Specialization.cpp"
CQ = "ir-pass/src/CQLoweringPass.cpp"
FILES = [TP, SP, CQ]
SAVE = P / "pristine"

MUTANTS = [
    ("N0-null", [(TP, "  if (Roots.empty())\n    return false;\n  SmallPtrSet<const Value *, 8> Keep;",
                  "  if (Roots.empty() || Roots.size() > 1000000000u)\n    return false;\n  SmallPtrSet<const Value *, 8> Keep;", 1)]),
    ("M1-drain-never-defers", [(TP, "      if (returnTaintIsSpecProvisional(*F, out))\n        continue;  // deferred",
                                "      if (false)\n        continue;  // deferred", 1)]),
    ("M2-drain-always-defers", [(TP, "      if (returnTaintIsSpecProvisional(*F, out))\n        continue;  // deferred",
                                 "      if (true)\n        continue;  // deferred", 1)]),
    ("M3-early-no-skip", [(TP, "if (SkipSpecProvisional && returnTaintIsSpecProvisional(F, taint))",
                           "if (false && SkipSpecProvisional && returnTaintIsSpecProvisional(F, taint))", 1)]),
    ("M4-no-late-slot", [(CQ, "if (declineQuantumReturnCalls(M, taint, /*SkipSpecProvisional=*/false))",
                          "if (false && declineQuantumReturnCalls(M, taint, /*SkipSpecProvisional=*/false))", 2)]),
    ("M5-pred-no-theta-keep", [(TP, "  for (const CallInst *Theta : taint.ThetaCalls)\n    Keep.insert(Theta);\n  SmallVector<Value *, 16> Cone;",
                                "  SmallVector<Value *, 16> Cone;", 1)]),
    ("M6-pred-some-not-every", [(TP, "        if (!InCone.count(RV))\n          return false;  // this return is quantum whatever the clones prove.",
                                 "        if (InCone.count(RV))\n          return true;", 1),
                                (TP, "  return AnyTainted;\n}", "  (void)AnyTainted;\n  return false;\n}", 1)]),
    ("M7-pred-roots-any-tainted-call", [(TP, "      if (llvm::any_of(CB->args(), [&](const Use &A) {\n            return taint.Tainted.count(A.get()) != 0;\n          }))\n        Roots.push_back(CBV);",
                                         "      Roots.push_back(CBV);", 1)]),
    ("M8-spec-no-mask-recompute", [(SP, "    SpecMask Now = taintArgMask(Cand.Site, taint);",
                                    "    SpecMask Now = Cand.Mask;", 1)]),
    ("M9-spec-no-mask0-skip", [(SP, "      if (Now == 0 && !taint.Tainted.count(Cand.Site))\n        continue;",
                                "      if (false)\n        continue;", 1)]),
    ("M10-spec-no-reclassify", [(SP, "        SpecReject Why = classifyCandidate(ReCand, taint, wd, Where, Kind);",
                                 "        (void)ReCand;\n        SpecReject Why = SpecReject::Accept;", 1)]),
    ("M11-spec-sources-not-grown", [(SP, "      TaintedSources.insert(Cand.Site);\n", "", 1)]),
    ("M12-cone-ignores-keep", [(TP, "      if (Keep.count(I))\n        continue;", "      if (false)\n        continue;", 1)]),
    ("M13-cone-ignores-other-operand", [(TP, "      if (HasOtherTaintedOperand)\n        continue;  // tainted via another path — keep.",
                                         "      (void)HasOtherTaintedOperand;", 1)]),
    ("M14-fence-mask-check-off", [(TP, "            if (CB->getArgOperand(A) == V && ((It->second >> A) & 1))",
                                   "            if (CB->getArgOperand(A) == V)", 1)]),
    ("M15-fence-clone-reader-off", [(TP, "        auto It = taint.SpecHandleArgMask.find(Callee);\n        if (It != taint.SpecHandleArgMask.end())",
                                     "        auto It = taint.SpecHandleArgMask.end();\n        if (It != taint.SpecHandleArgMask.end())", 1)]),
    ("M16-early-skip-no-caller-check", [(TP, "                 taint.Tainted.count(CB);\n        }))\n      continue;",
                                         "                 taint.Tainted.count(CB) && false;\n        }))\n      continue;", 1)]),
    ("MORD-late-ask-before-d88e", [
        (CQ, "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();",
         "  if (declineQuantumReturnCalls(M, taint, /*SkipSpecProvisional=*/false))\n"
         "    return PreservedAnalyses::none();\n"
         "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();", 1),
        (CQ, "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return false;",
         "  if (declineQuantumReturnCalls(M, taint, /*SkipSpecProvisional=*/false))\n"
         "    return false;\n"
         "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return false;", 1)]),
    ("M17-spec-no-reinsert", [(SP, "      taint.Tainted.insert(Cand.Site);\n      TaintedSources.insert(Cand.Site);",
                               "      TaintedSources.insert(Cand.Site);", 1)]),
    ("M18-spec-no-oldsite-scrub", [(SP, "    if (Cand.Site != OldSite) {\n      taint.Tainted.erase(OldSite);",
                                    "    if (Cand.Site != OldSite && false) {\n      taint.Tainted.erase(OldSite);", 1)]),
]


def restore():
    for f in FILES:
        shutil.copyfile(SAVE / pathlib.Path(f).name, W / f)


def build():
    r = subprocess.run(["cmake", "--build", str(W / "build"), "--target", "cq-opt", "-j8"],
                       capture_output=True, text=True)
    return r.returncode == 0, r.stdout[-2000:] + r.stderr[-2000:]


def lit():
    r = subprocess.run(["lit", "ir-pass/test", "-q"], cwd=W / "build", capture_output=True,
                       text=True)
    fails = sorted(set(re.findall(r"CQ IR-pass :: (\S+\.ll)", r.stdout)))
    tot = re.search(r"Total Discovered Tests: (\d+)", r.stdout + r.stderr)
    return fails, (tot.group(1) if tot else "?"), r.stdout


if not SAVE.exists():
    SAVE.mkdir()
    for f in FILES:
        shutil.copyfile(W / f, SAVE / pathlib.Path(f).name)
want = set(sys.argv[1:])
try:
    for name, patches in MUTANTS:
        if want and name not in want:
            continue
        restore()
        ok = True
        for f, old, new, n in patches:
            src = (W / f).read_text()
            if src.count(old) != n:
                print(f"{name}: INVALID (pattern count {src.count(old)} != {n} in {f})", flush=True)
                ok = False
                break
            (W / f).write_text(src.replace(old, new))
        if not ok:
            continue
        good, log = build()
        if not good:
            print(f"{name}: BUILD FAILED\n{log}", flush=True)
            continue
        fails, tot, out = lit()
        verdict = "KILLED" if fails else "MISSED"
        print(f"{name}: {verdict} ({len(fails)} of {tot} lit fail)", flush=True)
        for x in fails:
            print(f"    {x}", flush=True)
finally:
    restore()
    good, log = build()
    print("restored pristine sources; rebuild", "ok" if good else "FAILED", flush=True)
