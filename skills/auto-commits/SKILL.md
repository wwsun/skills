---
name: auto-commits
description: Use when the user wants to commit changes that span multiple modules, features, or logical groups, or specifically asks to split commits logically with user confirmation.
---

# Auto-Commits

## Overview
Ensure atomic and logical code commits by analyzing changes, proposing a grouped commit plan, and obtaining user confirmation before execution. 

**MANDATORY:** Always use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat(scope):`, `fix(scope):`, `chore:`) for all commit messages.

## When to Use
- Changes involve multiple independent features or bugfixes.
- Commits need to be "clean" and easy to review/revert.
- **NEVER** use when the user explicitly asks for a single "squashed" commit or provides a specific commit message for the entire set of changes.

## Core Pattern
### 1. Research & Grouping
Use `git status` and `git diff` to identify modified files. Group them by:
- **Module/Package:** (e.g., `packages/server` vs `packages/web`)
- **Functional Layer:** (e.g., DTOs/Services vs Controllers/UI)
- **Logic:** (e.g., Feature A vs Refactor B)

### 2. Propose Plan
Present a structured plan to the user using Conventional Commits:
- **Commit #1:** `feat(scope): descriptive message` -> `file1`, `file2`
- **Commit #2:** `fix(scope): descriptive message` -> `file3`
- ...

### 3. Confirm (MANDATORY)
Use `ask_user` or wait for a directive to confirm the plan. **DO NOT** execute `git commit` until the user says "OK" or provides adjustments.

### 4. Sequential Execution
Execute `git add <files>` followed by `git commit -m "<message>"` for each group in the plan.

## Quick Reference
| Step | Action | Tool |
|------|--------|------|
| **Analyze** | Check status/diff | `run_shell_command` |
| **Propose** | List groups & Conventional messages | Text Output |
| **Verify** | Ask for approval | `ask_user` |
| **Commit** | Add & Commit | `run_shell_command` |

## Common Mistakes
- **Non-Conventional Messages:** Using "Update files" or "Save changes" instead of `feat/fix/chore`.
- **Mixing Concerns:** Including UI changes in a "backend logic" commit.
- **Silent Execution:** Committing without showing the plan first.
- **Staging Pollution:** Not using `git reset` before starting to ensure a clean state for the plan.

## Implementation Example
Partner: "Commit these changes."
You: "I see changes in the server statistics and the web dashboard. Here is my plan using Conventional Commits:
1. `feat(server): add statistics service` -> `packages/server/app/service/statistics.ts` ...
2. `feat(web): update dashboard UI` -> `packages/web/src/...` 
Shall I proceed?"
Partner: "Looks good, go ahead."
[Execute commits...]
