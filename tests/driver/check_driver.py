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
  K           -cq-k / -cq-k-default do not reach the pass, or K = 0 (owner ruling Q2 of 2026-11-15, CR §0) is
              rejected or its K-loop runs a trip, or a
              CQ_K line's constant is missing from the pass input or output (same TU), or, in a program of several
              TUs, a line is not bound by C scope before the link (CR §0, cq-z9vt): another TU's line does not reach
              the function it names; the defining TU's line does not win, or without one the largest other line;
              two statics of one name do not keep their own K, or -cq-k=f=k misses a renamed one; a CQ_K(f, 0)
              line is lost (the defining unit's 0, a static's own 0); differing lines give no warning; the lowering
              depends on the link order
  cq-check    --cq-check does not run `python3 -m cqcheck user` on the linked and lowered modules with
              the entry and sample count, or cqcc's status differs from cqcheck user's own
  link        -c does not give an object, or an executable built with a --backend object prints a
              wrong value
  library     rule 27 (cq-ywi8o): --cq-lib does not export exactly the root's own symbol and its table clone, _ctl
              form and twins (a function off the list keeps its clones internal); a program naming the list does
              not call the declared clone, or still has an effect entry; program and library do not link, or the
              executable prints a wrong value; the program lowered against the library is not §6-equal to the C
              program of both sources; a listed name is injected from the bundle; a library of a bundle function
              exports anything but its root's four clones, or does not key the row by the host's sin

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


def cqcc(*args, cwd=None, env=None):
    return run([sys.executable, CQCC, *args], cwd=cwd, text=True, env=dict(ENV, **(env or {})))


sys.path.insert(0, str(ROOT / "tests" / "loops-cutoff"))
import ktrips  # noqa: E402


def k_trips(text, fn):
    """The trip counts of fn's rolled K-loops with no received K (ktrips.counter_loops: N, at least 1 unless the
    counter is also tested before trip 0), or None where one is unknown."""
    loops = ktrips.counter_loops(ktrips.body(text, fn))
    if any(N is None for _, _, _, _, N, *_ in loops):
        return None
    return [N if top else max(N, 1) for _, _, _, _, N, top, *_ in loops]


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
    # the pass parses them: its own usage error comes back on a malformed one, on a tainted and on an untainted module
    for src in ("kfun.c", "classical.c"):
        flag, msg = "-cq-k=add_q=x", "cq: -cq-k: expected <fn>=<k> with k >= 0, got 'add_q=x'"
        out = tmp / f"bad.{src}.ll"
        r = cqcc("-S", SRC / src, flag, "-o", out)
        if r.returncode == 0 or msg not in r.stderr or out.exists():
            fail(f"K {flag} reaches the pass ({src})", r.stderr)
        else:
            ok(f"K {flag} reaches the pass ({src}): its usage error, nothing emitted")
    # K = 0 is legal (owner ruling Q2 of 2026-11-15, CR §0): accepted on a tainted and an untainted module, and the
    # K-loop of f runs no trip (at K 3 it runs 3)
    for src, flag, want in (("kunit_def_noline.c", "-cq-k=f=0", [0]), ("kunit_def_noline.c", "-cq-k-default=0", [0]),
                            ("kunit_def_noline.c", "-cq-k=f=3", [3]), ("classical.c", "-cq-k-default=0", None)):
        out = tmp / f"k0.{Path(src).stem}.{flag[1:].replace('=', '_')}.ll"
        r = cqcc("-S", SRC / src, flag, "-o", out)
        tag = f"K {flag} ({src})"
        if r.returncode or not out.exists():
            fail(tag, r.stderr)
        elif want is not None and k_trips(out.read_text(), "f") != want:
            fail(tag, f"f's K-loop runs {k_trips(out.read_text(), 'f')} trips, want {want}")
        else:
            ok(f"{tag}: accepted" + (f", f's K-loop runs {want[0]} trips" if want else ""))
    # CQ_K lines: the used constant reaches the pass input and survives in the output
    for name, srcs, k in (("same TU", ["kfun.c"], ("add_q", 9)),):
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
    # another TU (cq-z9vt, CR §0): the line, bound per unit before the link, reaches the pass as the attribute
    # "cq-k"="11" of the function it names (the external add_q2), and its constant is gone
    d = tmp / "kline.add_q2"
    r = cqcc("-S", SRC / "kline_other.c", SRC / "add_q2.c", "--save-temps", d, "-o", tmp / "kline.add_q2.ll")
    linked = "" if r.returncode else (d / "linked.ll").read_text()
    if r.returncode:
        fail("CQ_K other TU", r.stderr)
    elif not re.search(r'^attributes #\d+ = \{[^}]*"cq-k"="11"', linked, re.M) or "@__cq_k_add_q2" in linked:
        fail("CQ_K other TU", '"cq-k"="11" missing from the pass input, or @__cq_k_add_q2 still there')
    else:
        ok('CQ_K other TU: add_q2 carries "cq-k"="11" into the pass')


def fn_body(text, name):
    """The body of @name in a lowered module (its attribute group numbers dropped: they follow the link order), or
    None."""
    m = re.search(r"^define [^\n]*@%s\([^\n]*\n(?:.*\n)*?\}\n" % re.escape(name), text, re.M)
    return re.sub(r" #\d+\b", " #", m.group(0)) if m else None


def test_k_units(tmp):
    """CR §0 (owner ruling 2026-11-15, cq-z9vt): CQ_K binds per unit by C scope, before the link. Each function's
    lowered body is compared with the one-unit lowering at the K the ruling gives it, in both link orders."""
    def low(name, *args, env=None):
        out = tmp / f"ku.{name}.ll"
        r = cqcc("-S", *args, "-o", out, env=env)
        if r.returncode:
            fail(f"CQ_K units {name}", r.stderr)
            return None, r.stderr
        return out.read_text(), r.stderr

    refs = {}
    for k in (2, 5):
        refs[("f", k)] = fn_body(low(f"ref.f{k}", SRC / "kunit_def_noline.c", f"-cq-k=f={k}")[0] or "", "f")
    for src, k in (("kunit_st2.c", 2), ("kunit_st3.c", 3), ("kunit_st2.c", 6)):
        refs[("helper", k)] = fn_body(low(f"ref.h{k}", SRC / src, f"-cq-k=helper={k}")[0] or "", "__cq_q_helper_1")
    if not all(refs.values()) or len(set(refs.values())) != len(refs):
        fail("CQ_K units", "the one-unit references are missing or do not tell the K apart")
        return

    warn = re.compile(r"^cqcc: warning: CQ_K\(f, k\) differs between units", re.M)
    for what, srcs, k in (("the defining unit's line wins", ["kunit_def.c", "kunit_use3.c"], 2),
                          ("no line in the defining unit: the largest of the others",
                           ["kunit_def_noline.c", "kunit_use3.c", "kunit_use5.c"], 5)):
        for order in (srcs, srcs[::-1]):
            text, err = low("f." + "-".join(Path(s).stem for s in order), *[SRC / s for s in order])
            if text is None:
                continue
            tag = f"CQ_K units, {what} ({' '.join(order)})"
            if fn_body(text, "f") != refs[("f", k)]:
                fail(tag, f"f is not lowered at K {k}")
            elif not warn.search(err):
                fail(tag, "no warning on the differing lines")
            else:
                ok(f"{tag}: K {k}, warned")

    def helper_of(text, entry):
        """The clone of the static helper the clone of `entry` calls, normalized to __cq_q_helper_1."""
        caller = fn_body(text, f"__cq_q_{entry}_11_t") or ""
        m = re.search(r"@(__cq_q_helper(?:\.\d+)?_1)\(", caller)
        if not m:
            return None
        b = fn_body(text, m.group(1))
        return b and re.sub(r"@__cq_q_helper\.\d+_1", "@__cq_q_helper_1", b)

    for order in (["kunit_st2.c", "kunit_st3.c"], ["kunit_st3.c", "kunit_st2.c"]):
        for flag, want in (("", {"entry2": 2, "entry3": 3}), ("-cq-k=helper=6", {"entry2": 6, "entry3": 6})):
            text, err = low("st." + "-".join(Path(s).stem for s in order) + flag, *[SRC / s for s in order],
                            *([flag] if flag else []))
            if text is None:
                continue
            tag = f"CQ_K units, two statics of one name {flag or 'with their own lines'} ({' '.join(order)})"
            bad = [e for e, k in want.items() if helper_of(text, e) != refs[("helper", k)]]
            if bad:
                fail(tag, f"the helper of {', '.join(bad)} is not lowered at its K ({want})")
            elif "warning" in err:
                fail(tag, "a warning for statics, which never conflict")
            else:
                ok(f"{tag}: {want}")

    # K2 likewise: two statics mk of one name, each allocating at its own K2 (100, 200) in both link orders
    for order in (["kunit_k2_100.c", "kunit_k2_200.c"], ["kunit_k2_200.c", "kunit_k2_100.c"]):
        text, err = low("k2." + "-".join(Path(s).stem for s in order), *[SRC / s for s in order])
        if text is None:
            continue
        tag = f"CQ_K2 units, two statics of one name ({' '.join(order)})"
        mks = [n for n in re.findall(r"^define [^\n]*@(__cq_q_mk[.\d]*_\d+)\(", text, re.M) if "unc" not in n]
        ks = sorted(int(m) for n in mks for m in set(re.findall(r"\bi64 ([12]00)\b", fn_body(text, n) or "")))
        if ks != [100, 200]:
            fail(tag, f"the clones {mks} allocate at K2 {ks}, want [100, 200] one each")
        else:
            ok(f"{tag}: K2 100 and 200")

    # CQ_K(f, 0) (owner ruling Q2 of 2026-11-15, CR §0: K = 0 is a K): the defining unit's 0 wins over another unit's 3,
    # and a static's own 0 is its K next to a static of the same name at 3; each lowered as the one-unit lowering at its
    # K, the K-loop at 0 running no trip, in both link orders
    r0 = {"f0": fn_body(low("ref.f0", SRC / "kunit_def_noline.c", "-cq-k=f=0")[0] or "", "f"),
          "h0": fn_body(low("ref.h0", SRC / "kunit_st0.c", "-cq-k=helper=0")[0] or "", "__cq_q_helper_1"),
          "h3": fn_body(low("ref.h3r", SRC / "kunit_st3.c", "-cq-k=helper=3")[0] or "", "__cq_q_helper_1")}
    if not all(r0.values()) or len(set(r0.values())) != len(r0):
        fail("CQ_K units, K 0", "the one-unit references are missing or do not tell the K apart")
    else:
        for order in (["kunit_def0.c", "kunit_use3.c"], ["kunit_use3.c", "kunit_def0.c"]):
            text, err = low("f0." + "-".join(Path(s).stem for s in order), *[SRC / s for s in order])
            if text is None:
                continue
            tag = f"CQ_K units, the defining unit's 0 wins over another's 3 ({' '.join(order)})"
            if fn_body(text, "f") != r0["f0"] or k_trips(text, "f") != [0]:
                fail(tag, f"f is not lowered at K 0 (trips {k_trips(text, 'f')})")
            elif not warn.search(err):
                fail(tag, "no warning on the differing lines")
            else:
                ok(f"{tag}: K 0, no trip, warned")
        for order in (["kunit_st0.c", "kunit_st3.c"], ["kunit_st3.c", "kunit_st0.c"]):
            text, err = low("st0." + "-".join(Path(s).stem for s in order), *[SRC / s for s in order])
            if text is None:
                continue
            tag = f"CQ_K units, a static's own 0 next to a static of its name at 3 ({' '.join(order)})"
            h0, h3 = helper_of(text, "entry0"), helper_of(text, "entry3")
            if h0 != r0["h0"] or h3 != r0["h3"] or k_trips(h0 or "", "__cq_q_helper_1") != [0]:
                fail(tag, "the helper of entry0 is not lowered at K 0, or that of entry3 not at 3")
            elif "warning" in err:
                fail(tag, "a warning for statics, which never conflict")
            else:
                ok(f"{tag}: 0 (no trip) and 3")

    # a function no unit defines externally keeps its constants (K and K2); a static's own lines become its
    # attributes; a static with no line is marked "none" so the constant of its name does not reach it
    d = tmp / "ku.lib"
    r = cqcc("-S", *[SRC / f"kunit_lib_{x}.c" for x in "abc"], "--save-temps", d, "-o", tmp / "ku.lib.ll")
    if r.returncode:
        fail("CQ_K units, library function", r.stderr)
        return
    linked = (d / "linked.ll").read_text()
    attrs = dict(re.findall(r"^attributes (#\d+) = \{([^}]*)\}", linked, re.M))
    fattr = {n: attrs.get(g, "") for n, g in re.findall(r"^define [^\n]*@(libf[.\d]*)\([^\n]*\) unnamed_addr (#\d+)",
                                                          linked, re.M)}
    own = [n for n, a in fattr.items() if '"cq-k"="7"' in a and '"cq-k2"="50"' in a]
    marked = [n for n, a in fattr.items() if '"cq-k"="none"' in a and '"cq-k2"="none"' in a]
    consts = (re.search(r"^@__cq_k_libf = internal constant i32 3\b", linked, re.M),
              re.search(r"^@__cq_k2_libf = internal constant i64 100\b", linked, re.M),
              re.search(r"^@__cq_k_libf2 = internal constant i32 2\b", linked, re.M))
    if len(fattr) != 2 or len(own) != 1 or len(marked) != 1 or not all(consts) or "@__cq_k_libf." in linked:
        fail("CQ_K units, library function", f"attributes {fattr}, constants {[bool(c) for c in consts]}")
    else:
        ok("CQ_K units, library function: constants kept, the static's own lines on it, the other static marked none")


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


def test_plain(tmp):
    """cq-ezgjn, cq-ywym5: a plain program through cqcc and the checker, the entry named a1."""
    out = tmp / "entry_a1.ll"
    r = cqcc("-S", SRC / "entry_a1.c", "--cq-check", "--cq-entry", "a1", "--cq-samples", "16", "-o", out)
    if r.returncode or not out.exists():
        fail("plain program", (r.stdout + r.stderr).strip()[-600:])
    else:
        ok("plain program, entry a1: §6-equal under --cq-check")


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


def test_library(tmp):
    """Rule 27, BACKEND_ABI §3 (cq-ywi8o): a lowered library and a program that names its root list."""
    nm_x = lambda f: {t for t in run([LLVM / "llvm-nm", "--defined-only", "--extern-only", "--format=just-symbols", f],
                                     text=True).stdout.split() if not t.endswith(":")}   # an archive member's name
    roots = tmp / "lib.roots"
    roots.write_text("triple\n")
    lib, lib_ll, lt = tmp / "libq.a", tmp / "libq.ll", tmp / "libq.tmp"
    r = cqcc("--cq-lib", "--cq-roots", roots, SRC / "qlib.c", "-o", lib)
    r2 = cqcc("--cq-lib", "-S", "--cq-roots", roots, SRC / "qlib.c", "-o", lib_ll, "--save-temps", lt)
    clones = {"___cq_q_triple_1_t", "___cq_q_triple_1_t_ctl", "___cq_q_triple_1_t_unc", "___cq_q_triple_1_t_ctl_unc"}
    got = nm_x(lib) if lib.exists() else set()
    if r.returncode or r2.returncode or got != clones | {"_triple", "_bump"}:
        fail("--cq-lib exports", r.stderr + r2.stderr + f" defined: {sorted(got)}")
    else:
        ok("--cq-lib: the root's own symbol and its four table clones are exported, bump's clones are not")

    prog_ll, pt = tmp / "quser.ll", tmp / "quser.tmp"
    r = cqcc("-S", "--cq-roots", roots, SRC / "qlib_user.c", "-o", prog_ll, "--save-temps", pt)
    text = prog_ll.read_text() if prog_ll.exists() else ""
    if r.returncode or "call i32 @__cq_q_triple_1_t(" not in text or "call void @__cq_q_triple_1_t_unc(" not in text \
            or "cqrt_tape_effect" in text or re.search(r"(?m)^define[^@]*@triple\(", text):
        fail("program on a root list", r.stderr + text[-400:])
    else:
        ok("a listed bodiless callee is a call of its declared clone and twin, no effect entry")
    r = cqcc("-S", SRC / "qlib_user.c", "-o", tmp / "quser_nolist.ll")
    if r.returncode or "cqrt_tape_effect" not in (tmp / "quser_nolist.ll").read_text():
        fail("program off the root list", "expected rule 16's effect entry without the list: " + r.stderr)
    else:
        ok("without the list the same call is rule 16's effect entry")

    backend, exe = tmp / "toy_lib_backend.o", tmp / "qlib.exe"
    run([LLVM / "clang", "-c", SRC / "toy_lib_backend.c", "-o", backend])
    r = cqcc(SRC / "qlib_main.c", SRC / "qlib_user.c", "--cq-roots", roots, lib, "--backend", backend, "-o", exe)
    code = subprocess.run([str(exe)]).returncode if exe.exists() else None
    if r.returncode or code != 16:
        fail("executable with a lowered library", r.stderr + str(code))
    else:
        ok("program, lowered library and backend link and run: exit status use(5, 0) = triple(5) + 1 = 16")

    # §6 against the C program of both sources: the lowered program and the lowered library as one module.
    c_ll, ct = tmp / "qboth.ll", tmp / "qboth.tmp"
    r = cqcc("-S", SRC / "qlib_user.c", SRC / "qlib.c", "-o", c_ll, "--save-temps", ct)
    merged = tmp / "qmerged.ll"
    r2 = run([LLVM / "llvm-link", "-S", prog_ll, lib_ll, "-o", merged])
    chk = run([sys.executable, "-m", "cqcheck", "user", "--o1", ct / "linked.ll", "--lowered", merged, "--entry", "use",
               "--light", "--samples", "16"], text=True, cwd=ROOT / "checker", env=ENV)
    if r.returncode or r2.returncode or chk.returncode:
        fail("lowered library under cqcheck", r.stderr + str(r2.stderr) + (chk.stdout + chk.stderr)[-600:])
    else:
        ok("the program lowered against the library is §6-equal to the C program of both sources")

    # A listed name is the library's: the bundle never supplies its body, and a library made of a bundle body
    # exports its root alone.
    if not os.environ.get("CQ_BUNDLE_MANIFEST") and not ENV.get("CQ_BUNDLE_MANIFEST"):
        sin_roots, sin_c, st = tmp / "sin.roots", tmp / "sin_user.c", tmp / "sin.tmp"
        sin_roots.write_text("sin\n")
        sin_c.write_text("#include <math.h>\ndouble s(double x, double th) { cq_theta(&x, th); return cq_measure(sin(x)); }\n")
        r = cqcc("-S", "--cq-roots", sin_roots, sin_c, "-o", tmp / "sin_user.ll", "--save-temps", st)
        linked = (st / "linked.ll").read_text() if (st / "linked.ll").exists() else ""
        low = (tmp / "sin_user.ll").read_text() if (tmp / "sin_user.ll").exists() else ""
        if r.returncode or re.search(r"(?m)^define[^@]*@sin\(", linked) or "@__cq_q_sin_1_t(" not in low:
            fail("listed name and the bundle", r.stderr + low[-300:])
        else:
            ok("a listed sin is not injected from the bundle: its call is the declared clone")
        r = cqcc("-S", sin_c, "-o", tmp / "sin_inj.ll", "--save-temps", tmp / "sin_inj.tmp")
        if r.returncode or not re.search(r"(?m)^define[^@]*@sin\(", (tmp / "sin_inj.tmp" / "linked.ll").read_text()):
            fail("unlisted name and the bundle", "expected the bundle's sin body without the list: " + r.stderr)
        else:
            ok("without the list sin is injected from the bundle (rule 18)")
        r = cqcc("--cq-lib", "--cq-roots", sin_roots, "-o", tmp / "libqsin.a")
        got = nm_x(tmp / "libqsin.a") if (tmp / "libqsin.a").exists() else set()
        want = {"___cq_q_sin_1_t", "___cq_q_sin_1_t_ctl", "___cq_q_sin_1_t_unc", "___cq_q_sin_1_t_ctl_unc"}
        und = set(run([LLVM / "llvm-nm", "--undefined-only", "--format=just-symbols", tmp / "libqsin.a"], text=True).stdout.split())
        if r.returncode or got != want or "_sin" not in und:
            fail("--cq-lib from the bundle", r.stderr + f" defined: {sorted(got)}; _sin undefined: {'_sin' in und}")
        else:
            ok("--cq-lib with no input takes sin from the bundle: its four clones exported, sin itself left to the host library")


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
    ap.add_argument("--spec", default=str(ROOT / "spec"))
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
        test_k_units(tmp)
        test_check(tmp)
        test_plain(tmp)
        test_link(tmp)
        test_library(tmp)
        test_host_link(tmp)
    print(f"\n{len(failures)} failure(s)")
    return 1 if failures else 0


ENV = None
if __name__ == "__main__":
    sys.exit(main())
