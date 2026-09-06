# Migration preparation: one operator's estate

This folder prepares a workspace-root migration and rehearses it. It does not perform one, and
nothing in it can be pointed at a real workspace by accident.

Packet D01 of the 2026-09-06 Multiverse sprint. The named boundary is explicit in the assignment:
manifest, domain map, fixture rehearsal and approval packet only. No live cutover, no worktree prune,
no private-history sharing, no credential copy, and no deletion or renaming of the existing root.

## What is here

| File | What it is | Safe to run |
|---|---|---|
| `inventory.sh` | Read-only estate inventory. Every git call is a query. | Yes, on any root |
| `MANIFEST-SCHEMA.md` | The row shape a migration plan has to carry, and the risk classes | Reading only |
| `DOMAIN-MAP.md` | Which brain serves which audience, and how that maps to the export axis | Reading only |
| `rehearsal/rehearse.sh` | The migration rehearsed on a synthetic estate it builds and destroys | Yes; it takes no path arguments |
| `CUTOVER-AND-RECOVERY.md` | The ordered checklist, the service and timer changes, the rollback frontier | Reading only |
| `APPROVAL-PACKET.md` | The exact decisions and authorizations a cutover needs from the operator | Reading only |

## The rule that shapes this folder: the machinery ships, the estate does not

A real inventory names client repositories and their remote URLs, and some of those URLs carry
per-client path identifiers. This repository is published. So `inventory.sh` **refuses to write its
output inside this repository** and says why. The tools are the shareable artifact; one person's
estate is `private` in exactly the sense the brain's own audience axis means it.

That is the same rule the sprint's B01 packet enforces at node grain
(`_system/audience-and-export-schema.md` in the starter). A migration folder that shipped a client
census would be the first thing to violate it.

Run it and keep the output with the operator:

```bash
bash migration/andrew/inventory.sh /path/to/root /path/outside/the/repo
```

## What the rehearsal established, in the order it matters

Run it yourself: `bash migration/andrew/rehearsal/rehearse.sh`. Eleven assertions, one demonstrated
hazard, about five seconds, no arguments to get wrong.

1. **A copied linked worktree is still bound to the source repository.** This is the finding that
   changed the plan. A commit made in the new root, before the worktree metadata is repaired, was
   written into the **old** repository and was invisible in the new one. Nothing reported an error.
2. **So the rollback frontier is the first write into an unrepaired copy, not the cutover.** The copy
   itself leaves the source byte-identical, git internals included; the first use of an unrepaired
   worktree does not. Both halves are asserted.
3. **A Windows-created worktree read from WSL is reported prunable while it is alive.** The recorded
   gitdir says `C:/Users/...`, a WSL git cannot stat it, and git concludes the worktree is gone. The
   rehearsal reproduces that state, maps the path to the mount prefix, and shows the worktree working
   again.
4. **`git worktree prune` in that state deletes the record of a live worktree.** Demonstrated on a
   throwaway copy: one administrative entry removed while the directory and its unmerged commits sat
   there untouched. Repair paths first. Never prune to tidy up a copy.
5. A plan with two rows resolving to one destination is refused **before** anything is copied.
6. History, branch, HEAD, the staged/unstaged split and untracked files all survive the copy, and a
   repository with no remote arrives whole. That last one is the whole game for the thirteen
   repositories in this estate whose only copy is on this machine.
7. Every `export_class` marker arrives unchanged. A migration moves a brain; it does not export one.

## What this preparation does not establish

- It has not been run against the real estate, by design. The inventory has; the move has not.
- It says nothing about services, timers, tokens or anything outside the filesystem. Those are
  enumerated in `CUTOVER-AND-RECOVERY.md` as work, not as done work.
- A passing rehearsal on a synthetic estate is evidence about mechanics, not a prediction about a
  63-repository tree with 15 dirty working directories. The value is that the failures it found are
  now known before they are expensive.
