# register-repo

Register a child repo in this harness.

Read `ADD-A-BRAIN.md` at the harness root and execute its four-step registration procedure
exactly. That file is the single source of truth for the steps; do not improvise fields, do
not skip the verification step, and do not restate the procedure from memory.

Before executing, collect from the user whatever these require that was not given as an
argument:

- the child's slug and path (`internal/<slug>`, `external/<slug>`, or
  `external/<group>/<slug>`)
- its kind (`brain`, `app`, or `mixed`) and, for a brain, its tier
- its remote URL, or `local-only`

Invariants to hold while executing:

- exactly one harness file is created: `repo-registry/<slug>.md`, from
  `repo-registry/_template.md`, with every field filled
- the child itself stays untracked; `git status` at the harness root shows only the new
  registry entry
- finish by confirming the routing rule in `CLAUDE.md` resolves as expected with the new
  entry in place
