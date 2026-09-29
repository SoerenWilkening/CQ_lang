#!/usr/bin/env python3
"""cq_stage_cache.py — content-addressed cache for the e2e harness's PURE stages.

bd test_C_libtooling-2dfk (owner ruling 2026-09-29: "engineer faster tests");
re-keyed by bd test_C_libtooling-ffm0 (Rule-13 r1, F-r1-1..5).

WHAT IS CACHED, AND WHY THAT IS NOT A WEAKER TEST
-------------------------------------------------
An e2e check is a chain of stages. Only ONE of them is the thing under test:

    S1   clang -O1 -emit-llvm        f(clang, SDK, headers, env, FLAGS, source)        CACHED
    S2   cq-opt -passes=cq-lowering  THE PASS UNDER TEST                               NEVER CACHED
    S2b  free_pairing_check.py       f(lowered IR, checker bytes, FLAGS, python, env)  CACHED (bash runners)
    S3   clang -c + ld               f(lowered IR, clang, FLAGS, ld, both archives, env) } ONE entry:
    S4   run the executable          f(the executable, argv, env)                        } the trace

Every cached stage is a PURE FUNCTION of the bytes in its key. The trace runtime
is trace-only (no clock, no environment read, no randomness — `measure` returns
0), so S3+S4 map (lowered IR, archives, toolchain, argv) to one byte string, and
the goldens have always depended on exactly that determinism. A cache HIT
therefore returns the SAME answer the stage would compute, for a stage whose
inputs AND COMMAND have not changed; the stage under test (S2) runs every time
and a changed lowering is a changed key. The comparison that makes each check a
check — the trace against its golden, rolled against unrolled, the verdict
against the expected table — is NEVER cached and runs every time.

THE COMMAND IS PART OF THE KEY (bd ffm0, F-r1-1 — the P1 of the first version).
Keying a stage's INPUTS is not enough: the first version did not key the command
the harness applies to them, so a harness edit that must fail — `-include CQ.h`
on a lib TU (the C18 tripwire), `-O2` on stage 3 (the bd szpr pin), `-O0` on a
stage-1 line — was REPLAYED as the old pass on a warm cache (measured: 31
multi-TU entries and 5 slices that must fail passed warm). Every key now carries
  * the HARNESS DIGEST (`harness_digest`): the bytes of tests/e2e/run_slice.sh,
    run_slice_multi.sh, stage_cache.sh and this file — where every cached
    command is written. Any edit to any of them invalidates the whole cache,
    which is the conservative, correct behaviour for Rule 19 item 3's class;
  * the LITERAL flag arrays each stage runs with (stage-1 flags per call — the
    lib TUs' included, never a tag; `S3_CC_FLAGS` for stage 3), count-prefixed;
  * the identity (bytes) of the clang that runs the stage (`clang_id`);
  * the ENVIRONMENT DIGEST (`env_digest`) of KEY_ENV_VARS — the variables that
    steer clang (SDKROOT, CPATH, ...), ld (LIBRARY_PATH, ...), dyld (DYLD_*) or
    python (PYTHONPATH/HOME). Set-to-empty and unset are distinct.
free_pairing_check.py is keyed by its own bytes in the 2b key (the only stage
whose result depends on it) and deliberately NOT in the harness digest: two
copies of one component make a key that drops one of them undetectable by any
row (an equivalent mutant), and the selftest must be able to see every drop.

WHAT A HIT DOES NOT RE-WITNESS, stated so its absence is not read as coverage:
  * the MACHINE — "this toolchain still links and runs this IR on this box
    today". The toolchain half of the key (clang version, the headers under
    include/, the SYSROOT clang uses and its SDKSettings.json — see
    s1_cache_key.py; the ld wrapper, `ld -v`, `sw_vers`) is computed at
    CONFIGURE time: a `brew upgrade llvm@19` or a Command Line Tools update with
    no reconfigure is served stale, the same contract the build has. The clang
    DRIVER's bytes are hashed per run (`clang_id`); its dylibs
    (libclang-cpp/libLLVM) only through `clang --version`;
  * a header included RELATIVE TO A SOURCE (`#include "x.h"` outside include/)
    — measured 0 such includes in the e2e and railbank-pair sources today;
  * an in-place edit of a file INSIDE the SDK that leaves SDKSettings.json alone.
`CQ_E2E_NO_CACHE=1` switches every cache off (S1 included) for a from-scratch
run; deleting `build/tests/e2e/.s1cache` / `.runcache` is the same reset. There
is NO EVICTION (the cache grows by one small file per distinct module; the reset
is the eviction), and a SIGKILL between write and rename can leave a `.tmp` file
that is never read (measured 1 in 40 kills, 0 torn entries).

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
run. It is dropped from the S2b/S3/S4 key. That is exact UNLESS THAT LINE HOLDS A
CARRIAGE RETURN: the LLVM lexer ends a `;` comment at CR as well as LF, so text
after a CR would be IR (bd ffm0 F-r1-3, measured: two modules with one digest,
exit 0 and 7). A first line containing CR is therefore hashed WHOLE (it then
never hits — safe). Otherwise the line is an IR comment; the module identifier
of the stage-3 compile comes from its own command-line path (also a fresh temp
path), and `free_pairing_check.py` matches only `define`, `@global =` and label
lines outside a function, none of which a `;` line can match.

KEY FRAMING. Every key is sha256 over NUL-TERMINATED fields, with every
variable-length list COUNT-PREFIXED (flags, argv): paths and argv strings cannot
contain NUL, so the framing is injective (bd ffm0 F-r1-5: the first version
joined argv with newlines, so ["a\\narg:b"] and ["a", "b"] shared a key).

Environment (exported to every e2e entry by tests/e2e/CMakeLists.txt):
    CQ_S1CACHE, CQ_S1_BASE   stage-1 cache dir + configure-time toolchain key
    CQ_RUNCACHE              dir for the S2b / S3+S4 entries
    CQ_RUN_BASE              stage-3/4 configure-time toolchain key
                             (`cq_stage_cache.py run-base`)
    CQ_E2E_NO_CACHE          non-empty => every cache is OFF (forced full run)

A by-hand invocation (no env) caches nothing — byte-identical to the old harness.

The KEY TEXT of the run key, the harness digest and the env digest is shared
with tests/e2e/stage_cache.sh, which spells it with printf + `openssl dgst` (a
python start per slice would cost more than the hash): the two spellings MUST
stay identical, and `tools/cq_stage_cache_test.py` checks that they are.
"""
import functools
import hashlib
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
E2E = os.path.join(os.path.dirname(HERE), "tests", "e2e")

RUN_VERSION = "cq-run-v2"
S1_VERSION = "cq-s1-v2"
# The ONE spelling of the python stage-3 compile flags; `link_and_run`'s command
# and the run key both read it (bd szpr: deliberately NO -O). The bash twin is
# stage_cache.sh's CQ_S3_CC_FLAGS, and the run keys of the two are one namespace.
S3_CC_FLAGS = ("-c",)
# SORTED; identical to stage_cache.sh's CQ_KEY_ENV_VARS.
KEY_ENV_VARS = (
    "CCC_OVERRIDE_OPTIONS", "COMPILER_PATH", "CPATH", "CPLUS_INCLUDE_PATH",
    "C_INCLUDE_PATH", "DEVELOPER_DIR", "DYLD_FALLBACK_LIBRARY_PATH",
    "DYLD_INSERT_LIBRARIES", "DYLD_LIBRARY_PATH", "LIBRARY_PATH",
    "MACOSX_DEPLOYMENT_TARGET", "OBJCPLUS_INCLUDE_PATH", "OBJC_INCLUDE_PATH",
    "PYTHONHOME", "PYTHONPATH", "SDKROOT", "SOURCE_DATE_EPOCH",
)
# The files every cached COMMAND is written in, in key order (name, path).
HARNESS_FILES = (
    ("run_slice.sh", os.path.join(E2E, "run_slice.sh")),
    ("run_slice_multi.sh", os.path.join(E2E, "run_slice_multi.sh")),
    ("stage_cache.sh", os.path.join(E2E, "stage_cache.sh")),
    ("cq_stage_cache.py", os.path.join(HERE, "cq_stage_cache.py")),
)


def _env(name):
    return os.environ.get(name, "")


def disabled():
    return bool(_env("CQ_E2E_NO_CACHE"))


def s1_enabled():
    return (not disabled() and bool(_env("CQ_S1CACHE")) and bool(_env("CQ_S1_BASE"))
            and harness_digest() is not None)


def run_enabled():
    return (not disabled() and bool(_env("CQ_RUNCACHE")) and bool(_env("CQ_RUN_BASE"))
            and harness_digest() is not None)


def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def sha_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def frame(fields):
    """NUL-terminated field framing — exactly what `printf '%s\\0'` produces."""
    out = bytearray()
    for f in fields:
        b = f if isinstance(f, bytes) else str(f).encode("utf-8", "surrogateescape")
        if b"\0" in b:
            raise ValueError("a key field contains NUL")
        out += b + b"\0"
    return bytes(out)


def counted(tag, items):
    """A count-prefixed list: tag, N, item_1 ... item_N."""
    return [tag, str(len(items))] + list(items)


@functools.lru_cache(maxsize=None)
def harness_digest():
    """sha256 over the bytes of HARNESS_FILES; None if any is unreadable (then
    every cache is off). Memoised: the files do not change under one harness
    process."""
    fields = ["cq-hd-v1"]
    try:
        for name, path in HARNESS_FILES:
            fields += [name, sha_file(path)]
    except OSError:
        return None
    return sha_bytes(frame(fields))


def env_digest(env=None):
    env = os.environ if env is None else env
    fields = ["cq-env-v1"]
    fields += ["%s=%s" % (v, env[v]) for v in KEY_ENV_VARS if v in env]
    return sha_bytes(frame(fields))


@functools.lru_cache(maxsize=None)
def clang_id(clang):
    """sha256 of the clang executable's bytes (symlinks followed); None if it
    cannot be read (then that call is not cached)."""
    try:
        return sha_file(clang)
    except OSError:
        return None


def lowered_digest(path):
    """sha256 of a lowered module MINUS a leading `; ModuleID = ` comment line
    (the one line that names a temp path) — unless that line holds a CR, in
    which case the module is hashed WHOLE (see the module docstring)."""
    with open(path, "rb") as f:
        data = f.read()
    if data.startswith(b"; ModuleID = "):
        nl = data.find(b"\n")
        first = data if nl < 0 else data[:nl]
        if b"\r" not in first:
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
def s1_key(kind, clang, flags, src_path, src_digest):
    """The python stage-1 key (its own namespace, `gen/` and `file/`; the bash
    runners' entries live at the cache root and are never shared)."""
    cid = clang_id(clang)
    if cid is None:
        return None
    fields = [S1_VERSION + "-" + kind, harness_digest(), _env("CQ_S1_BASE"), cid,
              env_digest()]
    fields += counted("flags", list(flags))
    fields += ["src", src_path, src_digest]
    return sha_bytes(frame(fields))


def stage1_generated(clang, flags, csrc, work, name):
    """Stage 1 of a GENERATED source (text, not a file on disk).

    Returns (returncode, stderr, ir_path). Uncached: writes `<work>/<name>.c`
    and compiles it there — exactly what the harnesses did before. Cached: the
    source is written to a CONTENT-ADDRESSED path under CQ_S1CACHE and compiled
    from there, so its `source_filename` is a pure function of the key and a hit
    is byte-identical to the miss that published it."""
    key = None
    if s1_enabled():
        root = os.path.join(_env("CQ_S1CACHE"), "gen")
        src_digest = sha_bytes(csrc.encode())
        cpath = os.path.join(root, src_digest + ".c")
        key = s1_key("gen", clang, flags, cpath, src_digest)
    if key is None:
        cpath = os.path.join(work, name + ".c")
        with open(cpath, "w") as f:
            f.write(csrc)
        out = os.path.join(work, name + ".s1.ll")
        r = subprocess.run([clang, *flags, cpath, "-o", out],
                           capture_output=True, text=True)
        return r.returncode, r.stderr, out
    if not os.path.exists(cpath):
        _publish(cpath, csrc.encode())
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
    key = None
    if s1_enabled():
        key = s1_key("file", clang, flags, os.path.abspath(src), sha_file(src))
    if key is None:
        r = subprocess.run([clang, *flags, src, "-o", out],
                           capture_output=True, text=True)
        return r.returncode, r.stderr, out
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
def run_manifest(hd, run_base, cid, s3_flags, s2_digest, tpl_digest, rt_digest,
                 ld_digest, envd, argv=()):
    """THE key text (bytes) for one link+run. stage_cache.sh's `cq_cache_keys`
    builds the identical bytes with printf for argv=(); keep the two in
    lock-step (selftest row I)."""
    fields = [RUN_VERSION, hd, run_base, cid]
    fields += counted("s3cc", list(s3_flags))
    fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]
    fields += counted("argc", list(argv))
    return frame(fields)


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
    cid = clang_id(clang) if use_ld else None
    if run_enabled() and use_ld and cid is not None and os.path.isfile(s2):
        manifest = run_manifest(harness_digest(), _env("CQ_RUN_BASE"), cid, S3_CC_FLAGS,
                                lowered_digest(s2), sha_file(templates),
                                sha_file(runtime), sha_file(ld), env_digest(), argv)
        key_path = os.path.join(_env("CQ_RUNCACHE"), "run", sha_bytes(manifest) + ".out")
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
        r = subprocess.run([clang, *S3_CC_FLAGS, s2, "-o", obj],
                           capture_output=True, text=True)
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
    CQ_S1_BASE): CQ_S1_BASE already carries the clang bytes + version + sysroot;
    add the derived link wrapper, the version of the ld it execs, and the OS
    build (the trace is printed through libSystem's printf)."""
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
    if len(argv) == 1 and argv[0] == "harness-digest":
        print(harness_digest())
        return 0
    if len(argv) == 1 and argv[0] == "env-digest":
        print(env_digest())
        return 0
    print("usage: cq_stage_cache.py run-base <s1_base> <ld_wrapper>\n"
          "       cq_stage_cache.py lowered-digest <file.ll>\n"
          "       cq_stage_cache.py harness-digest | env-digest", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
