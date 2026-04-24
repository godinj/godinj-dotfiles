---
name: repo-audit
description: Run a full-repo quality audit covering constitution, tests, architecture, and documentation.
---

Run a full-repo quality audit covering constitution constraints, test coverage, ARCHITECTURE.md adherence, deep module interfaces, and human documentation coverage.

Steps:

1. **Constitution Constraints** — Run `bash scripts/check_constitution.sh` from the repo root. Report each constraint by name with pass/fail. Verdict: PASS if exit code 0.

2. **Test Coverage** — Run `go test -cover ./...`. Extract per-package coverage percentages. Flag any package below 60%. Report repo-wide average. Verdict: PASS if average >= 60%.

3. **ARCHITECTURE.md Adherence** — Read `ARCHITECTURE.md` and verify:
   - Every directory under `internal/` and `cmd/` is listed in the Package Map section; no listed package is missing from disk
   - Each rule marked `[enforced]` has a corresponding constraint in `.drem/constraints.toml`
   - Each `shrink-only` exception in `constraints.toml` has a current metric at or below its baseline

4. **Deep Module Interfaces** — Evaluate `internal/` packages:
   - Export ratio: count exported vs total symbols in non-test `.go` files; flag any package exceeding 15% (unless grandfathered in `constraints.toml`)
   - Pass-throughs: identify functions that simply delegate to another package with no added logic; flag any package with more than 3 (unless grandfathered)
   - Interface placement: check that interfaces are defined at consumption sites, not provider sites

5. **Human Documentation Coverage** — Verify:
   - README.md exists and is non-empty at repo root
   - Every package in `internal/` with exported types/functions has a corresponding mention in README.md
   - `docs/` covers major subsystems (constraints, scoring, orchestrator, memory, merge)
   - No stale references in README.md or docs/ to files, functions, or packages that no longer exist

Parallelize checks 1, 2, and 5 as independent agents. Run checks 3 and 4 together since they share file reads.

Present results as a summary table:

```
| Dimension        | Verdict | Details                          |
|------------------|---------|----------------------------------|
| Constitution     | PASS    | 12/12 constraints pass           |
| Test Coverage    | FAIL    | avg 58%, agent/ at 32%           |
| Architecture     | PASS    | package map current              |
| Deep Modules     | FAIL    | tui/ export ratio 100% (gf'd)   |
| Documentation    | PASS    | no stale refs                    |
```

After the table, list each FAIL dimension with actionable remediation steps.
