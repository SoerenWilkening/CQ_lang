#!/usr/bin/env python3
"""tests/driver (cq-w1-driver): cqcc end to end with the real plugin.

Fails on any of:
  corpus      cqcc -S on an example's .c differs from opt -passes=cq-lower on its .O1.ll (linked with the
              injection bundle --only-needed when the manifest lists one and the .O1.ll declares, without a
              body, a symbol the bundle defines), modulo the ModuleID comment and source_filename; or,
              where the reference run fails, cqcc does not fail with the same "cq: ..." error and no output
  bundle      with a non-empty manifest, a module declaring memcmp and logb does not get exactly the
              bundle's bodies for them (and not the unrelated complex runtime), or the result is not the pass's
              identity; with the empty manifest, they do not stay declarations; a module declaring
              nothing of the bundle (identity) is relinked
  identity    a TU with no taint is not byte-identical to opt with no passes on the module cqcc gave the
              pass, or (one TU) to opt -S of clang -O1 -S -emit-llvm -include CQ.h output
  K           -cq-k / -cq-k-default do not reach the pass (its own usage errors must come back), or a
              CQ_K line's constant is missing from the pass input or output (same TU and another TU)
  cq-check    --cq-check does not run `python3 -m cqcheck user` on the linked and lowered modules with
              the entry and sample count, or cqcc's status differs from cqcheck user's own
  link        -c does not give an object, or an executable built with a --backend object prints a
              wrong value

Default corpus examples: a handful (the bead iterates on few); --examples NN_name... or --all for more.
--manifest FILE (or CQ_BUNDLE_MANIFEST) tests against another bundle manifest than bundle/manifest.json.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CQCC = ROOT / "driver" / "cqcc"
SRC = HERE / "src"
LLVM = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
DEFAULT_EXAMPLES = ["01_add_classical_const", "02_add_quantum_quantum", "03_phase_arm_eq", "13_fp_arith",
                    "42_measure_one_of_two", "05_while_quantum_cond"]

failures = []


def fail(test, msg):
    failures.append(f"{test}: {msg}")
    print(f"FAIL {test}: {msg}")


def ok(test):
    print(f"ok   {test}")


def run(cmd, **kw):
    return subprocess.run([str(c) for c in cmd], capture_output=True, **kw)


def cqcc(*args, cwd=None):
    return run([sys.executable, CQCC, *args], cwd=cwd, text=True, env=ENV)


def strip_ids(text):
    return [ln for ln in text.splitlines() if not ln.startswith(("; ModuleID = ", "source_filename = "))]


def cq_error(stderr):
    m = re.search(r"^.*\bcq: .*$", stderr, re.M)
    return m.group(0)[m.group(0).index("cq: "):] if m else None


def bundle_files():
    import json
    man = Path(ENV.get("CQ_BUNDLE_MANIFEST", ROOT / "bundle" / "manifest.json"))
    return [(man.parent / p).resolve() for p in json.loads(man.read_text())]


def ext_syms(path, flag, tmp):
    """External symbols of an IR file per llvm-nm (bitcode only, so .ll is assembled first)."""
    path = Path(path)
    if path.suffix == ".ll":
        bc = tmp / (path.name + ".syms.bc")
        run([LLVM / "llvm-as", path, "-o", bc])
        path = bc
    out = run([LLVM / "llvm-nm", flag, "--extern-only", "--format=just-symbols", path], text=True).stdout
    return set(out.split())


def needs_bundle(module, b, tmp):
    """The bundle rule: link iff the module declares without a body a symbol some bundle file defines."""
    defined = set().union(*(ext_syms(f, "--defined-only", tmp) for f in b)) if b else set()
    return bool(defined & ext_syms(module, "--undefined-only", tmp))


def test_corpus(examples, spec, plugin, tmp):
    for ex in examples:
        d = spec / "examples" / ex
        base = ex.split("_", 1)[1]
        c, o1 = d / f"{base}.c", d / f"{base}.O1.ll"
        ref_in = o1
        b = bundle_files()
        if b and needs_bundle(o1, b, tmp):
            ref_in = tmp / f"{ex}.ref.bc"
            r = run([LLVM / "llvm-link", o1, "--only-needed", *b, "-o", ref_in])
            if r.returncode:
                fail(f"corpus {ex}", "llvm-link of the reference with the bundle: " + r.stderr.decode())
                continue
        with open(ref_in, "rb") as f:
            ref = run([LLVM / "opt", f"-load-pass-plugin={plugin}", "-passes=cq-lower", "-S"], stdin=f, text=False)
        out = tmp / f"{ex}.lowered.ll"
        r = cqcc("-S", c.name, "-o", out, cwd=d)
        if ref.returncode == 0:
            if r.returncode:
                fail(f"corpus {ex}", f"cqcc failed where opt on the .O1.ll lowers: {r.stderr.strip()[-400:]}")
            elif strip_ids(out.read_text()) != strip_ids(ref.stdout.decode()):
                fail(f"corpus {ex}", "lowered module differs from opt -passes=cq-lower on the .O1.ll")
            else:
                ok(f"corpus {ex} (same lowered module)")
        else:
            want = cq_error(ref.stderr.decode())
            got = cq_error(r.stderr)
            if r.returncode == 0 or out.exists():
                fail(f"corpus {ex}", "cqcc succeeded or wrote output where opt on the .O1.ll fails")
            elif want != got:
                fail(f"corpus {ex}", f"different internal error: reference {want!r}, cqcc {got!r}")
            else:
                ok(f"corpus {ex} (same internal error, nothing emitted: {got})")


def opt_identity(module):
    with open(module, "rb") as f:
        return run([LLVM / "opt", "-S"], stdin=f).stdout


def test_identity(spec, tmp):
    # one TU
    d = tmp / "id1"
    out = tmp / "classical.ll"
    r = cqcc("-S", SRC / "classical.c", "-o", out, "--save-temps", d)
    if r.returncode:
        fail("identity one TU", r.stderr)
    else:
        got = out.read_bytes()
        if got != opt_identity(d / "linked.ll"):
            fail("identity one TU", "not byte-identical to opt with no passes on the pass input")
        else:
            ok("identity one TU: byte-identical to opt with no passes")
        # The driver adds nothing of its own: the output is plain clang -O1 output read and written by
        # LLVM (the reader normalizes intrinsic attributes, so raw clang text is no fixed point).
        direct = tmp / "classical.direct.ll"
        run([LLVM / "clang", "-O1", "-include", spec / "CQ.h", "-S", "-emit-llvm", SRC / "classical.c",
             "-o", direct])
        if got != opt_identity(direct):
            fail("identity one TU", "differs from opt -S of clang -O1 -S -emit-llvm output")
        else:
            ok("identity one TU: byte-identical to opt -S of plain clang -O1 output")
    # two TUs through llvm-link
    d = tmp / "id2"
    out = tmp / "classical2.ll"
    r = cqcc("-S", SRC / "classical.c", SRC / "classical_main.c", "-o", out, "--save-temps", d)
    if r.returncode:
        fail("identity two TUs", r.stderr)
    elif out.read_bytes() != opt_identity(d / "linked.ll"):
        fail("identity two TUs", "not byte-identical to opt with no passes on the pass input")
    else:
        ok("identity two TUs: byte-identical to opt with no passes")
    # and it runs
    exe = tmp / "classical.exe"
    r = cqcc(SRC / "classical.c", SRC / "classical_main.c", "-o", exe)
    ref_exe = tmp / "classical.ref.exe"
    run([LLVM / "clang", "-O1", SRC / "classical.c", SRC / "classical_main.c", "-o", ref_exe])
    if r.returncode or run([exe]).stdout != run([ref_exe]).stdout:
        fail("identity executable", r.stderr or "output differs from the plain clang build")
    else:
        ok("identity executable runs like the plain clang build")


def test_bundle(tmp):
    b = bundle_files()
    d = tmp / "bundle"
    out = tmp / "bundle_user.ll"
    r = cqcc("-S", SRC / "bundle_user.c", "-o", out, "--save-temps", d)
    if r.returncode:
        fail("bundle", r.stderr)
        return
    linked = d / "linked.ll"
    defined = ext_syms(linked, "--defined-only", tmp)
    lib = {"_memcmp", "_logb"}
    if b:
        offered = set().union(*(ext_syms(f, "--defined-only", tmp) for f in b))
        if not lib <= offered:
            fail("bundle", f"manifest bundle does not define {sorted(lib - offered)}; cannot test linking")
            return
        # --only-needed: logb's body may pull ilogb in, but nothing of the complex runtime
        extra = {x for x in defined & offered if re.fullmatch(r"___(mul|div)[sdx]c3", x)}
        if not lib <= defined:
            fail("bundle", f"bodies of {sorted(lib - defined)} not linked from the bundle")
        elif extra:
            fail("bundle", f"bundle symbols linked though nothing needs them: {sorted(extra)}")
        elif out.read_bytes() != opt_identity(linked):
            fail("bundle", "not byte-identical to opt with no passes on the pass input")
        else:
            ok("bundle: memcmp and logb bodies linked --only-needed, pass is the identity")
    else:
        if defined & lib or not lib <= ext_syms(linked, "--undefined-only", tmp):
            fail("bundle (empty manifest)", "memcmp/logb are not plain declarations")
        else:
            ok("bundle (empty manifest): memcmp and logb stay declarations")


def test_k(tmp):
    out = tmp / "k.ll"
    r = cqcc("-v", "-S", SRC / "kfun.c", "-cq-k=add_q=7,other=3", "-cq-k-default=5", "-o", out)
    opt_line = [l for l in r.stderr.splitlines() if "-passes=cq-lower" in l]
    if r.returncode or not opt_line or "-cq-k=add_q=7,other=3" not in opt_line[0].split() \
            or "-cq-k-default=5" not in opt_line[0].split():
        fail("K flags on the opt line", r.stderr)
    else:
        ok("K flags on the opt line")
    # the pass parses them: its own usage errors come back, on a tainted and on an untainted module
    for src in ("kfun.c", "classical.c"):
        for flag, msg in (("-cq-k=add_q=0", "cq: -cq-k: expected <fn>=<k> with k >= 1, got 'add_q=0'"),
                          ("-cq-k-default=0", "cq: -cq-k-default: expected k >= 1")):
            out = tmp / f"bad.{src}.{flag[1:5]}.ll"
            r = cqcc("-S", SRC / src, flag, "-o", out)
            if r.returncode == 0 or msg not in r.stderr or out.exists():
                fail(f"K {flag} reaches the pass ({src})", r.stderr)
            else:
                ok(f"K {flag} reaches the pass ({src}): its usage error, nothing emitted")
    # CQ_K lines: the used constant reaches the pass input and survives in the output
    for name, srcs, k in (("same TU", ["kfun.c"], ("add_q", 9)),
                          ("other TU", ["kline_other.c", "add_q2.c"], ("add_q2", 11))):
        d = tmp / f"kline.{k[0]}"
        out = tmp / f"kline.{k[0]}.ll"
        r = cqcc("-S", *[SRC / s for s in srcs], "--save-temps", d, "-o", out)
        pat = re.compile(r"^@__cq_k_%s = internal constant i32 %d\b" % k, re.M)
        used = re.compile(r"^@llvm\.(compiler\.)?used = .*@__cq_k_%s\b" % k[0], re.M)
        if r.returncode:
            fail(f"CQ_K {name}", r.stderr)
        elif not (pat.search((d / "linked.ll").read_text()) and used.search((d / "linked.ll").read_text())):
            fail(f"CQ_K {name}", f"@__cq_k_{k[0]} = {k[1]} (used) missing from the pass input")
        elif not pat.search(out.read_text()):
            fail(f"CQ_K {name}", f"@__cq_k_{k[0]} missing from the lowered module")
        else:
            ok(f"CQ_K {name}: @__cq_k_{k[0]} = {k[1]} reaches the pass")


def test_check(tmp):
    d = tmp / "chk"
    out = tmp / "chk.ll"
    r = cqcc("-v", "-S", SRC / "kfun.c", "--cq-check", "--cq-entry", "add_q", "--cq-samples", "4",
             "--save-temps", d, "-o", out)
    o1, low = (d / "linked.ll").resolve(), (d / "lowered.ll").resolve()
    want = ["-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(low), "--entry", "add_q", "--samples", "4"]
    line = [l.split() for l in r.stderr.splitlines() if "cqcheck user" in " ".join(l.split()[:4])]
    direct = run([sys.executable, *want], cwd=ROOT / "checker", text=True, env=ENV)
    if not line or line[0][1:] != want:
        fail("--cq-check command", r.stderr)
    elif not out.exists():
        fail("--cq-check output", "lowered module not written")
    elif r.returncode != direct.returncode or direct.stdout != r.stdout:
        fail("--cq-check status", f"cqcc {r.returncode}, cqcheck user {direct.returncode}")
    else:
        ok(f"--cq-check runs cqcheck user (status {direct.returncode}, propagated)")


def test_link(tmp):
    backend = tmp / "toy_backend.o"
    run([LLVM / "clang", "-c", SRC / "toy_backend.c", "-o", backend])
    obj = tmp / "kfun.o"
    r = cqcc("-c", SRC / "kfun.c", "-o", obj)
    nm = run([LLVM / "llvm-nm", obj], text=True).stdout if obj.exists() else ""
    if r.returncode or not re.search(r"U _cqrt_alloc_i32\b", nm) or not re.search(r"T _add_q\b", nm):
        fail("-c object", r.stderr + nm)
    else:
        ok("-c: one object, add_q defined, the ABI undefined")
    exe = tmp / "q.exe"
    r = cqcc(SRC / "qmain.c", SRC / "kfun.c", "--backend", backend, "-o", exe)
    got = run([exe], text=True).stdout.strip() if exe.exists() else ""
    if r.returncode or got != "8":
        fail("executable with --backend", r.stderr + got)
    else:
        ok("executable linked with --backend prints add_q(5, 0, 3) = 8")


def test_host_link(tmp):
    """Rulings Q7, Q6: cq_host.c is linked after the pass when the lowered module asks for a host symbol."""
    main_c = tmp / "hostmain.c"
    main_c.write_text('extern int __cq_mem(void);\nint main(void) { return __cq_mem() == __cq_mem() ? 42 : 1; }\n')
    be_c = tmp / "busbackend.c"
    be_c.write_text("int cqrt_qram_alloc_i8(int n) { return 5 + n; }\n")
    backend = tmp / "busbackend.o"
    run([LLVM / "clang", "-c", be_c, "-o", backend])
    exe = tmp / "host.exe"
    r = cqcc(main_c, "--backend", backend, "-o", exe)
    code = subprocess.run([str(exe)]).returncode if exe.exists() else None
    if r.returncode or code != 42:
        fail("executable with the host object", r.stderr + str(code))
    else:
        ok("executable links bundle/host/cq_host.c when the lowered module asks for __cq_mem")
    roots = tmp / "roots.txt"
    roots.write_text("nosuchfunction_1\n")
    r = cqcc("-S", main_c, "--cq-roots", roots, "-o", tmp / "roots.ll")
    if r.returncode == 0 or "nosuchfunction" not in r.stderr + r.stdout:
        ok("--cq-roots passed through") if r.returncode == 0 else fail("--cq-roots", r.stderr)
    else:
        ok("--cq-roots reaches cq-lower")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", default=str(ROOT / "build" / "pass" / "libCQLower.so"))
    ap.add_argument("--spec", default=str(ROOT.parent / "CQ_spec"))
    ap.add_argument("--examples", nargs="*")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--manifest", help="bundle manifest (default: CQ_BUNDLE_MANIFEST or bundle/manifest.json)")
    a = ap.parse_args()
    spec = Path(a.spec).resolve()
    global ENV
    ENV = dict(os.environ, CQ_PLUGIN=str(Path(a.plugin).resolve()), CQ_SPEC_DIR=str(spec))
    if a.manifest:
        ENV["CQ_BUNDLE_MANIFEST"] = str(Path(a.manifest).resolve())
    examples = sorted(p.name for p in (spec / "examples").iterdir() if p.is_dir()) if a.all \
        else (a.examples or DEFAULT_EXAMPLES)
    with tempfile.TemporaryDirectory(prefix="cq-driver-test.") as t:
        tmp = Path(t)
        test_corpus(examples, spec, Path(a.plugin).resolve(), tmp)
        test_identity(spec, tmp)
        test_bundle(tmp)
        test_k(tmp)
        test_check(tmp)
        test_link(tmp)
        test_host_link(tmp)
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


ENV = None
if __name__ == "__main__":
    sys.exit(main())
