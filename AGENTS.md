# Repos Root (Codex orientation)

This is the repos root: the shared-parent tier of the Infinite Brain topology. It is a thin,
versioned harness that carries orientation (this file and `CLAUDE.md`), routing (the rule
below plus the `register-repo` command), and the client workspace (`repo-registry/`). Nothing
else lives at this tier. Orient from this file first.

## Routing rule

1. Read the entries in `repo-registry/`. Every child repo under `internal/` or `external/`
   has exactly one entry recording its kind and, for a brain, its tier.
2. For cross-repo or general work, orient into the company brain: the entry with
   `repo_kind: brain` and `brain_tier: company`. Go to its path and follow that brain's own
   `AGENTS.md` startup from there.
3. If you were sent to a specific child repo, go straight to it and follow its own
   orientation files. The registry still tells you what kind of repo you are entering.

This file never names a specific child repo. The registry is the routing table, so this file
stays unchanged as children are added, renamed, and retired.

## Empty root

If the registry has no company brain yet, this root is new. Follow `ADD-A-BRAIN.md` to add
and register the first brain.

## The ownership axis

`internal/` holds repos this operation owns and operates end to end; `external/` holds repos
a client owns or that are co-operated with an outside party, with one client's several repos
grouped under `external/<group>/`. Every child in either folder is an independent git repo,
ignored by the harness and known to it only through its registry entry.

## What the harness never carries

No knowledge bases or doctrine, no agents, skills, rules, or workflows beyond the one
`register-repo` command, no child repo state (commits, secrets, queues, build artifacts), no
live runtime state, no metrics or data. If a file answers a question about a brain's
content, it belongs in that brain, not here.

## Mirror rule

`CLAUDE.md` is the Claude Code-facing mirror of this file. The two files carry the same
content and must be edited together.
