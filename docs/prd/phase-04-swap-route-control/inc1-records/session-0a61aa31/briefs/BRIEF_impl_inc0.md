# BRIEF_impl_inc0 — bd test_C_libtooling-3qlq.1: Inc 0 — docs + `cq_ry` macro + frontend-lit (NO pass change)
Read `$SP/briefs/BRIEF_common.md` first. Agent name for the progress file: `inc0`.

## Where you work
Worktree `$SP/wt/inc0`, branch `3qlq-inc0` (already created from main = dfb8e83). You touch ONLY:
`include/CQ.h`, `docs/frontend.md`, `docs/backend.md`, `CLAUDE.md`, `ROADMAP.md` (one note),
`tests/frontend/*`. NO file under `ir-pass/`, `runtime/`, `tools/`, `tests/e2e/`.
Done = docs merged, frontend-lit green, ir-pass-lit dispositions UNCHANGED (trivially, since
you touch no pass source and no fixture — state it that way).

## Deliverables (PRD §4.2, §8; bd .1)
1. `include/CQ.h`: add, next to the `cq_theta` dispatch macro (line ~116),
   `#define cq_ry(x, angle) ((x) = cq_theta((x), (angle)))` with a 3–5 line comment: the
   documented STATEMENT surface for an in-place Ry; `cq_theta` stays declared (state prep
   `r = cq_theta(5, θ)`). Do NOT touch `cq_phi` in this increment (Inc 1 replaces it).
2. `tests/frontend/cq_ry_macro.c` — a frontend-lit fixture (copy the RUN-line style of
   `tests/frontend/cq_theta_o1_survival.c`; it runs clang only, no plugin): `cq_ry(x, .1)` at
   -O1 produces the SAME IR construct as `x = cq_theta(x, .1)` — assert both functions emit
   `call i32 @cq_theta_si32(` with the result feeding the next use; add one width besides int
   (e.g. `_Bool` → `@cq_theta_i1`, `double` → `@cq_theta_f64`). Register it the way the other
   fixtures are (check `tests/frontend/CMakeLists.txt` / lit globbing — probably automatic).
3. `docs/frontend.md`:
   - §3.2 (`cq_theta`, line 171ff): add the LINEAR RULE, stated ONCE as language semantics:
     "a rotation consumes the old name; a read of the pre-gate value that the compiler cannot
     prove executes before the gate is refused". Name the three SITES of that one rule in the
     pass: `R6` (ArmClassify's stale-record fence for in-place rotation arms),
     `LoopLowering::staleRailRecordRead`, `OpcodeLowering::declineStaleRecordOps`. Say
     strict single-use is deliberately NOT the rule (Grover's compare and rotation both read
     `q`). Introduce `cq_ry(x, θ)` as the statement surface.
   - §3.3 (`cq_phi`, line 197ff): REWRITE for the register-free branch phase:
     `void cq_phi(double θ)` = multiply the CURRENT BRANCH amplitude by e^{iθ}; under a
     tainted condition it lowers by KICKBACK (flag mint → uncontrolled `cqrt_rz_i1(f,θ)` →
     strip → free; the flag is |0> on every branch); uncontrolled or classically-controlled
     `cq_phi` is a GLOBAL PHASE and is deleted (D2 — a documented semantic, no diagnostic);
     there is NO multi-bit Rz (D4) — the idiom for a register-wide Z rotation is the classical
     per-bit loop `for (i…) if ((q >> i) & 1) cq_phi(θ)` (measured: lowers rolled at K=4 and
     K=32, IR size independent of K); "Rz on qubit i" is a backend peephole. Two worked
     examples: the Grover oracle `if (q == 5) cq_phi(PI);` and the |0> reflection
     `if (q == 0) cq_phi(PI);`. Mark clearly: "the lowering ships in Inc 1 (bd 3qlq.2); until
     it lands the header still declares the old register form" — do not claim the lowering exists.
   - The tensored-register paragraph at lines ~192–196 currently says Rz is per-qubit; rewrite
     it so it is true of Ry only and cross-reference the PRD §1 finding for why per-qubit Rz
     under control is not an oracle.
   - §7 (Quantum control flow, line 464ff): the phase-arm sentence(s) — update to kickback.
4. `docs/backend.md` ~line 985–1000: the `cqrt_rz_i<W>` row — Rz becomes "emitted only at
   `i1`, as the kickback gate on a flag ancilla since 3qlq Inc 1; the W>1 and `_controlled`
   declarations stay declared-unemitted until the freeze (owner Q1)". Keep it short and dated.
5. `CLAUDE.md`: in the CORRECTNESS RISK section (the paragraph starting "Tainted `br` /
   `select` / `switch` is the construct...") add ONE dense paragraph, in the house style:
   the 2026-09-05 finding (tensored Rz ⇒ every shipped Grover golden is the identity on `q`,
   marked phase (-1)^popcount(target), a per-qubit diagonal gate cannot mark |0…0>; the
   kickback spelling declined at `dead chain would free a measured register`), the fix (bd
   3qlq: register-free `cq_phi` by kickback, D1–D7 in the PRD), and RETIRE "`Rz|0⟩ = |0⟩`
   for free" as a load-bearing argument — it becomes history (say explicitly that it is exactly
   the property that made the routed/controlled Rz NOT an oracle). Also update Rule 7's first
   sentences so they do not present `cqrt_rz_<W>_controlled` as the current phase-arm gate
   without the 3qlq caveat (one sentence: "as of 3qlq Inc 1 the phase-arm gate is the
   register-free kickback `cqrt_rz_i1` on the flag — see the Correctness-Risk paragraph").
   Do not rewrite history; append and caveat.
6. `ROADMAP.md`: at the freeze-list mention of `cqrt_rz_<W>_controlled` (grep it; ~line 1004
   and ~1025), add a one-line note "(declared, unemitted since 3qlq Inc 1 — PRD §5)".

## Verification (Rule 19)
- `cd $SP/wt/inc0 && cmake -S tests/frontend -B build-frontend -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm`
  then `ctest --test-dir build-frontend -R frontend-lit --output-on-failure` (standalone
  configure is supported — read the top of `tests/frontend/CMakeLists.txt`). Report the
  fixture count.
- Compile ONE e2e slice through stage 1 only with the edited header to prove the macro does
  not break `-include CQ.h -O1` (e.g. `tests/e2e/slice_control_seq_grover.c`).
- Do NOT run ir-pass-lit or the full ctest.

## Commit
One commit on `3qlq-inc0`: `docs(control): 3qlq Inc 0 — cq_ry statement macro + the linear
rule stated once + register-free branch-phase cq_phi documented (NO pass change; lowering
in Inc 1)`. Report the hash, the files, and the frontend-lit count.
