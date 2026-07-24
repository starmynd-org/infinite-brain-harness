# /start: set up (or wake up) this workspace

Run this first on a new machine, and again each day. It establishes git access, clones your brains into
`brains/`, and syncs. Work autonomously and verify each step before the next; only stop for a sign-in the
person must click, and tell them exactly what to click. Report each step in one plain line. Set
`GIT_TERMINAL_PROMPT=0` so git fails fast instead of hanging on a credential prompt.

## Step 1: Git access (GitHub by default)

- Confirm git is installed and `user.name` and `user.email` are set. If not, set them (ask once).
- Confirm the git host is reachable and authenticated. GitHub is the default backend: check `gh auth
  status`, or an SSH key, or a credential helper. If a later clone fails with an auth error, tell the
  person to run `gh auth login` (or set up an SSH key) and retry. Never store a token in the repo. An
  alternate backend (a self-hosted or access-gated git host) only changes the remote URL and its
  sign-in; the rest of this command is unchanged.

## Step 2: Know which brains to mount

- Read `.claude/brains.conf`: one `folder = git-remote-url` per line, lines starting with `#` ignored.
- If it is missing or empty, ask the person for two remotes and write the file:
  - their **shared brain** (a company or department brain). If they have none, they can first clone the
    public starter `https://github.com/starmynd-org/infinite-brain-os.git` as their company brain.
  - their **individual brain**, named `individual-<their-name>`.
  `.claude/brains.conf` is local and git-ignored; it holds no secrets, only repo URLs.

## Step 3: Clone or refresh every brain

```bash
mkdir -p brains
# for each "folder = remote" line in .claude/brains.conf:
#   if brains/<folder>/.git is absent:  git clone <remote> brains/<folder>
#   else: leave it; /sync updates it.
```

On a clone auth failure, it is the Step 1 git-access issue, not a real error: fix auth and retry.

## Step 4: Sync

Run `/sync` to back up anything already here, pull the latest, and refresh the copied command layer and
the capability index.

## Step 5: Report

Give a short checklist: git access is working, which brains are present and at which commit, and that
`/workspace-help` explains the rest. Remind the person to **restart Claude Code** to load the brains' own
slash commands that `/sync` just copied up.
