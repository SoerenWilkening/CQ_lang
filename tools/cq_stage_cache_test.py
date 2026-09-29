#!/usr/bin/env python3
"""cq_stage_cache_test.py — MUTANT VALIDATION of the e2e stage cache (bd 2dfk).

CLAUDE.md L10: "an instrument's failure mode is to REPORT A PASS, so the only
instrument worth citing is one that has been MADE TO FAIL ON PURPOSE." A cache in
front of a check is exactly the kind of instrument that can turn a red into a
green, so this file tries to make it do that, through the REAL runner
(tests/e2e/run_slice.sh), in PRIVATE caches (never the build's shared one):

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

STRUCTURE (for speed — a first version ran every row serially and, at load ~100,
became the longest entry of the whole suite): row A runs first and populates a
shared stage-1 cache and the BASE run cache; the other rows are independent
GROUPS run on a thread pool, each with its OWN run cache — a COPY of A's
populated one, so every perturbation still meets the good module's entries (see
`warm_copy`; an empty per-group cache silently lost two catches, measured) — and
its OWN clang/checker invocation logs. Results are printed in a fixed order.
Exit 0 iff every expectation holds.
"""
import argparse
import concurrent.futures
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


def count(d, ext=""):
    if not os.path.isdir(d):
        return 0
    return len([f for f in os.listdir(d) if not f.startswith(".") and f.endswith(ext)])


def main():
    ap = argparse.ArgumentParser()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld", "s1-base"):
        ap.add_argument("--" + k, required=True)
    a = ap.parse_args()
    for k in ("clang", "opt", "plugin", "include", "runtime", "templates", "ld"):
        setattr(a, k, os.path.abspath(getattr(a, k)))
    py = sys.executable
    tmp = tempfile.mkdtemp(prefix="cqcache_selftest.")
    results = {}          # group -> [(tag, ok, detail)]
    try:
        s1c = os.path.join(tmp, "s1")
        run_base = C.run_base(a.s1_base, a.ld)

        def script(name, body):
            p = os.path.join(tmp, name)
            with open(p, "w") as f:
                f.write(body)
            os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR)
            return p

        # Wrappers log each invocation to the file named by an env var, so every
        # run has its own log and parallel groups never share one.
        clang_w = script("clang_w", '#!/bin/bash\necho "$*" >> "$CQ_ST_CLOG"\n'
                                    'exec %s "$@"\n' % a.clang)
        py_w = script("py_w", '#!/bin/bash\necho "$*" >> "$CQ_ST_PLOG"\nexec %s "$@"\n' % py)

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
        with open(golden) as f:
            want = f.read()

        def slice_run(rc_dir, opt=a.opt, gold=golden, rt=a.runtime, cache=True, extra=None):
            # One fresh, uniquely named log pair per run (mkstemp: thread-safe).
            fd1, clog = tempfile.mkstemp(dir=tmp, prefix="clang.", suffix=".log")
            fd2, plog = tempfile.mkstemp(dir=tmp, prefix="py.", suffix=".log")
            os.close(fd1)
            os.close(fd2)
            env = {"HOME": os.environ.get("HOME", "/tmp"), "PATH": "/usr/bin:/bin",
                   "CQ_PYTHON": py_w, "CQ_LD": a.ld, "CQ_ST_CLOG": clog, "CQ_ST_PLOG": plog}
            if cache:
                env.update(CQ_S1CACHE=s1c, CQ_S1_BASE=a.s1_base,
                           CQ_RUNCACHE=rc_dir, CQ_RUN_BASE=run_base)
            env.update(extra or {})
            r = subprocess.run(["bash", os.path.join(ROOT, "tests", "e2e", "run_slice.sh"),
                                clang_w, opt, a.plugin, a.include, src, rt, a.templates, gold],
                               capture_output=True, text=True, env=env)
            return (r.returncode, r.stdout + r.stderr,
                    sum(1 for _ in open(clog)), sum(1 for _ in open(plog)))

        def group(name, fn):
            out = []
            try:
                fn(lambda tag, cond, detail="": out.append((tag, bool(cond), detail)))
            except Exception as e:           # a crashed group is a FAILED group
                out.append(("%s raised %r" % (name, e), False, ""))
            return out

        rc0 = os.path.join(tmp, "rc0")       # the BASE run cache, owned by A

        def warm_copy(name):
            """A group's private run cache = a COPY of A's populated one. This is
            load-bearing, not bookkeeping: every perturbation below must run
            against a cache that ALREADY HOLDS the good module's trace and 2b
            marker, or a key that ignores the module could never hit and the row
            could not see it (measured: with EMPTY per-group caches, planted
            defects M1/M5 went uncaught by D/E)."""
            d = os.path.join(tmp, name)
            shutil.copytree(rc0, d)
            return d

        def gA(expect):
            rc, out, nc, npy = slice_run(rc0)
            expect("A cold run passes", rc == 0, out[-300:] if rc else "")
            expect("A records one trace and one 2b marker",
                   count(os.path.join(rc0, "run")) == 1 and count(os.path.join(rc0, "2b")) == 1,
                   "run=%d 2b=%d" % (count(os.path.join(rc0, "run")), count(os.path.join(rc0, "2b"))))
            expect("A really ran stage 1 + stage 3 (clang x2) and the checker",
                   nc >= 2 and npy == 1, "clang=%d checker=%d" % (nc, npy))

        def gBJC(expect):                     # reads rc0, writes nothing
            rc, out, nc, npy = slice_run(rc0)
            expect("B warm run passes", rc == 0, out[-300:] if rc else "")
            expect("B is a real HIT: no clang, no checker", nc == 0 and npy == 0,
                   "clang=%d checker=%d" % (nc, npy))
            rc, out, nc, npy = slice_run(rc0, opt=opt_null)
            expect("J NULL CONTROL: no-op OPT wrapper still HITS and passes",
                   rc == 0 and nc == 0 and npy == 0, "rc=%d clang=%d checker=%d" % (rc, nc, npy))
            rc, out, nc, npy = slice_run(rc0, gold=bad_golden)
            expect("C perturbed GOLDEN fails on a warm hit",
                   rc != 0 and "cqrt_extra_line" in out, "rc=%d" % rc)

        def gD(expect):
            rcd = warm_copy("rcD")
            rc, out, nc, npy = slice_run(rcd, opt=opt_angle)
            expect("D perturbed LOWERING misses (re-links) and FAILS",
                   rc != 0 and nc >= 1 and "0x1p-2" in out, "rc=%d clang=%d" % (rc, nc))
            expect("D records the perturbed module's OWN trace (new entry)",
                   count(os.path.join(rcd, "run")) == 2, "run=%d" % count(os.path.join(rcd, "run")))
            rc, out, nc, npy = slice_run(rcd, opt=opt_angle)
            expect("D fails AGAIN on its own recorded entry (hit, still red)",
                   rc != 0 and nc == 0, "rc=%d clang=%d" % (rc, nc))

        def gE(expect):
            rce = warm_copy("rcE")
            rc, out, nc, npy = slice_run(rce, opt=opt_dirty)
            expect("E a checker-REJECTED lowering fails AT STAGE 2b (before any link)",
                   rc != 0 and "violation" in out.lower() and nc == 0, "rc=%d clang=%d" % (rc, nc))
            rc, out, nc, npy = slice_run(rce, opt=opt_dirty)
            expect("E fails again (no 2b marker was recorded for it)",
                   rc != 0 and npy == 1 and count(os.path.join(rce, "2b")) == 1,
                   "rc=%d checker=%d 2b=%d" % (rc, npy, count(os.path.join(rce, "2b"))))

        def gF(expect):
            # Archives are key material. A re-archived copy of the SAME objects has
            # different bytes (member timestamps) and must MISS and PASS; a runtime
            # whose trace text differs must MISS and FAIL.
            objdir = os.path.join(tmp, "rtobj")
            os.mkdir(objdir)
            subprocess.run(["ar", "x", a.runtime], cwd=objdir, check=True)
            same_rt = os.path.join(tmp, "libsame.a")
            members = [m for m in os.listdir(objdir) if m.endswith(".o")]
            subprocess.run(["ar", "rcs", same_rt] + members, cwd=objdir, check=True)
            rc, out, nc, npy = slice_run(warm_copy("rcF1"), rt=same_rt)
            expect("F byte-different, same-semantics runtime: MISS and PASS",
                   rc == 0 and nc >= 1, "rc=%d clang=%d" % (rc, nc))
            with open(os.path.join(ROOT, "runtime", "cq_runtime.c")) as f:
                txt = f.read()
            needle = '"cqrt_alloc_i32(%lld) -> h%d\\n"'
            expect("F (setup) runtime source has the alloc_i32 format", needle in txt)
            rt_src = os.path.join(tmp, "cq_runtime_perturbed.c")
            with open(rt_src, "w") as f:
                f.write(txt.replace(needle, '"cqrt_alloc_i32(%lld) => h%d\\n"'))
            bad_obj = os.path.join(tmp, "cq_runtime.c.o")
            subprocess.run([a.clang, "-c", "-I", os.path.join(ROOT, "runtime"), rt_src,
                            "-o", bad_obj], check=True, capture_output=True)
            bad_rt = os.path.join(tmp, "libbad.a")
            subprocess.run(["ar", "rcs", bad_rt, bad_obj], check=True)
            rc, out, nc, npy = slice_run(warm_copy("rcF2"), rt=bad_rt)
            expect("F semantically perturbed runtime: MISS and FAIL",
                   rc != 0 and nc >= 1 and "=> h0" in out, "rc=%d clang=%d" % (rc, nc))

        def gG(expect):
            rcg = warm_copy("rcG")
            before = (count(os.path.join(rcg, "run")), count(os.path.join(rcg, "2b")))
            rc, out, nc, npy = slice_run(rcg, extra={"CQ_E2E_NO_CACHE": "1"})
            after = (count(os.path.join(rcg, "run")), count(os.path.join(rcg, "2b")))
            expect("G CQ_E2E_NO_CACHE=1 passes, runs clang + checker, records nothing",
                   rc == 0 and nc >= 2 and npy == 1 and after == before,
                   "rc=%d clang=%d checker=%d" % (rc, nc, npy))

        def gH(expect):
            rch = warm_copy("rcH")
            before = (count(os.path.join(rch, "run")), count(os.path.join(rch, "2b")))
            rc, out, nc, npy = slice_run(rch, cache=False)
            after = (count(os.path.join(rch, "run")), count(os.path.join(rch, "2b")))
            expect("H by-hand (no cache env) passes, reads nothing (clang runs), records nothing",
                   rc == 0 and nc >= 2 and after == before, "rc=%d clang=%d" % (rc, nc))

        def gIK(expect):
            # I — key parity with the python spelling, on the module the bash runner
            # recorded in A: rebuild it here (stage 1 + the real pass), derive the
            # key in python, and require that EXACT entry to exist and to replay.
            s1, s2 = os.path.join(tmp, "s1.ll"), os.path.join(tmp, "s2.ll")
            subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm",
                            "-S", src, "-o", s1], check=True)
            subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S",
                            s1, "-o", s2], check=True)
            man = C.run_manifest(run_base, C.lowered_digest(s2), C.sha_file(a.templates),
                                 C.sha_file(a.runtime), C.sha_file(a.ld))
            key = C.sha_bytes(man.encode())
            expect("I python run_manifest key == the bash runner's entry",
                   os.path.isfile(os.path.join(rc0, "run", key + ".out")), key[:16])
            os.environ.update(CQ_RUNCACHE=rc0, CQ_RUN_BASE=run_base)
            os.environ.pop("CQ_E2E_NO_CACHE", None)
            lr = C.link_and_run(a.clang, a.ld, s2, a.templates, a.runtime, tmp, "py")
            expect("I python link_and_run replays it (cached, == golden)",
                   lr.cached and lr.stdout == want, "cached=%s" % lr.cached)
            # K — a NORMAL non-zero exit is recorded WITH its status (`<key>.nz`)
            # and replayed with the same status and stdout; no bash `.out` entry.
            ksrc = os.path.join(tmp, "k.c")
            with open(ksrc, "w") as f:
                f.write("int main(void) { int x = cq_theta(3, 0.5); return 3 + cq_measure(x); }\n")
            k1, k2 = os.path.join(tmp, "k.s1.ll"), os.path.join(tmp, "k.s2.ll")
            subprocess.run([a.clang, "-I" + a.include, "-include", "CQ.h", "-O1", "-emit-llvm",
                            "-S", ksrc, "-o", k1], check=True)
            subprocess.run([a.opt, "-load-pass-plugin", a.plugin, "-passes=cq-lowering", "-S",
                            k1, "-o", k2], check=True)
            rdir = os.path.join(rc0, "run")
            n_out, n_nz = count(rdir, ".out"), count(rdir, ".nz")
            r1 = C.link_and_run(a.clang, a.ld, k2, a.templates, a.runtime, tmp, "k1")
            r2 = C.link_and_run(a.clang, a.ld, k2, a.templates, a.runtime, tmp, "k2")
            expect("K non-zero exit: first run is live, exit 3",
                   not r1.cached and r1.run_rc == 3, "cached=%s rc=%s" % (r1.cached, r1.run_rc))
            expect("K replay keeps the status and the stdout",
                   r2.cached and r2.run_rc == 3 and r2.stdout == r1.stdout and bool(r1.stdout),
                   "cached=%s rc=%s" % (r2.cached, r2.run_rc))
            expect("K wrote ONE `.nz` entry and NO bash `.out` entry",
                   count(rdir, ".out") == n_out and count(rdir, ".nz") == n_nz + 1,
                   ".out %d->%d .nz %d->%d" % (n_out, count(rdir, ".out"), n_nz, count(rdir, ".nz")))

        print("cq_stage_cache_test: private caches in", tmp)
        results["A"] = group("A", gA)
        if all(ok for _, ok, _ in results["A"]):
            # gIK is the only group that WRITES rc0 (a `.nz`) while gBJC reads it;
            # gBJC's rows never count rc0, so the two are independent.
            groups = [("BJC", gBJC), ("D", gD), ("E", gE), ("F", gF), ("G", gG),
                      ("H", gH), ("IK", gIK)]
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                futs = [(n, pool.submit(group, n, fn)) for n, fn in groups]
                for n, fut in futs:
                    results[n] = fut.result()
        else:
            results["skip"] = [("rows B-K NOT RUN: row A failed, so nothing below "
                                "it would measure the cache", False, "")]
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    nfail = 0
    for rows in results.values():
        for tag, ok, detail in rows:
            print("  %-4s %-66s %s" % ("ok" if ok else "FAIL", tag, detail))
            nfail += not ok
    total = sum(len(r) for r in results.values())
    print("cq_stage_cache_test: %d expectation(s), %d FAILED" % (total, nfail))
    return 1 if nfail or total < 22 else 0


if __name__ == "__main__":
    sys.exit(main())
