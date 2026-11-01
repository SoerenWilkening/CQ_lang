"""The progress table (module chk-report, NORTHSTAR principle 7): rule -> witnesses -> passing.

Witnesses come from the text of CONSTRUCTION_RULES.md §3, never from a quoted list: each rule (and
each italic sub-case bullet of a rule, rule 14's loop cases) ends its witness clause with
"— NN, NN, …". Parenthesized remarks inside the clause are stripped (as for the examples' Rules:
headers in cq-arch's partition), as are non-numeric items such as "new example required (§8)". A
rule or sub-case with no clause is listed with no witnesses.

`passing`/`failing` read the verdicts the last `cqcheck run` stored (report.verdict_store()). An
example passes iff it is green (report.green: §6, C-oracle and verifier verdicts all pass and no
uncovered target; an UNCOVERED example is listed as failing: never counted green); an example with no stored
verdict is failing (nothing proved it). tests/progress.tsv has the columns rule, witnesses,
passing, failing; each of the last three is a comma-separated list of example numbers.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

from cqcheck import report

RULE_START = re.compile(r"^(\d+)\.\s+\*\*(.+?)\*\*")
SUBCASE_START = re.compile(r"^\s+-\s+\*(?!\*)(.+?)\*")
BULLET = re.compile(r"^\s+-\s")
SECTION = re.compile(r"^##\s+(\d+)\.")


@dataclass(frozen=True)
class RuleRow:
    rule: str                 # "4 Opcode lowering, always out of place." / "14 Loops: Classical bound, quantum body"
    witnesses: Tuple[str, ...]  # example numbers as CR writes them ("01", "187")


def _strip_parens(s: str) -> str:
    out, depth = [], 0
    for c in s:
        if c == "(":
            depth += 1
        elif c == ")":
            depth = max(0, depth - 1)
        elif depth == 0:
            out.append(c)
    return "".join(out)


def witness_clause(text: str) -> Tuple[str, ...]:
    """Example numbers of the witness clause of one rule's text (lines joined by spaces)."""
    m = None
    for m in re.finditer(r"(?:^|\s)—\s+(?=\d)", text):
        pass
    if m is None:
        return ()
    clause = _strip_parens(text[m.end():])
    nums = []
    for item in re.split(r"[;,]", clause):
        item = item.strip().rstrip(".").strip()
        if re.fullmatch(r"\d{2,3}", item):
            nums.append(item)
    return tuple(nums)


def _clean_title(t: str) -> str:
    return re.sub(r"[`*]", "", t).strip().rstrip(".").strip()


def _bullet_title(line: str) -> str:
    """A plain bullet's label: its text up to the first ':' (or its first eight words)."""
    text = line.split("-", 1)[1].strip()
    head = text.split(":", 1)[0] if ":" in text[:90] else " ".join(text.split()[:8])
    return _clean_title(head)


def parse_rules(cr_text: str) -> List[RuleRow]:
    """Every rule of CR §3 in order, rule 14 split into its sub-cases."""
    lines = cr_text.splitlines()
    try:
        start = next(i for i, l in enumerate(lines) if (m := SECTION.match(l)) and m.group(1) == "3")
    except StopIteration:
        raise ValueError("CONSTRUCTION_RULES.md has no section 3")
    end = next((i for i in range(start + 1, len(lines)) if SECTION.match(lines[i])), len(lines))

    # Split §3 into rules, each into its head and its italic sub-case bullets.
    rules: List[Tuple[str, str, List[str], List[Tuple[str, List[str]]]]] = []
    for line in lines[start + 1:end]:
        m = RULE_START.match(line)
        if m:
            rules.append((m.group(1), _clean_title(m.group(2)), [line], []))
            continue
        if not rules:
            continue
        if BULLET.match(line):
            # Every bullet is a candidate sub-case; a rule becomes one row per bullet only when
            # several bullets carry their own witness clause (rule 14's loop cases).
            sm = SUBCASE_START.match(line)
            title = _clean_title(sm.group(1)) if sm and not line.lstrip().startswith("- **") \
                else _bullet_title(line)
            rules[-1][3].append((title, [line]))
        elif rules[-1][3]:
            rules[-1][3][-1][1].append(line)
        else:
            rules[-1][2].append(line)

    rows: List[RuleRow] = []
    for num, title, head, subs in rules:
        head_w = witness_clause(" ".join(head))
        sub_w = [(t, witness_clause(" ".join(b))) for t, b in subs]
        # Split only when several bullets carry their own clause (rule 14); a single trailing clause
        # after the last bullet (rules 16, 20) is the whole rule's.
        if sum(1 for _, w in sub_w if w) >= 2:
            if head_w:
                rows.append(RuleRow(f"{num} {title}", head_w))
            for t, w in sub_w:
                rows.append(RuleRow(f"{num} {title}: {t}", w))
        else:
            # Bullets with no clause of their own: the rule's clause (wherever it sits) is the rule's.
            all_text = " ".join(head + [l for _, b in subs for l in b])
            rows.append(RuleRow(f"{num} {title}", witness_clause(all_text)))
    nums = [int(r.rule.split()[0]) for r in rows]
    expected = list(range(1, max(nums) + 1)) if nums else []
    if sorted(set(nums)) != expected:
        raise ValueError(f"CR §3 rule numbers are not 1..N: {sorted(set(nums))}")
    return rows


def example_numbers(spec: Optional[Path] = None) -> Dict[str, str]:
    """int(NN) as a string -> NN_name, from the examples directory."""
    return {str(int(e.number)): e.name for e in report.all_examples(spec)}


def build_table(cr_text: str, verdicts: Dict[str, "report.Verdict"],
                examples: Dict[str, str]) -> Tuple[List[Tuple[str, str, str, str]], List[str]]:
    """Rows (rule, witnesses, passing, failing) and the problems found (a witness with no example)."""
    problems = []
    table = []
    for row in parse_rules(cr_text):
        passing, failing = [], []
        for w in row.witnesses:
            name = examples.get(str(int(w)))
            if name is None:
                problems.append(f"rule {row.rule}: witness {w} has no example directory")
                failing.append(w)
                continue
            v = verdicts.get(name)
            (passing if v is not None and report.green(v) else failing).append(w)
        table.append((row.rule, ", ".join(row.witnesses), ", ".join(passing), ", ".join(failing)))
    return table, problems


def tsv(table: Sequence[Tuple[str, str, str, str]]) -> str:
    out = ["rule\twitnesses\tpassing\tfailing"]
    for r in table:
        out.append("\t".join(c.replace("\t", " ") for c in r))
    return "\n".join(out) + "\n"


def write_progress(dest: Optional[Path] = None, spec: Optional[Path] = None) -> Tuple[Path, List, List[str]]:
    spec = spec or report.spec_dir()
    cr = (spec / "CONSTRUCTION_RULES.md").read_text()
    table, problems = build_table(cr, report.load_verdicts(), example_numbers(spec))
    dest = dest or (report.ROOT / "tests" / "progress.tsv")
    dest.write_text(tsv(table))
    return dest, table, problems
