# internal/

Everything your own operation owns and operates end to end lives here, and it holds two kinds of
child that behave differently.

**The brains this harness mounts.** Your shared work brain (a company brain, or a department brain
that graduated to its own repo) and your individual brain (`individual-<your-name>/`). `/start`
clones these in from the remotes in `.claude/brains.conf`, and `/sync` keeps them backed up. These
are the folders you actually work in every day.

**Your other repos.** Product code, client-facing apps, tools: anything you own that is not a brain.
The harness registers these and routes to them, but never mounts them.

The harness tells the two apart structurally, not from a list: a child is treated as a mounted brain
when it carries both `.claude/` and `_system/validate.sh`, the marker every brain built from the
Infinite Brain OS starter has and no app repo does. That is why an app repo can carry its own
`.claude/` without its commands leaking into this root.

Each child is an independent git repo with its own remote and its own history. The harness ignores
everything under `internal/` except this file, and knows children only through their entries in
`repo-registry/`. Every child directory here must have exactly one registry entry, brains included;
an unregistered child is a posture violation. `/start` writes the entry for each brain it mounts; for
anything else use `/register-repo` or follow `ADD-A-BRAIN.md`.

Because children are ignored, the harness's git provides them no backup and no history. Each child's
backup story is its own remote, recorded in the `remote` field of its registry entry. A child with
`remote: local-only` has no backup at all until you give it one.

Two rules about a brain's remote, both handled by `/start`:

- A brain cloned from the public starter must have its origin re-pointed at a private repository you
  own before it counts as backed up; the public starter cannot be pushed to.
- A newborn individual brain starts as an empty private repository; the first `/save` plus `/sync`
  writes its initial commit. "You appear to have cloned an empty repository" is the expected state,
  not an error.

Nothing harness-owned may be placed in this folder beyond this README. A file that wants to live here
is either a child's file or it does not belong in the harness.
