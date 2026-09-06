# Domain and audience map

Which brain serves which audience, what that permits, and where the boundary is enforced rather than
described. The registry already records what a repository *is* (`ownership`, `repo_kind`,
`brain_tier`). This file records who each one is *for*, because a move is the moment those two get
confused.

## The four audiences, and the one that is not a scope

| Audience | Holds | May be mounted by | Export axis |
|---|---|---|---|
| personal | One person's raw capture, unfinished thinking, private positions | That person only | `private` nodes live here and only here |
| company | The operation's shared working material | Anyone inside the operation | `internal` |
| department | Material scoped to one team's trust boundary | That department | `department` |
| client | Work a client owns or co-operates | The people that client has agreed to | `internal` to the client, never to the operation |

`private` is a stop, not a scope. There is no "private audience" that some export could request and
be handed. A node marked `private` does not leave the brain that wrote it, by any profile, and
widening it is a recorded act rather than an edit. The mechanism is
`_system/audience-and-export-schema.md` in the starter, and the computation is
`_system/checks/audience-export-check.sh`.

## The two promotions, kept apart

- Lifecycle promotion, `scratch` to `research` to `canon`, says how settled the content is.
- Audience promotion, `private` to `internal` to `public`, says who may see it.

A node can be canon and private forever. That is the normal state of a mature personal brain.
Treating a lifecycle promotion as implying an audience promotion is the mechanism by which a personal
brain leaks into a shared one one confident node at a time, which is why an audience widening is
never implied: it is recorded on the node as a grant naming who granted it, when, and from which
class to which.

## What this means for a migration specifically

1. **A migration is not an export.** Moving a brain preserves every marker exactly. The rehearsal
   asserts the marker census is identical across the move, so a migration cannot become a quiet
   reclassification.
2. **A boundary that only exists in the directory layout does not survive a move.** `external/<client>/`
   tells a reader the likely trust context, and that is worth keeping, but the enforceable statement
   is the registry entry plus the node markers. Re-parenting a directory changes the hint and not the
   policy.
3. **Client consent is per client and is not implied by a path.** Any repository under `external/`
   whose owner is a client needs that client's agreement before it moves anywhere the client did not
   agree to, including a differently named root on the same machine if the agreement named the path.
4. **The personal brain is the one that cannot be re-derived.** Its unique material is exactly the
   material with no remote and no export. In this estate that is not a hypothetical: thirteen
   repositories have no remote at all.

## Mapping the actual estate

The measured half comes from `inventory.sh`. The decided half is one `audience` and one `owner` per
row, in the operator's copy of the manifest, kept outside this repository for the reason
`README.md` gives.

Two shapes in the current estate need a decision rather than a default, and both are recorded in
`APPROVAL-PACKET.md`:

- **A seat is a harness with its own registry.** Several entries in the live root describe paths
  *inside* another harness root, which flattens two registries into one namespace. The parent should
  record the seat as one entry and stop; what lives inside it belongs to the seat's own registry.
  Deciding that is a registry migration, and it is separate from moving files.
- **Individual brains that belong to other people** are mounted in this estate and are not the
  operator's to move. They are `client` or `personal` to their owner, never `company` to this one.
