#!/usr/bin/env python3
"""cq_stage_cache_test.py — MUTANT VALIDATION of the e2e stage cache (bd 2dfk).

CLAUDE.md L10: "an instrument's failure mode is to REPORT A PASS, so the only
instrument worth citing is one that has been MADE TO FAIL ON PURPOSE." A cache in
front of a check is exactly the kind of instrument that can turn a red into a
green, so this file tries to make it do that, through the REAL runner
(tests/e2e/run_slice.sh), in a PRIVATE cache (never the build's shared one):

  A  cold run passes and records ONE trace + ONE 2b marker
  B  warm run passes and invokes NEITHER clang NOR the checker (a real hit)
  C  a perturbed GOLDEN fails on the warm hit (the diff is never cached)
  D  a perturbed LOWERING (the pass under test changed) misses, re-links, FAILS
     — and fails AGAIN on its own recorded entry (a failing check stays failing)
  E  a lowering that the free-pairing checker REJECTS fails at stage 2b, twice,
     and leaves no 2b marker
  F  a semantically perturbed RUNTIME archive misses and FAILS; a byte-different
     but semantically identical archive misses and PASSES (archive bytes are key)
  G  CQ_E2E_NO_CACHE=1 runs every stage (clang invoked) and records nothing
  H  a by-hand run (no CQ_RUNCACHE) records nothing
  I  KEY PARITY: tools/cq_stage_cache.py derives the SAME key as the bash
     spelling for the same module, and its link_and_run replays that entry
  J  NULL CONTROL: a no-op OPT wrapper (same output) is a HIT, not a miss
  K  a NORMAL non-zero exit (python API only) is replayed with its status

Exit 0 iff every expectation holds; every row is printed with its outcome.
"""
import argparse
import os
import shutil
import stat
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import cq_stage_cache as C  # noqa: E402

FAIL = []


def expect(tag, cond, detail=""):
    print("  %-4s %-66s %s" % ("ok" if cond else "FAIL", tag, detail))
    if not cond:
        FAIL.append(tag)


def count(d):
    return len([f for f in os.listdir(d) if not f.startswith(".")]) if os.path.isdir(d) else 0


def main():
    ap = argparse.ArgumentParser()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld", "s1-base"):
        ap.add_argument("--" + k, required=True)
    a = ap.parse_args()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld"):
        setattr(a, k, os.path.abspath(getattr(a, k)))
    py = sys.executable
    tmp = tempfile.mkdtemp(prefix="cqcache_selftest.")
    try:
        s1c, rc_dir = os.path.join(tmp, "s1"), os.path.join(tmp, "rc")
        run_base = C.run_base(a.s1_base, a.ld)
        clog, plog = os.path.join(tmp, "clang.log"), os.path.join(tmp, "py.log")

        def script(name, body):
            p = os.path.join(tmp, name)
            with open(p, "w") as f:
                f.write(body)
            os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR)
            return p

        clang_w = script("clang_w", '#!/bin/bash\necho "$*" >> %s\nexec %s "$@"\n' % (clog, a.clang))
        py_w = script("py_w", '#!/bin/bash\necho "$*" >> %s\nexec %s "$@"\n' % (plog, py))

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
                                # EVERY occurrence: the first one is in @slice,
                                # which main never calls (its body is inlined), and
                                # mutating dead code leaves the trace unchanged.
                                "t = t.replace('double 5.000000e-01', 'double 2.500000e-01')")
        opt_dirty = opt_wrapper("opt_dirty",
                                "import re\n"
                                "m = re.search(r'^(\\s*call void @cqrt_ry_i32\\(i32 (%[\\w.]+),.*)$', t, re.M)\n"
                                "assert m\n"
                                "t = t[:m.end()] + '\\n  call void @cqrt_free(i32 %s)' % m.group(2) + t[m.end():]")

        src = os.path.join(ROOT, "tests", "e2e", "slice_theta_add_measure.c")
        golden = os.path.join(ROOT, "tests", "e2e", "slice_theta_add_measure.expected.log")
        bad_golden = os.path.join(tmp, "bad.expected.log")
        with open(golden) as f, open(bad_golden, "w") as g:
            g.write(f.read() + "cqrt_extra_line()\n")

        def slice_run(opt=a.opt, gold=golden, rt=a.runtime, cache=True, extra=None):
            env = {"HOME": os.environ.get("HOME", "/tmp"), "PATH": "/usr/bin:/bin",
                   "CQ_PYTHON": py_w, "CQ_LD": a.ld}
            if cache:
                env.update(CQ_S1CACHE=s1c, CQ_S1_BASE=a.s1_base,
                           CQ_RUNCACHE=rc_dir, CQ_RUN_BASE=run_base)
            env.update(extra or {})
            for p in (clog, plog):
                open(p, "w").close()
            r = subprocess.run(["bash", os.path.join(ROOT, "tests", "e2e", "run_slice.sh"),
                                clang_w, opt, a.plugin, a.include, src, rt, a.templates, gold],
                               capture_output=True, text=True, env=env)
            nclang = sum(1 for _ in open(clog))
            npy = sum(1 for _ in open(plog))
            return r.returncode, r.stdout + r.stderr, nclang, npy

        runs = lambda: count(os.path.join(rc_dir, "run"))
        oks = lambda: count(os.path.join(rc_dir, "2b"))

        print("cq_stage_cache_test: private cache in", tmp)
        rc, out, nc, npy = slice_run()
        expect("A cold run passes", rc == 0, out[-300:] if rc else "")
        expect("A records one trace and one 2b marker", runs() == 1 and oks() == 1,
               "run=%d 2b=%d" % (runs(), oks()))
        expect("A really ran stage 1 + stage 3 (clang x2) and the checker", nc >= 2 and npy == 1,
               "clang=%d checker=%d" % (nc, npy))

        rc, out, nc, npy = slice_run()
        expect("B warm run passes", rc == 0, out[-300:] if rc else "")
        expect("B is a real HIT: no clang, no checker", nc == 0 and npy == 0,
               "clang=%d checker=%d" % (nc, npy))

        rc, out, nc, npy = slice_run(opt=opt_null)
        expect("J NULL CONTROL: no-op OPT wrapper still HITS and passes",
               rc == 0 and nc == 0 and npy == 0, "rc=%d clang=%d checker=%d" % (rc, nc, npy))

        rc, out, nc, npy = slice_run(gold=bad_golden)
        expect("C perturbed GOLDEN fails on a warm hit", rc != 0 and "cqrt_extra_line" in out,
               "rc=%d" % rc)

        before = runs()
        rc, out, nc, npy = slice_run(opt=opt_angle)
        expect("D perturbed LOWERING misses (re-links) and FAILS",
               rc != 0 and nc >= 1 and "0x1p-2" in out, "rc=%d clang=%d" % (rc, nc))
        expect("D records the perturbed module's OWN trace (new entry)", runs() == before + 1,
               "run=%d" % runs())
        rc, out, nc, npy = slice_run(opt=opt_angle)
        expect("D fails AGAIN on its own recorded entry (hit, still red)",
               rc != 0 and nc == 0, "rc=%d clang=%d" % (rc, nc))

        before_ok = oks()
        rc, out, nc, npy = slice_run(opt=opt_dirty)
        expect("E a checker-REJECTED lowering fails AT STAGE 2b (before any link)",
               rc != 0 and "violation" in out.lower() and nc == 0,
               "rc=%d clang=%d" % (rc, nc))
        rc2, out2, nc2, npy2 = slice_run(opt=opt_dirty)
        expect("E fails again (no 2b marker was recorded for it)",
               rc2 != 0 and npy2 == 1 and oks() == before_ok, "rc=%d checker=%d 2b=%d" % (rc2, npy2, oks()))

        # F — archives are key material. A re-archived copy of the SAME objects has
        # different bytes (member timestamps) and must MISS and PASS; a runtime
        # whose trace text differs must MISS and FAIL.
        objdir = os.path.join(tmp, "rtobj")
        os.mkdir(objdir)
        subprocess.run(["ar", "x", a.runtime], cwd=objdir, check=True)
        same_rt = os.path.join(tmp, "libsame.a")
        members = [m for m in os.listdir(objdir) if m.endswith(".o")]
        subprocess.run(["ar", "rcs", same_rt] + members, cwd=objdir, check=True)
        rc, out, nc, npy = slice_run(rt=same_rt)
        expect("F byte-different, same-semantics runtime: MISS and PASS",
               rc == 0 and nc >= 1, "rc=%d clang=%d" % (rc, nc))
        rt_src = os.path.join(tmp, "cq_runtime_perturbed.c")
        with open(os.path.join(ROOT, "runtime", "cq_runtime.c")) as f:
            txt = f.read()
        needle = '"cqrt_alloc_i32(%lld) -> h%d\\n"'
        expect("F (setup) runtime source has the alloc_i32 format", needle in txt)
        with open(rt_src, "w") as f:
            f.write(txt.replace(needle, '"cqrt_alloc_i32(%lld) => h%d\\n"'))
        bad_obj = os.path.join(tmp, "cq_runtime.c.o")
        subprocess.run([a.clang, "-c", "-I", os.path.join(ROOT, "runtime"), rt_src, "-o", bad_obj],
                       check=True, capture_output=True)
        bad_rt = os.path.join(tmp, "libbad.a")
        subprocess.run(["ar", "rcs", bad_rt, bad_obj], check=True)
        rc, out, nc, npy = slice_run(rt=bad_rt)
        expect("F semantically perturbed runtime: MISS and FAIL",
               rc != 0 and nc >= 1 and "=> h0" in out, "rc=%d clang=%d" % (rc, nc))

        before, before_ok = runs(), oks()
        rc, out, nc, npy = slice_run(extra={"CQ_E2E_NO_CACHE": "1"})
        expect("G CQ_E2E_NO_CACHE=1 passes, runs clang + checker, records nothing",
               rc == 0 and nc >= 2 and npy == 1 and runs() == before and oks() == before_ok,
               "rc=%d clang=%d checker=%d" % (rc, nc, npy))
        rc, out, nc, npy = slice_run(cache=False)
        expect("H by-hand (no cache env) passes and records nothing",
               rc == 0 and nc >= 2 and runs() == before and oks() == before_ok,
               "rc=%d clang=%d" % (rc, nc))

        # I — key parity with the python spelling, on the module the bash runner
        # recorded in A: rebuild it here (stage 1 + the real pass), derive the key
        # in python, and require that EXACT entry to exist and to replay.
        s1 = os.path.join(tmp, "s1.ll")
        s2 = os.path.join(tmp, "s2.ll")
        subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                        src, "-o", s1], check=True)
        subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S", s1,
                        "-o", s2], check=True)
        man = C.run_manifest(run_base, C.lowered_digest(s2), C.sha_file(a.templates),
                             C.sha_file(a.runtime), C.sha_file(a.ld))
        key = C.sha_bytes(man.encode())
        expect("I python run_manifest key == the bash runner's entry",
               os.path.isfile(os.path.join(rc_dir, "run", key + ".out")), key[:16])
        os.environ.update(CQ_RUNCACHE=rc_dir, CQ_RUN_BASE=run_base)
        os.environ.pop("CQ_E2E_NO_CACHE", None)
        lr = C.link_and_run(a.clang, a.ld, s2, a.templates, a.runtime, tmp, "py")
        with open(golden) as f:
            want = f.read()
        expect("I python link_and_run replays it (cached, == golden)",
               lr.cached and lr.stdout == want, "cached=%s" % lr.cached)

        # K — a NORMAL non-zero exit is recorded WITH its status (`<key>.nz`) and
        # replayed with the same status and stdout; the bash `.out` entry is not
        # written for it.
        ksrc = os.path.join(tmp, "k.c")
        with open(ksrc, "w") as f:
            f.write("int main(void) { int x = cq_theta(3, 0.5); return 3 + cq_measure(x); }\n")
        k1, k2 = os.path.join(tmp, "k.s1.ll"), os.path.join(tmp, "k.s2.ll")
        subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                        ksrc, "-o", k1], check=True)
        subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S", k1,
                        "-o", k2], check=True)
        rdir = os.path.join(rc_dir, "run")
        kind = lambda ext: len([x for x in os.listdir(rdir) if x.endswith(ext)])
        n_out, n_nz = kind(".out"), kind(".nz")
        r1 = C.link_and_run(a.clang, a.ld, k2, a.templates, a.runtime, tmp, "k1")
        r2 = C.link_and_run(a.clang, a.ld, k2, a.templates, a.runtime, tmp, "k2")
        expect("K non-zero exit: first run is live, exit 3",
               not r1.cached and r1.run_rc == 3, "cached=%s rc=%s" % (r1.cached, r1.run_rc))
        expect("K replay keeps the status and the stdout",
               r2.cached and r2.run_rc == 3 and r2.stdout == r1.stdout and bool(r1.stdout),
               "cached=%s rc=%s" % (r2.cached, r2.run_rc))
        expect("K wrote ONE `.nz` entry and NO bash `.out` entry",
               kind(".out") == n_out and kind(".nz") == n_nz + 1,
               ".out %d->%d .nz %d->%d" % (n_out, kind(".out"), n_nz, kind(".nz")))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("cq_stage_cache_test: %d expectation(s) FAILED" % len(FAIL))
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
