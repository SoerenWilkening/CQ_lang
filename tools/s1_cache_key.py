#!/usr/bin/env python3
"""Compute the TOOLCHAIN half of the e2e stage-1 cache key. Run ONCE, by CMake.

Stage 1 (`clang -I<inc> -include CQ.h -O1 -emit-llvm -S slice.c`) is a PURE
FUNCTION of the compiler, its flags, the headers it can see, and the source --
and, critically, it does NOT depend on the cq-lowering plugin. The plugin is the
thing that changes on every iteration; the slice sources and CQ.h almost never
do. So a full run spends ~104s of CPU recomputing a byte-identical answer.

The key is split in two so the expensive half is paid once:

    BASE  (this script, at CMake configure time) = clang bytes + clang --version
                                                   + every header under <inc>
                                                   + the literal flag string
    FULL  (run_slice.sh, per slice)              = sha256(BASE || source bytes)

That keeps the per-slice cost to a single `openssl dgst` over one small .c
(MEASURED 0.006s CPU, against the 0.428s of stage 1 it replaces). Hashing the
compiler here rather than per-slice is the entire reason for the split -- doing
it 220 times would cost more than it saves.

CORRECTNESS IS THE WHOLE POINT. A test-input cache that returns a stale artifact
does not make a test slow, it makes it LIE: the pass would be exercised against
IR that no longer corresponds to the source. So every component is CONTENT,
never a timestamp -- a stale hit requires a SHA-256 collision, not clock skew.
Hashing the clang BINARY (not just its version string) is what catches an
in-place toolchain upgrade that keeps the same version number.

⚠ CORRECTED (bd test_C_libtooling-ffm0, Rule-13 r1 F-r1-4, L7 at the source):
this paragraph used to say the system SDK headers "cannot move without the clang
bytes or version changing, so they are covered transitively". That is FALSE on
this box: Homebrew clang takes its sysroot from the Command Line Tools
(`-isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`), which update
independently of clang. So the key now hashes the SYSROOT clang actually uses
(read from `clang -###`, not from `xcrun`, which reports the Xcode SDK — a
different one) and that SDK's SDKSettings.json (its name + version). Residuals,
declared: an in-place edit of a header inside the SDK that leaves SDKSettings.json
alone; the environment that steers clang at TEST time (SDKROOT, CPATH, ...) is
keyed per test by tests/e2e/stage_cache.sh / tools/cq_stage_cache.py, not here.

Any failure is fatal and loud. A cache that silently degraded to a fixed key
would serve one slice's IR to every other slice -- the exact silent-miscompile
shape this project exists to avoid.
"""
import hashlib
import os
import subprocess
import sys


def main():
    if "--" not in sys.argv:
        raise SystemExit("usage: s1_cache_key.py <clang> <incdir> -- <flags...>")
    split = sys.argv.index("--")
    if split != 3:
        raise SystemExit("usage: s1_cache_key.py <clang> <incdir> -- <flags...>")
    clang, incdir = sys.argv[1:3]
    flags = sys.argv[split + 1:]

    h = hashlib.sha256()

    def feed_file(path):
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)

    # 1. the compiler itself -- bytes, so an in-place upgrade cannot alias.
    #    realpath first: `clang` is typically a symlink into the Cellar.
    h.update(b"clang-binary\0")
    feed_file(os.path.realpath(clang))

    # 2. its reported identity (catches a shim/wrapper swap around the same bytes)
    h.update(b"\0clang-version\0")
    ver = subprocess.run([clang, "--version"], capture_output=True, check=True)
    h.update(ver.stdout)

    # 3. every header the include dir exposes, in a stable order
    h.update(b"\0headers\0")
    for root, dirs, files in os.walk(incdir):
        dirs.sort()
        for name in sorted(files):
            if name.endswith((".h", ".hpp", ".inc")):
                p = os.path.join(root, name)
                h.update(os.path.relpath(p, incdir).encode())
                h.update(b"\0")
                feed_file(p)

    # 4. the SYSROOT this clang compiles against, as the driver itself reports it
    #    (`-isysroot <dir>` in its -### job), plus that SDK's SDKSettings.json.
    #    No sysroot (a non-Darwin driver) is keyed as its absence.
    h.update(b"\0sysroot\0")
    job = subprocess.run([clang, "-###", "-x", "c", "-c", os.devnull],
                         capture_output=True, text=True, check=True)
    toks = [x.strip('"') for x in job.stderr.split()]
    sysroot = toks[toks.index("-isysroot") + 1] if "-isysroot" in toks else ""
    h.update(sysroot.encode() + b"\0")
    settings = os.path.join(sysroot, "SDKSettings.json") if sysroot else ""
    if settings and os.path.isfile(settings):
        feed_file(settings)
    else:
        h.update(b"no-SDKSettings.json")

    # 5. the exact flags
    h.update(b"\0flags\0")
    h.update("\0".join(flags).encode())

    sys.stdout.write(h.hexdigest())


if __name__ == "__main__":
    main()
