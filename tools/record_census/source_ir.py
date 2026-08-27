#!/usr/bin/env python3
"""source_ir.py — a PRE-LOWERING chained-theta / live-record analyser.

WHY THIS EXISTS, AND WHY IT IS SEPARATE FROM THE LOWERED-IR CENSUSES
===================================================================
Censuses 0.1 and 0.2 work on LOWERED IR, which is the faithful view: the emitted
gate stream is the artefact whose physics is at issue. But a module that DECLINES
produces NO lowered IR at all — measured: `cq-opt` exits non-zero and writes
nothing. Census 0.4 is precisely about DECLINING modules (which negative fixture's
pinned message would the new M-A guard steal?), so it cannot use that view.

This file therefore models the SAME predicate one stage earlier, on the IR as
committed. It is deliberately a SEPARATE FILE with a SEPARATE model rather than a
mode of the lowered-IR census, because the two are not the same measurement and
merging them would let the weaker one borrow the stronger one's credibility.

WHERE THE REAL GUARD WOULD SIT
------------------------------
The plan of record puts M-A (`declineLiveRecordRotations`) in the
`declineStaleRecordOps` slot. DERIVED from ir-pass/src/CQLoweringPass.cpp's
`run()`, that slot sits AFTER `propagate`, the bitcast/volatile folds, the fp80
union promotion, the PredMux fixpoint, const-trip unrolling, the ctlz idiom
prepass and `declineTaintEscapes` — and BEFORE `lowerLoops`,
`lowerControlRegions`, `lowerQramReads`, `lowerRotations`, `lowerOps`,
`lowerMeasures` and `uncompute`. So at the M-A slot `@cq_theta_*` is still a
CALL and a record is still a plain LLVM instruction, which is what this file
models.

WHAT IT COMPUTES
----------------
  TAINT      Seeded at `@cq_theta_*` results ONLY (Rule 3: `cq_theta` is the sole
             source). Propagated forward along operand->result edges. The arg-1
             ANGLE operand of `@cq_theta_*` / `@cq_phi_*` is EXCLUDED (Rule 3's
             per-operand-use exclusion), so an angle never carries taint.
  WIRE(C)    For a `@cq_theta_*` call C, the set of SSA values denoting the SAME
             physical rail: C's arg-0 and C's result, closed transitively through
             any further `@cq_theta_*` / `@cq_phi_*` call that reads or produces
             a member. (After lowering these all RAUW to one i32 handle; before
             lowering they are distinct SSA names for one wire.)
  CHAINED    C is chained iff its arg-0 is tainted — i.e. the rotation lands on
             an existing wire rather than minting one.
  RECORD     A tainted PURE PRODUCER instruction (a binop, a unary op, a cast, a
             `getelementptr`-free load, or a call that is not one of the `cq_*`
             intrinsics) that is not itself part of the wire. ANCESTORS are those
             reachable backwards from the wire along operand edges; DESCENDANTS
             those reachable forwards along use edges, excluding the wire chain.

APPROXIMATION DIRECTIONS — this model is an UPPER BOUND, on purpose
-------------------------------------------------------------------
  U1  NO LIVENESS, NO DISCHARGE. Pre-lowering there is no `cqrt_free` and no
      `_unc` to observe, so a record that Phase 4 or the Phase-5 spine would
      later discharge is still counted. DIRECTION: OVER-counts. That is the
      right direction for census 0.4, whose question is "which fixtures COULD
      have their message stolen".
  U1b POSITION IS MODELLED. A record produced textually AFTER the theta is NOT
      counted (it does not exist at the rotation); it is reported in
      `after_theta` instead. This mirrors census 0.1's lowered `live_at` and is
      what keeps `declineStaleRecordOps`'s OWN cases (an op scheduled past a
      theta) out of the M-A population.
  U2  The `cq_measure` exemption IS modelled (a record whose value is consumed by
      a `@cq_measure_*` call textually before the theta is dropped), and the
      control-position-compare exemption is modelled STRUCTURALLY (a tainted
      `icmp`/`fcmp` whose only users are `br` / `select` / `switch`), both as
      separate counters so their effect is visible rather than baked in.
  U1c THE OWNER-RULED DEADNESS CLAUSE (clause 3) IS MODELLED, and here it is the
      STRONGER view, not the weaker one. Pre-lowering there are no discharge ops
      at all — no `cqrt_free`, no `_unc`, no compiler-emitted adjoint `cqrt_ry`
      — so "R has no use after T" is a plain SSA-user question with no exception
      list to get wrong. That is exactly what the guard at the
      `declineStaleRecordOps` slot will see. Under `--predicate ruled` a
      `@cq_theta_*` result OUTSIDE the wire is also a record (the pre-lowering
      spelling of an alloc-minted rail: `lowerRotations` allocates AT the theta),
      which is the ruling's new inclusion. `--predicate plan-v1` keeps the old
      record class and drops the clause. Position is textual line order (U1b).
  U3  NO PredMux / unroll / ctlz REWRITING. Those stages run BEFORE the M-A slot
      and can duplicate or erase instructions, so a fixture whose shape changes
      under them is modelled as written. DIRECTION: unknown-sign; the affected
      fixtures are identifiable by their names (`*predmux*`, `*ctlz*`, `*loop*`)
      and census 0.4 lists them.
  U4  Line-oriented operand extraction. `phi` incomings are read from the
      `[ value, %block ]` brackets so a block label is never taken for an
      operand; `br`/`switch` label operands are stripped. Anything else is read
      as "every `%name` token on the line", which can over-collect on an exotic
      instruction. DIRECTION: OVER-counts edges.

VALIDATION
----------
`--validate [--predicate ruled|plan-v1]` runs this model over the POSITIVE lit
corpus and compares TWO verdicts against census 0.1's lowered-IR census on the
same fixtures:

  1. the CHAINED-THETA verdict (is there a site at all) — predicate-independent
     by construction, and the check that found the §9.3 lowered-only artefacts;
  2. the RECORD-HIT verdict under the selected predicate — which is where the
     ruling's clause 3 bites, and where the lowered view is the WEAKER one
     (U1c): a lowered module carries `_unc` / `cqrt_free` / adjoint-`cqrt_ry`
     traffic that does not exist yet at the guard slot, and read literally the
     ruling counts those as data uses.

Disagreements are printed with their direction. That is the honest way to state
how much each view can be trusted: not "it agrees", but "here is exactly where it
does not".
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402

fpc = cc.fpc

DEFINE_RE = re.compile(r"^define\s")
RES_RE = re.compile(r"^\s*(%[-\w.$]+|%\"[^\"]+\")\s*=\s*(.*)$")
SSA_RE = re.compile(r"%(?:\"[^\"]+\"|[-\w.$]+)")
CALLEE_RE = re.compile(r"@([\w.$]+|\"[^\"]+\")\s*\(")
LABEL_OPERAND_RE = re.compile(r"\blabel\s+%(?:\"[^\"]+\"|[-\w.$]+)")
PHI_INCOMING_RE = re.compile(r"\[\s*([^,\]]+)\s*,")

THETA_RE = re.compile(r"^cq_theta_\w+$")
PHI_INTRIN_RE = re.compile(r"^cq_phi_\w+$")
MEASURE_RE = re.compile(r"^cq_measure_\w+$")
CQ_ANY_RE = re.compile(r"^cq_(theta|phi|measure|invert)_\w+$")

# Opcodes that are NOT pure producers of a record.
NON_PRODUCER = {"store", "br", "switch", "ret", "unreachable", "fence",
                "indirectbr", "resume", "call", "invoke"}


class Instr:
    __slots__ = ("line", "res", "opcode", "operands", "callee", "text", "fn")

    def __init__(self, line, res, opcode, operands, callee, text):
        self.line = line
        self.res = res
        self.opcode = opcode
        self.operands = operands
        self.callee = callee
        self.text = text


def _operands(opcode, rest, callee, line_text):
    if opcode == "phi":
        vals = [v.strip() for v in PHI_INCOMING_RE.findall(rest)]
        return [v for v in vals if v.startswith("%")]
    body = LABEL_OPERAND_RE.sub(" ", rest)
    if callee is not None:
        m = CALLEE_RE.search(body)
        if m:
            open_at = body.index("(", m.end() - 1)
            j = fpc.balanced(body, open_at)
            args = fpc.split_args(body[open_at + 1:j])
            vals = [fpc.arg_value(a) for a in args]
            # Rule 3: the arg-1 ANGLE of a rotation is CLASSICAL, per-operand.
            if (THETA_RE.match(callee) or PHI_INTRIN_RE.match(callee)) \
                    and len(vals) >= 2:
                vals = [vals[0]] + vals[2:]
            return [v for v in vals if v.startswith("%")]
    return SSA_RE.findall(body)


def parse_functions(path):
    """-> {fn_name: [Instr]} over an UNLOWERED (or any) .ll."""
    lines = open(path, errors="replace").read().split("\n")
    out, i = {}, 0
    while i < len(lines):
        if not DEFINE_RE.match(lines[i]):
            i += 1
            continue
        m = re.match(r"^define\s.*?@([\w.$]+|\"[^\"]+\")\s*\(", lines[i])
        name = m.group(1).strip('"') if m else f"@{i}"
        instrs, j = [], i + 1
        while j < len(lines) and lines[j] != "}":
            ln = lines[j]
            rm = RES_RE.match(ln)
            if rm:
                res, rest = rm.group(1), rm.group(2)
            else:
                res, rest = None, ln.strip()
            toks = rest.split()
            opcode = toks[0] if toks else ""
            if opcode in ("tail", "musttail", "notail"):
                opcode = toks[1] if len(toks) > 1 else opcode
            cm = CALLEE_RE.search(rest)
            callee = cm.group(1).strip('"') if (cm and "call" in rest) else None
            if opcode or res:
                instrs.append(Instr(j + 1, res, opcode,
                                    _operands(opcode, rest, callee, ln),
                                    callee, ln.strip()))
            j += 1
        out[name] = instrs
        i = j + 1
    return out


class FnAnalysis:
    def __init__(self, name, instrs):
        self.name = name
        self.instrs = instrs
        self.by_res = {i.res: i for i in instrs if i.res}
        self.users = {}
        for ins in instrs:
            for op in ins.operands:
                self.users.setdefault(op, []).append(ins)
        self.tainted = set()
        self._propagate()

    def _propagate(self):
        work = [i.res for i in self.instrs
                if i.callee and THETA_RE.match(i.callee) and i.res]
        self.tainted.update(work)
        while work:
            v = work.pop()
            for u in self.users.get(v, ()):
                if u.res and u.res not in self.tainted:
                    self.tainted.add(u.res)
                    work.append(u.res)

    def is_producer(self, ins):
        if ins.res is None:
            return False
        if ins.callee is not None:
            return not CQ_ANY_RE.match(ins.callee)
        return ins.opcode not in NON_PRODUCER and ins.opcode != "phi"

    def wire_of(self, theta):
        """Values naming the SAME rail as `theta`'s arg-0/result."""
        w, stack = set(), []
        if theta.operands:
            w.add(theta.operands[0])
            stack.append(theta.operands[0])
        if theta.res:
            w.add(theta.res)
            stack.append(theta.res)
        while stack:
            v = stack.pop()
            d = self.by_res.get(v)
            if d is not None and d.callee and (THETA_RE.match(d.callee)
                                               or PHI_INTRIN_RE.match(d.callee)):
                if d.operands and d.operands[0] not in w:
                    w.add(d.operands[0])
                    stack.append(d.operands[0])
            for u in self.users.get(v, ()):
                if u.callee and (THETA_RE.match(u.callee)
                                 or PHI_INTRIN_RE.match(u.callee)) and u.res:
                    if u.res not in w:
                        w.add(u.res)
                        stack.append(u.res)
        return w

    def chained_thetas(self):
        out = []
        for ins in self.instrs:
            if not (ins.callee and THETA_RE.match(ins.callee)):
                continue
            if ins.operands and ins.operands[0] in self.tainted:
                out.append(ins)
        return out

    def _cone(self, wire, forward):
        seen, stack = set(), list(wire)
        while stack:
            v = stack.pop()
            nxt = []
            if forward:
                nxt = [u.res for u in self.users.get(v, ()) if u.res]
            else:
                d = self.by_res.get(v)
                if d is not None:
                    nxt = list(d.operands)
            for w in nxt:
                if w in wire or w in seen:
                    continue
                seen.add(w)
                stack.append(w)
        return seen

    def control_position_compare(self, ins):
        """A tainted compare whose ONLY users are br/select/switch — the shape
        Phase 4 owns (discharges or declines). Modelled structurally."""
        if ins.opcode not in ("icmp", "fcmp") or ins.res is None:
            return False
        us = self.users.get(ins.res, [])
        return bool(us) and all(u.opcode in ("br", "select", "switch")
                                for u in us)

    def is_alloc_record(self, ins, wire):
        """The pre-lowering spelling of an ALLOC-minted rail (the ruling's new
        inclusion): a `@cq_theta_*` result that is NOT part of this theta's own
        wire. `lowerRotations` allocates AT the theta, so such a value becomes a
        `cqrt_alloc_<W>` rail in the lowered view — bd nepx's `h0`."""
        return (ins.res is not None and ins.callee is not None
                and THETA_RE.match(ins.callee) and ins.res not in wire)

    def dead_at(self, v, theta):
        """Ruling clause 3, pre-lowering: NO user of `%v` after the theta.

        There is no exception list here and that is the point — at the M-A slot
        the module contains no `cqrt_free`, no `_unc` and no compiler-emitted
        adjoint `cqrt_ry`, so every user really is a data user. Returns
        (dead, [witness user lines])."""
        after = [f"{u.line}:{u.opcode}" for u in self.users.get(v, ())
                 if u.line > theta.line]
        return (not after), after

    def records_for(self, theta, predicate="ruled"):
        wire = self.wire_of(theta)
        anc = self._cone(wire, forward=False)
        desc = self._cone(wire, forward=True)
        out = {"ancestors": [], "descendants": [],
               "exempt_control_compare": [], "exempt_measured": [],
               "exempt_live_after": [], "after_theta": []}
        measured_before = set()
        for ins in self.instrs:
            if ins.line >= theta.line:
                break
            if ins.callee and MEASURE_RE.match(ins.callee):
                measured_before.update(ins.operands)
        for key, cone in (("ancestors", anc), ("descendants", desc)):
            for v in sorted(cone):
                d = self.by_res.get(v)
                if d is None or v not in self.tainted:
                    continue
                if not (self.is_producer(d)
                        or (predicate == "ruled"
                            and self.is_alloc_record(d, wire))):
                    continue
                # A record only exists AT the theta if it was already produced.
                # This mirrors census 0.1's lowered-IR `live_at` (mint index <
                # theta index) and is what separates `d = q + 1` BEFORE a chained
                # theta from the same op scheduled AFTER it (already
                # `declineStaleRecordOps`'s own case, and NOT an M-A site).
                if d.line >= theta.line:
                    out["after_theta"].append(v)
                    continue
                if v in measured_before:
                    out["exempt_measured"].append(v)
                    continue
                if predicate != "ruled" and self.control_position_compare(d):
                    out["exempt_control_compare"].append(v)
                    continue
                if predicate == "ruled":
                    dead, after = self.dead_at(v, theta)
                    if not dead:
                        out["exempt_live_after"].append(
                            f"{v} used at {', '.join(after[:3])}")
                        continue
                out[key].append(f"{v}={d.opcode}"
                                + (f"@{d.callee}" if d.callee else ""))
        return out


def analyse(path, predicate="ruled"):
    """-> {'fns': [...], 'chained': n, 'anc': n, 'desc': n}"""
    res = {"fns": [], "chained": 0, "anc": 0, "desc": 0, "exempt_compare": 0,
           "exempt_measured": 0, "exempt_live_after": 0, "after_theta": 0,
           "predicate": predicate}
    for name, instrs in parse_functions(path).items():
        fa = FnAnalysis(name, instrs)
        for t in fa.chained_thetas():
            r = fa.records_for(t, predicate)
            res["chained"] += 1
            res["anc"] += len(r["ancestors"])
            res["desc"] += len(r["descendants"])
            res["exempt_compare"] += len(r["exempt_control_compare"])
            res["exempt_measured"] += len(r["exempt_measured"])
            res["exempt_live_after"] += len(r["exempt_live_after"])
            res["after_theta"] += len(r["after_theta"])
            res["fns"].append({"fn": name, "line": t.line,
                               "wire_arg": t.operands[0] if t.operands else None,
                               **r})
    return res


def _validate(repo=cc.REPO, predicate="ruled"):
    """Compare this model with census 0.1's lowered-IR census over the POSITIVE
    lit corpus, on TWO verdicts. Prints every disagreement."""
    import census_01_guard_population as c01
    agree = dis_src_only = dis_low_only = 0
    rows = []
    h_agree, h_rows = 0, []
    for name, path, neg in cc.lit_fixtures(repo):
        rc, out, _ = cc.lower_ll(path, repo)
        if rc != 0 or out is None:
            continue
        low = c01.analyse_module(out, name)
        low_hit = bool(low["thetas"])
        src = analyse(path, predicate)
        src_hit = src["chained"] > 0
        if low_hit == src_hit:
            agree += 1
        elif src_hit:
            dis_src_only += 1
            rows.append(("source-only", name, src["chained"], 0))
        else:
            dis_low_only += 1
            rows.append(("lowered-only", name, 0, len(low["thetas"])))
        # ---- verdict 2: the RECORD-HIT verdict under `predicate` -----------
        low_rec = any(t["by_predicate"][predicate]["ancestor_hits"]
                      or t["by_predicate"][predicate]["descendant_hits"]
                      for t in low["thetas"])
        src_rec = (src["anc"] + src["desc"]) > 0
        if low_rec == src_rec:
            h_agree += 1
        else:
            h_rows.append(("source-only" if src_rec else "lowered-only", name,
                           src["anc"] + src["desc"],
                           sum(len(t["by_predicate"][predicate]["ancestor_hits"])
                               + len(t["by_predicate"][predicate]
                                     ["descendant_hits"])
                               for t in low["thetas"])))
    print("validate 1/2 — chained-theta verdict, positive lit corpus:")
    print(f"  agree            : {agree}")
    print(f"  source-IR only   : {dis_src_only}")
    print(f"  lowered-IR only  : {dis_low_only}")
    for kind, name, a, b in sorted(rows):
        print(f"    {kind:13s} {name} (src={a} low={b})")
    print(f"validate 2/2 — RECORD-HIT verdict under `{predicate}`:")
    print(f"  agree            : {h_agree}")
    print(f"  disagree         : {len(h_rows)}")
    for kind, name, a, b in sorted(h_rows):
        print(f"    {kind:13s} {name} (src_hits={a} low_hits={b})")
    return 0


if __name__ == "__main__":
    if "--validate" in sys.argv:
        pred = "ruled"
        if "--predicate" in sys.argv:
            pred = sys.argv[sys.argv.index("--predicate") + 1]
        sys.exit(_validate(predicate=pred))
    print(__doc__)
