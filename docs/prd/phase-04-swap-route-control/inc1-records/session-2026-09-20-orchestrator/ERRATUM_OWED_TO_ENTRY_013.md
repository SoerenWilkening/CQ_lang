# ⚠ ERRATUM OWED TO LAB ENTRY 013 — and the PROCESS DEFECT behind it

## The erratum (entry 014 must carry it, dated)

Entry 013's header records the close hash as **`286b53f7`**. That commit was
rewritten by `git pull --rebase` during the closing push and **is not reachable
from `main`**. The correct hash is **`4f752e06`**
(`records(2026-09-20): round 4's P1, and the corrections it forced in CLAUDE.md`),
and the sealing commit itself is `fd0d01b7`.

Verified: `git merge-base --is-ancestor 286b53f7 main` → false.

## ⚠ THIS IS THE THIRD INSTANCE AND THE SECOND IN ONE SESSION, SO IT IS A PROCESS DEFECT, NOT A MISTAKE

* Entry 012 recorded `e2fd1a16`, unreachable; entry 013 carried that erratum.
* **Entry 013 then did the same thing, in the session that wrote the erratum,
  about ninety seconds after sealing.**

Writing the erratum did nothing to prevent the repeat, because the erratum
describes a SYMPTOM. **The cause is ORDERING**: the close hash is read from
`HEAD` *before* `git pull --rebase`, and a rebase rewrites every unpushed commit.
No amount of care at the writing step can fix a value that is computed too early.

## THE FIX, which the next session must apply rather than re-derive

Seal AFTER the rebase, never before:

```
git pull --rebase                 # hashes are final only after this
H=$(git rev-parse --short=8 HEAD) # <- the close hash, now stable
# write $H into the entry header
tools/labreport/build.py --seal
git add -A docs/labreport && git commit    # the sealing commit itself
git push                          # push does NOT rewrite
```

⚠ **The sealing commit's own hash is still unknowable at seal time, and that is
fine** — the close hash names the last commit of the session's WORK, not the
commit that seals the record of it. What must be stable is the former, and after
the rebase it is.

⚠ **AND IF THE PUSH IS REJECTED AND A SECOND `pull --rebase` IS NEEDED, THE HASH
MOVES AGAIN.** Re-check `git merge-base --is-ancestor <recorded hash> main`
AFTER the push, every time, and treat a `false` as an erratum owed immediately —
not as something to notice next session. That check takes one second and is the
only thing that actually closes this loop.
