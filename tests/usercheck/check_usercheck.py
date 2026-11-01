#!/usr/bin/env python3
"""tests/usercheck (cq-w1-usercheck): `cqcheck user`, the C-oracle check of any program.

Fails on any of:
  program   a small C program (src/*.c) compiled by cqcc -S is not green under `cqcheck user` with its
            entry (exit 0)
  corpus    a CQ_spec example's reference lowered.ll is not green against its .O1.ll, with every entry
            of its drivers.txt line and no quantum flags (default 01, 02, 42, 60, 61, 120, 133 and
            117 at --samples 200; --examples NN_name[:samples]... for others). 60 takes a pointer to
            handle cells, 120's all-zero baseline reads q[-1][1] (outside the domain), 117's big
            groups run out of the matching budget (cq-sujz); 61 calls prep inside a cq_invert region
            and 133's prep_twice overwrites a prep with a NaN angle (cq-mopw)
  unit      in process: the verdict of out-of-budget reasons is undecided (2), never differs; a
            --samples subset keeps classical groups whole, smallest first; a template's literal
            operand is no rail position, nor xorc_controlled's literal (c, h, lit) or push's word
            (cq-oylm, src/xorc_cells.ll); cq-mopw: the sites a cq_invert region may reach (61:
            prep's two and invert_theta's second, not invert_call's), and an Ry whose angle is the
            identity still counts as the overwriting prep of a rule-10 un-prep
  mutant    a wrong lowered module is not rejected (exit 1): built from 01's reference with the Ry's
            angle negated, the add computed before the Ry (only cq_theta substitution sees it), the
            measured rail replaced by its classical input, and an empty body (ret 0); from 60's
            reference, five wrong phases or Ry that only varied handle cells expose (cq-rbe6)
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


def user(o1, low, entry, samples=None):
    r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(low),
                        "--entry", entry] + (["--samples", str(samples)] if samples else []),
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
    for callee, nargs, k, want in (("@cq_template_icmp_eq_i32_hl", 2, 1, False),
                                   ("@cq_template_icmp_eq_i32_hl_unc", 3, 2, False),
                                   ("@cq_template_icmp_eq_i32_hl_unc", 3, 1, True),
                                   ("@cq_template_sub_i32_lh", 2, 0, False),
                                   ("@cq_template_select_i8_lh", 3, 1, False),
                                   ("@cq_template_select_i8_lh", 3, 0, True),
                                   ("@cq_template_fadd_f64_hl_rm_exc", 3, 2, False),
                                   ("@cq_template_add_i32", 2, 1, True),
                                   ("@cqrt_and_i1", 3, 2, True), ("@cqrt_xorc_i32", 2, 1, False),
                                   ("@cqrt_alloc_i1", 1, 0, False), ("@cqrt_qram_load_i32_hl", 2, 1, False),
                                   # cq-oylm: xorc_controlled is (c, h, lit); push's word is no rail
                                   ("@cqrt_xorc_i32_controlled", 3, 0, True),
                                   ("@cqrt_xorc_i32_controlled", 3, 1, True),
                                   ("@cqrt_xorc_i32_controlled", 3, 2, False), ("@cqrt_push", 1, 0, False),
                                   ("@cqrt_ry_i32_controlled", 3, 2, False),
                                   ("@cqrt_tape_write_i32_controlled", 3, 1, False),
                                   ("@cqrt_qram_store_i8_controlled", 4, 0, True),
                                   ("@cqrt_qram_store_i8_controlled", 4, 1, False)):
        got = U._rail_position(callee, k, nargs)
        (ok if got == want else fail)(f"unit rail position {callee}#{k}", f"{got}")
    # widths per operand: a control is an i1 rail whatever the gate's width
    for callee, nargs, k, want in (("@cqrt_xorc_i32_controlled", 3, 0, 1), ("@cqrt_xorc_i32_controlled", 3, 1, 32),
                                   ("@cqrt_copy_i8_controlled", 3, 2, 8), ("@cqrt_ry_i16_controlled", 3, 0, 1)):
        got = U._rail_width(callee, k, nargs)
        (ok if got == want else fail)(f"unit rail width {callee}#{k}", f"{got}" + ("" if got == want else f", want {want}"))
    # cq-oylm repro (review cq-9edz): f's i32 cell is xorc's classical literal, g's is its target handle
    from pathlib import Path as _P
    got = {fn: U.handle_cell_params(_P(SRC / "xorc_cells.ll"), fn) for fn in ("f", "g", "k")}
    want = {"f": {}, "g": {0: 32}, "k": {}}
    (ok if got == want else fail)("unit handle cells xorc_controlled", f"{got}" + ("" if got == want else f", want {want}"))
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
    tv = (32, (5, 5, 5))
    j = C._Ev(idx=0, kind="ry", target=3, tclass=tv, theta=t1, afn=None, pred=(1, 1, 0), cpred=(1, 1, 0))
    i = C._Ev(idx=1, kind="ry", target=3, tclass=tv, theta=t1 ^ sign, afn=None, pred=(1, 0, 0), cpred=(1, 0, 0))
    k = C._Ev(idx=2, kind="ry", target=3, tclass=tv, theta=nan, afn=None, pred=(0, 0, 0), cpred=(1, 0, 1))
    for name, idle, want in (("with the idle prep", [k], (0, frozenset())), ("without it", [], None)):
        got = C._unprep_partners([j, i], idle)[1]
        (ok if got == want else fail)(f"unit un-prep {name}", f"{got}" + ("" if got == want else f", want {want}"))


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


def mutants60(ref_text):
    """name -> a wrong lowered module of 60_qft (qft), cq-rbe6 (review cq-9edz's m60 mutants): the
    controlled phase dropped, negated, controlled on q[j] twice, on the wrong cell, and the Ry
    negated. Only varied handle cells (the quantum inputs behind q) fire the phase."""
    rz = "  call void @cqrt_rz_i1(i32 %24, double %29)"
    andq = "  call void @cqrt_and_i1(i32 %23, i32 %17, i32 %24)"
    gep = "  %22 = getelementptr inbounds i32, ptr %0, i64 %21"
    ry = "  call void @cqrt_ry_i1(i32 %17, double %2)"
    for t in (rz, andq, gep, ry):
        if t not in ref_text:
            raise SystemExit(f"60's reference changed: {t!r} not found")
    return {"drop_phase": ref_text.replace(rz, ""),
            "negated_phase": ref_text.replace(rz, "  %neg = fneg double %29\n  call void @cqrt_rz_i1(i32 %24, double %neg)"),
            "control_twice": ref_text.replace(andq, "  call void @cqrt_and_i1(i32 %23, i32 %23, i32 %24)"),
            "wrong_cell": ref_text.replace(gep, "  %22 = getelementptr inbounds i32, ptr %0, i64 %15"),
            "negated_ry": ref_text.replace(ry, "  %ng = fneg double %2\n  call void @cqrt_ry_i1(i32 %17, double %ng)")}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", type=Path, default=ROOT.parent / "CQ_spec")
    ap.add_argument("--examples", nargs="*", default=DEFAULT_EXAMPLES)
    a = ap.parse_args()
    spec = a.spec.resolve()
    unit(spec)
    with tempfile.TemporaryDirectory(prefix="cqu-test-") as t:
        tmp = Path(t)
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
