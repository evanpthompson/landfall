# Landfall — Claude Instructions

## TDD is non-negotiable

Every session follows Red → Green → Refactor. No production code is written without a failing test first.

### Required test coverage for every component

| What ships | Required tests |
|---|---|
| Every `Cubit` / `Bloc` | `bloc_test` suite covering **all** state transitions |
| Every public widget | Widget test + golden test at 1920×1080 |
| Every Serverpod endpoint | Integration test via Serverpod test framework |
| Every repository interface | Contract test running against both mock and real implementation |
| Every use case | Unit test covering success, failure, and edge cases |

### Test order — always

1. Write the test (it must fail)
2. Write the minimum production code to make it pass
3. Refactor if needed
4. Confirm all tests pass before moving on

### Before calling any feature "done"

- [ ] `bloc_test` suite exists for every new cubit with all states covered
- [ ] Widget test exists for every new widget
- [ ] Integration test exists for the end-to-end path
- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` is green across all packages

### Session planning

Every phase plan must list the tests to be written before listing the production code.
Format: "Test: [what it verifies] → Code: [what it implements]"

Never declare a feature complete without confirming all three levels (unit, widget/integration, end-to-end) are covered.

## Architecture

See `docs/architecture_decisions.md` for rationale on all major decisions.
See `docs/project_plan_v1.md` for the phased delivery plan.

## Commit discipline

- No AI attribution in commit messages (no Co-Authored-By lines)
- One logical change per commit
- Commit message describes the why, not the what
