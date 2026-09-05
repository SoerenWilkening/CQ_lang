#!/usr/bin/env python3
"""migrate_phi_fixtures.py — bd epic test_C_libtooling-3qlq, Increment 1.

Migrate the `ir-pass/test/*.ll` corpus from the REGISTER-CARRYING `cq_phi`
surface

    %r = call T @cq_phi_<sfx>(T %x, double THETA)      ; 16 widths

to the REGISTER-FREE branch-phase surface (PRD
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §4.1, D1/D2)

    call void @cq_phi(double THETA)                    ; ONE extern

There are exactly TWO cases and the tool decides them PER CALL SITE:

  (U) UNCONTROLLED / classically-controlled — the call is not control-dependent
      on a TAINTED `br`/`switch`.  Owner decision **D2**: it is a global phase
      and is DELETED.  Rewrite: RAUW `%r -> %x`, erase the call line.  A merge
      phi that used to join `%r` with `%x` becomes a phi of identical incomings
      and is LEFT ALONE (the pass folds it).

  (A) IN A TAINTED ARM — the call becomes `call void @cq_phi(double THETA)` and
      the merge phi that carried `%r` against `%x` is DISSOLVED: RAUW the phi to
      the PRED incoming (`%x`) and erase it.  The lowering is the kickback
      triple (mint -> `cqrt_rz_i1(f, THETA)` -> strip -> free) whose handle
      numbers CANNOT be derived without the Inc-1 binary, so the fixture's CHECK
      lines are LEFT UNTOUCHED and the file is reported `NEEDS-REDERIVE`.

  (S) ANGLE SELECT — the call sits in a STRAIGHT-LINE block but its ANGLE is a
      `select`/`phi` on a TAINTED condition.  This is the `-O1` fold of
      `if (c) cq_phi(A); else cq_phi(B);` (PRD §6.2 P2) and is emphatically NOT
      a global phase: deleting it under D2 would silently remove a
      control-carrying gate.  Rewrite: `call void @cq_phi(double %ang)` with the
      result RAUWed to the base.  `NEEDS-REDERIVE`.

  (D) DECLARE-ONLY — a dead `declare ... @cq_phi_<sfx>(...)` with no call.  The
      declaration names a symbol the new frontend surface does not have, so it
      is erased.  (Class (M): the file only MENTIONS `cq_phi` in prose/CHECK
      text — nothing to do.)

WHY A TEXTUAL SSA WALKER.  `llvmlite` is not installed on this machine and the
pass itself cannot answer "is this call in a tainted arm?" for the ~2/3 of the
corpus that DECLINES (opt exits non-zero and prints no module).  The walker
below is deliberately conservative: anything it cannot parse or cannot prove
UNCONTROLLED is reported as class (A) or as HAND-DECISION, never silently
migrated as (U).  Documented limits are in `LIMITS` below and are echoed into
the report.

Usage
    python3 tools/migrate_phi_fixtures.py --report [--only GLOB]
    python3 tools/migrate_phi_fixtures.py --dry-run [--only GLOB]
    python3 tools/migrate_phi_fixtures.py --apply   [--only GLOB] [--classes U,A,D]
"""

from __future__ import annotations

import argparse
import fnmatch
import glob
import os
import re
import sys
from collections import defaultdict

# --------------------------------------------------------------------------
LIMITS = """
Documented limits of the textual SSA walker (read before trusting a class):
  L1 the parser is line-oriented; one LLVM instruction per line is assumed
     (true for every file in ir-pass/test at dfb8e83 -- verified by the
     `--report` self-check `unparsed_multiline`).
  L2 memory is NOT modelled: taint through `store`/`load` of a tainted value
     is not tracked.  Every fixture that stores a tainted value is listed as
     `mem-taint` in the report and forced to class (A)/HAND-DECISION.
  L3 interprocedural taint is a fixpoint over (arg -> param) and
     (return -> call result) for DEFINED callees only; an indirect call, a
     varargs call or a call to a declaration taints its result if any argument
     is tainted (conservative).
  L4 control dependence uses post-dominators over the textual CFG with a single
     virtual exit; blocks with no path to a `ret`/`unreachable` (infinite
     loops) post-dominate nothing, which OVER-approximates control dependence,
     i.e. pushes calls INTO class (A) -- the safe direction.
  L5 `cq_measure_*` is a taint SINK: its result is classical.  The arg-1 angle
     operand of `cq_theta_*`/`cq_phi_*` never carries taint (Rule 3).
  L6 control dependence is TRANSITIVE (a block under a classical branch nested
     inside a tainted arm counts as in-arm -- the §6.3 multi-block-arm decline
     shape) and INTERPROCEDURAL (a callee whose call site is under tainted
     control has all its `cq_phi` sites classified (A), noted `callsite-ctl`).
  L7 an angle operand that is TAINTED is never class (U): a `select`/`phi` on a
     tainted condition is class (S); anything else tainted is HAND-DECISION
     (that is the `tainted angle under quantum control` decline family).
"""

CALL_RE = re.compile(
    r'^(?P<indent>\s*)(?:(?P<lhs>%[\w.$]+)\s*=\s*)?'
    r'(?:tail\s+|musttail\s+|notail\s+)?call\s+(?P<rest>.*)$'
)
FN_RE = re.compile(r'@(?P<fn>[\w.$]+)\s*\(')
DEFINE_RE = re.compile(r'^define\b.*?@(?P<name>[\w.$"]+)\s*\(')
DECLARE_PHI_RE = re.compile(r'^declare\b[^;]*@cq_phi_[\w.$]+\s*\(')
LABEL_RE = re.compile(r'^(?P<name>[-\w.$]+):')
OPERAND_RE = re.compile(r'%[\w.$]+')
TERM_BR_COND_RE = re.compile(r'^\s*br\s+i1\s+(?P<cond>[%\w.$]+)\s*,\s*label\s+%(?P<t>[-\w.$]+)\s*,\s*label\s+%(?P<f>[-\w.$]+)')
TERM_BR_UNCOND_RE = re.compile(r'^\s*br\s+label\s+%(?P<t>[-\w.$]+)')
TERM_SWITCH_RE = re.compile(r'^\s*switch\s+\S+\s+(?P<val>[%\w.$-]+)\s*,\s*label\s+%(?P<def>[-\w.$]+)')
LABEL_REF_RE = re.compile(r'label\s+%([-\w.$]+)')

THETA_RE = re.compile(r'@cq_theta_[\w.$]+')
PHI_CALL_RE = re.compile(r'@(cq_phi_[\w.$]+)')
MEASURE_RE = re.compile(r'@cq_measure_[\w.$]+')


def word_sub(text: str, old: str, new: str) -> str:
    """Replace SSA name `old` (with its leading %) by `new`, whole-token only."""
    assert old.startswith('%')
    return re.sub(re.escape(old) + r'(?![\w.$])', new.replace('\\', '\\\\'), text)


def split_args(s: str) -> list[str]:
    """Split a call argument list on top-level commas."""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in '([{<':
            depth += 1
        elif ch in ')]}>':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if ''.join(cur).strip():
        out.append(''.join(cur).strip())
    return out


def call_arglist(rest: str) -> str | None:
    """Given the text after `call `, return the raw argument text."""
    m = FN_RE.search(rest)
    if not m:
        return None
    i = rest.index('(', m.end() - 1)
    depth, j = 0, i
    while j < len(rest):
        if rest[j] == '(':
            depth += 1
        elif rest[j] == ')':
            depth -= 1
            if depth == 0:
                return rest[i + 1:j]
        j += 1
    return None


# --------------------------------------------------------------------------
class Instr:
    __slots__ = ('idx', 'text', 'lhs', 'callee', 'args', 'is_term', 'is_phi')

    def __init__(self, idx, text):
        self.idx = idx
        self.text = text
        self.lhs = None
        self.callee = None
        self.args = None
        self.is_term = False
        self.is_phi = False


class Func:
    def __init__(self, name, start, end):
        self.name = name
        self.start = start          # index of the `define` line
        self.end = end              # index of the closing `}` line
        self.params: list[str] = []
        self.blocks: list[str] = []
        self.block_of: dict[int, str] = {}     # line idx -> block name
        self.block_lines: dict[str, list[int]] = defaultdict(list)
        self.succs: dict[str, list[str]] = defaultdict(list)
        self.preds: dict[str, list[str]] = defaultdict(list)
        self.term: dict[str, int] = {}         # block -> line idx of terminator
        self.instrs: dict[int, Instr] = {}
        self.entry: str | None = None


class Module:
    def __init__(self, path: str, lines: list[str]):
        self.path = path
        self.lines = lines
        self.funcs: list[Func] = []
        self.parse_error: str | None = None
        self.multiline_suspect = False
        self._parse()

    # -- parsing ---------------------------------------------------------
    def _parse(self):
        lines = self.lines
        i = 0
        n = len(lines)
        while i < n:
            m = DEFINE_RE.match(lines[i])
            if not m:
                i += 1
                continue
            start = i
            # the closing brace of a function is a bare `}` at column 0
            j = i + 1
            while j < n and lines[j].rstrip() != '}':
                j += 1
            if j >= n:
                self.parse_error = f'unterminated define at line {start+1}'
                return
            f = Func(m.group('name'), start, j)
            self._parse_params(f, lines[start])
            self._parse_body(f)
            self.funcs.append(f)
            i = j + 1

    def _parse_params(self, f: Func, define_line: str):
        raw = call_arglist(define_line[define_line.index('define'):])
        if raw is None:
            return
        for a in split_args(raw):
            names = OPERAND_RE.findall(a)
            if names:
                f.params.append(names[-1])

    def _parse_body(self, f: Func):
        cur = None
        for idx in range(f.start + 1, f.end):
            raw = self.lines[idx]
            stripped = raw.strip()
            if not stripped or stripped.startswith(';'):
                continue
            code = stripped.split(';', 1)[0].rstrip()
            if not code:
                continue
            lm = LABEL_RE.match(code)
            if lm and not code.startswith('%'):
                cur = lm.group('name')
                if f.entry is None:
                    f.entry = cur
                if cur not in f.blocks:
                    f.blocks.append(cur)
                continue
            if cur is None:
                cur = '%__entry__'
                f.entry = cur
                f.blocks.append(cur)
            f.block_of[idx] = cur
            f.block_lines[cur].append(idx)
            ins = Instr(idx, code)
            eq = code.find('=')
            if code.startswith('%') and eq > 0:
                ins.lhs = code[:eq].strip()
            m = CALL_RE.match(raw.split(';', 1)[0])
            if m:
                fm = FN_RE.search(m.group('rest'))
                if fm:
                    ins.callee = fm.group('fn')
                    ins.args = split_args(call_arglist(m.group('rest')) or '')
            if re.search(r'=\s*phi\b', code):
                ins.is_phi = True
            if re.match(r'^(ret|br|switch|unreachable|resume|indirectbr|invoke|callbr|cleanupret|catchret|catchswitch)\b', code):
                ins.is_term = True
                f.term[cur] = idx
            f.instrs[idx] = ins
            # multi-line instruction heuristic: unbalanced parens/brackets
            if code.count('(') != code.count(')') or code.count('[') != code.count(']'):
                self.multiline_suspect = True
        # CFG edges
        for b in f.blocks:
            t = f.term.get(b)
            if t is None:
                continue
            code = f.instrs[t].text
            for tgt in LABEL_REF_RE.findall(code):
                if tgt not in f.succs[b]:
                    f.succs[b].append(tgt)
        for b in f.blocks:
            for s in f.succs[b]:
                f.preds[s].append(b)


# --------------------------------------------------------------------------
def compute_taint(mods_funcs: list[Func], mod: Module) -> tuple[set[str], set[str]]:
    """Return (tainted SSA names qualified `fn::%name`, set of fns w/ mem taint).

    Interprocedural fixpoint over defined callees (limit L3).
    """
    tainted: set[str] = set()
    mem_taint_fns: set[str] = set()
    defined = {f.name: f for f in mods_funcs}
    ret_tainted: set[str] = set()
    changed = True
    guard = 0
    while changed and guard < 200:
        changed = False
        guard += 1
        for f in mods_funcs:
            for idx in sorted(f.instrs):
                ins = f.instrs[idx]
                code = ins.text
                q = lambda nm: f'{f.name}::{nm}'
                # -- taint SOURCE
                if ins.callee and ins.callee.startswith('cq_theta_'):
                    if ins.lhs and q(ins.lhs) not in tainted:
                        tainted.add(q(ins.lhs)); changed = True
                    continue
                # -- taint SINK
                if ins.callee and ins.callee.startswith('cq_measure_'):
                    continue
                if ins.callee and ins.callee.startswith('cq_phi_'):
                    a0 = OPERAND_RE.findall(ins.args[0]) if ins.args else []
                    if a0 and q(a0[-1]) in tainted and ins.lhs and q(ins.lhs) not in tainted:
                        tainted.add(q(ins.lhs)); changed = True
                    continue
                if ins.callee and ins.callee.startswith('cq_invert_'):
                    # escape; result (if any) conservatively tainted
                    if ins.lhs and q(ins.lhs) not in tainted:
                        tainted.add(q(ins.lhs)); changed = True
                    continue
                # -- store of a tainted value (limit L2)
                if code.startswith('store'):
                    ops = OPERAND_RE.findall(code)
                    if any(q(o) in tainted for o in ops):
                        if f.name not in mem_taint_fns:
                            mem_taint_fns.add(f.name); changed = True
                    continue
                if ins.callee and ins.callee in defined:
                    callee = defined[ins.callee]
                    for i, a in enumerate(ins.args or []):
                        names = OPERAND_RE.findall(a)
                        if names and q(names[-1]) in tainted and i < len(callee.params):
                            k = f'{callee.name}::{callee.params[i]}'
                            if k not in tainted:
                                tainted.add(k); changed = True
                    if ins.lhs and ins.callee in ret_tainted and q(ins.lhs) not in tainted:
                        tainted.add(q(ins.lhs)); changed = True
                    continue
                # -- generic forward propagation
                ops = OPERAND_RE.findall(code[code.find('=') + 1:] if ins.lhs else code)
                if ins.lhs and any(q(o) in tainted for o in ops):
                    if q(ins.lhs) not in tainted:
                        tainted.add(q(ins.lhs)); changed = True
                if code.startswith('ret') and any(q(o) in tainted for o in ops):
                    if f.name not in ret_tainted:
                        ret_tainted.add(f.name); changed = True
    return tainted, mem_taint_fns


# --------------------------------------------------------------------------
def post_dominators(f: Func) -> dict[str, set[str]]:
    """Post-dominator sets over the textual CFG with one virtual exit (L4)."""
    EXIT = '\0exit'
    blocks = list(f.blocks)
    succs = {b: list(f.succs[b]) for b in blocks}
    for b in blocks:
        t = f.term.get(b)
        if t is None or not succs[b]:
            succs[b] = [EXIT]
        else:
            code = f.instrs[t].text
            if re.match(r'^(ret|unreachable|resume)\b', code):
                succs[b] = [EXIT]
    universe = set(blocks) | {EXIT}
    pd = {b: set(universe) for b in blocks}
    pd[EXIT] = {EXIT}
    changed = True
    guard = 0
    while changed and guard < 10000:
        changed = False
        guard += 1
        for b in blocks:
            new = set(universe)
            for s in succs[b]:
                new &= pd.get(s, {s})
            new.add(b)
            if new != pd[b]:
                pd[b] = new
                changed = True
    return pd


def ipdom_map(f: Func, pd: dict[str, set[str]]) -> dict[str, str | None]:
    ip: dict[str, str | None] = {}
    for b in f.blocks:
        cands = pd[b] - {b}
        best = None
        for c in cands:
            # ipdom is the candidate post-dominated by every other candidate
            if all((c in pd.get(o, set())) or o == c for o in cands):
                if best is None or len(pd.get(c, set())) > len(pd.get(best, set())):
                    best = c
        ip[b] = best
    return ip


def branch_cond(f: Func, b: str) -> str | None:
    t = f.term.get(b)
    if t is None:
        return None
    code = f.instrs[t].text
    m = TERM_BR_COND_RE.match(' ' + code)
    if m:
        return m.group('cond')
    m = TERM_SWITCH_RE.match(' ' + code)
    if m:
        return m.group('val')
    return None


def control_deps(f: Func, tainted: set[str], seed_all: bool = False) -> set[str]:
    """Blocks TRANSITIVELY control-dependent on a TAINTED branch (limit L6).

    `seed_all=True` means the whole function runs under tainted control (its
    call site is in a tainted arm), so every block counts.
    """
    if seed_all:
        return set(f.blocks)
    pd = post_dominators(f)
    ip = ipdom_map(f, pd)
    # cd[B] = set of blocks whose terminator B is control-dependent on
    cd: dict[str, set[str]] = defaultdict(set)
    for b in f.blocks:
        if len(f.succs[b]) < 2:
            continue
        stop = ip.get(b)
        for s in f.succs[b]:
            cur, seen = s, set()
            while cur is not None and cur != stop and cur not in seen and cur != '\0exit':
                seen.add(cur)
                cd[cur].add(b)
                cur = ip.get(cur)
    tainted_branch: set[str] = set()
    for b in f.blocks:
        c = branch_cond(f, b)
        if c and c.startswith('%') and f'{f.name}::{c}' in tainted:
            tainted_branch.add(b)
    under: set[str] = set()
    changed = True
    while changed:
        changed = False
        for b in f.blocks:
            if b in under:
                continue
            if any(p in tainted_branch or p in under for p in cd.get(b, ())):
                under.add(b)
                changed = True
    return under


# --------------------------------------------------------------------------
class Site:
    def __init__(self, func, block, idx, lhs, base, angle, sfx, cls, why):
        self.func, self.block, self.idx = func, block, idx
        self.lhs, self.base, self.angle, self.sfx = lhs, base, angle, sfx
        self.cls, self.why = cls, why


class FileAnalysis:
    def __init__(self, path):
        self.path = path
        self.sites: list[Site] = []
        self.decl_lines: list[int] = []
        self.cls = 'M'
        self.notes: list[str] = []
        self.needs_rederive = False
        self.hand_decision: str | None = None


def analyze(path: str) -> FileAnalysis:
    fa = FileAnalysis(path)
    with open(path, 'r') as fh:
        lines = fh.read().split('\n')
    mod = Module(path, lines)
    if mod.parse_error:
        fa.notes.append(f'parse-error: {mod.parse_error}')
        fa.hand_decision = 'parse error'
        fa.cls = 'X'
        return fa
    if mod.multiline_suspect:
        fa.notes.append('unparsed_multiline')
    for i, ln in enumerate(lines):
        if DECLARE_PHI_RE.match(ln):
            fa.decl_lines.append(i)
    # an `invoke` of a cq_phi is a CALL SITE the line parser does not model; it has
    # its own decline (`reached via invoke; only a direct call is supported`).
    for i, ln in enumerate(lines):
        if re.search(r'\binvoke\b[^;]*@cq_phi', ln.split(';')[0]):
            fa.notes.append(f'invoke-callsite line {i+1}')
            fa.hand_decision = 'cq_phi reached via `invoke`, not a direct call'
    tainted, mem_fns = compute_taint(mod.funcs, mod)
    if mem_fns:
        fa.notes.append('mem-taint:' + ','.join(sorted(mem_fns)))
    byname = {f.name: f for f in mod.funcs}
    # -- pass 1: intraprocedural transitive control dependence
    under_of: dict[str, set[str]] = {f.name: control_deps(f, tainted) for f in mod.funcs}
    # -- pass 2: a callee whose call site is under tainted control runs under it (L6)
    fn_under: set[str] = set()
    changed = True
    while changed:
        changed = False
        for f in mod.funcs:
            for idx in sorted(f.instrs):
                ins = f.instrs[idx]
                if not ins.callee or ins.callee not in byname:
                    continue
                site_under = (f.block_of[idx] in under_of[f.name]) or (f.name in fn_under)
                if site_under and ins.callee not in fn_under:
                    fn_under.add(ins.callee)
                    under_of[ins.callee] = set(byname[ins.callee].blocks)
                    changed = True
    if fn_under:
        fa.notes.append('callsite-ctl:' + ','.join(sorted(fn_under)))
    # -- pass 3: classify each site
    for f in mod.funcs:
        under = under_of[f.name]
        defs = {ins.lhs: ins for ins in f.instrs.values() if ins.lhs}
        for idx in sorted(f.instrs):
            ins = f.instrs[idx]
            if not (ins.callee and ins.callee.startswith('cq_phi_')):
                continue
            blk = f.block_of[idx]
            args = ins.args or []
            a0 = OPERAND_RE.findall(args[0]) if args else []
            base = a0[-1] if a0 else (args[0].split()[-1] if args else None)
            angle_raw = args[1].strip() if len(args) > 1 else None
            angle = (OPERAND_RE.findall(angle_raw)[-1]
                     if angle_raw and OPERAND_RE.findall(angle_raw)
                     else (angle_raw.split()[-1] if angle_raw else None))
            angle_tainted = bool(angle and angle.startswith('%')
                                 and f'{f.name}::{angle}' in tainted)
            cls, why = ('U', 'not control-dependent on a tainted branch')
            if blk in under:
                cls, why = ('A', 'control-dependent on a tainted branch')
                if f.name in fn_under:
                    why += ' (via call site)'
            elif angle_tainted:
                d = defs.get(angle)
                sel = d is not None and re.search(r'=\s*(select|phi)\b', d.text)
                if sel:
                    cls, why = ('S', 'angle is a select/phi on a tainted condition (PRD P2)')
                else:
                    cls, why = ('H', 'angle operand is TAINTED and not a select/phi')
                    fa.hand_decision = (fa.hand_decision
                                        or f'tainted angle operand {angle} at line {idx+1}')
            elif f.name in mem_fns:
                cls, why = ('A', 'memory taint in this function (limit L2) -> conservative')
            fa.sites.append(Site(f.name, blk, idx, ins.lhs, base, angle_raw, ins.callee, cls, why))
    # PRD §6.3 row 1: an arm with N>1 cq_phi calls declines (angle sum, follow-on)
    per_block: dict[tuple[str, str], int] = defaultdict(int)
    for s in fa.sites:
        if s.cls in ('A', 'S'):
            per_block[(s.func, s.block)] += 1
    if any(v > 1 for v in per_block.values()):
        fa.notes.append('arm-N>1')
    if not fa.sites:
        fa.cls = 'D' if fa.decl_lines else 'M'
    else:
        kinds = {s.cls for s in fa.sites}
        if kinds == {'U'}:
            fa.cls = 'U'
        elif kinds == {'A'}:
            fa.cls = 'A'
        elif kinds == {'S'}:
            fa.cls = 'S'
        elif 'H' in kinds:
            fa.cls = 'H'
        else:
            fa.cls = 'MIX'
    return fa


# --------------------------------------------------------------------------
CHECK_RE = re.compile(r'^\s*;\s*(RUN|CHECK[-\w]*)\s*:')
RZ_POSITIVE_RE = re.compile(r'^\s*;\s*CHECK(?!-NOT)[-\w]*\s*:.*cqrt_rz_')
RZ_CONTROLLED_RE = re.compile(r'cqrt_rz_\w+_controlled')


def rewrite(path: str, fa: FileAnalysis, do_checks: bool) -> tuple[list[str], list[str]]:
    """Return (new_lines, actions).  Pure; caller writes."""
    with open(path, 'r') as fh:
        lines = fh.read().split('\n')
    actions: list[str] = []
    drop: set[int] = set()
    # --- 1. per-call-site body rewrite (bottom-up so indices stay valid)
    mod = Module(path, lines)
    funcs = {f.name: f for f in mod.funcs}
    added_void_decl = False
    for s in sorted(fa.sites, key=lambda s: -s.idx):
        f = funcs[s.func]
        if s.cls == 'U':
            if s.lhs and s.base:
                for idx in range(f.start + 1, f.end):
                    if idx == s.idx:
                        continue
                    lines[idx] = word_sub(lines[idx], s.lhs, s.base)
            drop.add(s.idx)
            actions.append(f'U delete {s.func}:{s.block} {s.lhs} -> {s.base}')
        elif s.cls in ('A', 'S'):
            # dissolve a merge phi that carried this result FIRST (class A only:
            # the -O1 output for a void arm has no merge phi at all, PRD §6.1)
            if s.cls == 'A' and s.lhs:
                for idx in range(f.start + 1, f.end):
                    ins = f.instrs.get(idx)
                    if not ins or not ins.is_phi:
                        continue
                    if not re.search(re.escape(s.lhs) + r'(?![\w.$])', ins.text):
                        continue
                    incs = re.findall(r'\[\s*([^,\]]+)\s*,\s*%([-\w.$]+)\s*\]', ins.text)
                    others = [v.strip() for (v, _b) in incs
                              if v.strip() != s.lhs]
                    keep = None
                    if s.base and s.base in others:
                        keep = s.base
                    elif len(set(others)) == 1:
                        keep = others[0]
                    if keep is None:
                        fa.notes.append(f'phi-not-dissolvable at line {idx+1}')
                        fa.hand_decision = (fa.hand_decision or 'merge phi not mechanically dissolvable')
                        continue
                    phi_lhs = ins.lhs
                    drop.add(idx)
                    if phi_lhs:
                        for k in range(f.start + 1, f.end):
                            if k == idx:
                                continue
                            lines[k] = word_sub(lines[k], phi_lhs, keep)
                    actions.append(f'{s.cls} dissolve phi {phi_lhs} -> {keep}')
            # the register-free call returns NOTHING: every surviving use of the
            # old result becomes the base (a phi already dissolved above is gone).
            if s.lhs and s.base:
                for idx in range(f.start + 1, f.end):
                    if idx == s.idx or idx in drop:
                        continue
                    lines[idx] = word_sub(lines[idx], s.lhs, s.base)
            elif s.lhs and not s.base:
                fa.hand_decision = (fa.hand_decision or
                                    f'{s.lhs} has a non-SSA base operand; cannot RAUW')
            indent = re.match(r'^(\s*)', lines[s.idx]).group(1)
            trailing = ''
            if ';' in lines[s.idx]:
                trailing = '  ;' + lines[s.idx].split(';', 1)[1]
            ang = s.angle.split()[-1] if s.angle else '0.000000e+00'
            lines[s.idx] = f'{indent}call void @cq_phi(double {ang}){trailing}'
            added_void_decl = True
            actions.append(f'{s.cls} void-call {s.func}:{s.block} (was {s.lhs})')
    # --- 2. declares.  Erase a `declare @cq_phi_<sfx>` ONLY when no reference to
    # that symbol survives -- an `invoke` (or any construct the line parser does
    # not model) would otherwise leave a dangling reference and a PARSE ERROR.
    body_now = '\n'.join(l for i, l in enumerate(lines)
                         if i not in drop and not DECLARE_PHI_RE.match(l))
    for i, ln in enumerate(lines):
        m = re.search(r'@(cq_phi_[\w.$]+)', ln) if DECLARE_PHI_RE.match(ln) else None
        if not m:
            continue
        if re.search(r'@' + re.escape(m.group(1)) + r'(?![\w.$])', body_now):
            fa.hand_decision = (fa.hand_decision or
                                f'@{m.group(1)} still referenced after the rewrite; declare kept')
            actions.append(f'declare KEPT (still referenced): {ln.strip()}')
            continue
        drop.add(i)
        actions.append(f'declare erased: {ln.strip()}')
    if added_void_decl and not any(re.match(r'^declare\s+void\s+@cq_phi\s*\(', l) for l in lines):
        anchor = None
        for i, ln in enumerate(lines):
            if re.match(r'^declare\b', ln):
                anchor = i
                break
        if anchor is None:
            for i, ln in enumerate(lines):
                if ln.startswith('define '):
                    anchor = i
                    break
        if anchor is None:
            anchor = len(lines)
        lines.insert(anchor, 'declare void @cq_phi(double)')
        drop = {d + 1 if d >= anchor else d for d in drop}
        actions.append('declare void @cq_phi(double) added')
    # --- 3. CHECK lines (only where the rewrite is CERTAIN)
    if do_checks:
        for i, ln in enumerate(lines):
            if i in drop:
                continue
            if RZ_CONTROLLED_RE.search(ln) and CHECK_RE.match(ln):
                fa.needs_rederive = True
                continue
            if RZ_POSITIVE_RE.match(ln):
                drop.add(i)
                actions.append(f'CHECK deleted (uncontrolled Rz gone): {ln.strip()}')
    # --- 4. header note
    out = [l for i, l in enumerate(lines) if i not in drop]
    case = {'U': 'uncontrolled -> deleted (D2)',
            'A': 'tainted arm -> void call, merge phi dissolved',
            'S': 'angle select -> void call on the select (PRD P2)',
            'MIX': 'mixed sites: see the migration report',
            'H': 'hand decision',
            'D': 'dead declare erased',
            'M': 'no IR change'}[fa.cls]
    note = f'; 3qlq: migrated from register cq_phi ({case})'
    ins_at = 0
    for i, l in enumerate(out):
        if l.startswith(';'):
            ins_at = i + 1
        elif l.strip() == '':
            continue
        else:
            break
    out.insert(ins_at, note)
    return out, actions


# --------------------------------------------------------------------------
# Oracle equivalence check (run BEFORE --apply; the on-disk file is the original)
RZ_UNCTL_RE = re.compile(r'call void @cqrt_rz_(i1|i8|i16|i32|i64|f16|f32|f64|f80)\(')
RZ_DECL_RE = re.compile(r'^declare\s+void\s+@cqrt_rz_')
PHI_DECL_ANY_RE = re.compile(r'^declare\b.*@cq_phi')


def _norm(out: str) -> list[str]:
    keep = []
    for l in out.split('\n'):
        if RZ_UNCTL_RE.search(l) and '_controlled' not in l:
            continue
        if RZ_DECL_RE.match(l) or PHI_DECL_ANY_RE.match(l):
            continue
        if l.startswith("; ModuleID = ") or l.startswith('source_filename = '):
            continue
        l = l.rstrip()
        if not l:
            continue          # blank-line count is not part of the contract
        keep.append(l)
    return keep


def run_oracle(cq_opt: str, cq_pass: str, path: str):
    import subprocess
    p = subprocess.run([cq_opt, '-load-pass-plugin', cq_pass,
                        '-passes=cq-lowering', '-S', path],
                       capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def verify_oracle(path: str, fa: FileAnalysis, cq_opt: str, cq_pass: str, tmpdir: str,
                  opt_bin: str | None = None):
    """Return (verdict, detail).

    For class U/D the ORACLE is a real equivalence oracle: the migrated module
    contains no `cq_phi` at all, so the pre-3qlq binary answers it exactly as the
    Inc-1 binary will.  Verdicts OK / EXIT / STDERR / EXTRA-DIFF / RZ-LEFT.

    For class A/S/MIX the migrated module contains `call void @cq_phi(double)`,
    which the ORACLE cannot lower -- there is nothing to compare.  The check
    degrades to WELL-FORMEDNESS (`opt -passes=verify`): PARSE-OK / PARSE-FAIL.
    """
    new_lines, _ = rewrite(path, fa, do_checks=False)
    tmp = os.path.join(tmpdir, os.path.basename(path))
    with open(tmp, 'w') as fh:
        fh.write('\n'.join(new_lines))
    if fa.cls not in ('U', 'D'):
        if not opt_bin:
            return 'PARSE-SKIP', 'no --opt binary given'
        import subprocess
        p = subprocess.run([opt_bin, '-passes=verify', '-disable-output', tmp],
                           capture_output=True, text=True)
        if p.returncode != 0:
            return 'PARSE-FAIL', p.stderr.strip().split('\n')[0][:200]
        return 'PARSE-OK', 'module verifies'
    rc0, o0, e0 = run_oracle(cq_opt, cq_pass, path)
    rc1, o1, e1 = run_oracle(cq_opt, cq_pass, tmp)
    if (rc0 == 0) != (rc1 == 0):
        return 'EXIT', f'oracle exit {rc0} -> {rc1}'
    if rc0 != 0:
        s0 = [l for l in e0.split('\n') if 'error' in l]
        s1 = [l for l in e1.split('\n') if 'error' in l]
        if s0 != s1:
            return 'STDERR', f'{s0} -> {s1}'
        return 'OK', 'decline unchanged'
    n0, n1 = _norm(o0), _norm(o1)
    if n0 != n1:
        import difflib
        d = list(difflib.unified_diff(n0, n1, 'orig', 'migrated', n=1, lineterm=''))
        return 'EXTRA-DIFF', '\\n'.join(d[:24])
    if fa.cls in ('U', 'D'):
        left = [l for l in o1.split('\n')
                if RZ_UNCTL_RE.search(l) and '_controlled' not in l]
        if left:
            return 'RZ-LEFT', left[0].strip()
    return 'OK', f'{len(o0.split(chr(10))) - len(n0)} rz/decl line(s) removed'


def probe_theta_swap(path: str, fa: FileAnalysis, cq_opt: str, cq_pass: str, tmpdir: str):
    """Proposed disposition probe for a HELD fixture.

    Many held fixtures use an UNCONTROLLED `cq_phi` merely as "a gate on a
    handle" -- the subject is uncompute / mux / measurement ordering, not Rz.
    Substituting the OTHER rotation (`cq_theta`, which keeps its register under
    D5) is then a semantics-preserving rewrite for the fixture's PURPOSE.  This
    probe MEASURES that on the oracle: same exit code AND the same `error` lines
    as the ORIGINAL means the swap is a safe proposal, not a guess.
    """
    with open(path) as fh:
        txt = fh.read()
    new = txt
    for s in fa.sites:
        new = re.sub(r'@' + re.escape(s.sfx) + r'(?![\w.$])',
                     '@cq_theta_' + s.sfx[len('cq_phi_'):], new)
    new = re.sub(r'^declare\s+(\S+)\s+@cq_theta_([\w.$]+)\((.*)\)\s*$',
                 lambda m: f'declare {m.group(1)} @cq_theta_{m.group(2)}({m.group(3)})',
                 new, flags=re.M)
    # collapse the now-duplicated cq_theta declares
    seen = set()
    out = []
    for l in new.split('\n'):
        m = re.match(r'^declare\s+\S+\s+@(cq_theta_[\w.$]+)\(', l)
        if m:
            if m.group(1) in seen:
                continue
            seen.add(m.group(1))
        out.append(l)
    tmp = os.path.join(tmpdir, 'theta_' + os.path.basename(path))
    with open(tmp, 'w') as fh:
        fh.write('\n'.join(out))
    rc0, o0, e0 = run_oracle(cq_opt, cq_pass, path)
    rc1, o1, e1 = run_oracle(cq_opt, cq_pass, tmp)
    s0 = [l for l in e0.split('\n') if 'error' in l]
    s1 = [l for l in e1.split('\n') if 'error' in l]
    if (rc0 == 0) != (rc1 == 0):
        return 'THETA-NO', f'exit {rc0} -> {rc1}'
    if rc0 != 0:
        return ('THETA-OK', 'same diagnostic') if s0 == s1 else ('THETA-NO', f'{s1}')
    return 'THETA-ACCEPTS-BOTH', 'both accept; compare the streams by hand'


# --------------------------------------------------------------------------
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--root', default=None, help='repo root (default: parent of tools/)')
    ap.add_argument('--only', default='*', help='glob over fixture BASENAMES')
    ap.add_argument('--classes', default='U,A,S,MIX,D',
                    help='comma list of classes to APPLY (default U,A,S,MIX,D)')
    ap.add_argument('--no-checks', action='store_true',
                    help='never touch CHECK lines (IR body only)')
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--report', action='store_true')
    g.add_argument('--dry-run', action='store_true')
    g.add_argument('--apply', action='store_true')
    g.add_argument('--verify-oracle', action='store_true',
                   help='run the ORACLE cq-opt on the file AND on its in-memory '
                        'migration and compare (run BEFORE --apply)')
    g.add_argument('--probe-theta', action='store_true',
                   help='for each selected file, MEASURE whether swapping every '
                        'cq_phi_<sfx> for cq_theta_<sfx> preserves the oracle '
                        'disposition (a proposed disposition for HELD fixtures)')
    ap.add_argument('--cq-opt', default=os.environ.get('CQ_OPT'))
    ap.add_argument('--cq-pass', default=os.environ.get('CQ_PASS'))
    ap.add_argument('--opt', default=os.environ.get('LLVM_OPT'),
                    help='stock LLVM 19 opt, for the -passes=verify well-formedness check')
    ap.add_argument('--hold-file', default=None,
                    help='newline list of BASENAMES the mechanical migration must NOT '
                         'touch (default tools/migrate_phi_fixtures.hold.txt)')
    ap.add_argument('--write-hold', default=None,
                    help='--verify-oracle: write the files whose ORACLE disposition '
                         'CHANGED to this path (they become HAND-DECISION)')
    ap.add_argument('--limits', action='store_true', help='print the walker limits and exit')
    args = ap.parse_args(argv)
    if args.limits:
        print(LIMITS)
        return 0
    root = args.root or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    files = sorted(glob.glob(os.path.join(root, 'ir-pass', 'test', '*.ll')))
    files = [f for f in files if fnmatch.fnmatch(os.path.basename(f), args.only)]
    want = set(x.strip() for x in args.classes.split(',') if x.strip())

    hold_path = args.hold_file or os.path.join(root, 'tools', 'migrate_phi_fixtures.hold.txt')
    hold: dict[str, str] = {}
    if os.path.exists(hold_path):
        for l in open(hold_path):
            l = l.split('#', 1)[0].strip()
            if not l:
                continue
            parts = l.split(None, 1)
            hold[parts[0]] = parts[1] if len(parts) > 1 else 'held'

    counts = defaultdict(int)
    verdicts = defaultdict(int)
    held_out: list[tuple[str, str]] = []
    rows = []
    tmpdir = None
    if args.verify_oracle or args.probe_theta:
        import tempfile
        if not args.cq_opt or not args.cq_pass:
            print('this mode needs CQ_OPT and CQ_PASS (env or flags)', file=sys.stderr)
            return 2
        tmpdir = tempfile.mkdtemp(prefix='phi_migrate_')
    for path in files:
        with open(path) as fh:
            txt = fh.read()
        if 'cq_phi' not in txt:
            continue
        fa = analyze(path)
        base = os.path.basename(path)
        if base in hold and not args.write_hold:
            fa.hand_decision = fa.hand_decision or ('HOLD: ' + hold[base])
        counts[fa.cls] += 1
        per = {k: sum(1 for s in fa.sites if s.cls == k) for k in 'UASH'}
        rows.append((os.path.basename(path), fa.cls, per['U'], per['A'], per['S'],
                     per['H'], len(fa.decl_lines),
                     ';'.join(fa.notes), fa.hand_decision or ''))
        if args.report:
            continue
        if args.probe_theta:
            if not fa.sites:
                continue
            v, detail = probe_theta_swap(path, fa, args.cq_opt, args.cq_pass, tmpdir)
            verdicts[(fa.cls, v)] += 1
            print(f'{v}\t{base}\t[{fa.cls}]\t{detail}')
            continue
        if fa.cls not in want or fa.cls in ('M',):
            continue
        if args.verify_oracle:
            if fa.hand_decision and not args.write_hold:
                verdicts[(fa.cls, 'HAND-SKIP')] += 1
                continue
            v, detail = verify_oracle(path, fa, args.cq_opt, args.cq_pass, tmpdir, args.opt)
            verdicts[(fa.cls, v)] += 1
            if v not in ('OK', 'PARSE-OK'):
                print(f'{v}\t{base}\t[{fa.cls}]\t{detail}')
                if v in ('EXIT', 'STDERR', 'EXTRA-DIFF', 'RZ-LEFT', 'PARSE-FAIL'):
                    held_out.append((base, f'{v}: {detail[:150]}'))
            continue
        do_checks = (fa.cls in ('U', 'D')) and not args.no_checks
        new_lines, actions = rewrite(path, fa, do_checks)
        if args.apply and not fa.hand_decision:
            with open(path, 'w') as fh:
                fh.write('\n'.join(new_lines))
        if args.dry_run:
            print(f'--- {os.path.basename(path)} [{fa.cls}]'
                  + (f'  HAND-DECISION: {fa.hand_decision}' if fa.hand_decision else ''))
            for a in actions:
                print(f'    {a}')

    print('class counts:', dict(sorted(counts.items())))
    if args.probe_theta:
        print('theta-swap verdicts:',
              dict(sorted((f'{c}/{v}', n) for (c, v), n in verdicts.items())))
    if args.verify_oracle:
        print('oracle verdicts:', dict(sorted((f'{c}/{v}', n) for (c, v), n in verdicts.items())))
        if args.write_hold:
            with open(args.write_hold, 'w') as fh:
                fh.write('# generated by migrate_phi_fixtures.py --verify-oracle '
                         '--write-hold\n# BASENAME  reason\n')
                for b, r in sorted(held_out):
                    fh.write(f'{b}  {r}\n')
            print(f'wrote {len(held_out)} hold entries to {args.write_hold}')
    if args.report:
        print('file\tclass\tU\tA\tS\tH\tdeclares\tnotes\thand_decision')
        for r in rows:
            print('\t'.join(str(x) for x in r))
    return 0


if __name__ == '__main__':
    sys.exit(main())
