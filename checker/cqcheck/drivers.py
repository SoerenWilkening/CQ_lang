"""Checker drivers (cq-w0-chk-drivers): `_tools/drivers.txt` to DriverSpec.

drivers.txt is input data (CLAUDE.md "Reading the spec"): one line per example,

    NN_name|prototypes|call;call[|setup]

where the optional fourth field is C run in `main` before the calls. The spec tooling README names
two driver objects that a call may pass without defining them, `coef` and `icoef`
(`static const double coef[4]={1,2,3,4}; static const int icoef[4]={1,2,3,4}` "when used"); the
DriverSpec's setup carries their definitions when a call references them, ahead of the line's own
setup field.

A DriverSpec has one entry in `calls` per call of the drivers.txt line, in order. An argument is
quantum when, in the example's `.O1.ll`, it flows into the first operand of a `cq_theta_*` call (by
SSA data flow, across calls, through memory a store writes and a load reads). A pointer argument is
quantum when the memory it points to flows in that way (the register array of 60_qft). The
concrete values of the drivers.txt calls are not part of DriverSpec: they are the baseline samples
of the SampleSet (sampling.py).

Handle cells (cq-rbe6). A quantum pointer argument whose drivers.txt object the setup fills with rail
handles (`int q[N]` with `q[i] = cqrt_alloc_iW(0)`, 60_qft; and cqcheck user's seeded objects) is a
memory-borne quantum input: its argument entry carries `"cells": {"w": W, "n": N}`, and its N cells
are quantum inputs sampled like any other (CLAUDE.md "Inputs"). A sample gives their values in the
pointer value, `<expr>@cells:<hex>,<hex>,...` (one W-bit pattern per cell; the bare `<expr>` is every
cell 0, the setup's own values). The driver writes them at the start of the sample, every cell in
every sample (so the circuit's structure does not depend on them): on the lowered side, where the
setup left a handle (>= 1, rt/core.c) in each cell, cell k becomes `cqrt_alloc_iW(v_k)`, a rail
holding v_k; on the C side, where the setup's `cqrt_alloc_iW(0)` left the value 0 (oracle/cqo_rt.c),
element k of the C program's view of the object, an array of the W-bit C type the alloc takes
(60's `bool *q`), becomes v_k. Cell 0 as the setup left it tells the sides apart (read at the first
sample, before any write).

The module also holds the textual `.O1.ll` reader that sampling.py builds on, and the C source of a
driver `main` (`driver_source`), which renders every sample of a SampleSet with bit-exact argument
values.
"""
from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, FrozenSet, Iterable, List, NoReturn, Optional, Sequence, Set, Tuple

from cqcheck.contracts import DriverSpec

REPO = Path(__file__).resolve().parents[2]


def spec_dir() -> Path:
    return Path(os.environ.get("CQ_SPEC_DIR", REPO.parent / "CQ_spec")).resolve()


def unimplemented(what: str) -> NoReturn:
    """An input shape this module does not handle yet: an internal error, never a decline."""
    raise RuntimeError(f"cq: unimplemented: chk-drivers: {what}")


# ------------------------------------------------------------------------------------------------
# drivers.txt
# ------------------------------------------------------------------------------------------------

# Driver objects the spec tooling README defines for calls that use them (README.txt, "drv.c").
IMPLICIT_OBJECTS = {
    "coef": "static const double coef[4]={1,2,3,4};",
    "icoef": "static const int icoef[4]={1,2,3,4};",
}


@dataclass(frozen=True)
class DriverLine:
    example: str
    protos: List[str]
    calls: List[str]
    setup: str          # the fourth field, "" when absent


def _split_top(s: str, sep: str) -> List[str]:
    """Split at `sep` outside (), [], {} and quotes."""
    out, depth, cur, q = [], 0, [], None
    for ch in s:
        if q:
            cur.append(ch)
            if ch == q:
                q = None
            continue
        if ch in "\"'":
            q = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            out.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return out


def read_drivers_txt(path: Optional[Path] = None) -> Dict[str, DriverLine]:
    path = path or spec_dir() / "_tools" / "drivers.txt"
    lines: Dict[str, DriverLine] = {}
    for raw in path.read_text().splitlines():
        if not raw.strip():
            continue
        parts = raw.split("|", 3)
        if len(parts) < 3:
            unimplemented(f"drivers.txt line with {len(parts)} fields: {raw!r}")
        name, protos, calls = parts[0], parts[1], parts[2]
        setup = parts[3] if len(parts) == 4 else ""
        if name in lines:
            unimplemented(f"drivers.txt names {name} twice")
        lines[name] = DriverLine(
            example=name,
            protos=[p.strip() + ";" for p in protos.split(";") if p.strip()],
            calls=[c.strip() for c in _split_top(calls, ";") if c.strip()],
            setup=setup.strip(),
        )
    return lines


# ------------------------------------------------------------------------------------------------
# C prototypes and calls
# ------------------------------------------------------------------------------------------------

@dataclass(frozen=True)
class CType:
    """A driver argument type: a scalar (int or fp, `bits` wide) or a pointer."""
    spelling: str
    kind: str           # 'i' integer, 'f' floating, 'p' pointer
    bits: int           # value bits: _Bool 1, char 8, ..., long double 80; pointers 64
    signed: bool = False

    @property
    def storage_bits(self) -> int:
        return 8 if self.bits == 1 else self.bits


_INT_TYPES = {
    "_Bool": (1, False), "bool": (1, False),
    "char": (8, True), "signed char": (8, True), "unsigned char": (8, False),
    "short": (16, True), "short int": (16, True), "signed short": (16, True),
    "unsigned short": (16, False), "unsigned short int": (16, False),
    "int": (32, True), "signed": (32, True), "signed int": (32, True),
    "unsigned": (32, False), "unsigned int": (32, False),
    "long": (64, True), "long int": (64, True), "signed long": (64, True),
    "unsigned long": (64, False), "unsigned long int": (64, False),
    "long long": (64, True), "long long int": (64, True), "signed long long": (64, True),
    "unsigned long long": (64, False), "unsigned long long int": (64, False),
    # not in drivers.txt; hand-written DriverSpecs (chk-core tests, usercheck) use them
    "int8_t": (8, True), "uint8_t": (8, False), "int16_t": (16, True), "uint16_t": (16, False),
    "int32_t": (32, True), "uint32_t": (32, False), "int64_t": (64, True), "uint64_t": (64, False),
    "size_t": (64, False), "ssize_t": (64, True), "ptrdiff_t": (64, True), "intptr_t": (64, True),
    "uintptr_t": (64, False), "__int128": (128, True), "unsigned __int128": (128, False),
}
_FP_TYPES = {"_Float16": 16, "float": 32, "double": 64, "long double": 80}


_CTYPES: Dict[str, CType] = {}


def parse_ctype(spelling: str) -> CType:
    """The CType of a C type spelling; parsed once per spelling (cq-bhp2: callers ask per sample)."""
    ct = _CTYPES.get(spelling)
    if ct is None:
        ct = _CTYPES[spelling] = _parse_ctype(spelling)
    return ct


def _parse_ctype(spelling: str) -> CType:
    s = " ".join(spelling.replace("*", " * ").split())
    if "*" in s:
        return CType(s.replace(" *", "*"), "p", 64)
    base = " ".join(w for w in s.split() if w not in ("const", "volatile"))
    if base in _INT_TYPES:
        bits, signed = _INT_TYPES[base]
        return CType(base, "i", bits, signed)
    if base in _FP_TYPES:
        return CType(base, "f", _FP_TYPES[base], True)
    unimplemented(f"driver argument type {spelling!r}")


@dataclass(frozen=True)
class Proto:
    ret: str
    name: str
    params: List[CType]
    text: str


_PROTO = re.compile(r"^\s*(?P<ret>.*?)\s*\b(?P<name>[A-Za-z_]\w*)\s*\((?P<params>.*)\)\s*;?\s*$")


def parse_proto(text: str) -> Proto:
    m = _PROTO.match(text)
    if not m:
        unimplemented(f"prototype {text!r}")
    params_s = m.group("params").strip()
    params: List[CType] = []
    if params_s and params_s != "void":
        params = [parse_ctype(p) for p in _split_top(params_s, ",")]
    return Proto(m.group("ret"), m.group("name"), params, text)


_CALL = re.compile(r"^\s*(?P<fn>[A-Za-z_]\w*)\s*\((?P<args>.*)\)\s*$")


def parse_call(text: str) -> Tuple[str, List[str]]:
    m = _CALL.match(text)
    if not m:
        unimplemented(f"driver call {text!r}")
    a = m.group("args").strip()
    return m.group("fn"), ([x.strip() for x in _split_top(a, ",")] if a else [])


# ------------------------------------------------------------------------------------------------
# Textual .O1.ll reader (clang -O1 output; enough for data flow, CFG and probes)
# ------------------------------------------------------------------------------------------------

_LOCAL = r'%(?:"[^"]*"|[-A-Za-z$._][-A-Za-z$._0-9]*|\d+)'
_RE_LOCAL = re.compile(_LOCAL)
_RE_GLOBAL = re.compile(r'@(?:"[^"]*"|[-A-Za-z$._][-A-Za-z$._0-9]*|\d+)')
_RE_LABEL = re.compile(r'^(?:"([^"]*)"|([-A-Za-z$._0-9]+)):(?:\s|$)')


def strip_comment(line: str) -> str:
    """Drop a trailing `; ...` comment, respecting quoted names and c"..." strings."""
    q = False
    for i, ch in enumerate(line):
        if ch == '"':
            q = not q
        elif ch == ";" and not q:
            return line[:i].rstrip()
    return line.rstrip()


def split_operands(s: str) -> List[str]:
    """Top-level comma split respecting (), [], {}, <> and quotes."""
    out, depth, cur, q = [], 0, [], False
    for ch in s:
        if ch == '"':
            q = not q
        elif not q:
            if ch in "([{<":
                depth += 1
            elif ch in ")]}>":
                depth -= 1
            elif ch == "," and depth == 0:
                out.append("".join(cur).strip())
                cur = []
                continue
        cur.append(ch)
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return out


def locals_in(s: str) -> List[str]:
    return _RE_LOCAL.findall(s)


@dataclass
class Inst:
    text: str           # without comment, without leading indentation
    dest: Optional[str]  # "%7" or None
    op: str             # opcode ("call" for tail/musttail/notail call)
    block: str          # label of the containing block ("%16")
    index: int          # position in the function body (line order)
    callee: Optional[str] = None      # "@name" for a direct call
    call_args: List[str] = field(default_factory=list)   # operand texts of a call
    operands: List[str] = field(default_factory=list)    # top-level operand texts (non-call)
    # identified type names of the module ("%struct.pair") that are no local of this function: they
    # look like locals in the text but are never SSA operands (cq-y10d)
    types: FrozenSet[str] = frozenset()

    def refs(self) -> List[str]:
        """The SSA locals the instruction reads (type names excluded)."""
        body = self.text.split("=", 1)[1] if self.dest else self.text
        return [r for r in locals_in(body) if r not in self.types]

    def successors(self) -> List[str]:
        if self.op in ("br", "switch", "indirectbr", "callbr", "invoke"):
            return re.findall(r"label\s+(" + _LOCAL + ")", self.text)
        return []

    @property
    def is_terminator(self) -> bool:
        return self.op in ("br", "switch", "ret", "unreachable", "indirectbr", "resume", "callbr", "invoke")


@dataclass
class Function:
    name: str           # "@name"
    ret: str
    params: List[Tuple[str, str]]     # (type text, "%N")
    blocks: Dict[str, List[Inst]]     # label -> instructions, in order
    order: List[str]                  # block labels in textual order
    header: str                       # the define line
    defs: Dict[str, Inst] = field(default_factory=dict)

    def insts(self) -> Iterable[Inst]:
        for b in self.order:
            yield from self.blocks[b]

    def param_index(self, v: str) -> Optional[int]:
        for i, (_, n) in enumerate(self.params):
            if n == v:
                return i
        return None

    def preds(self) -> Dict[str, List[str]]:
        p: Dict[str, List[str]] = {b: [] for b in self.order}
        for b in self.order:
            for s in self.blocks[b][-1].successors():
                p.setdefault(s, []).append(b)
        return p


@dataclass
class Module:
    path: Path
    lines: List[str]
    functions: Dict[str, Function]
    globals: Dict[str, str]           # "@g" -> its definition line
    declares: Dict[str, str]          # "@f" -> its declare line
    types: FrozenSet[str] = frozenset()   # identified type names ("%struct.pair")


def _parse_params(s: str) -> List[Tuple[str, str]]:
    out = []
    for p in split_operands(s):
        if p == "...":
            out.append(("...", ""))
            continue
        refs = locals_in(p)
        out.append((p, refs[-1] if refs else ""))
    return out


def _op_of(rhs: str) -> str:
    w = rhs.split()
    i = 0
    while i < len(w) and w[i] in ("tail", "musttail", "notail"):
        i += 1
    return w[i] if i < len(w) else ""


def _parse_call(text: str) -> Tuple[Optional[str], List[str]]:
    """The callee and argument texts of a call instruction."""
    body = text.split("=", 1)[1] if re.match(r"^" + _LOCAL + r"\s*=", text) else text
    i = body.find(" call ")
    if i < 0 and body.lstrip().startswith("call "):
        i = body.find("call ") - 1
    rest = body[i + 6:] if i >= 0 else body
    # The callee is the first @global or %local followed by '(' at depth 0 after the type.
    m = re.search(r"(@(?:\"[^\"]*\"|[-A-Za-z$._0-9]+)|" + _LOCAL + r")\(", rest)
    if not m:
        if "asm " in rest:
            m2 = rest.find("asm ")
            j = rest.find("(", rest.find('"', rest.find('"', rest.find('"', rest.find('"', m2) + 1) + 1) + 1) + 1)
            return "asm", split_operands(_balanced(rest, j)) if j >= 0 else []
        unimplemented(f"call shape {text!r}")
    callee = m.group(1)
    args = _balanced(rest, m.end() - 1)
    return (callee if callee.startswith("@") else None), split_operands(args)


def _balanced(s: str, open_at: int) -> str:
    depth = 0
    for j in range(open_at, len(s)):
        if s[j] == "(":
            depth += 1
        elif s[j] == ")":
            depth -= 1
            if depth == 0:
                return s[open_at + 1:j]
    unimplemented(f"unbalanced parentheses in {s!r}")


_RE_TYPEDEF = re.compile(r"^(" + _LOCAL + r")\s*=\s*type\b")


_MODULES: Dict[Tuple[str, int, int], Module] = {}
_MODULES_KEPT = 8


def read_module(path: Path) -> Module:
    """The parsed module at `path`, parsed once per file content (cq-wx6s: an example's module is
    read by the driver spec, the probe build, the sampler and the theta sites). Keyed by the
    resolved path, mtime and size; the most recent _MODULES_KEPT are kept. Callers never mutate a
    Module."""
    p = Path(path).resolve()
    st = p.stat()
    key = (str(p), st.st_mtime_ns, st.st_size)
    mod = _MODULES.pop(key, None)
    if mod is None:
        mod = _read_module(Path(path))
        while len(_MODULES) >= _MODULES_KEPT:
            del _MODULES[next(iter(_MODULES))]
    _MODULES[key] = mod
    return mod


def _read_module(path: Path) -> Module:
    lines = path.read_text().splitlines()
    types = frozenset(m.group(1) for m in (_RE_TYPEDEF.match(ln) for ln in lines) if m)
    functions: Dict[str, Function] = {}
    gl: Dict[str, str] = {}
    decl: Dict[str, str] = {}
    i = 0
    while i < len(lines):
        line = strip_comment(lines[i])
        if line.startswith("define "):
            m = re.search(r"(@(?:\"[^\"]*\"|[-A-Za-z$._0-9]+))\(", line)
            if not m:
                unimplemented(f"define line {line!r}")
            name = m.group(1)
            params = _parse_params(_balanced(line, m.end() - 1))
            ret = line[len("define "):m.start()].strip()
            nums = [int(n[1:]) for _, n in params if n[1:].isdigit()]
            entry = "%" + str((max(nums) + 1) if nums else 0)
            blocks: Dict[str, List[Inst]] = {entry: []}
            order = [entry]
            cur = entry
            idx = 0
            i += 1
            while i < len(lines) and not lines[i].startswith("}"):
                raw = lines[i]
                s = strip_comment(raw)
                i += 1
                # a switch spans lines: join until its case list closes
                while s.count("[") > s.count("]") and i < len(lines) and not lines[i].startswith("}"):
                    s = s + " " + strip_comment(lines[i]).strip()
                    i += 1
                if not s.strip():
                    continue
                lm = _RE_LABEL.match(s)
                if lm and not raw.startswith(" "):
                    lab = "%" + (('"' + lm.group(1) + '"') if lm.group(1) is not None else lm.group(2))
                    if blocks[cur] or cur != entry:
                        cur = lab
                        blocks[cur] = []
                        order.append(cur)
                    else:           # an explicitly labelled entry block
                        blocks.pop(entry)
                        order[0] = cur = lab
                        blocks[cur] = []
                    continue
                t = s.strip()
                dm = re.match(r"^(" + _LOCAL + r")\s*=\s*(.*)$", t)
                dest = dm.group(1) if dm else None
                rhs = dm.group(2) if dm else t
                op = _op_of(rhs)
                inst = Inst(t, dest, op, cur, idx)
                idx += 1
                if op == "call":
                    inst.callee, inst.call_args = _parse_call(t)
                else:
                    after = rhs.split(None, 1)[1] if len(rhs.split(None, 1)) > 1 else ""
                    inst.operands = split_operands(after)
                blocks[cur].append(inst)
            f = Function(name, ret, params, blocks, order, line)
            for ins in f.insts():
                if ins.dest:
                    f.defs[ins.dest] = ins
            ftypes = types - set(f.defs) - {n for _, n in params}
            for ins in f.insts():
                ins.types = ftypes
            functions[name] = f
        elif line.startswith("declare "):
            m = re.search(r"(@(?:\"[^\"]*\"|[-A-Za-z$._0-9]+))\(", line)
            if m:
                decl[m.group(1)] = line
        elif line.startswith("@"):
            m = _RE_GLOBAL.match(line)
            if m:
                gl[m.group(0)] = line
        i += 1
    return Module(path, lines, functions, gl, decl, types)


def example_dir(example: str) -> Path:
    return spec_dir() / "examples" / example


def o1_path(example: str) -> Path:
    d = example_dir(example)
    found = sorted(d.glob("*.O1.ll"))
    if len(found) != 1:
        unimplemented(f"{example}: expected one .O1.ll, found {len(found)}")
    return found[0]


# ------------------------------------------------------------------------------------------------
# Quantum arguments: what flows into a cq_theta_* first operand
# ------------------------------------------------------------------------------------------------

_POINTER_THROUGH = ("getelementptr", "bitcast", "addrspacecast")


def pointer_roots(f: Function, v: str, seen: Optional[Set[str]] = None) -> Set[str]:
    """The base values a pointer SSA value derives from (through GEP, casts, phi and select).
    A root is a parameter, an alloca, a call result, a load result or a global ("@g")."""
    seen = seen if seen is not None else set()
    if v.startswith("@"):
        return {v}
    if v in seen:
        return set()
    seen.add(v)
    d = f.defs.get(v)
    if d is None:
        return {v}          # a parameter
    if d.op in _POINTER_THROUGH:
        base = d.operands[1] if d.op == "getelementptr" else d.operands[0]
        return _operand_roots(f, base, seen)
    if d.op in ("phi", "select"):
        out: Set[str] = set()
        parts = d.operands
        if d.op == "phi":
            vals = re.findall(r"\[\s*([^,\]]+)\s*,", d.text)
        else:
            vals = [parts[1].split()[-1], parts[2].split()[-1]]
        for x in vals:
            out |= _operand_roots(f, x.strip(), seen)
        return out
    if d.op == "call" and d.callee == "@llvm.ptrmask.p0.i64":
        return _operand_roots(f, d.call_args[0], seen)
    return {v}


def _operand_roots(f: Function, text: str, seen: Set[str]) -> Set[str]:
    g = _RE_GLOBAL.findall(text)
    loc = locals_in(text)
    out: Set[str] = set()
    for x in loc[-1:]:
        out |= pointer_roots(f, x, seen)
    if not loc:
        out |= set(g)
    return out


@dataclass
class QuantumParams:
    value: Set[Tuple[str, int]] = field(default_factory=set)      # (function, param index)
    pointee: Set[Tuple[str, int]] = field(default_factory=set)
    theta_sites: int = 0
    nonarg_sources: List[str] = field(default_factory=list)       # theta inputs not from a param


def quantum_params(mod: Module, only: Optional[Tuple[str, int]] = None) -> QuantumParams:
    """Backward closure from every cq_theta_* first operand (only: from the one theta site
    (function, T1 site ordinal), cq-6m2)."""
    qp = QuantumParams()
    vneed: List[Tuple[str, str]] = []
    mneed: List[Tuple[str, str]] = []
    seen_v: Set[Tuple[str, str]] = set()
    seen_m: Set[Tuple[str, str]] = set()
    callers: Dict[str, List[Tuple[Function, Inst]]] = {}
    for f in mod.functions.values():
        for ins in f.insts():
            if ins.op == "call" and ins.callee:
                callers.setdefault(ins.callee, []).append((f, ins))
    for f in mod.functions.values():
        ordinal = 0
        for ins in f.insts():
            if ins.op == "call" and ins.callee and site_kind(ins.callee):
                ordinal += 1
            if ins.op == "call" and ins.callee and ins.callee.startswith("@cq_theta_"):
                if only is not None and (f.name, ordinal - 1) != only:
                    continue
                qp.theta_sites += 1
                for r in locals_in(ins.call_args[0]):
                    vneed.append((f.name, r))
                if not locals_in(ins.call_args[0]):
                    qp.nonarg_sources.append(f"{f.name}: constant {ins.call_args[0]}")

    def want_mem(fn: str, root: str):
        if (fn, root) not in seen_m:
            seen_m.add((fn, root))
            mneed.append((fn, root))

    while vneed or mneed:
        while vneed:
            fn, v = vneed.pop()
            if (fn, v) in seen_v:
                continue
            seen_v.add((fn, v))
            f = mod.functions[fn]
            pi = f.param_index(v)
            if pi is not None:
                qp.value.add((fn, pi))
                for (g, call) in callers.get(fn, []):
                    if pi < len(call.call_args):
                        for r in locals_in(call.call_args[pi]):
                            vneed.append((g.name, r))
                continue
            d = f.defs.get(v)
            if d is None:
                continue
            if d.op == "load":
                for root in _operand_roots(f, d.operands[1], set()):
                    want_mem(fn, root)
                continue
            if d.op == "call":
                # cq_theta_* is the identity on the basis value: only its register operand flows
                flowing = d.call_args[:1] if (d.callee or "").startswith("@cq_theta_") else d.call_args
                for a in flowing:
                    for r in locals_in(a):
                        vneed.append((fn, r))
                if d.callee in mod.functions:
                    g = mod.functions[d.callee]
                    for ins in g.insts():
                        if ins.op == "ret":
                            for r in ins.refs():
                                vneed.append((g.name, r))
                continue
            for r in d.refs():
                if r in f.defs or f.param_index(r) is not None:
                    vneed.append((fn, r))
        while mneed:
            fn, root = mneed.pop()
            if root.startswith("@"):
                for f in mod.functions.values():
                    _mem_writes(mod, f, root, vneed, want_mem, callers)
                continue
            f = mod.functions[fn]
            pi = f.param_index(root)
            if pi is not None:
                qp.pointee.add((fn, pi))
                for (g, call) in callers.get(fn, []):
                    if pi < len(call.call_args):
                        for r in _operand_roots(g, call.call_args[pi], set()):
                            want_mem(g.name, r)
            _mem_writes(mod, f, root, vneed, want_mem, callers)
            d = f.defs.get(root)
            if d is not None and d.op == "load":
                # a pointer read from memory: the memory that holds it is what flows
                for r2 in _operand_roots(f, d.operands[1], set()):
                    want_mem(fn, r2)
    return qp


# ------------------------------------------------------------------------------------------------
# cq_theta sites (cq-6m2, cq-arch Z4): what a sample's "subst" substitutes
# ------------------------------------------------------------------------------------------------

def site_kind(callee: str) -> Optional[str]:
    """The T1.1 site kind of a callee ("@name"), or None: the calls T1 numbers."""
    n = callee[1:] if callee.startswith("@") else callee
    if n.startswith("cq_theta_"):
        return "theta"
    if n.startswith("cq_measure_"):
        return "measure"
    if n == "cq_phi":
        return "phi"
    if n in ("__cq_invert_begin", "__cq_invert_end"):
        return n[len("__cq_"):]
    return None


# cq_theta_<suffix> (CQ.h) -> the register's width token
THETA_RAIL = {"i1": "i1", "c": "i8", "si8": "i8", "ui8": "i8", "si16": "i16", "ui16": "i16",
              "si32": "i32", "ui32": "i32", "sl": "i64", "ul": "i64", "sll": "i64", "ull": "i64",
              "f16": "f16", "bf16": "bf16", "f32": "f32", "f64": "f64", "f80": "f80"}


@dataclass
class ThetaSite:
    fn: str                    # IR name without "@" (T1.1 "fn")
    site: int                  # T1.1 ordinal among fn's site calls
    w: str                     # register width token (i1, i8, ..., f80)
    params: Set[Tuple[str, int]]    # (function "@f", index): scalar parameters its register derives from

    def key(self) -> str:
        return f"{self.fn}:{self.site}"

    @property
    def ctype(self) -> CType:
        """The C type sampling draws its value in (storage width = the register width)."""
        return parse_ctype({"i1": "_Bool", "i8": "signed char", "i16": "short",
                            "i32": "int", "i64": "long long", "f16": "_Float16",
                            "bf16": "unsigned short", "f32": "float", "f64": "double",
                            "f80": "long double"}[self.w])


def theta_site_widths(o1: Path) -> Dict[str, str]:
    """cq-arch Z4: "<fn>:<site>" (T1.1) -> the register width token of every cq_theta_* site of the
    .O1.ll at o1 (the evaluator's theta schedule names the width of each reach, run.py)."""
    return {st.key(): st.w for st in theta_sites(read_module(Path(o1)), closure=False)}


def theta_sites(mod: Module, closure: bool = True) -> List[ThetaSite]:
    """Every cq_theta_* call of the module, in function and textual order, with its T1.1 site key
    and the scalar parameters its register operand derives from (quantum_params' closure; empty
    when closure is False)."""
    out = []
    for f in mod.functions.values():
        ordinal = 0
        for ins in f.insts():
            if not (ins.op == "call" and ins.callee and site_kind(ins.callee)):
                continue
            ordinal += 1
            if not ins.callee.startswith("@cq_theta_"):
                continue
            suffix = ins.callee[len("@cq_theta_"):]
            if suffix not in THETA_RAIL:
                unimplemented(f"{f.name}: theta call {ins.text!r}: register type of {ins.callee}")
            name = f.name[1:]
            if name.startswith('"'):
                name = name[1:-1]
            params = set(quantum_params(mod, (f.name, ordinal - 1)).value) if closure else set()
            out.append(ThetaSite(name, ordinal - 1, THETA_RAIL[suffix], params))
    return out


def reachable_functions(mod: Module, entry: str) -> Set[str]:
    """Functions ("@f") reachable from entry by direct calls (entry included)."""
    seen, work = set(), [entry]
    while work:
        fn = work.pop()
        if fn in seen or fn not in mod.functions:
            continue
        seen.add(fn)
        for ins in mod.functions[fn].insts():
            if ins.op == "call" and ins.callee in mod.functions:
                work.append(ins.callee)
            for g in _RE_GLOBAL.findall(ins.text):    # a function whose address is taken
                if g in mod.functions and g != ins.callee:
                    work.append(g)
    return seen


def substituted_sites(mod: Module, spec: DriverSpec, call: int) -> List[ThetaSite]:
    """The theta sites a sample of driver call `call` substitutes (cq-6m2, cq-lvkq): every site
    reachable from the call's function (CR §6 item 1: each cq_theta input replaced by a chosen bit
    pattern)."""
    # cq-lvkq (amends cq-arch Z4): every reachable site, those fed by a varied argument too. CR §6
    # item 1 replaces each cq_theta input by a chosen bit pattern; without it, a site whose input
    # is an argument has the same value before and after its Ry, so a computation moved across the
    # Ry goes unseen (02 with its Ry after the add passed).
    c = spec.calls[call]
    fn = "@" + c["fn"]
    reach = reachable_functions(mod, fn)
    out = []
    for st in theta_sites(mod):
        f = "@" + (st.fn if re.fullmatch(r"[-A-Za-z$._0-9]+", st.fn) else '"' + st.fn + '"')
        if f in reach:
            out.append(st)
    return out


def _mem_writes(mod: Module, f: Function, root: str, vneed, want_mem, callers) -> None:
    """Everything in f that writes memory rooted at `root` adds a need."""
    def rooted(text: str) -> bool:
        return root in _operand_roots(f, text, set())
    for ins in f.insts():
        if ins.op == "store":
            if rooted(ins.operands[1]):
                for r in locals_in(ins.operands[0]):
                    vneed.append((f.name, r))
        elif ins.op == "call" and ins.callee:
            c = ins.callee
            if c.startswith("@llvm.memcpy") or c.startswith("@llvm.memmove"):
                if rooted(ins.call_args[0]):
                    for r in _operand_roots(f, ins.call_args[1], set()):
                        want_mem(f.name, r)
            elif c.startswith("@llvm.memset"):
                if rooted(ins.call_args[0]):
                    for r in locals_in(ins.call_args[1]):
                        vneed.append((f.name, r))
            elif c in mod.functions:
                for j, a in enumerate(ins.call_args):
                    if locals_in(a) or _RE_GLOBAL.findall(a):
                        if rooted(a):
                            # the callee may write through its parameter j
                            g = mod.functions[c]
                            if j < len(g.params) and g.params[j][1]:
                                want_mem(g.name, g.params[j][1])
            # a call with no body (realloc, a declared function) writes nothing that flows here
    return None


_VALUE_OPS = {"add", "sub", "mul", "udiv", "sdiv", "urem", "srem", "shl", "lshr", "ashr", "and", "or",
              "xor", "fadd", "fsub", "fmul", "fdiv", "frem", "fneg", "trunc", "zext", "sext", "fptrunc",
              "fpext", "fptoui", "fptosi", "uitofp", "sitofp", "bitcast", "freeze", "phi", "select",
              "insertvalue", "extractvalue", "insertelement", "extractelement", "shufflevector"}


def only_into_theta(mod: Module, fn: str, param: int) -> Tuple[bool, str]:
    """Whether a parameter's value reaches nothing but cq_theta_* register operands: through value
    operations, local memory (a store to an alloca and the loads of it) and calls with a body.
    The first other use found is returned as the reason (a classical use: a branch, a bound, a size,
    an index, a measurement, a call with no body, a return)."""
    seen: Set[Tuple[str, str]] = set()
    work = [(fn, mod.functions[fn].params[param][1])]
    users_cache: Dict[str, Dict[str, List[Inst]]] = {}

    def users(f: Function) -> Dict[str, List[Inst]]:
        if f.name not in users_cache:
            u: Dict[str, List[Inst]] = {}
            for ins in f.insts():
                for r in set(ins.refs()):
                    u.setdefault(r, []).append(ins)
            users_cache[f.name] = u
        return users_cache[f.name]

    while work:
        fname, v = work.pop()
        if (fname, v) in seen:
            continue
        seen.add((fname, v))
        f = mod.functions[fname]
        for u in users(f).get(v, []):
            where = f"{fname}: {u.text}"
            if u.op == "call":
                c = u.callee or ""
                idx = [i for i, a in enumerate(u.call_args) if v in locals_in(a)]
                if c.startswith("@cq_theta_"):
                    if idx != [0]:
                        return False, where
                    continue
                if c.startswith("@cq_measure_"):
                    continue                     # the register is measured unrotated on this path
                if c in mod.functions and not c.startswith("@cq_"):
                    g = mod.functions[c]
                    for i in idx:
                        if i >= len(g.params) or not g.params[i][1]:
                            return False, where
                        work.append((g.name, g.params[i][1]))
                    if u.dest:
                        pass        # the result flows only if the callee returns the value; followed via ret
                    continue
                return False, where
            if u.op == "ret":
                for (g, call) in _callers_of(mod, fname):
                    if call.dest:
                        work.append((g.name, call.dest))
                continue
            if u.op == "store":
                if v in locals_in(u.operands[1]):
                    return False, where          # used as an address
                places = _local_places(mod, f, _operand_roots(f, u.operands[1], set()))
                if places is None:
                    return False, where
                for (g, roots) in places:
                    bad = _local_memory_reads(mod, g, roots, work)
                    if bad:
                        return False, bad
                continue
            if u.op in _VALUE_OPS and u.dest:
                if u.op == "select" and v in locals_in(u.operands[0]):
                    return False, where          # the condition of a select
                work.append((fname, u.dest))
                continue
            return False, where
    return True, ""


def _local_places(mod: Module, f: Function, roots: Set[str], depth: int = 0):
    """The allocas a set of pointer roots denotes: allocas of f, or, for a parameter, the allocas
    every caller passes. None when some root is not local memory (a global, the heap, an entry
    parameter, a loaded pointer)."""
    if not roots or depth > 8:
        return None
    out = []
    for r in roots:
        d = f.defs.get(r)
        if d is not None and d.op == "alloca":
            out.append((f, {r}))
            continue
        pi = f.param_index(r) if d is None else None
        if pi is None:
            return None
        callers = _callers_of(mod, f.name)
        if not callers:
            return None
        for (g, call) in callers:
            sub = _local_places(mod, g, _operand_roots(g, call.call_args[pi], set()), depth + 1)
            if sub is None:
                return None
            out += sub
    return out


def _local_memory_reads(mod: Module, f: Function, roots: Set[str], work: list,
                        seen: Optional[Set[Tuple[str, str]]] = None) -> str:
    """Queue every load of local memory rooted at `roots` (in f, and in the callees it is passed
    to). Returns the first use that lets the memory escape, or ""."""
    seen = seen if seen is not None else set()
    for ins in f.insts():
        if ins.op == "load" and _operand_roots(f, ins.operands[1], set()) & roots and ins.dest:
            work.append((f.name, ins.dest))
        elif ins.op == "call" and ins.callee:
            for j, a in enumerate(ins.call_args):
                if not (locals_in(a) and _operand_roots(f, a, set()) & roots):
                    continue
                c = ins.callee
                if c.startswith("@llvm.lifetime") or c.startswith("@cq_"):
                    continue
                if c not in mod.functions:
                    return f"{f.name}: {ins.text}"
                g = mod.functions[c]
                if j >= len(g.params) or not g.params[j][1]:
                    return f"{f.name}: {ins.text}"
                key = (g.name, g.params[j][1])
                if key not in seen:
                    seen.add(key)
                    bad = _local_memory_reads(mod, g, {g.params[j][1]}, work, seen)
                    if bad:
                        return bad
    return ""


def _callers_of(mod: Module, fname: str) -> List[Tuple[Function, Inst]]:
    out = []
    for g in mod.functions.values():
        for ins in g.insts():
            if ins.op == "call" and ins.callee == fname:
                out.append((g, ins))
    return out


# ------------------------------------------------------------------------------------------------
# DriverSpec
# ------------------------------------------------------------------------------------------------

def _ident_of(expr: str) -> Optional[str]:
    e = expr.strip()
    if e.startswith("&"):
        e = e[1:].strip()
    return e if re.fullmatch(r"[A-Za-z_]\w*", e) else None


CELL_CTYPES = {1: "_Bool", 8: "signed char", 16: "short", 32: "int"}   # cqrt_alloc_i<W>'s parameter
CELLS_SEP = "@cells:"


def handle_cells(setup: str, expr: str) -> Optional[Dict[str, int]]:
    """{"w", "n"} when the setup fills the object `expr` names with rail handles (an `int X[N]` whose
    cells are assigned `cqrt_alloc_iW(0)`), else None."""
    ident = _ident_of(expr)
    if ident is None or not expr.strip() == ident:
        return None
    al = re.findall(r"\b" + re.escape(ident) + r"\s*\[[^\]]*\]\s*=\s*cqrt_alloc_i(\d+)\s*\(([^)]*)\)", setup)
    if not al:
        return None
    decl = re.search(r"\bint\s+" + re.escape(ident) + r"\s*\[\s*(\d+)\s*\]", setup)
    ws = {int(w) for w, _ in al}
    if decl is None or len(ws) != 1 or any(v.strip() != "0" for _, v in al) or next(iter(ws)) not in CELL_CTYPES:
        unimplemented(f"driver object {ident}: handle cells other than `int {ident}[N]` filled with "
                      f"cqrt_alloc_i<W>(0) of one W in 1, 8, 16, 32 (setup {setup!r})")
    return {"w": next(iter(ws)), "n": int(decl.group(1))}


def cell_ctype(cells: Dict[str, int]) -> "CType":
    return parse_ctype(CELL_CTYPES[cells["w"]])


def split_ptr(v: str) -> Tuple[str, Optional[List[str]]]:
    """(the C expression, the cell values or None) of a pointer sample value."""
    if CELLS_SEP in v:
        e, vals = v.split(CELLS_SEP, 1)
        return e, vals.split(",")
    return v, None


def ptr_with_cells(expr: str, vals: Sequence[str]) -> str:
    return expr + CELLS_SEP + ",".join(vals)


def build_driver_spec(line: DriverLine, mod: Optional[Module] = None) -> DriverSpec:
    mod = mod or read_module(o1_path(line.example))
    protos = {p.name: p for p in (parse_proto(t) for t in line.protos)}
    qp = quantum_params(mod)
    implicit = []
    calls = []
    for c in line.calls:
        fn, args = parse_call(c)
        if fn not in protos:
            unimplemented(f"{line.example}: call {c!r} has no prototype")
        pr = protos[fn]
        if len(args) != len(pr.params):
            unimplemented(f"{line.example}: call {c!r} has {len(args)} arguments, prototype {len(pr.params)}")
        irf = mod.functions.get("@" + fn)
        if irf is None:
            unimplemented(f"{line.example}: {fn} has no definition in the .O1.ll")
        if len(irf.params) != len(pr.params):
            unimplemented(f"{line.example}: {fn}: IR has {len(irf.params)} parameters, prototype {len(pr.params)}")
        cargs = []
        for i, (ct, a) in enumerate(zip(pr.params, args)):
            if ct.kind == "p":
                q = ("@" + fn, i) in qp.pointee
            else:
                q = ("@" + fn, i) in qp.value and only_into_theta(mod, "@" + fn, i)[0]
            cargs.append({"ctype": ct.spelling, "quantum": bool(q)})
            cells = handle_cells(line.setup, a) if ct.kind == "p" else None
            if cells is not None:     # rails, whether or not a cq_theta rotates them: quantum
                cargs[-1].update(quantum=True, cells=cells)
            ident = _ident_of(a)
            if ct.kind == "p" and ident in IMPLICIT_OBJECTS and ident not in implicit \
                    and not re.search(r"\b" + ident + r"\b", line.setup):
                implicit.append(ident)
        calls.append({"fn": fn, "args": cargs})
    setup = " ".join([IMPLICIT_OBJECTS[o] for o in implicit] + ([line.setup] if line.setup else []))
    return DriverSpec(example=line.example, protos=list(line.protos), setup=setup, calls=calls)


def driver_spec(example: str, example_dir: Path) -> DriverSpec:
    """The DriverSpec of one example (cq-zew). drivers.txt is read from the CQ_spec checkout that
    holds `example_dir` (`<spec>/examples/<example>`)."""
    example_dir = Path(example_dir)
    lines = read_drivers_txt(example_dir.resolve().parent.parent / "_tools" / "drivers.txt")
    if example not in lines:
        unimplemented(f"{example} has no drivers.txt line")
    found = sorted(example_dir.glob("*.O1.ll"))
    if len(found) != 1:
        unimplemented(f"{example}: expected one .O1.ll in {example_dir}, found {len(found)}")
    return build_driver_spec(lines[example], read_module(found[0]))


def driver_specs(examples: Optional[Sequence[str]] = None) -> Dict[str, DriverSpec]:
    lines = read_drivers_txt()
    names = sorted(lines, key=lambda n: int(n.split("_", 1)[0])) if examples is None else list(examples)
    out = {}
    for n in names:
        if n not in lines:
            unimplemented(f"{n} has no drivers.txt line")
        out[n] = build_driver_spec(lines[n])
    return out


def all_examples() -> List[str]:
    """Every example directory of the pinned CQ_spec (counted from the directory)."""
    return sorted((p.name for p in (spec_dir() / "examples").iterdir() if p.is_dir()),
                  key=lambda n: int(n.split("_", 1)[0]))


# ------------------------------------------------------------------------------------------------
# Driver source: render samples as C
# ------------------------------------------------------------------------------------------------

def baseline_values(line: DriverLine, spec: DriverSpec) -> List[List[str]]:
    """The drivers.txt call arguments as sample values (sampling.encode)."""
    from cqcheck import sampling
    out = []
    for c, call in zip(line.calls, spec.calls):
        _, args = parse_call(c)
        out.append([sampling.encode_c_literal(parse_ctype(a["ctype"]), txt)
                    for a, txt in zip(call["args"], args)])
    return out


_HEX = re.compile(r"0x[0-9a-fA-F]+")


def _scalar_bits(ct: CType, v) -> int:
    """The bit pattern of scalar sample value `v` (sampling encoding: "0x" + hex digits)."""
    if not isinstance(v, str) or not _HEX.fullmatch(v):
        unimplemented(f"sample value {v!r} for {ct.spelling}")
    return int(v, 16)


def c_value(ct: CType, v: str) -> str:
    """A C expression with the exact bit pattern of sample value `v` (sampling encoding)."""
    if ct.kind == "p":
        return v
    n = _scalar_bits(ct, v)
    if ct.kind == "i":
        if ct.bits == 1:
            return "(_Bool)" + str(n & 1)
        if ct.bits > 64:
            n &= (1 << ct.bits) - 1
            return f"(((({ct.spelling})0x{n >> 64:x}ULL) << 64) | ({ct.spelling})0x{n & ((1 << 64) - 1):x}ULL)"
        return f"(({ct.spelling})0x{n:x}ULL)"
    if ct.bits == 16:
        return f"cqd_f16(0x{n & 0xffff:04x}u)"
    if ct.bits == 32:
        return f"cqd_f32(0x{n:08x}u)"
    if ct.bits == 64:
        return f"cqd_f64(0x{n:016x}ULL)"
    return f"cqd_f80(0x{n & ((1 << 64) - 1):016x}ULL, 0x{n >> 64:04x}u)"


DRIVER_PRELUDE = r"""
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
static inline _Float16 cqd_f16(uint16_t b) { _Float16 f; memcpy(&f, &b, 2); return f; }
static inline float cqd_f32(uint32_t b) { float f; memcpy(&f, &b, 4); return f; }
static inline double cqd_f64(uint64_t b) { double f; memcpy(&f, &b, 8); return f; }
static inline long double cqd_f80(uint64_t m, uint16_t e) {
    long double f = 0; memcpy(&f, &m, 8); memcpy((char *)&f + 8, &e, 2); return f; }
"""

# ------------------------------------------------------------------------------------------------
# The run-time sample file (cq-arch Z2, cq-7lrz)
#
# driver_source emits a driver that reads its samples when it runs, from the file named by the
# environment variable CQD_SAMPLES, so one build of an example serves every sample. The file is
# sample_file(spec, samples): one record per sample, one line per record, fields separated by one
# space:
#
#     <call> <arg> <arg> ...
#
# <call> is the decimal index into spec.calls; one <arg> per argument of that call: a scalar is its
# sample value's bit pattern as "0x" + lowercase hex digits (the value c_value renders, at most 128
# bits); a pointer is "p" + the hex of the UTF-8 bytes of its C expression, which must be one the
# driver was rendered with, followed, for an argument with handle cells, by one "0x" token per cell
# (its value; 0 for a pointer value without cells). Record k (0-based, in file order) runs with
# CQD_SAMPLE = k.
# ------------------------------------------------------------------------------------------------

SAMPLES_ENV = "CQD_SAMPLES"


def _ptr_token(expr: str) -> str:
    return "p" + expr.encode().hex()


def _call_ctypes(spec: DriverSpec, sample: dict) -> Tuple[int, List[CType]]:
    ci = sample.get("call")
    if not isinstance(ci, int) or isinstance(ci, bool) or not 0 <= ci < len(spec.calls):
        unimplemented(f"sample {sample!r}: call is not an index into the {len(spec.calls)} driver calls")
    cts = [parse_ctype(a["ctype"]) for a in spec.calls[ci]["args"]]
    if len(sample.get("args", ())) != len(cts):
        unimplemented(f"sample {sample!r}: call {ci} takes {len(cts)} arguments")
    return ci, cts


def sample_record(spec: DriverSpec, sample: dict) -> str:
    """The sample file line of one sample (without the newline)."""
    ci, cts = _call_ctypes(spec, sample)
    return _record(ci, cts, sample["args"], spec.calls[ci]["args"])


def _record(ci: int, cts: Sequence[CType], args: Sequence, cargs: Sequence[dict] = ()) -> str:
    """A pointer with handle cells is its expression's token followed by one 0x token per cell."""
    toks = [str(ci)]
    for ai, (ct, v) in enumerate(zip(cts, args)):
        if ct.kind == "p":
            if not isinstance(v, str) or not v.strip():
                unimplemented(f"pointer sample value {v!r}: a C expression")
            expr, vals = split_ptr(v)
            cells = cargs[ai].get("cells") if ai < len(cargs) else None
            toks.append(_ptr_token(expr))
            if cells is None:
                if vals is not None:
                    unimplemented(f"pointer sample value {v!r}: cell values for an argument with no handle cells")
                continue
            vals = vals if vals is not None else ["0x0"] * cells["n"]
            if len(vals) != cells["n"]:
                unimplemented(f"pointer sample value {v!r}: {cells['n']} cell values")
            m = (1 << cells["w"]) - 1
            toks += [f"0x{_scalar_bits(cell_ctype(cells), x) & m:x}" for x in vals]
        else:
            n = _scalar_bits(ct, v)
            if n >> 128:
                unimplemented(f"sample value {v!r} for {ct.spelling}: wider than 128 bits")
            toks.append(f"0x{n:x}")
    return " ".join(toks)


def sample_file(spec: DriverSpec, samples: Sequence[dict]) -> str:
    """The run-time sample file of `samples`, in order: what the driver reads from $CQD_SAMPLES.
    The argument types of each call are looked up once per file, not per sample (cq-bhp2)."""
    per_call: Dict[int, List[CType]] = {}
    out = []
    for s in samples:
        ci = s.get("call")
        cts = per_call.get(ci) if type(ci) is int else None
        if cts is None:
            ci, cts = _call_ctypes(spec, s)
            per_call[ci] = cts
        elif len(s.get("args", ())) != len(cts):
            unimplemented(f"sample {s!r}: call {ci} takes {len(cts)} arguments")
        out.append(_record(ci, cts, s["args"], spec.calls[ci]["args"]))
        out.append("\n")
    return "".join(out)


_DRIVERS_TXT: Dict[Tuple[str, int], Dict[str, DriverLine]] = {}


def _drivers_txt_lines() -> Dict[str, DriverLine]:
    path = spec_dir() / "_tools" / "drivers.txt"
    if not path.exists():
        return {}
    k = (str(path), path.stat().st_mtime_ns)
    if k not in _DRIVERS_TXT:
        _DRIVERS_TXT[k] = read_drivers_txt(path)
    return _DRIVERS_TXT[k]


def _pointer_exprs(spec: DriverSpec, samples: Sequence[dict]) -> Dict[Tuple[int, int], List[str]]:
    """(call, arg) -> the C expressions a pointer argument may take: those of the samples, and, when
    spec is a drivers.txt example, those of its line (sampling never varies a pointer, so a driver
    rendered from any subset of an example's samples is the same driver)."""
    out: Dict[Tuple[int, int], Set[str]] = {}
    for s in samples:
        ci, cts = _call_ctypes(spec, s)
        for ai, (ct, v) in enumerate(zip(cts, s["args"])):
            if ct.kind == "p":
                out.setdefault((ci, ai), set()).add(split_ptr(v)[0])
    line = _drivers_txt_lines().get(spec.example)
    if line is not None and [parse_call(c)[0] for c in line.calls] == [c["fn"] for c in spec.calls]:
        for ci, (ctext, call) in enumerate(zip(line.calls, spec.calls)):
            args = parse_call(ctext)[1]
            if len(args) != len(call["args"]):
                continue
            for ai, (a, txt) in enumerate(zip(call["args"], args)):
                if parse_ctype(a["ctype"]).kind == "p":
                    out.setdefault((ci, ai), set()).add(txt)
    return {k: sorted(v) for k, v in out.items()}


def _ret_type(spec: DriverSpec, fn: str) -> Tuple[str, str, int]:
    """(C spelling, rail type, value bits) of fn's return: rail type '' for void, a pointer or an
    aggregate (bits 0); 'i<N>' for an integer, 'f<N>' for an fp type."""
    for p in spec.protos:
        for part in _split_top(p, ";"):
            m = _PROTO.match(part) if part.strip() else None
            if m and m.group("name") == fn:
                ret = " ".join(w for w in m.group("ret").split()
                               if w not in ("static", "inline", "extern", "const", "volatile"))
                if ret == "void" or "*" in ret:
                    return ret, "", 0
                if ret in _INT_TYPES:
                    return ret, f"i{_INT_TYPES[ret][0]}", _INT_TYPES[ret][0]
                if ret in _FP_TYPES:
                    return ret, f"f{_FP_TYPES[ret]}", _FP_TYPES[ret]
                return ret, "agg", 0
    unimplemented(f"{spec.example}: no prototype for {fn}")


_READER_PRELUDE = r"""
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#ifndef CQD_RESULT
#define CQD_RESULT(call, fn, w, p, n, bits) ((void)0)
#endif
#define CQD_BAD(why) do { fprintf(stderr, "cqd: sample %d: %s\n", cqd_idx, why); _exit(3); } while (0)
#define CQD_TOK() do { cqd_t = strtok_r(0, " ", &cqd_sv); if (!cqd_t) CQD_BAD("too few arguments"); } while (0)
#define CQD_HEX() do { \
    CQD_TOK(); \
    if (cqd_t[0] != '0' || cqd_t[1] != 'x') CQD_BAD("a scalar is 0x<hex>"); \
    size_t cqd_len = strlen(cqd_t + 2); char *cqd_e = 0; \
    if (cqd_len == 0 || cqd_len > 32) CQD_BAD("a scalar has 1 to 32 hex digits"); \
    cqd_w[0] = cqd_w[1] = 0; \
    if (cqd_len > 16) { \
        cqd_w[0] = strtoull(cqd_t + cqd_len - 14, &cqd_e, 16); if (*cqd_e) CQD_BAD("bad hex digit"); \
        cqd_t[cqd_len - 14] = 0; \
    } \
    cqd_w[cqd_len > 16] = strtoull(cqd_t + 2, &cqd_e, 16); if (*cqd_e) CQD_BAD("bad hex digit"); \
} while (0)
#define CQD_SCALAR(v, nbytes) do { CQD_HEX(); memset(&(v), 0, sizeof(v)); memcpy(&(v), cqd_w, nbytes); } while (0)
#define CQD_BOOL(v) do { CQD_HEX(); (v) = (_Bool)(cqd_w[0] & 1); } while (0)
"""


def _cells_helper(w: int) -> str:
    """The driver's writer of one sample's handle cells (module docstring, cq-rbe6)."""
    ct = CELL_CTYPES[w]
    nb = max(1, w // 8)
    m = (1 << w) - 1
    return (f"int cqrt_alloc_i{w}({ct});\n"
            f"static void cqd_cells_i{w}(void *p, int n, const unsigned long long *v) {{\n"
            f"    int32_t *h = (int32_t *)p;\n"
            f"    static int rails = -1;   /* decided on the post-setup state, before any sample writes */\n"
            f"    if (rails < 0) rails = h[0] != 0;\n"
            f"    if (rails) {{   /* handles (>= 1): the lowered side */\n"
            f"        for (int k = 0; k < n; k++) h[k] = cqrt_alloc_i{w}(({ct})(v[k] & 0x{m:x}ULL));\n"
            f"    }} else {{          /* the setup's cqrt_alloc_i{w}(0) as the value 0: the C side's {ct} view */\n"
            f"        for (int k = 0; k < n; k++) {{ unsigned long long x = v[k] & 0x{m:x}ULL; "
            f"memcpy((char *)p + (size_t)k * {nb}, &x, {nb}); }}\n"
            f"    }}\n}}")


def driver_source(spec: DriverSpec, samples: Sequence[dict], *, before_call: str = "",
                  after_call: str = "", main_name: str = "main") -> str:
    """A C driver (cq-arch Z2): `int <main_name>(void)` runs the setup once, then reads the sample
    file named by $CQD_SAMPLES (sample_file) and makes one call per record, in order. Scalar
    arguments are the records' bit patterns (bit-identical to c_value); a pointer argument is one of
    the expressions of `samples` (and of the example's drivers.txt line), so the source does not
    depend on scalar values: one build serves every sample.

    `before_call` and `after_call` are C statements around each call with `CQD_SAMPLE` (the record
    index) in scope. After a call whose result is an integer, fp or aggregate value, the driver
    evaluates `CQD_RESULT(call, fn, w, p, n, bits)`: call index, function name, rail type ("i<N>",
    "f<N>", or "agg"), a pointer to the result, sizeof the result, and its value bits (0 for an
    aggregate). It is a macro a consumer may define ahead of the source; by default it does nothing.
    A malformed record, or a pointer expression the driver was not rendered with, prints
    "cqd: sample <k>: <why>" on stderr and ends the process with _exit(3)."""
    ptrs = _pointer_exprs(spec, samples)
    out = [DRIVER_PRELUDE, _READER_PRELUDE]
    out += [p.strip().rstrip(";") + ";" for p in spec.protos if p.strip()]
    for w in sorted({a["cells"]["w"] for c in spec.calls for a in c["args"] if a.get("cells")}):
        out.append(_cells_helper(w))
    out.append(f"int {main_name}(void) {{")
    out.append("    " + spec.setup)
    out.append(f'    const char *cqd_path = getenv("{SAMPLES_ENV}");')
    out.append('    FILE *cqd_f = cqd_path ? fopen(cqd_path, "rb") : 0;')
    out.append('    int cqd_idx = -1;')
    out.append('    if (!cqd_f) CQD_BAD("cannot open the sample file $' + SAMPLES_ENV + '");')
    out.append("    fseek(cqd_f, 0, SEEK_END); long cqd_size = ftell(cqd_f); fseek(cqd_f, 0, SEEK_SET);")
    out.append("    char *cqd_buf = malloc((size_t)cqd_size + 1);")
    out.append('    if (!cqd_buf || fread(cqd_buf, 1, (size_t)cqd_size, cqd_f) != (size_t)cqd_size) '
               'CQD_BAD("cannot read the sample file");')
    out.append("    fclose(cqd_f); cqd_buf[cqd_size] = 0;")
    out.append("    unsigned long long cqd_w[2]; char *cqd_t, *cqd_sv, *cqd_next;")
    out.append("    for (char *cqd_p = cqd_buf; *cqd_p; cqd_p = cqd_next) {")
    out.append("        char *cqd_nl = strchr(cqd_p, '\\n');")
    out.append("        if (cqd_nl) { *cqd_nl = 0; cqd_next = cqd_nl + 1; } else cqd_next = cqd_p + strlen(cqd_p);")
    out.append("        cqd_idx++;")
    out.append("        cqd_sv = 0; cqd_t = strtok_r(cqd_p, \" \", &cqd_sv);")
    out.append('        if (!cqd_t) CQD_BAD("an empty record");')
    out.append("        char *cqd_ce = 0; long cqd_call = strtol(cqd_t, &cqd_ce, 10);")
    out.append('        if (*cqd_ce) CQD_BAD("the call is a decimal index");')
    out.append("        switch (cqd_call) {")
    for ci, call in enumerate(spec.calls):
        fn = call["fn"]
        out.append(f"        case {ci}: {{")
        names = []
        cellw: List[str] = []
        for ai, a in enumerate(call["args"]):
            ct = parse_ctype(a["ctype"])
            nm = f"cqd_a{ai}"
            names.append(nm)
            if ct.kind == "p":
                out.append(f"            {ct.spelling} {nm} = 0; CQD_TOK();")
                conds = [f'if (!strcmp(cqd_t, "{_ptr_token(e)}")) {nm} = ({ct.spelling})({e});'
                         for e in ptrs.get((ci, ai), [])]
                out.append("            " + " else ".join(conds + ['CQD_BAD("a pointer expression the driver '
                                                                    'was not rendered with");']))
                if a.get("cells"):
                    n = a["cells"]["n"]
                    out.append(f"            unsigned long long cqd_c{ai}[{n}]; "
                               f"for (int cqd_k = 0; cqd_k < {n}; cqd_k++) {{ CQD_HEX(); cqd_c{ai}[cqd_k] = cqd_w[0]; }}")
                    cellw.append(f"cqd_cells_i{a['cells']['w']}((void *)({nm}), {n}, cqd_c{ai});")
            elif ct.bits == 1:
                out.append(f"            {ct.spelling} {nm}; CQD_BOOL({nm});")
            else:
                nbytes = 10 if ct.bits == 80 else ct.bits // 8
                out.append(f"            {ct.spelling} {nm}; CQD_SCALAR({nm}, {nbytes});")
        out.append('            if (strtok_r(0, " ", &cqd_sv)) CQD_BAD("too many arguments");')
        rt, w, bits = _ret_type(spec, fn)
        callexpr = f"{fn}({', '.join(names)})"
        if w:
            body = (f"{rt} cqd_r = {callexpr}; "
                    f'CQD_RESULT({ci}, "{fn}", "{w}", &cqd_r, sizeof cqd_r, {bits});')
        else:
            body = f"(void){callexpr};"
        out.append(f"            {{ const int CQD_SAMPLE = cqd_idx; (void)CQD_SAMPLE; {before_call} "
                   f"{' '.join(cellw)} {body} {after_call} }}")
        out.append("            break; }")
    out.append('        default: CQD_BAD("call index out of range");')
    out.append("        }")
    out.append("    }")
    out.append("    return 0;\n}")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    for n, s in driver_specs(sys.argv[1:] or None).items():
        print(n, [(c["fn"], [a["ctype"] + ("*Q" if a["quantum"] else "") for a in c["args"]]) for c in s.calls])
