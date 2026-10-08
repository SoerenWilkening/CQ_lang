# R3 — PHI taint and frozen-bit negation

Analytic clearance from independent reviewer `/root/dm7f16_review_r3`: PHI
replacement and erasure precede the owning taint refresh. Existing live quantum
seeds reach fresh predicates through `propagateFromSeeds`; constants remain
classical. No bounded negative ancestry proof is used. The outer specialization
fixpoint and final literal rechecks remain.

`xor %frozen, true` preserves the chosen stable bit. `collectCondTree` records
an untainted whole child of an AND/OR through `condLiteralAdmissible` before
walking that child, so the generated opaque classical negation uses the
existing literal path beneath a quantum node. This clears the reported mixed
condition shape; it does not establish a new mixed-xor or classical-root
capability. Clone adjoints still mirror captured gates.

The nexttoward trace correction changes only h114's unused undef realization
to +0.0. Saved stage-1 select `%114 = select %108, undef, %113` is consumed by
the final PHI only on the !%108 predecessor; the other predecessor uses %120.
The selected defined result, widths, borrowed handles and frees are preserved.

The three historical negative migrations were reviewed from source and owning
emitters: total classical f64 result routed as data; nested retained wrapping
i32 call; and normalized `[0,undef]` followed by classical edge predicates.
Their original diagnostic pipelines did not retain complete lowered modules,
so this review does not claim to have read those missing outputs. Positive
assertions were subsequently validated by the implementer's scoped green.

**0 tests, probes, builds, mutations or edits by this reviewer.**
