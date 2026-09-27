W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'


def sub(path, old, new, n=1):
    p = W + path
    s = open(p).read()
    assert s.count(old) == n, (path, s.count(old), old[:70])
    s = s.replace(old, new)
    open(p, 'w').write(s)


# ---- qce6: the implicit section and the non-default address space; drop the redundant test
sub('ir-pass/src/QramLowering.cpp', '''    // Not in a NAMED SECTION and not at an ABSOLUTE / fixed address: that is how
    // MMIO is declared, and the owner's reachability ruling (2026-09-26, bd memory
    // `owner-ruling-volatile-unreachable-object-2026-09-26`) requires both. A
    // pointer built from an integer (`*(volatile int *)0x40000000`) never strips to
    // a `GlobalVariable`, so it never reaches this loop.
    if (G.hasSection() || G.isAbsoluteSymbolRef() ||
        G.getMetadata(LLVMContext::MD_absolute_symbol))
      continue;''', '''    // Not in a NAMED SECTION — explicit (`section "…"`) OR IMPLICIT (the
    // `bss-section`/`data-section`/`rodata-section`/`relro-section` attributes
    // `#pragma clang section` sets, which the backend honours and `hasSection()`
    // does not see: bd `qce6`, r4B F-YB-1, an MMIO `static volatile int STATUS;`
    // under the pragma folded to its initializer) — not at an ABSOLUTE / fixed
    // address (`isAbsoluteSymbolRef()`, which IS the `!absolute_symbol` test for a
    // global object — round 4 spelled it twice, r4B P3), and not in a NON-DEFAULT
    // ADDRESS SPACE (owner decision 2026-09-27, conservative: an address space is
    // how device / MMIO memory is declared on GPU and embedded targets). That is
    // how MMIO is declared, and the owner's reachability ruling (2026-09-26, bd
    // memory `owner-ruling-volatile-unreachable-object-2026-09-26`) excludes it. A
    // pointer built from an integer (`*(volatile int *)0x40000000`) never strips
    // to a `GlobalVariable`, so it never reaches this loop.
    if (G.hasSection() || G.hasImplicitSection() || G.isAbsoluteSymbolRef() ||
        G.getAddressSpace() != 0)
      continue;''')

sub('ir-pass/include/QramLowering.h', '''// absolute/fixed address (that is how MMIO is declared). Every conjunct is a gate
// here; the section / absolute-address one was MISSING until bd vsfp round 4 (a
// `static volatile … __attribute__((section("…")))` global folded like any other,
// `lowering_reject_volatile_global_section.ll`).''', '''// absolute/fixed address (that is how MMIO is declared). Each conjunct is a gate
// here. ⚠ Round 4 wrote "Every conjunct is a gate here" when it had added only the
// EXPLICIT section and the absolute symbol; `#pragma clang section bss=/data=/
// rodata=/relro=` sets an IMPLICIT section `hasSection()` does not see, and an MMIO
// `static volatile int STATUS;` under the pragma still folded (bd `qce6`, r4B
// F-YB-1). Since round 5 the gate is: explicit section, implicit section
// (`hasImplicitSection()`), absolute symbol, and — owner decision 2026-09-27,
// conservative — any NON-DEFAULT ADDRESS SPACE (device memory). Pins:
// `lowering_reject_volatile_global_{section,absolute_symbol,pragma_bss,pragma_data,
// addrspace}.ll`.''')
sub('ir-pass/include/QramLowering.h', '''// any store, any escaping user, atomic, a named section or absolute symbol, a type
// the initializer cannot produce at that offset)''', '''// any store, any escaping user, atomic, a named section — explicit or pragma-implied —,
// an absolute symbol, a non-default address space, a type the initializer cannot
// produce at that offset)''')

# fixture headers' "non-section object" wording
sub('ir-pass/test/lowering_qram_volatile_fold.ll', '''; access to an internal, never-written, non-escaping, non-section object is not
; observable), NOT''', '''; access to an internal, never-written, non-escaping object that is in no named section —
; explicit or `#pragma clang section`-implied —, at no absolute address and in the default
; address space is not observable), NOT''')

# ---- w9xe: the SimplifyCFG claim
sub('ir-pass/src/DeadValueLiveness.cpp', '''      // What SimplifyCFG's `FoldTwoEntryPHINode` builds: through the folder, so
      // `select %c, i1 true, i1 false` IS `%c` (bd vsfp round 4: r3B `u1.ll`'s
      // cascaded fold otherwise left a logical `select i1` as a 4.4 data select's
      // condition, which the data-select grammar refuses — an over-decline against
      // the twin). `simplifySelectInst` returns only an EXISTING value equal to the
      // select, never a new instruction.''', '''      // `select %c, i1 true, i1 false` IS `%c`, so ask the folder first (bd vsfp
      // round 4: r3B `u1.ll`'s cascaded fold otherwise left a logical `select i1`
      // as a 4.4 data select's condition, which the data-select grammar refuses —
      // an over-decline against the twin). ⚠ Round 4's comment said this is what
      // SimplifyCFG's `FoldTwoEntryPHINode` builds — FALSE (bd `w9xe`, r4B F-YB-2,
      // measured): stock SimplifyCFG builds through `IRBuilder<NoFolder>` and emits
      // `select i1 %c, i1 true, i1 false`; the `-O1` twin loses it only in the LATER
      // InstCombine. The parity bar is SimplifyCFG + InstCombine, of which this is
      // one fold. `simplifySelectInst` returns only an EXISTING value (a constant,
      // `Cond`, `VT`, `VF` or an operand of `Cond`'s compare — all available at the
      // branch), never a new instruction.''')
sub('ir-pass/include/DeadValueLiveness.h', '''//   * the two-entry-φ fold goes through `simplifySelectInst` first (`select %c,
//     i1 true, i1 false` IS `%c`), as SimplifyCFG's own fold does;''', '''//   * the two-entry-φ fold goes through `simplifySelectInst` first (`select %c,
//     i1 true, i1 false` IS `%c`). ⚠ NOT "as SimplifyCFG's own fold does" (round
//     4's wording, bd `w9xe`): SimplifyCFG builds with `IRBuilder<NoFolder>`; the
//     `-O1` twin loses the select in InstCombine;''')
sub('ir-pass/test/lowering_volatile_globalfold_cascade.ll', '''; the tracked seed follows the first φ to its replacement and the fold goes through the folder
; (`simplifySelectInst`), so `select %c, i1 true, i1 false` IS `%c` and the second φ becomes''', '''; the tracked seed follows the first φ to its replacement and the fold asks the folder
; (`simplifySelectInst`; NOT what SimplifyCFG does — it builds with NoFolder and -O1 loses the
; select in InstCombine, bd w9xe), so `select %c, i1 true, i1 false` IS `%c` and the second φ becomes''')

# ---- F-YA-3: isCopyDestination retirement trigger
sub('ir-pass/src/Specialization.cpp', '''bool isCopyDestination(const Use &U) {''', '''//
// ⚠ RETIREMENT TRIGGER (L8; bd vsfp Rule-13 r4A F-YA-3). The test is NAME-keyed
// (`cqrt_copy_` + the last argument) and sound by ENUMERATION: every emitter rail
// that exists when `resolvePhantomCloneArgReads` asks is built by
// `cqrt_copy_<W>[_controlled]` with the destination last (`SelectMergeEmit`,
// `ClassicalCallArmEmit`, `SwitchValueEmit`'s preload and controlled copies,
// `SwitchDataMuxEmit`, the `IOSinkLowering` value mux); `BreakReversePlay`'s copies
// are minted later, and the tape-write / abort-park `OutputRails` have no users.
// The day an emitter builds a user-visible rail with `cqrt_cswap` / `cqrt_cnot` /
// `cqrt_toffoli` / `cqrt_x` (or a copy whose destination is not last) BEFORE this
// point, that traffic will read as a REAL read of the rail and a phantom-only rail
// will be accepted: widen this test to that emitter's write slots IN THE SAME CHANGE.
bool isCopyDestination(const Use &U) {''')
print('ok')
