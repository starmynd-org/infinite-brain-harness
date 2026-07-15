# Infinite Brain Harness

The repos root for an Infinite Brain deployment. You clone this repository as the parent
directory your brains and app repos live in. It carries exactly three things: orientation for
AI agents (`CLAUDE.md` and `AGENTS.md`), a routing rule that sends every agent to the right
child repo, and a registry that records what each child is. Nothing else.

The engine is the Infinite Brain OS, the public brain starter at
https://github.com/starmynd-org/infinite-brain-os. The harness is the mount: it holds one or
more brains and any number of app repos side by side and keeps agents oriented across them.

## Why a tier above the brain

A brain repo is self-contained: it carries its own orientation, knowledge, and startup
discipline. But a real operation quickly runs more than one repo. A company brain, a personal
brain per teammate, a product codebase, a client codebase. Three problems appear the moment
the second repo exists:

1. An agent landing at the top of the machine needs one place to orient from, or every
   session starts with guesswork about which repo is which.
2. The brain must not absorb its siblings. A brain that starts tracking other repos' state
   stops being a brain and becomes a junk drawer.
3. An unversioned root rots. Orientation notes scattered in an untracked folder drift out of
   date the first week nobody maintains them.

The harness solves all three by being a thin, versioned repo that is itself the root. It
orients, it routes, and it registers. It never carries content of its own beyond that, so it
almost never changes: children come and go, and only the registry moves.

## The tier story

Brains in a harness come in three tiers, and the harness grows through them in order:

1. **Start with one company brain.** Clone the public brain starter into `internal/` and
   register it with `repo_kind: brain` and `brain_tier: company`. It is the standard-setter
   and the upstream core everything else in the root vendors from.
2. **Add an individual brain per person.** Every person who works in the system gets their
   own brain repo (`brain_tier: individual`), their scratch-and-research layer. A solo
   adopter may run only the company brain at first; that collapse is the pre-team special
   case, and it unwinds the moment a second person arrives.
3. **Departments stay folders inside the company brain until a trust boundary fires.** A
   department graduates to its own sibling repo (`brain_tier: department`) only when a real
   person needs access to that department without standing access to the whole company
   brain, or when a client-facing or compliance boundary demands isolation. Never on a
   schedule, never for symmetry.
4. **App repos are ordinary siblings.** Product and client codebases register as
   `repo_kind: app`, with no brain ontology and no tier. A thin `.claude/` folder for
   product-development commands is normal in an app repo; a knowledge graph is not.

## Quickstart

1. Clone this repository to the place you want your repos root to live, and open a shell at
   its root:

   ```sh
   git clone https://github.com/starmynd-org/infinite-brain-harness.git repos
   ```

   (That URL is the proposed public home of this repository; if it was published under a
   different name, use the URL you actually cloned from.)

2. Clone the public brain starter as your company brain, under the slug you want it to
   carry. For a company called Acme:

   ```sh
   git clone https://github.com/starmynd-org/infinite-brain-os.git internal/acme-brain
   ```

   As a health check on the fresh clone, run the starter's own validation script from
   inside it: `bash _system/validate.sh`, run in `internal/acme-brain`, should exit 0.

3. Register it. Follow the four-step procedure in `ADD-A-BRAIN.md`, or run the
   `register-repo` command from Claude Code, which executes the same procedure. The result
   is one new file, `repo-registry/acme-brain.md`, and nothing else: the brain itself stays
   untracked by the harness on purpose.
4. Verify. Open an AI agent at the harness root with no other context. It should read
   `CLAUDE.md` (or `AGENTS.md`), resolve the registry to your company brain, and follow that
   brain's own startup. If it does, the root works.

Adding a second brain or an app repo later is the same four steps. See `ADD-A-BRAIN.md`.

## Layout

| Path | What it is |
|---|---|
| `CLAUDE.md`, `AGENTS.md` | root orientation for Claude Code and Codex; mirrors of each other |
| `ADD-A-BRAIN.md` | the getting-started playbook and the registration procedure |
| `.claude/commands/register-repo.md` | the one routing command; executes the procedure in `ADD-A-BRAIN.md` |
| `internal/` | child repos your own operation owns and operates (ignored siblings) |
| `external/` | client-owned or co-operated child repos (ignored siblings) |
| `repo-registry/` | one entry per child; the routing table the orientation files read |

## What the harness never carries

- knowledge bases, notes, or doctrine: those live inside a brain
- agents, skills, rules, or workflows beyond the one `register-repo` command
- child repo state of any kind: no child commits, no child secrets, no build artifacts
- live runtime state: local agent settings and personal notes stay untracked by design
- metrics or data: the harness answers what repos live here, what kind each one is, and
  where an agent goes first, and nothing else

Every child under `internal/` or `external/` is an independent git repo with its own remote
and its own history. The harness git-ignores all of them and knows them only through their
registry entries. That means the harness provides children no backup: each child's backup
story is its own remote, recorded in its registry entry.

## Local files

`.claude/CLAUDE.local.md` is available for personal, local-only notes; the shipped
`.gitignore` keeps it and the rest of the local agent state (`settings.json`,
`settings.local.json`, `mcp-servers.json`) out of git.

## License

MIT. See `LICENSE`.
