# Spec issues

Contradictions found in the pinned CQ_spec (see `spec.lock`). CONSTRUCTION_RULES.md wins over an
example; the fix lands in CQ_spec (tracked in its §7 table), never as a workaround here. An entry is
removed when the fix is in CQ_spec and `spec.lock` is re-pinned to it. Version 1 requires this list
to be empty.

Entry format:

```
## <example or CR section>: <one-line summary>
- Rule: <CR rule/section the example or text should follow>
- Disagreement: <what the reference, header or text says vs what the rule requires>
- Evidence: <checker output, input sample, line references>
- Bead: <cq-… id>
```

## Open

Closed earlier, not listed here: the 2026-11-03 CQ_spec commit 34c1df7 answered 87 vs 190/189 (rule 14 affine induction, 87 owed a regeneration), 67 vs rule 20 (confined static is a rule-31 slot), rule 17 every-arm markers, rule 20 strided qram_alloc_host, rule 13 label-address compare.

Entries 1 to 16 are from the flat-memory rulings (`wt/flat/rulings.md`, "Entries for SPEC_ISSUES.md"), against CQ_spec bff98cb.
## §7 and preamble: regeneration-owed status is stale for flat memory
- Rule: §7 status table and the preamble must match the regenerated examples on disk.
- Disagreement: The 73 "regeneration owed (flat memory)" examples, 96, 98 and 161 are regenerated on disk (all call `__cq_mem`); 202 is rolled although §7 says it unrolls; the commit message names 146, which has no diff. The "(regeneration owed)" tags on every rule's witness list are stale.
- Evidence: CQ_spec commit 5ed7bc7 ("78 regenerated (the 73 memory-affected ones, 96, 98, 146, 161, 202)"); on disk the 73 call `__cq_mem`; 146 has no diff.
- Request: delete the owed table or say "regenerated 2026-11-05".
- Bead: cq-0rd4

## Rule 18 vs rule 27 and §0 on a bodiless math callee (175)
- Rule: rule 27 ("A bodiless callee on no list is the host boundary (rule 16)"); §0 bullet 1 agrees with rule 27.
- Disagreement: Rule 18 says "a declared clone otherwise (175)"; rule 27 and §0 bullet 1 say a bodiless callee on no list is the host boundary. 175 declares rule-18 clones (`__cq_q_exp_1`, no `_t`, no K) with bodies omitted and presumes musl libm injected.
- Evidence: example 175.
- Request: rule 18 to say "and rule 16/27 otherwise"; 175 to state the bundle it needs.
- Bead: cq-vmgc

## Rule 18 "measures" vs rule 2 classical-path measurement with a twin
- Rule: rule 2 (classical-path measurement returns a seed and the clone keeps its twin).
- Disagreement: Rule 18 says "measures"; rule 2 treats a classical-path measurement differently. The ruling reads "measures" in rule 18 as a tainted measurement (under a quantum predicate or in a `_ctl` clone).
- Evidence: rulings Q3.
- Request: rule 18 to read "has a measurement whose outcome is tainted (under a quantum predicate or rule 19's controlled copy)".
- Bead: cq-jnaw

## 102 contradicts rule 5 sentence 3 (kept conjunction flag and seed)
- Rule: rule 5 sentence 3 ("the caller uncomputes/frees what it minted after the twin"); example 212 follows this text.
- Disagreement: 102 keeps the conjunction flag and the `|sig⟩` seed passed to a storing candidate. The reference's kept multiset differs from CR. Our checker reports 102 spec-blocked on kept rails.
- Evidence: our checker output on kept rails for 102; 212 matches the text.
- Request: regenerate 102 per the text.
- Bead: cq-p7qn

## Rule 27 quantum-depth recursion min(K, B) vs rule 14 cut at K (98)
- Rule: rule 14 "cut at K whatever decides its depth" (98).
- Disagreement: rule 27 says "quantum-depth recursion runs min(K, B)"; rule 14 says recursion is cut at K.
- Evidence: example 98.
- Request: rule 27 to say "loops min(K, B), recursion K".
- Bead: cq-8ce3

## Rule 16 `va_copy` "as it stands" copies host bytes of quantum cells; rule 22 silent
- Rule: rule 22 (copy of quantum cells).
- Disagreement: rule 16's `va_copy` "as it stands" copies host bytes of cells that may be QUANTUM; example 109 emits rule 22's 24-byte copy.
- Evidence: example 109.
- Request: rule 22 to list `llvm.va_copy` as a copy of `sizeof(va_list)` bytes.
- Bead: cq-xo91

## Rule 5 "`memory(none)` or `memory(read)`" vs clang's attribute spelling
- Rule: rule 5 (callee classification).
- Disagreement: clang emits `memory(argmem: read)` and similar spellings, which the rule's wording does not cover.
- Evidence: rulings entry 7 (clang emits `memory(argmem: read)` etc.).
- Request: "a callee LLVM marks as not writing memory".
- Bead: cq-tuwh

## Rule 14 gaps: exit-test load (117) and two exit tests per trip (189)
- Rule: rule 14 classical-bound-with-quantum-exit bullet and trip structure.
- Disagreement: the exit-test load in the classical-bound-with-quantum-exit bullet is a gap (117, SPEC GAP 2); example 189 has two exit tests per trip.
- Evidence: examples 117 and 189.
- Request: spell both as the witnesses do.
- Bead: cq-kgd2

## §0 never-lifted list omits injection-bundle host symbols
- Rule: §0 "The only bodies never lifted are those rule 16 names".
- Disagreement: the list omits the injection-bundle host symbols `__cq_mem`, `__cq_alloc`, `__cq_clone_*` and `__cq_sig`, which ABI §0 places in classical host C with one definition per process.
- Evidence: BACKEND_ABI.md §0.
- Request: name them as never lifted and shipped with the runtime, not the pre-pass bundle.
- Bead: cq-r2ej

## Rule 27 root lists are not machine-readable (161 ext_fn, 190 ext_sink)
- Rule: rule 27 root lists.
- Disagreement: nothing machine-readable says 161 `ext_fn` and 190 `ext_sink` are listed; only drivers.txt prototype comments do.
- Evidence: `_tools/drivers.txt` prototype comments.
- Request: a `roots=` field in drivers.txt.
- Bead: cq-huvb

## §0 "every body is lowered" for a module with no CQ primitive
- Rule: §0 "Every body is lowered"; NORTHSTAR principle 1 and goal 4 tier 1.
- Disagreement: §0 requires every body to be lowered even for a module with no CQ primitive. We apply a module gate instead (identity iff no `cq_*` call, no root list, no declared-clone reference).
- Evidence: NORTHSTAR principle 1, goal 4 tier 1.
- Request: owner decision requested.
- Bead: cq-bkgt

## §6 is silent on effect entries' event sequence
- Rule: §6 (what of the tape is compared).
- Disagreement: our checker compares (name, fields, predicate, order) per input with the §6 stand-in; a deferred output's `|0⟩` result rail is a stated deviation excluded against the C oracle only.
- Evidence: our checker's per-input comparison.
- Request: §6 to say what of the tape is compared.
- Bead: cq-fmia

## Rule 16 `realloc` of a host-made block reads the allocator word as size
- Rule: rule 16 (`realloc`).
- Disagreement: `realloc` of a host-made block reads the host allocator's word as the size.
- Evidence: recorded deviation.
- Request: none; no fix possible under §0. Recorded deviation.
- Bead: cq-tb7a

## Minor wording: ABI §0 Ry, rule 19 twin handles order, rule 19 "no call"
- Rule: ABI §0 (Ry definition); rule 19 (twin handles; "no call").
- Disagreement: ABI §0 "every core gate … classical-valued" vs Ry (the definition governs); rule 19 "the twin taking those handles first" vs §1.4 `_unc(outs…, args…)` (extras trail the results); rule 19 "no call" should say opcode-like and lifetime/debug intrinsics are not calls.
- Evidence: BACKEND_ABI.md §0 and §1.4; CONSTRUCTION_RULES.md rule 19.
- Request: wording fixes.
- Bead: cq-ktst

## 206 driver call `(&cell, &cell, …)` is C UB (restrict violated)
- Rule: §6 (the C oracle decides inputs with a defined value; UB inputs are out of domain).
- Disagreement: the driver call `(&cell, &cell, …)` violates `restrict`, which is UB in C, so the C oracle has no value on it; it is compared against the reference only.
- Evidence: example 206 driver call in `_tools/drivers.txt`.
- Request: drivers.txt to mark the call as reference-only, or §6 to say the reference alone decides such inputs.
- Bead: cq-p3fz

## §6 stand-in vs drivers' printing stubs
- Rule: §6 stand-in ("deterministic of the name and argument bits, the checker's").
- Disagreement: none. The drivers' rule-27 stand-ins only print. Noted so nobody treats the printing stubs as the model.
- Evidence: `_tools/drivers.txt`.
- Request: none.
- Bead: cq-tltm

## 129 declares `cqrt_qram_store_i32_hl` with four parameters
- Rule: BACKEND_ABI §1.10, `void cqrt_qram_store_<W>_hl(i32 m, i64 addr, i32 v)`.
- Disagreement: `examples/129_quantum_ptr_select_store/quantum_ptr_select_store.lowered.ll` line 232 declares `@cqrt_qram_store_i32_hl(i32, i32, i64, i32)` (the `_controlled` shape); its calls pass three arguments. The reference does not run: evaluator `malformed_call`, every sample of both calls.
- Evidence: `cqcheck run 129_quantum_ptr_select_store --ours build/ref_as_ours --oracle c`, sample ptr_select_rmw(0, .5, 1, 2, .3, 5, .4): `cqrt_qram_store_i32_hl: 4 arguments (ABI §1.10)`, returns 0x2 != C's 0x9.
- Request: fix the declare. Not copied; the example stays red against the reference until then.
- Bead: cq-3s95

## Rule 6: the second operand of a bijective op in two dead rails is not named as kept (109)
- Rule: CR §6 item 1 (a rail live at exit is a leak unless a rule names it); rule 6 ("The old value is kept only when no such point exists: it escapes, it is the value or control rail of a kept store, it is measured, or a reader of it follows a non-diagonal gate on its image"); rule 5 sentence 1 (a rule-6 image is never uncomputed).
- Disagreement: rule 6's list does not name the case `sum = s + t` with s and t both dead: rule 6 cleans one operand against the sum; the other has no inverse left and its producer's `_unc` needs rails already freed. 2(x + a) mod 2^32 loses a bit of x + a, so one garbage rail must survive. 109's header names it ("s (IR %32 of the last trip, rule 6: the operand of s + t that is not cleaned)"). Which operand is cleaned is by no stated convention (109 cleans operand 0).
- Evidence: `examples/109_intrinsic_variants`, va_copy_q: `%105 = add(%86, %47); %106 = sub(%105, %47); copy(%106, %86); free(%86)`, `%47` stays live. The evaluator reads it as a rule-6 image (role `rule6_image`, rulings 2 A). Not a blocker: the construction and the kept rail are forced either way.
- Request: rule 6 to name the uncleaned operand in the kept list, and which operand is cleaned.
- Bead: cq-8h3a

## ABI 1.11 vs CR rule 16: no boundary before an effect entry's fields after an over-supplied format entry
- Rule: CR rule 16 ("`printf` is the format entry ... with its variadic arguments as fields by promoted IR type"); C11 7.21.6.1p2 (excess arguments are evaluated and otherwise ignored). CR wins over the non-normative ABI.
- Disagreement: ABI 1.11 says a format entry "is complete ... when the fields its format string consumes are written", and an effect's arguments "are the fields written to t since the previous entry", which hands the excess to the next effect: `printf("%d", a, b); raise(sig)` would call `raise(b, sig)`. `tape_fmt` precedes its fields and `tape_effect` follows its fields, so between the two calls the fields are one stream with no marker. For a callee the backend knows by name the split is determined (the effect takes its last arity fields). For an unknown callee, a null `name` or a variadic one (fprintf, open) nothing in the ABI determines it.
- Evidence: checker/rt/rt_tape.c `split_after_format`. On such a callee the evaluator gives the effect every waiting field and marks it `split_open`; compare.py `_split_gap` reports a C call with fewer arguments as this gap, verdict error, never FAIL (rulings 2 C).
- Request: the owner picks a boundary: (i) `cqrt_tape_effect*` takes the field count, or (ii) a format entry closes with `cqrt_tape_fmt_end(t)`.
- Bead: cq-6ucw

## ABI 1.11 "host memory, which the bus sees through the overlay" vs 1.10 on an INPUT entry's write (cross-reference)
- Rule: ABI 1.10 Overlay ("A write the backend itself makes for an effect entry (§1.11) is a bus store"), which governs (rulings 2 D): INPUT bytes are bus stores, classical ones leaving the cells HOST with the displaced content in a tape slot, so fgets overwrites a QUANTUM cell as C does.
- Disagreement: 1.11's "Memory the host call reads or writes is host memory, which the bus sees through the overlay" read alone, with 1.10's "A byte host code writes at a QUANTUM cell is not seen by the bus", would leave the stale cell. Loose wording, no contradiction once 1.10's specific sentence applies.
- Evidence: BACKEND_ABI.md §1.10, §1.11; checker/rt/rt_bus.c `tape_cstore`, tests/rt-bus `effect_cstore`.
- Request: 1.11 to cross-reference 1.10's sentence.
- Bead: cq-5c33
