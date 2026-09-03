# Tone

Use ASD-STE100 (Simplified Technical English) for prose. Beyond short active sentences, apply these rules, in every domain:

1. **One word, one meaning.** Pick one term per concept and reuse it verbatim.
Never vary wording for elegance; repetition is correct.
2. **Use the technical name of the actual artefact.** If the thing has a real
name in the system under discussion, use that name: "the ephemeral pipeline
and its two Harness services", not "the rig"; "the Terraform state bucket",
not "the backend". If a collective noun is genuinely needed, name the set
explicitly on first use, then use the short form.
3. **Reject metaphors borrowed from other physical domains.** These are the
most frequent offender. Replace them with the literal action
4. **Do not inherit vague vocabulary from source material.** When a prompt,
ticket, or existing document uses a metaphor, translate it to the technical
name in your own prose. Quote the original term only when identifying the
source text, and mark it as a quotation.

Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested.

# Shell

For tool calls use bash shell
The user uses the fish shell, all shell commands suggested to the user should use fish syntax

# Code comments

Only leave code comments in areas of unclear, non-idiomatic, or complex/magic looking code. Explanations of the intent of code is best left in READMEs.

# Commit messages

Should be completely in lowercase, and follow the standard in repositories with semantic commit

# PRs
## PR Format

PR descriptions should include the following sections:

- **Purpose** — What issue or need does this address?
- **Context** — What was happening prior, how will this address the issue?
- **Verification** — Steps taken to verify this change (or some unticked boxes for suggested steps that can verify this change)
- **Other changes** (optional) — Include this section when there are unusual or supplementary changes bundled in the PR

## PR Comments

Never comment on GitHub on behalf of the user without being asked to.

# Worktrunk (`wt`)

This user manages git worktrees for parallel agent workflows with [worktrunk](https://worktrunk.dev) (`github.com/max-sixty/worktrunk`). The binary is `wt`. Worktrees share the repository's tracked files but **not** untracked/gitignored files (secrets, `.env`, build caches)

# Tone Preference

Keep outputs reasonably concise.
