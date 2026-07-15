# external/

Client-owned or co-operated repos live here: codebases a client owns, releases you maintain
for someone else, and anything operated jointly with an outside party. If your operation
owns and operates a repo end to end, it belongs in `internal/` instead.

When one client or partner has several repos, group them under one folder:
`external/<group>/<slug>`, for example `external/acme-corp/storefront`. The group folder
keeps a client's repos together and makes the ownership boundary visible in the tree.

Each child is an independent git repo with its own remote and its own history. The harness
ignores everything under `external/` except this file, and knows children only through their
entries in `repo-registry/`. Every child directory here, including each one inside a group
folder, must have exactly one registry entry; an unregistered child is a posture violation.
To add one, follow `ADD-A-BRAIN.md` at the harness root.

Because children are ignored, the harness's git provides them no backup and no history. Each
child's backup story is its own remote, recorded in the `remote` field of its registry
entry. A child with `remote: local-only` has no backup at all until you give it one.

Nothing harness-owned may be placed in this folder beyond this README. A file that wants to
live here is either a child's file or it does not belong in the harness.
