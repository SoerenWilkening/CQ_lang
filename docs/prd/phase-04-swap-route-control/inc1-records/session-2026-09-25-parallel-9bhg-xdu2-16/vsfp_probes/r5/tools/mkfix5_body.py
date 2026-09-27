
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
