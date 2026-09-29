#!/usr/bin/env python3
"""cq_stage_cache.py — content-addressed cache for the e2e harness's PURE stages.

bd test_C_libtooling-2dfk (owner ruling 2026-09-29: "engineer faster tests").

WHAT IS CACHED, AND WHY THAT IS NOT A WEAKER TEST
-------------------------------------------------
An e2e check is a chain of stages. Only ONE of them is the thing under test:

    S1   clang -O1 -emit-llvm        f(clang, headers, flags, source)          CACHED (already, bd dgn5)
    S2   cq-opt -passes=cq-lowering  THE PASS UNDER TEST                        NEVER CACHED
    S2b  free_pairing_check.py       f(lowered IR, checker source, flags)       CACHED (bash runners)
    S3   clang -c + ld               f(lowered IR, clang, ld, the two archives)  CACHED  } as ONE entry:
    S4   run the executable          f(the executable, argv)                     CACHED  } the trace

Every cached stage is a PURE FUNCTION of the bytes in its key. The trace runtime
is trace-only (no clock, no environment, no randomness — `measure` returns 0), so
S3+S4 map (lowered IR, archives, toolchain, argv) to one byte string, and the
goldens have always depended on exactly that determinism. A cache HIT therefore
returns the SAME answer the stage would compute, for a stage whose inputs have
not changed; the stage under test (S2) runs every time and a changed lowering is
a changed key. The comparison that makes each check a check — the trace against
its golden, rolled against unrolled, the verdict against the expected table —
is NEVER cached and runs every time.

What a hit does NOT re-witness is the machine: "this toolchain still links and
runs this IR on this box today". That is why the toolchain is IN the key (clang
bytes + version via CQ_S1_BASE, the ld wrapper, `ld -v`, the OS build), and why
`CQ_E2E_NO_CACHE=1` exists: it switches every cache off (S1 included) for a
from-scratch run. Deleting `build/tests/e2e/.s1cache` / `.runcache` is the same
reset.

CORRECTNESS IS THE WHOLE POINT (the s1_cache_key.py discipline, verbatim): a stale
hit does not make a test slow, it makes it LIE. So every key component is
CONTENT, never a timestamp or a path standing in for content; only SUCCESSFUL
results are stored (a failing clang, a failing link, a failing checker always
re-run and print their own failure); entries are published atomically (write +
rename), so a concurrent reader never sees half an entry. ONE refinement: the
python API also records a NORMAL non-zero EXIT of a linked program (a matrix
`main` returning `slice(argc)`) with its status, as `<key>.nz` — the exit status
is as deterministic as the trace, and every python caller either ignores it or
fails on it. A signal is never recorded. The bash runners write only `<key>.out`
(exit 0): a non-zero exit fails a slice, so it simply re-runs.

THE ONE NORMALISATION. The lowered module's first line is the comment
`; ModuleID = '<input path>'`, and the input path is a fresh `mktemp -d` on every
run. It is dropped from the S2b/S3/S4 key. That is exact, not approximate: it is
an IR COMMENT (the LLVM lexer discards `;` comments, and the module identifier
of the stage-3 compile comes from its own command-line path, which is also a
fresh temp path today); `free_pairing_check.py` matches only `define`, `@global =`
and label lines outside a function, none of which a `;` line can match.

Environment (exported to every e2e entry by tests/e2e/CMakeLists.txt):
    CQ_S1CACHE, CQ_S1_BASE   stage-1 cache dir + toolchain key (pre-existing)
    CQ_RUNCACHE              dir for the S2b / S3+S4 entries
    CQ_RUN_BASE              stage-3/4 toolchain key (computed at configure time
                             by `cq_stage_cache.py run-base`)
    CQ_E2E_NO_CACHE          non-empty => every cache is OFF (forced full run)

A by-hand invocation (no env) caches nothing — byte-identical to the old harness.

The KEY DERIVATION is shared with tests/e2e/run_slice.sh and run_slice_multi.sh,
which spell it with `openssl dgst` (a python start per slice would cost more than
the hash): see `run_manifest` — the two spellings MUST stay identical, and
`tools/cq_stage_cache_test.py` checks that they are.
"""
import hashlib
import os
import subprocess
import sys
import tempfile

RUN_VERSION = "cq-run-v1"
PB2_VERSION = "cq-2b-v1"
S1_VERSION = "cq-s1gen-v1"


def _env(name):
    return os.environ.get(name, "")


def disabled():
    return bool(_env("CQ_E2E_NO_CACHE"))


def s1_enabled():
    return not disabled() and bool(_env("CQ_S1CACHE")) and bool(_env("CQ_S1_BASE"))


def run_enabled():
    return not disabled() and bool(_env("CQ_RUNCACHE")) and bool(_env("CQ_RUN_BASE"))


def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def sha_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def lowered_digest(path):
    """sha256 of a lowered module MINUS a leading `; ModuleID = ` comment line
    (the one line that names a temp path; see the module docstring)."""
    with open(path, "rb") as f:
        data = f.read()
    if data.startswith(b"; ModuleID = "):
        nl = data.find(b"\n")
        data = b"" if nl < 0 else data[nl + 1:]
    return sha_bytes(data)


def _publish(final, data):
    """Atomic: write a sibling temp file, then rename(2) over `final`."""
    d = os.path.dirname(final)
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp.")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
        os.replace(tmp, final)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


# ── stage 1 ────────────────────────────────────────────────────────────────
def stage1_generated(clang, flags, csrc, work, name):
    """Stage 1 of a GENERATED source (text, not a file on disk).

    Returns (returncode, stderr, ir_path). Uncached: writes `<work>/<name>.c`
    and compiles it there — exactly what the harnesses did before. Cached: the
    source is written to a CONTENT-ADDRESSED path under CQ_S1CACHE and compiled
    from there, so its `source_filename` is a pure function of the key and a hit
    is byte-identical to the miss that published it."""
    if not s1_enabled():
        cpath = os.path.join(work, name + ".c")
        with open(cpath, "w") as f:
            f.write(csrc)
        out = os.path.join(work, name + ".s1.ll")
        r = subprocess.run([clang, *flags, cpath, "-o", out],
                           capture_output=True, text=True)
        return r.returncode, r.stderr, out
    root = os.path.join(_env("CQ_S1CACHE"), "gen")
    src_digest = sha_bytes(csrc.encode())
    cpath = os.path.join(root, src_digest + ".c")
    if not os.path.exists(cpath):
        _publish(cpath, csrc.encode())
    key = sha_bytes("\n".join([S1_VERSION, _env("CQ_S1_BASE"), clang,
                               "\0".join(flags), cpath, src_digest]).encode())
    hit = os.path.join(root, key + ".ll")
    if os.path.exists(hit):
        return 0, "", hit
    out = os.path.join(work, name + ".s1.ll")
    r = subprocess.run([clang, *flags, cpath, "-o", out],
                       capture_output=True, text=True)
    if r.returncode == 0:
        with open(out, "rb") as f:
            _publish(hit, f.read())
    return r.returncode, r.stderr, out


def stage1_file(clang, flags, src, out):
    """Stage 1 of a source FILE on disk. Returns (returncode, stderr, ir_path).
    The key has the source PATH as well as its bytes, because clang bakes the
    path into `source_filename` (the run_slice.sh rule)."""
    if not s1_enabled():
        r = subprocess.run([clang, *flags, src, "-o", out],
                           capture_output=True, text=True)
        return r.returncode, r.stderr, out
    with open(src, "rb") as f:
        body = f.read()
    key = sha_bytes("\n".join([S1_VERSION + "-file", _env("CQ_S1_BASE"), clang,
                               "\0".join(flags), os.path.abspath(src),
                               sha_bytes(body)]).encode())
    hit = os.path.join(_env("CQ_S1CACHE"), "file", key + ".ll")
    if os.path.exists(hit):
        return 0, "", hit
    r = subprocess.run([clang, *flags, src, "-o", out],
                       capture_output=True, text=True)
    if r.returncode == 0:
        with open(out, "rb") as f:
            _publish(hit, f.read())
    return r.returncode, r.stderr, out


# ── stages 3 + 4 ───────────────────────────────────────────────────────────
def run_manifest(run_base, s2_digest, tpl_digest, rt_digest, ld_digest, argv=()):
    """THE key text for one link+run. run_slice.sh / run_slice_multi.sh build
    the identical text with printf; keep the two in lock-step."""
    lines = [RUN_VERSION, run_base, s2_digest, tpl_digest, rt_digest, ld_digest]
    lines += ["arg:" + a for a in argv]
    return "\n".join(lines) + "\n"


class LinkRun:
    __slots__ = ("link_rc", "link_stderr", "run_rc", "stdout", "cached")

    def __init__(self, link_rc, link_stderr, run_rc, stdout, cached=False):
        self.link_rc = link_rc
        self.link_stderr = link_stderr
        self.run_rc = run_rc
        self.stdout = stdout
        self.cached = cached


def link_and_run(clang, ld, s2, templates, runtime, work, tag, argv=()):
    """Stage 3 (link: `clang -c` + the CQ_LD wrapper when `ld` is executable,
    else the clang driver) and stage 4 (run, stdout captured as text).

    Link order is load-bearing: templates BEFORE runtime. The run's stderr is
    captured and discarded, as every python harness did before (none reads it;
    the runtime writes nothing to stderr)."""
    use_ld = bool(ld) and os.access(ld, os.X_OK)
    key_path = None
    # A missing lowered module (its row declined) is not hashed: it falls
    # through to the link, which fails exactly as it did before the cache.
    if run_enabled() and use_ld and os.path.isfile(s2):
        manifest = run_manifest(_env("CQ_RUN_BASE"), lowered_digest(s2),
                                sha_file(templates), sha_file(runtime),
                                sha_file(ld), argv)
        key_path = os.path.join(_env("CQ_RUNCACHE"), "run",
                                sha_bytes(manifest.encode()) + ".out")
        if os.path.exists(key_path):
            with open(key_path, "rb") as f:
                return LinkRun(0, "", 0, f.read().decode("utf-8", "surrogateescape"),
                               cached=True)
        # A NORMAL non-zero exit (a matrix `main` that returns `slice(argc)`) is
        # as deterministic as the trace; it is recorded beside the key as
        # `<key>.nz` = "<status>\n" + stdout. The bash runners never read or
        # write these (a non-zero exit fails a slice, so it simply re-runs).
        nz = key_path[:-len(".out")] + ".nz"
        if os.path.exists(nz):
            with open(nz, "rb") as f:
                head, _, body = f.read().partition(b"\n")
            return LinkRun(0, "", int(head), body.decode("utf-8", "surrogateescape"),
                           cached=True)
    exe = os.path.join(work, tag + ".exe")
    if use_ld:
        obj = os.path.join(work, tag + ".o")
        r = subprocess.run([clang, "-c", s2, "-o", obj], capture_output=True, text=True)
        if r.returncode == 0:
            r = subprocess.run([ld, "-o", exe, obj, templates, runtime],
                               capture_output=True, text=True)
    else:
        r = subprocess.run([clang, s2, templates, runtime, "-o", exe],
                           capture_output=True, text=True)
    if r.returncode != 0:
        return LinkRun(r.returncode, r.stderr, None, "")
    p = subprocess.run([exe, *argv], capture_output=True, text=True)
    if key_path and p.returncode == 0:
        _publish(key_path, p.stdout.encode("utf-8", "surrogateescape"))
    elif key_path and p.returncode > 0:      # never a signal (negative status)
        _publish(key_path[:-len(".out")] + ".nz",
                 b"%d\n" % p.returncode + p.stdout.encode("utf-8", "surrogateescape"))
    return LinkRun(0, r.stderr, p.returncode, p.stdout)


# ── configure-time toolchain key for stages 3+4 ────────────────────────────
def run_base(s1_base, ld_wrapper):
    """The stage-3/4 toolchain key. Computed ONCE per configure (like
    CQ_S1_BASE): CQ_S1_BASE already carries the clang bytes + version; add the
    derived link wrapper, the version of the ld it execs, and the OS build (the
    trace is printed through libSystem's printf)."""
    if not s1_base or not ld_wrapper or not os.path.isfile(ld_wrapper):
        raise SystemExit("run-base: need a non-empty S1 base and an existing wrapper")
    h = hashlib.sha256()
    h.update(b"cq-run-base-v1\0")
    h.update(s1_base.encode() + b"\0")
    with open(ld_wrapper, "rb") as f:
        h.update(f.read())
    h.update(b"\0ld-v\0")
    ld = subprocess.run(["/usr/bin/ld", "-v"], capture_output=True)
    h.update(ld.stdout + ld.stderr)
    h.update(b"\0os\0")
    try:
        osv = subprocess.run(["/usr/bin/sw_vers"], capture_output=True, check=True)
        h.update(osv.stdout)
    except (OSError, subprocess.CalledProcessError):
        h.update(os.uname().version.encode())
    return h.hexdigest()


def main(argv):
    if len(argv) == 3 and argv[0] == "run-base":
        sys.stdout.write(run_base(argv[1], argv[2]))
        return 0
    if len(argv) == 2 and argv[0] == "lowered-digest":
        print(lowered_digest(argv[1]))
        return 0
    if len(argv) >= 7 and argv[0] == "run-manifest":
        sys.stdout.write(run_manifest(*argv[1:6], argv=argv[6:]))
        return 0
    print("usage: cq_stage_cache.py run-base <s1_base> <ld_wrapper>\n"
          "       cq_stage_cache.py lowered-digest <file.ll>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
