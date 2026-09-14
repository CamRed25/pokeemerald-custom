# Upstream and source update audit — 2026-09-13

## Scope and method

This is a read-only audit of the configured Git remotes and GitHub's public API.
It covers the fork (`origin`), the RHH base, and the three donor repositories
whose code is already integrated into this fork. Results were checked on
2026-09-13/14 UTC. No source branch or issue was changed.

## Provenance

| Role | Repository | Evidence in this fork |
| --- | --- | --- |
| Fork/origin | [CamRed25/pokeemerald-custom](https://github.com/CamRed25/pokeemerald-custom) | Configured as `origin`; `custom` is the integration branch. |
| Base upstream | [rh-hideout/pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion) | `custom`'s merge-base with `RHH/master` is `4dc3dc658850e8c4477058772624bde0678dd95b` (`Fix movement type playing between trainer move and player face`, 2026-08-25). It is also tagged locally as `clean-expansion-base` / `baseline-rhh`. |
| Quest menu, registered-item menu, soft wild-level scaling | [ebears/pokeemerald-bear](https://github.com/ebears/pokeemerald-bear) | `next.md` records Objectives 9, 11, and 12 as ports from this donor. |
| Catch Mode and move-info icons | [worpbane/pokeemerald-worped-ex](https://github.com/worpbane/pokeemerald-worped-ex) | `next.md` records Objectives 15a and 15b as ports from this donor. |
| Key Item Wheel | [zanderb27/emerald-plus](https://github.com/zanderb27/emerald-plus) | `next.md` records Objective 10 as a port from this donor. |
| Historical/reference-only remote | [monhacks/infusedemerald](https://github.com/monhacks/infusedemerald) | Configured as `infused`, but not listed as a completed-feature donor in the current donor map. |

## Current update status

### RHH base: update is available and should be planned separately

GitHub's [compare API](https://api.github.com/repos/rh-hideout/pokeemerald-expansion/compare/4dc3dc658850e8c4477058772624bde0678dd95b...083b15cd6db8cade17c3f83f20807b3c8af6ad0d)
reports that RHH `master` (`083b15cd6db8cade17c3f83f20807b3c8af6ad0d`,
2026-09-13) is **220 commits ahead** of the fork base and has no commits
behind it. The fork's `custom` branch is itself 35 commits beyond that base,
including its independently developed features; the current autosave work is
uncommitted and therefore outside that count.

This is not a safe cherry-pick-sized maintenance update. It includes the
1.16.4 and 1.17.0 releases, a pret merge, battle-engine refactors, map-header
changes, and generated-data changes. Several merged upstream commits overlap
areas modified by this fork:

- [#10365](https://github.com/rh-hideout/pokeemerald-expansion/pull/10365)
  fixes an off-by-one error for category icons; relevant to Objective 15b.
- [#10404](https://github.com/rh-hideout/pokeemerald-expansion/pull/10404)
  fixes move-info argument-field sizing, and
  [#10541](https://github.com/rh-hideout/pokeemerald-expansion/pull/10541)
  adds effectiveness indicators; both are relevant to the modified battle UI.
- [#10753](https://github.com/rh-hideout/pokeemerald-expansion/pull/10753)
  changes overworld encounter sound behavior, and
  [#10776](https://github.com/rh-hideout/pokeemerald-expansion/pull/10776)
  fixes heap corruption in shiny wild-battle tests; both warrant attention
  around the fork's wild-encounter customization.
- [#10779](https://github.com/rh-hideout/pokeemerald-expansion/pull/10779)
  updates terrain access during AI calculations. This is unrelated to the
  donor ports but illustrates that the upstream update is still actively
  changing core battle code.

### Feature donors: no default-branch update or open PR queue

The configured default heads reported by `git ls-remote` match the locally
tracked donor heads. GitHub's open-pull-request endpoint returned an empty
list for each repository.

| Repository | Default head | Result |
| --- | --- | --- |
| [ebears/pokeemerald-bear](https://github.com/ebears/pokeemerald-bear) | `494749d818fd8e99d24bd1263040c6b1f22808a9` (2023-05-09) | No default-branch change; no open PRs. |
| [worpbane/pokeemerald-worped-ex](https://github.com/worpbane/pokeemerald-worped-ex) | `bc906dcc68ca722cd1769ead0f6d3030b1b1ceee` (2026-07-04) | No default-branch change; no open PRs. |
| [zanderb27/emerald-plus](https://github.com/zanderb27/emerald-plus) | `b4aecc057b0f691506805af8882795eb8a2b2111` (2023-11-06) | No default-branch change; no open PRs. |
| [monhacks/infusedemerald](https://github.com/monhacks/infusedemerald) | `9d5ccb2e1dc5ebf88ab6cf6e6213c73fe6d71677` (2025-05-13) | Historical/reference-only remote, not a completed-feature donor; no open PRs. Treat its topic branches as unvetted references, not updates to merge. |

The donor repositories do expose assorted topic branches, but none represents
a new default-branch update or an open pull request. The project policy in
`next.md` remains appropriate: use donors as narrowly scoped references rather
than synchronizing their histories.

## Open PRs and issues worth monitoring

`origin` has no open PRs. RHH has a large open-PR queue, so only items
connected to this fork's merged components
or planned work are listed below.

| Item | Status | Why it matters |
| --- | --- | --- |
| [RHH #10164 — Wild encounter refactor](https://github.com/rh-hideout/pokeemerald-expansion/pull/10164) | Open, targets `upcoming` | It can conflict with the fork's soft-level-scaling change in `src/wild_encounter.c`; review before any future RHH sync. |
| [RHH #10617 — battle-interface refactor](https://github.com/rh-hideout/pokeemerald-expansion/pull/10617) | Open draft, targets `upcoming` | Directly overlaps Catch Mode and move-info UI work. Do not build more battle-interface ports atop it without first deciding whether to adopt it. |
| [RHH #9005 — optional move type icons](https://github.com/rh-hideout/pokeemerald-expansion/pull/9005) | Open draft, targets `upcoming` | Conceptually overlaps Objective 15b, though the fork already has its own icon implementation. |
| [RHH #9449](https://github.com/rh-hideout/pokeemerald-expansion/pull/9449) and [#10479](https://github.com/rh-hideout/pokeemerald-expansion/pull/10479) — battle status/info menu | Open, target `upcoming` | Potential future QoL candidates; neither should be merged casually because both touch battle UI. |
| [RHH #8760](https://github.com/rh-hideout/pokeemerald-expansion/issues/8760) / [#8763](https://github.com/rh-hideout/pokeemerald-expansion/pull/8763) — wild-item capture behavior | Issue remains open; fix PR is open to `master` | Relevant to planned Objective 20 (wild held-item drops). Re-evaluate this pair before implementing that objective. |
| [RHH #6692 — mining minigame](https://github.com/rh-hideout/pokeemerald-expansion/pull/6692) | Open, targets `upcoming` | A possible future-content candidate, not a maintenance update. |

The listed PR statuses were returned directly by GitHub's public API. This is
a targeted relevance audit, not a claim that no other RHH issue or PR is
relevant.

## Recommendation

1. **Do not merge a donor repository.** There is no donor-side default-branch
   update or open PR that calls for one.
2. **Schedule a dedicated RHH-upstream integration branch before the next
   broad feature port.** Start from the current integration branch only after
   preserving/committing the in-progress autosave work. Merge or rebase the
   220-commit RHH update as one reviewed migration, resolve conflicts by
   subsystem, and run the full build/test/runtime suite. Do not combine it
   with Autosave or another objective.
3. **Before that integration, inspect and decide on the five overlap items
   above.** In particular, decide whether RHH's newer move-info/category-icon
   work supersedes parts of Objective 15b, and retain the fork's soft-level
   scaling when reconciling the wild-encounter refactor.
4. **Monitor, do not adopt, RHH `upcoming` PRs.** They are not on `master` and
   include large unfinished refactors. Re-run this audit when the dedicated
   RHH integration branch is started.
