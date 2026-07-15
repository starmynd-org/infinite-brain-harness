# Add a Brain

The getting-started playbook for this harness. It covers the first brain, every later brain,
and app repos, because all of them go through the same four-step registration procedure. This
file is the single source of truth for that procedure; the `register-repo` command executes
it, and no other file restates it.

## Before you start

You have cloned the harness as your repos root and you are working at its root. The harness
tracks only its own files: everything you place under `internal/` or `external/` is ignored
by the harness's git and lives as an independent repo with its own remote and history.

## The first brain is the company brain

Every harness normally has exactly one company brain: the standard-setter, the shared
library, and the place agents orient into for cross-repo work. If the registry has no entry
with `repo_kind: brain` and `brain_tier: company` yet, that is the brain to add first. The
public brain starter at https://github.com/starmynd-org/infinite-brain-os is the intended
first clone.

## The four steps

### Step 1: Clone or create the child

Put the child where its ownership says it belongs:

- `internal/<slug>` for a repo your own operation owns and operates
- `external/<slug>` for a client-owned or co-operated repo
- `external/<group>/<slug>` when one client or partner has several repos; the group folder
  keeps them together

For a first company brain at a company called Acme:

```sh
git clone https://github.com/starmynd-org/infinite-brain-os.git internal/acme-brain
```

The slug you choose here is the slug the registry entry carries. Pick it once and keep it.

### Step 2: Create the registry entry

Copy `repo-registry/_template.md` to `repo-registry/<slug>.md` and fill every field. The
fields and their allowed values are listed inline in the template and explained in
`repo-registry/README.md`. Two rules bind the classification:

- a brain must declare its tier (`individual`, `department`, or `company`)
- an app must not carry a tier: omit the `brain_tier` line entirely

`repo-registry/example-company-brain.md` shows a complete, correctly filled entry for a
company brain.

### Step 3: Commit the registry entry

```sh
git add repo-registry/<slug>.md
git commit -m "Register <slug>"
```

The child itself stays untracked: the ignore posture excludes everything under `internal/`
and `external/`. Before you commit, `git status` at the harness root must show only the new
registry file. If it shows anything from inside the child's directory, stop; the posture is
broken and the problem must be fixed before anything is committed.

### Step 4: Verify routing

Open a fresh AI agent session at the harness root, with no other context, and confirm it
orients correctly:

- for a company brain: the agent reads the root orientation, resolves the registry to the
  new entry, and follows the brain's own startup inside `internal/<slug>`
- for any other child: the agent can state from the registry what the repo is, what kind it
  is, and where it lives

The first registered brain is normally the company brain, so the first run of this step is
the moment the whole root starts working.

## Adding a second brain

Same four steps. The usual second brains are:

- an individual brain for a new teammate: `repo_kind: brain`, `brain_tier: individual`
- a graduated department brain, split out of the company brain when a real trust boundary
  demands it: `repo_kind: brain`, `brain_tier: department`

No harness file outside `repo-registry/` changes when a brain is added. The orientation
files never name children; the registry is the routing table, so registration is the entire
integration.

Department graduation itself (deciding to split, moving the content, rewiring the company
brain) is run from inside the company brain with its own tooling. The harness only receives
the result: a new sibling under `internal/` and a new registry entry.

## Adding an app repo

Same four steps, with `repo_kind: app` and no `brain_tier` line. Product codebases and
client codebases are ordinary siblings: they get a registry entry so agents know what they
are, and nothing else about the harness changes.

## If something looks wrong

- a child directory exists but has no registry entry: that is a posture violation; create
  the entry (steps 2 through 4)
- a registry entry exists but its directory is gone: the entry is stale; set its status to
  `archived` or delete the entry
- `git status` at the root shows files from inside a child: the ignore posture is broken;
  fix `.gitignore` before committing anything
