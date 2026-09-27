#!/usr/bin/env python3
"""mut.py NAME : apply mutant NAME to the private worktree, build cq-opt, run full lit
and the probe list, then restore. Prints the lit failures and the probe verdict moves
vs the subject binary. Null control: NAME=N0 (a no-op textual edit)."""
import subprocess, sys, pathlib, hashlib
S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
WT = S / "rev9A_wt"
SUBJ = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/build/ir-pass/cq-opt"
CQP = WT / "ir-pass/src/CQLoweringPass.cpp"
TP = WT / "ir-pass/src/TaintPropagation.cpp"
SP = WT / "ir-pass/src/Specialization.cpp"
LATE = "  if (declineQuantumReturnCalls(M, taint, /*SkipSpecProvisional=*/false))\n    return PreservedAnalyses::none();\n"
MUTS = {
 "N0": [(TP, "  if (Roots.empty())\n    return false;\n", "  if (Roots.empty() || Roots.size() > 1000000000u)\n    return false;\n", 1)],
 # late ask moved after lowerMeasures (run() only; runOnFunction is a dead shim)
 "M4": [(CQP, LATE, "", 1)],
 "MSLOT": [(CQP, LATE, "", 1),
           (CQP, "  lowerMeasures(M, wd, taint);\n", "  lowerMeasures(M, wd, taint);\n" + LATE, -1)],
 # early skip premise conjunct removed
 "M16": [(TP, "          return CB && CB->getCalledOperand() == &F && !CB->use_empty() &&\n                 taint.Tainted.count(CB);", "          return false && CB && CB->getCalledOperand() == &F && !CB->use_empty() &&\n                 taint.Tainted.count(CB);", 1)],
 # drain: deferred functions are dropped after the first decision (no re-decision)
 "MRED": [(TP, "      if (returnTaintIsSpecProvisional(*F, out))\n        continue;  // deferred: its callers do not see this taint.\n",
               "      if (returnTaintIsSpecProvisional(*F, out)) {\n        Decided.push_back(F);\n        continue;\n      }\n", 1)],
 # early ask: skip on the premise conjunct alone (no predicate re-ask)
 "MNOREASK": [(TP, "    if (SkipSpecProvisional && returnTaintIsSpecProvisional(F, taint) &&\n",
                   "    if (SkipSpecProvisional &&\n", 1)],
 # M11: genuine sites not added as keep roots at resolution
 "M11": [(SP, "      taint.Tainted.insert(Cand.Site);\n      TaintedSources.insert(Cand.Site);\n",
              "      taint.Tainted.insert(Cand.Site);\n", 1)],
}
name = sys.argv[1]
probes = sys.argv[2:]
orig = {}
try:
    for (f, a, b, n) in MUTS[name]:
        t = orig.get(f) or f.read_text()
        orig.setdefault(f, t)
        cur = f.read_text()
        if n == -1:
            assert cur.count(a) >= 1, (name, f, cur.count(a))
            f.write_text(cur.replace(a, b, 1))
        else:
            assert cur.count(a) == n, (name, f, cur.count(a))
            f.write_text(cur.replace(a, b))
    r = subprocess.run(["cmake", "--build", str(WT / "build"), "--target", "CQPass", "cq-opt", "-j6"], capture_output=True, text=True)
    if r.returncode:
        print("BUILD FAILED"); print(r.stdout[-3000:]); print(r.stderr[-3000:]); sys.exit(2)
    h = hashlib.sha256((WT / "build/ir-pass/cq-opt").read_bytes()).hexdigest()[:16]
    print(f"mutant {name}: cq-opt {h}")
    r = subprocess.run(["lit", "-s", str(WT / "build/ir-pass/test")], capture_output=True, text=True, cwd=str(WT / "build"))
    out = r.stdout + r.stderr
    fails = [l for l in out.splitlines() if l.startswith(("FAIL:", "XPASS:", "UNRESOLVED:"))]
    tot = [l for l in out.splitlines() if l.strip().startswith(("Total Discovered", "Passed", "Failed", "Expectedly", "Unresolved"))]
    print(f"lit rc={r.returncode}")
    print("lit:", " | ".join(x.strip() for x in tot))
    print(f"lit failures: {len(fails)}")
    for l in fails: print("  ", l)
    moved = 0
    for p in probes:
        rs = []
        for b in (SUBJ, str(WT / "build/ir-pass/cq-opt")):
            q = subprocess.run([b, "-passes=cq-lowering", "-S", p, "-o", "-"], capture_output=True)
            err = next((l.split("error:",1)[1].strip() for l in q.stderr.decode(errors="replace").splitlines() if "error:" in l), "")
            rs.append((q.returncode, hashlib.sha256(q.stdout).hexdigest()[:12], err))
        if rs[0] != rs[1]:
            moved += 1
            print(f"  PROBE MOVE {pathlib.Path(p).name}: subj rc={rs[0][0]} {rs[0][2][:90]} | mut rc={rs[1][0]} {rs[1][2][:90]}")
    print(f"probes: {len(probes)} run, {moved} moved")
finally:
    for f, t in orig.items():
        f.write_text(t)
    subprocess.run(["cmake", "--build", str(WT / "build"), "--target", "CQPass", "cq-opt", "-j6"], capture_output=True)
    h = hashlib.sha256((WT / "build/ir-pass/cq-opt").read_bytes()).hexdigest()[:16]
    print(f"restored: cq-opt {h}")
