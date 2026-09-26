#!/usr/bin/env python3
"""enum_erase.py — the STATIC j8sk enumeration: every site in ir-pass/src/*.cpp
that deletes IR (instruction, block, function) directly or through an LLVM
utility, with its enclosing function and whether an explicit TaintSet scrub
(`Tainted.erase`, `scrubTaint`, `erase_value`, `BirthOrder.erase`) appears in
the 15 lines before it. Output: TSV on stdout + a summary on stderr."""
import glob, os, re, sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"
PAT = re.compile(
    r"(eraseFromParent\s*\(|RecursivelyDeleteTriviallyDeadInstructions\w*\s*\(|"
    r"DeleteDeadBlocks?\s*\(|removeUnreachableBlocks\w*\s*\(|MergeBlockIntoPredecessor\s*\(|"
    r"deleteValue\s*\(|\bdelete\s+[A-Za-z_]\w*\s*;|ConstantFoldTerminator\s*\(|"
    r"SimplifyInstructionsInBlock\s*\(|DeleteDeadPHIs\s*\(|InlineFunction\s*\(|"
    r"PromoteMemToReg\s*\(|removeDeadConstantUsers\s*\(|dropAllReferences\s*\(|"
    r"eraseDeadDecls\s*\(|FoldSingleEntryPHINodes\s*\(|MergeBasicBlockIntoOnlyPred\s*\(|"
    r"simplifyCFG\s*\(|EliminateDuplicatePHINodes\s*\(|removeFromParent\s*\()")
SCRUB = re.compile(r"Tainted\.erase|scrubTaint|erase_value|BirthOrder\.erase|HandleWidth\.erase|scrub\w*\(")
FNDEF = re.compile(r"^(?:[A-Za-z_][\w:<>,\s\*&]*?\s)?[\*&]?([A-Za-z_][\w:]*)\s*\([^;]*$")

rows = []
for f in sorted(glob.glob(f"{W}/ir-pass/src/*.cpp")):
    lines = open(f).read().splitlines()
    fn = "?"
    for i, l in enumerate(lines):
        s = l.split("//")[0]
        if l and not l[0].isspace() and not l.startswith(("//", "#", "}", "namespace", "using", "static const", "const ")):
            m = FNDEF.match(l)
            if m and m.group(1) not in ("if", "for", "while", "switch", "return"):
                fn = m.group(1)
        if l.lstrip().startswith("//"):
            continue
        m = PAT.search(s)
        if not m:
            continue
        call = m.group(1).rstrip("( ").strip()
        prior = "\n".join(lines[max(0, i - 15):i + 1])
        rows.append((os.path.basename(f), i + 1, fn, call, "yes" if SCRUB.search(prior) else "no", l.strip()[:90]))

print("file\tline\tenclosing\tcall\texplicit-scrub-within-15-lines\tsource")
for r in rows:
    print("\t".join(map(str, r)))
from collections import Counter
c = Counter(r[3] for r in rows)
print(f"sites={len(rows)} files={len(set(r[0] for r in rows))} explicit-scrub-near={sum(r[4]=='yes' for r in rows)} "
      + " ".join(f"{k}={v}" for k, v in c.most_common()), file=sys.stderr)
