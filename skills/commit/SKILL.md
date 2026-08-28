---
name: commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git commit:*), Bash(git log:*)
argument-hint: [optional scope or note]
description: Create a Conventional Commit in English, no AI attribution
---

## Context
- Status: !`git status`
- Staged diff: !`git diff --cached`
- Unstaged diff: !`git diff`
- Recent commits (style reference): !`git log --oneline -10`

## Task
Create a git commit for the current changes.

Rules:
- Write the ENTIRE commit message in English.
- Use Conventional Commits types: feat, fix, chore, docs, refactor, test, perf, build, ci, style.
- Subject: `<type>(<optional-scope>): <concise summary>`, imperative mood, <= 72 chars.
- In the body, list what was done as bullet points (one per meaningful change).
- If nothing is staged, `git add` the relevant files first.
- NEVER add AI/Claude attribution: no "Co-Authored-By", no "Generated with Claude Code",
  no emoji byline, no mention of Claude anywhere.
- If arguments were provided, use them as scope/context hint: $ARGUMENTS
