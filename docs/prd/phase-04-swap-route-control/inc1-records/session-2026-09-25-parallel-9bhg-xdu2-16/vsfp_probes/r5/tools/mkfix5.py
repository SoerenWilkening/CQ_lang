#!/usr/bin/env python3
"""mkfix2.py — bd vsfp ROUND 3 lit fixtures (the round-2 machinery, round-3 entries). For every entry: build (or take) the module,
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
SUBJ = os.environ.get("SUBJ", "r5a")
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


# ================================================================ bd vsfp ROUND 5 entries
CLONE_NOTPL = {}
INNER_ZERO = set()
NONULL = set()

# ---- bd 91k9 (Rule-13 r4A F-YA-1): the one rewrite never nulls a pointer / byval slot
for key, spell, fname in (
    ("r5_bv", "`int h(int a, struct Big s)` (a `byval` struct slot `h` never reads)",
     "spec_accept_phantom_arg_read_byval_slot_kept.ll"),
    ("r5_bvn2", "`h(a, s) { return g(a + 1, s); }` with `g` ignoring its `byval` `s` — the INNER call too",
     "spec_accept_phantom_arg_read_byval_inner_slot_kept.ll"),
    ("r5_pn", "`int h(int a, int p[static 4])` (a `nonnull dereferenceable(16)` pointer slot)",
     "spec_accept_phantom_arg_read_pointer_slot_kept.ll")):
    NONULL.add(fname)
    E(fname, V / f"fx/{key}.s1.ll", "main",
      f"""; {fname} — ACCEPT, the pointer slot KEPT (bd test_C_libtooling-91k9; bd vsfp Rule-13 r4A
; F-YA-1, probe `{key[3:]}`; 2 TUs).
;
; The callee is {spell}. The clone records that slot dead, and rounds 3–4 NEUTRALISED it with
; `Constant::getNullValue(<param type>)` — for a pointer that is `null`: the call became
; `ptr noundef nonnull byval(%struct.Big) align 8 null` and the linked executable SIGSEGVed (exit
; 139; `pn` got `nonnull null` into a `dereferenceable(16)` parameter — immediate UB), while opt,
; the verifier and stage 2b were all clean. The ORACLE compiles it correctly. Since round 5 the
; one rewrite applies the pre-`specialize()` drop's own eligibility (`dropEligibleSlot`: an int/fp
; scalar, no `byval`/`inalloca`/`preallocated`/`returned`/`swifterror`, allowlisted attributes
; only), so a pointer slot is never rewritten — a classical pointer left in a dead slot costs
; nothing (no rail, no spine). The NONULL prefix pins that no pointer argument is `null`; the
; main CHECKs pin the stream (the ORACLE's, byte-identical; the executable exits 5, measured).
{{src}}""", src=key)

# ---- owner ruling 2026-09-26 + qce6 (r4B F-YB-1): the implicit section and the address space
for key, spell, fname in (
    ("r5_s4_pragma_bss", "`#pragma clang section bss=\"__DATA,__mmiob\"` · `static volatile int STATUS;` · `if (q > 3) r = STATUS;`",
     "lowering_reject_volatile_global_pragma_bss.ll"),
    ("r5_s2_pragma_val", "`#pragma clang section data=\"__DATA,__mmio\"` · `static volatile int K = 7;` · `if (q > 3) r = K;`",
     "lowering_reject_volatile_global_pragma_data.ll"),
    ("r5_g_as", "`static volatile int __attribute__((address_space(1))) K = 7;` · `if (q > 3) r = K;`",
     "lowering_reject_volatile_global_addrspace.ll")):
    E(fname, V / f"fx/{key}.s1.ll", "main",
      f"""; {fname} — DECLINE (owner ruling 2026-09-26, bd memory
; `owner-ruling-volatile-unreachable-object-2026-09-26`: a volatile access is unobservable only if
; the object is unreachable from outside the program — never in a named section or at a fixed
; address, the ways MMIO is declared; bd test_C_libtooling-qce6, bd vsfp Rule-13 r4B F-YB-1).
;
; {spell}. `#pragma clang section` does not set the IR `section` field: it attaches the global
; attribute `bss-section`/`data-section`, which the backend honours and `hasSection()` misses, so
; round 4 folded the device read to its INITIALIZER and ACCEPTED the program by deleting the
; quantum branch (exit 0, 2b clean). A NON-DEFAULT ADDRESS SPACE is refused too (owner decision
; 2026-09-27, conservative: device memory on GPU/embedded targets). Round 5 adds
; `G.hasImplicitSection()` and `G.getAddressSpace() != 0`; the volatile read stays in the tainted
; arm and the module declines exactly as its explicit-`section` sibling does on round 4 and 5
; (`value-arm swap-route`; the ORACLE declines this shape earlier, `control flow`).
{{src}}""", kind="decline", src=key)
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
        if e["name"] in NONULL:
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=NONULL < %t.cqd0.ll")
            lines.append(";")
            lines.append("; No pointer argument is neutralised to null (bd 91k9):")
            lines.append("; NONULL-NOT: align {{[0-9]+}} null")
            lines.append("; NONULL-NOT: nonnull null")
        if e["name"] in CLONE_NOTPL:
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll")
            lines.append(";")
            lines.append("; The clone body reads nothing the caller did not pass: no template call (bd sqjq):")
            lines.append(f"; CLONE-LABEL: define {{{{.*}}}}@{CLONE_NOTPL[e['name']]}")
            lines.append("; CLONE-NOT: cq_template_")
            if e["name"] in INNER_ZERO:
                lines.append("; CLONE: call i32 @__cq_q_g_{{[0-9]+}}(i32 noundef 0,")
                lines.append("; CLONE-NOT: cq_template_")
            lines.append("; CLONE: ret ")
        if e["name"] in ("lowering_volatile_alloca_fold_cascade_uaf.ll",
                         "lowering_volatile_arm_fold_cascade_classical.ll",
                         "lowering_volatile_arm_fold_cascade_tainted.ll",
                         "lowering_volatile_arm_fold_cascade_live_condition.ll",
                         "lowering_volatile_globalfold_cascade.ll"):
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.nofree.ll")
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 2,
                         "; RUN: %filecheck %s < %t.nofree.ll")
        if e["name"] == "spec_accept_phantom_arg_read_measured_record.ll":
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=NOWARN --allow-empty < %t.err")
            lines.append("; No lyyf-(B) warning (the twin emits none):")
            lines.append("; NOWARN-NOT: warning:")
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
