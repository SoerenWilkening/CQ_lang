#!/usr/bin/env python3
"""tests/loops-cutoff probes of the widened rule-14 constructions (cq-b58q, owner 2026-11-02: no stops).

Usage: run_probes.py --plugin P --opt O probes/NAME.O1.ll [...]. For each probe file it checks, and fails on:
  - cq-lower (with its built-in structural verifier) exits 0, and plain cq-verify accepts the output;
  - no CQ.h surface call is left in an entry;
  - every entry (each external `define` in NAME.c) is §6-equal to its own C program (`python3 -m cqcheck user`,
    the C oracle) within a time limit.
The count options (--measures, --measures-in, --br-in, --test-br-in, --calls-in) count executions with no received K, read from the
lowered CFG (ktrips.py, cq-9kcq): a K-loop is one rolled trip run K times by a classical trip counter.
Outputs go to build/tests/loops-cutoff/out/.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ktrips  # noqa: E402
from ktrips import body  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SURFACE = re.compile(r"call [^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_\w+)\(")


# probe -> [(entry, mutant, regex over the entry's lowered body, its replacement)]: the mutant must be REJECTED by the
# §6 check against the C program (exit 1). me_site (cq-47f8h, owner 2026-11-07: measurements are identified by call
# site): an extra measurement at a site the C program has no counterpart of, a trip that measures another rail than
# the site's (on a trip no sample reaches), and a wrong value at the site's first trip, which C reaches.
MUTANTS = {
    "me_site": [
        ("f", "extra_site", r"(  ret i32 %[\w.]+\n)", r"  %cq.a = call i32 @cqrt_alloc_i32(i32 7)\n  %cq.mx = call i32 @cqrt_measure_i32(i32 %cq.a), !cq.measure !6\n\1"),
        # trip 2 (which no sample reaches) measures at a call site of another shape: one site runs per trip (cq-9kcq), so
        # the mutant branches on the trip counter j == 2 to a second measurement call with other instructions (a clean add
        # of 0, uncomputed) around it (cq-amtcn: each trip measures a kept copy of v)
        ("f", "other_site", lambda b: other_site(b), None),
        # v's bit 3 (b3) set as 16 instead of 8, forward and uncomputation alike: the first trip, which C reaches, measures another v
        ("f", "wrong_value", r"i32 8, i32 0\)", "i32 16, i32 0)"),
    ],
    # me_cbr (cq-v8cn7, cq-1ye9c; CR rules 2, 8, 14): a measurement behind a classical branch runs only where the
    # classical arguments take it; a trip's execution is the site only if it measures the site's register.
    "me_cbr": [
        # the last trip (trip 3, which no sample reaches) measures a copy of v (the rail the trip shifts), not w: the trip's
        # one site, its register chosen by trip index, j == K - 1 (accepted by §6 at 31bbc2ec, rejected since checker bead
        # cq-2pdir: run.py names the register per execution)
        ("h", "other_register", lambda b: other_register(b), None),
        # the trip's measurement moved above its classical br, so it runs also where (c & 1) is 0
        ("h", "hoist_trips", r"(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n\n[\w.]+:[^\n]*\n)"
         r"(  %[\w.]+ = call i32 @cqrt_alloc_i32\(i32 0\)\n  call void @cqrt_copy_i32[^\n]*\n"
         r"  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)", r"\2\1"),
        # g's measurement (and the w it measures) moved above the classical br on (c & 1)
        ("g", "hoist_branch", r"(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n\n[\w.]+:[^\n]*\n  %[\w.]+ = phi[^\n]*\n"
         r"  ret i32 %[\w.]+\n\n[\w.]+:[^\n]*\n)((?:  [^\n]*\n)*?  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)",
         r"\2\1"),
    ],
    # rulings Q3 (2026-11-11): the measurement behind the classical branch on an earlier outcome (m & 1), hoisted above
    # that branch, so it collapses y also where m is even and C keeps y coherent: the C run leaves the site by a classical
    # condition (a statically collapsed outcome), a failure.
    "me_outcome": [
        ("meas_behind_outcome", "hoist_outcome",
         r"(?s)(  br i1 %[\w.]+, label %[\w.]+, label %[\w.]+\n.*?\n[\w.]+:[^\n]*\n)"
         r"(  %[\w.]+ = call i32 @cqrt_alloc_i32\(i32 0\)\n  call void @cqrt_copy_i32[^\n]*\n"
         r"  %[\w.]+ = call i32 @cqrt_measure_i32[^\n]*\n)", r"\2\1"),
    ],
    # rulings Q8: every trip measures a select of its own making, select(!a, x0, v), in place of its kept copy of v (a the
    # trip's predicate): where the trip is reached its condition reads 0 and the value is the site's; where it is not (an
    # extra), it reads 1 and the trip measures x0, another register. The old static rule (any three-rail select followed to
    # its third operand) accepted it.
    "me_carried": [
        ("measure_carried", "own_select", lambda b: own_select(b), None),
    ],
    # owner ruling 2026-11-15 on cq-zk0aj (CR rule 14, §6): ex_pre's quantum header test (v & 4) == 0 made a constant, its mask
    # 4 replaced by 0 in every trip and its uncomputation alike, so every trip runs on: trips C leaves by v & 4 still
    # measure v and add to n, a classical test on a value no earlier outcome fixes
    # cq-9kcq S21 (CR rules 14, 26): the vector w of the header test region is carried one field per header phi; field 1's
    # phi (read by the body as w[1]) takes field 0's latch value, so every trip after trip 0 reads w[0] for w[1]
    "agg_region": [
        ("vec_region", "other_field", lambda b: other_field(b), None),
    ],
    # cq-n1hy7 (CR rules 6, 14): te_sub's exit value a (the last executed trip's capture rail, copied out at X) read from the
    # trip before it: the copy and its un-copy read the capture's header phi (the previous trip's value) in place of the
    # last trip's select, so a - b after the loop pairs one trip's a with another's b
    "trip_exit": [
        ("te_sub", "prev_trip", lambda b: prev_trip(b), None),
    ],
    # cq-shndm (CR rules 5, 9, 14): em_wcs_f's copy at X of the exit hub's value (read by the select that joins the storing exit
    # arm's N - n at the return) left live: its un-copy after that reader (the first un-copy of the deferred reverse) dropped
    "exit_mem": [
        ("em_wcs_f@em_wcs", "keep_hub", r"  call void @cqrt_copy_i32\(i32 %[\w.]+, i32 (%[\w.]+)\)\n  call void @cqrt_free\(i32 \1\)\n", ""),
    ],
    "me_exit": [
        ("ex_pre", "const_test", lambda b: re.sub(r"(@cq_template_and_i32_hl(?:_unc)?\((?:i32 %[\w.]+, )+i32 )4\)", r"\g<1>0)", b),
         None),
    ],
    # cq-nmzv3 (review R1 t3): the classical br on c dropped, the measurement on every input
    "q3_conjunct": [
        ("mix", "unguarded", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
        ("mixc", "unguarded_c", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
    ],
    # owner ruling Q10 (cq-kbygn exit-test part; CR rule 14): the classical br of test 0 on c dropped, so the chain goes on
    # where c is 0 (a_1 = a_0 & q), and trips C never runs change acc and *f
    "exit_conjunct": [
        ("ec_do", "no_test_branch", r"  br i1 %[\w.]+, label (%[\w.]+), label %[\w.]+\n", r"  br label \1\n"),
    ],
    # cq-9kcq (CR rule 27 "Cutoff", §1.4): the table clone ignores the K it received and runs its own K 4 where tk_f passed
    # 2: its K parameter is replaced by the own K 4 at every use (the trip count, the K it passes on in @__cq_k alike), in
    # the clone and its twin alike, so the twin undoes the
    # 4 trips the clone ran and only the cutoff differs. Checked through tk_f, whose pointer is a rail: the dispatch
    # calls the _ctl table clone; a mutant entry "fn+twin@entry".
    "table_k": [
        ("__cq_q_kf_11_t_ctl+__cq_q_kf_11_t_ctl_unc@tk_f", "own_k", lambda b: own_k(b, 4), None),
    ],
    # cq-9kcq S6 (CR §1.4 "Received K", owner 2026-11-15: the received K in place of the own one, smaller or larger): the
    # table clone run at its own K 4 where tk6_f passes 6 is rejected against the one C module. recv_k_cut1: a cut that
    # comes too early, the clone and its twin running 1 trip where tk2_f passes 2.
    "table_k6": [
        ("__cq_q_kf_11_t_ctl+__cq_q_kf_11_t_ctl_unc@tk6_f", "own_k", lambda b: own_k(b, 4), None),
        ("__cq_q_kf_11_t_ctl+__cq_q_kf_11_t_ctl_unc@tk2_f", "recv_k_cut1", lambda b: own_k(b, 1), None),
    ],
    # cq-9kcq with owner ruling Q2 (2026-11-14): a by-name helper of a table clone ignores @__cq_k (its own K 4 where kh_1
    # passed 2); a table clone does not restore @__cq_k at its returns, so kh_after's by-name call of h1 after the table
    # call runs at 2 instead of its own 4. helper_own_k (cq-rin8c): kh_1's rail pointer dispatches to t1's _t_ctl clone
    # and its twin (__cq_clone_resolve variants 1 and 3), which call h1's _ctl clone and its twin; the plain h1 clone
    # runs only under the forward table clone (kh_cls), so it is the _ctl pair that ignores the received K.
    "table_kh": [
        ("__cq_q_h1_11_ctl+__cq_q_h1_11_ctl_unc@kh_1", "helper_own_k", r"load i32, ptr @__cq_k, align 4",
         r"add i32 -1, 0"),
        ("__cq_q_t1_11_t_ctl@kh_after", "no_restore", r"  store i32 %\d+, ptr @__cq_k, align 4\n  ret", r"  ret"),
        # the helper's quantum-depth recursion, and the K a helper passes through a pointer, at its own K 4
        ("__cq_q_hr_1_ctl@kh_rec", "rec_own_k", r"load i32, ptr @__cq_k, align 4", r"add i32 -1, 0"),
        ("__cq_q_hp_11_ctl@kh_ptr", "ptr_own_k", r"load i32, ptr @__cq_k, align 4", r"add i32 -1, 0"),
    ],
    # cq-nmzv3's sibling (review R1 t2): the second call of g, behind `if (c)`, unguarded
    "q3_phantom": [
        ("phantom", "second_unguarded", r"(?s)(  br i1 (%[\w.]+), label %[\w.]+, label %[\w.]+\n.*?)"
         r"  br i1 \2, label (%[\w.]+), label %[\w.]+\n", r"\1  br label \3\n"),
        ("phantom2", "second_unguarded2", r"(  %[\w.]+ = icmp eq i32 %0, 0\n)  br i1 %[\w.]+, label %[\w.]+, label (%[\w.]+)\n",
         r"\1  br label \2\n"),
    ],
    # owner ruling of 2026-11-15 (the activation-counter cut; CR §1.4, rule 14): the depth counter's cut test is d < K, K the
    # K the table clone receives. A cut at a constant other than K (the clone and the copy that recomputes it alike) cuts
    # another activation than the C oracle (cqo_rt.c __cqo_act_enter): at K = 0 (k_zero) d < 1 runs the
    # first activation; at a received K 2 (k_chain) d < 3 runs the third.
    "k_zero": [
        ("__cq_q_kf_11_t_ctl+__cq_q_kf_11_t_ctl_unc@kz_tab", "cut_d1",
         r"(store i32 %[\w.]+, ptr @__cq_act_kf, align 4\n  %[\w.]+ = icmp ult i32 %[\w.]+), %[\w.]+\n", r"\1, 1\n"),
    ],
    "k_chain": [
        ("__cq_q_kt_1_t_ctl+__cq_q_kt_1_t_ctl_pure@kc_chain", "cut_d3",
         r"(store i32 %[\w.]+, ptr @__cq_act_kt, align 4\n  %[\w.]+ = icmp ult i32 %[\w.]+), %[\w.]+\n", r"\1, 3\n"),
    ],
}
_ALL = ("wrong_value", "hoist_trips", "no_restore")   # mutants applied at every match, not the first only
NAMED = ("me_cbr", "me_outcome")                        # probes whose lowered module is mutated after opt -passes=instnamer


def own_k(fn_body: str, k: int):
    """A table clone that ignores the K it receives: every use of its K parameter (ktrips.table_k_param) reads k."""
    p = ktrips.table_k_param(fn_body)
    if not p:
        return fn_body
    head, rest = fn_body.split("\n", 1)
    return head + "\n" + re.sub(re.escape(p) + r"(?![-\w.$])", str(k), rest)


def other_site(fn_body: str):
    """me_site's f with trip 2 (which no sample reaches) measuring at a call site of another shape: a classical branch on
    the trip counter j == 2 to a second measurement call with a clean add of 0 (uncomputed) before and after it, the
    site's own elsewhere."""
    loops = ktrips.counter_loops(fn_body)
    if not loops:
        return fn_body
    j = loops[0][2]
    m = re.search(r"^  (%[\w.]+) = call i32 @cqrt_measure_i32\(i32 (%[\w.]+)\), !cq.measure !6\n", fn_body, re.M)
    if not m:
        return fn_body
    hdr = re.findall(r"^([\w.]+):", fn_body[:m.start()], re.M)[-1]
    out, r = m.group(1), m.group(2)
    dummy = lambda d: (f"  %{d} = call i32 @cq_template_add_i32_hl(i32 {r}, i32 0)\n  call void @cq_template_add_i32_hl_unc(i32 "
                       f"%{d}, i32 {r}, i32 0)\n  call void @cqrt_free(i32 %{d})\n")
    split = (f"  %cq.t2 = icmp eq i32 {j}, 2\n  br i1 %cq.t2, label %cq.o, label %cq.n\n\ncq.o:\n" + dummy("d0")
             + f"  %cq.mo = call i32 @cqrt_measure_i32(i32 {r}), !cq.measure !6\n" + dummy("d1") + "  br label %cq.j\n\ncq.n:\n"
             f"  %cq.mn = call i32 @cqrt_measure_i32(i32 {r}), !cq.measure !6\n  br label %cq.j\n\ncq.j:\n"
             f"  {out} = phi i32 [ %cq.mo, %cq.o ], [ %cq.mn, %cq.n ]\n")
    b = fn_body[:m.start()] + split + fn_body[m.end():]
    # the header's terminator now ends cq.j: every phi's incoming edge from the header comes from cq.j
    return re.sub(r"^(  %[\w.]+ = phi [^\n]*)$", lambda p: p.group(1).replace(f", %{hdr} ]", ", %cq.j ]"), b, flags=re.M)


def prev_trip(fn_body: str):
    """trip_exit's te_sub: the copy-out of the capture rail of a (cqrt_copy_i32 of the select whose third operand, the
    accumulator, is a header phi) and its un-copy read that phi instead: the trip before the last one's value."""
    for m in re.finditer(r"call void @cqrt_copy_i32\(i32 (%[\w.]+), i32 (%[\w.]+)\)", fn_body):
        x, c = m.group(1), m.group(2)
        sel = re.search(r"^  " + re.escape(x) + r" = call i32 @cq_template_select_i32\(i32 %[\w.]+, i32 %[\w.]+, i32 (%[\w.]+)\)$",
                        fn_body, re.M)
        if not sel or not re.search(r"^  " + re.escape(sel.group(1)) + r" = phi i32 ", fn_body, re.M):
            continue
        return fn_body.replace(f"call void @cqrt_copy_i32(i32 {x}, i32 {c})", f"call void @cqrt_copy_i32(i32 {sel.group(1)}, i32 {c})")
    return fn_body


def other_field(fn_body: str):
    """agg_region's vec_region: the header phis of w's two fields (entered as the region's evaluation before the loop:
    field 0 x*x, field 1 3x*7); field 1's latch incoming replaced by field 0's."""
    f0 = re.search(r"^  (%[\w.]+) = call i32 @cq_template_mul_i32\(i32 (%[\w.]+), i32 \2\)", fn_body, re.M)
    f1 = re.search(r"^  (%[\w.]+) = call i32 @cq_template_mul_i32_hl\(i32 %[\w.]+, i32 7\)", fn_body, re.M)
    if not f0 or not f1:
        return fn_body
    phi = r"^(  %[\w.]+ = phi i32 \[ {}, %[\w.]+ \], \[ )(%[\w.]+)(, %[\w.]+ \])$"
    p0 = re.search(phi.format(re.escape(f0.group(1))), fn_body, re.M)
    p1 = re.search(phi.format(re.escape(f1.group(1))), fn_body, re.M)
    if not p0 or not p1:
        return fn_body
    return fn_body[:p1.start()] + p1.group(1) + p0.group(2) + p1.group(3) + fn_body[p1.end():]


def own_select(fn_body: str):
    """me_carried's measure_carried measuring select(!a, x0, v) of its own making where a reached trip measures v (rulings
    Q8): where the trip is reached !a reads 0 and the value is the site's, where it is not (an extra execution) the
    measurement reads x0, another register. Every trip, a the trip's predicate (the condition of the select that advances
    the measured carried value), in place of the trip's kept basis copy of v."""
    if not ktrips.counter_loops(fn_body):
        return fn_body
    m = re.search(r"^  (%[\w.]+) = call i32 @cqrt_alloc_i32\(i32 0\)\n  call void @cqrt_copy_i32\(i32 (%[\w.]+), i32 \1\)\n"
                  r"(  %[\w.]+ = call i32 @cqrt_measure_i32\(i32 \1\), !cq.measure !6\n)", fn_body, re.M)
    if not m:
        return fn_body
    c, v = m.group(1), m.group(2)
    a = re.search(r"= call i32 @cq_template_select_i32\(i32 (%[\w.]+), i32 %[\w.]+, i32 " + re.escape(v) + r"\)", fn_body)
    x0 = re.search(r"^  " + re.escape(v) + r" = phi i32 \[ (%[\w.]+), ", fn_body, re.M)
    if not a or not x0:
        return fn_body
    a, x0 = a.group(1), x0.group(1)
    rep = (f"  %q.one = call i32 @cqrt_alloc_i1(i1 true)\n  %q.n = call i32 @cqrt_alloc_i1(i1 false)\n"
           f"  call void @cqrt_and_i1(i32 {a}, i32 %q.one, i32 %q.n)\n  call void @cqrt_and_i1(i32 %q.one, i32 %q.one, i32 %q.n)\n"
           f"  {c} = call i32 @cq_template_select_i32(i32 %q.n, i32 {x0}, i32 {v})\n"
           f"  call void @cqrt_and_i1(i32 %q.one, i32 %q.one, i32 %q.n)\n  call void @cqrt_and_i1(i32 {a}, i32 %q.one, i32 %q.n)\n"
           f"  call void @cqrt_free(i32 %q.n)\n  call void @cqrt_free(i32 %q.one)\n" + m.group(3))
    return fn_body[:m.start()] + rep + fn_body[m.end():]


def other_register(fn_body: str):
    """me_cbr's h with its last trip's measurement on a copy of v (the operand of the trip's lshr), not of w."""
    loops = ktrips.counter_loops(fn_body)
    if not loops:
        return fn_body
    _, _, j, _, n, *_ = loops[0]     # one site, its register a classical select on the trip counter
    v = re.search(r"lshr_i32_hl\(i32 (%[\w.]+), i32 1\)", fn_body)
    if n is None or not v:
        return fn_body
    return re.sub(r"(call void @cqrt_copy_i32\(i32 )(%[\w.]+)(, i32 %[\w.]+\)\n  %[\w.]+ = call i32 @cqrt_measure_i32)",
                  lambda m: f"%cq.last = icmp eq i32 {j}, {n - 1}\n  %cq.reg = select i1 %cq.last, i32 {v.group(1)}, i32 "
                  f"{m.group(2)}\n  {m.group(1)}%cq.reg{m.group(3)}", fn_body, count=1)


def mutants(a, probe: Path, mod: str, out: Path) -> int:
    failures = 0
    stem = probe.name.replace(".O1.ll", "")
    if stem in NAMED and MUTANTS.get(stem):
        # a mutant that moves instructions across blocks needs named values (numbered ones must stay in order)
        mod = subprocess.run([a.opt, "-passes=instnamer", "-S", "-"], input=mod, capture_output=True, text=True,
                             check=True).stdout
    for e, name, old, new in MUTANTS.get(stem, []):
        e, _, entry = e.partition("@")   # "fn@entry": the mutated function is not the entry checked
        entry = entry or e.split("+")[0]
        m, missing = mod, []
        for fn in e.split("+"):          # "fn+fn2@entry": each function mutated alike (a clone and its twin)
            b = body(m, fn)
            nb = old(b) if callable(old) else re.sub(old, new, b, count=(0 if name in _ALL else 1))
            if nb == b:
                missing.append(fn)
            m = m.replace(b, nb, 1)
        if missing:
            print(f"FAIL {probe.name} mutant {name}: " + ("not applicable" if callable(old) else f"{old!r} is not")
                  + " in " + ", ".join("@" + x for x in missing))
            failures += 1
            continue
        low = out / probe.name.replace(".O1.ll", f".{name}.ll")
        low.write_text(m)
        v = subprocess.run([a.opt, "-passes=verify", "-disable-output", str(low)], capture_output=True, text=True)
        if v.returncode != 0:            # a rejection must come from §6, not from a module that does not parse
            print(f"FAIL {probe.name} mutant {name}: not valid IR: " + (v.stderr.strip().splitlines() or ["?"])[0])
            failures += 1
            continue
        c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                            str(low), "--entry", entry], capture_output=True, text=True, cwd=ROOT / "checker",
                            timeout=a.timeout)
        rejected = c.returncode == 1 and "FAIL" in c.stdout
        print(("ok   " if rejected else "FAIL ") + f"{probe.name} mutant {name}: "
              + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1][:200])
        failures += not rejected
    return failures


def measures(fn_body: str):
    """The cqrt_measure executions of one function with no received K (ktrips.runs): a site in a rolled trip loop runs
    once per trip, except one measuring a rail made before the loop: its later trips re-measure the same rail, a
    classical re-read (CR rule 2)."""
    return ktrips.runs(fn_body, r"call [^@]*@cqrt_measure_", invariant_once=True)


def test_brs(fn_body: str):
    """The executions of a conditional br on an `icmp` the function computes (a classical condition, CR rule 8), with no
    received K (ktrips.runs): the trip counter's own br and its test before trip 0 are not counted, nor a br on a phi of
    flags. Owner ruling Q10: a K-loop's classical exit conjunct is such a br at each of its tests (one test run once per
    trip)."""
    conds = [v for v, rhs in ktrips.defs(fn_body).items() if rhs.startswith("icmp ")]
    if not conds:
        return 0
    return ktrips.runs(fn_body, r"^  br i1 (?:" + "|".join(map(re.escape, conds)) + r"),", skip_latches=True)


def entries(o1: str):
    return [m.group(1) for m in re.finditer(r"^define (?!internal|private)[^\n]*@(\w+)\(", o1, re.M)
            if "noinline" not in m.group(0)]


def one(a, probe: Path) -> int:
    out = ROOT / "build" / "tests" / "loops-cutoff" / "out"
    out.mkdir(parents=True, exist_ok=True)
    lowered = out / probe.name.replace(".O1.ll", ".lowered.ll")
    r = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-S", str(probe), "-o",
                        str(lowered)], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL {probe.name} cq-lower: " + (r.stderr.strip().splitlines() or ["?"])[0])
        return 1
    v = subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-verify", "-disable-output",
                        str(lowered)], capture_output=True, text=True)
    if v.returncode != 0:
        print(f"FAIL {probe.name} cq-verify: " + (v.stderr.strip().splitlines() or ["?"])[0])
        return 1
    mod = lowered.read_text()
    failures = 0
    for e in (a.entry or entries(probe.read_text())):
        why = []
        b = body(mod, e)
        if not b:
            why.append("no lowered body")
        if SURFACE.search(b):
            why.append("a CQ.h surface call is left")
        # The counts are of executions with no received K, read from the CFG (ktrips.runs, cq-9kcq): a site of a rolled
        # trip runs once per trip of the trip counter.
        for spec in a.measures_in or []:
            fn, n = spec.split("=")
            got = measures(body(mod, fn))
            if got != int(n):
                why.append(f"{got} cqrt_measure runs in @{fn}, not {n}")
        for spec in a.br_in or []:
            fn, n = spec.split("=")
            got = ktrips.runs(body(mod, fn), r"^  br i1 ", skip_latches=True)
            if got is None or got < int(n):
                why.append(f"{got} conditional br runs in @{fn}, fewer than {n}")
        for spec in a.test_br_in or []:
            fn, n = spec.split("=")
            got = test_brs(body(mod, fn))
            if got != int(n):
                why.append(f"{got} runs of a br on a classical icmp in @{fn}, not {n}")
        for spec in a.calls_in or []:
            fn, callee, n = spec.split("=")
            got = ktrips.runs(body(mod, fn), r"call [^@\n]*@" + re.escape(callee) + r"\(")
            if got != int(n):
                why.append(f"{got} runs of a call of @{callee} in @{fn}, not {n}")
        if a.measures is not None and measures(b) != a.measures:
            why.append(f"{measures(b)} cqrt_measure runs, not {a.measures}")
        if a.measures is not None and re.search(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M) and any(
                "cqrt_measure" in t for t in re.findall(r"^define [^\n]*_unc\(.*?^}", mod, re.S | re.M)):
            why.append("a twin measures")
        try:
            c = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(probe), "--lowered",
                                str(lowered), "--entry", e], capture_output=True, text=True, cwd=ROOT / "checker",
                               timeout=a.timeout)
            if c.returncode != 0 or "PASS" not in c.stdout + c.stderr:
                why.append("§6 against the C program: " + ((c.stdout + c.stderr).strip().splitlines() or ["?"])[-1])
        except subprocess.TimeoutExpired:
            why.append("§6 against the C program: timed out")
        print(("FAIL " if why else "ok   ") + probe.name + " " + e + ("" if not why else ": " + "; ".join(why)))
        failures += bool(why)
    return failures + mutants(a, probe, mod, out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--entry", action="append")
    ap.add_argument("--measures", type=int, help="the cqrt_measure runs of each entry (a K-loop's trips counted, a "
                    "rail made before the loop re-read); no twin may hold one")
    ap.add_argument("--measures-in", action="append", help="NAME=N: the cqrt_measure runs of function NAME")
    ap.add_argument("--timeout", type=int, default=240, help="seconds for one entry's §6 check")
    ap.add_argument("--br-in", action="append", help="NAME=N: function NAME must run at least N conditional br, a K-loop's trips "
                    "counted, its trip counter's own br not (cq-jws5r)")
    ap.add_argument("--test-br-in", action="append", help="NAME=N: the runs of a conditional br on an icmp of function NAME, "
                    "exactly N, a K-loop's trips counted, its trip counter's own br not (owner ruling Q10)")
    ap.add_argument("--calls-in", action="append", help="NAME=CALLEE=N: the runs of a call of CALLEE in function NAME, a K-loop's "
                    "trips counted")
    ap.add_argument("--table-k", type=int, help="the K a table clone's K parameter holds in the counts (the K its dispatch "
                    "passes where no K is received); without it a trip loop bounded by that parameter is not counted (cq-9kcq)")
    ap.add_argument("probes", nargs="+")
    a = ap.parse_args()
    if a.table_k is not None:
        ktrips.TABLE_K = a.table_k
    fails = sum(one(a, Path(p).resolve()) for p in a.probes)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
