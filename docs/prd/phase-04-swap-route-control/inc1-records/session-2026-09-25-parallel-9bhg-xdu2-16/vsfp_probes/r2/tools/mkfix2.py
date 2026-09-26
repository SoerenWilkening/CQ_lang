#!/usr/bin/env python3
"""mkfix2.py — bd vsfp ROUND 2 lit fixtures. For every entry: build (or take) the module,
run the SUBJECT binary (`bin/cq-opt.<SUBJ>`, env SUBJ, default r2d) with the drop census
lever, and write a fixture whose CHECKs are DERIVED from that output:
  * ACCEPT: the ordered sequence of every call in the quantum function (SSA names
    wildcarded, constants kept — so a dropped `i32 noundef 0` and every angle are
    pinned), a NEG prefix forbidding each callee the ORACLE emitted there and the
    subject does not (the round-1 defect's own symbols), and a DROP/NODROP prefix over
    the census lines.
  * DECLINE: the census lines and the error string, character for character.
Every ACCEPT entry names its twin; the twin's trace equality is checked separately
(pp.sh) and recorded in TRACK_VSFP, never assumed here."""
import os
import pathlib
import re
import subprocess
import sys

V = pathlib.Path(__file__).parent
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
T = W / "ir-pass/test"
SUBJ = os.environ.get("SUBJ", "r2g")
BIN = V / f"bin/cq-opt.{SUBJ}"
ORA = V.parent / "frozen/cq-opt.main_aee8"

REGEN = """; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>"""
REGEN1 = """; Regenerate: clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o <body>"""


def src_block(k):
    c = (V / "fx" / f"{k}.c").read_text().strip().split("\n")
    out = [";", "; Caller TU (clang -O1 -include CQ.h):"] + [";   " + l for l in c]
    libs = [V / "fx" / f"{k}.lib{'' if i == 0 else i + 1}.c" for i in range(6)]
    libs = [l for l in libs if l.exists()]
    for i, lib in enumerate(libs):
        tag = "" if len(libs) == 1 else f" {i + 1}"
        out += [f"; Library TU{tag} (plain C, no CQ.h):"] + [";   " + l for l in lib.read_text().strip().split("\n")]
    if len(libs) == 1:
        out += [";", REGEN, ";"]
    elif libs:
        out += [";", "; Regenerate: as tests/e2e/run_slice_multi.sh, one `clang -O1` per library TU, then", f";   llvm-link -S caller.ll lib.ll lib2.ll … lib{len(libs)}.ll -o <this file's body>", ";"]
    else:
        out += [";", REGEN1, ";"]
    return "\n".join(out)


def run(binp, path):
    r = subprocess.run([str(binp), "-passes=cq-lowering", "-S", str(path), "-o", "-"],
                       capture_output=True, text=True, env=dict(os.environ, CQ_DEADARG_DBG="1"))
    return r.returncode, r.stdout, r.stderr


def fn_body(ir, fn):
    m = re.search(r"^define [^\n]*@" + re.escape(fn) + r"\(.*?^}\n", ir, re.S | re.M)
    return m.group(0) if m else ""


def calls(body):
    out = []
    for l in body.splitlines():
        m = re.search(r"\bcall (.*)$", l)
        if not m:
            continue
        txt = m.group(1)
        txt = re.sub(r"\s*#\d+$", "", txt)
        txt = re.sub(r"\s*, !dbg !\d+$", "", txt)
        out.append(txt)
    return out


def pat(txt):
    txt = re.sub(r"\{\{", "{ {", txt)
    return re.sub(r"%[\w.]+", "%{{[a-zA-Z0-9_.]+}}", txt)


def callee(txt):
    m = re.search(r"@([\w.]+)\(", txt)
    return m.group(1) if m else None


ENTRIES = []


def E(name, module, fn, text, twin=None, kind="accept", src=None):
    ENTRIES.append(dict(name=name, module=module, fn=fn, text=text, twin=twin, kind=kind, src=src))


def body_of_fixture(fname):
    s = (T / fname).read_text()
    i = s.index("; ModuleID") if "; ModuleID" in s else s.index("declare ")
    return s[i:]


def mkll(name, text):
    p = V / "ll" / f"{name}.ll"
    p.write_text(text)
    return p


# ---------------------------------------------------------------- hand modules
th = body_of_fixture("spec_accept_phantom_arg_read_theta_source.ll")
H_OLD = """define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3)
  store volatile i32 %0, ptr %3, align 4, !tbaa !10
  %4 = add nsw i32 %1, 1
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3)
  ret i32 %4
}"""
H_NEW = """define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp sgt i32 %0, 3   ; a BRANCH-ONLY read: live in @h, removed by the CLONE's own flatten
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %vsfp.r = add nsw i32 %1, 1
  ret i32 %vsfp.r
}"""
if H_OLD in th:
    mkll("theta_source_branch", th.replace(H_OLD, H_NEW))
thi = body_of_fixture("spec_accept_phantom_arg_read_theta_source_inplace_mc.ll")
if H_OLD in thi:
    mkll("theta_source_inplace_branch", thi.replace(H_OLD, H_NEW))
rng = (V / "ll/bk_range_sel.ll").read_text()
mkll("range_attr_stripped", rng)
mkll("string_attr_opaque", rng.replace("i32 range(i32 1, 100) %a", 'i32 "cq.probe.opaque" %a'))

BRANCH_NOTE = """; ⚠ WHY HAND-WRITTEN IR (bd vsfp round 2). The callee's only read of `a` is a
; BRANCH-ONLY one — an empty diamond on `a > 3`. The pass's liveness predicate has no
; control dependence (`DeadValueLiveness.h` LIMITS), so `a` is LIVE in the ORIGINAL
; `@h` and the dead-argument drop (both slots) does NOT fire; the CLONE's own control
; flatten then removes the branch, and `buildClone` RECORDS slot 0 dead
; (`taint.SpecDeadArgMask`). That is the one route by which a phantom read still
; reaches the post-`specialize()` backstop. It is IR-only: `clang -O1` deletes an
; empty diamond in the library TU. Round 1 spelled this file with `volatile int z = a;`,
; which bd vsfp r1B F-VB-3 showed is erased by the MODULE fenv pre-pass on the
; ORIGINAL callee — predictable pre-emission, and since round 2 the drop's slot B
; predicts it (see `spec_reject_phantom_arg_read_volatile_callee.ll`, now an accept)."""

# ---------------------------------------------------------------- rewrites of round-1 own fixtures
E("spec_reject_phantom_arg_read_volatile_callee.ll", V / "fx/derived_exempt_negative.s1.ll", "main",
  """; spec_reject_phantom_arg_read_volatile_callee.ll — ⚠ NOW AN ACCEPT with the fenv-intended
; twin's stream (bd test_C_libtooling-vsfp ROUND 2; bd a8q5; Rule-13 r1B F-VB-3). The name
; is kept on purpose: round 1's record, both Rule-13 reviews and bd a8q5 cite it.
;
; Round 1 pinned this as the backstop's one C-reachable customer and said the CLONE
; pipeline erased the callee's volatile store. r1B measured that FALSE: the MODULE fenv
; pre-pass `eraseDeadVolatileScalarStores` erases it on the ORIGINAL callee, before
; `detectSpecializations` — predictable, and the round-1 decline cost the program its
; fenv meaning (the coherent twin). Round 2 asks the drop again right after the fenv
; stages (SLOT B), so `h(p, m)` becomes `h(0, m)`, the dead 4.4 select is deleted, and
; the stream is the twin's (`volatile int z = a;` removed, `int t = m + 1;`):
; alloc; Ry(.5); Ry(.7); measure — no `%out` rail, no copy. Twin: fx/volatile_charT.
{src}""", twin="volatile_charT", src="derived_exempt_negative")

E("spec_accept_phantom_arg_read_theta_source.ll", V / "ll/theta_source_branch.ll", "main",
  """; spec_accept_phantom_arg_read_theta_source.ll — ACCEPT (bd test_C_libtooling-vsfp — the
; backstop's ONE exemption; r2A_9bhg probe `cv9S`). Re-spelled in ROUND 2, see below.
;
; The built clone never reads its parameter 0 (the specializer RECORDED it dead), but the
; operand is `q`, a `cq_theta` RESULT — the user's own register. The phantom read neither
; mints nor keeps alive a rail the hand-inlined twin lacks (`cq_theta` is a liveness root;
; nothing discharges a user register) — r2A's harmless quadrant, validated on nine shapes
; by Rule-13 r1B (mutant B2 load-bearing on all nine). `declinePhantomCloneArgReads`
; exempts a `taint.ThetaCalls` member by MEMBERSHIP; delete the exemption and this file
; declines. The drop does not fire (NODROP): `a` is live in the original `@h`.
;
""" + BRANCH_NOTE + "\n;\n; Caller: `int q = cq_theta(m, .5); int t = h(q, m); return cq_measure(t) * 100 + cq_measure(q);`\n;")

E("spec_accept_phantom_arg_read_theta_source_inplace_mc.ll", V / "ll/theta_source_inplace_branch.ll", "main",
  """; spec_accept_phantom_arg_read_theta_source_inplace_mc.ll — ACCEPT, IN PLACE like the
; hand-inlined twin (bd test_C_libtooling-vsfp / bd hgwx — M-C `priorUseIsSettled` arm
; (d0)). Re-spelled in ROUND 2, see below.
;
; `t = h(q, m)` passes `q` only in a slot the specializer RECORDED dead in the built clone,
; so arm (d0) — asked by CALLING `isRecordedDeadSlot`, the one owner of "slot unread" —
; settles the call as a prior user of `q`, and `u = t + q` lowers IN PLACE
; (`cqrt_addc_i32(q, t)`), as in its twin (`int t = m + 1;`). Without (d0) (mutant D1) it
; lowers OUT of place and the later Ry on `u` dephases `q` (warned, lyyf-(B)).
;
""" + BRANCH_NOTE + "\n;\n; Caller: `int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r);`\n;")

E("spec_reject_phantom_arg_read_range_attr.ll", V / "ll/string_attr_opaque.ll", "main",
  """; spec_reject_phantom_arg_read_range_attr.ll — DECLINE (bd test_C_libtooling-vsfp, the
; phantom-read BACKSTOP; hand-written IR). ⚠ Round 2: the name is kept, the attribute is not.
;
; Round 1 defeated the drop with `range(i32 1, 100)` on the dead parameter. Round 2 mirrors
; LLVM DAE, which STRIPS `range`/`nofpclass` when it rewrites an argument, so that slot is
; now dropped (pinned by spec_accept_dropped_arg_range_attr_stripped.ll). What the drop
; still refuses is an attribute it does not know — here a STRING attribute on the
; parameter — so the phantom operand (a 4.4 bool-select `%out`, which the twin never
; computes) reaches `specialize()`, the clone records slot 0 dead, and the backstop
; declines rather than keep that which-path rail alive across the later Ry on `b`.
;""", kind="decline")

E("spec_accept_dropped_arg_range_attr_stripped.ll", V / "ll/range_attr_stripped.ll", "main",
  """; spec_accept_dropped_arg_range_attr_stripped.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2; hand-written IR, round 1's range_attr module).
;
; The dead parameter carries `range(i32 1, 100)`. A null constant violates it (a poison
; argument), so LLVM DAE strips the attribute when it rewrites the argument, and so does
; the drop: `range` is removed from the callee's parameter AND the call site, then the
; argument becomes `i32 0` and the dead 4.4 select is deleted. The CHECKs pin both the
; stream and that no `range` survives on `@h`'s first parameter.
;""", twin=None)

E("spec_accept_dropped_arg_dead_pure_call.ll", V / "fx/dead_pure_call.s1.ll", "main",
  """; spec_accept_dropped_arg_dead_pure_call.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2). Renamed from round 1's `…_pure_call_kept.ll`,
; whose rule ("the cone walk never deletes a call") is RETIRED — it was a syntactic answer
; (L5) and it kept a dead clone call whose out rail stayed entangled with `q`.
;
; `p = k2(q, 3)` and `s = k3(m)` feed only `h`'s dead slot. `k2`'s body is side-effect-free
; and terminating, so the liveness predicate calls the call DEAD and it is deleted — as
; `-O1` deletes it once `k2` is visible (the twin's module, llvm-linked, loses it too).
; `k3` WRITES A GLOBAL: its call is a ROOT and is KEPT, result unused. The twin keeps it.
{src}""", twin="dead_pure_callT", src="dead_pure_call")

E("spec_accept_dropped_arg_classical_call_arm.ll", V / "fx/dead_classical_call_arm.s1.ll", "main",
  """; spec_accept_dropped_arg_classical_call_arm.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-vsfp; r2A `s3d`, the ROUND-2 6.5 `%out` member). Renamed from round 1's
; `spec_reject_…`: round 1 declined here, like the hand-inlined twin in which `K` stays
; in another TU.
;
; `r` (a 6.5 classical-call-arm merge) feeds only `h`'s dead slot. The drop replaces it by
; `0`; the φ is dead; round 2 then sees `K(m)` as a DEAD call — `K` is `const`, visible
; after llvm-link — deletes it and folds the emptied diamond (SimplifyCFG's empty-arm
; fold). The program is the twin with `K` visible (`int u = m + 1;`, no `r`): Ry(.5)
; Ry(.7) on one register. On the oracle it accepted DEPHASED (the round-2 `%out` rail kept
; alive by the phantom read). The twin that keeps `K` opaque in another TU (r2A `s3dT`)
; now ACCEPTS with the identical trace on this binary as well, measured — the round-1
; decline was an over-decline for this program.
{src}""", twin="dead_classical_call_armT", src="dead_classical_call_arm")

E("spec_accept_dropped_arg_nested_fixpoint.ll", V / "fx/nested4.s1.ll", "main",
  """; spec_accept_dropped_arg_nested_fixpoint.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2 — the drop's FIXPOINT, four TUs deep).
;
; `o4 -> m4 -> n4 -> i4`, one per TU, each forwarding `a` to the next; only `i4` ignores it.
; Each drop makes the next caller's parameter dead, so the chain needs FOUR turns. The
; drop's two slots give two turns for free, which is why the 2-link
; `spec_accept_dropped_arg_nested.ll` could not pin the fixpoint (measured: the one-turn
; mutant passed it). Here the one-turn mutant leaves `o4(p, m)` reading the 4.4 `%out`,
; and the phantom-read backstop declines it. The four census lines, innermost first,
; pin the order. Twin: `int t = ((m + 1 - 1) + 3) * 2 + m;` — no gate but the two Ry.
{src}""", src="nested4")

E("spec_accept_dropped_arg_dead_read_ir.ll", V / "ll/dead_read_ir.ll", "main",
  """; spec_accept_dropped_arg_dead_read_ir.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-vsfp ROUND 2 — LIVENESS, not `use_empty()`; hand-written IR).
;
; `@h` computes `a * 3 + k` and discards it: its parameter HAS USES, all DEAD. Round 1 asked
; `use_empty()` and did not drop, so the 4.4 select `p` stayed alive for a callee that
; never reads it (round 1's own re-spelled fixtures used exactly this dead `mul` to keep a
; parameter "used"). The liveness predicate calls `a` dead, the call becomes `h(0, m)`, the
; select is deleted, and the stream is the program with `h` inlined as `-O1` would
; (`t = m + 1`, no `p`): alloc; Ry(.5); Ry(.7); measure. IR-only: `clang -O1` deletes the
; dead `mul` in the library TU; the fenv residue (`volatile char z = a;`) is the
; C-reachable member of the same class (spec_accept_dropped_arg_volatile_char.ll).
;""")

E("spec_accept_dropped_arg_loop_callee_kept.ll", V / "ll/loop_callee_kept.ll", "main",
  """; spec_accept_dropped_arg_loop_callee_kept.ll — ACCEPT, the call KEPT (bd
; test_C_libtooling-vsfp ROUND 2 — the liveness predicate's `bodyIsSideEffectFree`
; refuses a CYCLIC body; hand-written IR).
;
; `@spin` ignores `a` (dropped: `spin(0, m)`) and loops on `k` with no memory effect and no
; `mustprogress` — it may legitimately never terminate, so an unused call to it is NOT
; dead. The predicate's body rule admits only an ACYCLIC body (every execution terminates);
; with that conjunct removed (mutant L5) the call is deleted and a possibly non-terminating
; program is made to terminate. `-O1` would keep it too without `mustprogress`.
;""")

E("spec_accept_phantom_arg_read_classical_slot.ll", V / "ll/classical_dead_slot.ll", "main",
  """; spec_accept_phantom_arg_read_classical_slot.ll — ACCEPT, the oracle's verdict and stream
; (bd test_C_libtooling-vsfp ROUND 2 — the backstop asks about QUANTUM operands only;
; hand-written IR).
;
; `@h` reads `a` and `b` only through one empty diamond: both are live in `@h`, both dead
; in its clone, and the specializer records both slots dead. Slot 0 gets `q` (a `cq_theta`
; result — exempt) and slot 1 `m * 5`, a CLASSICAL value read by nothing else. A classical
; value kept alive by a phantom read costs nothing — no rail, no entanglement — so the
; backstop must not decline it (mutant B4, which drops the "quantum" conjunct, does).
;""")

E("lowering_volatile_scalar_promoted_residue.ll", V / "fx/local_promoted_residue.s1.ll", "main",
  """; lowering_volatile_scalar_promoted_residue.ll — ACCEPT with the fenv-intended twin's stream
; (bd test_C_libtooling-vsfp ROUND 2 / bd a8q5 `v29c`'s mechanism with no call at all).
;
; `volatile char z = q; char w = z; … (w - w)`: `clang -O1` folds `w - w` but keeps the
; volatile load, bd zco4's promotion then replaces the load by the stored `trunc q`, and
; that `trunc` is DEAD. Before round 2 it was lowered as a template product and left DIRTY
; across the later Ry on `q` (warned, lyyf-(B); trace-different from the twin on the
; oracle). The promotion stage now deletes its residue with the ONE liveness predicate
; (mutant V2 restores the dirty product): alloc; Ry(.5); Ry(.7); measure.
{src}""", twin="local_promoted_residueT", src="local_promoted_residue")

E("spec_accept_dropped_arg_reserved_marker_kept.ll", V / "ll/reserved_marker_kept.ll", "main",
  """; spec_accept_dropped_arg_reserved_marker_kept.ll — ACCEPT, the reserved-namespace call KEPT
; (bd test_C_libtooling-vsfp ROUND 2 — a liveness ROOT by the reserved name; hand-written IR).
;
; The module DEFINES `@__cq_marker` with an empty body, so its unused void call is
; side-effect-free by attributes AND by body — and the dead-call seeding would delete it.
; Calls into the project's reserved namespaces (`cq_`, `__cq_`, `cqrt_`) are roots
; whatever their body says: the name is used only to ADD a root, never to allow a
; deletion. The first spelling of the rule sat after the side-effect branch and never
; fired for a defined attribute-less callee — measured on this module, the call was
; deleted; that is why the identity roots are now asked first. (The dead 4.4 select `%p`
; is lowered: a dead tainted value in the INPUT is not a seed of any round-2 deletion,
; and `clang -O1` never leaves one.)
;""")

E("spec_accept_dropped_arg_musttail_kept.ll", V / "ll/musttail_kept.ll", "main",
  """; spec_accept_dropped_arg_musttail_kept.ll — ACCEPT, no argument dropped (bd
; test_C_libtooling-vsfp ROUND 2 — the drop's `musttail` refusal; hand-written IR).
;
; `@g` forwards `a` to `@h` by a `musttail` call and `@h` ignores it. The drop refuses a
; `musttail` SITE, so `@h(%a, %k)` is kept, `a` stays live in `@g`, and `main`'s `g(%m, …)`
; is kept too (NODROP). ⚠ This pins a CONSERVATISM, not a soundness property: a constant
; argument changes no signature, and LLVM's DAE refuses `musttail` only where it would
; change one. It is the mirror the reviewers asked for (bd vsfp r1A F-VA-1), pinned so
; that relaxing it is a decision (mutant R7 flips it).
;""")

E("spec_accept_dropped_arg_varargs_kept.ll", V / "ll/varargs_kept.ll", "main",
  """; spec_accept_dropped_arg_varargs_kept.ll — ACCEPT, no argument dropped (bd
; test_C_libtooling-vsfp ROUND 2 — the drop's variadic-callee refusal; hand-written IR).
;
; `@hv(i32 %a, ...)` ignores its fixed parameter. The drop refuses a variadic callee — STRICTER
; than LLVM DAE, which does rewrite a vararg callee's fixed parameters at its call sites — so
; `hv(%m, …)` is kept (NODROP). A conservatism pin, like the `musttail` one (mutant R12).
;""")

# ---------------------------------------------------------------- new: bd ctz4 (naked)
E("spec_accept_dropped_arg_naked_kept.ll", V / "fx/naked_kept.s1.ll", "main",
  """; spec_accept_dropped_arg_naked_kept.ll — ACCEPT, the call UNCHANGED (bd
; test_C_libtooling-ctz4, bd vsfp Rule-13 r1A F-VA-1 `naked1`).
;
; `ident` is `naked`: its asm reads the argument REGISTER, so its IR parameter has no use.
; LLVM DAE refuses `naked`; round 1's drop did not, rewrote `ident(m * 3)` to `ident(0)`
; and the program printed `ident=0` at exit 0 — a CLASSICAL miscompile inside a quantum
; program, since the drop is taint-agnostic. The drop now mirrors DAE's preconditions
; (`dropEligibleCallee`); the call keeps `m * 3` and no drop happens (NODROP).
{src}""", src="naked_kept")

E("spec_reject_dropped_arg_naked_quantum.ll", V / "fx/naked_quantum.s1.ll", "main",
  """; spec_reject_dropped_arg_naked_quantum.ll — DECLINE, the oracle's verdict (bd
; test_C_libtooling-ctz4, bd vsfp Rule-13 r1A F-VA-1 `naked2`).
;
; `ident(q)` with `q` quantum and a `naked` callee. The oracle declines at the specializer
; (inline assembly cannot be lifted) — correct. Round 1's drop rewrote the argument to `0`
; first, so the call stopped being a Phase-6 site and the module ACCEPTED at exit 0 with the
; asm receiving 0. With DAE's `naked` precondition mirrored the drop leaves the call alone
; and the verdict is the oracle's again; the census line must be absent.
{src}""", kind="decline", src="naked_quantum")

# ---------------------------------------------------------------- new: bd m1gi (dead intrinsics)
for nm, key, idiom, probe in (("smax", "dead_smax", "`p > n ? p : n` (llvm.smax)", "prov1"),
                              ("abs", "dead_abs", "`__builtin_abs(p)` (llvm.abs)", "bint2"),
                              ("ctpop", "dead_ctpop", "`__builtin_popcount(q)` (llvm.ctpop)", "ctlz2")):
    E(f"spec_accept_dropped_arg_dead_intrinsic_{nm}.ll", V / f"fx/{key}.s1.ll", "f" if nm == "smax" else "main",
      f"""; spec_accept_dropped_arg_dead_intrinsic_{nm}.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-m1gi; bd vsfp Rule-13 r1A F-VA-2, probe `{probe}`).
;
; The dropped operand is {idiom} of a quantum value. Round 1's cone walk deleted only
; `use_empty()` non-call instructions, so the dead intrinsic call survived and kept the
; quantum value it reads alive — for a 4.4 select, its `%out` which-path rail, entangled
; across the later Ry (silent dephasing). The liveness predicate calls a side-effect-free
; intrinsic with a dead result DEAD, so the whole cone goes, as `-O1` removes it in the
; twin (`int t = m + 1;`).
{{src}}""", twin=f"{key}T", src=key)

# ---------------------------------------------------------------- new: r1A F-VA-3/4
E("spec_accept_dropped_arg_dead_loop_cycle.ll", V / "fx/dead_loop_cycle.s1.ll", "main",
  """; spec_accept_dropped_arg_dead_loop_cycle.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2; Rule-13 r1A F-VA-3, probe `dcar1`).
;
; `s` is a loop-carried register (`if (b0[i]) s -= 7;`) whose only exit use is `h`'s dead
; slot. Its header-φ/latch pair is a CYCLE with no `use_empty()` member, so round 1's walk
; kept it — and its per-trip rails (81 trace lines; twin 50). Liveness has no such blind
; spot: nothing live reads the cycle, so it is dead and deleted, and the rolled loop is the
; twin's.
{src}""", twin="dead_loop_cycleT", src="dead_loop_cycle")

E("spec_accept_dropped_arg_emptied_arm.ll", V / "fx/emptied_arm.s1.ll", "main",
  """; spec_accept_dropped_arg_emptied_arm.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp ROUND 2; Rule-13 r1A F-VA-4, probe `ediam1`).
;
; `if (q > 3) p = 100 / n;` with `p` feeding only `h`'s dead slot. `-O1` keeps the branch
; (`sdiv` is not speculatable). Once `p`'s φ and the `sdiv` are deleted the arm is EMPTY;
; round 1 left an empty diamond on a quantum condition (`control flow under quantum
; control`, the twin accepts). `deleteDeadCones` now folds an arm it emptied into its
; merge (SimplifyCFG's empty-arm fold): no branch, no compare, the twin's stream.
{src}""", twin="emptied_armT", src="emptied_arm")

E("spec_accept_dropped_arg_emptied_arm_phi.ll", V / "fx/emptied_arm_phi.s1.ll", "main",
  """; spec_accept_dropped_arg_emptied_arm_phi.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp ROUND 2; Rule-13 r1A F-VA-4, probe `ediam2`).
;
; As `…_emptied_arm.ll`, but the merge keeps a LIVE φ (`s`, measured). The emptied arm is
; folded by SimplifyCFG's two-entry-φ fold: the φ becomes `select q > 3, 5, 7` and the
; blocks merge, which is what `-O1` gave the twin — whose 4.4 data select then lowers as
; usual. Round 1 declined `value-arm swap-route`; an intermediate round-2 build that folded
; the branch but left the merge block declined `classical-condition phi` (measured).
{src}""", twin="emptied_arm_phiT", src="emptied_arm_phi")

# ---------------------------------------------------------------- new: r1A F-VA-5 (M10)
E("spec_accept_dropped_arg_reserved_symbol_angle.ll", V / "fx/reserved_symbol_angle.s1.ll", "main",
  """; spec_accept_dropped_arg_reserved_symbol_angle.ll — ACCEPT, the oracle's stream (bd
; test_C_libtooling-vsfp; Rule-13 r1A F-VA-5, probe `resv2`).
;
; A library TU DEFINES the reserved front-end symbol `cq_theta_si32` with an UNUSED angle
; parameter. The drop skips every front-end intrinsic SITE by MEMBERSHIP
; (`taint.ThetaCalls`), so the user's runtime angle survives: `cqrt_ry_i32(h, <atof>)`.
; Round 1's record called that skip "a belt" (mutant M10 "equivalent"); r1A measured it
; LOAD-BEARING — without it the angle became `0.0`. This file is the pin. (That the pass
; accepts a user definition of a reserved symbol is pre-existing and out of scope.)
{src}""", src="reserved_symbol_angle")

E("spec_accept_dropped_arg_reserved_symbol_theta_kept.ll", V / "fx/reserved_symbol_theta_kept.s1.ll", "main",
  """; spec_accept_dropped_arg_reserved_symbol_theta_kept.ll — ACCEPT: the user's gate is KEPT (bd
; test_C_libtooling-vsfp ROUND 2; CLAUDE.md §4h/§4i — a user gate is never a stage's to
; erase, whatever its use count).
;
; A library TU DEFINES `cq_theta_si32` as `return x;`, so `clang -O1` infers
; `memory(none) nounwind willreturn` for it — by ATTRIBUTES the call is side-effect-free.
; After the drop `q` feeds nothing, so the call is dead by data flow. It stays, and it
; lowers to its alloc + Ry, because the liveness predicate makes every front-end
; intrinsic SITE a root by MEMBERSHIP (`taint.ThetaCalls`), never by name or attribute.
; Without that root the dead-cone deletion erases the user's rotation (a vanishing gate).
{src}""", src="reserved_symbol_theta_kept")

E("spec_accept_phantom_arg_read_kept_alive.ll", V / "ll/kept_alive.ll", "main",
  """; spec_accept_phantom_arg_read_kept_alive.ll — ACCEPT, the oracle's verdict (bd
; test_C_libtooling-vsfp ROUND 2; Rule-13 r1B F-VB-4's class; hand-written IR).
;
; `h`'s only read of `a` is branch-only (live in `@h`, removed by the clone's flatten),
; so the specializer records slot 0 dead and the call `h(p, m)` is a phantom read of `p`,
; a 4.4 `%out` rail. But `p` is ALSO measured: it is kept alive by a reader of its own,
; the hand-inlined twin (`t = m + 1`) computes and measures the same rail, and the phantom
; read adds nothing. The backstop asks "does anything else keep this value alive?" before
; declining; round 1 did not, and declined this program (an over-decline — the oracle
; accepts it). The stream is the twin's plus the clone call, which emits no gate.
;""")

# ---------------------------------------------------------------- new: bd a8q5 (volatile residue)
for key, spell, probe in (("volatile_char", "`volatile char z = a;` (a dead `trunc`)", "v15vc"),
                          ("volatile_derived", "`volatile int z = a * 3;` (a dead `mul`)", "v02"),
                          ("volatile_double", "`volatile double z = a;` (a dead `sitofp`)", "v15vd"),
                          ("volatile_two_stores", "`volatile int z = a; z = a + 1;` (two stores)", "v26v2s"),
                          ("volatile_promoted_residue", "`volatile char z = a; char w = z; … (w - w)` (promotion residue)", "v29c")):
    E(f"spec_accept_dropped_arg_{key}.ll", V / f"fx/{key}.s1.ll", "main",
      f"""; spec_accept_dropped_arg_{key}.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-a8q5; bd vsfp Rule-13 r1B F-VB-1, probe `{probe}`).
;
; The callee is {spell}. The fenv stages erase the store (and, for the loaded
; spelling, promote the local), and round 1 left the stored value's cone behind: the
; parameter still "had a use", the drop and the backstop both asked `use_empty()` and both
; stayed silent, and the caller's 4.4 `%out` which-path rail stayed alive across the later
; Ry on `b` — silent dephasing, byte-identical on the oracle. Round 2: the fenv stages
; delete their dead cone (the ONE liveness predicate), the drop is asked again right after
; them (SLOT B), and the stream is the program without the volatile line
; (fx/volatile_charT): alloc; Ry(.5); Ry(.7); measure.
{{src}}""", twin="volatile_charT", src=key)

for key, spell, stage in (("volatile_arm_const", "`if (a > 3) { volatile int z = 1; }`", "the dead-store erasure"),
                          ("volatile_arm_value", "`if (a > 3) { volatile int z = a; }`", "the dead-store erasure"),
                          ("volatile_arm_constfold", "`if (a > 3) { volatile int z = 1; w = z; }` (`w - w` folded)", "the volatile const-alloca fold")):
    E(f"spec_accept_dropped_arg_{key}.ll", V / f"fx/{key}.s1.ll", "main",
      f"""; spec_accept_dropped_arg_{key}.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-vsfp ROUND 2 — an arm the FENV STAGE empties).
;
; The callee's only read of `a` is the condition of {spell}. {stage[0].upper() + stage[1:]}
; empties the arm; the empty diamond then kept `a` LIVE in `@h` (a branch condition is a
; liveness root) and the program reached the phantom-read backstop (measured on an
; intermediate round-2 build: `quantum argument to a parameter the lifted callee never
; reads`; the oracle accepted it DEPHASED — the 4.4 `%out` rail copying `b` kept alive).
; The fenv stages now hand the blocks they emptied to `deleteDeadCones`, whose empty-arm
; fold removes the diamond and its compare; `a` is dead, slot B drops it, and the stream
; is the program without the arm (fx/volatile_charT): alloc; Ry(.5); Ry(.7); measure.
{{src}}""", twin="volatile_charT", src=key)

E("spec_accept_dropped_arg_volatile_round2_arm.ll", V / "fx/volatile_round2_arm.s1.ll", "main",
  """; spec_accept_dropped_arg_volatile_round2_arm.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-a8q5; bd vsfp Rule-13 r1B F-VB-1, probe `v20` — r2A `s3d` with a
; `volatile char` callee). The phantom operand is the ROUND-2 6.5 `%out`. The drop's slot B
; removes it before any emission; the dead `K(m)` and its emptied diamond go too.
{src}""", twin="volatile_round2_armT", src="volatile_round2_arm")

E("spec_accept_dropped_arg_volatile_hgwx.ll", V / "fx/volatile_hgwx.s1.ll", "main",
  """; spec_accept_dropped_arg_volatile_hgwx.ll — ACCEPT, IN PLACE like the twin (bd
; test_C_libtooling-hgwx / a8q5; bd vsfp Rule-13 r1B F-VB-1 "(d0) blind", probe `v30`).
;
; Round 1: the clone Bennett-reversed the dead `trunc`, so its parameter "had a use", arm
; (d0) did not apply, and `u = t + q` lowered OUT of place — the later Ry on `u` dephased
; `q` (warned). Round 2: the drop's slot B rewrites the call to `h(0, m)` before emission,
; so no prior reader of `q` remains and M-C lowers in place (`cqrt_addc_i32`).
{src}""", twin="volatile_hgwxT", src="volatile_hgwx")

E("spec_accept_dropped_arg_volatile_promoted_bool.ll", V / "fx/volatile_promoted_bool.s1.ll", "main",
  """; spec_accept_dropped_arg_volatile_promoted_bool.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-vsfp ROUND 2; Rule-13 r1B F-VB-4, probe `v12`).
;
; C promotes `_Bool b` to `int` at the call, so the operand is a `zext` of a quantum
; register, not a `cq_theta` result. Round 1's backstop declined it although no later gate
; touches `b` (the oracle compiled a correct distribution) — an over-decline. The drop's
; slot B now removes the read before emission, so the backstop never sees it and the
; stream is the twin's (`int t = m + 1;`).
{src}""", twin="volatile_promoted_boolT", src="volatile_promoted_bool")

E("spec_accept_dropped_arg_volatile_stale_attrs.ll", V / "fx/volatile_stale_attrs.s1.ll", "main",
  """; spec_accept_dropped_arg_volatile_stale_attrs.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-vsfp ROUND 2; Rule-13 r1B probe `v16`).
;
; `h(q, p, m)` reads `p` (spec-QUANTUM clone) and only volatile-stores `q`; `t` is unused.
; After slot B drops `q`, the call is DEAD — but `-O1` inferred `h`'s attributes from the
; volatile store (`memory(inaccessiblemem: readwrite)`, no `willreturn`), which are STALE
; once the fenv stage erased it. The liveness predicate asks the callee's BODY
; (`bodyIsSideEffectFree`: acyclic, no call, no memory write), calls the call dead and
; deletes it; round 1 left the clone's out rail entangled with `p` (16 trace lines; twin 8).
{src}""", twin="volatile_stale_attrsT", src="volatile_stale_attrs")

# ---------------------------------------------------------------- new: bd qjoc (no clone)
E("lowering_volatile_scalar_deadstore_select.ll", V / "fx/qjoc_select.s1.ll", "main",
  """; lowering_volatile_scalar_deadstore_select.ll — ACCEPT with the fenv-intended twin's stream
; (bd test_C_libtooling-qjoc; bd vsfp Rule-13 r1B F-VB-7). No clone, no call.
;
; `int p = b ? 9 : 4; volatile int z = p;` — the fenv stage erased the store and (before
; round 2) nothing else: the dead 4.4 select was still claimed, its `%out` which-path rail
; minted and never discharged, SILENT dephasing of the later Ry on `b` (15 trace lines;
; twin 4). The stage now deletes the stored value's dead cone itself.
{src}""", twin="qjoc_selectT", src="qjoc_select")

E("lowering_volatile_scalar_deadstore_template.ll", V / "fx/qjoc_template.s1.ll", "main",
  """; lowering_volatile_scalar_deadstore_template.ll — ACCEPT with the fenv-intended twin's stream
; (bd test_C_libtooling-qjoc; bd vsfp Rule-13 r1B F-VB-7 `qjoc_tpl`). No clone.
;
; `int p = q * 3; volatile int z = p;` — before round 2 the dead template product was left
; DIRTY across the later Ry on `q` (warned, lyyf-(B)), falsifying "lowered, uncomputed
; and freed — harmless". The stage now deletes it: no `cq_template_mul`.
{src}""", twin="qjoc_templateT", src="qjoc_template")

# ---------------------------------------------------------------- new: an unused clone call
E("spec_accept_dead_clone_call.ll", V / "fx/dead_clone_call.s1.ll", "main",
  """; spec_accept_dead_clone_call.ll — ACCEPT with the twin's stream (bd test_C_libtooling-vsfp
; ROUND 2). No argument is dropped here: `t = h(q, p, m)` READS both quantum arguments and
; `t` is simply unused. `-O1` cannot delete the call in the caller TU (it cannot see `h`),
; so the oracle built a spec-quantum clone whose OUT rail stayed entangled with `p` across
; the later Ry on it (warned; 17 lines vs twin 5). `h`'s body is side-effect-free, so the
; call is DEAD under the liveness predicate and the drop's dead-call seeding deletes it —
; the program `-O1` gives when both TUs are visible.
{src}""", twin="dead_clone_callT", src="dead_clone_call")


# ---------------------------------------------------------------- write
def write(e):
    mod = pathlib.Path(e["module"])
    rc, out, err = run(BIN, mod)
    drops = [l for l in err.splitlines() if l.startswith("CQ_DEADARG_DBG:")]
    hdr = e["text"]
    if e["src"]:
        hdr = hdr.replace("{src}", src_block(e["src"]))
    hdr = hdr.rstrip("\n")
    body = mod.read_text()
    lines = [hdr]
    if e["kind"] == "decline":
        if rc == 0:
            raise SystemExit(f"{e['name']}: expected a decline, got an accept")
        errl = [l for l in err.splitlines() if "error:" in l][0]
        msg = errl.split(": ", 2)[-1] if "in function" not in errl else errl[errl.index("in function"):]
        lines += [";", "; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \\",
                  "; RUN:   | %filecheck %s"]
        for d in drops:
            lines.append(f"; CHECK: {d}")
        if not drops:
            lines.append("; CHECK-NOT: CQ_DEADARG_DBG")
        lines.append(f"; CHECK: error: {{{{.*}}}}{msg.split('): ', 1)[-1] if '): ' in msg else msg}")
    else:
        if rc != 0:
            raise SystemExit(f"{e['name']}: expected an accept, got: {err}")
        fb = fn_body(out, e["fn"])
        cs = calls(fb)
        orc, oout, oerr = run(ORA, mod)
        neg = []
        if orc == 0:
            ob = fn_body(oout, e["fn"])
            mine = {callee(c) for c in cs}
            neg = sorted({callee(c) for c in calls(ob)} - mine - {None})
        lines += [";", "; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err",
                  "; RUN: %filecheck %s < %t.cqd0.ll"]
        if neg:
            lines.append("; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll")
        lines.append("; RUN: %filecheck %s --check-prefix=" + ("DROP < %t.err" if drops else "NODROP --allow-empty < %t.err"))
        lines.append(";")
        lines.append("; The ordered call sequence of @" + e["fn"] + " (derived from the lowered module; SSA names")
        lines.append("; wildcarded, constants — every dropped `0` and every angle — kept):")
        lines.append("; Between consecutive matches NO other runtime/clone call may appear, so the")
        lines.append("; runtime stream is pinned EXACTLY, not as a subsequence.")
        NOT = "; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}"
        lines.append(f"; CHECK-LABEL: define {{{{.*}}}}@{e['fn']}(")
        lines.append(NOT)
        for c in cs:
            lines.append(f"; CHECK: call {pat(c)}")
            lines.append(NOT)
        lines.append("; CHECK: ret i32")
        if neg:
            lines.append(";")
            lines.append("; Callees the ORACLE emitted in @" + e["fn"] + " and this lowering must not:")
            lines.append(f"; NEG-LABEL: define {{{{.*}}}}@{e['fn']}(")
            for n in neg:
                lines.append(f"; NEG-NOT: @{n}(")
            lines.append("; NEG: ret i32")
        if drops:
            for d in drops:
                lines.append(f"; DROP: {d}")
        else:
            lines.append("; NODROP-NOT: CQ_DEADARG_DBG")
        if e["name"] == "spec_accept_dropped_arg_range_attr_stripped.ll":
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=ATTR < %t.cqd0.ll")
            lines.append("; No `range` survives on `@h`'s parameter (it precedes @main) nor at the call:")
            lines.append("; ATTR-NOT: range(i32 1, 100)")
            lines.append("; ATTR: call i32 @h(i32 0, i32 %m)")
    (T / e["name"]).write_text("\n".join(lines) + "\n\n" + body)
    print("wrote", e["name"], e["kind"], f"calls={len(fb) if e['kind']!='decline' else '-'}", f"drops={len(drops)}")


only = set(sys.argv[1:])
for e in ENTRIES:
    if only and e["name"] not in only:
        continue
    write(e)
