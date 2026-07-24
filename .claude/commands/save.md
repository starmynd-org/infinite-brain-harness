# /save: save my work

Commit work in every brain under `brains/` with the person's name on it. Commits only; pushing and the
review-branch logic are `/sync`'s job.

## Steps

1. Identity. Ensure `user.name` and `user.email` are set in each brain; ask once if empty.
2. Individual brains. For each `brains/individual-*` with changes, stage and commit with a short
   descriptive message, for example `<name>: draft ideas for the spring campaign`.
3. Shared brains. For each shared brain, commit ONLY what this session produced under `outputs/` or
   `sessions/`, with a message prefixed by the person's name. If the diff touches anything outside those
   folders (a core change), do NOT commit it here: leave it and say in one line that a core change is
   best handled by `/sync`, which routes it to a review branch.
4. Report in one or two plain sentences what was saved where. If nothing changed, say so and stop.

Do not push from this command. Pushing is `/sync`'s job.
