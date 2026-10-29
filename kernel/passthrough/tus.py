#!/usr/bin/env python3
"""tus.py: the TU list of the tier-1 passthrough build (cq-w1-kernel-t1).

A TU is every kernel C file kbuild compiled with kcc to an object (`-c -o X.o Y.c`, outside scripts/),
found from kbuild's own .X.o.cmd files under $KOUT, plus every such compile that failed (from the
build logs: `*** [...: X.o] Error`). Prints one line per TU, sorted:
    object <TAB> source <TAB> opt level (the last -O flag kbuild passed) <TAB> state
state: bitcode (the object is LLVM bitcode) | not-bitcode | compile-failed.
"""
import os, re, shlex, sys
from pathlib import Path

KOUT = Path(os.environ["KOUT"]); KTREE = Path(os.environ["KTREE"]); KSRC = Path(os.environ["KSRC"])
# raw bitcode, and the wrapper header LLVM puts in front of it for Darwin triples
BITCODE = (b"BC\xc0\xde", b"\xde\xc0\x17\x0b")

def is_kcc(argv0):
    """The compiler of a .cmd line is this harness's kcc, whichever checkout ran the build: the .cmd
    files record the absolute path of the kcc kbuild was given (a worktree that may be gone since), so
    the match is on the path's last two components (kernel/passthrough/kcc), not on this file's path."""
    p = Path(argv0)
    return p.name == "kcc" and p.parent.name == "passthrough" and p.parent.parent.name == "kernel"

def tus():
    out = {}
    for root, dirs, files in os.walk(KOUT):
        rel = Path(root).relative_to(KOUT)
        if rel.parts and rel.parts[0] in ("scripts", "tools"):
            dirs[:] = []; continue
        for f in files:
            if not (f.startswith(".") and f.endswith(".o.cmd")):
                continue
            line = open(os.path.join(root, f), errors="replace").readline()
            m = re.match(r"savedcmd_(\S+) := (.*)$", line)
            if not m:
                continue
            obj, cmd = m.group(1), m.group(2)
            argv = shlex.split(cmd.split(";")[0])
            if not argv or not is_kcc(argv[0]):
                continue
            if "-c" not in argv or "-o" not in argv:
                continue
            srcs = [a for a in argv[1:] if a.endswith(".c")]
            if not srcs or argv[argv.index("-o") + 1] != obj:
                continue
            ol = [a for a in argv if re.fullmatch(r"-O[0-3sz]?", a)]
            o = KOUT / obj
            state = "bitcode" if o.exists() and open(o, "rb").read(4) in BITCODE else "not-bitcode"
            src = srcs[-1]
            src = str(Path(src).relative_to(KTREE)) if src.startswith(str(KTREE)) else src
            out[obj] = (obj, src, ol[-1] if ol else "", state)
    for log in sorted((KSRC / "logs").glob("*.log")):
        for m in re.finditer(r"\*\*\* \[\S+: (\S+\.o)\] Error", open(log, errors="replace").read()):
            obj = m.group(1)
            if obj not in out and not (KOUT / obj).exists() and (KTREE / obj).with_suffix(".c").exists():
                out[obj] = (obj, str(Path(obj).with_suffix(".c")), "", "compile-failed")
    return [out[k] for k in sorted(out)]

if __name__ == "__main__":
    ts = tus()
    for t in ts:
        print("\t".join(t))
    if not ts:   # an empty list is never a vacuous pass for the callers
        print(f"tus: no TUs found under {KOUT}", file=sys.stderr)
        sys.exit(1)
