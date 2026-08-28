---
name: push
allowed-tools: Bash(git push:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git status:*)
argument-hint: [branch]
description: Push committed changes to the given branch
---

## Task
Push the current commits to branch: **$1**

Steps:
- If `$1` is empty, push to the current branch (`git rev-parse --abbrev-ref HEAD`).
- Run `git push origin $1` (or the current branch if empty).
- If the branch has no upstream yet, use `git push -u origin <branch>`.
- Show the result. NEVER force-push unless I explicitly ask.
