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
## 32: the reference keeps x where rule 6 cleans it
- Rule: 6 ("the old value is kept only when no such point exists": it escapes, it is the value or control rail of a kept
  store, it is measured, or a reader follows a non-diagonal gate on its image).
- Example: `y' = x + c` with x's only reader the add, y' the value rail of a kept store. x itself is not the store's
  value rail; a clean-up point exists (y' stays live), so rule 6 cleans x. The reference's header lists x as kept.
- Input: any; the C-oracle verdict agrees either way (the permutation part is the same), the kept multisets differ by x.
- Checked with `--oracle c` until CQ_spec regenerates 32 or rule 6 names the case.

## 114: `%71` is a `load i8 !range [0,2)` accessed at i1, against 176, 178, 179, 185
- Rule: CR rule 5, "used as i1 ... or a [0,2) range fact", which does not decide the shape: a `load i8 !range [0,2)` whose only user is `zext nneg i8 to i32`.
- Disagreement: 114 `%71` uses `qram_load_i1` and labels it "SPEC GAP 2"; 176 (`%34`, `%51`), 178 (`%29`), 179 (`%17`, `%34`), 185 (`%45`) use `qram_load_i8_hl` + `zext_i8_to_i32`. Value functions coincide; only the kept rail's width differs.
- Request: reword the parenthetical as "a trunc whose high bits a range fact proves 0" and re-emit 114 at i8. Not copied; 114 runs `--oracle c` until then.
- Bead: cq-ssyq

## 164: the reference forms in place across two seed stores with no `d` test, against rule 5 *Readers*
- Rule: CR rule 5 *Readers*: "With several changes in the interval `d` is the AND of their tests, computed before the first of them, where the one copy is taken; a change of any other kind, a change whose address is not yet computed at that point, or an address rail `p`, makes `d` the constant 0 (the copy, no branch)." Rule 5 *Memory*: "no rule asks at compile time whether two addresses differ (the one run-time test of two classical addresses is the in-place form's *Readers* clause)". CR rule 26 lists 164 as "regeneration owed".
- Disagreement: `struct big p = {x0, b, c}; cq_theta(&p.a, tx)`. The interval from `store %0, ptr %5` holds the stores at `%6` and `%7`, and `%7 = gep %5, 16` follows the first of them, so d is the constant 0: load copy before the first change, Ry on the copy (frozen, rule 2), kept store. The reference's `%15`..`%17` (both entries) swap cell a with no copy and no test. On cell b of `byval_large_two` the rule gives the `d` branch (`%8` is computed before the first change, the store at `%8`); the reference's `%17` again has no branch.
- Evidence: `cqcheck run 164_byval_large --oracle both`: s6=fail, c=pass, verifier=pass, "1 rail(s) i64 ... kept on our side that the reference does not keep" (the rotated copy, value a); `--oracle c`: c=pass, verifier=pass. Permutation part and rotation list agree with the C program.
- Request: regenerate 164 by the clause, or, if the owner wants the form there, say that a classical address computed in the interval from values live at its start counts as computed at that point. 164 runs `--oracle c` until then. Not copied.
- Bead: cq-bj01

## 175: the reference declares its libm clones only, so it pins no value or kept rail for them, against rules 14 and 18
- Rule: rule 18 ("Library code is injected source ... lifted like any callee"; rulings Q5: musl in the v1 bundle) and rule 14 (a loop with a quantum exit runs K trips and keeps a_K). The lifted bodies hold such loops (`__rem_pio2_large`).
- Disagreement: `libm_quantum.lowered.ll` lines 24 and 289-290 ("THE CLONE BODIES ARE DECLARED ONLY") call `__cq_q_exp_1`, `__cq_q_atan2_10`, `__cq_q_sin_1`, `__cq_q_log_1`, `__cq_q_pow_10` with no body. The reference therefore has no K cut and no a_K rail, and its value is whatever the checker's stand-in computes. It is not a §6 oracle for these two entries.
- Evidence: `cqcheck run 175 --oracle both`: c=pass, verifier=pass, s6=fail. Input x=0xc0183da9a01f78dc, y=1: ours and C give 0xbff67a932c9a5b41 (musl atan2); the stand-in gives ...42 (host libm, cq-xuzb0). With the stand-in linked to the bundle in a local probe (not committed), the failure moves to x=0x434f45777737523b, y=0xc0103f2d152bc924: ours 0x40433415a4c865b5 (loops cut at K=4), reference 0x4043191c0437c0f2 (the uncut body). The C oracle stops that sample at K=4 at `cap:__rem_pio2_large:%32` and returns at K=8.
- Request: give 175 the clone bodies as built from the bundle, or state that its third and fourth entries witness call sites and signatures only. Not copied; 175 runs `--oracle c` until then.
- Bead: cq-5jrs1
## 95: the reference uncomputes the carried overflow_arg_area by the reverse loop, against rule 6 *In a rolled loop* (109 follows it)
- Rule: CR rule 6, *In a rolled loop*: "a carried value whose trip update is such a bijection and whose trip predicate does not read it ... is cleaned in the body of the same trip ... A final carried rail that nothing reads after the loop stays allocated (kept, §6)"; *Bijections*: "a select whose arms are such updates of `y` or `y` itself (125) and whose condition does not read `y`".
- Disagreement: `examples/95_varargs/varargs.lowered.ll` line 47 (SPEC GAP: "Read here: the chain is uncomputed by the reverse loop, so its old values are not dead in the trip and rule 6 does not fire") and line 164 (`select_i64_unc` of `%45`). The update `%23 = phi ptr [%11, %16], [%21, %20]` is such a select under `gp_offset < 41`, which does not read `%11`, so rule 6 fires; its "nothing could then return it to |0>" is what the clause's last sentence answers. `examples/109_intrinsic_variants` has the same va_arg walk and follows the rule (header: "the final overflow_arg_area of each walk ... a dead rule-6 image").
- Evidence: `cqcheck run 95_varargs --oracle both`: s6=fail, c=pass, verifier=pass, "1 rail(s) i64 with values ('heap', 40) ... kept on our side that the reference does not keep": block + 24, the final overflow_arg_area of the third trip, a rule-named kept rail and no leak. Nothing else differs.
- Request: regenerate 95 as 109, dropping the SPEC GAP. 95 runs `--oracle c` until then. Not copied.
- Bead: cq-h72ng

## 73: memcpy_quantum's reference keeps x, against rule 6 *In a rolled loop* (75 cleans it)
- Rule: CR rule 6, *In a rolled loop*: "A loop-invariant rail read by such an update in every trip is cleaned from the last trip's image on the exit edge, and kept on a zero-trip path (75)"; "The old value is kept only when no such point exists".
- Disagreement: `examples/73_memcpy_array/memcpy_array.lowered.ll` line 13 lists x as kept in memcpy_quantum, and `%11` is never cleaned after line 128 (`%16 = add_i32_hl(%11, %15)`, the fill `a[i] = x + i`, a bijection in x). None of the listed exceptions holds: x is no value rail of a store (x + i is), nothing reads it later, and no non-diagonal gate acts on the image. 75 has the same loop and cleans x (`sub_i32_hl`, `copy_i32`, lines 66, 67). The fill loop runs 4 trips, so no zero-trip path exists.
- Evidence: `cqcheck run 73_memcpy_array --oracle both`: s6=fail, c=pass, verifier=pass, "1 rail(s) i32 with values 0 0 0 0 1 1 1 1 4294967295 ... the reference keeps are not kept on our side", which is x; our rail x + 3 stays kept and x is freed at 0 (the evaluator checks it). Nothing else differs.
- Request: regenerate 73 by the clause. 73 runs `--oracle c` until then. Not copied.
- Bead: cq-xlqo1
