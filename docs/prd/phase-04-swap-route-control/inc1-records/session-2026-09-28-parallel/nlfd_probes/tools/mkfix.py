#!/usr/bin/env python3
"""mkfix.py — the lit fixtures of bd nlfd / bd ev3m (session 2026-09-28).

For every entry: run the SUBJECT `cq-opt` (this worktree's build) on the module with
the drop census lever (CQ_DEADARG_DBG=1) and write a fixture whose CHECKs are DERIVED
from that output (the vsfp mkfix convention):
  * ACCEPT: for each (prefix, function) the ordered sequence of every call in the
    function (SSA names wildcarded, constants — every dropped `0`, every angle — kept),
    with a CHECK-NOT between consecutive matches so the runtime/clone stream is pinned
    EXACTLY; the census lines (DROP) or their absence (NODROP); extra literal lines.
  * DECLINE: the census lines' absence and the error string, character for character.
The CHECKs are derived only AFTER the subject's trace was measured equal to the
hand-inlined twin's (tools/pairs.py; TRACK_NLFD_EV3M.md records each pair) — they pin
the twin's stream, not whatever the subject emits.
Run with `--check` to only re-derive and diff against the committed files."""
import os
import pathlib
import re
import subprocess
import sys

V = pathlib.Path(__file__).resolve().parent.parent
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295")
T = W / "ir-pass/test"
BIN = W / "build/ir-pass/cq-opt"
SRC = V / "src"

STREAM_NOT = "call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}"


def run(path):
    r = subprocess.run([str(BIN), "-passes=cq-lowering", "-S", str(path), "-o", "-"],
                       capture_output=True, text=True, env=dict(os.environ, CQ_DEADARG_DBG="1"))
    return r.returncode, r.stdout, r.stderr


def fn_body(ir, fn):
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}\n", ir, re.S | re.M)
    if not m:
        raise SystemExit(f"no function @{fn}")
    return m.group(0)


def calls(body):
    out = []
    for l in body.splitlines():
        m = re.search(r"\bcall (.*)$", l)
        if not m:
            continue
        txt = re.sub(r"\s*#\d+$", "", m.group(1))
        txt = re.sub(r"\s*, !dbg !\d+$", "", txt)
        out.append(txt)
    return out


def pat(txt):
    txt = txt.replace("{{", "{ {")
    return re.sub(r"%[\w.]+", "%{{[a-zA-Z0-9_.]+}}", txt)


def stream(prefix, ir, fn):
    b = fn_body(ir, fn)
    head = b.splitlines()[0]
    name = re.search(r"@([\w.]+)\(", head).group(1)
    lines = [f"; {prefix}-LABEL: define {{{{.*}}}}@{name}("]
    for c in calls(b):
        lines.append(f"; {prefix}-NOT: {STREAM_NOT}")
        lines.append(f"; {prefix}: call {pat(c)}")
    lines.append(f"; {prefix}-NOT: {STREAM_NOT}")
    lines.append(f"; {prefix}: ret ")
    return lines


def body_text(p):
    s = p.read_text()
    for key in ("; ModuleID", "target datalayout"):
        if key in s:
            return s[s.index(key):]
    return s


ENTRIES = []


def E(**kw):
    ENTRIES.append(kw)


MSG = "cq specialization: quantum argument to a parameter the lifted callee never reads"

# ── bd nlfd ────────────────────────────────────────────────────────────────────
E(name="spec_accept_phantom_arg_read_unread_scalar_inner_arg", module=SRC / "sa1.ll",
  kind="accept", streams=[("CHECK", "main"), ("CLONE", "__cq_q_h_01")], drop=False,
  twin="r5 `mtT` (`r = m + 1;`)",
  head="""ACCEPT with the hand-inlined twin's stream (bd test_C_libtooling-nlfd; bd vsfp
; Rule-13 r6 F-R6-1, probe `sa1.ll`; IR-only).
;
; r5's `mtN` stage-1 IR (r2B's `k19` main: `p = q * 3` feeds `h`'s slot 0 and the phase oracle
; `(p ^ q) == 10`; `h(a,k){ return h2(a,k); }`; `h2` reads `a` only in a volatile-fold empty
; diamond) with ONE edit: `h2`'s parameter 0 carries a string attribute (`"cq.probe.opaque"`),
; so the inner slot is NOT null-safe (`nullSafeSlot`'s allowlist is a WRITE policy). `h2`'s
; clone records slot 0 dead. On `main` 9a230646 the liveness call-slot rule counted the inner
; slot as a READ, so `h`'s clone parameter became LIVE one level up, `main`'s (null-safe)
; phantom slot was never neutralised, and the spine left `p`'s rail DIRTY across `Ry(0.7)` —
; bd tzfa's wrong unitary (exit 0, one lyyf-(B) warning, 12 trace lines; the twin has 14).
; Since bd nlfd an ARGUMENT in an unread scalar slot (`isUnreadScalarSlot`: recorded dead,
; int/fp) is not a read: the record calls `h`'s parameter dead and `main`'s slot is `0`. The
; CLONE prefix pins that `h`'s clone still forwards its (dead) parameter `%0` into the inner
; slot — the IR operand of a not-null-safe slot is never rewritten — and holds no template.
; RED on the ORACLE (measured). Remove the Argument clause of the call-slot rule and it goes
; red (mutant N1).""")

E(name="spec_accept_phantom_arg_read_unread_scalar_inner_arg_range",
  module=SRC / "cells/x_arg_range.ll", kind="accept",
  streams=[("CHECK", "main")], drop=False, twin="`r = m + 1;` (cells/x_arg_rangeT.ll)",
  extra=["; STRIP-LABEL: define internal i32 @__cq_q_h_01(",
         "; STRIP: call i32 @__cq_q_h2_01(i32 noundef %a, i32 noundef %k)",
         "; STRIP-LABEL: define internal i32 @__cq_q_h2_01(i32 noundef \"cq.probe.opaque\" %x, i32 noundef %k)"],
  extra_prefix="STRIP",
  head="""ACCEPT, and the value constraints of the inner slot STRIPPED (bd
; test_C_libtooling-nlfd; hand-written IR).
;
; `sa1`'s shape (k19 main; `h(a,k){ return h2(a,k); }`; `h2` reads `x` only in an empty
; diamond, so only the CLONE's flatten kills the read) with `range(i32 1, 100)` on the inner
; slot — on `h2`'s parameter AND on `h`'s call site — beside the string attribute that makes
; the slot not null-safe. The record calls `h`'s parameter dead (bd nlfd), so `main`'s slot
; is neutralised to `0` and that `0` reaches the inner slot THROUGH the parameter: a `range`
; that excludes it would make the argument poison, and with `noundef` immediate UB. So
; `buildClone` strips `range`/`nofpclass` there (`stripUnreadSlotValueConstraints` — the
; strip of the one rewrite, without the write). The STRIP prefix pins both sites in the
; clones; the original `h`/`h2` keep theirs. RED on the ORACLE (measured: TRACE-DIFF, the
; range kept). Remove the strip and the STRIP lines go red (mutant N3).""")

E(name="spec_reject_phantom_arg_read_unread_scalar_inner_inst",
  module=SRC / "cells/i_inst_tc_nn_cd.ll", kind="decline", fn="__cq_q_h_01",
  head="""DECLINE (bd test_C_libtooling-nlfd — the rule of
; `resolvePhantomCloneArgReads` step 1, one clone level down; hand-written IR).
;
; k19 main; `h(a,k){ t = a * 5; return h2(t, k); }`; `h2`'s parameter 0 carries a string
; attribute (NOT null-safe) and is read only in an empty diamond (dead only after the CLONE's
; flatten). The inner slot's operand is an INSTRUCTION: it cannot be deleted while the call
; uses it, and the rewrite may not null the slot, so `%t` survives and keeps `h`'s HANDLE
; parameter live — while nothing observes `%t`'s value (`SlotReads::Value` calls the
; parameter dead). Both accepts are wrong: keeping `main`'s slot is bd tzfa's phantom read
; (what the ORACLE does: exit 0, a warning, `p`'s rail dirty across the Ry — TRACE-DIFF vs
; the twin), and neutralising it would lower `t = a * 5` on runtime handle 0 (bd sqjq). The
; hand-inlined twin (`r = m + 1`) ACCEPTS: this is a knowing over-decline of an IR-only shape
; (clang-19 -O1 emits only allowlisted attributes on an int parameter). Retirement trigger:
; the day `nullSafeSlot` admits string/unknown attributes, this module accepts.""")

E(name="spec_reject_phantom_arg_read_unread_scalar_inner_inst_musttail",
  module=SRC / "cells/i_inst_mt_nn_pd.ll", kind="decline", fn="__cq_q_h_01",
  head="""DECLINE (bd test_C_libtooling-nlfd; hand-written IR) — the
; `musttail` × never-read cell of the nlfd/ev3m table.
;
; k19 main; `h(a,k){ t = a * 5; musttail return h2(t, k); }`; `h2` never reads parameter 0,
; which carries a string attribute (NOT null-safe), so the pre-specialize drop leaves the slot
; alone and `h2`'s clone records it dead. The inner slot's operand is a surviving quantum
; INSTRUCTION that keeps `h`'s handle parameter alive for nothing — the same fence as
; `…_inner_inst.ll`. On the ORACLE this module ABORTED (exit 134: the `musttail` call inside
; `h`'s clone was no longer followed by `ret` once `t`'s template was Bennett-reversed after
; it). The fence speaks inside `buildClone` right after the record — before the Bennett wrap
; emits anything — so this file declines with or without the same track's clone-`musttail`
; demotion (commit C).""")

E(name="spec_reject_phantom_arg_read_unread_scalar_outer_nn",
  module=SRC / "cells/x_outer_nn.ll", kind="decline", fn="main",
  head="""DECLINE at MODULE level (bd test_C_libtooling-nlfd's L2 consequence;
; hand-written IR).
;
; `sa1`'s shape with the OUTER slot not null-safe too: `h(a "opaque", k){ return h2(a, k); }`,
; `h2(x "opaque", k)` reading `x` only in an empty diamond. Since bd nlfd the record calls
; `h`'s parameter dead (an ARGUMENT in an unread scalar slot is not a read), so
; `resolvePhantomCloneArgReads` step 1 now SEES `main`'s slot: recorded dead, not null-safe,
; quantum operand — its existing decline. On the ORACLE the record called the parameter live
; and the module ACCEPTED with bd tzfa's phantom read (TRACE-DIFF vs the twin `r = m + 1`, `p`
; dirty across the Ry, warned). A wrong accept became the module-level rule's (IR-only,
; knowing) over-decline; the twin accepts. Retirement trigger: `nullSafeSlot` admitting
; string attributes (owner question, TRACK_NLFD_EV3M.md §15 Q1).""")

E(name="spec_accept_phantom_arg_read_unread_scalar_inner_inst_live",
  module=SRC / "cells/x_inst_live.ll", kind="accept",
  streams=[("CLONE", "__cq_q_h_01")], drop=False,
  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})"],
  twin="`r = m + 1 + 5p` (cells/x_inst_liveT.ll) — TRACE-DIFF on the ORACLE too (bd rhk5's shape: the clone call sits between `p` and its phase consumer)",
  head="""ACCEPT — the PRECISION control of bd test_C_libtooling-nlfd's fence
; (hand-written IR).
;
; As `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll`, except that `h` ALSO returns
; `t` (`return h2(t, k) + t;`): the instruction in the not-null-safe dead slot is read by a
; live root, so its VALUE is observed, `h`'s parameter is live under `SlotReads::Value` too,
; and the fence must NOT fire. The CLONE stream is pinned (the ORACLE's, byte-for-byte,
; measured); `main`'s is DELIBERATELY NOT: it is not the hand-inlined twin's — the clone call
; sits between `p = q * 3` and its phase consumer, which is bd rhk5 (P1, warned, PRE-EXISTING:
; one lyyf-(B) warning, `p`'s rail left dirty across the Ry, on the ORACLE and here alike) — and
; a golden of a known-wrong stream would bless it (bd jlf8's lesson). `main` is pinned only to
; keep the clone call's operand (the slot is live). Fence without its value-liveness test →
; this file declines (mutant N4).""")

E(name="spec_accept_phantom_arg_read_unread_scalar_nested_arg",
  module=SRC / "cells/x_nested_arg.ll", kind="accept",
  streams=[("CHECK", "main"), ("CLONE", "__cq_q_g_01"), ("CLONE2", "__cq_q_h_01")], drop=False,
  twin="`r = m + 1;` (cells/x_nested_argT.ll)",
  head="""ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-nlfd; hand-written IR) — TWO not-null-safe levels.
;
; k19 main calls `g(p, m)`; `g(a,k){ return h(a,k); }`; `h`'s parameter 0 carries a string
; attribute and `h(a,k){ return h2(a,k); }`; `h2`'s parameter 0 carries one too and is read
; only in an empty diamond. Each level forwards an ARGUMENT into an unread scalar slot: `h`'s
; clone records its parameter dead (bd nlfd), so `g`'s call into it is again an Argument in an
; unread scalar slot and `g`'s clone records ITS parameter dead, and `main`'s slot — the only
; null-safe one — is neutralised. RED on the ORACLE (TRACE-DIFF, `p` dirty across the Ry).""")

E(name="spec_accept_phantom_arg_read_unread_scalar_classical_inst",
  module=SRC / "cells/x_classical_inst.ll", kind="accept",
  streams=[("CLONE", "__cq_q_h_001")], drop=False,
  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_001(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})"],
  twin="`r = m + p` (cells/x_classical_instT.ll) — TRACE-DIFF on the ORACLE too (bd rhk5's shape)",
  head="""ACCEPT — the HANDLE-MASK control of bd test_C_libtooling-nlfd's
; fence (hand-written IR).
;
; `h(a, c, k){ t = c + 1; return h2(t, a, k); }` with `c` CLASSICAL (`main` passes `m`) and
; `h2` never reading parameter 0, which carries a string attribute. The surviving `t` keeps
; `c` live for nothing — but `c` is not a handle, `main`'s operand there is classical, and a
; classical phantom read costs nothing (no rail, no spine), so the fence (which asks only the
; clone's HANDLE parameters) must not fire. The CLONE stream is pinned (the ORACLE's,
; byte-for-byte, measured); `main`'s is deliberately NOT, for `…_inst_live.ll`'s reason (bd
; rhk5's pre-existing warned divergence from the twin). Fence without the handle-mask
; conjunct → this file declines (mutant N5).""")

# ── bd ev3m ────────────────────────────────────────────────────────────────────
E(name="spec_accept_dropped_arg_musttail_return", module=SRC / "mm1.s1.ll", kind="accept",
  streams=[("CHECK", "w")], drop=True, twin="r6 `mmT` (`return k + 1;`)",
  csrc=[SRC / "mm1.c", SRC / "mm1.lib.c"],
  head="""ACCEPT with the hand-inlined twin's stream (bd test_C_libtooling-ev3m;
; r6 probe `mm1`; 2 TUs llvm-linked as tests/e2e/run_slice_multi.sh does).
;
; A quantum function `w` ends in `__attribute__((musttail)) return h2(p, k);` where `h2`
; reads `p` only in a volatile-fold empty diamond (dead once the fenv stages ran: slot B). On
; `main` 9a230646 the dead-argument drop refused a `musttail` SITE as a POLICY conservatism,
; so the call kept reading `p`, its result stayed (conservatively) tainted, and `main` declined
; `cq taint escape: quantum value returned across a function boundary` — while the plain-tail
; spelling (`mmN`) and the twin compile. Since bd ev3m a `musttail` site is drop-eligible (a
; constant operand changes no signature, calling convention or ABI attribute): the DROP line
; pins the drop, the CHECK lines the twin's stream, and the call keeps its `musttail`.""",
  extra=["; MT: {{^}}  %{{[0-9]+}} = musttail call i32 @h2(i32 noundef 0, i32 noundef %1)"],
  extra_prefix="MT")

E(name="spec_accept_dropped_arg_musttail_forward_chain", module=SRC / "ev2.s1.ll",
  kind="accept", streams=[("CHECK", "f")], drop=True, twin="`return k + 1;` (ev2T.c)",
  csrc=[SRC / "ev2.c", SRC / "ev2.lib.c"],
  head="""ACCEPT with the hand-inlined twin's stream (bd test_C_libtooling-ev3m;
; 2 TUs) — a `musttail` FORWARDING CHAIN.
;
; `f` (quantum) ends in `musttail return h(p, k)`; `h` musttail-forwards to `h2`, `h2` to
; `h3`, and `h3` reads its first parameter only in a volatile-fold empty diamond. The drop's
; fixpoint walks the chain one site per turn — `h3`'s parameter dead → `h2`'s musttail slot
; `0` → `h2`'s parameter dead → `h`'s → `f`'s — with no signature to keep in step (only
; operands change). On `main` 9a230646 every one of those sites was refused and `main`
; declined at the 3jru return refusal. The DROP lines pin all three drops; the MT lines that
; every rewritten call is still a `musttail` call whose dropped slot is `0`.""",
  extra=["; MT-LABEL: define {{.*}}@f(",
         "; MT: musttail call i32 @h(i32 noundef 0, i32 noundef %1)",
         "; MT-LABEL: define {{.*}}@h2(",
         "; MT: musttail call i32 @h3(i32 noundef 0, i32 noundef %1)",
         "; MT-LABEL: define {{.*}}@h(",
         "; MT: musttail call i32 @h2(i32 noundef 0, i32 noundef %1)"],
  extra_prefix="MT")

E(name="spec_accept_musttail_in_clone_demoted", module=SRC / "mtl.s1.ll", kind="accept",
  streams=[], drop=False,
  twin="its plain-`tail` spelling `mtlN` (byte-identical traces, measured); the hand-inlined twin `mtlT` differs on BOTH (bd rhk5's shape)",
  csrc=[SRC / "mtl.c", SRC / "mtl.lib.c"],
  extra=["; CHECK-LABEL: define {{.*}}@main(",
         "; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})",
         "; CHECK-LABEL: define {{.*}}@h(",
         "; CHECK-NEXT: musttail call i32 @h2(",
         "; CLONE-LABEL: define internal i32 @__cq_q_h_01(",
         "; CLONE-NOT: musttail",
         "; CLONE: call i32 @__cq_q_h2_01(",
         "; CLONE-NOT: musttail",
         "; CLONE: ret i32"],
  extra_prefix="CLONE",
  head="""ACCEPT — a `musttail` call inside a CLONE is demoted (bd
; test_C_libtooling-m5pn, found by the bd nlfd/ev3m cell table, 2026-09-28; 2 TUs, plain C).
;
; `int h(int a, int k){ __attribute__((musttail)) return h2(a, k); }` with `h2` READING `a`
; (`return k + a;`), called with a quantum `p`. `h2`'s clone returns a quantum rail, so `h`'s
; clone's Bennett wrap copies it out AFTER the inner call — and on `main` 9a230646 the
; `musttail` marker cloned from `h` was then no longer followed by `ret`: the verifier ABORTED
; the whole run (exit 134, `musttail call must precede a ret`). `musttail` promises only the
; tail-call lowering, so `stripStaleClassicalAttrs` now demotes it in every clone body (the
; CLONE lines; the ORIGINAL `h`, a non-clone, keeps its `musttail` — the CHECK-NEXT line). The
; trace is then byte-identical to the plain-`tail` spelling's on the ORACLE (measured). ⚠ That
; trace is NOT the hand-inlined twin's: the clone call sits between `p = q * 3` and its phase
; consumer — bd rhk5 (P1, warned, PRE-EXISTING), whose population this demotion GROWS by the
; `musttail` spellings (previously exit 134) — so `main`'s stream is deliberately NOT pinned
; here (a golden of a known-wrong stream would bless it, bd jlf8). See TRACK_NLFD_EV3M.md.
; Remove the demotion and this file ABORTS again (mutant D1).""")


def src_comment(paths):
    out = []
    for p in paths:
        tag = "Library TU (plain C, no CQ.h)" if p.name.endswith(".lib.c") else "Caller TU (clang -O1 -include CQ.h)"
        out.append(f"; {tag}:")
        out += [";   " + l for l in p.read_text().strip().split("\n")]
    out += [";", "; Regenerate (tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19): clang -O1",
            "; -emit-llvm -S the caller with -I<repo>/include -include CQ.h, the library without it,",
            "; then llvm-link -S caller.ll lib.ll."]
    return out


def build(e):
    rc, out, err = run(e["module"])
    L = [f"; {e['name']}.ll — {e['head']}", ";"]
    if e.get("csrc"):
        L += src_comment(e["csrc"]) + [";"]
    if e.get("twin"):
        L += [f"; Twin (trace-compared, tools/pairs.py): {e['twin']}.", ";"]
    if e["kind"] == "decline":
        if rc == 0:
            raise SystemExit(f"{e['name']}: expected a decline, got exit 0")
        L += ["; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \\",
              ";   RUN:   | %filecheck %s".replace(";   RUN", "; RUN"),
              "; CHECK-NOT: CQ_DEADARG_DBG",
              f"; CHECK: error: {{{{.*}}}}in function {e['fn']}{{{{.*}}}}{MSG}"]
    else:
        if rc != 0:
            raise SystemExit(f"{e['name']}: expected an accept, got exit {rc}: {err[:300]}")
        L += ["; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err",
              "; RUN: %filecheck %s < %t.cqd0.ll"]
        prefixes = [p for p, _ in e["streams"] if p != "CHECK"]
        if e.get("extra_prefix"):
            prefixes.append(e["extra_prefix"])
        for p in dict.fromkeys(prefixes):
            L.append(f"; RUN: %filecheck %s --check-prefix={p} < %t.cqd0.ll")
        census = [l for l in err.splitlines() if l.startswith("CQ_DEADARG_DBG")]
        warn = [l for l in err.splitlines() if "warning" in l]
        if e["drop"]:
            if not census:
                raise SystemExit(f"{e['name']}: expected drop census lines")
            L.append("; RUN: %filecheck %s --check-prefix=DROP < %t.err")
        else:
            if census:
                raise SystemExit(f"{e['name']}: unexpected drop census {census}")
            L.append("; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err")
        L += [";", "; The ordered call sequence of each function (derived from the lowered module; SSA",
              "; names wildcarded, constants — every dropped `0` and every angle — kept). Between",
              "; consecutive matches NO other runtime/clone call may appear, so the stream is pinned",
              "; EXACTLY, not as a subsequence."]
        for p, fn in e["streams"]:
            L += stream(p, out, fn)
        if e.get("extra"):
            L += e["extra"]
        if e["drop"]:
            L += [f"; DROP: {c}" for c in census]
            L.append("; DROP-NOT: CQ_DEADARG_DBG")
        else:
            L.append("; NODROP-NOT: CQ_DEADARG_DBG")
        if warn:
            L.append(f"; (stderr also carries {len(warn)} warning line(s) — the ORACLE's, see the header.)")
    L.append("")
    return "\n".join(L) + "\n" + body_text(e["module"])


def main():
    check = "--check" in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    bad = 0
    for e in ENTRIES:
        if only and e["name"] not in only:
            continue
        txt = build(e)
        p = T / (e["name"] + ".ll")
        if check:
            if not p.exists() or p.read_text() != txt:
                print("DIFFERS", p.name)
                bad += 1
        else:
            p.write_text(txt)
            print("wrote", p.name)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
