#!/usr/bin/env python3
"""mut.py [MUTANT...] — bd d88e mutation matrix.

Each mutant is an exact textual patch to the COPY of the subject tree
(scratchpad d88e/mutsrc), rebuilt (CQPass + cq-opt), then measured by
  (1) the FULL lit suite of that tree (`lit -s`, parsed from its own summary;
      the denominator is printed, and a run that discovers 0 tests is an error),
  (2) the probe battery (every p/*.s1.ll) against the frozen SUBJECT binary
      (verdict+first-error+IR sha per module; movers listed).
The file is restored after every mutant and, at the end, the tree is rebuilt and
its cq-opt must hash to the subject's (restoration check).
"""
import hashlib
import pathlib
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
T = S / "d88e/mutsrc"
SUBJ = S / (sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].startswith("frozen/") else "frozen/cq-opt.d88e_v2")
MUTB = T / "build/ir-pass/cq-opt"
OUT = S / "d88e/mut_results_v2"
OUT.mkdir(exist_ok=True)
TP = "ir-pass/src/TaintPropagation.cpp"
CP = "ir-pass/src/CQLoweringPass.cpp"
TH = "ir-pass/include/TaintPropagation.h"

MUTANTS = {
    # null control: a semantic no-op that changes the binary.
    "N0": [(TP, "  if (taint.LiftedMergePhis.empty())\n    return false;\n  SmallPtrSet<CallInst *, 32> GateCalls;\n  collectLiftGateCalls(taint, GateCalls);\n  for (const TaintSet::LiftedMergePhi &L",
            "  if (taint.LiftedMergePhis.empty() && taint.LiftedConsumers.size() > 100000000u)\n    return false;\n  SmallPtrSet<CallInst *, 32> GateCalls;\n  collectLiftGateCalls(taint, GateCalls);\n  for (const TaintSet::LiftedMergePhi &L")],
    # the re-ask is never asked (run() entry point).
    "M1_noask": [(CP, "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();",
                  "  if (false && declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();")],
    # the record is never written.
    "M2_norecord": [(TP, "    taint.LiftedMergePhis.push_back(std::move(Rec));",
                     "    (void)Rec;")],
    # the classical-phi entry test (no tainted incoming -> skip) is dropped.
    "M3_noskip": [(TP, "      if (!AnyTainted)\n        continue;", "      (void)AnyTainted;")],
    # conjunct (2) dropped.
    "M4_no2": [(TP, "        if (!taint.Tainted.count(V) ||\n            resolveWireBase(V, GateCalls, taint).Base != Base) {",
                "        if (resolveWireBase(V, GateCalls, taint).Base != Base) {")],
    # conjunct (3) dropped.
    "M5_no3": [(TP, "        if (!taint.Tainted.count(V) ||\n            resolveWireBase(V, GateCalls, taint).Base != Base) {",
                "        if (!taint.Tainted.count(V)) {")],
    # the record does not follow RAUW.
    "M6_weakvh": [(TH, "    llvm::WeakTrackingVH Base;\n    llvm::SmallVector<llvm::WeakTrackingVH, 2> Incomings;",
                   "    llvm::WeakVH Base;\n    llvm::SmallVector<llvm::WeakVH, 2> Incomings;"),
                  (TP, "    for (const WeakTrackingVH &H : L.Incomings) {", "    for (const WeakVH &H : L.Incomings) {")],
    # a nulled handle passes instead of declining.
    "M7_nullpass": [(TP, "      if (!V)\n        Falsified = true;\n      else\n        Ins.push_back(V);",
                     "      if (V)\n        Ins.push_back(V);"),
                    (TP, "    bool Falsified = !Base;", "    bool Falsified = false;\n    if (!Base)\n      continue;")],
    # slot: the re-ask after the l3oi fence (v2 anchors: run() only; the shim is dead).
    "M8_after_l3oi": [(CP, "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();\n\n  // Post-lift stale-record re-sweep",
                        "  // Post-lift stale-record re-sweep"),
                       (CP, "  if (declineScrubbedHandleReads(M, taint))\n    return PreservedAnalyses::none();\n\n  // The lowered calls are erased",
                        "  if (declineScrubbedHandleReads(M, taint))\n    return PreservedAnalyses::none();\n  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();\n\n  // The lowered calls are erased")],
    # slot: the re-ask after the 3d8q stale-reader backstop.
    "M9_after_backstop": [(CP, "  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();\n\n  // Post-lift stale-record re-sweep",
                            "  // Post-lift stale-record re-sweep"),
                           (CP, "  declineRecordedStaleQuantumReaders(M, taint);\n  // bd `test_C_libtooling-s82e`",
                            "  declineRecordedStaleQuantumReaders(M, taint);\n  if (declineFalsifiedMergePhiLifts(M, taint))\n    return PreservedAnalyses::none();\n  // bd `test_C_libtooling-s82e`", "first")],
    # the 2qyz re-sweep moved BACK to right after the lift (the v1 slot).
    "M10_resweep_back": [(CP, "  declineLiftedStaleRecordOps(M, taint);\n\n  // bd `test_C_libtooling-l3oi`",
                           "\n  // bd `test_C_libtooling-l3oi`"),
                          (CP, "  declineClassicalMuxes(M, taint);\n  // (The bd 2qyz post-lift stale-record re-sweep, `declineLiftedStaleRecordOps`,",
                           "  declineClassicalMuxes(M, taint);\n  declineLiftedStaleRecordOps(M, taint);\n  // (The bd 2qyz post-lift stale-record re-sweep, `declineLiftedStaleRecordOps`,")],
    # the moved 2qyz re-sweep deleted outright.
    "M11_no_resweep": [(CP, "  declineLiftedStaleRecordOps(M, taint);\n\n  // bd `test_C_libtooling-l3oi`",
                         "\n  // bd `test_C_libtooling-l3oi`")],
    # CENSUS (not a kill test): every recorded lift declines -> the movers are the
    # modules whose lift reaches the re-ask at all.
    "MC_census": [(TP, "    if (!Falsified)\n      continue;\n    // The erased phi's own diagnostic:",
                   "    Falsified = true;\n    if (!Falsified)\n      continue;\n    // The erased phi's own diagnostic:")],
}


def sh(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def build():
    r = sh(["cmake", "--build", str(T / "build"), "--target", "CQPass", "cq-opt", "-j8"])
    if r.returncode != 0:
        print(r.stdout[-3000:], r.stderr[-3000:])
        raise SystemExit("BUILD FAILED")


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]


def lit():
    r = sh(["lit", "-s", "ir-pass/test"], cwd=str(T / "build"))
    txt = r.stdout + r.stderr
    m = re.search(r"Total Discovered Tests: (\d+)", txt)
    disc = int(m.group(1)) if m else 0
    failed = re.findall(r"^\s+CQ IR-pass :: (\S+)$", txt.split("Failed Tests")[1] if "Failed Tests" in txt else "", re.M)
    p = re.search(r"Passed\s*:\s*(\d+)", txt)
    return disc, (int(p.group(1)) if p else 0), failed


PROBES = sorted((S / "d88e/p").glob("*.s1.ll"))


def run1(b, f):
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "-"], capture_output=True)
    err = ""
    for l in r.stderr.decode(errors="replace").splitlines():
        if "error:" in l:
            err = l.split("error:", 1)[1].strip()
            break
    return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16], err


def probes(b):
    with ThreadPoolExecutor(6) as ex:
        return list(ex.map(lambda f: run1(b, f), PROBES))


def main():
    names = [a for a in sys.argv[1:] if not a.startswith("frozen/")] or list(MUTANTS)
    base_sha = sha(SUBJ)
    subj_probe = probes(SUBJ)
    for name in names:
        patches = MUTANTS[name]
        orig = {}
        ok = True
        for patch in patches:
            f, old, new = patch[:3]
            first = len(patch) > 3 and patch[3] == "first"
            p = T / f
            text = orig.get(f) or p.read_text()
            orig.setdefault(f, text)
            cur = p.read_text()
            n = cur.count(old)
            if n != 1 and not (first and n >= 1):
                print(f"{name}: patch anchor count {n} in {f} — SKIP")
                ok = False
                break
            # "first": run() precedes the dead runOnFunction shim in the file.
            p.write_text(cur.replace(old, new, 1))
        if ok:
            build()
            msha = sha(MUTB)
            disc, passed, failed = lit()
            mp = probes(MUTB)
            movers = [(pr.name, a, b) for pr, a, b in zip(PROBES, subj_probe, mp) if a != b]
            lines = [f"{name}: cq-opt {msha} (subject {base_sha}) lit discovered={disc} passed={passed} failed={len(failed)}",
                     f"  probes: {len(movers)} movers of {len(PROBES)}"]
            lines += [f"  LIT-FAIL {x}" for x in failed]
            lines += [f"  PROBE {n}: subj rc={a[0]} [{a[2][:90]}] -> mut rc={b[0]} [{b[2][:90]}]" for n, a, b in movers]
            if disc == 0:
                lines.append("  ERROR: lit discovered 0 tests")
            txt = "\n".join(lines)
            print(txt, flush=True)
            (OUT / f"{name}.txt").write_text(txt + "\n")
        for f, text in orig.items():
            (T / f).write_text(text)
    build()
    final = sha(MUTB)
    print(f"restored: cq-opt {final} == subject {base_sha}: {final == base_sha}")


if __name__ == "__main__":
    main()
