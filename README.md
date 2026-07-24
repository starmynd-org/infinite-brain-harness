# Infinite Brain Harness

A multi-brain workspace: the repos root you open in Claude Code (or Codex) to work across more than one
Infinite Brain at once. It mounts a few brains under `brains/`, routes your work to the right one, and
keeps them synced over git (GitHub by default). It doubles as a registry root for an operation that runs
many repos.

The engine is the Infinite Brain OS, the public brain starter at
https://github.com/starmynd-org/infinite-brain-os. The harness is the mount: it holds your brains side by
side and keeps agents oriented and synced across them.

## Why a tier above the brain

A brain repo is self-contained: it carries its own orientation, knowledge, and startup discipline. But
real work quickly spans more than one brain: a shared company or department brain everyone relies on, and
your own individual brain for scratch and research. Three problems appear the moment the second brain
exists:

1. An agent needs one place to orient from, or every session starts by guessing which brain is which.
2. A brain must not absorb its siblings. A brain that tracks other repos' state stops being a brain.
3. The brains need to sync. Your work must back up and the shared brain's releases must come down,
   without you running git by hand.

The harness solves all three. You open it, not a brain in isolation. It routes between the brains under
`brains/`, and its `/start` and `/sync` commands do the git so you never have to.

## The workspace (primary)

`brains/` holds the brains you work across, each an independent git repo:

- a **shared brain** (a company brain, or a department brain that graduated to its own repo): the default
  working surface, the canon everyone relies on;
- your **individual brain** (`individual-<name>/`): your own layer, fewer guardrails.

The routing rule: real and shared work goes to the shared brain; anything experimental or unproven starts
in your individual brain; proven work is promoted up, never edited into the shared brain directly.

### Quickstart

1. Clone this repository to where you want your root, and open it in Claude Code:

   ```sh
   git clone https://github.com/starmynd-org/infinite-brain-harness.git repos
   ```

2. In the chat, run **`/start`**. It establishes git access (GitHub by default), clones your brains into
   `brains/`, and runs `/sync`. On a brand-new root with no brains configured yet, it walks you through
   pointing at your shared brain (clone the public starter as your company brain if you have none) and
   your individual brain.
3. Work. Real work in the shared brain, experiments in your own; `/sync` backs everything up and pulls
   the latest. `/workspace-help` explains the rest.

### Commands

| Command | What it does |
|---|---|
| `/start` | Set up or wake up the machine: git access, clone or refresh the brains, then `/sync`. |
| `/sync` | Push your individual brain; push shared-brain content; route shared-brain core changes to a `proposal/<slug>-<topic>` branch for review; pull the latest; refresh the copied command layer and the capability index. |
| `/save` | Commit every brain with your name on it, no push. |
| `/promote-to-department` | Package individual work for review before it reaches the shared brain. |
| `/workspace-help` | Explain the workspace in plain words. |
| `register-repo` | Register a child repo in the registry (see the registry root, below). |

Each brain's own commands, skills, agents, and rules are copied up into this root by `/sync` so they work
as slash commands here (after a Claude Code restart). `.claude/CAPABILITIES.md`, regenerated on sync,
lists what each brain holds so you route work to the right one.

## The registry root (secondary)

An operation that runs many repos, several brains plus product and client codebases, also uses this root
as a registry. Child repos live under `internal/` (repos you own) and `external/` (client-owned or
co-operated, grouped under `external/<group>/`), each an independent git repo the harness ignores and
knows only through a `repo-registry/` entry.

Brains come in three tiers: one **company brain** (the standard-setter and upstream core), an
**individual brain per person**, and **department brains** that graduate from folders to their own repo
only when a real trust boundary fires. **App repos** are ordinary siblings with `repo_kind: app`, no
brain ontology and no tier. To register a repo, follow `ADD-A-BRAIN.md` or run `register-repo`; the
result is one new file under `repo-registry/`. The registry is the full map of the root; `brains/` is the
subset you actively work across.

## Layout

| Path | What it is |
|---|---|
| `CLAUDE.md`, `AGENTS.md` | root orientation for Claude Code and Codex; mirrors of each other |
| `.claude/commands/` | the workspace commands (`start`, `sync`, `save`, `promote-to-department`, `workspace-help`) and `register-repo` |
| `.claude/refresh-commands.sh` | the copy-up and capability-index generator, run by `/start` and `/sync` |
| `.claude/settings.json` | the workspace's model pin and permission guards |
| `brains/` | the brains you work across; cloned in by `/start`, each an independent ignored repo |
| `ADD-A-BRAIN.md` | the registration procedure for the registry root |
| `internal/`, `external/` | registry-root children (ignored siblings) |
| `repo-registry/` | one entry per registered child |

## What the harness never carries

- no brain content of its own: knowledge, doctrine, and entities live inside a brain
- no child repo state: the brains under `brains/` and the children under `internal/`/`external/` are
  independent git repos with their own remotes; the harness ignores their contents and provides no backup
- no live runtime state or secrets: the copied command layer and the capability index are generated,
  git-ignored, and regenerated by `/sync`; they are read-only downstream and never a second source of
  truth; local agent settings stay untracked

## Local files

`.claude/CLAUDE.local.md` is available for personal, local-only notes; the shipped `.gitignore` keeps it
and the rest of local agent state (`settings.local.json`, `mcp-servers.json`) out of git.

## License

MIT. See `LICENSE`.
