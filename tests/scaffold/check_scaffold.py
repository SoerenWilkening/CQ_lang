#!/usr/bin/env python3
"""Acceptance test of cq-w0-scaffold.

1. spec.lock holds (tools/spec_lock.py).
2. The frozen headers equal cq-arch's text with the owner's amendments A1-A4 and freeze beads K1
   (cq-k1w), S1 (cq-sml), P1 (cq-6yb), M1 (cq-mgi) and C1 (cq-4cy): pass/include/cq/*.h, checker/rt/cqe.h, and
   the dataclass fields of checker/cqcheck/contracts.py. cq-arch is read live from beads (`bd show cq-arch --json`) unless
   --arch-json names a saved copy.
3. `opt -passes=cq-lower` on every example `.O1.ll` (counted from the directory) exits non-zero with
   `cq: unimplemented: <module>: <function>` and writes no output file and nothing to stdout.
4. A module with no CQ.h call comes out byte-identical (.ll and .bc, with and without the K flags) to
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
    # S1 (freeze bead cq-sml, final text in a cq-arch comment): the K channel into construct().
    ("class PathPredicates; struct Pred;",
     ["namespace loops { struct KOptions; }"], "after"),
    ("  LoweringContext(llvm::Module &, const TaintInfo &, const Specialization &);",
     ["  LoweringContext(llvm::Module &, const TaintInfo &, const Specialization &, const loops::KOptions &);"],
     "replace"),
    ("void construct(llvm::Module &, const TaintInfo &, const Specialization &);",
     ["void construct(llvm::Module &, const TaintInfo &, const Specialization &, const loops::KOptions &);"],
     "replace"),
    # P1 (freeze bead cq-6yb, final text in a cq-arch comment): rule 8's C && Q factoring.
    ("  bool isClassical(const TaintInfo &, const Specialization &) const;",
     ["  Pred classicalFactor(const TaintInfo &, const Specialization &) const;"], "after"),
]

# M1 (freeze bead cq-mgi, final text in a cq-arch comment): the op registry and the handler
# contract, as edits to cq-arch's checker/rt/cqe.h block. The '#define CQE_OP_NOT_MINE 1' line is
# checked separately (header_decls drops preprocessor lines).
C_AMENDMENTS = [
    ("void    cqe_register_op(const char *op, cqe_op_fn);   /* a family registers from a constructor */",
     [
      '/* M1 (freeze bead cq-mgi): the op registry and the handler contract.',
      ' * Registry. cqe_register_op keeps every (op, fn) pair, per op name in registration order; a second',
      ' *   registration of the same pair is a no-op. op is the exact cqe_tname.op the dispatcher looks up:',
      " *   the template's op for cq_template_*, the stem for a non-core cqrt_* call. The dispatcher calls",
      ' *   the handlers of tname.op in registration order until one returns other than CQE_OP_NOT_MINE.',
      ' *   Every handler returning CQE_OP_NOT_MINE, or none registered, is a violation (no_family).',
      " * Return. 0: out holds the value. CQE_OP_NOT_MINE: the call is outside this handler's family,",
      ' *   decided from tname and nargs alone; the handler has not called cqe_fail or cqe_log nor touched',
      ' *   a rail, and whatever it wrote to out->w is discarded (out->w is zeroed again before the next',
      ' *   handler). -1: the call is malformed and the handler has called cqe_fail; no handler follows.',
      ' * out, owned by the dispatcher. On entry out->w is non-NULL with out->nw = ceil(out->bits / 64)',
      ' *   words (at least 1), all zero, and out->bits and out->kind are preset to the result type: what',
      ' *   the template name implies, or the declared return type on the family path (bits 0 for void).',
      ' *   The handler writes the value into out->w with bits above out->bits zero. It never frees,',
      ' *   reallocates or replaces out->w, and leaves out->bits, out->kind and out->nw at their preset',
      ' *   values; anything else is a violation (result_width).',
      ' * args, owned by the dispatcher and valid for the call only.',
      ' *   Template path (cq_template_*): every argument of the forward form in signature order, literals',
      " *   included, the _unc form's leading out handle omitted: the select condition, the data operands,",
      " *   the _rm/_rmq mode, qrom_load's table, n, stride and index. Each is resolved to a value: a",
      " *   handle to a copy of its rail's value (bits and kind the rail's), a literal to its value (bits",
      " *   its LLVM type's width; kind 'f' for half, float, double, x86_fp80, else 'i'; ptr a 64-bit 'i').",
      ' *   The handler computes the forward value f(args) whatever tname->unc says; the dispatcher',
      ' *   allocates the result rail (forward) or XORs the value into the out rail and checks the',
      ' *   residue (_unc).',
      ' *   Family path (any other non-core cqrt_*): every ABI argument raw, in signature order: a handle',
      " *   as its i32 number, a literal as its value, a ptr as a 64-bit 'i'. The family manages rails",
      ' *   through cqe_new_rail, cqe_rail, cqe_xor_into and cqe_set_known and returns a handle as an i32',
      ' *   in out. */',
     ], "after"),
    # C1 (freeze bead cq-4cy, final text in a cq-arch comment): the family path's names, arguments,
    # roles and end of shot, inserted after M1's last line.
    (" *   in out. */",
     [
      "/* C1 (freeze bead cq-4cy): the family path's names, arguments, roles and end of shot.",
      ' * Names. A cqrt_ symbol that is not a core gate (alloc, free, measure, ry*, rz_*, not/and/or/xor_i1,',
      ' *   copy*, xorc*, push, pop) is cqrt_<op>[_<W>][_hl|_lit][_controlled][_unc], op the longest of',
      ' *   qram_alloc, qram_realloc, qram_store, qram_load, qram_free, tape_alloc, tape_fmt, tape_effect,',
      ' *   tape_write, tape_write_str, abort that matches, W a width token i<N> or f<N>. Any other cqrt_',
      ' *   name is a violation (unknown_symbol). The dispatcher passes a zeroed cqe_tname with op = <op>,',
      ' *   w = W ("" if absent), shape = "hl" for _hl and "l" for _lit, pred = "ctl" for _controlled,',
      ' *   unc = 1 for _unc; to, rm, exc and strided stay 0. A family registers the bare op only; telling',
      ' *   _controlled by arity agrees with pred. Examples: cqrt_tape_write_i8_lit is {op "tape_write",',
      ' *   w "i8", shape "l"}; cqrt_tape_write_str_lit is {op "tape_write_str", shape "l"}; cqrt_abort_i1 is',
      ' *   {op "abort", w "i1"}; cqrt_tape_effect_controlled is {op "tape_effect", pred "ctl"};',
      ' *   cqrt_qram_store_i32_hl_controlled_unc is {op "qram_store", w "i32", shape "hl", pred "ctl", unc 1}.',
      " * Arguments (family path). args[i] is the i-th argument of the declared ABI signature, an _unc's",
      " *   leading out handle included: an i32 handle is a 32-bit 'i' holding its number; a literal has",
      " *   bits its LLVM type's width and kind 'f' for half, float, double, x86_fp80, else 'i'; a ptr is a",
      " *   64-bit 'i' holding the host address it points to in the running program, dereferenceable for",
      ' *   the call only (a family that keeps a string or a table copies it).',
      ' * Roles. The dispatcher, not the family, sets the exit role of tape and abort rails: before the',
      ' *   handler runs, argument 0 of abort becomes role "abort"; every rail cqe_new_rail creates during',
      ' *   a tape_write call becomes role "tape". The exit event reports such a live rail with that role,',
      ' *   as kept. A cqrt_free of a tape or abort rail is a violation (free_forbidden) whatever its value',
      ' *   and known flag, also after an _unc returned it to 0. Handles are never reused; cqe_rail of a',
      ' *   freed or unknown handle records a violation and returns NULL.',
      ' * End of shot. Every cqe_* entry, cqe_register_op included, initializes the core first, and the core',
      " *   registers its exit handler with atexit when it initializes. A family's atexit handler registered",
      ' *   after its first cqe_* call therefore runs before the exit event, with cqe_rail, cqe_log and',
      ' *   cqe_fail valid. */',
     ], "after"),
]
C_DEFINES = ["#define CQE_OP_NOT_MINE 1"]

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
    for anchor, new, mode in C_AMENDMENTS:
        want_c = patch(want_c, anchor, new, mode)
    got_c = header_decls(ROOT / "checker/rt/cqe.h", c_header=True)
    cqe_text = (ROOT / "checker/rt/cqe.h").read_text()
    missing = [d for d in C_DEFINES if not re.search(r"^" + re.escape(d) + r"(\s|$)", cqe_text, re.M)]
    if got_c != want_c or missing:
        fail(f"checker/rt/cqe.h differs from cq-arch (+M1, C1){'; missing ' + str(missing) if missing else ''}")
        for a, b in zip(got_c + [""] * len(want_c), want_c + [""] * len(got_c)):
            if a != b:
                print(f"    have: {a!r}\n    want: {b!r}")
                break
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
    print(f"headers: {n} interfaces compared against cq-arch (+A1-A4, K1, S1, P1, M1, C1)")


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
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
