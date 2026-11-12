#!/usr/bin/env python3
"""tests/bundle (cq-w1-bundle): the version 1 injection bundle against the corpus.

    check_bundle.py --spec <CQ_spec> [--sources <dir with musl/ and llvm-project/>]

1. bundle/manifest.json lists exactly the pinned output of bundle/pins.json, and that file has the pinned
   sha256.
2. The bundle is closed (no undefined symbols but llvm.* intrinsics and the functions bundle/recipe.json omits, host
   calls, or names bodiless) and defines the bead's functions, the rule 16 string formatters over their internal cores, and the result
   entries of recipe.json "entries" (cq-cdf9z) as external functions; it defines no omitted name and no standard
   stream (owner ruling 2026-11-11 Q6).
3. For every example whose reference lowered.ll lifts a library body (a __cq_q_<fn>_* definition for an <fn>
   that is not user code of the example) or whose .O1.ll calls a bundle function: `llvm-link --only-needed`
   of the .O1.ll with the bundle succeeds; every lifted library <fn> is in the bundle; a body the .O1.ll
   already defines (the compiler-rt reproductions) is kept, never replaced by the bundle's.
4. The bundle defines nothing beyond those: every bundle function is lifted by some reference, called by
   some example's .O1.ll, or called by another bundle function so reached.
5. count_probe.c, linked --only-needed with the bundle and run natively: the result entries and string formatters
   compute musl's values (cq-cdf9z).
With --sources, the bundle is also rebuilt from the pinned checkouts and must reproduce the pinned sha256.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUNDLE = ROOT / "bundle"
LLVM_BIN = Path("/usr/local/opt/llvm@19/bin")
# The bead's list (cq-w1-bundle): compiler-rt's complex helpers, musl memcmp and the libm bodies the
# helpers call. ilogb/ilogbf/ilogbl are reached from logb/logbf/logbl (musl keeps them in their own TUs).
REQUIRED = {"__muldc3", "__divdc3", "__mulsc3", "__divsc3", "__mulxc3", "__divxc3", "memcmp",
            "logb", "scalbn", "logbf", "scalbnf", "logbl", "scalbnl",
            # rule 18, Q5 (8dcb7c47): the libm bodies a math intrinsic links by a declaration of its name
            "exp", "atan2", "atan", "sin", "log", "pow", "fabs", "floor"}
# CR rule 16: the string formatters are injected and lifted (cq-cdf9z)
FORMATTERS = {"sprintf", "snprintf", "sscanf", "vsprintf", "vsnprintf", "vsscanf",
              "swprintf", "vswprintf", "swscanf", "vswscanf"}
CORES = {"__cq_vfprintf", "__cq_vfscanf", "__cq_vfwprintf", "__cq_vfwscanf"}
STD_STREAMS = {"stdin", "stdout", "stderr", "__stdin_FILE", "__stdout_FILE", "__stderr_FILE",
               "__stdin_used", "__stdout_used", "__stderr_used"}

fails = []


def fail(msg):
    fails.append(msg)
    print("FAIL:", msg)


def run(cmd, **kw):
    return subprocess.run([str(c) for c in cmd], capture_output=True, text=True, **kw)


def demangle(sym):  # Mach-O C symbols carry a leading underscore
    return sym[1:] if sym.startswith("_") else sym


def nm(path, flag):
    r = run([LLVM_BIN / "llvm-nm", flag, "--format=just-symbols", path])
    if r.returncode:
        fail(f"llvm-nm {path}: {r.stderr.strip()}")
        return set()
    return {demangle(s) for s in r.stdout.split()}


def calls(ll_text):
    """Called functions of every body in a textual module: name -> set of direct callees."""
    out, cur = {}, None
    for line in ll_text.splitlines():
        m = re.match(r"^define [^@]*@([\w.$]+)\(", line)
        if m:
            cur = m.group(1)
            out[cur] = set()
            continue
        if line.startswith("}"):
            cur = None
        elif cur:
            for c in re.findall(r"\bcall [^@;]*@([\w.$]+)\(", line.split(";")[0]):
                out[cur].add(c)
    return out


def body_refs(ll_text):
    """Every name each body, global initializer or alias refers to (calls, addresses taken): name -> set."""
    out, cur = {}, None
    for line in ll_text.splitlines():
        g = re.match(r'^@([\w.$]+) = (.*)$', line)
        if g and cur is None:
            out.setdefault(g.group(1), set()).update(re.findall(r"@([\w.$]+)", g.group(2)))
            continue
        m = re.match(r'^define [^@]*@([\w.$]+)\(', line)
        if m:
            cur = m.group(1)
            out[cur] = set()
            continue
        if line.startswith("}"):
            cur = None
        elif cur:
            out[cur] |= set(re.findall(r"@([\w.$]+)", line.split(";")[0]))
    return out


def lifted(lowered_text):
    """<fn> of every __cq_q_<fn>_<mask>[...] definition (CR §1.4 names)."""
    out = set()
    for name in re.findall(r"^define [^@]*@__cq_q_([\w.$]+)\(", lowered_text, re.M):
        name = re.sub(r"(_t)?(_ctl)?(_pure)?(_unc)?$", "", name)
        name = re.sub(r"_b\d+(_\d+)*$", "", name)
        m = re.match(r"^(.*)_[01]+$", name)
        out.add(m.group(1) if m else name)
    return out


def opcodes(module, fn, tmp):
    r = run([LLVM_BIN / "llvm-extract", f"--func={fn}", "-S", module, "-o", tmp / f"{fn}.ll"])
    if r.returncode:
        return None
    body = (tmp / f"{fn}.ll").read_text()
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}", body, re.M | re.S)
    return [re.sub(r"%[\w.]+ = ", "", l.split(";")[0]).split()[0] for l in m.group(0).splitlines()[1:-1]
            if l.strip() and not l.split(";")[0].rstrip().endswith(":") and l.split(";")[0].strip()]


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True, type=Path)
    ap.add_argument("--sources", type=Path)
    a = ap.parse_args(argv)
    pins = json.loads((BUNDLE / "pins.json").read_text())
    out = BUNDLE / pins["output"]

    # 1.
    man = json.loads((BUNDLE / "manifest.json").read_text())
    if man != [pins["output"]]:
        fail(f"manifest.json {man} != [{pins['output']!r}]")
    if not out.exists():
        fail(f"{out} missing")
        return 1
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    if digest != pins["sha256"]:
        fail(f"{out.name} sha256 {digest} != pinned {pins['sha256']}")

    # 2.
    recipe = json.loads((BUNDLE / "recipe.json").read_text())
    omit = set(recipe["omit"])
    entries = set(recipe["entries"])
    und = {u for u in nm(out, "--undefined-only")
           if not u.startswith("llvm.") and u not in omit and u not in recipe["bodiless"]}
    if und:
        fail(f"bundle not closed, undefined: {sorted(und)}")
    defined = nm(out, "--defined-only")
    exported = nm(out, "--extern-only") & defined
    want = REQUIRED | FORMATTERS | entries
    if not want <= exported:
        fail(f"bundle lacks (as external definitions) {sorted(want - exported)}")
    if not CORES <= defined:
        fail(f"bundle lacks the formatter cores {sorted(CORES - defined)}")
    if defined & (omit | STD_STREAMS):
        fail(f"bundle defines omitted names or standard streams: {sorted(defined & (omit | STD_STREAMS))}")
    text = run([LLVM_BIN / "llvm-dis", out, "-o", "-"]).stdout
    stds = sorted(n for n in STD_STREAMS if re.search(rf"@{n}\b", text))
    if stds:
        fail(f"bundle refers to standard streams {stds}")
    bundle_calls = body_refs(text)

    # 3.
    reached = set()
    owned = []
    with tempfile.TemporaryDirectory(prefix="cqbundle-test.") as t:
        tmp = Path(t)
        for ex in sorted((a.spec / "examples").iterdir()):
            o1s = sorted(ex.glob("*.O1.ll"))
            refs = sorted(ex.glob("*.lowered.ll"))
            if not o1s or not refs:
                continue
            o1_text = o1s[0].read_text()
            o1_calls = calls(o1_text)
            o1_defined = set(o1_calls)
            o1_called = set().union(*o1_calls.values()) if o1_calls else set()
            lib = {f for f in lifted(refs[0].read_text()) if f not in o1_defined or f in defined}
            uses = (o1_called - o1_defined) & defined
            if not lib and not uses:
                continue
            owned.append(ex.name)
            reached |= lib | uses
            missing = lib - defined
            if missing:
                fail(f"{ex.name}: the reference lifts {sorted(missing)}, not in the bundle")
            linked = tmp / f"{ex.name}.bc"
            r = run([LLVM_BIN / "llvm-link", o1s[0], "--only-needed", out, "-o", linked])
            if r.returncode:
                fail(f"{ex.name}: llvm-link with the bundle: {r.stderr.strip()}")
                continue
            ldef = nm(linked, "--defined-only")
            lund = {u for u in nm(linked, "--undefined-only") if u in defined}
            if lund:
                fail(f"{ex.name}: bundle functions still undefined after the link: {sorted(lund)}")
            for f in sorted(lib):
                if f not in ldef:
                    fail(f"{ex.name}: {f} not defined after the link")
            for f in sorted(o1_defined & defined):
                mine, theirs = opcodes(linked, f, tmp), opcodes(o1s[0], f, tmp)
                if not mine or not theirs:
                    fail(f"{ex.name}: cannot extract {f}")
                elif mine != theirs:
                    fail(f"{ex.name}: the link replaced the .O1.ll's own body of {f}")
            print(f"{ex.name}: linked; lifts {sorted(lib)}; calls {sorted(uses - lib)}")

    # 4.
    closure, todo = set(), list(reached)
    while todo:
        f = todo.pop()
        if f in closure or f not in defined:
            continue
        closure.add(f)
        todo += bundle_calls.get(f, set()) | {d for d in bundle_calls.get("_" + f, set())}
    closure |= REQUIRED | FORMATTERS | entries  # required whether or not the corpus calls them
    todo = list(closure)
    while todo:
        f = todo.pop()
        for c in bundle_calls.get(f, set()):
            if c in defined and c not in closure:
                closure.add(c)
                todo.append(c)
    extra = defined - closure
    if extra:
        fail(f"bundle defines functions nothing reaches: {sorted(extra)}")
    print(f"examples: {' '.join(owned)}")
    print(f"bundle: {sorted(defined)}")

    # 5.
    with tempfile.TemporaryDirectory(prefix="cqbundle-probe.") as t:
        tmp = Path(t)
        probe = Path(__file__).resolve().parent / "count_probe.c"
        steps = [[LLVM_BIN / "clang", "-O1", "-w", "-D_FORTIFY_SOURCE=0", "-c", "-emit-llvm", probe, "-o", tmp / "p.bc"],
                 [LLVM_BIN / "llvm-link", tmp / "p.bc", "--only-needed", out, "-o", tmp / "pl.bc"],
                 [LLVM_BIN / "clang", "-O1", tmp / "pl.bc", "-o", tmp / "probe"], [tmp / "probe"]]
        for cmd in steps:
            r = run(cmd)
            if r.returncode:
                fail(f"count probe: {Path(str(cmd[0])).name} exited {r.returncode}: {(r.stderr or r.stdout).strip()[:600]}")
                break
        else:
            print("count probe: pass")

    if a.sources:
        with tempfile.TemporaryDirectory(prefix="cqbundle-rebuild.") as t:
            dest = Path(t) / pins["output"]
            r = run([sys.executable, BUNDLE / "build.py", "--musl", a.sources / "musl",
                     "--llvm-project", a.sources / "llvm-project", "--out", dest])
            if r.returncode:
                fail(f"rebuild: {r.stderr.strip()}")
            elif hashlib.sha256(dest.read_bytes()).hexdigest() != pins["sha256"]:
                fail("rebuild does not reproduce the pinned sha256")
            else:
                print("rebuild: reproduces the pinned sha256")

    print("bundle:", "FAIL" if fails else "PASS")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
