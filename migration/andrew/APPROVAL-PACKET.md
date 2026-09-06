# Approval packet

What the operator is being asked to decide, and what is being asked for permission to do. Nothing in
this folder authorizes anything; this file is the request.

Prepared under packet D01, 2026-09-06. Preparation is complete and the cutover has not been
attempted. The rehearsal ran on a synthetic estate; the inventory ran, read only, on the real one.

## Part 1: decisions only the operator can make

**D-1. Does the root move at all?**
The rename is cosmetic; the registry-governed structure is the substance and it already exists. The
measured cost of the rename is not zero: per-project agent state is keyed by the workspace path, so a
new root means a new key and an empty history, plus the directories keyed to paths inside the root.
A defensible answer is "keep the root, complete the registry work", and it should be considered on
the evidence rather than dismissed. If the name matters for explaining the product, that is a real
reason; it is just not a technical one.

**D-2. Which repositories travel, and which stay behind on purpose?**
Every row needs `yes` or `no`. A `no` on a repository with no remote is a decision to keep the only
copy where it is, or to end it. Thirteen repositories in this estate have no remote at all.

**D-3. What is each repository's audience and owner?**
Four values: personal, company, department, client. The owner is who owns the repository, not who
operates it. This governs consent, and it is the column that cannot be inferred from a path.

**D-4. Which client repositories need their owner's agreement before anything moves?**
Consent is per client. It is not implied by the directory layout, and if an agreement named a path,
changing the path is a change to the agreement.

**D-5. Do the four or five segment registry entries get migrated to the seat shape?**
A seat is a harness with its own registry. Twelve live entries describe paths inside another harness
root, which flattens two registries into one namespace. Fixing that is registry work, separate from
moving files, and it was already ruled out as a precondition for the contract pin. It can happen
before, after, or independently of any move.

**D-6. Does the old root get deleted, and when?**
The recommendation is not yet, and not as part of the same operation. Retiring a root and deleting it
are different acts.

## Part 2: operations requiring explicit authorization

None of these has been performed. Each is listed with what it changes and how it is undone.

| # | Operation | Changes | Undo |
|---|---|---|---|
| O-1 | Copy the estate to a new root | Adds a second copy; source untouched | Delete the copy |
| O-2 | Repair worktree bindings and path forms in the copy | Administrative files in the copy only | Re-copy from source |
| O-3 | Copy or re-key agent project state | Adds a directory under the agent's state folder | Delete it; the original key is untouched |
| O-4 | Re-point absolute symlinks | The link target | Re-point back |
| O-5 | Change scheduled tasks, timers or services to new paths | Host state outside the estate | Restore each to its previous value; enumerate before changing |
| O-6 | Switch daily work to the new root | Which root is authoritative | Migration in the other direction |
| O-7 | Retire the old root | Which root is authoritative | Switch back |
| O-8 | Delete the old root | Destroys the only copy of every local-only repository | **None** |

O-8 is the only irreversible row, and it stays out of any batch that contains the others.

## Part 3: what is explicitly not requested here

- No repository is created because a diagram names it.
- No remote is added, no repository is published, and no local-only repository is given a remote as a
  side effect of migrating. That is a separate decision with its own disclosure question.
- No credential, token or secret is copied, and no service is re-authenticated.
- No collaborator is invited and no private history is shared.
- No `git worktree prune` anywhere, in either root, at any phase.

## Part 4: the standing hazard, which is not conditional on any of the above

**Do not run `git worktree prune` from WSL in the current estate.** Twenty-five worktrees across
eight repositories are reported prunable right now because their gitdir is recorded in Windows form
and a WSL git cannot stat it. They are alive and several carry unmerged work. This is true today,
with or without a migration, and it is the one item in this packet that is urgent independently of
any decision above.
