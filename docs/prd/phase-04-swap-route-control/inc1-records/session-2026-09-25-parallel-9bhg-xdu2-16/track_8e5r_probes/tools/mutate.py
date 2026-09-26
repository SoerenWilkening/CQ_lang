#!/usr/bin/env python3
"""mutate.py [--only NAME,...] [--no-corpus] — the bd 8e5r mutation matrix.

For each mutant: restore the PRISTINE copies of the mutated files in mut_src,
apply the mutation (asserting the anchor occurs exactly as expected), rebuild
cq-opt + cq-scrub-selftest in mut_build, snapshot the binaries, and run every
detector:
  D1 lit spec_scrub_dangling_key_clone_classical_mul (x3)
  D2 lit the four bd um24 fixtures (x3)
  D3 e2e-spec-scrub-dangling-key under lifo (x3)
  D4 cq-scrub-selftest under lifo and under the system allocator
  D5 taintset_scrub_guard.py on the mutated source
  D6 corpus A/B (all lit + e2e stage-1 + alias families) mutant:lifo vs subject:lifo
The null mutant M0 must move NOTHING; its denominator is printed like any other."""
import hashlib, os, shutil, subprocess, sys

T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r"
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"
SRC = f"{T}/mut_src"
BLD = f"{T}/mut_build"
HDR = "ir-pass/include/ScrubOnDelete.h"
LL = "ir-pass/src/LoopLowering.cpp"
FILES = [HDR, LL]

OLD_SCAN = """    bool AnyTainted = false;
    for (Value *V : taint.Tainted)
      if (auto *I = dyn_cast<Instruction>(V))
        if (I->getFunction() == &F) {
          AnyTainted = true;
          break;
        }
    if (!AnyTainted)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // ScalarEvolution"""
NEW_SCAN_TAIL = """    bool AnyTainted = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB)
        if (taint.Tainted.count(&I)) {
          AnyTainted = true;
          break;
        }
      if (AnyTainted)
        break;
    }
    if (!AnyTainted)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;
    // ScalarEvolution"""

# name: [(file, old, new, occurrence-index or None=unique)]
MUTANTS = {
    "Mpristine_no_mutation": [],
    "M0_null_reorder": [(HDR, "    C->Dead.erase(K);\n    C->H.disarm(K);\n    return (Had && !WasDead) ? 1 : 0;",
                         "    C->H.disarm(K);\n    C->Dead.erase(K);\n    return (Had && !WasDead) ? 1 : 0;", None)],
    "M1_hook_silent": [(HDR, "    O->keyDeleted(V);", "    (void)O;", None)],
    "M2_set_nomark": [(HDR, "        Dead.insert(V);", "        (void)V;", 0)],
    "M3_map_nomark": [(HDR, "        Dead.insert(V);", "        (void)V;", 1)],
    "M4_list_nonull": [(HDR, "          Slot = nullptr;", "          (void)Slot;", None)],
    "M5_pair_noerase": [(HDR, "      for (const PairT &P : Doomed)\n        S.erase(P);", "      for (const PairT &P : Doomed)\n        (void)P;", None)],
    "M6_set_count_ignores_dead": [(HDR, "  std::size_t count(KeyArg V) const {\n    if (C->dead(asValue(V)))\n      return 0;\n    return C->S.count(toStore(V)) ? 1 : 0;",
                                   "  std::size_t count(KeyArg V) const {\n    return C->S.count(toStore(V)) ? 1 : 0;", None)],
    "M7_set_iter_noskip": [(HDR, "      while (I != E && Co->Dead.count(asValue(*I)))", "      while (false && I != E && Co->Dead.count(asValue(*I)))", None)],
    "M8_map_lookup_stale": [(HDR, "  ValT lookup(KeyArg K) const {\n    if (C->dead(asValue(K)))\n      return ValT();\n",
                             "  ValT lookup(KeyArg K) const {\n", None)],
    "M9_revive_not_new": [(HDR, "      return {find(V), true};", "      return {find(V), false};", None)],
    "M10_map_no_reset": [(HDR, "      Slot = ValT();", "      (void)0;", None)],
    "M11_raw_tainted": [(HDR, "using TaintedValueSet = scrub::Set<std::set<llvm::Value *>, llvm::Value *>;",
                         "using TaintedValueSet = std::set<llvm::Value *>;", None)],
    "M12_um24_scan_keyderef": [(LL, NEW_SCAN_TAIL, OLD_SCAN, None)],
}

UM24 = ("iosink_reject_mux_literal_callee|lowering_reject_break_uncollected_clone|"
        "lowering_reject_inplace_rail_stale_w1_xor_bareout|lowering_reject_inplace_rail_stale_w1_xor_derived")


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def pristine():
    for f in FILES:
        shutil.copyfile(f"{W}/{f}", f"{SRC}/{f}")


def apply(muts):
    for f, old, new, occ in muts:
        p = f"{SRC}/{f}"
        s = open(p).read()
        n = s.count(old)
        if occ is None:
            assert n == 1, (f, old[:50], n)
            s = s.replace(old, new, 1)
        else:
            assert n > occ, (f, old[:50], n)
            idx = -1
            for _ in range(occ + 1):
                idx = s.index(old, idx + 1)
            s = s[:idx] + new + s[idx + len(old):]
        open(p, "w").write(s)


def build():
    r1 = sh(["cmake", "--build", BLD, "--target", "cq-opt", "cq-opt-debugalloc", "-j8"])
    r2 = sh(["cmake", "--build", BLD, "--target", "cq-scrub-selftest", "-j8"])
    return r1.returncode == 0, r2.returncode == 0


def main():
    only = None
    corpus = "--no-corpus" not in sys.argv
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
    rows = []
    for name, muts in MUTANTS.items():
        if only and name not in only:
            continue
        pristine()
        apply(muts)
        ok_opt, ok_st = build()
        d = f"{T}/mut/{name}"
        os.makedirs(d, exist_ok=True)
        res = {"build_opt": ok_opt, "build_selftest": ok_st}
        if ok_opt:
            for b in ("cq-opt", "cq-opt-debugalloc"):
                shutil.copyfile(f"{BLD}/ir-pass/{b}", f"{d}/{b}")
                os.chmod(f"{d}/{b}", 0o755)
            res["sha"] = hashlib.sha256(open(f"{d}/cq-opt", "rb").read()).hexdigest()[:16]
            sh(["python3", f"{T}/mklit.py", name, f"{d}/cq-opt", f"{d}/cq-opt-debugalloc"])
            res["D1_k65_lit"] = sh(["bash", f"{T}/litn.sh", name, "spec_scrub_dangling_key", "3"]).stdout.strip().split("  ", 1)[-1]
            res["D2_um24_lit"] = sh(["bash", f"{T}/litn.sh", name, UM24, "3"]).stdout.strip().split("  ", 1)[-1]
            res["D3_e2e_lifo"] = sh(["bash", f"{T}/e2e_rg.sh", f"{d}/cq-opt-debugalloc", "3", "lifo"]).stdout.strip().split(" runs=", 1)[-1]
        if ok_st:
            shutil.copyfile(f"{BLD}/ir-pass/cq-scrub-selftest", f"{d}/cq-scrub-selftest")
            os.chmod(f"{d}/cq-scrub-selftest", 0o755)
            for mode in ("lifo", ""):
                env = dict(os.environ, CQ_OPT_DEBUG_ALLOC=mode)
                r = sh([f"{d}/cq-scrub-selftest"], env=env)
                last = (r.stdout.strip().splitlines() or ["(no output)"])[-1]
                res[f"D4_selftest_{mode or 'sys'}"] = f"rc={r.returncode} " + last.replace("scrub-on-delete selftest: ", "")
        g = sh(["python3", f"{SRC}/tools/taintset_scrub_guard.py"])
        res["D5_guard"] = f"rc={g.returncode}"
        if ok_opt and corpus:
            r = sh(["python3", f"{T}/ab.py", f"{T}/cq-opt.subj4d:lifo", f"{d}/cq-opt-debugalloc:lifo",
                    f"{T}/corpus_all.lst", f"{d}/ab_lifo.tsv", "-j", "10"])
            res["D6_corpus_lifo"] = " | ".join(l for l in r.stdout.splitlines() if l.startswith(("denominator", "counts")))
        rows.append((name, res))
        print(name, res, flush=True)
    pristine()
    for f in FILES:
        a = hashlib.sha256(open(f"{W}/{f}", "rb").read()).hexdigest()
        b = hashlib.sha256(open(f"{SRC}/{f}", "rb").read()).hexdigest()
        assert a == b, f"mut_src not restored: {f}"
    print("mut_src restored to pristine (sha256-verified)")


main()
