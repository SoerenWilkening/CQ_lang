#!/usr/bin/env python3
"""Mutation matrix for bd xdu2.16's nulled-root block in LoopLowering.cpp.
One mutant per run: exact-text substitution (anchor must match EXACTLY once),
rebuild CQPass + cq-opt, run the owned lit fixtures + owned ctest entries,
restore the file, rebuild, and ASSERT the restored binary hash equals baseline.
The NULL mutant (comment-only) runs FIRST and must move 0 tests.
Usage: mutate.py [MUTANT_ID ...]   (default: all, NULL first)"""
import hashlib, json, os, re, subprocess, sys
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df"
SRC = W + "/ir-pass/src/LoopLowering.cpp"
OPT = W + "/build/ir-pass/cq-opt"
LIT_FILTER = "loop_condtree_select|row13_hybrid|loop_pairing|condtree_classical_leaf|loop_carried_handle"
CTEST_RE = "condtree-select-hoisted|condtree-classical-leaf-matrix|railbank-dynamic-admission-matrix|railbank-guarded-vla-matrix"
OUT = os.path.dirname(os.path.abspath(__file__)) + "/mut"
os.makedirs(OUT, exist_ok=True)

A_IF = "      if (Nulled) {\n        SmallPtrSet<Value *, 4> Fresh;\n"
A_IRR = ("        if (!invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Fresh,\n"
         "                                    /*CarriedRoots=*/nullptr)) {\n")
A_RLQ = ("        if (!railLocalQualifies(L, taint, LI, GateCalls, Fresh, AnyLocal,\n"
         "                                &WhyNot)) {\n")
MUTANTS = {
    "M0_null": ("      // WHAT THIS REPLACED. Until xdu2.16 a nulled root was refused HERE,",
                "      // WHAT THIS REPLACED. Until xdu2.16 a nulled root was refused HERE, "),
    "M1_withdraw": (A_IF, "      if (Nulled) {\n        continue;\n        SmallPtrSet<Value *, 4> Fresh;\n"),
    "M2_no_totality": (A_IRR, A_IRR.replace("nullptr)) {", "nullptr)) && false) {").replace("if (!invariant", "if ((!invariant")),
    "M3_union_survivors": (A_RLQ, "        Fresh.insert(Roots.begin(), Roots.end());\n" + A_RLQ),
    "M4_old_refusal": (A_IF, "      if (Nulled) {\n        diagnose(L->getHeader()->getTerminator(), kMsgRound1GrantFalsified);\n        return;\n        SmallPtrSet<Value *, 4> Fresh;\n"),
    "M5_skip_rlq": (A_RLQ, A_RLQ.replace("if (!railLocalQualifies", "if (false && !railLocalQualifies")),
    "M6_as_intact": (A_IF, A_IF.replace("if (Nulled) {", "if (false && Nulled) {")),
}

def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)

def build():
    p = sh(["cmake", "--build", W + "/build", "--target", "CQPass", "cq-opt", "-j8"])
    if p.returncode:
        print(p.stdout[-3000:], p.stderr[-3000:]); raise SystemExit("BUILD FAILED")
    return hashlib.sha256(open(OPT, "rb").read()).hexdigest()[:16]

def run_tests():
    res = {}
    p = sh(["lit", "-v", W + "/build/ir-pass/test", "--filter", LIT_FILTER])
    for line in p.stdout.splitlines():
        m = re.match(r"^(PASS|FAIL|XFAIL|XPASS|UNRESOLVED): CQ IR-pass :: (\S+)", line)
        if m:
            res["lit:" + m.group(2)] = m.group(1)
    p = sh(["ctest", "--test-dir", W + "/build", "-j6", "-R", CTEST_RE])
    for line in p.stdout.splitlines():
        m = re.search(r"Test\s+#\d+: (\S+) \.+\s*(\*\*\*Failed|Passed)", line)
        if m:
            res["ctest:" + m.group(1)] = "PASS" if m.group(2) == "Passed" else "FAIL"
    return res

orig = open(SRC).read()
base_hash = hashlib.sha256(open(OPT, "rb").read()).hexdigest()[:16]
bl_path = OUT + "/baseline.json"
if not os.path.exists(bl_path):
    base = run_tests()
    json.dump({"hash": base_hash, "res": base}, open(bl_path, "w"), indent=1)
else:
    b = json.load(open(bl_path)); base = b["res"]
    assert b["hash"] == base_hash, "baseline was taken on a different binary"
nonpass = [k for k, v in base.items() if v != "PASS"]
print(f"baseline binary {base_hash}: {len(base)} tests ({sum(1 for k in base if k.startswith('lit:'))} lit + "
      f"{sum(1 for k in base if k.startswith('ctest:'))} ctest), non-PASS at baseline: {nonpass}", flush=True)
ids = sys.argv[1:] or list(MUTANTS)
results = {}
try:
    for mid in ids:
        a, b = MUTANTS[mid]
        n = orig.count(a)
        assert n == 1, f"{mid}: anchor matches {n} times"
        open(SRC, "w").write(orig.replace(a, b))
        h = build()
        r = run_tests()
        movers = sorted(k for k in set(base) | set(r) if base.get(k) != r.get(k))
        results[mid] = {"hash": h, "movers": movers}
        verdict = "KILLED" if movers else "MISSED"
        if mid == "M0_null":
            verdict = "NULL-OK" if not movers else "NULL-MOVED(!)"
        print(f"{mid:20s} bin={h} {verdict} {len(movers)} mover(s): {movers}", flush=True)
        open(SRC, "w").write(orig)
finally:
    open(SRC, "w").write(orig)
    h = build()
    print(f"restored: {h} (baseline {base_hash}) {'OK' if h == base_hash else 'MISMATCH!'}")
    json.dump(results, open(OUT + "/results.json", "w"), indent=1)
