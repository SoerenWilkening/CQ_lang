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
SUBJ = os.environ.get("SUBJ", "r4f")
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


# ================================================================ bd vsfp ROUND 4 entries
R4 = V / "r4a"
R4B = V / "r4b"
R4C = V / "r4c"

# Clones whose body must contain NO template call (bd sqjq): name -> clone symbol prefix.
CLONE_NOTPL = {}

# ---- bd 1xp9 (Rule-13 r3B F-XB-1): a freed φ read as a condition seed
E("lowering_volatile_arm_fold_cascade_classical.ll", V / "fx/r4_u5.s1.ll", "main",
  """; lowering_volatile_arm_fold_cascade_classical.ll — ACCEPT with the fenv-intended twin's stream
; (bd test_C_libtooling-1xp9; bd vsfp Rule-13 r3B F-XB-1, probe `u5`). A CRASH REGRESSION PIN.
;
; Two cascaded diamonds on CLASSICAL conditions; the second branch's condition is an `i1` φ
; in the first diamond's merge. The fenv store erasure empties both arms and `deleteDeadCones`
; folds both in one pass. Fold 1 left that φ single-entry, `MergeBlockIntoPredecessor` then
; ERASED it (`FoldSingleEntryPHINodes`), and rounds 2–3 held the condition seeds as raw
; `Value *` — the recursive call read freed memory: SIGSEGV (exit 139) on a program the ORACLE
; compiles (3 trace lines). Round 4 holds the seeds as `WeakTrackingVH`, which follow the φ's
; RAUW to its replacement. The stream is the program without the volatile lines (r4b `u5T`).
; The second RUN line runs the TEST allocator in `nofree` mode, where a freed instruction's
; parent pointer is null, so the round-3 read crashes deterministically (measured, exit 139;
; under the system allocator the UAF is a lottery — r3B saw 139, a lit run of `u3` passed).
{src}""", twin="u5T", src="r4_u5")

E("lowering_volatile_arm_fold_cascade_tainted.ll", V / "fx/r4_u3.s1.ll", "main",
  """; lowering_volatile_arm_fold_cascade_tainted.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-1xp9; r3B probe `u3`). The first condition is TAINTED (`q > 3`), so the
; cascade crosses a quantum branch; rounds 2–3 segfaulted (exit 139), the ORACLE declined
; (`value-arm swap-route`). The twin (`u3T`, volatile lines removed) compiles, and so does this.
; ⚠ Under the system allocator round 3 PASSED this file in one lit run — a use-after-free is a
; lottery — so the second RUN line runs the deterministic test allocator (`nofree`: exit 139 on
; the round-3 objects, measured).
{src}""", twin="u3T", src="r4_u3")

E("lowering_volatile_arm_fold_cascade_merge_phi.ll", V / "fx/r4_u4.s1.ll", "main",
  """; lowering_volatile_arm_fold_cascade_merge_phi.ll — DECLINE with the twin's string (bd
; test_C_libtooling-1xp9; r3B probe `u4`, the second merge has a φ). Round 3 segfaulted (exit
; 139), round 2 aborted in the verifier (exit 134). Now a clean decline with the SAME string as
; the fenv-intended twin `u4T` (`control flow under quantum control` — a pre-existing shape the
; control layer does not claim), which is what a crash regression pin must show: rc 1, not 139.
{src}""", kind="decline", src="r4_u4")

E("lowering_volatile_arm_fold_cascade_live_condition.ll", V / "fx/r4_u6.s1.ll", "main",
  """; lowering_volatile_arm_fold_cascade_live_condition.ll — ACCEPT with the fenv-intended twin's
; stream (bd test_C_libtooling-1xp9; bd vsfp round 4 — why the seeds must TRACK, not merely be weak).
;
; The `u3` cascade (first condition `q > 3` tainted) plus a second merge value `r = c ? 5 : 9` that
; is MEASURED, so the first condition stays LIVE. Fold 1 turns both first-merge φs into selects;
; the second condition `p` is one of them and fold 2 makes it dead. The block merge then RAUWs the
; φ `p` to its select and erases it. A `WeakTrackingVH` seed follows that RAUW and the recursion
; deletes the dead select; a plain `WeakVH` (r3B's "just skip deleted seeds") would null, the
; condition's own seed would stop at the live compare, and the dead select would survive as a 4.4
; select on a TAINTED condition — a which-path rail nobody discharges (measured on mutant U2: one
; extra template rail, TRACE-DIFF vs the twin). Round 3 crashed here (exit 139); the ORACLE
; declined. The twin `u6T` (volatile lines removed) is the stream; the second RUN line is the nofree pin.
{src}""", twin="u6T", src="r4_u6")

E("lowering_volatile_globalfold_cascade.ll", R4B / "u1.ll", "main",
  """; lowering_volatile_globalfold_cascade.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-1xp9; r3B probe `u1`, the GLOBAL-fold path; hand-written IR).
;
; Two never-stored internal volatile globals (`@KB`, an `i1` read as the second branch's
; condition φ; `@K2`, the second merge's φ incoming). Round 3 segfaulted (exit 139). Round 4:
; the tracked seed follows the first φ to its replacement and the fold goes through the folder
; (`simplifySelectInst`), so `select %c, i1 true, i1 false` IS `%c` and the second φ becomes
; `select %c, 5, 9` — the twin `u1T.ll`. Without the folder the logical select would be a 4.4
; data select's condition, which that grammar refuses (an over-decline; oracle declined too).
; The second RUN line is the deterministic use-after-free pin (test allocator, `nofree`).
;""", twin="u1T")

E("lowering_volatile_alloca_fold_cascade_uaf.ll", R4B / "u2.ll", "main",
  """; lowering_volatile_alloca_fold_cascade_uaf.ll — ACCEPT with the twin's stream, under the plain
; allocator AND under the deterministic test allocator (bd test_C_libtooling-1xp9; r3B probe
; `u2`, the ALLOCA-fold path; hand-written IR).
;
; On rounds 2–3 this was SILENT UB under the system allocator (exit 0 — the freed φ's bytes
; happened to read back) and SIGSEGV under Guard Malloc. The `%debugalloc-cq-opt` driver makes
; that deterministic: under `CQ_OPT_DEBUG_ALLOC=nofree` a freed instruction's parent pointer is
; null, and the round-3 objects crash on it every time (measured, exit 139, also under `lifo`).
; The second RUN line is therefore the use-after-free pin; the first pins the twin's stream.
;""", twin="u2T")

# ---- bd f061 (Rule-13 r3A F-XA-1): the neutralising constant takes the CALLEE parameter's type
for key, spell in (("fpfloatb", "`float`"), ("f1b", "`double` (operand `x * 2.0`, later measured)"),
                   ("fplongdb", "`long double` (x86_fp80)"), ("f2b", "`double` with an fp RESULT (`__cq_q_hf_11`)")):
    E(f"spec_accept_phantom_arg_read_fp_slot_{key[:-1]}.ll", R4 / f"{key}.ll", "main",
      f"""; spec_accept_phantom_arg_read_fp_slot_{key[:-1]}.ll — ACCEPT (bd test_C_libtooling-f061; bd vsfp
; Rule-13 r3A F-XA-1, probe `{key}`; hand-written IR, a branch-only read of the dead slot).
;
; An fp-ABI clone's dead slot, {spell}. After `retargetSite` the clone parameter is an `i32`
; HANDLE while the caller's operand is still the stock fp value; round 3 neutralised the slot
; with a null of the OPERAND's type — `float 0.0` into an `i32` parameter — and the in-process
; verifier ABORTED (exit 134). The constant now takes the callee parameter's type. The ORACLE
; compiles this trace-identical to the hand-inlined twin; so does round 4, except `f2b`, whose
; spec-QUANTUM clone keeps the oracle's Bennett copy-out around the twin's product (the same
; stream as the ORACLE — the known clone copy-out divergence, net unitary unchanged).
;""")

# ---- bd sqjq (Rule-13 r3A F-XA-2): the dead-slot record made EXACT for the built clone
SQ = (("a2_chain", "`t = a*3; if (t > 3) {}` — the flatten deletes the compare, not its chain"),
      ("a3_width", "the same, with the slot's operand a `_Bool` register (a 32-bit template on a 1-qubit handle)"),
      ("a1_icmp", "a dead compare on the slot"),
      ("a1_xorself", "a dead `xor` chain on the slot"),
      ("n5_nested", "the slot forwarded as `a + 1` into an INNER clone's dead slot"),
      ("g1c", "`-g`: the same chain with debug records"),
      ("n6_nested_arg", "the parameter passed STRAIGHT into an INNER clone's dead slot (round 4's own probe)"))
INNER_ZERO = {"spec_accept_phantom_arg_read_exact_record_n5_nested.ll",
              "spec_accept_phantom_arg_read_exact_record_n6_nested_arg.ll"}
for key, spell in SQ:
    fname = f"spec_accept_phantom_arg_read_exact_record_{key}.ll"
    CLONE_NOTPL[fname] = "__cq_q_h_"
    E(fname, (R4C if key == "n6_nested_arg" else R4) / f"{key}.ll", "main",
      f"""; {fname} — ACCEPT, and the CLONE reads nothing the caller did not pass (bd
; test_C_libtooling-sqjq; bd vsfp Rule-13 r3A F-XA-2, probe `{key}`; hand-written IR).
;
; The callee's read of the dead slot is {spell}. `buildClone` records the slot dead (no live root
; reads it) but round 3 left the dead instruction standing, so the clone's `lowerOps` lowered
; it: once the caller's slot was neutralised to `0`, the clone operated on runtime handle h0 —
; a register the caller never passed. Round 4 deletes the dead cone of every recorded-dead
; parameter right after taking the record (an inner clone call inherits the dead slot as a
; constant — `rewriteRecordedDeadSlotUse`, the one spelling of that rewrite). The CLONE prefix
; pins that `@__cq_q_h_*` contains no template call at all (and, for the nested probes, that the
; inner clone call passes `0` in the inherited dead slot); the main CHECKs pin the caller's
; stream (TRACE-IDENT with the hand-inlined twin, measured).
;""")

# ---- bd xh17 (Rule-13 r3A F-XA-3): a `%out` read by a later select's controlled copy
E("spec_accept_phantom_arg_read_copy_source_reader.ll", R4 / "e2b.ll", "main",
  """; spec_accept_phantom_arg_read_copy_source_reader.ll — ACCEPT, trace-identical to the twin (bd
; test_C_libtooling-xh17; bd vsfp Rule-13 r3A F-XA-3, probe `e2b`; hand-written IR).
;
; `r = b ? x : 7; t = h(r, m)` (a branch-only read — a phantom) and `s = b2 ? r : 3`. `r`'s 4.4
; `%out` is read in the SOURCE slot of the second select's `cqrt_copy_i32_controlled`. Rounds 1–3
; counted every runtime call on an emitter rail as construction, so `%out` looked unread and the
; module declined `quantum argument to a parameter the lifted callee never reads`; the ORACLE
; compiles it trace-identical to the twin (27 lines). Only the DESTINATION slot of a basis copy
; is now construction (`isCopyDestination`).
;""")

# ---- owner ruling 2026-09-26 (bd memory owner-ruling-volatile-unreachable-object-2026-09-26)
E("lowering_reject_volatile_global_section.ll", V / "fx/r4_sect.s1.ll", "main",
  """; lowering_reject_volatile_global_section.ll — DECLINE (owner ruling 2026-09-26: a volatile access
; is unobservable iff the object is unreachable from outside the program — internal or local,
; never written, address never escaping, no atomic access, and NOT in a named section or at an
; absolute/fixed address).
;
; `static volatile int K __attribute__((section("__DATA,__mmio"))) = 7; if (q > 3) (void)K;` — a
; named section is how MMIO is declared, so the read is observable and must NOT be folded. Round 3
; folded it (the conjunct was missing) and ACCEPTED the program by deleting the quantum branch;
; round 4 refuses a global with `hasSection()`, the volatile read stays in the tainted arm, and the
; module declines exactly as on the ORACLE. The same program without the section
; (`spec_accept_dropped_arg_volatile_global_*`, `lowering_volatile_globalfold_equal_phi.ll`) folds.
{src}""", kind="decline", src="r4_sect")

E("lowering_reject_volatile_global_absolute_symbol.ll", R4C / "abs.ll", "main",
  """; lowering_reject_volatile_global_absolute_symbol.ll — DECLINE (owner ruling 2026-09-26; see
; lowering_reject_volatile_global_section.ll). The same program with `!absolute_symbol` on the
; internal global instead of a section: an object at a fixed address. Round 3 folded it and
; accepted; round 4 refuses it and declines as the ORACLE does. Hand-written IR (C has no spelling
; that puts `!absolute_symbol` on an internal definition).
;""", kind="decline")
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
