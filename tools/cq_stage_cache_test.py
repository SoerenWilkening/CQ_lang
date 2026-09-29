#!/usr/bin/env python3
"""cq_stage_cache_test.py — MUTANT VALIDATION of the e2e stage cache (bd 2dfk, ffm0).

CLAUDE.md L10: "an instrument's failure mode is to REPORT A PASS, so the only
instrument worth citing is one that has been MADE TO FAIL ON PURPOSE." A cache in
front of a check is exactly the kind of instrument that can turn a red into a
green, so this file tries to make it do that, through the REAL runners
(tests/e2e/run_slice.sh, run_slice_multi.sh) and the real python API, in PRIVATE
caches (never the build's shared one).

THE RULE EVERY ROW FOLLOWS (bd ffm0, Rule-13 r1 F-r1-2): one row per KEY
COMPONENT. The row starts from a cache that ALREADY HOLDS the good entry (a copy
of the A-phase cache, or a warm-up run of its own), changes exactly that one
component, and requires a MISS (the stage visibly re-runs: clang, the checker or
the link is invoked) — and a RED where the change breaks the program. A key that
forgot the component would HIT and replay the stale result, and the row would go
red. The file's own meta-mutation (TRACK_2DFK.md) deletes each component from
the key, one at a time and from BOTH spellings where both exist, and requires
this file to fail each time.

  A    the base: three cold runs populate the shared warm cache (single TU, the
       -O2-sensitive QRAM slice, a two-TU slice)
  B/J/C  warm hit (no clang, no checker); a no-op cq-opt wrapper still hits
       (NULL CONTROL); a perturbed golden fails on the hit (the diff is never cached)
  D/E  a perturbed lowering misses and fails, twice; a checker-rejected lowering
       fails AT stage 2b, twice, no marker
  RUN KEY   runtime archive (same-semantics MISS+pass, perturbed MISS+red),
       templates archive, link wrapper (comment MISS+pass, no -lSystem MISS+red),
       CQ_RUN_BASE, clang bytes, environment
  2b KEY    checker bytes, checker flags, python interpreter path
  S1 KEY    source bytes (same path), lib-TU bytes (same path), CQ_S1_BASE,
       clang bytes, environment, stage-1 flags (-O0 on run_slice.sh: MISS+red),
       lib-TU flags (-include CQ.h: the C18 tripwire, MISS+red)
  HARNESS   an unmodified harness COPY hits (the digest is content, not path —
       NULL CONTROL); a comment in EACH of the four harness files misses;
       stage-3 `-O2` (the bd szpr pin) misses and is RED on the QRAM slice
  G/H  CQ_E2E_NO_CACHE=1 and a by-hand run read and record nothing
  PY   the python API: run-key PARITY with the bash entry (I), a non-zero exit
       replayed with its status (K), argv is key material, stage-1 file/gen
       keys (bytes, flags, env, harness copy), the CR guard of the ModuleID
       normalisation (both spellings)

Exit 0 iff every expectation holds and none of the groups crashed.
"""
import argparse
import concurrent.futures
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
E2E = os.path.join(ROOT, "tests", "e2e")
sys.path.insert(0, HERE)
import cq_stage_cache as C  # noqa: E402

HARNESS = (("tests/e2e/run_slice.sh", os.path.join(E2E, "run_slice.sh")),
           ("tests/e2e/run_slice_multi.sh", os.path.join(E2E, "run_slice_multi.sh")),
           ("tests/e2e/stage_cache.sh", os.path.join(E2E, "stage_cache.sh")),
           ("tools/cq_stage_cache.py", os.path.join(HERE, "cq_stage_cache.py")),
           ("tools/free_pairing_check.py", os.path.join(HERE, "free_pairing_check.py")))
EXPECTED_ROWS = 66
# The environment of the bash key-function probes: EXPLICIT, like every other
# row's. Measured: probes that inherited the ambient environment went red under
# `CQ_E2E_NO_CACHE=1 ctest`, because the off switch they inherited correctly
# produced no key — the selftest must measure the cache, not its caller's env.
PROBE_ENV = {"PATH": "/usr/bin:/bin", "HOME": os.environ.get("HOME", "/tmp")}


def count(d, ext=""):
    if not os.path.isdir(d):
        return 0
    return len([f for f in os.listdir(d) if not f.startswith(".") and f.endswith(ext)])


def main():
    ap = argparse.ArgumentParser()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld",
              "s1-base", "llvm-link"):
        ap.add_argument("--" + k, required=True)
    a = ap.parse_args()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld", "llvm_link"):
        setattr(a, k, os.path.abspath(getattr(a, k)))
    py = sys.executable
    tmp = tempfile.mkdtemp(prefix="cqcache_selftest.")
    results = {}
    try:
        s1c = os.path.join(tmp, "s1")
        run_base = C.run_base(a.s1_base, a.ld)

        def script(name, body, where=tmp):
            p = os.path.join(where, name)
            with open(p, "w") as f:
                f.write(body)
            os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR)
            return p

        # Logging wrappers: each run gets its own log files (env), so parallel
        # groups never share one. Stage-1 lines carry `-emit-llvm`, stage-3 lines
        # name `s2.ll`.
        clang_w = script("clang_w", '#!/bin/bash\necho "$*" >> "$CQ_ST_CLOG"\n'
                                    'exec %s "$@"\n' % a.clang)
        clang_w2 = script("clang_w2", '#!/bin/bash\n# a different clang (bytes)\n'
                                      'echo "$*" >> "$CQ_ST_CLOG"\nexec %s "$@"\n' % a.clang)
        py_w = script("py_w", '#!/bin/bash\necho "$*" >> "$CQ_ST_PLOG"\nexec %s "$@"\n' % py)
        py_w2 = script("py_w2", '#!/bin/bash\necho "$*" >> "$CQ_ST_PLOG"\nexec %s "$@"\n' % py)

        def opt_wrapper(name, transform):
            """A cq-opt stand-in: run the real pass, then rewrite its -o file."""
            return script(name, "#!%s\nimport subprocess, sys\n"
                          "r = subprocess.run([%r] + sys.argv[1:])\n"
                          "o = sys.argv[sys.argv.index('-o') + 1]\n"
                          "t = open(o).read()\n%s\nopen(o, 'w').write(t)\n"
                          "sys.exit(r.returncode)\n" % (py, a.opt, transform))

        opt_null = opt_wrapper("opt_null", "pass")
        opt_angle = opt_wrapper("opt_angle",
                                "assert 'double 5.000000e-01' in t\n"
                                # EVERY occurrence: the first is in @slice, which
                                # main never calls (its body is inlined).
                                "t = t.replace('double 5.000000e-01', 'double 2.500000e-01')")
        opt_dirty = opt_wrapper("opt_dirty",
                                "import re\n"
                                "m = re.search(r'^(\\s*call void @cqrt_ry_i32\\(i32 (%[\\w.]+),.*)$', t, re.M)\n"
                                "assert m\n"
                                "t = t[:m.end()] + '\\n  call void @cqrt_free(i32 %s)' % m.group(2) + t[m.end():]")

        def e2e(n):
            return os.path.join(E2E, n)

        theta_src, theta_gold = e2e("slice_theta_add_measure.c"), e2e("slice_theta_add_measure.expected.log")
        qram_src, qram_gold = e2e("slice_spec_qram_read.c"), e2e("slice_spec_qram_read.expected.log")
        caller_src, lib_src = e2e("slice_multi_caller.c"), e2e("slice_multi_lib.c")
        multi_gold = e2e("slice_multi.expected.log")
        bad_golden = os.path.join(tmp, "bad.expected.log")
        with open(theta_gold) as f, open(bad_golden, "w") as g:
            g.write(f.read() + "cqrt_extra_line()\n")
        with open(theta_gold) as f:
            want = f.read()

        def harness_copy(name, edits=()):
            """A private copy of the five harness files; `edits` is a list of
            (relpath, old, new): old must occur (a sed that matches nothing is a
            NULL mutant), or old=None appends `new`."""
            root = os.path.join(tmp, "h_" + name)
            for rel, src in HARNESS:
                dst = os.path.join(root, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
            for rel, old, new in edits:
                p = os.path.join(root, rel)
                with open(p) as f:
                    t = f.read()
                if old is None:
                    t += new
                else:
                    if old not in t:
                        raise AssertionError("harness edit not planted in %s: %r" % (rel, old))
                    t = t.replace(old, new, 1)
                with open(p, "w") as f:
                    f.write(t)
            return root

        def run(rc_dir, kind="single", src=theta_src, gold=None,
                harness=None, clang=clang_w, py_wrap=py_w, opt=a.opt, rt=a.runtime,
                tpl=a.templates, ld=a.ld, s1base=a.s1_base, runbase=run_base,
                fc_flags="", lib=lib_src, cache=True, extra=None, inc=None):
            gold = theta_gold if gold is None else gold
            fd1, clog = tempfile.mkstemp(dir=tmp, prefix="clang.", suffix=".log")
            fd2, plog = tempfile.mkstemp(dir=tmp, prefix="py.", suffix=".log")
            os.close(fd1)
            os.close(fd2)
            env = {"HOME": os.environ.get("HOME", "/tmp"), "PATH": "/usr/bin:/bin",
                   "CQ_PYTHON": py_wrap, "CQ_LD": ld, "CQ_ST_CLOG": clog, "CQ_ST_PLOG": plog}
            if cache:
                env.update(CQ_S1CACHE=s1c, CQ_S1_BASE=s1base,
                           CQ_RUNCACHE=rc_dir, CQ_RUN_BASE=runbase)
            env.update(extra or {})
            e2edir = os.path.join(harness, "tests", "e2e") if harness else E2E
            inc = a.include if inc is None else inc
            if kind == "single":
                cmd = ["bash", os.path.join(e2edir, "run_slice.sh"), clang, opt, a.plugin,
                       inc, src, rt, tpl, gold, fc_flags]
            else:
                cmd = ["bash", os.path.join(e2edir, "run_slice_multi.sh"), clang, opt,
                       a.llvm_link, a.plugin, inc, src, lib, rt, tpl, gold, fc_flags]
            r = subprocess.run(cmd, capture_output=True, text=True, env=env)
            lines = open(clog).read().splitlines()
            n1 = sum(1 for x in lines if "-emit-llvm" in x)
            n3 = sum(1 for x in lines if "s2.ll" in x)
            npy = sum(1 for _ in open(plog))
            return r.returncode, r.stdout + r.stderr, n1, n3, npy

        def pyrun(code, env_extra=None, module_dir=HERE):
            """Run `code` in a FRESH python with the cache module imported from
            `module_dir` and a private environment; the code sets `out` (json)."""
            env = {"HOME": os.environ.get("HOME", "/tmp"), "PATH": "/usr/bin:/bin"}
            env.update(env_extra or {})
            prog = ("import json, os, sys\nsys.path.insert(0, %r)\n"
                    "import cq_stage_cache as C\nout = {}\n%s\nprint(json.dumps(out))\n"
                    % (module_dir, code))
            r = subprocess.run([py, "-c", prog], capture_output=True, text=True, env=env)
            if r.returncode != 0:
                raise AssertionError("python row crashed:\n" + r.stderr[-1500:])
            return json.loads(r.stdout.strip().splitlines()[-1])

        def group(name, fn):
            out = []
            try:
                fn(lambda tag, cond, detail="": out.append((tag, bool(cond), detail)))
            except Exception as e:           # a crashed group is a FAILED group
                out.append(("%s raised %r" % (name, e), False, ""))
            return out

        rc0 = os.path.join(tmp, "rc0")       # the BASE run cache, filled by A

        def warm_copy(name):
            """A group's private run cache = a COPY of A's populated one. This is
            load-bearing, not bookkeeping: a perturbation only reveals a key that
            ignores a component when it runs against a cache that ALREADY HOLDS
            the good entry (measured: with empty per-group caches, planted defects
            went uncaught)."""
            d = os.path.join(tmp, name)
            shutil.copytree(rc0, d)
            return d

        def private_src(tag, *paths):
            d = os.path.join(tmp, "src_" + tag)
            os.makedirs(d)
            out = []
            for p in paths:
                q = os.path.join(d, os.path.basename(p))
                shutil.copy2(p, q)
                out.append(q)
            return out

        def edit(path, old, new):
            with open(path) as f:
                t = f.read()
            if old not in t:
                raise AssertionError("source edit not planted in %s" % path)
            with open(path, "w") as f:
                f.write(t.replace(old, new, 1))

        # ── A: populate ────────────────────────────────────────────────────
        def gA(expect):
            rc, out, n1, n3, npy = run(rc0)
            expect("A cold single-TU run passes", rc == 0, out[-300:] if rc else "")
            expect("A records one trace and one 2b marker",
                   count(os.path.join(rc0, "run")) == 1 and count(os.path.join(rc0, "2b")) == 1,
                   "run=%d 2b=%d" % (count(os.path.join(rc0, "run")), count(os.path.join(rc0, "2b"))))
            expect("A really ran stage 1, stage 3 and the checker",
                   n1 == 1 and n3 == 1 and npy == 1, "s1=%d s3=%d py=%d" % (n1, n3, npy))
            rc, out, n1, n3, npy = run(rc0, src=qram_src, gold=qram_gold)
            expect("A cold QRAM slice passes", rc == 0, out[-300:] if rc else "")
            rc, out, n1, n3, npy = run(rc0, kind="multi", src=caller_src, gold=multi_gold)
            expect("A cold two-TU slice passes, compiling both TUs",
                   rc == 0 and n1 == 2, "rc=%d s1=%d" % (rc, n1))

        # ── B/J/C: warm hit, null control, golden ─────────────────────────
        def gBJC(expect):                     # reads rc0, writes nothing
            rc, out, n1, n3, npy = run(rc0)
            expect("B warm run passes", rc == 0, out[-300:] if rc else "")
            expect("B is a real HIT: no clang, no checker", n1 == 0 and n3 == 0 and npy == 0,
                   "s1=%d s3=%d py=%d" % (n1, n3, npy))
            rc, out, n1, n3, npy = run(rc0, kind="multi", src=caller_src, gold=multi_gold)
            expect("B two-TU warm run is a real HIT", rc == 0 and n1 == 0 and n3 == 0,
                   "rc=%d s1=%d s3=%d" % (rc, n1, n3))
            rc, out, n1, n3, npy = run(rc0, opt=opt_null)
            expect("J NULL CONTROL: no-op cq-opt wrapper still HITS and passes",
                   rc == 0 and n1 == 0 and n3 == 0 and npy == 0,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            rc, out, n1, n3, npy = run(rc0, gold=bad_golden)
            expect("C perturbed GOLDEN fails on a warm hit",
                   rc != 0 and "cqrt_extra_line" in out and n3 == 0, "rc=%d s3=%d" % (rc, n3))

        def gD(expect):
            rcd = warm_copy("rcD")
            rc, out, n1, n3, npy = run(rcd, opt=opt_angle)
            expect("D perturbed LOWERING misses (re-links) and FAILS",
                   rc != 0 and n3 == 1 and "0x1p-2" in out, "rc=%d s3=%d" % (rc, n3))
            expect("D records the perturbed module's OWN trace (new entry)",
                   count(os.path.join(rcd, "run")) == 4, "run=%d" % count(os.path.join(rcd, "run")))
            rc, out, n1, n3, npy = run(rcd, opt=opt_angle)
            expect("D fails AGAIN on its own recorded entry (hit, still red)",
                   rc != 0 and n3 == 0, "rc=%d s3=%d" % (rc, n3))

        def gE(expect):
            rce = warm_copy("rcE")
            before = count(os.path.join(rce, "2b"))
            rc, out, n1, n3, npy = run(rce, opt=opt_dirty)
            expect("E a checker-REJECTED lowering fails AT STAGE 2b (before any link)",
                   rc != 0 and "violation" in out.lower() and n3 == 0, "rc=%d s3=%d" % (rc, n3))
            rc, out, n1, n3, npy = run(rce, opt=opt_dirty)
            expect("E fails again (no 2b marker was recorded for it)",
                   rc != 0 and npy == 1 and count(os.path.join(rce, "2b")) == before,
                   "rc=%d checker=%d" % (rc, npy))

        # ── RUN KEY components ─────────────────────────────────────────────
        def rearchive(archive, name):
            objdir = os.path.join(tmp, "ar_" + name)
            os.mkdir(objdir)
            subprocess.run(["ar", "x", archive], cwd=objdir, check=True)
            out = os.path.join(tmp, name + ".a")
            members = sorted(m for m in os.listdir(objdir) if m.endswith(".o"))
            subprocess.run(["ar", "rcs", out] + members, cwd=objdir, check=True)
            return out

        def gRT(expect):
            same_rt = rearchive(a.runtime, "libsame_rt")
            rc, out, n1, n3, npy = run(warm_copy("rcRT1"), rt=same_rt)
            expect("RUN runtime archive, byte-different same semantics: MISS and pass",
                   rc == 0 and n3 == 1 and n1 == 0, "rc=%d s1=%d s3=%d" % (rc, n1, n3))
            with open(os.path.join(ROOT, "runtime", "cq_runtime.c")) as f:
                txt = f.read()
            needle = '"cqrt_alloc_i32(%lld) -> h%d\\n"'
            expect("RUN (setup) runtime source has the alloc_i32 format", needle in txt)
            rt_src = os.path.join(tmp, "cq_runtime_perturbed.c")
            with open(rt_src, "w") as f:
                f.write(txt.replace(needle, '"cqrt_alloc_i32(%lld) => h%d\\n"'))
            bad_obj = os.path.join(tmp, "cq_runtime.c.o")
            subprocess.run([a.clang, "-c", "-I", os.path.join(ROOT, "runtime"), rt_src,
                            "-o", bad_obj], check=True, capture_output=True)
            bad_rt = os.path.join(tmp, "libbad_rt.a")
            subprocess.run(["ar", "rcs", bad_rt, bad_obj], check=True)
            rc, out, n1, n3, npy = run(warm_copy("rcRT2"), rt=bad_rt)
            expect("RUN runtime archive, perturbed trace: MISS and RED",
                   rc != 0 and n3 == 1 and "=> h0" in out, "rc=%d s3=%d" % (rc, n3))

        def gTPL(expect):
            same_tpl = rearchive(a.templates, "libsame_tpl")
            rc, out, n1, n3, npy = run(warm_copy("rcTPL"), tpl=same_tpl)
            expect("RUN templates archive, byte-different: MISS and pass",
                   rc == 0 and n3 == 1 and n1 == 0, "rc=%d s1=%d s3=%d" % (rc, n1, n3))

        def gLD(expect):
            with open(a.ld) as f:
                wtxt = f.read()
            ld1 = script("cq_link_comment.sh", wtxt + "# a comment: different bytes\n")
            rc, out, n1, n3, npy = run(warm_copy("rcLD1"), ld=ld1)
            expect("RUN link wrapper, byte-different: MISS and pass",
                   rc == 0 and n3 == 1 and n1 == 0, "rc=%d s1=%d s3=%d" % (rc, n1, n3))
            expect("RUN (setup) wrapper links -lSystem", " -lSystem " in wtxt)
            ld2 = script("cq_link_nosys.sh", wtxt.replace(" -lSystem ", " "))
            rc, out, n1, n3, npy = run(warm_copy("rcLD2"), ld=ld2)
            expect("RUN link wrapper without -lSystem: MISS and RED",
                   rc != 0 and n3 == 1, "rc=%d s3=%d" % (rc, n3))

        def gBASE(expect):
            rc, out, n1, n3, npy = run(warm_copy("rcRB"), runbase="0" * 64)
            expect("RUN CQ_RUN_BASE changed: stage 3 MISS, stage 1 hit, pass",
                   rc == 0 and n3 == 1 and n1 == 0, "rc=%d s1=%d s3=%d" % (rc, n1, n3))
            rc, out, n1, n3, npy = run(warm_copy("rcSB"), s1base="1" * 64)
            expect("S1 CQ_S1_BASE changed: stage 1 MISS, pass",
                   rc == 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))

        def gCL(expect):
            rc, out, n1, n3, npy = run(warm_copy("rcCL"), clang=clang_w2)
            expect("RUN+S1 clang bytes changed: stage 1 AND stage 3 MISS, pass",
                   rc == 0 and n1 == 1 and n3 == 1, "rc=%d s1=%d s3=%d" % (rc, n1, n3))

        def gENV(expect):
            empty = os.path.join(tmp, "empty_inc")
            os.makedirs(empty, exist_ok=True)
            rc, out, n1, n3, npy = run(warm_copy("rcENV"), extra={"CPATH": empty})
            expect("ENV CPATH set: stage 1, stage 3 AND 2b MISS, pass",
                   rc == 0 and n1 == 1 and n3 == 1 and npy == 1,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            rc, out, n1, n3, npy = run(warm_copy("rcENV2"), extra={"SDKROOT": ""})
            expect("ENV SDKROOT set-to-EMPTY is not unset: MISS",
                   n1 == 1, "rc=%d s1=%d" % (rc, n1))

        # ── 2b KEY components ──────────────────────────────────────────────
        def g2B(expect):
            h = harness_copy("fpc", [("tools/free_pairing_check.py", None, "\n# different bytes\n")])
            rc, out, n1, n3, npy = run(warm_copy("rcFPC"), harness=h)
            expect("2b checker bytes changed: ONLY 2b misses, pass",
                   rc == 0 and npy == 1 and n1 == 0 and n3 == 0,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            rc, out, n1, n3, npy = run(warm_copy("rcFLG"), fc_flags="--allow-unproven")
            expect("2b checker flags changed: ONLY 2b misses, pass",
                   rc == 0 and npy == 1 and n1 == 0 and n3 == 0,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            rc, out, n1, n3, npy = run(warm_copy("rcPY"), py_wrap=py_w2)
            expect("2b python interpreter path changed: ONLY 2b misses, pass",
                   rc == 0 and npy == 1 and n1 == 0 and n3 == 0,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))

        # ── S1 KEY: source bytes at the SAME path ─────────────────────────
        def gSRC(expect):
            rcs = warm_copy("rcSRC")
            (src,) = private_src("theta", theta_src)
            rc, out, n1, n3, npy = run(rcs, src=src)
            expect("S1 the same bytes at a NEW PATH: stage 1 MISS, pass",
                   rc == 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))
            rc2, out2, n1b, n3b, npyb = run(rcs, src=src)
            expect("S1 (setup) private source warms, then hits",
                   rc2 == 0 and n1b == 0, "rc=%d s1=%d" % (rc2, n1b))
            incd = os.path.join(tmp, "inc_copy")
            shutil.copytree(a.include, incd)
            rc, out, n1, n3, npy = run(warm_copy("rcINC"), inc=incd)
            expect("S1 FLAGS changed (the -I path; same header bytes): stage 1 MISS, pass",
                   rc == 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))
            edit(src, "int y = x + 1;", "int y = x + 2;")
            rc, out, n1, n3, npy = run(rcs, src=src)
            expect("S1 source BYTES changed at the same path: MISS and RED",
                   rc != 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))

        def gLIB(expect):
            rcl = warm_copy("rcLIB")
            caller, lib = private_src("multi", caller_src, lib_src)
            rc, out, n1, n3, npy = run(rcl, kind="multi", src=caller, lib=lib, gold=multi_gold)
            rc2, out2, n1b, n3b, npyb = run(rcl, kind="multi", src=caller, lib=lib, gold=multi_gold)
            expect("S1 (setup) private two-TU pair warms, then hits",
                   rc == 0 and rc2 == 0 and n1b == 0, "rc=%d/%d s1=%d" % (rc, rc2, n1b))
            edit(lib, "int lib_bias(void) { return 0; }", "int lib_bias(void) { return 1; }")
            rc, out, n1, n3, npy = run(rcl, kind="multi", src=caller, lib=lib, gold=multi_gold)
            expect("S1 lib-TU BYTES changed at the same path: lib MISS and RED",
                   rc != 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))

        # ── HARNESS digest + literal flags ────────────────────────────────
        def gHD(expect):
            h0 = harness_copy("null")
            rc, out, n1, n3, npy = run(warm_copy("rcHD0"), harness=h0)
            expect("HD NULL CONTROL: an unmodified harness COPY (other path) HITS",
                   rc == 0 and n1 == 0 and n3 == 0 and npy == 0,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            for rel, com in (("tests/e2e/run_slice.sh", "\n# comment\n"),
                             ("tests/e2e/run_slice_multi.sh", "\n# comment\n"),
                             ("tests/e2e/stage_cache.sh", "\n# comment\n"),
                             ("tools/cq_stage_cache.py", "\n# comment\n")):
                h = harness_copy("c_" + os.path.basename(rel), [(rel, None, com)])
                rc, out, n1, n3, npy = run(warm_copy("rcHD_" + os.path.basename(rel)), harness=h)
                expect("HD comment in %s: stage 1, 2b and 3 all MISS, pass" % os.path.basename(rel),
                       rc == 0 and n1 == 1 and n3 == 1 and npy == 1,
                       "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))

        def gHDR(expect):
            # r1's repro (a): the C18 tripwire — lib TUs get -include CQ.h.
            h = harness_copy("c18", [("tests/e2e/run_slice_multi.sh",
                                      'LIB_FLAGS=(-I"$INC" -O1 -emit-llvm -S)',
                                      'LIB_FLAGS=(-I"$INC" -include CQ.h -O1 -emit-llvm -S)')])
            rc, out, n1, n3, npy = run(warm_copy("rcC18"), kind="multi", src=caller_src,
                                       gold=multi_gold, harness=h)
            expect("HD lib-TU flags + -include CQ.h (C18 tripwire): MISS and RED",
                   rc != 0 and n1 >= 1 and "C18 violation" in out, "rc=%d s1=%d" % (rc, n1))
            # r1's repro (b): the bd szpr pin — stage 3 at -O2.
            h = harness_copy("o2", [("tests/e2e/stage_cache.sh",
                                     "CQ_S3_CC_FLAGS=(-c)", "CQ_S3_CC_FLAGS=(-O2 -c)")])
            rc, out, n1, n3, npy = run(warm_copy("rcO2"), src=qram_src, gold=qram_gold, harness=h)
            expect("HD stage-3 flags + -O2 (bd szpr pin): MISS and RED on the QRAM slice",
                   rc != 0 and n3 == 1, "rc=%d s3=%d" % (rc, n3))
            # r1's (d): run_slice.sh's own stage-1 flags at -O0.
            h = harness_copy("o0", [("tests/e2e/run_slice.sh",
                                     'S1_FLAGS=(-I"$INC" -include CQ.h -O1 -emit-llvm -S)',
                                     'S1_FLAGS=(-I"$INC" -include CQ.h -O0 -emit-llvm -S)')])
            rc, out, n1, n3, npy = run(warm_copy("rcO0"), harness=h)
            expect("HD stage-1 flags -O1 -> -O0: MISS and RED",
                   rc != 0 and n1 == 1, "rc=%d s1=%d" % (rc, n1))

        # ── G/H: off switches ─────────────────────────────────────────────
        def gGH(expect):
            rcg = warm_copy("rcG")
            before = (count(os.path.join(rcg, "run")), count(os.path.join(rcg, "2b")))
            rc, out, n1, n3, npy = run(rcg, extra={"CQ_E2E_NO_CACHE": "1"})
            after = (count(os.path.join(rcg, "run")), count(os.path.join(rcg, "2b")))
            expect("G CQ_E2E_NO_CACHE=1 passes, runs every stage, records nothing",
                   rc == 0 and n1 == 1 and n3 == 1 and npy == 1 and after == before,
                   "rc=%d s1=%d s3=%d py=%d" % (rc, n1, n3, npy))
            rch = warm_copy("rcH")
            before = (count(os.path.join(rch, "run")), count(os.path.join(rch, "2b")))
            rc, out, n1, n3, npy = run(rch, cache=False)
            after = (count(os.path.join(rch, "run")), count(os.path.join(rch, "2b")))
            expect("H by-hand (no cache env) runs every stage, records nothing",
                   rc == 0 and n1 == 1 and n3 == 1 and after == before,
                   "rc=%d s1=%d s3=%d" % (rc, n1, n3))

        # ── PY: the python API ─────────────────────────────────────────────
        def gPY(expect):
            rci = warm_copy("rcI")
            s1, s2 = os.path.join(tmp, "i.s1.ll"), os.path.join(tmp, "i.s2.ll")
            subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm",
                            "-S", theta_src, "-o", s1], check=True)
            subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S",
                            s1, "-o", s2], check=True)
            env = {"CQ_RUNCACHE": rci, "CQ_RUN_BASE": run_base, "CQ_ST_CLOG": os.devnull}
            r = pyrun("import os\n"
                      "man = C.run_manifest(C.harness_digest(), os.environ['CQ_RUN_BASE'],"
                      " C.clang_id(%r), C.S3_CC_FLAGS, C.lowered_digest(%r), C.sha_file(%r),"
                      " C.sha_file(%r), C.sha_file(%r), C.env_digest())\n"
                      "out['key'] = C.sha_bytes(man)\n"
                      "lr = C.link_and_run(%r, %r, %r, %r, %r, %r, 'py')\n"
                      "out['cached'] = lr.cached; out['stdout'] = lr.stdout\n"
                      % (clang_w, s2, a.templates, a.runtime, a.ld,
                         clang_w, a.ld, s2, a.templates, a.runtime, tmp), env)
            expect("I python run key == the bash runner's entry (PARITY)",
                   os.path.isfile(os.path.join(rci, "run", r["key"] + ".out")), r["key"][:16])
            expect("I python link_and_run replays it (cached, == golden)",
                   r["cached"] and r["stdout"] == want, "cached=%s" % r["cached"])
            # K + ARGV on a module whose main returns 3 + measure (= 3).
            ksrc = os.path.join(tmp, "k.c")
            with open(ksrc, "w") as f:
                f.write("int main(int c, char **v) { (void)v; int x = cq_theta(3, 0.5);"
                        " return 3 + cq_measure(x); }\n")
            k1, k2 = os.path.join(tmp, "k.s1.ll"), os.path.join(tmp, "k.s2.ll")
            subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm",
                            "-S", ksrc, "-o", k1], check=True)
            subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S",
                            k1, "-o", k2], check=True)
            code = ("res = []\nfor argv in [(), (), ('a',), ('a',), ('b',), ('a', 'b')]:\n"
                    "    lr = C.link_and_run(%r, %r, %r, %r, %r, %r, 'k', argv)\n"
                    "    res.append([lr.cached, lr.run_rc, lr.stdout])\n"
                    "out['res'] = res\n" % (a.clang, a.ld, k2, a.templates, a.runtime, tmp))
            r = pyrun(code, {"CQ_RUNCACHE": os.path.join(tmp, "rcK"), "CQ_RUN_BASE": run_base})
            res = r["res"]
            expect("K non-zero exit: first run is live, exit 3",
                   not res[0][0] and res[0][1] == 3, str(res[0][:2]))
            expect("K replay keeps the status and the stdout",
                   res[1][0] and res[1][1] == 3 and res[1][2] == res[0][2] and res[0][2],
                   str(res[1][:2]))
            expect("K wrote `.nz` entries only (no bash `.out`)",
                   count(os.path.join(tmp, "rcK", "run"), ".out") == 0
                   and count(os.path.join(tmp, "rcK", "run"), ".nz") == 4,
                   ".nz=%d" % count(os.path.join(tmp, "rcK", "run"), ".nz"))
            expect("ARGV is key material: ('a',) misses then hits; ('b',) and ('a','b') miss",
                   not res[2][0] and res[3][0] and not res[4][0] and not res[5][0],
                   str([x[0] for x in res]))

        def gPS1(expect):
            (src,) = private_src("ps1", theta_src)
            flags = ["-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm", "-S"]
            envp = {"CQ_S1CACHE": os.path.join(tmp, "ps1cache"), "CQ_S1_BASE": a.s1_base}
            step = ("def once(flags, env_over=None):\n"
                    "    import os, tempfile\n"
                    "    open(os.environ['CQ_ST_CLOG'], 'w').close()\n"
                    "    rc, err, p = C.stage1_file(%r, flags, %r, os.path.join(tempfile.mkdtemp(), 'o.ll'))\n"
                    "    return [rc, len(open(os.environ['CQ_ST_CLOG']).read().splitlines())]\n"
                    % (clang_w, src))
            log = os.path.join(tmp, "ps1.log")
            envp["CQ_ST_CLOG"] = log
            r = pyrun(step + "out['a'] = once(%r)\nout['b'] = once(%r)\n"
                      "out['c'] = once(%r)\n" % (flags, flags, flags[:3] + ["-O0"] + flags[4:]), envp)
            expect("PS1 python file key: cold compiles, warm hits",
                   r["a"] == [0, 1] and r["b"] == [0, 0], str([r["a"], r["b"]]))
            expect("PS1 python file key: FLAGS changed misses", r["c"][1] == 1, str(r["c"]))
            envp2 = dict(envp, CPATH=os.path.join(tmp, "empty_inc2"))
            r = pyrun(step + "out['d'] = once(%r)\n" % (flags,), envp2)
            expect("PS1 python file key: ENV changed misses", r["d"][1] == 1, str(r["d"]))
            h = harness_copy("ps1hd", [("tests/e2e/run_slice.sh", None, "\n# comment\n")])
            r = pyrun(step + "out['e'] = once(%r)\n" % (flags,), envp,
                      module_dir=os.path.join(h, "tools"))
            expect("PS1 python file key: HARNESS changed misses", r["e"][1] == 1, str(r["e"]))
            r = pyrun(step + "out['g'] = once(%r)\n" % (flags,), dict(envp, CQ_S1_BASE="2" * 64))
            expect("PS1 python file key: CQ_S1_BASE changed misses", r["g"][1] == 1, str(r["g"]))
            r = pyrun(step.replace(repr(clang_w), repr(clang_w2)) + "out['h'] = once(%r)\n" % (flags,),
                      envp)
            expect("PS1 python file key: clang BYTES changed misses", r["h"][1] == 1, str(r["h"]))
            (src2,) = private_src("ps1b", theta_src)
            r = pyrun(step.replace(repr(src), repr(src2)) + "out['i'] = once(%r)\n" % (flags,), envp)
            expect("PS1 python file key: same bytes at a NEW PATH misses", r["i"][1] == 1, str(r["i"]))
            edit(src, "int y = x + 1;", "int y = x + 2;")
            r = pyrun(step + "out['f'] = once(%r)\n" % (flags,), envp)
            expect("PS1 python file key: source BYTES changed (same path) misses",
                   r["f"][1] == 1, str(r["f"]))
            # generated-source key (the loop twin matrix's): text is the key.
            gen = ("def g(csrc, flags):\n"
                   "    import os, tempfile\n"
                   "    open(os.environ['CQ_ST_CLOG'], 'w').close()\n"
                   "    rc, err, p = C.stage1_generated(%r, flags, csrc, tempfile.mkdtemp(), 'n')\n"
                   "    return [rc, len(open(os.environ['CQ_ST_CLOG']).read().splitlines())]\n"
                   % clang_w)
            csrc = open(theta_src).read()
            r = pyrun(gen + "out['a'] = g(%r, %r)\nout['b'] = g(%r, %r)\n"
                      "out['c'] = g(%r, %r)\nout['d'] = g(%r, %r)\n"
                      % (csrc, flags, csrc, flags, csrc + "\n// x\n", flags,
                         csrc, flags[:3] + ["-O0"] + flags[4:]), envp)
            expect("PS1 python gen key: cold, warm hit, TEXT change misses, FLAGS change misses",
                   r["a"] == [0, 1] and r["b"] == [0, 0] and r["c"][1] == 1 and r["d"][1] == 1,
                   str([r["a"], r["b"], r["c"], r["d"]]))

        def gCR(expect):
            # bd ffm0 F-r1-3: a CR in the ModuleID line must NOT be stripped.
            body_a = "; ModuleID = 'a'\r@x = global i32 0\ndefine i32 @main() {\n  ret i32 0\n}\n"
            body_b = "; ModuleID = 'a'\r@x = global i32 7\ndefine i32 @main() {\n  ret i32 0\n}\n"
            pa, pb = os.path.join(tmp, "cr_a.ll"), os.path.join(tmp, "cr_b.ll")
            with open(pa, "w", newline="") as f:
                f.write(body_a)
            with open(pb, "w", newline="") as f:
                f.write(body_b)
            expect("CR python: two modules differing after a CR in line 1 get two digests",
                   C.lowered_digest(pa) != C.lowered_digest(pb))
            probe = script("cr_probe.sh",
                           "#!/bin/bash\nHERE=%s\nCLANG=%s\nPY=x TPL=%s RT=%s CQ_LD=%s\n"
                           "CQ_S1CACHE=/nonexistent CQ_RUNCACHE=/nonexistent CQ_RUN_BASE=b\n"
                           ". \"$HERE/stage_cache.sh\"\ncq_cache_init\n"
                           "for f in %s %s; do TMP=$(mktemp -d); cp \"$f\" \"$TMP/s2.ll\";"
                           " cq_cache_keys %s ''; echo \"$CQ_RUN_KEY\"; rm -rf \"$TMP\"; done\n"
                           % (E2E, a.clang, a.templates, a.runtime, a.ld, pa, pb,
                              os.path.join(HERE, "free_pairing_check.py")))
            keys = subprocess.run(["bash", probe], capture_output=True, text=True,
                                  env=PROBE_ENV).stdout.split()
            expect("CR bash: the same two modules get two run keys",
                   len(keys) == 2 and keys[0] != keys[1] and all(len(k) == 64 for k in keys),
                   str([k[:12] for k in keys]))

        # ── S3 FLAGS + ENV-LIST parity: components with no free variable ───
        def gS3(expect):
            # The stage-3 flags are literals inside the HARNESS-DIGESTED files, so
            # an edit to them also moves the harness digest; these rows observe the
            # flag component ALONE — the bash key function driven directly, and the
            # python API with S3_CC_FLAGS overridden at run time.
            probe = script("s3_probe.sh",
                           "#!/bin/bash\nHERE=%s\nCLANG=%s\nPY=x TPL=%s RT=%s CQ_LD=%s\n"
                           "CQ_S1CACHE=/nonexistent CQ_RUNCACHE=/nonexistent CQ_RUN_BASE=b\n"
                           ". \"$HERE/stage_cache.sh\"\ncq_cache_init\nTMP=$(mktemp -d)\n"
                           "cp %s \"$TMP/s2.ll\"\n"
                           "cq_cache_keys %s ''; echo \"$CQ_RUN_KEY\"\n"
                           "CQ_S3_CC_FLAGS=(-O2 -c); cq_cache_keys %s ''; echo \"$CQ_RUN_KEY\"\n"
                           "rm -rf \"$TMP\"\n"
                           % (E2E, a.clang, a.templates, a.runtime, a.ld,
                              theta_gold,   # any file: the probe drives the key function only
                              os.path.join(HERE, "free_pairing_check.py"),
                              os.path.join(HERE, "free_pairing_check.py")))
            keys = subprocess.run(["bash", probe], capture_output=True, text=True,
                                  env=PROBE_ENV).stdout.split()
            expect("S3 bash: CQ_S3_CC_FLAGS is in the run key",
                   len(keys) == 2 and keys[0] != keys[1] and all(len(k) == 64 for k in keys),
                   str([k[:12] for k in keys]))
            s1, s2 = os.path.join(tmp, "s3.s1.ll"), os.path.join(tmp, "s3.s2.ll")
            subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm",
                            "-S", theta_src, "-o", s1], check=True)
            subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S",
                            s1, "-o", s2], check=True)
            code = ("res = []\nfor fl in [None, None, ('-O0', '-c')]:\n"
                    "    if fl: C.S3_CC_FLAGS = fl\n"
                    "    lr = C.link_and_run(%r, %r, %r, %r, %r, %r, 's3')\n"
                    "    res.append(lr.cached)\nout['res'] = res\n"
                    % (a.clang, a.ld, s2, a.templates, a.runtime, tmp))
            r = pyrun(code, {"CQ_RUNCACHE": os.path.join(tmp, "rcS3"), "CQ_RUN_BASE": run_base})
            expect("S3 python: S3_CC_FLAGS is in the run key (warm hit, then a MISS)",
                   r["res"] == [False, True, False], str(r["res"]))
            allset = {v: "v_" + v for v in C.KEY_ENV_VARS}
            # ⚠ macOS SIP strips every DYLD_* variable from the environment of a
            # protected binary such as /bin/bash (measured), so nothing the bash
            # runners launch can see them and "unset" IS their truth there; the
            # python harnesses and the programs they run DO see them, and key them.
            # So parity is asserted over the environment bash actually RECEIVES,
            # which the probe reports back.
            probe = script("env_probe.sh",
                           "#!/bin/bash\nHERE=%s\nCLANG=%s\nCQ_S1CACHE=/nonexistent\n"
                           ". \"$HERE/stage_cache.sh\"\ncq_cache_init\necho \"$CQ_ENVD\"\n"
                           "for v in $CQ_KEY_ENV_VARS; do eval \"s=\\${$v+x}\"; "
                           "[ -n \"$s\" ] && echo \"seen $v\"; done; true\n"
                           % (E2E, a.clang))
            benv = dict({"PATH": "/usr/bin:/bin"}, **allset)
            lines = subprocess.run(["bash", probe], capture_output=True, text=True,
                                   env=benv).stdout.split("\n")
            bash_envd = lines[0].strip()
            seen = {x.split()[1] for x in lines[1:] if x.startswith("seen ")}
            unseen = sorted(set(allset) - seen)
            expect("ENV-LIST parity: every KEY_ENV_VAR set -> bash ENVD == python env_digest"
                   " over what bash receives",
                   bash_envd == C.env_digest({k: v for k, v in allset.items() if k in seen})
                   and len(bash_envd) == 64 and all(v.startswith("DYLD_") for v in unseen),
                   "%s; stripped before bash: %s" % (bash_envd[:12], ",".join(unseen) or "none"))

        print("cq_stage_cache_test: private caches in", tmp)
        results["A"] = group("A", gA)
        if all(ok for _, ok, _ in results["A"]):
            groups = [("BJC", gBJC), ("D", gD), ("E", gE), ("RT", gRT), ("TPL", gTPL),
                      ("LD", gLD), ("BASE", gBASE), ("CL", gCL), ("ENV", gENV), ("2B", g2B),
                      ("SRC", gSRC), ("LIB", gLIB), ("HD", gHD), ("HDR", gHDR), ("GH", gGH),
                      ("PY", gPY), ("PS1", gPS1), ("CR", gCR), ("S3", gS3)]
            with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
                futs = [(n, pool.submit(group, n, fn)) for n, fn in groups]
                for n, fut in futs:
                    results[n] = fut.result()
        else:
            results["skip"] = [("groups after A NOT RUN: row A failed, so nothing below "
                                "it would measure the cache", False, "")]
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    nfail = 0
    for rows in results.values():
        for tag, ok, detail in rows:
            print("  %-4s %-72s %s" % ("ok" if ok else "FAIL", tag, detail))
            nfail += not ok
    total = sum(len(r) for r in results.values())
    short = total < EXPECTED_ROWS
    print("cq_stage_cache_test: %d expectation(s), %d FAILED%s"
          % (total, nfail, " — FEWER THAN THE %d EXPECTED" % EXPECTED_ROWS if short else ""))
    return 1 if nfail or short else 0


if __name__ == "__main__":
    sys.exit(main())
