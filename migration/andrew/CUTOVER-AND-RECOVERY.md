# Cutover and recovery

The ordered operation, the things outside the filesystem that a file copy does not move, and the
exact point after which rolling back stops being free.

Nothing here is authorized by this document. `APPROVAL-PACKET.md` is where the operator authorizes,
and every phase below that changes anything is gated on it.

## The model: copy, verify, repair, retire

Never move. Copy, verify the copy, repair what the copy broke, and only then retire the source, on a
separate day, as a separate decision. A move is a single irreversible act with no verification step
in the middle; a copy has one, and the verification is where every finding in the rehearsal came
from.

## The rollback frontier

**Rollback is free until the first write into an unrepaired copy. It is not free after that.**

This is a measured property, not a caution. In the rehearsal, one commit made in the new root while
its linked worktree was still bound to the old repository was written into the **old** repository and
was invisible in the new one. No error was reported. The copy itself leaves the source
byte-identical, git internals included.

So the frontier sits between phase D and phase E below, and the whole point of phase D is to move it.

## Phases

### A. Freeze what is in flight

Every repository carrying uncommitted work is a repository whose state no clone reproduces. In the
current estate fifteen repositories carry modified or untracked paths, concentrated in a handful.
Either commit them on their own branches or accept copying a dirty tree deliberately; both are fine,
guessing is not. Six repositories are checked out on a branch that is not their default, and that
checked-out branch is part of the state being preserved.

### B. Inventory, read only

`bash migration/andrew/inventory.sh <root> <output outside the repo>`. It mutates nothing. Keep the
output: it is the before-picture that phase E compares against, and without it "everything arrived"
is an impression rather than a measurement.

### C. Copy

Copy, preserving mode, timestamps and symlinks. Do not use a tool that follows symlinks or normalises
line endings. Do not delete anything from the source. The source stays exactly as it was, which is
the whole basis of the rollback.

### D. Repair, before anyone works in the new root

This phase is not optional and it is not cleanup. It is the phase that moves the rollback frontier.

1. **Linked worktree bindings.** A copied worktree still points at the source repository. Rewrite
   both administrative files: `.git` inside the worktree, and `.git/worktrees/<name>/gitdir` inside
   the repository. Until this is done, work in the new root lands in the old one.
2. **Path form.** A worktree created by Windows git records `C:/Users/...`. A WSL git cannot stat
   that and reports the worktree prunable while it is alive. Normalise to the mount prefix, or accept
   that the worktree is invisible to WSL tools. In the current estate this affects twenty-five
   worktrees across eight repositories, all of them live.
3. **Do not prune.** `git worktree prune` in the unrepaired state deletes the record of live
   worktrees holding unmerged commits. Demonstrated in the rehearsal. If a worktree really is dead,
   remove it deliberately, by name, after checking the directory yourself.
4. **Absolute symlinks** that point into the estate. They break silently.
5. **Agent state keyed by the workspace path.** The per-project directory name is the workspace path
   with separators replaced, so a new root means a new key and an empty history. Decide whether to
   copy the old key's directory to the new key, and remember the directories keyed to paths inside
   the root are orphaned by the same rename.

### E. Verify against phase B

Re-run the inventory against the new root and compare, row by row: same repositories, same branches,
same HEADs, same dirty and untracked counts, same marker census. A difference is a finding to explain
before continuing, not a rounding error.

### F. Services, timers and everything that is not a file

A file copy moves none of this. Each item is a change with its own rollback, and each one must be
named in the approval packet before it is touched.

- Scheduled tasks and cron entries that name absolute paths.
- Any service or daemon started from a path in the estate, including local ports already in use.
- IDE and editor workspace files holding absolute paths.
- Shell profile entries, aliases and functions.
- Tool configuration holding absolute paths, including per-project agent configuration and hooks.
- Anything that authenticates from a path-derived identity.

The enumeration is the operator's, because only the operator can see the host. What this file
supplies is the rule: nothing in this list may be changed as a side effect of the migration. Each is a
separate, named, reversible change.

### G. Retire, later, separately

Only after the new root has been used for real work and verified. Retiring means the source stops
being the working root, not that it is deleted. Deleting the source is a distinct decision, and for
the thirteen repositories with no remote it is a decision to destroy the only copy.

## Recovery

- **Before the first write in the new root:** delete the copy. Nothing else is required. The source
  was never modified.
- **After the first write, before repair:** treat the old root as authoritative, find the commits
  written into it through the cross-linked worktree, and reconcile them by hand before deleting the
  copy. This is the case worth avoiding by doing phase D properly.
- **After repair and use:** the new root is authoritative and rollback is a migration in the other
  direction, with the same phases.
- **If a prune has already run:** the worktree directory and its commits are still on disk. The lost
  part is the administrative record. Re-adding the worktree by name recovers the binding; the
  branches were never in the deleted files.
