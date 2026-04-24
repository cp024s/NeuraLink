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

## Issue and PR discipline

- Track each enhancement/bug as a GitHub issue.
- Reference issue IDs in PR titles and commit messages.
- Use draft PRs for long-running RTL feature branches.
- Require at least one review for `main` and `stable` merges.

## Milestones and releases

- Tag milestone drops with semantic labels such as:
  - `v0.1-rtl-bringup`
  - `v0.2-fpga-flow`
  - `v0.3-pd-research`
- Create release notes with:
  - validated boards
  - known limitations
  - reproduction commands

## Actions, Wiki, and Packages

- GitHub Actions:
  - run lint/smoke/testbench targets on every PR
  - archive benchmark artifacts on tagged runs
- Wiki:
  - mirror setup/execution docs for quick onboarding
- Packages:
  - publish prebuilt simulation containers or tool images where useful

## Cherry-pick usage

- Use cherry-pick for selective backporting of:
  - bug fixes
  - test infrastructure improvements
  - visualization/reporting updates
