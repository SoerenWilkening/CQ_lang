#!/usr/bin/env python3
"""Acceptance test of cq-w0-scaffold.

1. spec.lock holds (tools/spec_lock.py).
2. The interfaces of the flat memory model (plan_layout.md §1, CR §0 Retired; they replace cq-arch's freeze, whose
   text is the retired memory model): pass/include/cq/*.h and checker/rt/cqe.h name no retired symbol, Bus.h declares
   the bus API, and the dataclass fields of checker/cqcheck/contracts.py equal cq-arch's (read live from beads, `bd
   show cq-arch --json`, unless --arch-json names a saved copy).
3. `opt -passes=cq-lower` on every example `.O1.ll` (counted from the directory) either exits 0 with an
   output that passes `opt -passes=verify` and `opt -passes=cq-verify`, or exits non-zero with
   `cq: unimplemented: <module>: <function>` and writes no output file and nothing to stdout.
4. A module with no CQ.h call, no root list and no __cq_q_* declaration (rulings Q2) comes out byte-identical (.ll and .bc, with and without the K flags) to
   the same opt run with no pass: the identity is the pass's, opt's reader and writer are not measured.
5. The early exit tests calls, not uses (owner ruling 2 on cq-arch, bead cq-bym):
   surface/references_only.ll references every CQ.h function without calling one and passes through
   byte-identical as in 4; surface/phi_only.ll, whose only CQ.h call is cq_phi, does not take the
   early exit: with -cq-trace-pipeline its first stderr line is `cq-lower: taint: preliminary`.

Usage: check_scaffold.py --plugin build/pass/libCQLower.so [--opt OPT] [--clang CLANG] [--spec DIR]
Exit 0 only when every check holds; every failure is printed.
"""
import argparse
import collections
import concurrent.futures
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
LLVM = Path("/usr/local/opt/llvm@19/bin")
UNIMPL = re.compile(r"^LLVM ERROR: cq: unimplemented: ([a-z][a-z0-9-]*): (\S.*)$", re.M)

failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL:", msg)


# ---------------------------------------------------------------------------------------------
# 2. Headers against cq-arch


def arch_description(arch_json):
    if arch_json:
        data = json.loads(Path(arch_json).read_text())
    else:
        out = subprocess.run(["bd", "show", "cq-arch", "--json"], cwd=ROOT, capture_output=True, text=True)
        if out.returncode != 0:
            fail(f"bd show cq-arch failed: {out.stderr.strip()}")
            return None
        data = json.loads(out.stdout)
    if isinstance(data, list):
        data = data[0]
    return data["description"]


# CR §0 Retired, the memory and clone names; word-bounded, in code lines (a comment may name what replaced them).
RETIRED = re.compile(r"\b(ObjectId|ObjClass|PtrAbi|PtrFormal|OffsetKind|objectOf|classOf|mayHoldHandle|provenance|"
                     r"isFatPointer|cellsWritten|cellsRotated|cellForward|pointerFormal|isCodeAddress|QramRealloc|"
                     r"QramFree|QramSize|QramAllocHost|qram_realloc|qram_free|qram_size|qrom_load|strided|"
                     r"TapeWriteStrLit|TapeStrBegin|TapeStrEnd|recordCellLoad|"
                     r"noteCallBusRead|WalkedPtr)\b")
BUS_API = ["mem", "address", "hostAccess", "lowerLoad", "lowerStore", "lowerAtomic", "lowerMemIntrinsic", "lowerCopy",
           "lowerAlloc", "lowerRealloc", "versionChange", "writesMemory", "K2"]
C_DEFINES = ["#define CQE_OP_NOT_MINE 1"]


def code_lines(path):
    """The lines of a C or C++ header outside comments."""
    text = re.sub(r"/\*.*?\*/", "", path.read_text(), flags=re.S)
    return [re.sub(r"//.*$", "", l) for l in text.splitlines()]


def check_headers(desc):
    n = 0
    for p in sorted((ROOT / "pass/include/cq").glob("*.h")) + [ROOT / "checker/rt/cqe.h"]:
        hits = sorted({m.group(1) for l in code_lines(p) for m in RETIRED.finditer(l)})
        if hits:
            fail(f"{p.relative_to(ROOT)} names retired symbols: {hits}")
        else:
            n += 1
    bus = "\n".join(code_lines(ROOT / "pass/include/cq/Bus.h"))
    missing = [f for f in BUS_API if not re.search(r"\b" + f + r"\(", bus)]
    if missing:
        fail(f"pass/include/cq/Bus.h lacks {missing}")
    cqe_text = (ROOT / "checker/rt/cqe.h").read_text()
    missing = [d for d in C_DEFINES if not re.search(r"^" + re.escape(d) + r"(\s|$)", cqe_text, re.M)]
    if missing:
        fail(f"checker/rt/cqe.h: missing {missing}")

    # contracts.py dataclass fields
    sec = desc[desc.index("**`checker/cqcheck/contracts.py`**"):desc.index("**CLI")]
    spec = importlib.util.spec_from_file_location("contracts", ROOT / "checker/cqcheck/contracts.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules["contracts"] = mod
    spec.loader.exec_module(mod)
    import dataclasses
    for m in re.finditer(r"- `(\w+)\{(.*)\}`", sec):
        cls, body = m.group(1), m.group(2)
        fields, depth, cur = [], 0, ""
        for ch in body:
            if ch in "[{":
                depth += 1
            elif ch in "]}":
                depth -= 1
            if ch == "," and depth == 0:
                fields.append(cur)
                cur = ""
            else:
                cur += ch
        fields.append(cur)
        names = [f.split(":")[0].strip() for f in fields]
        got = [f.name for f in dataclasses.fields(getattr(mod, cls))] if hasattr(mod, cls) else None
        if got != names:
            fail(f"contracts.py {cls}: fields {got} != cq-arch {names}")
        else:
            n += 1
    print(f"headers: {n} interfaces compared against cq-arch (+A1-A4, K1, S1, P1, B1, M1, C1, M2, U1, L1-L3)")


# ---------------------------------------------------------------------------------------------
# 3. Every example lowers to a verified module, or stops at cq: unimplemented with no output
#    (orchestrator decision on cq-ta8u)


def run_example(opt, plugin, ll, tmp):
    out = Path(tmp) / (ll.parent.name + ".out.ll")
    p = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", str(ll), "-S", "-o", str(out)],
                       capture_output=True, text=True)
    res = {"ll": ll, "rc": p.returncode, "stdout": p.stdout, "stderr": p.stderr, "wrote": out.exists()}
    if p.returncode == 0 and res["wrote"]:
        v = subprocess.run([opt, "-disable-output", "-passes=verify", str(out)], capture_output=True, text=True)
        res["verify"] = (v.returncode, v.stderr)
        c = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-disable-output", "-passes=cq-verify", str(out)],
                           capture_output=True, text=True)
        res["cqverify"] = (c.returncode, c.stderr)
    return res


def check_examples(opt, plugin, spec):
    examples = sorted((Path(spec) / "examples").glob("*/*.O1.ll"))
    dirs = sorted(p for p in (Path(spec) / "examples").iterdir() if p.is_dir())
    if len(examples) != len(dirs):
        fail(f"{len(dirs)} example directories but {len(examples)} .O1.ll files")
    msgs = collections.Counter()
    lowered, unimpl, bad_names = 0, 0, []
    with tempfile.TemporaryDirectory() as tmp, concurrent.futures.ThreadPoolExecutor(os.cpu_count()) as ex:
        for r in ex.map(lambda e: run_example(opt, plugin, e, tmp), examples):
            name, err, bad = r["ll"].parent.name, r["stderr"], []
            if r["rc"] == 0:
                if not r["wrote"]:
                    bad.append("exit 0 but no output file")
                else:
                    vrc, verr = r["verify"]
                    if vrc != 0:
                        bad.append(f"LLVM verifier failed: {verr.strip()[:200]!r}")
                    crc, cerr = r["cqverify"]
                    if crc != 0:
                        bad.append(f"cq-verify failed: {cerr.strip()[:200]!r}")
                if bad:
                    fail(f"{name}: " + "; ".join(bad))
                    bad_names.append(name)
                else:
                    lowered += 1
                continue
            m = UNIMPL.search(err)
            if not m:
                bad.append(f"exit {r['rc']} without 'cq: unimplemented: <module>: <function>': {err.strip()[:200]!r}")
            if r["wrote"]:
                bad.append("output file written")
            if r["stdout"]:
                bad.append("stdout not empty")
            if bad:
                fail(f"{name}: " + "; ".join(bad))
                bad_names.append(name)
            else:
                unimpl += 1
                msgs[f"{m.group(1)}: {m.group(2)}"] += 1
    print(f"examples: {len(examples)} total: {lowered} lowered (verify + cq-verify clean), "
          f"{unimpl} cq: unimplemented with no output, {len(bad_names)} failure(s)"
          + (f": {' '.join(sorted(bad_names))}" if bad_names else ""))
    for k, v in sorted(msgs.items()):
        print(f"    {v:4d}  cq: unimplemented: {k}")


# ---------------------------------------------------------------------------------------------
# 4. Passthrough


FLAGSETS = [[], ["-cq-k=f=3,horner=9", "-cq-k-default=5", "-cq-dump-taint"]]


def assemble(ll, tmp):
    """The .bc of a hand-written .ll, or None (failure recorded)."""
    bc = Path(tmp) / (ll.stem + ".bc")
    r = subprocess.run([str(LLVM / "llvm-as"), str(ll), "-o", str(bc)], capture_output=True, text=True)
    if r.returncode != 0:
        fail(f"llvm-as {ll.name}: {r.stderr.strip()}")
        return None
    return bc


def identity_runs(opt, plugin, src, tmp, label):
    """cq-lower under every flag set against opt with no pass; returns the byte-identical count."""
    # Baseline: the same opt reading and writing the same file with no pass. opt's reader and
    # writer are not the pass (ModuleID, use-list order, intrinsic attribute upgrades, the
    # bitcode header), so the identity is measured against them (NORTHSTAR goal 4, tier 1).
    base = Path(tmp) / f"base{src.suffix}"
    cmd = [opt, str(src), "-o", str(base)] + (["-S"] if src.suffix == ".ll" else [])
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        fail(f"baseline {src.name}: {r.stderr.strip()}")
        return 0
    n = 0
    for i, flags in enumerate(FLAGSETS):
        out = Path(tmp) / f"out{i}{src.suffix}"
        cmd = [opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", *flags, str(src), "-o", str(out)]
        if src.suffix == ".ll":
            cmd.append("-S")
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            fail(f"{label} {src.name} {flags}: exit {r.returncode}: {r.stderr.strip()}")
        elif r.stdout or r.stderr:
            fail(f"{label} {src.name} {flags}: unexpected output {r.stdout + r.stderr!r}")
        elif out.read_bytes() != base.read_bytes():
            fail(f"{label} {src.name} {flags}: output differs from opt with no pass")
        else:
            n += 1
    return n


def check_passthrough(opt, clang, plugin, spec):
    n = 0
    with tempfile.TemporaryDirectory() as tmp:
        inputs = []
        for c in sorted((HERE / "passthrough").glob("*.c")):
            base = Path(tmp) / c.stem
            common = [clang, "-O1", "-target", "x86_64-apple-macosx", "-include", str(Path(spec) / "CQ.h"),
                      "-emit-llvm", str(c)]
            for ext, extra in ((".ll", ["-S"]), (".bc", ["-c"])):
                r = subprocess.run(common + extra + ["-o", str(base) + ext], capture_output=True, text=True)
                if r.returncode != 0:
                    fail(f"clang {c.name}: {r.stderr.strip()}")
                    continue
                inputs.append(Path(str(base) + ext))
        for ll in sorted((HERE / "passthrough").glob("*.ll")):
            inputs.append(ll)
            bc = assemble(ll, tmp)
            if bc:
                inputs.append(bc)
        for src in inputs:
            n += identity_runs(opt, plugin, src, tmp, "passthrough")
    print(f"passthrough: {n}/{len(inputs) * len(FLAGSETS)} runs byte-identical")


# ---------------------------------------------------------------------------------------------
# 5. The early exit tests calls to the CQ.h surface, not uses (owner ruling 2, cq-bym)


def check_declared_clone_reference(opt, plugin):
    """Rulings Q2 (c): a module referencing a declared clone of a linked lowered library is no identity."""
    r = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", "-cq-trace-pipeline", "-disable-output",
                        str(HERE / "surface/declared_clone_ref.ll")], capture_output=True, text=True)
    first = (r.stderr.splitlines() or [""])[0]
    if first != "cq-lower: taint: preliminary":
        fail(f"surface/declared_clone_ref.ll took the early exit: first stderr line {first!r}")
    else:
        print("declared clone reference: not the identity")


def check_surface_calls(opt, plugin):
    refs = HERE / "surface" / "references_only.ll"
    phi = HERE / "surface" / "phi_only.ll"
    for f in (refs, phi):
        if not f.is_file():
            fail(f"missing input {f}")
            return
    n, total = 0, 0
    with tempfile.TemporaryDirectory() as tmp:
        inputs = [refs]
        bc = assemble(refs, tmp)
        if bc:
            inputs.append(bc)
        for src in inputs:
            total += len(FLAGSETS)
            n += identity_runs(opt, plugin, src, tmp, "references-only")
        print(f"surface: references_only: {n}/{total} runs byte-identical")

        # cq_phi is the only call: the pipeline must start. Whatever happens after the first step
        # is a later bead's subject; the early exit (exit 0, no trace line) is the failure here.
        out = Path(tmp) / "phi.out.ll"
        r = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", "-cq-trace-pipeline",
                            str(phi), "-S", "-o", str(out)], capture_output=True, text=True)
        steps = [l for l in r.stderr.splitlines() if l.startswith("cq-lower: ")]
        if not steps or steps[0] != "cq-lower: taint: preliminary":
            fail(f"phi-only: early exit taken (exit {r.returncode}, trace {steps}, stderr {r.stderr.strip()[:200]!r})")
        else:
            status = "completed" if r.returncode == 0 else "stopped: " + \
                next((l for l in r.stderr.splitlines() if l.startswith("LLVM ERROR")), f"exit {r.returncode}")
            print(f"surface: phi_only: no early exit, first step 'taint: preliminary' ({status})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", default=str(ROOT / "build/pass/libCQLower.so"))
    ap.add_argument("--opt", default=str(LLVM / "opt"))
    ap.add_argument("--clang", default=str(LLVM / "clang"))
    ap.add_argument("--spec", default=str(ROOT / "../CQ_spec"))
    ap.add_argument("--arch-json")
    a = ap.parse_args()

    r = subprocess.run([sys.executable, str(ROOT / "tools/spec_lock.py")], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        fail(f"spec_lock: {r.stdout.strip()} {r.stderr.strip()}")
    else:
        print("spec.lock: ok")
    desc = arch_description(a.arch_json)
    if desc is not None:
        check_headers(desc)
    check_examples(a.opt, a.plugin, a.spec)
    check_passthrough(a.opt, a.clang, a.plugin, a.spec)
    check_surface_calls(a.opt, a.plugin)
    check_declared_clone_reference(a.opt, a.plugin)
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
