# Version Control Guidelines (Optional)

These practices are recommended while the project is still in rapid iteration mode.

## Branching

- Create one feature branch per workstream:
  - `fix/cleanup-and-visuals`
  - `fix/scheduler-integration`
  - `fix/fpga-wrapper`

## Commit style

- Keep commits small and testable.
- Prefer one logical change per commit (for easier cherry-picks).
- Include validation evidence in commit messages when possible.

## Merge strategy

- Merge to main only after:
  - `make clean && make demo` succeeds.
  - Metrics artifacts are generated.
  - Documentation for new commands is updated.

## Cherry-pick usage

- Use cherry-pick for selective backporting of:
  - bug fixes
  - test infrastructure improvements
  - visualization/reporting updates
