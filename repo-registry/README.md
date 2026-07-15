# Client workspace

The harness's routing table. One plain-markdown entry per child repo, named
`repo-registry/<slug>.md`. Root orientation (`CLAUDE.md` and `AGENTS.md`) reads this folder
to decide where an agent goes first, so the registry is the only place the harness records
what its children are. The orientation files never name children; entries here do.

## The routing rule this registry feeds

An agent at the harness root reads the entries and orients into the company brain: the entry
with `repo_kind: brain` and `brain_tier: company`. From there it follows that brain's own
startup. An agent sent to a specific child goes straight to that child, using its entry to
know what kind of repo it is entering.

The norm is one company brain per harness. Tier resolves orientation: company first for
cross-repo work. If a root ever runs several company-tier brains, the `primary_job`
sentences decide which one a given task belongs to, but the harness does not optimize for
that shape.

## When an entry is required

Coverage rule: every child directory directly under `internal/` or `external/` (or under an
external group folder) has exactly one entry here. An unregistered child is a posture
violation. An entry whose directory no longer exists is stale; archive or delete it.

Entries are created by the four-step procedure in `ADD-A-BRAIN.md`, from `_template.md`.
The `register-repo` command executes the same procedure.

## The fields

Every entry records nine fields:

| Field | Values | Notes |
|---|---|---|
| repo | the slug, matching the directory name | |
| path | `internal/<slug>` or `external/<slug>`, harness-relative | grouping allowed: `external/<group>/<slug>` |
| ownership | `internal` or `external` | must match the top-level folder in `path` |
| repo_kind | `brain`, `app`, or `mixed` | what the repo fundamentally is |
| brain_tier | `individual`, `department`, or `company` | only when `repo_kind` is `brain` or `mixed`; the line is omitted for `app` |
| primary_job | one sentence | what the repo is for |
| status | `active`, `supporting`, or `archived` | `active` is worked in; `supporting` is referenced but not driven; `archived` is kept for record only |
| remote | the origin URL, or `local-only` | the child's backup story lives here |
| added | the date the entry was created | |

Each entry ends with a `## Notes` section for risks, caveats, and boundaries. A healthy
entry with nothing to flag writes the single word "None" rather than leaving it empty.

## Files here

- `_template.md`: the entry template; copy it to `<slug>.md` and fill every field
- `example-company-brain.md`: a worked example, a brain starter clone registered as the
  company brain of a fictional company
