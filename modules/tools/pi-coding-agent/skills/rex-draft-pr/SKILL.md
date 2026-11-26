---
name: rex-draft-pr
description: Start a fresh Pi session in a new Rex tab and a new Worktrunk worktree to implement a request, verify it, and open a draft GitHub PR. Use when asked to spawn a Rex tab with a worktree and complete a change with a draft PR.
compatibility: Run from a Git repository inside a local Rex tab. Requires rex, wt, jq, pi, and authenticated GitHub CLI access.
---

# Rex draft PR

## Create the worktree and tab

1. Check that `REX_SESSION` and `REX_BLOCK` identify your current Rex tab: `rex --autostart=false block inspect -s "$REX_SESSION" "$REX_BLOCK" --json`. Check that `wt`, `jq`, `pi`, and `gh` are available. If Rex or Git is unavailable, report the blocker. Do not start a new Rex session, switch the current tab with `spawn_worktree`, or implement the change in the current checkout.
2. Use the requested branch name or choose a short, unused branch name that follows repository conventions. Use the requested base branch, or let Worktrunk select the default branch. From the repository root, run `wt switch --create --no-cd --format json "$branch"` (add `--base "$base"` before the branch when specified). Keep Worktrunk hooks enabled. Do not bypass hook approval, overwrite an existing branch, or reuse an existing worktree without permission. On success, check that `created_branch` is `true` and read `path` and `base_branch` from the JSON. Do not infer the path from the branch name. Do not copy changes from the current checkout.
3. Set `task_prompt` to the worker instructions below followed by the repository context, branch, base branch, and the complete implementation request. Include any relevant decisions or links from the current session because the new Pi session does not inherit the conversation. Pass the prompt as one quoted argument, not shell code or typed terminal input. Start Pi with its configured model unless the user requested a model. Use a short task label for the tab:

   ```bash
   rex --autostart=false window new -s "$REX_SESSION" -c "$worktree_path" \
     --shell=none --keep-open --json "$tab_label" -- "$(command -v pi)" -- "$task_prompt"
   ```

4. Report the tab label, branch, and worktree path. State that implementation and PR creation are in progress in the new tab, not complete. If Rex launch fails, report the worktree and error. After a timeout, inspect the session before retrying so you do not open a duplicate tab. Do not delete the worktree on failure.

## Instructions for the new Pi session

- Implement the request in this worktree. Read the repository instructions and run the relevant checks. Report failed or skipped checks accurately. Ask only when a missing decision or approval prevents safe, correct work.
- Review the diff, stage only the intended changes, and commit using repository conventions. Push the branch to the intended GitHub remote without force. Do not publish unrelated changes or create an empty PR.
- The user requested a draft. Use `gh pr create --draft` with an explicit title and body, and set `--base` to the intended GitHub base branch. Use the repository PR template if present. Otherwise include **Purpose**, **Context**, and **Verification**, plus **Other changes** only if applicable. Do not ask whether to make the PR a draft. If a PR already exists for the branch, report its URL and status instead of creating a duplicate or changing its status. Never mark the PR ready, merge it, or post comments.
- Report the draft PR URL and verification results in this tab. If blocked, report what succeeded, what failed, and what is needed to continue. Leave the tab and worktree available to the user.
