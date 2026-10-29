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
KCC = str(Path(__file__).resolve().parent / "kcc")

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
            if not cmd.startswith(KCC + " "):
                continue
            argv = shlex.split(cmd.split(";")[0])
            if "-c" not in argv or "-o" not in argv:
                continue
            srcs = [a for a in argv[1:] if a.endswith(".c")]
            if not srcs or argv[argv.index("-o") + 1] != obj:
                continue
            ol = [a for a in argv if re.fullmatch(r"-O[0-3sz]?", a)]
            o = KOUT / obj
            state = "bitcode" if o.exists() and open(o, "rb").read(4) == b"BC\xc0\xde" else "not-bitcode"
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
    for t in tus():
        print("\t".join(t))
