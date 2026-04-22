# Reference Provenance Policy

## Policy statement

This project may read public accelerator repositories and documentation for conceptual learning only.

The implemented design must remain original:
- no copied source code,
- no copied module hierarchies,
- no copied interface contracts,
- no copied verification harnesses,
- no copied script structures.

## Approved conceptual references

- `D:\Repositories\ref_repos\*` (local curated repositories)
- Public TPU system architecture documentation

## Required engineering behavior

1. Re-derive design decisions in project language and project interfaces.
2. Implement modules from first principles within this repository.
3. Document adaptation rationale and intended bottleneck impact.
4. Avoid one-to-one structural mirroring of any single external design.

## Compliance checklist (for PR/review)

- [ ] New module is authored in this repo with original interface naming.
- [ ] Behavior description is written in our own spec language.
- [ ] Verification collateral is project-native and independently authored.
- [ ] Any external reference cited is treated as conceptual context only.
