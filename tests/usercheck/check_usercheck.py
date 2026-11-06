#!/usr/bin/env python3
"""tests/usercheck (cq-w1-usercheck): `cqcheck user`, the C-oracle check of any program.

Fails on any of:
  program   a small C program (src/*.c) compiled by cqcc -S is not green under `cqcheck user` with its
            entry (exit 0)
  corpus    a CQ_spec example's reference lowered.ll is not green against its .O1.ll, with every entry
            of its drivers.txt line and no quantum flags (default 01, 02, 42, 60, 61, 120, 133 and
            117 at --samples 200; --examples NN_name[:samples]... for others). 60 takes a pointer to
            registers its elements are quantum inputs of, 120's all-zero baseline reads q[-1][1] (outside the domain), 117's big
            groups run out of the matching budget (cq-sujz); 61 calls prep inside a cq_invert region
            and 133's prep_twice overwrites a prep with a NaN angle (cq-mopw)
  unit      in process: the verdict of out-of-budget reasons is undecided (2), never differs; a
            --samples subset keeps classical groups whole, spread over their sizes; cq-mopw: the sites a cq_invert region may reach (61:
            prep's two and invert_theta's second, not invert_call's), and an Ry whose angle is the
            identity still counts as the overwriting prep of a rule-10 un-prep where the C program
            overwrites j's register by an identity reach after j's (cq-q15r, cq-ia96)
  mutant    a wrong lowered module is not rejected (exit 1): built from 01's reference with the Ry's
            angle negated, the add computed before the Ry (only cq_theta substitution sees it), the
            measured rail replaced by its classical input, and an empty body (ret 0); from 60's
            reference, five wrong phases or Ry that only the varied elements behind q expose (cq-rbe6); from
            133's, an un-prep whose overwriting prep is an Ry(NaN) with no C reach (cq-q15r); from
            src/ia96/p.c's (green itself), an un-prep whose Ry(NaN) only another register's earlier
            NaN prep could back (m4, m5; cq-ia96); from src/yzuc's b.c (b_good green) and b2.c, an
            un-prep before an in-place second cq_theta, NaN or finite (b_mut, b2_mut; cq-yzuc); from
            src/leak, a garbage rail live at exit, rejected by CR §6 item 1's leak rule (m1_leak, m1_flat_leak,
            m1_flat_r6_leak, c8_leak, c7_leak; m1_good, m1_flat_good green; cq-tt2j, cq-cuu82)
  rv3       the fixtures of src/rv3 (each a C program, its -O1 module and the pass's lowering) are not green, or a wrong
            lowering of one is not rejected: rule 14's cut of a recursion entered under a predicate, a level early or late,
            with its a_K dropped or a garbage rail beside it (cq-rdsdj); a K-loop behind a function pointer with its a_K
            dropped (cq-2in7d); a classical unpaired longjmp's second return wrong (cq-li3wr); rule 19's host complement with
            the callee swapped (cq-d9vhj); rule 23's final flags rail wrong or with a second rail like it (cq-f8m9n); a
            literal adjacent in the link with other bytes (cq-l1fc8). --rv3 runs this group alone
  error     a missing entry or main(argc, argv) is not an error (exit 2)

Every run goes through the CLI (`python3 -m cqcheck user` from checker/), as cqcc --cq-check runs it.
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CQCC = ROOT / "driver" / "cqcc"
SRC = HERE / "src"
PROGRAMS = [("classical", "poly"), ("qmain", "main"), ("phase", "phase_if"), ("fromptr", "from_ptr"),
            ("fpq", "fpq")]
DEFAULT_EXAMPLES = ["01_add_classical_const", "02_add_quantum_quantum", "42_measure_one_of_two", "60_qft",
                    "61_invert_theta_and_call", "120_multidim_array", "133_state_prep_overwrite",
                    "117_qpe_counting:200"]

failures = []


def fail(test, msg):
    failures.append(test)
    print(f"FAIL {test}: {msg}")


def ok(test, msg=""):
    print(f"ok   {test}" + (f": {msg}" if msg else ""))


def user(o1, low, entry, samples=None, light=False):
    r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(low),
                        "--entry", entry] + (["--samples", str(samples)] if samples else []) + (["--light"] if light else []),
                       cwd=ROOT / "checker", capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr).strip()


def expect(test, status, got):
    code, out = got
    last = out.splitlines()[-1] if out else ""
    if code != status:
        fail(test, f"exit {code}, want {status}:\n{out}")
    else:
        ok(test, last)


def drivers_entries(spec, ex):
    """Every function the example's drivers.txt line calls, in order."""
    for line in (spec / "_tools" / "drivers.txt").read_text().splitlines():
        if line.startswith(ex + "|"):
            calls = [c.split("(")[0].strip() for c in line.split("|")[2].split(";") if c.strip()]
            return list(dict.fromkeys(calls))
    raise SystemExit(f"{ex}: no drivers.txt line")


def unit(spec_root):
    sys.path.insert(0, str(ROOT / "checker"))
    from cqcheck import user as U
    from cqcheck.contracts import DriverSpec
    oob = ("classical arguments ('0', '\"0x00000007\"') (1 samples): the matching of 609 lowered gates to the "
           "C sites exceeded 20000 search nodes without an order-consistent matching")
    for name, reasons, want in (("verdict pass", [], 0), ("verdict out of budget", [oob, oob], 2),
                                ("verdict differs", [oob, "sample {}: returns 1 != 2"], 1)):
        got = U.verdict(reasons)
        (ok if got == want else fail)(f"unit {name}", f"{got}" + ("" if got == want else f", want {want}"))
    spec = DriverSpec(example="00_user_f", protos=["int f(int);"], setup="",
                      calls=[{"fn": "f", "args": [{"ctype": "int", "quantum": False}]}])
    smp = [{"call": 0, "args": ["0x00000000"]}]
    for v, n in ((0x40, 1), (5, 3), (0xffffffff, 2)):      # -1 is small (signed), 0x40 is not
        smp += [{"call": 0, "args": [f"0x{v:08x}"]}] + [{"call": 0, "args": [f"0x{v:08x}"], "subst": {"s": f"{k}"}}
                                                       for k in range(n - 1)]
    got = U.subset(smp, 6, key=lambda s: tuple(s["args"]), spec=spec)
    groups = [s["args"][0] for s in got]        # in set order
    want = ["0x00000000", "0x00000005", "0x00000005", "0x00000005", "0xffffffff", "0xffffffff"]
    (ok if groups == want else fail)("unit subset", f"{groups}" + ("" if groups == want else f", want {want}"))
    # owner 2026-11-01 (cq-w71h): the groups taken spread over the size range, not the smallest only
    smp = [{"call": 0, "args": ["0x00000000"]}]
    for v in range(1, 9):
        smp += [{"call": 0, "args": [f"0x{v:08x}"]}, {"call": 0, "args": [f"0x{v:08x}"], "subst": {"s": "0"}}]
    got = sorted({int(s["args"][0], 16) for s in U.subset(smp, 7, key=lambda s: tuple(s["args"]), spec=spec)})
    (ok if got == [0, 1, 3, 5] else fail)("unit subset spread", f"{got}" + ("" if got == [0, 1, 3, 5] else ", want [0, 1, 3, 5]"))
    # cq-w71h narrow review: one classical group only (rest empty) must not crash
    one = [{"call": 0, "args": [f"0x{v:08x}"]} for v in range(10)]
    got = len(U.subset(one, 5, key=lambda s: (0,), spec=spec))
    (ok if got == 5 else fail)("unit subset one group", f"{got}")
    (ok if U._spread(0) == [] else fail)("unit spread 0", f"{U._spread(0)}")
    for m in (1, 2, 3, 7, 8, 107):
        got = U._spread(m)
        (ok if sorted(got) == list(range(m)) and got[0] == 0 else fail)(f"unit spread {m}", f"{got[:6]}")
    unit_mopw(spec_root)


def unit_mopw(spec_root):
    """cq-mopw: the two false rejects of the corpus references 61 (invert_call) and 133 (prep_twice)."""
    from cqcheck import compare as C, drivers as D, sampling as S
    mod = D.read_module(spec_root / "examples" / "61_invert_theta_and_call" / "invert_theta_and_call.O1.ll")
    got = sorted(S.inverted_region_sites(mod))
    want = ["invert_theta:2", "prep:0", "prep:1"]
    (ok if got == want else fail)("unit inverted region sites (61)", f"{got}" + ("" if got == want else f", want {want}"))
    # 133 prep_twice with t2 a NaN: Ry(t1) under p (j), its adjoint under p & q (i), then Ry(NaN)
    # under q (k): no gate (CR §1.3), yet the overwrite that makes i j's un-prep
    sign = 1 << 63
    t1, nan = 0x3ff363085206319c, 0x7ff4000000000000
    tv = ("i32", (5, 5, 5))
    j = C._Ev(idx=0, kind="ry", target=3, tclass=tv, theta=t1, afn=None, pred=(1, 1, 0), cpred=(1, 1, 0))
    i = C._Ev(idx=1, kind="ry", target=3, tclass=tv, theta=t1 ^ sign, afn=None, pred=(1, 0, 0), cpred=(1, 0, 0))
    k = C._Ev(idx=2, kind="ry", target=3, tclass=tv, theta=nan, afn=None, pred=(0, 0, 0), cpred=(1, 0, 1))
    k.rawang = (nan, None, nan)
    site = ("prep_twice", 2, "theta")
    for name, idle, back, want in (
            ("with the idle prep, backed", [k], lambda j, k, s: (site, (s, 4)), (0, frozenset())),
            ("with the idle prep, unbacked", [k], lambda j, k, s: None, None),
            ("with the idle prep, no C backing given", [k], None, None),
            ("without it", [], None, None)):
        got = C._unprep_partners([j, i], idle, back)[1]
        (ok if got == want else fail)(f"unit un-prep {name}", f"{got}" + ("" if got == want else f", want {want}"))
    # cq-ia96: the C program's overwrite of j's reach is the next reach of the same register web
    # after it, an identity reach of k's angle class and value
    jsite = ("prep_twice", 1, "theta")
    zsite = ("f", 1, "theta")
    same = {"prep_twice:1": (1, frozenset()), "prep_twice:2": (1, frozenset()), "f:1": (2, frozenset())}
    inplace = dict(same, **{"prep_twice:2": (1, frozenset({"prep_twice:1"}))})
    for name, occ, ident, regs, want in (
            ("overwrite", [(3, t1, 5)], {site: [[(4, "NaN", 5)], [], []]}, same, (site, (0, 4))),
            ("other register", [(3, t1, 5)], {zsite: [[(4, "NaN", 5)], [], []]}, same, None),
            ("before j", [(3, t1, 5)], {site: [[(2, "NaN", 5)], [], []]}, same, None),
            ("a reach of the register between", [(3, t1, 5), (4, t1, 9)], {site: [[(6, "NaN", 5)], [], []]},
             same, None),
            ("other value", [(3, t1, 5)], {site: [[(4, "NaN", 6)], [], []]}, same, None),
            ("in place (cq-yzuc)", [(3, t1, 5)], {site: [[(4, "NaN", 5)], [], []]}, inplace, None)):
        sites = [C._Site(jsite, "theta", [occ, [], []])]
        got = C._c_backing(sites, ident, regs, True)(j, k, 0)
        (ok if got == want else fail)(f"unit C overwrite {name}", f"{got}" + ("" if got == want else f", want {want}"))
    for path, a, b, want in ((spec_root / "examples" / "133_state_prep_overwrite" / "state_prep_overwrite.O1.ll",
                              "prep_twice:1", "prep_twice:2", True),
                             (spec_root / "examples" / "133_state_prep_overwrite" / "state_prep_overwrite.O1.ll",
                              "prep_twice:0", "prep_twice:1", False),
                             (SRC / "ia96" / "p.O1.ll", "f:1", "f:2", False),
                             (SRC / "yzuc" / "b.O1.ll", "f:0", "f:1", True)):
        regs = D.theta_registers(D.read_module(path))
        got = regs[a][0] == regs[b][0]
        (ok if got == want else fail)(f"unit one register {path.name} {a} {b}", f"{got}")
    # cq-yzuc: b.c's second cq_theta rotates a in place (its seed is f:0's value); 133's second
    # prep of r seeds it afresh
    for path, a, b, want in ((SRC / "yzuc" / "b.O1.ll", "f:1", "f:0", True),
                             (spec_root / "examples" / "133_state_prep_overwrite" / "state_prep_overwrite.O1.ll",
                              "prep_twice:2", "prep_twice:1", False)):
        got = b in D.theta_registers(D.read_module(path))[a][1]
        (ok if got == want else fail)(f"unit in place {path.name} {a} of {b}", f"{got}")


def mutants(ref_text):
    """name -> a wrong lowered module of 01_add_classical_const (add_classical)."""
    ry = "  call void @cqrt_ry_i32(i32 %4, double %1)"
    add = "  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)"
    meas = "  %7 = call i32 @cqrt_measure_i32(i32 %5)"
    for s in (ry, add, meas):
        if s not in ref_text:
            raise SystemExit(f"01's reference changed: {s!r} not found")
    lines = ref_text.splitlines()
    out = {}
    out["negated_angle"] = ref_text.replace(ry, "  %neg = fneg double %1\n  call void @cqrt_ry_i32(i32 %4, double %neg)")
    i_ry = next(i for i, l in enumerate(lines) if l.startswith(ry))
    i_add = next(i for i, l in enumerate(lines) if l.startswith(add))
    swapped = list(lines)
    swapped[i_ry], swapped[i_add] = lines[i_add], lines[i_ry]
    out["add_before_ry"] = "\n".join(swapped) + "\n"
    out["measure_classical_input"] = ref_text.replace(meas, meas + "\n  %bad = add i32 %0, %2").replace(
        "  ret i32 %7", "  ret i32 %bad")
    body = re.search(r"(define i32 @add_classical\([^)]*\)[^{]*\{)(.*?)(\n\})", ref_text, re.S)
    out["empty"] = ref_text[:body.end(1)] + "\n  ret i32 0" + ref_text[body.start(3):]
    return out


def mutant133(ref_text):
    """cq-q15r (review of cq-mopw): 133's prep_const_incoming with an extra Ry(-t) right after the
    prep and then an Ry(NaN) on r: the NaN Ry is an identity the C program has no reach for, so it is
    no overwriting prep and the Ry(-t) is no rule-10 un-prep (a wrong circuit: the prep undone)."""
    prep = "  call void @cqrt_ry_i32_controlled(i32 %6, i32 %7, double %3)"
    lines = ref_text.split("\n")
    at = [n for n, l in enumerate(lines) if l.startswith(prep)]
    if len(at) != 1:
        raise SystemExit(f"133's reference changed: {prep!r} is not there once")
    extra = ["  %neg = fneg double %3",
             "  call void @cqrt_ry_i32_controlled(i32 %6, i32 %7, double %neg)",
             "  call void @cqrt_ry_i32_controlled(i32 %6, i32 %7, double 0x7FF8000000000000)"]
    return "\n".join(lines[:at[0] + 1] + extra + lines[at[0] + 1:])


def mutants60(ref_text):
    """name -> a wrong lowered module of 60_qft (qft), cq-rbe6 (review cq-9edz's m60 mutants): the
    controlled phase dropped, negated, controlled on q[j] twice, on the wrong cell, and the Ry
    negated. Only varied elements behind q fire the phase."""
    rz = "  call void @cqrt_rz_i1(i32 %28, double %33)"
    andq = "  call void @cqrt_and_i1(i32 %26, i32 %27, i32 %28)"
    addr = "  %24 = getelementptr inbounds i8, ptr %0, i64 %23"
    ry = "  call void @cqrt_ry_i1(i32 %19, double %2)"
    for t in (rz, andq, addr, ry):
        if t not in ref_text:
            raise SystemExit(f"60's reference changed: {t!r} not found")
    return {"drop_phase": ref_text.replace(rz, ""),
            "negated_phase": ref_text.replace(rz, "  %neg = fneg double %33\n  call void @cqrt_rz_i1(i32 %28, double %neg)"),
            "control_twice": ref_text.replace(andq, "  call void @cqrt_and_i1(i32 %26, i32 %26, i32 %28)"),
            "wrong_cell": ref_text.replace(addr, "  %24 = getelementptr inbounds i8, ptr %0, i64 %15"),
            "negated_ry": ref_text.replace(ry, "  %ng = fneg double %2\n  call void @cqrt_ry_i1(i32 %19, double %ng)")}


# name -> [(mutant, regular expression, its replacement)]: every occurrence, in the forward code and its twins
RV3 = {
    "rdsdj": [("cut_early", "icmp ult i32 %3, 4", "icmp ult i32 %3, 3"),
              ("cut_late", "icmp ult i32 %3, 4", "icmp ult i32 %3, 5"),
              ("no_ak", r"  call void @cqrt_copy_i1\(i32 %0, i32 %\d+\)\n", ""),
              ("leak", r"  call void @cq_template_icmp_eq_i32_hl_unc\(i32 %4, i32 %3, i32 0\)\n  call void @cqrt_free\(i32 %4\)\n", "")],
    "rdsdj2": [], "rdsdj8": [], "recmut": [], "recptr": [], "fpcand": [],
    # cq-6b2cc: g's word 0x279c0000000a lies in our arena; a wrong value there and a wrong pointer in cell both differ
    "arena_word": [("wrong_value", r"cqrt_alloc_i32\(i32 10140\)", "cqrt_alloc_i32(i32 10141)"),
                   ("wrong_pointer", r"cqrt_alloc_i64\(i64 ptrtoint \(ptr @a to i64\)\)", "cqrt_alloc_i64(i64 ptrtoint (ptr @b to i64))")],
    "2in7d": [("no_ak", r"  call void @cqrt_and_i1\(i32 %40, i32 %48, i32 %49\)\n", ""),
              ("no_xor", r"cq_template_xor_i32_hl\(", "cq_template_or_i32_hl(")],
    "li3wr": [("second_return", r"cq_template_add_i32_hl\(i32 %4, i32 6\)", "cq_template_add_i32_hl(i32 %4, i32 7)")],
    "d9vhj": [("classical_swap", "select i1 %52, ptr @abs, ptr @fa", "select i1 %52, ptr @fa, ptr @abs"),
              ("rail_swap", r"i64 ptrtoint \(ptr @fa to i64\), i64 ptrtoint \(ptr @abs to i64\)",
               "i64 ptrtoint (ptr @abs to i64), i64 ptrtoint (ptr @fa to i64)")],
    "f8m9n": [("wrong_flags", r"%9 = call i32 @cq_template_select_i32_ll\(i32 %8, i32 32, i32 0\)",
               "%9 = call i32 @cq_template_select_i32_ll(i32 %8, i32 16, i32 0)"),
              ("two_flags", r"  %9 = call i32 @cq_template_select_i32_ll\(i32 %8, i32 32, i32 0\)\n",
               "  %9 = call i32 @cq_template_select_i32_ll(i32 %8, i32 32, i32 0)\n"
               "  %again = call i32 @cq_template_select_i32_ll(i32 %8, i32 32, i32 0)\n")],
    "l1fc8": [("other_bytes", r'c"k\\00"', 'c"q\\00"')],
}


def rv3(tmp, only=()):
    d = SRC / "rv3"
    for name, muts in RV3.items():
        if only and name not in only:
            continue
        o1, low = d / f"{name}.O1.ll", d / f"{name}.lowered.ll"
        expect(f"program rv3 {name} (f)", 0, user(o1, low, "f", light=True))
        text = low.read_text()
        for m, old, new in muts:
            if not re.search(old, text):
                raise SystemExit(f"rv3 {name}: {old!r} is not in its lowering")
            p = tmp / f"rv3_{name}_{m}.ll"
            p.write_text(re.sub(old, lambda _: new, text))
            expect(f"mutant rv3 {name} {m}", 1, user(o1, p, "f", light=True))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rv3", nargs="*", help="only the src/rv3 group, or these of it")
    ap.add_argument("--spec", type=Path, default=ROOT.parent / "CQ_spec")
    ap.add_argument("--examples", nargs="*", default=DEFAULT_EXAMPLES)
    a = ap.parse_args()
    spec = a.spec.resolve()
    if a.rv3 is not None:
        with tempfile.TemporaryDirectory(prefix="cqu-test-") as t:
            rv3(Path(t), a.rv3)
        print(f"{len(failures)} failures" if failures else "all rv3 tests passed")
        return 1 if failures else 0
    unit(spec)
    with tempfile.TemporaryDirectory(prefix="cqu-test-") as t:
        tmp = Path(t)
        rv3(tmp)
        for name, entry in PROGRAMS:
            d = tmp / name
            r = subprocess.run([sys.executable, str(CQCC), "-S", str(SRC / f"{name}.c"), "--save-temps", str(d),
                                "-o", str(tmp / f"{name}.ll")], capture_output=True, text=True)
            if r.returncode != 0:
                fail(f"program {name}", f"cqcc exited {r.returncode}: {r.stderr.strip()}")
                continue
            expect(f"program {name} ({entry})", 0, user(d / "linked.ll", d / "lowered.ll", entry))

        for item in a.examples:
            ex, _, samples = item.partition(":")
            d = spec / "examples" / ex
            base = ex.split("_", 1)[1]
            for entry in drivers_entries(spec, ex):
                expect(f"corpus {ex} {entry}" + (f" (--samples {samples})" if samples else ""), 0,
                       user(d / f"{base}.O1.ll", d / f"{base}.lowered.ll", entry, samples or None))

        d = spec / "examples" / "01_add_classical_const"
        o1 = d / "add_classical_const.O1.ll"
        for name, text in mutants((d / "add_classical_const.lowered.ll").read_text()).items():
            p = tmp / f"mutant_{name}.ll"
            p.write_text(text)
            expect(f"mutant {name}", 1, user(o1, p, "add_classical"))

        d60 = spec / "examples" / "60_qft"
        for name, text in mutants60((d60 / "qft.lowered.ll").read_text()).items():
            p = tmp / f"mutant60_{name}.ll"
            p.write_text(text)
            expect(f"mutant 60 {name}", 1, user(d60 / "qft.O1.ll", p, "qft"))

        d133 = spec / "examples" / "133_state_prep_overwrite"
        p = tmp / "mutant133_unprep_nan.ll"
        p.write_text(mutant133((d133 / "state_prep_overwrite.lowered.ll").read_text()))
        expect("mutant 133 unprep_nan", 1, user(d133 / "state_prep_overwrite.O1.ll", p, "prep_const_incoming"))

        # cq-ia96 (review of cq-q15r): z's NaN prep, earlier in C and on another register, backs no
        # Ry(NaN) on r, so the Ry(-t) before it is no un-prep
        ia = SRC / "ia96"
        expect("program ia96 p (f)", 0, user(ia / "p.O1.ll", ia / "p.lowered.ll", "f"))
        for m in ("m4", "m5"):
            expect(f"mutant ia96 {m}", 1, user(ia / "p.O1.ll", ia / f"{m}.lowered.ll", "f"))
        # cq-yzuc (review of cq-ia96): an in-place second cq_theta of a is no overwrite, so Ry(-.5)
        # before it is no un-prep, whether its angle is NaN (b) or finite (b2)
        yz = SRC / "yzuc"
        expect("program yzuc b_good (f)", 0, user(yz / "b.O1.ll", yz / "b_good.lowered.ll", "f"))
        expect("mutant yzuc b_mut", 1, user(yz / "b.O1.ll", yz / "b_mut.lowered.ll", "f"))
        expect("mutant yzuc b2_mut", 1, user(yz / "b2.O1.ll", yz / "b2_mut.lowered.ll", "f"))
        # cq-tt2j: CR §6 item 1's leak rule with no reference: a garbage rail live at exit fails. m1_leak is
        # m1_good (fatptr review) minus one icmp _unc and its free (an i1 garbage rail; the reviewer's
        # repro); c8_leak and c7_leak (cq-nyto's witnesses, an older pass) leave x + 3 live, its handle
        # only in a dead frame's cell. cq-cuu82: m1_leak's rail is the condition a rule-6 inverse reads, garbage
        # its producer's _unc can still clean, no rule-6 image. m1_flat_good is the pass's flat-memory lowering of
        # m1; m1_flat_leak drops the _unc and free of x > k (i1), m1_flat_r6_leak those of t * 3, an operand of
        # the inverse of rule 6's clean of s
        lk = SRC / "leak"
        for n in ("m1_good", "m1_flat_good"):
            expect(f"program leak {n} (m1)", 0, user(lk / "m1.O1.ll", lk / f"{n}.lowered.ll", "m1", 20))
        for n, e in (("m1_leak", "m1"), ("m1_flat_leak", "m1"), ("m1_flat_r6_leak", "m1"), ("c8_leak", "c8"),
                     ("c7_leak", "c7")):
            got = user(lk / f"{e}.O1.ll", lk / f"{n}.lowered.ll", e, 20)
            expect(f"mutant leak {n}", 1, got)
            if got[0] == 1 and "a leak; cq-tt2j" not in got[1]:
                fail(f"mutant leak {n}", "rejected, but not by the leak rule")

        expect("error: no such entry", 2, user(o1, d / "add_classical_const.lowered.ll", "nosuch"))
        argv = tmp / "argv"
        (argv / "x").mkdir(parents=True)
        src = argv / "argv.c"
        src.write_text("int main(int argc, char **argv) { int x = argc; cq_theta(&x, 0.5); "
                       "return cq_measure(x + 1); }\n")
        r = subprocess.run([sys.executable, str(CQCC), "-S", str(src), "--save-temps", str(argv / "x"),
                            "-o", str(argv / "argv.ll")], capture_output=True, text=True)
        if r.returncode != 0:
            fail("error: main(argc, argv)", f"cqcc exited {r.returncode}: {r.stderr.strip()}")
        else:
            expect("error: main(argc, argv)", 2, user(argv / "x" / "linked.ll", argv / "x" / "lowered.ll", "main"))

    print(f"{len(failures)} failures" if failures else "all usercheck tests passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
