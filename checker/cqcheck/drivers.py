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
from typing import Dict, Iterable, List, NoReturn, Optional, Sequence, Set, Tuple

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
}
_FP_TYPES = {"float": 32, "double": 64, "long double": 80}


def parse_ctype(spelling: str) -> CType:
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

    def refs(self) -> List[str]:
        body = self.text.split("=", 1)[1] if self.dest else self.text
        return locals_in(body)

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


def read_module(path: Path) -> Module:
    lines = path.read_text().splitlines()
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
    return Module(path, lines, functions, gl, decl)


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


def quantum_params(mod: Module) -> QuantumParams:
    """Backward closure from every cq_theta_* first operand."""
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
        for ins in f.insts():
            if ins.op == "call" and ins.callee and ins.callee.startswith("@cq_theta_"):
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


def c_value(ct: CType, v: str) -> str:
    """A C expression with the exact bit pattern of sample value `v` (sampling encoding)."""
    if ct.kind == "p":
        return v
    if not v.startswith("0x"):
        unimplemented(f"sample value {v!r} for {ct.spelling}")
    if ct.kind == "i":
        n = int(v, 16)
        if ct.bits == 1:
            return "(_Bool)" + str(n & 1)
        return f"(({ct.spelling})0x{n:x}ULL)"
    if ct.bits == 32:
        return f"cqd_f32(0x{int(v, 16):08x}u)"
    if ct.bits == 64:
        return f"cqd_f64(0x{int(v, 16):016x}ULL)"
    n = int(v, 16)
    return f"cqd_f80(0x{n & ((1 << 64) - 1):016x}ULL, 0x{n >> 64:04x}u)"


DRIVER_PRELUDE = r"""
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
static inline float cqd_f32(uint32_t b) { float f; memcpy(&f, &b, 4); return f; }
static inline double cqd_f64(uint64_t b) { double f; memcpy(&f, &b, 8); return f; }
static inline long double cqd_f80(uint64_t m, uint16_t e) {
    long double f = 0; memcpy(&f, &m, 8); memcpy((char *)&f + 8, &e, 2); return f; }
"""


def driver_source(spec: DriverSpec, samples: Sequence[dict], *, before_call: str = "",
                  after_call: str = "", main_name: str = "main") -> str:
    """A C driver: the prototypes, the setup, then one call per sample in order. `before_call` and
    `after_call` are C statements with `CQD_SAMPLE` (the sample index) in scope."""
    out = [DRIVER_PRELUDE]
    out += spec.protos
    out.append(f"int {main_name}(void) {{")
    out.append("    " + spec.setup)
    for i, s in enumerate(samples):
        call = spec.calls[s["call"]]
        cts = [parse_ctype(a["ctype"]) for a in call["args"]]
        args = ", ".join(c_value(ct, v) for ct, v in zip(cts, s["args"]))
        out.append(f"    {{ const int CQD_SAMPLE = {i}; (void)CQD_SAMPLE; {before_call} "
                   f"(void){call['fn']}({args}); {after_call} }}")
    out.append("    return 0;\n}")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    for n, s in driver_specs(sys.argv[1:] or None).items():
        print(n, [(c["fn"], [a["ctype"] + ("*Q" if a["quantum"] else "") for a in c["args"]]) for c in s.calls])
