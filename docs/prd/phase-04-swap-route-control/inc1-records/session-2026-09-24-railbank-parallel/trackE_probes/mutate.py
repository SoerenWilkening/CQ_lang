#!/usr/bin/env python3
"""xdu2.13 source-mutation harness (scratch, never committed).

For each mutant: apply ONE exact-text substitution (must match exactly once),
rebuild CQPass + cq-opt, run the OWNED tests only, record which moved vs the
baseline, restore the file byte-for-byte, and verify the restore. The NULL
mutant (a comment-only edit) runs FIRST and must move 0 tests.
usage: mutate.py [ID ...]   (default: all)
"""
import json
import pathlib
import re
import subprocess
import sys

W = pathlib.Path(__file__).resolve().parent.parent
B = W / "build"
LIT_FILTER = "condtree_classical_leaf|row13_hybrid|predmux_guarded_vla|cond_tree|condtree|select_classical_leaf|taint_reject_quantum_return|taint_accept_classical_decl|spec_reject_cq_primitive|offchain_ret|classical_call_arm"
CTEST_RE = ("^e2e-condtree-classical-leaf-matrix$|^e2e-slice-condtree-classical-leaf$|"
            "^e2e-railbank-dynamic-admission-matrix$|^e2e-railbank-guarded-vla-matrix$")

CL = "ir-pass/src/CondLiteral.cpp"
SC = "ir-pass/src/SelectClassify.cpp"
SM = "ir-pass/src/SelectMergeEmit.cpp"
CE = "ir-pass/src/CondTreeEmit.cpp"
CS = "ir-pass/src/CondTreeStrip.cpp"
PM = "ir-pass/src/PredMuxFlatten.cpp"
QP = "ir-pass/src/CQLoweringPass.cpp"
TP = "ir-pass/src/TaintPropagation.cpp"

MUTANTS = [
 ("NULL", CL, "namespace cq {\n\nnamespace {", "namespace cq {\n// null mutant\nnamespace {", "null control"),
 ("M1", CL, "|| isa<Constant>(V))\n    return false;", ")\n    return false;", "(a) Constant literal admitted"),
 ("M2", CL, "  if (taint.Tainted.count(V))\n    return false;", "", "(b) tainted child admitted as literal"),
 ("M3", CL, "    if (I->getMetadata(kPredMuxPredictedMD))\n      return false;", "    (void)I;", "(c) rule-(B) mark ignored"),
 ("M4", CL, "  if (F && F->getMetadata(kPredMuxPredictedOverflowMD))\n    return false;", "", "(c) overflow mark ignored"),
 ("M5", CL, "  else\n    return false;", "", "(a) non-Instruction/Argument admitted"),
 ("M1M5", CL, "|| isa<Constant>(V))\n    return false;\n  Function *F = nullptr;\n  if (auto *I = dyn_cast<Instruction>(V))\n    F = I->getFunction();\n  else if (auto *A = dyn_cast<Argument>(V))\n    F = A->getParent();\n  else\n    return false;",
  ")\n    return false;\n  Function *F = nullptr;\n  if (auto *I = dyn_cast<Instruction>(V))\n    F = I->getFunction();\n  else if (auto *A = dyn_cast<Argument>(V))\n    F = A->getParent();", "(a) BOTH Constant refusals dropped"),
 ("M6", SC, "IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeL)", "IsLiteral && IsLiteral(NodeL)", "xor node admits a left literal"),
 ("M6b", SC, "IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeR)", "IsLiteral && IsLiteral(NodeR)", "xor node admits a right literal"),
 ("M7", SC, "    if (LitL && LitR)\n      return false;\n", "", "two-literal node admitted"),
 ("M8", SC, "    if (isCondRailLeaf(LN.Sibling) || isCondRailPhiShape(LN.Sibling))\n      return diagnoseUnderControl(Sel, \"control flow\");", "", "rail-sibling classifier refusal dropped"),
 ("M9", SC, "  if (!Tree.LiteralLeaves.empty() && selReachesRotationArg1(Sel, taint))\n    return diagnoseUnderControl(Sel, \"control flow\");", "", "angle-select literal guard dropped"),
 ("M10", SC, "    R.CondLiterals.emplace_back(Lit);", "", "literal commit to the region dropped"),
 ("M11", SM, "    return !taint.Tainted.count(V) &&\n", "    return ", "emitter taint re-check dropped"),
 ("M12", SM, " ||\n      Tree.LiteralLeaves.size() != R.CondLiterals.size()) {", ") {", "emitter size-mismatch refusal dropped"),
 ("M13", CE, "if (isLit(Q) || !N.L || isRailFlag(Q))", "if (isLit(Q) || !N.L)", "emitter rail-sibling refusal dropped"),
 ("M14", CE, "N.Tpl = emitCondLiteralNode(B, Opc, N.L, isLit(L) ? L : R, wd, taint, DL);", "N.Tpl = emitCondLiteralNode(B, Opc == Instruction::And ? Instruction::Or : Instruction::And, N.L, isLit(L) ? L : R, wd, taint, DL);", "and/or template swapped"),
 ("M15", CS, "      stripCondLiteralNode(B, N.Tpl, wd, taint);\n", "", "mixed-node strip dropped (no _unc, no free)"),
 ("M16", CL, "  CallInst *Free = B.CreateCall(wd.freeFn(), {Tpl});\n  if (DebugLoc DL = Tpl->getDebugLoc())\n    Free->setDebugLoc(DL);", "", "mixed-node free dropped"),
 ("M17", CL, "  if (!emitInverseCall(B, Tpl, wd, /*CurHandle=*/nullptr, &taint.SpineOps))\n    return;", "", "mixed-node _unc dropped (dirty free)"),
 ("M18", CL, "    if (taint.Tainted.count(G->getArgOperand(1))) {", "    if (false) {", "round-2 re-ask never fires"),
 ("M19", CL, "  taint.CondLiteralGates.emplace_back(G);\n", "", "round-2 record dropped"),
 ("M20", CL, "        I.setMetadata(Kind, nullptr);", "        (void)I;", "rule-(B) marks never stripped"),
 ("M21", PM, "          R.PredictedConds.emplace_back(BI->getCondition());", "          ;", "rule-(B) record dropped at E6"),
 ("M22", PM, "      for (const WeakVH &PC : R.PredictedConds)\n        markPredictedTaintCone(PC);", "", "claim-time mark dropped"),
 ("M23", PM, "        if (static_cast<Value *>(PC) == BI->getCondition())\n          markPredictedTaintCone(L);", "        (void)PC;", "edge-literal mark dropped"),
 ("M24", CE, "    if (!isLit(R))\n      Stack.push_back({R, false});\n    if (!isLit(L))\n      Stack.push_back({L, false});", "    Stack.push_back({R, false});\n    Stack.push_back({L, false});", "emitter walks into literal children"),
 ("M25", SC, "    if (!LitR)\n      Stack.push_back({NodeR, false});\n    if (!LitL)\n      Stack.push_back({NodeL, false});", "    Stack.push_back({NodeR, false});\n    Stack.push_back({NodeL, false});", "classifier walks into literal children"),
 ("M6x", [(SC, "IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeL)", "IsLiteral && IsLiteral(NodeL)"),
          (SC, "IsLiteral && NodeOpc != Instruction::Xor && IsLiteral(NodeR)", "IsLiteral && IsLiteral(NodeR)"),
          (CL, "  if (Opc != Instruction::And && Opc != Instruction::Or)\n    return nullptr;\n", "")], None, None, "xor literal: classifier AND emitter refusals dropped"),
 ("M8x", [(SC, "    if (isCondRailLeaf(LN.Sibling) || isCondRailPhiShape(LN.Sibling))\n      return diagnoseUnderControl(Sel, \"control flow\");", ""),
          (CE, "if (isLit(Q) || !N.L || isRailFlag(Q))", "if (isLit(Q) || !N.L)")], None, None, "rail sibling: classifier AND emitter refusals dropped"),
 ("M32", CL, "  G->addParamAttr(1, Attribute::ZExt);", "", "F-2 zeroext on the forward dropped"),
 ("M33", CL, "      Unc->addParamAttr(2, Attribute::ZExt);", "      (void)Unc;", "F-2 zeroext on the _unc dropped"),
 ("M34", TP, "        if (out.Tainted.insert(CB).second) {", "        if (false) {", "3jru: call sites of a register-returning fn never tainted"),
 ("M35", [(QP, "  declineQuantumReturnCalls(M, taint);\n", "")], None, None, "3jru: refusal slot dropped (both entry points)"),
 ("M36", TP, "      auto *I = dyn_cast<Instruction>(U);\n      if (!I) {", "      auto *I = dyn_cast<CallBase>(U);\n      if (!I) { continue;", "3jru: refusal ignores non-call uses (address taken)"),
 ("M37", TP, "  for (bool Changed = true; Changed;) {\n    Changed = false;", "  for (bool Changed = true, Once = true; Once; Once = false) {\n    Changed = false; (void)Changed;", "3jru: fixpoint runs one pass only"),
 ("M38", TP, "        if (taint.Tainted.count(RV))\n          return true;\n  return false;\n}\n\n// bd `test_C_libtooling-3jru` — the LOUD", "        if (taint.Tainted.count(RV))\n          return false;\n  return false;\n}\n\n// bd `test_C_libtooling-3jru` — the LOUD", "3jru: functionReturnsTainted always false"),
 ("M26", PM, "        if (!ClaimAll && !Taint.Tainted.count(BI->getCondition()) &&", "        if (!Taint.Tainted.count(BI->getCondition()) &&", "rule-(B) record also in clone mode"),
]


def sh(cmd, **kw):
    return subprocess.run(cmd, shell=True, cwd=W, text=True, capture_output=True, **kw)


def build():
    r = sh("cmake --build build -j6 --target CQPass cq-opt 2>&1 | grep -E ' error' ; true")
    if r.stdout.strip():
        return "BUILD-ERROR: " + r.stdout.strip()[:300]
    return None


def run_tests():
    res = {}
    r = sh(f"cd build && lit -v ir-pass/test --filter '{LIT_FILTER}'")
    for m in re.finditer(r"^(PASS|FAIL|XFAIL|XPASS|UNRESOLVED): CQ IR-pass :: (\S+)", r.stdout, re.M):
        res["lit:" + m.group(2)] = m.group(1)
    r = sh(f"ctest --test-dir build -R '{CTEST_RE}'")
    for m in re.finditer(r"Test\s+#\d+: (\S+) \.+\**\s*(Passed|Failed|\*\*\*Failed)", r.stdout):
        res["ctest:" + m.group(1)] = "PASS" if m.group(2) == "Passed" else "FAIL"
    return res


def main():
    ids = sys.argv[1:]
    muts = [m for m in MUTANTS if not ids or m[0] in ids]
    base_path = W / "te_scratch" / "mut_baseline.json"
    if not base_path.exists():
        print("baseline build + run ...", flush=True)
        e = build()
        assert not e, e
        base = run_tests()
        base_path.write_text(json.dumps(base, indent=1))
    base = json.loads(base_path.read_text())
    print(f"baseline denominators: {sum(k.startswith('lit:') for k in base)} lit, "
          f"{sum(k.startswith('ctest:') for k in base)} ctest; "
          f"{sum(v != 'PASS' for v in base.values())} non-PASS", flush=True)
    out = []
    for mid, f, old, new, desc in muts:
        subs = f if isinstance(f, list) else [(f, old, new)]
        origs = {}
        bad = False
        for sf, so, sn in subs:
            sp = W / sf
            if sf not in origs:
                origs[sf] = sp.read_text()
            cur = sp.read_text()
            # list-form mutants may name an anchor that occurs in BOTH entry
            # points (M35); every occurrence is mutated, and 0 is an error.
            if cur.count(so) < 1 or (not isinstance(f, list) and cur.count(so) != 1):
                bad = True
                break
            sp.write_text(cur.replace(so, sn))
        if bad:
            for sf, o in origs.items():
                (W / sf).write_text(o)
            out.append((mid, "HARNESS-ERROR", "anchor", desc))
            print(mid, "HARNESS-ERROR anchor", flush=True)
            continue
        try:
            e = build()
            if e:
                verdict, movers = "KILLED(build)", [e]
            else:
                res = run_tests()
                if len(res) != len(base):
                    movers = [f"denominator {len(res)} != {len(base)}"]
                else:
                    movers = sorted(k for k in base if res.get(k) != base[k])
                verdict = "KILLED" if movers else "MISSED"
        finally:
            for sf, o in origs.items():
                (W / sf).write_text(o)
        for sf, o in origs.items():
            assert (W / sf).read_text() == o
        out.append((mid, verdict, movers, desc))
        print(mid, verdict, len(movers), desc, movers[:6], flush=True)
    e = build()
    assert not e, e
    log = W / "te_scratch" / "mut_results.json"
    prev = json.loads(log.read_text()) if log.exists() else {}
    for mid, v, mv, d in out:
        prev[mid] = {"verdict": v, "movers": mv, "desc": d}
    log.write_text(json.dumps(prev, indent=1))


if __name__ == "__main__":
    main()
