#!/usr/bin/env python3
"""stubgen.py <module.ll> [more.ll ...] [--c-module name.O1.ll ...] -o stubs.ll   (cq-w0-chk-core)

Emits one LLVM IR definition per cqrt_* and cq_template_* function the input modules declare (and
do not define). Each definition stores its arguments to memory and calls

    void cqe_call(ptr site, ptr args, ptr ret)

(checker/rt/dispatch.c), then loads and returns the result. site is the symbol's call site, an internal
{ptr sym, ptr sig, i32 nargs, i32 0, ptr null}: sig is "<ret>|<t0>,<t1>,..." in LLVM type spellings, and
the runtime keeps what it parsed from the name and the signature in the last field, so a call never parses
them again (cq-9hzgh). A constructor hands the table of every site to cqe_sites(ptr table, i32 n), and
the runtime parses them all once before the batch runner's setup snapshot. Return and parameter extension attributes (signext/zeroext) are kept so a narrow
result is extended the way the declaration promises (BACKEND_ABI §0, CR §1.2).

cqrt_qram_alloc_i8 is the one runtime symbol never stubbed: the injection bundle's __cq_mem (bundle/host/cq_host.c)
calls it from host C that no stubgen run sees, so checker/rt/rt_bus.c defines it.

Rule 27 declared clones (cq-rft). Every __cq_q_* the input modules declare and do not define is a clone nothing
links: a declared (table) clone __cq_q_<fn>_<1...1>_t(handles..., i32 K) and its _t_unc, or a rule 18 clone with its
body omitted (175). A pointer scalar is a handle to an i64 rail (mask digit 1) or a classical ptr (digit 0). Its
definition is the checker's stand-in (checker/rt/cq_standin.h, the function the C oracle gives the same body-less
callee): it calls

    void cqe_standin(ptr sym, ptr sig, ptr csig, i32 nargs, ptr args, ptr ret)

where csig = "<fn>|<ret>|<t0>,<t1>,..." is the C function's own signature, read from the --c-module
files (the example's .O1.ll: the declaration of fn, rule 27's callee). fn is the clone name read right
to left (CR §1.4): the suffix words (_unc, _pure, _ctl, _t), then the mask (binary digits, or v). A clone whose fn
the C modules do not declare is left undefined (no stub: an ordinary link error, as rule 27 says for
a missing definition); one whose C signature has a non-scalar type is an error.

Clones of host functions (cq-aou6). The C oracle links a callee nothing in the program defines to the
host library when the host defines it (libc/libm: oracle.py _host_defines, ctypes.CDLL(None)) and
gives only the rest the stand-in. A declared clone whose fn the host defines is therefore defined by
calling that same host function: its stub passes a thunk (an internal function that loads the C
arguments, calls fn with its C signature and stores the result) to

    void cqe_standin_host(ptr sym, ptr sig, ptr csig, i32 nargs, ptr args, ptr ret, ptr thunk)

which walks the clone's arguments as cqe_standin does and takes fn's value from the thunk instead of
the stand-in function; the twin XORs the same value out. Such an fn with a pointer parameter is an
error (unimplemented). The C signature of fn may also come from an fp intrinsic of the C module (rule
18: llvm.<n>.f64 is the call of the libm function n, .f32 of nf, .f80 of nl), as clang -O1 writes
exp, sin, log, pow and the like.

A declaration this generator cannot express (varargs, a type outside void/iN/half/float/double/
x86_fp80/bfloat/ptr, two different signatures for one symbol) is an error: exit 1, nothing written.
"""
import argparse
import re
import sys

RUNTIME_PREFIXES = ("cqrt_", "cq_template_")
CLONE_PREFIX = "__cq_q_"
SUFFIX = re.compile(r"_(unc|ctl|pure|t)$")
MASK = re.compile(r"_([01]+|v)$")
NEVER_STUBBED = {"cqrt_qram_alloc_i8"}   # rt_bus.c defines it (module docstring)
SCALAR = re.compile(r"^(void|i[1-9][0-9]*|half|bfloat|float|double|x86_fp80|ptr)$")
KEEP_ATTRS = ("signext", "zeroext")
DECL = re.compile(r"^declare\s+(?P<pre>.*?)@(?P<q>\"?)(?P<name>[A-Za-z0-9_.$]+)(?P=q)\s*\((?P<params>[^)]*)\)")
DEFINE = re.compile(r"^define\s+[^@]*@\"?([A-Za-z0-9_.$]+)\"?\s*\(")


class StubError(Exception):
    pass


def _split_params(s):
    s = s.strip()
    if not s:
        return []
    return [p.strip() for p in s.split(",")]


def parse_decl(line):
    """(name, ret_type, ret_attrs, [(type, attrs)]) of one declare line, or None if not a runtime symbol."""
    m = DECL.match(line.strip())
    if not m or not m.group("name").startswith(RUNTIME_PREFIXES + (CLONE_PREFIX,)):
        return None
    name = m.group("name")
    pre = m.group("pre").split()
    if not pre or not SCALAR.match(pre[-1]):
        raise StubError(f"{name}: return type '{' '.join(pre)}' is not a runtime scalar type")
    ret = pre[-1]
    rattrs = [a for a in pre[:-1] if a in KEEP_ATTRS]
    params = []
    for p in _split_params(m.group("params")):
        if p == "...":
            raise StubError(f"{name}: varargs runtime declaration")
        toks = p.split()
        if not toks or not SCALAR.match(toks[0]) or toks[0] == "void":
            raise StubError(f"{name}: parameter '{p}' is not a runtime scalar type")
        params.append((toks[0], [a for a in toks[1:] if a in KEEP_ATTRS]))
    return name, ret, rattrs, params


def clone_fn(name):
    """The C function a declared clone stands for: the name read right to left (CR §1.4)."""
    rest = name[len(CLONE_PREFIX):]
    while True:
        m = SUFFIX.search(rest)
        if not m:
            break
        rest = rest[:m.start()]
    m = MASK.search(rest)
    if not m or not rest[:m.start()]:
        raise StubError(f"{name}: not a clone name (CR §1.4: no mask)")
    return rest[:m.start()]


INTRINSIC_FP = re.compile(r"^llvm\.([a-z0-9]+)\.(f32|f64|f80)$")
INTRINSIC_SFX = {"f32": "f", "f64": "", "f80": "l"}


def host_defines(fn):
    """The host defines fn (the C oracle's test, oracle.py _host_defines)."""
    import ctypes
    global _HOST
    if _HOST is None:
        _HOST = ctypes.CDLL(None)
    try:
        getattr(_HOST, fn)
        return True
    except AttributeError:
        return False


_HOST = None


C_FN = re.compile(r"^declare\s+(?P<pre>[^@]*?)@(?P<q>\"?)(?P<name>[A-Za-z0-9_.$]+)(?P=q)\s*\((?P<params>[^)]*)\)")


def c_signatures(c_texts):
    """{fn: (ret, [param types])} of every function the C modules declare without a body (a clone of a
    function with a body is the compiler's to define, never the stand-in's)."""
    sigs, intr = {}, {}
    for text in c_texts:
        for line in text.splitlines():
            m = C_FN.match(line)
            if not m:
                continue
            pre = [t for t in m.group("pre").split() if t not in ("dso_local", "local_unnamed_addr")]
            params = [p.split()[0] for p in _split_params(m.group("params")) if p.split()]
            name = m.group("name")
            im = INTRINSIC_FP.match(name)
            if im:   # rule 18: the libm function of the same name (cq-aou6); a real declaration wins
                intr.setdefault(im.group(1) + INTRINSIC_SFX[im.group(2)], (pre[-1] if pre else "", params))
                continue
            sigs[name] = (pre[-1] if pre else "", params)
    for fn, sig in intr.items():
        sigs.setdefault(fn, sig)
    return sigs


def c_sig(name, sigs):
    """csig "<fn>|<ret>|<t0>,..." for a declared clone."""
    fn = clone_fn(name)
    ret, params = sigs[fn]
    if not SCALAR.match(ret):
        raise StubError(f"{name}: {fn} returns '{ret}', not a scalar the stand-in models")
    for t in params:
        if t == "..." or not SCALAR.match(t) or t == "void":
            raise StubError(f"{name}: {fn} has a parameter '{t}' the stand-in does not model")
    return f"{fn}|{ret}|{','.join(params)}"


def collect(texts):
    decls, defined = {}, set()
    triple = layout = None
    for text in texts:
        for line in text.splitlines():
            if triple is None:
                m = re.match(r'^target triple = "(.*)"', line)
                if m:
                    triple = m.group(1)
            if layout is None:
                m = re.match(r'^target datalayout = "(.*)"', line)
                if m:
                    layout = m.group(1)
            m = DEFINE.match(line)
            if m:
                defined.add(m.group(1))
                continue
            d = parse_decl(line)
            if d is None or d[0] in NEVER_STUBBED:
                continue
            name, ret, _, params = d
            sig = (ret, tuple(t for t, _ in params))
            if name in decls:
                old = decls[name]
                if (old[1], tuple(t for t, _ in old[3])) != sig:
                    raise StubError(f"{name}: declared with two different signatures")
                continue
            decls[name] = d
    return [decls[n] for n in sorted(decls) if n not in defined], triple, layout


def _cstr(s):
    b = s.encode() + b"\0"
    return f"[{len(b)} x i8] c\"" + "".join(chr(c) if 32 <= c < 127 and c not in (34, 92) else f"\\{c:02X}" for c in b) + '"'


def emit(decls, triple, layout, csigs=None, host_fns=()):
    out = ["; Generated by checker/rt/stubgen.py (cq-w0-chk-core). Do not edit."]
    if layout:
        out.append(f'target datalayout = "{layout}"')
    if triple:
        out.append(f'target triple = "{triple}"')
    out.append("")
    out.append("declare void @cqe_call(ptr, ptr, ptr)")
    out.append("declare void @cqe_sites(ptr, i32)")
    out.append("declare void @cqe_standin(ptr, ptr, ptr, i32, ptr, ptr)")
    out.append("declare void @cqe_standin_host(ptr, ptr, ptr, i32, ptr, ptr, ptr)")
    out.append("")
    host_decls = {}
    sites = []
    for k, (name, ret, rattrs, params) in enumerate(decls):
        sig = ret + "|" + ",".join(t for t, _ in params)
        out.append(f"@.cqe.sym.{k} = private unnamed_addr constant {_cstr(name)}")
        out.append(f"@.cqe.sig.{k} = private unnamed_addr constant {_cstr(sig)}")
        clone = name.startswith(CLONE_PREFIX)
        if clone:
            out.append(f"@.cqe.csig.{k} = private unnamed_addr constant {_cstr(csigs[name])}")
        plist = ", ".join(" ".join([t] + a + [f"%a{i}"]) for i, (t, a) in enumerate(params))
        head = " ".join(rattrs + [ret])
        body = [f"define {head} @{name}({plist}) {{", "entry:"]
        n = len(params)
        body.append(f"  %args = alloca [{max(n, 1)} x ptr]")
        for i, (t, _) in enumerate(params):
            body.append(f"  %p{i} = alloca {t}")
            body.append(f"  store {t} %a{i}, ptr %p{i}")
            body.append(f"  %g{i} = getelementptr [{max(n, 1)} x ptr], ptr %args, i64 0, i64 {i}")
            body.append(f"  store ptr %p{i}, ptr %g{i}")
        rt = "i8" if ret == "void" else ret
        body.append(f"  %r = alloca {rt}")
        host = clone and host_fns and csigs[name].split("|")[0] in host_fns
        if host:
            fn, cret, cps = csigs[name].split("|")
            cps = [t for t in cps.split(",") if t]
            host_decls[fn] = f"declare {cret} @{fn}({', '.join(cps)})"
            out.extend(_thunk(k, fn, cret, cps))
            body.append(f"  call void @cqe_standin_host(ptr @.cqe.sym.{k}, ptr @.cqe.sig.{k}, ptr @.cqe.csig.{k}, "
                        f"i32 {n}, ptr %args, ptr %r, ptr @.cqe.host.{k})")
        elif clone:
            body.append(f"  call void @cqe_standin(ptr @.cqe.sym.{k}, ptr @.cqe.sig.{k}, ptr @.cqe.csig.{k}, i32 {n}, "
                        f"ptr %args, ptr %r)")
        else:
            out.append(f"@.cqe.site.{k} = internal global {{ ptr, ptr, i32, i32, ptr }} "
                       f"{{ ptr @.cqe.sym.{k}, ptr @.cqe.sig.{k}, i32 {n}, i32 0, ptr null }}")
            sites.append(k)
            body.append(f"  call void @cqe_call(ptr @.cqe.site.{k}, ptr %args, ptr %r)")
        if ret == "void":
            body.append("  ret void")
        else:
            body.append(f"  %v = load {ret}, ptr %r")
            body.append(f"  ret {ret} %v")
        body.append("}")
        out.extend(body)
        out.append("")
    out.extend(host_decls[f] for f in sorted(host_decls))
    if sites:
        out.append(f"@.cqe.sites = internal global [{len(sites)} x ptr] "
                   f"[{', '.join(f'ptr @.cqe.site.{k}' for k in sites)}]")
        out.append("define internal void @.cqe.sites.init() {")
        out.append("entry:")
        out.append(f"  call void @cqe_sites(ptr @.cqe.sites, i32 {len(sites)})")
        out.append("  ret void")
        out.append("}")
        out.append("@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] "
                   "[{ i32, ptr, ptr } { i32 65535, ptr @.cqe.sites.init, ptr null }]")
    return "\n".join(out) + "\n"


def _thunk(k, fn, cret, cps):
    """void @.cqe.host.<k>(ptr args, ptr ret): fn called on the C values args[i] points at (cq-aou6)."""
    b = [f"define internal void @.cqe.host.{k}(ptr %a, ptr %r) {{", "entry:"]
    for i, t in enumerate(cps):
        b.append(f"  %g{i} = getelementptr ptr, ptr %a, i64 {i}")
        b.append(f"  %p{i} = load ptr, ptr %g{i}")
        b.append(f"  %v{i} = load {t}, ptr %p{i}")
    call = f"call {cret} @{fn}({', '.join(f'{t} %v{i}' for i, t in enumerate(cps))})"
    if cret == "void":
        b.append(f"  {call}")
    else:
        b.append(f"  %x = {call}")
        b.append(f"  store {cret} %x, ptr %r")
    b += ["  ret void", "}", ""]
    return b


def generate(texts, c_texts=()):
    decls, triple, layout = collect(texts)
    clones = [d[0] for d in decls if d[0].startswith(CLONE_PREFIX)]
    sigs = c_signatures(c_texts) if clones else {}
    # A clone whose fn no C module declares is not stubbed: it stays undefined, an ordinary link error
    # (rule 27: "a missing one is an ordinary undefined-symbol link error").
    decls = [d for d in decls if not d[0].startswith(CLONE_PREFIX) or clone_fn(d[0]) in sigs]
    csigs = {d[0]: c_sig(d[0], sigs) for d in decls if d[0].startswith(CLONE_PREFIX)}
    host_fns = set()
    for name, cs in csigs.items():
        fn, _, cps = cs.split("|")
        if host_defines(fn):
            if "ptr" in cps.split(","):
                raise StubError(f"unimplemented: {name}: a clone of the host function {fn}, which takes a pointer")
            host_fns.add(fn)
    return emit(decls, triple, layout, csigs, host_fns), [d[0] for d in decls]


def main(argv=None):
    ap = argparse.ArgumentParser(prog="stubgen.py")
    ap.add_argument("modules", nargs="+")
    ap.add_argument("-o", dest="out", required=True)
    ap.add_argument("--c-module", action="append", default=[],
                    help="a C-level module (.O1.ll) declaring the callees of rule 27 declared clones")
    a = ap.parse_args(argv)
    try:
        texts = [open(p).read() for p in a.modules]
        text, _ = generate(texts, [open(p).read() for p in a.c_module])
    except (StubError, OSError) as e:
        print(f"cq: stubgen: {e}", file=sys.stderr)
        return 1
    with open(a.out, "w") as f:
        f.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
