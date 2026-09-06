# Migration manifest: the row shape

The manifest is the plan. One row per repository, plus rows for the parts of an estate that are not
repositories and are therefore invisible to every git-shaped tool.

`inventory.sh` produces the measured half. A person supplies the decided half. The two must not be
mixed in one file by hand: a measurement that someone edited is no longer a measurement.

## Measured columns, written by `inventory.sh`

| Column | Meaning |
|---|---|
| `kind` | `root`, `internal`, `external`, `external-group` |
| `path` | path relative to the root being inventoried |
| `branch` | the branch actually checked out right now |
| `default_branch` | what `origin/HEAD` says, or `unknown` |
| `head` | commit SHA at the time of the inventory |
| `dirty` | count of modified tracked paths |
| `untracked` | count of untracked paths |
| `worktrees` | linked worktrees the repository knows about |
| `prunable` | how many of those git currently believes are gone. **Verify before believing** |
| `outside_root` | linked worktrees whose path is outside the root after drive-letter normalisation |
| `risk` | the class below |

## Risk classes, ranked by what is lost rather than by size

- `irreplaceable`: no remote. The move is the only other copy that will ever exist. A mistake here is
  not recoverable by re-cloning, because there is nothing to clone from.
- `worktree-metadata-at-risk`: the repository has linked worktrees that git currently reports as
  prunable. Copying is not the danger; tidying up afterwards is.
- `carries-uncommitted`: modified or untracked paths that no clone reproduces.
- `routine`: clean, has a remote, no linked worktrees.

A repository can qualify for several. The class recorded is the most severe.

## Decided columns, supplied by the operator

| Column | Values | Notes |
|---|---|---|
| `include` | `yes` / `no` | A `no` on an `irreplaceable` row is a deletion decision and must be stated as one |
| `target` | path under the new root | Two rows may never resolve to the same target; the rehearsal refuses that plan before copying |
| `audience` | `personal` / `company` / `department` / `client` | Feeds `DOMAIN-MAP.md`; determines who may mount it |
| `owner` | who owns the repository, not who operates it | For `external/` rows this is the client, and it governs consent |
| `backup` | the remote, or `local-only` | Copied from the measurement; restated here because it drives sequencing |

## Rows that are not repositories

Every one of these is a way a migration can succeed on paper and fail in use. They belong in the
manifest with an explicit disposition.

- **Untracked directories inside the root**: checkpoint snapshots, `node_modules`, scratch worktree
  roots. Each needs `travels` or `stays`, decided rather than defaulted.
- **Agent state keyed by the workspace path.** Claude Code stores per-project state in a directory
  whose name is the workspace path with separators replaced. Renaming the root produces a different
  key, so the history is not lost, it is orphaned: sessions simply start empty and nothing reports a
  problem. Directories keyed to paths *inside* the root are orphaned by the same rename.
- **Absolute symlinks that point into the estate.** They break on a rename and fail silently. The
  operator's memory directory is one of these today.
- **Anything outside the filesystem**: scheduled tasks, cron entries, service units, IDE workspace
  files, shell aliases, tool configuration holding absolute paths. `CUTOVER-AND-RECOVERY.md` carries
  the enumeration; the manifest carries one row each so nothing is silently assumed.

## Why the filled manifest is not in this repository

It names client repositories and their remotes. See `README.md`. `inventory.sh` refuses to write
inside this repository rather than trusting a convention.
