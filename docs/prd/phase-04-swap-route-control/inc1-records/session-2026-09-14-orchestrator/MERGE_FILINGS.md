# Merge-gate filings — 2026-09-14. Three things this gate created or exposed that NOTHING in the tree
# reviews, written so the next agent starts from evidence rather than from prose.

Binary for every measurement here: `cq-opt 5c6f7490a81c7505…` / `libCQPass.so 5276f7ab7416b36b…`
(bit-identical before and after this gate's e2e conversion; no pass source was touched).

---

## FILING 1 — X5. The back-edge shape is now REACHABLE, and `ArmClassify.cpp`'s retirement trigger (3a) has a FALSE PREMISE.

**Status: OWED, not attempted.** The re-derivation the comment demands is deliberately NOT done here.

### What the trigger says

`ir-pass/src/ArmClassify.cpp`, RETIREMENT TRIGGER (3) — the dominance skip in F2's collider helper —
half **(3a), the CYCLIC HALF**, names bd `wx8g` **by name**:

> "**bd `test_C_libtooling-wx8g`, BY NAME**: the open over-decline that keeps every IN-LOOP state prep
> from reaching this function today (`control flow inside a loop body`) … **It is the ONLY reason the
> back-edge-φ shape is unreachable rather than merely narrowed** … **The day `wx8g` lands, the back-edge
> fixture pair is the tripwire: re-derive this skip against the shapes `wx8g` admits, and do not assume
> the φ case is the only cyclic one.**"

**`wx8g` landed in this merge.** The trigger fired here, by design, and nowhere else could it.

### What the fixture pair says — IT HELD

Both named tripwires are UNMOVED on the merged binary, with a **byte-identical** `CQ_CTRL_DBG` anchor
to the ORACLE, and `lit --filter backedge` is 4/4 green:

```
control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll     ORACLE D(F2) -> MERGED D(F2)
control_inplace_ry_reject_stateprep_backedge_nonphidesc_collider.ll  ORACLE D(F2) -> MERGED D(F2)
  both anchors:  decline [state prep seed is proven equal to the condition register]
                 at:   %c = icmp eq i32 %q, 7
```

### What is NEW, and it is the part to read twice

The premise "`wx8g` is the ONLY reason the back-edge-φ shape is unreachable" **is now false**. Three
probes built from the shapes `wx8g` admits (committed: `merge_gate_probes/x5{a,b,c}_*.c`):

| probe | ORACLE `f7b65d8c` | MERGED `5c6f7490` |
|---|---|---|
| `x5a_inloop_prep_backedge_carry.c` — an in-loop bare-`_Bool` state prep whose loop-header φ takes the region's MERGE-φ descendant **on its back edge**, i.e. precisely the available collider the dominance skip was narrowed for | `D: control flow inside a loop body` | **`D: state prep merged with a quantum register`** (F1), source-located `!dbg` |
| `x5b_inloop_prep_guard_collider.c` | `D: control flow inside a loop body` | **ACCEPT** — STRICT 2b clean, 9 trace lines |
| `x5c_inloop_ry_backedge_carry.c` | `D: control flow inside a loop body` | **ACCEPT** — STRICT 2b clean, 8 trace lines |

The fence that made the shape unreachable is gone. The back-edge shape now **reaches** the state-prep
fences and is adjudicated by them; the skip is **LIVE rather than vacuous**.

### What is and is not claimed

* **Nothing over-accepts** on anything this gate could construct — `x5a` declines, in the safe
  direction, with a real `file:line:col`.
* **The argument text in `ArmClassify.cpp` is STALE** and must not be cited as it stands.
* The trigger's own second sentence — *"do not assume the φ case is the only cyclic one"* — is exactly
  the part that cannot be discharged by these three probes. **That is the re-derivation, and it is owed.**

---

## FILING 2 — the F × P compositions. Two new ACCEPTS that NO single track's gate could see, and that NO review has cleared.

**Status: sound as far as this gate can measure; NOT Rule-13 cleared as a composition.**

Found by the merge gate's corpus attribution: of 290 movers, 8 are reproduced by no single-track
binary, and three of those are one shape.

```
                                    ORACLE      U       F                P       W       D       MERGED
trackP/review_r1_probes/
  r19_phi_and_prepcond.c / .s1.ll   D(F2)       D(F2)   D(control flow)  D(F2)   D(F2)   D(F2)   ACCEPT
session-2026-09-13/trackM/probes/
  m28.c                             D(F2)       D(F2)   D(control flow)  D(F2)   D(F2)   D(F2)   ACCEPT
```

Track F alone clears F2 and then hits the leaf-grammar wall; Track P alone admits the leaf and then
hits F2. **Only together do they accept.** Both are the same shape — *a condition TREE whose leaves
are preps' merge φs*:

```c
/* r19 — the PHASE consumer */                 /* m28 — the VALUE consumer */
bool b0 = cq_theta((bool)0, 0.5);              if (a >= 3){ b0 = cq_theta(b0, 0.5); }
bool b1 = 0;                                   if (b0 == 1) a -= 3;
if (b0) { b1 = cq_theta(b1, 0.5); }            if (a >= 3){ b1 = cq_theta(b1, 0.5); }
if (b1 && b0) cq_phi(0.3);                     if (b1 && b0) a -= 3;
```

**Measured on the merged binary** (both link and run; full traces in
`merge_gate_probes/`):

* `r19`: STRICT 2b `3 rail mint(s) of which 2 left allocated, 1 cqrt_free site(s): 1 verified, 0
  violation(s), 0 unproven`; 11 trace lines. The kickback sits on a `cqrt_toffoli(h0, h1, h2)` of the
  two rail leaves, `cqrt_rz_i1(h2, …)`, the Toffoli again, then `cqrt_free(h2)` — `h0`/`h1` are read
  **only as controls** (never `cqrt_x`-bracketed, never freed) and the ancilla returns to `|0⟩` before
  its free.
* `m28`: STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0
  violation(s), 0 unproven`; 29 trace lines — the shipped 2026-09-13 cascade stream extended by a
  two-leaf Toffoli flag and a controlled-copy merge, ancillas `h2`/`h7` CNOT/Toffoli-bracketed and
  freed, `h0`/`h1` only ever controls.

**Stated plainly: this is cleared BY MEASUREMENT and NOT BY REVIEW.** Track F's Rule-13 rounds saw a
binary on which these decline; Track P's did too. The group gate is the first and only thing that has
ever compiled them. A green suite, a clean stage 2b and a well-formed trace are exactly the evidence
Rule 2 says is *necessary and not sufficient*.

---

## FILING 3 — the three surviving `il*` × `bcar` over-declines.

**Status: over-decline, filed, not a blocker.** Full reasoning in `MERGE_TWIN_ADJUDICATION.md` §G6.

Track T predicted eight twin-matrix loop-message rows would flip when `wx8g` landed; **five did**.
These three did not, and they remain a live DISPOSITION MISMATCH — the rolled side declines while the
FLAT spelling of the same program lowers:

```
m_none_bilry_none_none_bcar    rolled D(control flow inside a loop body) · flat ACCEPT
m_none_nbilry_none_none_bcar   rolled D(same)                            · flat ACCEPT
m_none_bilprep_none_none_bcar  rolled D(same)                            · flat ACCEPT
```

**The blocker is the COMBINATION, and the matrix isolates it by measurement.** `bcar` re-rotates the
CONDITION rail inside the body (`b = cq_theta(b, 0.25);` at the top of every trip), so the condition
register is loop-carried and moves per activation; `wx8g`'s clause (c) covers the iteration-local
**target** rail. That the two are separable is measured, not argued: `m_none_bry_none_none_bcar` — the
same carried condition with NO iteration-local target — **did** flip. What survives is exactly
*iteration-local target rail × in-body-rotated condition rail*.

Probes committed: `merge_gate_probes/m_none_{bilry,nbilry,bilprep}_none_none_bcar_{rolled,flat}.c`.
Per the owner's ruling of 2026-09-11, an over-decline is a defect to remove, not a safety margin.
