#!/usr/bin/env python3
"""Build the injection bundle (cq-w1-bundle; CLAUDE.md "Pipeline") and the full musl module.

    bundle/build.py --musl <checkout> --llvm-project <checkout> [--write] [--out FILE]
    bundle/build.py --full --musl <checkout> --out libc.ll [--work DIR] [--jobs N] [--write]

Version 1 (the default): compiles the pinned translation units of bundle/pins.json at clang 19.1.7 -O1 for the
corpus triple and links them into one bitcode module, bundle/<output>. One module, so `llvm-link --only-needed`
pulls a helper's callees (logb -> ilogb, ...) whatever order the consumers list files in. Every input is pinned:
the checkout's commit, and the sha256 of every file under a source root (or the CQ arch headers) that clang read,
found from its -MD dependency list. The output's sha256 is pinned too: a build that does not reproduce it fails.
`--write` re-pins the file hashes and the output (a deliberate bump, committed on its own); commits and units
are only ever edited by hand.

--full: the whole C library, as the musl sweep cuts its rows from (what wt/musl_sweep/libc_sweep2.py `build` did,
now committed): every .c of musl's src/<dir> for pins.json "full" dirs (src/thread: the C11 <threads.h> wrappers
only) and src/internal, compiled with the "full" flags into a cache under --work, plus bundle/src/*.c, linked into
one textual module. No file hashes are pinned (the checkout's commit is).

Both modes then apply the same recipe (bundle/recipe.json) to the linked module, in this order:

1. The string formatters over bundle-internal copies (tools/cq_formatters.py; CR rule 16, cq-2s5ho, cq-ojgho):
   sprintf, snprintf, sscanf, swprintf, swscanf, their v forms and the result entries call __cq_vfprintf,
   __cq_vfscanf, __cq_vfwprintf, __cq_vfwscanf and copies of what those call by name.
2. FILE objects (owner ruling 2026-11-11 Q6): recipe "omit" names every public function that reads or writes a
   FILE it did not create (a FILE * parameter, a standard stream, the open-file list; itself or through internal
   helpers), every internal helper that reaches a standard stream or the open-file list, and the standard stream
   objects. Their bodies (definitions) are deleted, so a call of one is bodiless: rule 16's host boundary. A kept
   body that still refers to stdin, stdout, stderr or __std{in,out,err}_{FILE,used} is a BUILD ERROR (cured by
   adding that body to "omit"). --full re-derives the list from musl's source and fails when it differs from
   recipe.json (--write rewrites it); see derive_omit() for the derivation.
3. Version 1 only (the recipe applies to the "recipe_units" module; the plain "units", which have no stdio, are
   linked to it afterwards from their own bitcode): every function that pins.json "export" does not name is internalized (it keeps
   musl's name), then globaldce and strip-dead-prototypes. So the bundle rule (driver/cqcc, checker oracle.py:
   the bundle is linked iff the program declares a symbol it defines) sees only the exported names, and a program
   that calls strlen or memcpy does not start linking the bundle because a formatter needs them.
4. Version 1: closed: every symbol the module uses is defined, but llvm.* intrinsics, the omitted names (host calls)
   and recipe "bodiless" (the allocator, __cq_syscall).

The result entries (owner ruling 2026-11-12 item 5, cq-cdf9z; bundle/src/cq_count.c): recipe.json "entries" lists
them. They are external functions under reserved names __cq_count_*, defined in both modes and exported by version 1.
They are NOT kept alive by llvm.used (that would link and lower printf_core into every program that links the
bundle, the corpus examples among them). The keep-alive contract is driver/cq_entries.py's: a consumer that links a
program for the pass (which inserts calls to the entries after the link) declares the entries the program needs
before the link, in a unit naming them in @llvm.compiler.used (so `llvm-link --only-needed` pulls their bodies and
the bundle rule links the bundle), and keeps them through any internalize/globaldce strip (e.g. adds them to
-internalize-public-api-list).

Nothing is written into the checkouts; generated headers and objects go to a temporary directory (or --work).
"""
import argparse
import concurrent.futures
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
RECIPE = HERE / "recipe.json"
FORMATTERS = ROOT / "tools" / "cq_formatters.py"
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
SPEC_DIR = Path(os.environ.get("CQ_SPEC_DIR", ROOT / "spec"))
if not SPEC_DIR.exists():  # a worktree under wt/ sits one level deeper than the main checkout
    SPEC_DIR = ROOT / "spec"
# musl's weak_alias is an ELF alias that clang's Darwin front end refuses: such a unit is compiled for musl's own
# ELF target and its IR carried over to the corpus triple (x86_64 SysV either way; libc_sweep2.py's method)
ELF_TRIPLE = "x86_64-unknown-linux-musl"
# owner ruling 2026-11-11 Q6: the objects no kept body may refer to
STD_STREAMS = ("stdin", "stdout", "stderr", "__stdin_FILE", "__stdout_FILE", "__stderr_FILE",
               "__stdin_used", "__stdout_used", "__stderr_used")


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
    text = "\n".join(lines) + "\n"
    if not out.exists() or out.read_text() != text:
        out.write_text(text)
    # obj/include/bits/syscall.h: `cp syscall.h.in; sed -n -e s/__NR_/SYS_/p < syscall.h.in >>` (musl's Makefile)
    src = (musl / "arch/x86_64/bits/syscall.h.in").read_text()
    text = src + "".join(l.replace("__NR_", "SYS_", 1) + "\n" for l in src.splitlines() if "__NR_" in l)
    sc = out.parent / "syscall.h"
    if not sc.exists() or sc.read_text() != text:
        sc.write_text(text)


def deps(dfile: Path) -> list:
    text = dfile.read_text().replace("\\\n", " ")
    return [Path(p) for p in text.split(":", 1)[1].split()]


def includes(s: dict, base: Path, srcs: dict, gen: Path) -> list:
    """-I flags of a source entry: @cq_arch, @musl_obj, @musl:<path in the musl checkout>, else relative to its root."""
    inc = []
    for i in s.get("include", []):
        if i == "@cq_arch":
            inc += ["-I", SPEC_DIR / "_tools" / "musl_arch_cq"]
        elif i == "@musl_obj":
            inc += ["-I", gen]
        elif i.startswith("@musl:"):
            inc += ["-I", srcs["musl"] / i[len("@musl:"):]]
        else:
            inc += ["-I", base / i]
    return inc


def compile_unit(flags: list, inc: list, unit: str, base: Path, out: Path, triple: str, text: bool) -> Path:
    """clang -O1 of one unit (run from its root with a relative path, so source_filename is the unit's path in its
    project); the ELF fallback for a unit with an alias. Writes `out` (.ll if text, else .bc) and its .d."""
    d = out.with_suffix(".d")
    kind = ["-S"] if text else ["-c"]
    cmd = [LLVM_BIN / "clang", f"--target={triple}", *flags, *inc, *kind, "-emit-llvm", "-MD", "-MF", d, unit, "-o", out]
    r = subprocess.run([str(c) for c in cmd], cwd=base, capture_output=True, text=True)
    if r.returncode and "aliases are not supported on darwin" in r.stderr:
        ll = out.with_suffix(".elf.ll")
        run([LLVM_BIN / "clang", f"--target={ELF_TRIPLE}", *flags, *inc, "-S", "-emit-llvm", "-MD", "-MF", d,
             unit, "-o", ll], cwd=base)
        t = ll.read_text()
        t = re.sub(r"^target triple = .*$", f'target triple = "{triple}"', t, flags=re.M)
        t = re.sub(r'^target datalayout = "e-m:e-', 'target datalayout = "e-m:o-', t, flags=re.M)
        if text:
            out.write_text(t)
        else:
            ll.write_text(t)
            run([LLVM_BIN / "llvm-as", ll, "-o", out])
        ll.unlink()
    elif r.returncode:
        raise BuildError(f"{shlex.join(map(str, cmd))} exited {r.returncode}:\n{r.stderr}")
    return out


# --- the version 1 bundle --------------------------------------------------------------------------------------
def build_v1(srcs: dict, pins: dict, tmp: Path) -> tuple:
    """Compile every unit; return ([the plain units' bitcode], the recipe units linked, {pinned file label: sha256}).
    A source's "units" are linked as they are (they have no stdio); its "recipe_units" (the string formatters with
    what they reach, and bundle/src) are linked into one module that the recipe is applied to."""
    roots = {name: srcs[name] / s["root"] for name, s in pins["sources"].items()}
    roots["cq_spec"] = SPEC_DIR / "_tools" / "musl_arch_cq"
    gen = tmp / "musl-obj" / "include"
    musl_alltypes(srcs["musl"], gen / "bits" / "alltypes.h")

    triple = pins["triple"]
    read = {f"musl:{p}": sha256(srcs["musl"] / p)  # the inputs of the generated headers
            for p in ("arch/x86_64/bits/alltypes.h.in", "include/alltypes.h.in", "tools/mkalltypes.sed",
                      "arch/x86_64/bits/syscall.h.in")}
    plain, rec = [], []
    for name, s in pins["sources"].items():
        base = srcs[name] / s["root"]
        inc = includes(s, base, srcs, gen)
        for unit, dest in [(u, plain) for u in s.get("units", [])] + [(u, rec) for u in s.get("recipe_units", [])]:
            bc = tmp / f"{name}.{unit.replace('/', '_')[:-2]}.bc"
            flags = [*s["flags"], *s.get("unit_flags", {}).get(unit, [])]
            compile_unit(flags, inc, unit, base, bc, triple, text=False)
            for p in deps(bc.with_suffix(".d")):
                p = (base / p).resolve() if not p.is_absolute() else p.resolve()
                for rname, r in roots.items():
                    r = r.resolve()
                    if p == r or r in p.parents:
                        read[f"{rname}:{p.relative_to(r)}"] = sha256(p)
                        break
            dest.append(bc)
    out = tmp / "recipe.bc"
    run([LLVM_BIN / "llvm-link", *rec, "-o", out])
    return plain, out, dict(sorted(read.items()))


# --- the full musl module --------------------------------------------------------------------------------------
def full_units(musl: Path, full: dict) -> list:
    """(dir, unit) of every musl unit of the full module, in libc_sweep2.py's order."""
    thread = re.compile(full["thread_units"])
    out = []
    for d in full["dirs"]:
        for f in sorted(os.listdir(musl / "src" / d)):
            if f.endswith(".c") and (d != "thread" or thread.match(f)):
                out.append((d, f"src/{d}/{f}"))
    out += [("internal", f"src/internal/{f}") for f in sorted(os.listdir(musl / "src" / "internal")) if f.endswith(".c")]
    return [(d, u) for d, u in out if u not in full.get("exclude", {})]


def build_full(srcs: dict, pins: dict, work: Path, jobs: int) -> Path:
    full, musl = pins["full"], srcs["musl"]
    s = pins["sources"]["musl"]
    gen = work / "musl-obj" / "include"
    musl_alltypes(musl, gen / "bits" / "alltypes.h")
    inc = includes(s, musl, srcs, gen)
    lldir = work / "ll"
    lldir.mkdir(parents=True, exist_ok=True)
    jobs_ = []
    for _, unit in full_units(musl, full):
        jobs_.append((musl, unit, [*full["flags"], *full.get("unit_flags", {}).get(unit, [])], inc,
                      lldir / (unit.replace("/", "_")[:-2] + ".ll")))
    cq = pins["sources"]["cq"]
    cqbase = srcs["cq"] / cq["root"]
    for unit in cq["recipe_units"]:
        jobs_.append((cqbase, unit, [*full["flags"]], includes(cq, cqbase, srcs, gen),
                      lldir / ("cq_" + unit.replace("/", "_")[:-2] + ".ll")))

    def one(j):
        base, unit, flags, inc_, out = j
        # cached by the exact command (and the unit's bytes): a rerun after a partial build is incremental
        key = hashlib.sha256(json.dumps([str(x) for x in (*flags, *inc_, unit)]).encode()
                             + (base / unit).read_bytes()).hexdigest()
        stamp = out.with_suffix(".key")
        if out.exists() and stamp.exists() and stamp.read_text() == key:
            return out
        compile_unit(flags, inc_, unit, base, out, full["triple"], text=True)
        stamp.write_text(key)
        return out

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
        lls = list(ex.map(one, jobs_))
    out = work / "linked.ll"
    run([LLVM_BIN / "llvm-link", "-S", *lls, "-o", out])
    return out


# --- FILE objects (owner ruling 2026-11-11 Q6) -------------------------------------------------------------------
NAME = r'(?:"[^"]+"|[-\w.$]+)'
DEFINE = re.compile(rf'(?ms)^define ([^\n]*?)@({NAME})\((.*?)^}}\n')
ALIAS = re.compile(rf'(?m)^@({NAME}) = ([^\n]*?)\balias [^\n]*?, ptr @({NAME})\s*$')
GLOBAL = re.compile(rf'(?m)^@({NAME}) = ((?:[a-z_]+ )*?)(?:global|constant) ([^\n]*)$')
REF = re.compile(rf'@({NAME})')


def unq(n: str) -> str:
    return n[1:-1] if n.startswith('"') else n


def parse(text: str) -> tuple:
    """({function: (linkage words, referenced names)}, {alias: (linkage words, aliasee)},
    {global: (linkage words, referenced names)}) of a textual module."""
    funcs = {}
    for m in DEFINE.finditer(text):
        funcs[unq(m.group(2))] = (m.group(1), {unq(r) for r in REF.findall(m.group(3))})
    aliases = {unq(a): (w, unq(t)) for a, w, t in ALIAS.findall(text)}
    globs = {}
    for m in GLOBAL.finditer(text):
        globs[unq(m.group(1))] = (m.group(2), {unq(r) for r in REF.findall(m.group(3))})
    return funcs, aliases, globs


def header_names(musl: Path) -> set:
    """Every identifier musl's public headers (include/, recursively) write before a `(`: the names a C program can
    call. A superset of the declared functions (macros, parameters of function pointer type); it is only ever
    intersected with the module's function and alias names."""
    out = set()
    for h in sorted((musl / "include").rglob("*.h")):
        out |= set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", h.read_text(errors="replace")))
    return out


def linked_public(words: str) -> bool:
    """external linkage, not hidden"""
    w = words.split()
    return not ({"internal", "private", "hidden"} & set(w))


def file_param_functions(musl: Path, srcs: dict, pins: dict, work: Path, jobs: int) -> set:
    """Every function musl's units of the full module define with a FILE * parameter, read from clang's AST (JSON)
    of each unit whose text names FILE (no FILE parameter can be written without the token: FILE or _IO_FILE).
    The ELF triple: the AST is the same, and Darwin's front end refuses musl's aliases."""
    full, s = pins["full"], pins["sources"]["musl"]
    gen = work / "musl-obj" / "include"
    inc = includes(s, musl, srcs, gen)
    units = [u for _, u in full_units(musl, full) if "FILE" in (musl / u).read_text(errors="replace")]
    file_t = re.compile(r"\bFILE\s*\*|\bstruct _IO_FILE\s*\*")

    def one(unit):
        r = subprocess.run([str(c) for c in [LLVM_BIN / "clang", f"--target={ELF_TRIPLE}", *full["flags"], *inc,
                                              "-fsyntax-only", "-Xclang", "-ast-dump=json", unit]],
                           cwd=musl, capture_output=True, text=True)
        if r.returncode:
            raise BuildError(f"bundle: AST of {unit}: {r.stderr[-600:]}")
        names = set()
        for d in json.loads(r.stdout).get("inner", []):
            if d.get("kind") != "FunctionDecl" or not any(c.get("kind") == "CompoundStmt" for c in d.get("inner", [])):
                continue
            for p in d.get("inner", []):
                if p.get("kind") == "ParmVarDecl":
                    t = p.get("type", {})
                    if file_t.search(t.get("qualType", "")) or file_t.search(t.get("desugaredQualType", "")):
                        names.add(d["name"])
        return names

    out = set()
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
        for names in ex.map(one, units):
            out |= names
    return out


def derive_omit(text: str, file_params: set, headers: set) -> list:
    """The Q6 omission list of a full module (after the formatter renaming).

    Roots: the standard stream objects (STD_STREAMS) and the open-file list (src/stdio/ofl.c's static ofl_head,
    which __ofl_lock hands out). A function is FOREIGN if its body refers to a root, or to a foreign function or
    alias, public or internal (wprintf writes stdout through vwprintf, _flushlbf the open-file list through fflush).
    A FILE * parameter alone does not make a function foreign: vdprintf, whose FILE is on its own stack, calls
    vfprintf and keeps its body.
    Omitted: every public function (or alias) with a FILE * parameter (file_param_functions) or that is foreign;
    every foreign internal function or alias; the root objects. Public: external linkage, not hidden, and declared in
    a public header of musl (header_names): so __uflow and __overflow, which musl exports for its ABI but declares
    only in src/internal/stdio_impl.h, are internal helpers, as are __fputwc_unlocked and the like.
    The internal copies cq_formatters.py makes (__cq_vfprintf, ...) have a FILE * parameter and are internal, so
    they are kept unless foreign; so are musl's hidden helpers (__fwritex, __towrite, __uflow, __shgetc, ...)."""
    funcs, aliases, globs = parse(text)
    roots = set(STD_STREAMS) | {"ofl_head"}

    def public(n):
        return n in headers and linked_public(words.get(n, "internal"))

    def target(n):
        seen = set()
        while n in aliases and n not in seen:
            seen.add(n)
            n = aliases[n][1]
        return n

    words = {**{f: w for f, (w, _) in funcs.items()}, **{a: w for a, (w, _) in aliases.items()}}

    foreign = set()
    changed = True
    while changed:
        changed = False
        for f in sorted(funcs):
            if f in foreign:
                continue
            if any(r in roots or target(r) in roots or target(r) in foreign for r in funcs[f][1]):
                foreign.add(f)
                changed = True
    omit = set()
    for f in funcs:
        if f in foreign or (public(f) and f in file_params):
            omit.add(f)
    for a in aliases:
        t = target(a)
        if t in omit or (public(a) and (t in file_params or t in foreign)):
            omit.add(a)
    omit |= {g for g in globs if g in roots}
    omit |= {a for a in aliases if a in roots}
    return sorted(omit)


def std_refs(text: str, omit: set) -> list:
    """(kept body or object, standard stream it refers to): each one a build error."""
    funcs, aliases, globs = parse(text)
    bad = []
    for n, (_, refs) in sorted({**funcs, **globs}.items()):
        if n in omit:
            continue
        for r in sorted(refs & set(STD_STREAMS)):
            bad.append((n, r))
    for a, (_, t) in sorted(aliases.items()):
        if a not in omit and t in STD_STREAMS:
            bad.append((a, t))
    return bad


def apply_recipe(linked: Path, omit: list, work: Path, export=None, renamed=False) -> Path:
    """Steps 1 to 3 of the module docstring on `linked` (step 1 already done if `renamed`); returns the textual
    result."""
    ll = work / "step0.ll"
    if linked.suffix == ".bc":
        run([LLVM_BIN / "llvm-dis", linked, "-o", ll])
    else:
        ll = linked
    fm = work / "step1.ll"
    if renamed:
        fm = ll
    else:
        run([sys.executable, "-I", FORMATTERS, ll, fm])
    text = fm.read_text()
    funcs, aliases, globs = parse(text)
    here = [n for n in omit if n in funcs or n in aliases or n in globs]
    bad = std_refs(text, set(omit))
    if bad:
        raise BuildError("bundle: a kept body refers to a standard stream (owner ruling 2026-11-11 Q6; omit it in "
                         "bundle/recipe.json):\n" + "\n".join(f"  {n} -> {r}" for n, r in bad))
    cur = fm
    if here:
        args = []
        for n in here:
            args.append(f"--func={n}" if n in funcs else f"--alias={n}" if n in aliases else f"--glob={n}")
        nxt = work / "step2.ll"
        run([LLVM_BIN / "llvm-extract", "--delete", "-S", *args, cur, "-o", nxt])
        cur = nxt
    passes = "strip-dead-prototypes"
    extra = []
    if export is not None:
        passes = "internalize,globaldce,strip-dead-prototypes"
        extra = [f"-internalize-public-api-list={','.join(export)}"]
    nxt = work / "step3.ll"
    run([LLVM_BIN / "opt", "-S", *extra, f"-passes={passes}", cur, "-o", nxt])
    text = nxt.read_text()
    funcs, aliases, globs = parse(text)
    defined_std = sorted(n for n in STD_STREAMS if n in funcs or n in aliases or n in globs)
    declared_std = sorted(n for n in STD_STREAMS if re.search(rf"@{re.escape(n)}\b", text))
    if defined_std or declared_std:
        raise BuildError(f"bundle: standard streams remain after the omission: defined {defined_std}, "
                         f"referred to {declared_std}")
    return nxt


def closed(bc: Path, omit: list, bodiless: list) -> list:
    """Every symbol a bundle body uses is in the bundle (llvm.* intrinsics aside), is an omitted function (a host
    call, rule 16) or is bodiless by design (recipe "bodiless"). Returns the omitted names the bundle calls."""
    und = run([LLVM_BIN / "llvm-nm", "--undefined-only", "--format=just-symbols", bc]).split()
    und = [u[1:] if u.startswith("_") else u for u in und]  # Mach-O C symbols carry a leading underscore
    und = [u for u in und if not u.startswith("llvm.")]
    host = sorted(u for u in und if u in set(omit))
    rest = sorted(set(und) - set(host) - set(bodiless))
    if rest:
        raise BuildError(f"bundle: undefined symbols in the bundle: {rest}")
    return host


def main(argv) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--musl", required=True, type=Path)
    ap.add_argument("--llvm-project", type=Path)
    ap.add_argument("--full", action="store_true", help="build the full musl module (textual) instead")
    ap.add_argument("--write", action="store_true",
                    help="v1: re-pin file and output hashes; --full: rewrite recipe.json's omit list")
    ap.add_argument("--out", type=Path, help="write the result here instead of bundle/<output> (a check build)")
    ap.add_argument("--work", type=Path, help="--full: the compile cache (default: a temporary directory)")
    ap.add_argument("--jobs", type=int, default=2)
    a = ap.parse_args(argv)
    pins = json.loads(PINS.read_text())
    recipe = json.loads(RECIPE.read_text())
    srcs = {"musl": a.musl.resolve(), "cq": ROOT}
    if a.llvm_project:
        srcs["llvm-project"] = a.llvm_project.resolve()
    check_toolchain(pins["clang"])
    check_rev(srcs["musl"], pins["sources"]["musl"]["rev"], "musl")

    if a.full:
        if not a.out:
            raise BuildError("bundle: --full needs --out")
        with tempfile.TemporaryDirectory(prefix="cqlibc.") as t:
            work = (a.work or Path(t)).resolve()
            work.mkdir(parents=True, exist_ok=True)
            linked = build_full(srcs, pins, work, a.jobs)
            renamed = work / "renamed.ll"
            run([sys.executable, "-I", FORMATTERS, linked, renamed])
            omit = derive_omit(renamed.read_text(), file_param_functions(srcs["musl"], srcs, pins, work, a.jobs),
                               header_names(srcs["musl"]))
            if a.write:
                recipe["omit"] = omit
                RECIPE.write_text(json.dumps(recipe, indent=2) + "\n")
            elif omit != recipe["omit"]:
                old, new = set(recipe["omit"]), set(omit)
                raise BuildError(f"bundle: recipe.json omit differs from the derivation: missing "
                                 f"{sorted(new - old)}, extra {sorted(old - new)} (--write rewrites it)")
            out = apply_recipe(renamed, recipe["omit"], work, renamed=True)
            a.out.write_bytes(out.read_bytes())
            print(f"libc: {a.out} sha256 {sha256(a.out)}; omitted {len(omit)} names")
        return 0

    if "llvm-project" not in srcs:
        raise BuildError("bundle: the version 1 bundle needs --llvm-project")
    for name, s in pins["sources"].items():
        if "rev" in s:
            check_rev(srcs[name], s["rev"], name)
    with tempfile.TemporaryDirectory(prefix="cqbundle.") as t:
        tmp = Path(t)
        plain, linked, read = build_v1(srcs, pins, tmp)
        ll = apply_recipe(linked, recipe["omit"], tmp, export=pins["export"])
        rbc = tmp / "recipe.out.bc"
        run([LLVM_BIN / "llvm-as", ll, "-o", rbc])
        out = tmp / pins["output"]
        # the plain units first, linked from their own bitcode, so their bodies (use-list orders included) are
        # what they were before the recipe units joined
        run([LLVM_BIN / "llvm-link", *plain, rbc, "-o", out])
        stds = sorted(set(STD_STREAMS) & set(
            u[1:] if u.startswith("_") else u
            for u in run([LLVM_BIN / "llvm-nm", "--format=just-symbols", out]).split()))
        if stds:
            raise BuildError(f"bundle: the bundle names standard streams {stds}")
        host = closed(out, recipe["omit"], list(recipe["bodiless"]))
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
    print(f"bundle: {dest} sha256 {digest}; host calls (omitted, Q6): {host}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except BuildError as e:
        print(e, file=sys.stderr)
        sys.exit(1)
