# RHH Upstream Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply every clean change from RHH `master` to the dedicated integration branch and isolate all merge conflicts for review.

**Architecture:** Merge `RHH/master` into the existing integration branch without creating a merge commit. Git automatically applies non-overlapping changes; conflicts remain unmodified for subsystem-by-subsystem resolution after review.

**Tech Stack:** Git, pokeemerald-expansion C/assembly build system.

**Spec:** `docs/research/upstream-source-update-audit-2026-09-13.md`

## Global Constraints

- Preserve all existing autosave WIP and untracked test artifacts.
- Do not commit, push, or resolve conflicted hunks during the initial merge.
- Merge only `RHH/master` at `083b15cd6db8cade17c3f83f20807b3c8af6ad0d`.

---

### Task 1: Apply non-conflicting RHH changes

**Files:**

- Modify: Git index and all non-conflicting files selected by `git merge`
- Preserve: `src/overworld.c`, `src/save.c`, and `test/save.c` autosave WIP via Git autostash

- [ ] **Step 1: Confirm the branch and target revision**

Run: `git branch --show-current && git rev-parse RHH/master`

Expected: `chore/upstream-sync-audit-20260913` and `083b15cd6db8cade17c3f83f20807b3c8af6ad0d`.

- [ ] **Step 2: Start a non-committing, autostashed merge**

Run: `git merge --no-commit --no-ff --autostash RHH/master`

Expected: Git applies non-overlapping files and reports every conflict without creating a commit.

### Task 2: Inventory conflicts

**Files:**

- Inspect: every path returned by `git diff --name-only --diff-filter=U`
- Inspect: Git's `MERGE_AUTOSTASH` state

- [ ] **Step 1: List each unresolved path and conflict stage**

Run: `git diff --name-only --diff-filter=U && git ls-files -u`

Expected: a complete conflict inventory, grouped by subsystem in the handoff.

- [ ] **Step 2: Verify no merge commit or remote update occurred**

Run: `git status --short --branch && git log --oneline -1`

Expected: an in-progress merge with no new commit and no push.
