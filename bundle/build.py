#!/usr/bin/env python3
"""Build the version 1 injection bundle (cq-w1-bundle; CLAUDE.md "Pipeline").

    bundle/build.py --musl <checkout> --llvm-project <checkout> [--write]

Compiles the pinned translation units of bundle/pins.json at clang 19.1.7 -O1 for the corpus triple and
links them into one bitcode module, bundle/<output>. One module, so `llvm-link --only-needed` pulls a
helper's callees (logb -> ilogb, ...) whatever order the consumers list files in.

Every input is pinned: the checkout's commit, and the sha256 of every file under a source root (or the CQ
arch headers) that clang read, found from its -MD dependency list. The output's sha256 is pinned too: a
build that does not reproduce it fails. `--write` re-pins the file hashes and the output (a deliberate
bump, committed on its own); commits and units are only ever edited by hand.

Nothing is written into the checkouts; generated headers and objects go to a temporary directory.
"""
import argparse
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
PINS = HERE / "pins.json"
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
SPEC_DIR = Path(os.environ.get("CQ_SPEC_DIR", ROOT.parent / "CQ_spec"))
if not SPEC_DIR.exists():  # a worktree under wt/ sits one level deeper than the main checkout
    SPEC_DIR = ROOT.parent.parent / "CQ_spec"


class BuildError(Exception):
    pass


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def run(cmd, cwd=None) -> str:
    r = subprocess.run([str(c) for c in cmd], cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise BuildError(f"{shlex.join(map(str, cmd))} exited {r.returncode}:\n{r.stderr}")
    return r.stdout


def check_toolchain(want: str) -> None:
    out = run([LLVM_BIN / "clang", "--version"])
    if f"clang version {want}" not in out.splitlines()[0]:
        raise BuildError(f"bundle: need clang {want} at {LLVM_BIN}, found: {out.splitlines()[0]}")


def check_rev(checkout: Path, rev: str, name: str) -> None:
    head = run(["git", "-C", checkout, "rev-parse", "HEAD"]).strip()
    if head != rev:
        raise BuildError(f"bundle: {name} checkout {checkout} is at {head}, pinned {rev}")


def musl_alltypes(musl: Path, out: Path) -> None:
    """obj/include/bits/alltypes.h exactly as musl's Makefile makes it (tools/mkalltypes.sed over
    arch/x86_64/bits/alltypes.h.in and include/alltypes.h.in), in Python so no sed dialect matters."""
    lines = []
    for src in (musl / "arch/x86_64/bits/alltypes.h.in", musl / "include/alltypes.h.in"):
        for line in src.read_text().splitlines():
            m = re.match(r"^TYPEDEF (.*) ([^ ]*);$", line)
            if m:
                t, n = m.groups()
                lines += [f"#if defined(__NEED_{n}) && !defined(__DEFINED_{n})", f"typedef {t} {n};",
                          f"#define __DEFINED_{n}", "#endif", ""]
                continue
            m = re.match(r"^(STRUCT|UNION) * ([^ ]*) (.*);$", line)
            if m:
                k, n, body = m.groups()
                kw = k.lower()
                lines += [f"#if defined(__NEED_{kw}_{n}) && !defined(__DEFINED_{kw}_{n})", f"{kw} {n} {body};",
                          f"#define __DEFINED_{kw}_{n}", "#endif", ""]
                continue
            lines.append(line)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n")


def deps(dfile: Path) -> list:
    text = dfile.read_text().replace("\\\n", " ")
    return [Path(p) for p in text.split(":", 1)[1].split()]


def build(srcs: dict, pins: dict, tmp: Path) -> tuple:
    """Compile every unit; return (the linked bundle path, {pinned file label: sha256})."""
    roots = {}
    for name, s in pins["sources"].items():
        roots[name] = srcs[name] / s["root"]
    arch_cq = SPEC_DIR / "_tools" / "musl_arch_cq"
    roots["cq_spec"] = arch_cq
    gen = tmp / "musl-obj" / "include"
    musl_alltypes(srcs["musl"], gen / "bits" / "alltypes.h")

    triple = pins["triple"]
    read = {f"musl:{p}": sha256(srcs["musl"] / p)  # the inputs of the generated alltypes.h
            for p in ("arch/x86_64/bits/alltypes.h.in", "include/alltypes.h.in", "tools/mkalltypes.sed")}
    bcs = []
    for name, s in pins["sources"].items():
        base = srcs[name] / s["root"]
        inc = []
        for i in s.get("include", []):
            if i == "@cq_arch":
                inc += ["-I", arch_cq]
            elif i == "@musl_obj":
                inc += ["-I", gen]
            else:
                inc += ["-I", base / i]
        for unit in s["units"]:
            bc = tmp / f"{name}.{Path(unit).stem}.bc"
            d = bc.with_suffix(".d")
            # Run from the checkout with a relative path, so the module's source_filename is the unit's
            # path in its project and not where the checkout happens to live.
            run([LLVM_BIN / "clang", f"--target={triple}", *s["flags"], *inc, "-c", "-emit-llvm",
                 "-MD", "-MF", d, unit, "-o", bc], cwd=base)
            for p in deps(d):
                p = (base / p).resolve() if not p.is_absolute() else p.resolve()
                for rname, r in roots.items():
                    r = r.resolve()
                    if p == r or r in p.parents:
                        read[f"{rname}:{p.relative_to(r)}"] = sha256(p)
                        break
            bcs.append(bc)
    out = tmp / pins["output"]
    run([LLVM_BIN / "llvm-link", *bcs, "-o", out])
    return out, dict(sorted(read.items()))


def closed(bc: Path) -> None:
    """Every callee of a bundle body is in the bundle (llvm.* intrinsics aside): no bundle function
    reaches the host's libraries."""
    und = run([LLVM_BIN / "llvm-nm", "--undefined-only", "--format=just-symbols", bc]).split()
    und = [u for u in und if not u.startswith("llvm.")]
    if und:
        raise BuildError(f"bundle: undefined symbols in the bundle: {und}")


def main(argv) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--musl", required=True, type=Path)
    ap.add_argument("--llvm-project", required=True, type=Path)
    ap.add_argument("--write", action="store_true", help="re-pin file and output hashes")
    ap.add_argument("--out", type=Path, help="write the bundle here instead of bundle/<output> (a check build)")
    a = ap.parse_args(argv)
    pins = json.loads(PINS.read_text())
    srcs = {"musl": a.musl.resolve(), "llvm-project": a.llvm_project.resolve()}
    check_toolchain(pins["clang"])
    for name, s in pins["sources"].items():
        check_rev(srcs[name], s["rev"], name)
    with tempfile.TemporaryDirectory(prefix="cqbundle.") as t:
        out, read = build(srcs, pins, Path(t))
        closed(out)
        digest = sha256(out)
        if a.write:
            pins["files"] = read
            pins["sha256"] = digest
            PINS.write_text(json.dumps(pins, indent=2) + "\n")
        else:
            if read != pins.get("files"):
                old, new = pins.get("files", {}), read
                diff = sorted(k for k in set(old) | set(new) if old.get(k) != new.get(k))
                raise BuildError(f"bundle: pinned source files differ: {diff}")
            if digest != pins.get("sha256"):
                raise BuildError(f"bundle: output sha256 {digest} != pinned {pins.get('sha256')}")
        dest = a.out or (HERE / pins["output"])
        dest.write_bytes(out.read_bytes())
    print(f"bundle: {dest} sha256 {digest}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except BuildError as e:
        print(e, file=sys.stderr)
        sys.exit(1)
