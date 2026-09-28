#!/usr/bin/env python3
"""mutants.py [--setup] [NAME ...]

The mutation matrix for bd nlfd / bd ev3m / the clone-musttail demotion. A SCRATCH copy of
this worktree's sources (ir-pass, include, runtime, tools, tests, CMakeLists.txt) is built in
its own build dir, so no binary a measurement of the real worktree reads is ever relinked.
Each mutant: restore the pristine sources, apply ONE anchored replacement (the anchor must
occur exactly once, else abort), build CQPass + cq-opt + cq-opt-debugalloc +
cq-scrub-selftest, refuse a binary equal to the base (except the null mutant, which MUST be
equal), then run the FULL lit suite (`lit -j4`, through the scratch build's own site config)
and record failed / discovered and the failing fixture names.
Results: ../results/mutants.txt (appended)."""
import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import sys

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295")
SP = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd/mut")
SRC, PRISTINE, BLD = SP / "src", SP / "pristine", SP / "build"
RES = pathlib.Path(__file__).resolve().parent.parent / "results" / "mutants.txt"
DIRS = ["ir-pass", "include", "runtime", "tools", "tests", "cmake"]
FILES = ["CMakeLists.txt"]

M = {
    "N0_null": ("ir-pass/src/DeadValueLiveness.cpp",
                "bool isUnreadScalarSlot(const CallBase &CB, unsigned ArgNo,",
                "// mutation-matrix null mutant: a comment only\nbool isUnreadScalarSlot(const CallBase &CB, unsigned ArgNo,"),
    "N1_no_argument_clause": ("ir-pass/src/DeadValueLiveness.cpp",
                "if ((Mode == SlotReads::Value || isa<Argument>(U.get())) &&",
                "if ((Mode == SlotReads::Value) &&"),
    "N2_no_scalar_type_test": ("ir-pass/src/DeadValueLiveness.cpp",
                "  return T->isIntegerTy() || T->isFloatingPointTy();\n}",
                "  (void)T;\n  return true;\n}"),
    "N3_no_strip": ("ir-pass/src/Specialization.cpp",
                "              stripUnreadSlotValueConstraints(*CB, CB->getArgOperandNo(&U));",
                "              (void)0;"),
    "N4_fence_structural": ("ir-pass/src/Specialization.cpp",
                "    const uint64_t ValueDead =\n        deadParamMask(*Clone, taint, SlotReads::Value) & HandleLive;",
                "    uint64_t ValueDead = 0;\n    for (Instruction &I : instructions(*Clone))\n      if (auto *CB = dyn_cast<CallBase>(&I))\n        for (unsigned A = 0, E = CB->arg_size(); A < E; ++A)\n          if (isa<Instruction>(CB->getArgOperand(A)) && isUnreadScalarSlot(*CB, A, taint) &&\n              !isRewritableDeadSlot(*CB, A, taint))\n            ValueDead = HandleLive;"),
    "N5_no_handle_mask": ("ir-pass/src/Specialization.cpp",
                "if (const uint64_t HandleLive = Mask & ~DeadSlots) {",
                "if (const uint64_t HandleLive = ~uint64_t(0) & ~DeadSlots) {"),
    "N6_no_fence": ("ir-pass/src/Specialization.cpp",
                "    if (ValueDead) {\n      DebugLoc Where;",
                "    if (false && ValueDead) {\n      DebugLoc Where;"),
    "E1_musttail_refused": ("ir-pass/src/SpecializeDetect.cpp",
                "      if (!dropEligibleCallee(Callee) ||\n          CI->getFunctionType() != Callee->getFunctionType())",
                "      if (!dropEligibleCallee(Callee) || CI->isMustTailCall() ||\n          CI->getFunctionType() != Callee->getFunctionType())"),
    "D1_no_demotion": ("ir-pass/src/SpecializeClone.cpp",
                "        CI->setTailCallKind(CallInst::TCK_None);",
                "        (void)CI;"),
}


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]


def sync(dst):
    for d in DIRS:
        if (dst / d).exists():
            shutil.rmtree(dst / d)
        shutil.copytree(W / d, dst / d, ignore=shutil.ignore_patterns("Output", "*.pyc", "__pycache__"))
    for f in FILES:
        shutil.copy2(W / f, dst / f)


def build():
    r = sh(["cmake", "--build", str(BLD), "-j4", "--target", "CQPass", "cq-opt", "cq-opt-debugalloc",
            "cq-scrub-selftest"])
    if r.returncode:
        raise SystemExit("BUILD FAILED\n" + r.stdout[-3000:] + r.stderr[-3000:])
    return sha(BLD / "ir-pass/cq-opt")


def setup():
    SP.mkdir(parents=True, exist_ok=True)
    for d in (SRC, PRISTINE):
        d.mkdir(exist_ok=True)
        sync(d)
    r = sh(["cmake", "-S", str(SRC), "-B", str(BLD), "-DLLVM_DIR=/usr/local/opt/llvm@19/lib/cmake/llvm",
            "-DCMAKE_BUILD_TYPE=Release"])
    if r.returncode:
        raise SystemExit(r.stderr[-2000:])
    h = build()
    (SP / "base.sha").write_text(h)
    print("base", h, "real worktree", sha(W / "build/ir-pass/cq-opt"))


def restore(files=None):
    """⚠ HARNESS DEFECT FOUND ON ITS FIRST RUN (2026-09-28): the first spelling was
    `rsync -a`, which restores a source with its OLD mtime, so `make` never recompiled a
    restored file and every later mutant carried the previous mutants' objects (the final
    rebuild hashed to D1's binary, not the base). A restore now WRITES each file fresh
    (new mtime) and `one()` rebuilds and asserts the BASE hash after every restore."""
    if files is None:
        files = [p.relative_to(PRISTINE) for d in DIRS for p in (PRISTINE / d).rglob("*") if p.is_file()]
    for rel in files:
        src, dst = PRISTINE / rel, SRC / rel
        if not dst.exists() or dst.read_bytes() != src.read_bytes():
            dst.write_bytes(src.read_bytes())


def assert_base(tag):
    h = build()
    base = (SP / "base.sha").read_text()
    if h != base:
        raise SystemExit(f"BOUNDARY CONTROL FAILED after {tag}: rebuilt {h} != base {base}")
    return h


def lit():
    r = sh(["lit", "-j4", "-v", str(BLD / "ir-pass/test")])
    out = r.stdout + r.stderr
    fails = re.findall(r"^FAIL: CQ IR-pass :: (\S+)", out, re.M)
    disc = re.search(r"Total Discovered Tests: (\d+)", out)
    passed = re.search(r"Passed\s*:\s*(\d+)", out)
    return (int(disc.group(1)) if disc else -1, int(passed.group(1)) if passed else -1, fails, out)


def one(name):
    f, a, b = M[name]
    restore()
    assert_base(f"restore before {name}")  # boundary control: the tree IS the base
    p = SRC / f
    s = p.read_text()
    if s.count(a) != 1:
        raise SystemExit(f"{name}: anchor found {s.count(a)} times")
    p.write_text(s.replace(a, b))
    h = build()
    base = (SP / "base.sha").read_text()
    if name.startswith("N0"):
        if h != base:
            raise SystemExit(f"null mutant binary {h} != base {base}")
    elif h == base:
        raise SystemExit(f"{name}: binary equal to base — mutant not applied")
    disc, passed, fails, out = lit()
    if disc < 0 or passed < 0:
        line = f"{name}\tINVALID (lit did not report)\t{out[-400:]!r}"
    else:
        v = "null" if name.startswith("N0") else ("KILLED" if fails else "MISSED")
        line = f"{name}\t{v}\tfailed {len(fails)} / discovered {disc}\tcq-opt {h}\t{' '.join(fails)}"
    print(line, flush=True)
    with open(RES, "a") as fo:
        fo.write(line + "\n")
    restore([pathlib.Path(f)])
    assert_base(f"restore after {name}")


if __name__ == "__main__":
    if "--setup" in sys.argv:
        setup()
    for n in [a for a in sys.argv[1:] if not a.startswith("--")]:
        one(n)
    if "--all" in sys.argv:
        for n in M:
            one(n)
        restore()
        print("restored; rebuild base:", assert_base("the end"))
