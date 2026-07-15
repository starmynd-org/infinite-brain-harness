# internal/

Repos your own operation owns and operates end to end live here: the company brain,
individual brains, graduated department brains, and your own product app repos.

Each child is an independent git repo with its own remote and its own history. The harness
ignores everything under `internal/` except this file, and knows children only through their
entries in `repo-registry/`. Every child directory here must have exactly one registry
entry; an unregistered child is a posture violation. To add one, follow `ADD-A-BRAIN.md` at
the harness root.

Because children are ignored, the harness's git provides them no backup and no history. Each
child's backup story is its own remote, recorded in the `remote` field of its registry
entry. A child with `remote: local-only` has no backup at all until you give it one.

Nothing harness-owned may be placed in this folder beyond this README. A file that wants to
live here is either a child's file or it does not belong in the harness.
