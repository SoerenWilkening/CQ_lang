; lowering_uncompute_compare_icmp_ule_qq.ll — witness restoration for the
; UNSIGNED-less-or-equal Q+Q data-position compare and its whole-DAG uncompute
; adjoint (bd `gowy`). PROVENANCE, stated precisely because the loose version of
; it ("dbab515 deleted 52 e2e slices") is FALSE and would send a future
; archaeologist hunting for files that were never removed: commit dbab515
; (`tkju`) deleted NOTHING. `git show --name-status --format='' dbab515` is 1 `A`
; + 75 `M` and ZERO `D`, and `tests/e2e/*.c` counts 249 both before and after.
; What dbab515 did was DE-VENDOR 52 `tests/e2e/slice_libm_real_*.c` IN PLACE —
; stripping the FICTIONAL openlibm SOFTWARE bodies those slices had vendored for
; Rule-18 HARDWARE keeps — and REGENERATE their `.expected.log` goldens. The
; slices all live on; what disappeared are the `cq_template_*` TRACE LINES the
; deleted software ladders used to emit. dbab515's own message tallies the
; damage: "SYMBOL COUNTS ACROSS ALL GOLDENS: +6 / -21 … 20 of those 21 now have
; NO witness anywhere, no golden and no lit fixture."
; `cq_template_icmp_ule_i32` and its void adjoint twin
; `cq_template_icmp_ule_i32_unc` are in that set: after dbab515 they exist solely
; in the generated runtime (`runtime/cq_templates.{h,c}`, minted from
; `tools/opcode_table.yaml`) with no e2e golden and no lit fixture exercising
; them. An ADJOINT twin with no witness is precisely the un-covered surface this
; project's silent miscompiles live on (Rule 13), so this cheap ir-pass fixture
; restores the witness without re-vendoring an e2e slice body.
;
; SHAPE. `q1 = cq_theta(x); q2 = cq_theta(y); w = (unsigned)q1 <= (unsigned)q2`
; — a DEAD, source-derived, tainted DATA-position compare with BOTH operands
; tainted, so it lowers to the QQ (two-handle) form `cq_template_icmp_ule_i32`,
; NOT the `_hl`/`_lh` handle+literal forms. The QQ symbol is genuinely distinct
; from the `_hl` one already covered by the e2e goldens and by the sibling
; `lowering_uncompute_compare_icmp.ll` (which pins `icmp slt ... , 5` → `_hl`);
; the naming grammar is predicate-exact AND arity-exact, so neither witnesses
; this one.
;
; PREDICATE ALGEBRA — why no other predicate's fixture can stand in for `ule`.
; `OpcodeSupport.cpp` keeps the integer predicate set CLOSED under operand-swap
; (`getSwappedPredicate`: `ugt`<->`ult`, `uge`<->`ule`) and the set also contains
; each predicate's negation (`ule` is `¬ugt`). So `ule` is one NEGATION
; (`getInversePredicate`) away from `ugt` and one operand-SWAP away from `uge`.
; Do not conflate the two mechanisms: the pass's `flipPredicate`
; (`OpcodeSupport.cpp:110`) IS the operand-swap and nothing else — its body is
; literally `return CmpInst::getSwappedPredicate(pred);` — so
; `flipPredicate(uge) == ule`, NOT `flipPredicate(ugt) == ule`. (The negation is
; reached only through `CmpInst::getInversePredicate`, which `CompareLowering.cpp`
; applies for the g5gi swapped-successor guarded-store arm.) NEITHER relation
; lets one symbol witness another: the emitted template name embeds the predicate
; VERBATIM (`cq_template_<op>_<pred>_<W>`), the pass performs no
; canonicalization to a representative predicate, and each predicate gets its own
; generated body plus its own `_unc` row. A green `ugt` or `uge` fixture proves
; exactly nothing about the `ule` row — hence this file, alongside its `ugt`/`ult`
; QQ siblings in the same batch.
;
; THE PHYSICS PINNED HERE.
;   * DD-3 SLOT ORDER. The void `_unc` emitter (`EmitInverse.cpp`) is
;     shape-agnostic: it PREPENDS the forward result `out` and then copies the
;     forward operands in their ORIGINAL order. For the QQ compare that means
;     forward `cq_template_icmp_ule_i32(a, b)` MUST adjoint to
;     `cq_template_icmp_ule_i32_unc(out, a, b)` — `a` stays in slot 1, `b` stays
;     in slot 2. A swapped pair here is a verify-clean WRONG UNITARY and would
;     silently compute `b <= a` (i.e. `uge`) on the reversal leg, failing to
;     restore the flag rail to |0>; the CHECK below binds all three handles by
;     IDENTITY so a swap cannot pass.
;   * LIFO, LEAF-FIRST. Uncomputation runs the recovered DAG in reverse program
;     order: the dead `zext` widen-flag LEAF reverses FIRST, then the compare,
;     then the two rotation roots in reverse ALLOCATION order (`%h1` before
;     `%h`). Any other order reads a rail that has already been restored/freed.
;   * STILL-LIVE SOURCE AT EACH ADJOINT STEP. The embedded compare
;     `|a,b,c> -> |a,b, c XOR (a<=b)>` is a self-inverse PERMUTATION (never a
;     phase — no dephasing, Rule 7), so its `_unc` clears the flag rail by
;     RECOMPUTING `a<=b` from the sources and XOR-ing. That is only correct while
;     BOTH sources are still live and still hold their forward values: LIFO
;     guarantees it, and here `%h`/`%h1` are visibly un-rotated and un-freed at
;     the moment `..._unc` reads them.
;   * PROVEN-RESTORED FREE (Rule 6) — and the two rail classes are NOT in the
;     same state at their free, so do not flatten this to "everything is freed at
;     |0>". A DERIVED rail is born |0> and its void `_unc` XORs the recomputed
;     value straight back out, so the cast rail after `zext..._unc` and the flag
;     rail after `icmp_ule..._unc` genuinely DO reach |0>. A ROOT rail does not:
;     `cqrt_alloc_i32(%x)` initialises it to the alloc-time CLASSICAL BASIS STATE
;     |x> (from the data operand), and `ry(-theta)` restores THAT state, not |0>.
;     So each root is KEPT, never freed (bd 5c5b, libcqops vmz9): this file used
;     to license a root `cqrt_free` as "provably DISENTANGLED and in a known
;     classical basis state", which is measurement immunity, not the |0> proof
;     `cqrt_free` requires. No rail is freed dirty; a dirty free is a hidden
;     measurement, and the backend's free certificate convicts it.
;   * FREE ADJACENCY IS ITSELF THE RULE-6 CHECK. Each `cqrt_free` below is pinned
;     with `CHECK-NEXT` directly on the adjoint that restored its rail, so a
;     stray re-dirtying gate slipped between them (e.g. `cqrt_x` on the rail
;     after its `_unc` zeroed it — a verify-clean dirty free) FAILS the fixture.
;     Nothing else covers that at the lit layer: `tools/free_pairing_check.py` is
;     an e2e stage-2b gate over linked slices and never runs on `.ll` fixtures.
;   * THE ADJOINT IS THE VOID `_unc`, NEVER THE FRESH-MINTING `_inv`. The
;     whole-DAG uncompute spine must reverse IN PLACE on the existing rail; an
;     `_inv` would allocate a fresh result handle and leave the original rail
;     dirty. FileCheck scopes a trailing `CHECK-NOT` to [last positive match ->
;     EOF], which here is `ret void` plus the declare block — and that is exactly
;     the region a stray `_inv` mint would surface in, because the lowered
;     module's declare block mirrors the emitted-symbol set one-for-one, so an
;     `_inv` call necessarily drags a `declare … @…_inv` into the guarded tail.
;     The `cq_theta_` guard bites there too: the pass ERASES the now-unused
;     `declare i32 @cq_theta_si32`, so its absence is a real witness that the
;     intrinsic surface is fully consumed rather than left dangling.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %c  = icmp ule i32 %q1, %q2   ; Q+Q tainted data-position compare -> QQ flag
  %w  = zext i1 %c to i32       ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; Forward: two theta roots (alloc + ry each), the QQ compare flag reading BOTH
; live roots, then the dead zext widen off the flag.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ule_i32(i32 %[[H]], i32 %[[H1]])
; CHECK-NEXT: %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
;
; Reversal (LIFO, leaf-first). CHECK-NEXT throughout, verified against the real
; lowered output: the adjoint block is genuinely CONTIGUOUS, so nothing may be
; inserted into or reordered within it — and in particular no gate may be slipped
; between a restoring adjoint and the `cqrt_free` that follows it (Rule 6).
;   1. the zext LEAF adjoint reads the still-live flag rail, then that cast rail
;      is |0> and is freed;
;   2. the compare adjoint recomputes `ule` from the STILL-LIVE %[[H]], %[[H1]]
;      in DD-3 slot order (out, a, b), clearing the flag rail, which is then |0>
;      and freed;
;   3. the roots un-rotate in reverse allocation order (%[[H1]] first), each
;      returning to its alloc-time classical basis state (|y>, then |x>) — NOT
;      |0>, see the Rule-6 bullet above — so neither is freed.
; All handles are i32 (Rule 15); every adjoint is the VOID `_unc`.
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST]], i32 %[[CMP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CAST]])
; CHECK-NEXT: call void @cq_template_icmp_ule_i32_unc(i32 %[[CMP]], i32 %[[H]], i32 %[[H1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: ret void
;
; No fresh-minting `_inv` twin for either pinned `_unc`; the intrinsic is gone.
; CHECK-NOT: cq_template_icmp_ule_i32_inv
; CHECK-NOT: cq_template_zext_i1_to_i32_inv
; CHECK-NOT: cq_theta_
