# /sync: back up my work and get the latest

Sync every brain mounted under `internal/`. Convention: a folder named `individual-*` is an individual brain (push
freely); every other brain mounted under `internal/` is a shared brain (content is free to push, core changes go to
a review branch). Backend is plain git (GitHub by default). Use `GIT_TERMINAL_PROMPT=0` so git fails fast,
and report any auth error as one friendly line, never as raw git output.

## Step 0: Preflight

If `internal/` has no mounted brains, tell the person to run `/start` first and stop. Ensure each brain has a git
identity set (from `/start`); set it if empty.

## Step 1: Individual brains (free)

For each `internal/individual-*`:

```bash
git -C "$b" add -A
git -C "$b" commit -m "<name>: <short summary>"      # skip if nothing to commit
GIT_TERMINAL_PROMPT=0 git -C "$b" pull --rebase origin HEAD
GIT_TERMINAL_PROMPT=0 git -C "$b" push origin HEAD
```

On an auth error, say the backup did not go through (fix git access) and continue.

## Step 2: Shared brains (governed)

For each shared brain (every brain mounted under `internal/` not named `individual-*`):

1. Pull the latest release first: `git -C "$b" fetch origin` then merge the shared branch
   (`origin/main` or the brain's default). On a merge conflict on shared canon, do not force it: tell the
   person to ask the brain's maintainer, and include the conflicting file names.
2. Classify local changes (`git -C "$b" status --porcelain`):
   - **content** (free): paths under `outputs/` or `sessions/`.
   - **core** (needs review): anything else, especially `entities/`, `knowledge/`, `_system/`,
     `workflows/`, `automations/`, `tools/`, `bin/`, `docs/`, `data/`, and root orientation.
3. If **only content** changed: commit and push to the shared branch.
4. If **any core** changed: do NOT push to the shared branch. Park the whole changeset on a review branch
   so nothing core lands unreviewed:
   ```bash
   git -C "$b" switch -c "proposal/<name>-<topic>"
   git -C "$b" add -A && git -C "$b" commit -m "<name> proposal: <what and why>"
   GIT_TERMINAL_PROMPT=0 git -C "$b" push -u origin "proposal/<name>-<topic>"
   git -C "$b" switch <shared-branch>
   ```
   Then tell the person it changes the shared brain, so it is on a review branch; ask the brain's
   maintainer to review and merge. The working copy is back on the shared branch and clean.

   **Solo deployments:** when the person IS the brain's maintainer, there is no one else to ping; the
   review branch is still worth the pause, and they review it themselves. Show the diff, and on their
   approval merge and clean up:

   ```bash
   git -C "$b" diff <shared-branch>..proposal/<name>-<topic>
   git -C "$b" merge --no-ff "proposal/<name>-<topic>"
   GIT_TERMINAL_PROMPT=0 git -C "$b" push origin HEAD
   git -C "$b" branch -d "proposal/<name>-<topic>"
   GIT_TERMINAL_PROMPT=0 git -C "$b" push origin --delete "proposal/<name>-<topic>"
   ```

## Step 3: Refresh the command layer and capability index

```bash
bash .claude/refresh-commands.sh
```

It copies each mounted brain's `.claude/{commands,skills,agents,rules}` up into this root's `.claude/`
and never overwrites the harness's own commands. It reads only children of `internal/` that carry both
`.claude/` and `_system/validate.sh`, so an app repo's own `.claude/` is left alone.

Name collisions are resolved rather than silently won. A name only one brain carries stays plain; a
name several brains carry byte-identically is copied once, plain; a name several brains carry with
DIFFERENT content is copied once per brain under a tagged name (`co-promote.md`, `me-promote.md`) with
no plain version, so you always know whose version you ran. The first tagged name is the moment two
brains have started to diverge: say so out loud in the report, because it looks like a bug and is not.

It also writes `.claude/COPIED-FROM.md` provenance and regenerates `.claude/CAPABILITIES.md` (what each
brain holds, with a one-line when-to-use). New copies load after a Claude Code restart.

## Step 4: Report

In one short paragraph: what backed up where, whether a review branch was created and who to ping,
whether a new shared release came in, and how many commands and skills the refresh copied up. If the
refresh tagged anything for the first time, name it and say plainly that the two brains have diverged
on that entity and both versions are now reachable under their tagged names. Remind the person to
restart Claude Code to load newly copied commands.
