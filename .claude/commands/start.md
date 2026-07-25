# /start: set up (or wake up) this workspace

Run this first on a new machine, and again each day. It establishes git access, clones your brains into
`brains/`, validates and registers them, and syncs. Work autonomously and verify each step before the
next; only stop for a sign-in the person must click, and tell them exactly what to click. Report each
step in one plain line. Set `GIT_TERMINAL_PROMPT=0` so git fails fast instead of hanging on a credential
prompt.

## Step 1: Git access (GitHub by default)

- Confirm git is installed and `user.name` and `user.email` are set. If not, set them (ask once).
- Confirm the git host is reachable and authenticated. GitHub is the default backend: check `gh auth
  status`, or an SSH key, or a credential helper. If `gh` is not installed, point the person at
  https://cli.github.com/ (one installer per OS), then have them run `gh auth login` and pick HTTPS plus
  browser sign-in; an SSH key per GitHub's docs works equally well. If a later clone fails with an auth
  error, it is this step unfinished: fix auth and retry. Never store a token in the repo. An alternate
  backend (a self-hosted or access-gated git host) only changes the remote URL and its sign-in; the rest
  of this command is unchanged.

## Step 2: Know which brains to mount

- Read `.claude/brains.conf`: one `folder = git-remote-url` per line, lines starting with `#` ignored.
- If it exists, go to Step 3. If it is missing or empty, ask the person which case they are in:
  - **They already have brains** (a team member joining an existing deployment): ask for the two
    remotes, their **shared brain** (a company or department brain) and their **individual brain**
    (named `individual-<their-name>`), and write the file.
  - **They are starting from zero** (a solo learner, no existing repos): create both brains now, per
    Step 2a. Every remote written to `brains.conf` must be a repository the person can push to; never
    write the public starter's URL there.
  `.claude/brains.conf` is local and git-ignored; it holds no secrets, only repo URLs.

### Step 2a: Starting from zero (solo path)

1. **Company brain from the public starter.** Clone the starter, then immediately re-point origin at a
   new private repository the person owns: the public starter cannot be pushed to, so until origin is
   re-pointed the brain has no backup and every later `/sync` push would fail.

   ```bash
   git clone https://github.com/starmynd-org/infinite-brain-os.git brains/<name>-brain
   gh repo create <name>-brain --private        # or create an empty private repo in the GitHub web UI
   git -C brains/<name>-brain remote set-url origin https://github.com/<user>/<name>-brain.git
   GIT_TERMINAL_PROMPT=0 git -C brains/<name>-brain push -u origin main
   ```

2. **Individual brain.** A newborn individual brain is an empty private repository, nothing more; the
   first `/save` plus `/sync` writes its initial commit. When git says "You appear to have cloned an
   empty repository", that is the expected state, not an error.

   ```bash
   gh repo create individual-<name> --private
   git clone https://github.com/<user>/individual-<name>.git brains/individual-<name>
   ```

3. Write both lines into `.claude/brains.conf` with the person's own remote URLs.

## Step 3: Clone or refresh every brain

```bash
mkdir -p brains
# for each "folder = remote" line in .claude/brains.conf:
#   if brains/<folder>/.git is absent:  git clone <remote> brains/<folder>
#   else: leave it; /sync updates it.
```

On a clone auth failure, it is the Step 1 git-access issue, not a real error: fix auth and retry.

## Step 4: Validate every brain that can validate

For each brain under `brains/` that carries `_system/validate.sh` (any brain built from the starter):

```bash
(cd brains/<folder> && bash _system/validate.sh)
```

A fresh clone exits 0 with "All checks passed" (a small set of known warnings on the shipped example
content is part of the baseline). A non-zero exit on a fresh clone means the clone or the environment is
broken; stop and report it before doing anything else.

## Step 5: Register each brain

Each mounted brain gets one entry in `repo-registry/` so any agent orienting at this root knows what it
is. For each brain not yet registered: copy `repo-registry/_template.md` to
`repo-registry/<folder>.md`, fill every field (`repo_kind: brain`; `brain_tier: company` for the shared
brain, `individual` for the personal one; `remote:` is the person's own URL from `brains.conf`), and
commit the entry at this root. `ADD-A-BRAIN.md` documents the fields. Note for solo learners: this root
was cloned from the public harness, so registry commits stay local until you give the root its own
private remote the same way as in Step 2a; local-only is fine to start.

## Step 6: Sync

Run `/sync` to back up anything already here, pull the latest, and refresh the copied command layer and
the capability index.

## Step 7: Restart and report

1. Give a short checklist: git access is working, which brains are present and at which commit, that
   each validating brain passed, and that each brain has a registry entry.
2. Tell the person to **restart Claude Code now**. The brains' own slash commands that `/sync` just
   copied up load only on restart; until then they do not appear, which otherwise looks like a failed
   install. After the restart, `/workspace-help` explains the rest.
