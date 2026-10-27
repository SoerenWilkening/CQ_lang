#!/usr/bin/env python3
"""Acceptance test of cq-w0-scaffold.

1. spec.lock holds (tools/spec_lock.py).
2. The frozen headers equal cq-arch's text with the owner's amendments A1-A4 and freeze bead K1
   (cq-k1w): pass/include/cq/*.h, checker/rt/cqe.h, and the dataclass fields of
   checker/cqcheck/contracts.py. cq-arch is read live from beads (`bd show cq-arch --json`) unless
   --arch-json names a saved copy.
3. `opt -passes=cq-lower` on every example `.O1.ll` (counted from the directory) exits non-zero with
   `cq: unimplemented: <module>: <function>` and writes no output file and nothing to stdout.
4. A module with no CQ.h call comes out byte-identical (.ll and .bc, with and without the K flags) to
   the same opt run with no pass: the identity is the pass's, opt's reader and writer are not measured.

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


def code_block(text, heading, lang):
    start = text.index(heading)
    open_ = text.index("```" + lang + "\n", start) + len(lang) + 4
    return text[open_:text.index("```", open_)]


def patch(lines, anchor, new, mode):
    """Apply one owner amendment; the anchor must occur exactly once."""
    idx = [i for i, l in enumerate(lines) if l == anchor]
    if len(idx) != 1:
        fail(f"amendment anchor not found exactly once in cq-arch: {anchor!r}")
        return lines
    i = idx[0]
    if mode == "after":
        return lines[:i + 1] + new + lines[i + 1:]
    return lines[:i] + new + lines[i + 1:]


# Owner amendments of 2026-10-27 (cq-arch comment), as edits to the approved text.
AMENDMENTS = [
    # A1
    ("  bool isTainted(const llvm::Function &) const;",
     ["  bool controlTainted(const llvm::BasicBlock *, const Specialization &) const;"], "after"),
    # A2
    ("struct Record { llvm::CallInst *forward; abi::TemplateSpec spec; llvm::SmallVector<Operand, 3> ops; RailId out; };",
     ["struct Record { llvm::CallInst *forward; std::variant<abi::TemplateSpec, abi::CoreSpec> spec; "
      "llvm::SmallVector<Operand, 3> ops; RailId out; };"], "replace"),
    ("  RailId recordTemplate(llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>);",
     ["  RailId recordCore(llvm::CallInst *fwd, const abi::CoreSpec &, llvm::ArrayRef<Operand>, RailId out);"], "after"),
    # A3
    ("  static Pred top(); static Pred bottom(); static Pred atom(const llvm::Value *cond);",
     ["  static Pred eqAtom(const llvm::Value *scrutinee, const llvm::APInt &v);"], "after"),
    # A4
    ("                            KeptOverflow, Escaped };",
     ["                            KeptOverflow, Escaped, KeptEntangled };"], "replace"),
    # K1 (freeze bead cq-k1w, final text in a cq-arch comment): storage for the stateful classes.
    ("  void print(llvm::raw_ostream &) const;                               // -cq-dump-taint",
     ["private:", "  struct Impl; std::shared_ptr<Impl> impl;",
      "  friend TaintInfo computeTaint(llvm::Module &, const TaintOptions &);"], "after"),
    ("  RailId recordTemplate(llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>);",
     ["  Uncompute();",
      "  RailId recordTemplate(llvm::CallInst *fwd, const abi::TemplateSpec &, llvm::ArrayRef<Operand>);"], "replace"),
    ("  void emitMirror(unsigned scope, llvm::IRBuilder<> &);",
     ["private:", "  struct Impl; std::shared_ptr<Impl> impl;"], "after"),
    ("  bool isClassical(const TaintInfo &, const Specialization &) const;",
     ["private:", "  struct Impl; std::shared_ptr<const Impl> impl;"], "after"),
    ("  void compute(llvm::Function &, const llvm::LoopInfo &, const TaintInfo &, const Specialization &,",
     ["  PathPredicates();",
      "  void compute(llvm::Function &, const llvm::LoopInfo &, const TaintInfo &, const Specialization &,"],
     "replace"),
    ("  llvm::Value *flag(LoweringContext &, const Pred &);",
     ["private:", "  struct Impl; std::shared_ptr<Impl> impl;"], "after"),
    ("  llvm::Module &M; const TaintInfo &T; const Specialization &S;",
     ["  LoweringContext(llvm::Module &, const TaintInfo &, const Specialization &);"], "after"),
    ("  unsigned K(const llvm::Loop *) const;",
     ["private:", "  struct Impl; std::shared_ptr<Impl> impl;"], "after"),
]

SECTION = re.compile(r"^// (\w+)\.h\b")


def arch_headers(desc):
    lines = [l.rstrip() for l in code_block(desc, "## Public headers", "cpp").splitlines()]
    for anchor, new, mode in AMENDMENTS:
        lines = patch(lines, anchor, new, mode)
    sections, cur = {}, None
    for l in lines:
        m = SECTION.match(l)
        if m:
            cur = m.group(1)
            sections[cur] = []
        if cur is None or not l.strip():
            continue
        sections[cur].append(l)
    return sections


def header_decls(path, c_header=False):
    """The header minus what the arch text leaves implicit: includes, pragmas, guards, forward
    declarations of llvm classes, extern "C" wrappers, and comment-only lines other than the
    section marker."""
    out = []
    for l in path.read_text().splitlines():
        l = l.rstrip()
        s = l.strip()
        if not s or s.startswith("#") or re.match(r"^namespace llvm \{ .* \}$", s):
            continue
        if c_header and s in ('extern "C" {', "}") or s.startswith("/* Frozen"):
            continue
        if s.startswith("//") and not SECTION.match(l):
            continue
        out.append(l)
    return out


def check_headers(desc):
    want = arch_headers(desc)
    have_files = {p.stem: p for p in (ROOT / "pass/include/cq").glob("*.h")}
    if set(want) != set(have_files):
        fail(f"header set differs: cq-arch {sorted(want)} vs pass/include/cq {sorted(have_files)}")
    for name in sorted(set(want) & set(have_files)):
        got = header_decls(have_files[name])
        if got != want[name]:
            fail(f"pass/include/cq/{name}.h differs from cq-arch")
            for a, b in zip(got + [""] * len(want[name]), want[name] + [""] * len(got)):
                if a != b:
                    print(f"    have: {a!r}\n    want: {b!r}")
                    break
    n = len(set(want) & set(have_files))

    # cqe.h
    want_c = [l.rstrip() for l in code_block(desc, "## Checker contracts", "c").splitlines() if l.strip()]
    got_c = header_decls(ROOT / "checker/rt/cqe.h", c_header=True)
    if got_c != want_c:
        fail("checker/rt/cqe.h differs from cq-arch")
    else:
        n += 1

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
    print(f"headers: {n} interfaces compared against cq-arch (+A1-A4, K1)")


# ---------------------------------------------------------------------------------------------
# 3. Every example is an internal error with no output


def run_example(opt, plugin, ll, tmp):
    out = Path(tmp) / (ll.parent.name + ".out.ll")
    p = subprocess.run([opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", str(ll), "-S", "-o", str(out)],
                       capture_output=True, text=True)
    return ll, p.returncode, p.stdout, p.stderr, out.exists()


def check_examples(opt, plugin, spec):
    examples = sorted((Path(spec) / "examples").glob("*/*.O1.ll"))
    dirs = sorted(p for p in (Path(spec) / "examples").iterdir() if p.is_dir())
    if len(examples) != len(dirs):
        fail(f"{len(dirs)} example directories but {len(examples)} .O1.ll files")
    msgs = collections.Counter()
    ok = 0
    with tempfile.TemporaryDirectory() as tmp, concurrent.futures.ThreadPoolExecutor(os.cpu_count()) as ex:
        for ll, rc, out, err, wrote in ex.map(lambda e: run_example(opt, plugin, e, tmp), examples):
            m = UNIMPL.search(err)
            bad = []
            if rc == 0:
                bad.append("exit 0")
            if not m:
                bad.append(f"no 'cq: unimplemented: <module>: <function>' in stderr: {err.strip()[:200]!r}")
            if wrote:
                bad.append("output file written")
            if out:
                bad.append("stdout not empty")
            if bad:
                fail(f"{ll.parent.name}: " + "; ".join(bad))
            else:
                ok += 1
                msgs[f"{m.group(1)}: {m.group(2)}"] += 1
    print(f"examples: {ok}/{len(examples)} exit non-zero with cq: unimplemented and no output")
    for k, v in sorted(msgs.items()):
        print(f"    {v:4d}  cq: unimplemented: {k}")


# ---------------------------------------------------------------------------------------------
# 4. Passthrough


def check_passthrough(opt, clang, plugin, spec):
    flagsets = [[], ["-cq-k=f=3,horner=9", "-cq-k-default=5", "-cq-dump-taint"]]
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
            bc = Path(tmp) / (ll.stem + ".bc")
            r = subprocess.run([str(LLVM / "llvm-as"), str(ll), "-o", str(bc)], capture_output=True, text=True)
            if r.returncode != 0:
                fail(f"llvm-as {ll.name}: {r.stderr.strip()}")
            else:
                inputs.append(bc)
        for src in inputs:
            # Baseline: the same opt reading and writing the same file with no pass. opt's reader and
            # writer are not the pass (ModuleID, use-list order, intrinsic attribute upgrades, the
            # bitcode header), so the identity is measured against them (NORTHSTAR goal 4, tier 1).
            base = Path(tmp) / f"base{src.suffix}"
            cmd = [opt, str(src), "-o", str(base)] + (["-S"] if src.suffix == ".ll" else [])
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                fail(f"baseline {src.name}: {r.stderr.strip()}")
                continue
            for i, flags in enumerate(flagsets):
                out = Path(tmp) / f"out{i}{src.suffix}"
                cmd = [opt, f"-load-pass-plugin={plugin}", "-passes=cq-lower", *flags, str(src), "-o", str(out)]
                if src.suffix == ".ll":
                    cmd.append("-S")
                r = subprocess.run(cmd, capture_output=True, text=True)
                if r.returncode != 0:
                    fail(f"passthrough {src.name} {flags}: exit {r.returncode}: {r.stderr.strip()}")
                elif r.stdout or r.stderr:
                    fail(f"passthrough {src.name} {flags}: unexpected output {r.stdout + r.stderr!r}")
                elif out.read_bytes() != base.read_bytes():
                    fail(f"passthrough {src.name} {flags}: output differs from opt with no pass")
                else:
                    n += 1
    print(f"passthrough: {n}/{len(inputs) * len(flagsets)} runs byte-identical")


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
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
