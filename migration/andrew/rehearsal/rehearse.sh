#!/usr/bin/env bash
# Migration rehearsal on a synthetic estate. Proves the move mechanics, and proves the two failures
# that a successful-looking copy hides.
#
# THIS SCRIPT CANNOT BE AIMED AT A REAL WORKSPACE. It takes no path arguments. It builds its own
# fixture estate in a scratch directory, migrates that, verifies it, and deletes it. The fence is
# structural rather than a warning, because "point it at the real root just to see" is exactly the
# thing a checklist cannot prevent.
#
# The migration model under test is COPY, VERIFY, REPAIR, THEN RETIRE. Going in, the intended
# property was that the old root is never mutated, so rollback would be "do nothing to the old
# root". The rehearsal partly falsified that and the assertions now say what is actually true: the
# copy does not touch the source, and the first write into an unrepaired copy does, because a
# copied worktree is still bound to the old repository.
#
# The five things the packet asks a rehearsal to cover are each an assertion here: Windows/WSL path
# mapping, a local-only repository, a dirty index with untracked files, linked-worktree metadata, and
# duplicate-writer prevention. The private marker is asserted as a sixth, because a migration must
# not be an export.
#
# Usage: bash migration/andrew/rehearsal/rehearse.sh
# Exit 0 when every assertion holds, 1 otherwise.
set -uo pipefail

PASS=0; FAIL=0; ELIGIBLE=0; DEMOS=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n      %s\n' "$1" "$2"; }
demo() { DEMOS=$((DEMOS+1)); printf 'DEMONSTRATED  %s\n              %s\n' "$1" "$2"; }

command -v git >/dev/null 2>&1 || { printf 'rehearse: git is required\n' >&2; exit 2; }

SCRATCH=$(mktemp -d 2>/dev/null || mktemp -d -t rehearse)
trap 'rm -rf "$SCRATCH"' EXIT
OLD="$SCRATCH/old-root"
# The new root sits under a fixture mount prefix so the drive-letter mapping below is the real
# transformation (C:/x -> <prefix>/c/x) rather than a synthesised string.
MNT="$SCRATCH/mnt"
NEW="$MNT/c/new-root"
mkdir -p "$MNT/c"

git_q() { git -C "$1" "${@:2}" >/dev/null 2>&1; }

make_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git_q "$dir" init
  git -C "$dir" config user.email "rehearsal@example.invalid"
  git -C "$dir" config user.name "D01 rehearsal"
  git -C "$dir" config commit.gpgsign false
}

write_node() {
  local file="$1" id="$2" cls="$3" body="$4"
  mkdir -p "$(dirname "$file")"
  {
    printf -- '---\n'
    printf 'id: "%s"\n' "$id"
    printf 'type: "Concept"\n'
    printf 'namespace: "fixture"\n'
    printf 'lifecycle_state: "research"\n'
    printf 'export_class: "%s"\n' "$cls"
    printf -- '---\n\n'
    printf '%s\n' "$body"
  } > "$file"
}

# ---------------------------------------------------------------------------
# The fixture estate. Each repository exists to carry one hazard.
# ---------------------------------------------------------------------------
mkdir -p "$OLD/internal" "$OLD/external/client-a" "$OLD/repo-registry"
printf 'fixture harness root\n' > "$OLD/README.md"

# 1. A brain with a remote and private-marked content.
ORIGIN="$SCRATCH/origins/company-brain.git"
mkdir -p "$ORIGIN"; git init -q --bare "$ORIGIN"
make_repo "$OLD/internal/company-brain"
write_node "$OLD/internal/company-brain/knowledge/shared-doctrine.md" "fx-shared" "internal" "Shared doctrine."
write_node "$OLD/internal/company-brain/knowledge/private-capture.md" "fx-private" "private" "Raw capture that must stay where it was written."
git_q "$OLD/internal/company-brain" add -A
git_q "$OLD/internal/company-brain" commit -m "first"
git_q "$OLD/internal/company-brain" remote add origin "$ORIGIN"

# 2. A local-only repository: no remote anywhere, and a dirty index plus untracked files.
make_repo "$OLD/internal/local-only-notes"
printf 'committed line\n' > "$OLD/internal/local-only-notes/notes.md"
git_q "$OLD/internal/local-only-notes" add -A
git_q "$OLD/internal/local-only-notes" commit -m "first"
printf 'committed line\nan edit nobody has committed\n' > "$OLD/internal/local-only-notes/notes.md"
printf 'staged but not committed\n' > "$OLD/internal/local-only-notes/staged.md"
git_q "$OLD/internal/local-only-notes" add staged.md
printf 'never added to git at all\n' > "$OLD/internal/local-only-notes/untracked.md"

# 3. A repository with a linked worktree inside the root.
make_repo "$OLD/internal/with-worktree"
printf 'main line\n' > "$OLD/internal/with-worktree/file.md"
git_q "$OLD/internal/with-worktree" add -A
git_q "$OLD/internal/with-worktree" commit -m "first"
mkdir -p "$OLD/_worktrees"
git_q "$OLD/internal/with-worktree" worktree add -b feature "$OLD/_worktrees/feature"
printf 'work in the linked worktree\n' > "$OLD/_worktrees/feature/feature.md"
git -C "$OLD/_worktrees/feature" config user.email "rehearsal@example.invalid"
git -C "$OLD/_worktrees/feature" config user.name "D01 rehearsal"
git_q "$OLD/_worktrees/feature" add -A
git_q "$OLD/_worktrees/feature" commit -m "feature work"

# 4. A client repository under an external group.
make_repo "$OLD/external/client-a/client-brain"
write_node "$OLD/external/client-a/client-brain/knowledge/terms.md" "fx-client" "department" "Client-owned material."
git_q "$OLD/external/client-a/client-brain" add -A
git_q "$OLD/external/client-a/client-brain" commit -m "first"

# ---------------------------------------------------------------------------
# Measurement helpers.
# ---------------------------------------------------------------------------
REPOS="internal/company-brain internal/local-only-notes internal/with-worktree external/client-a/client-brain"

repo_history() { git -C "$1" log --format='%H %T %s' 2>/dev/null; }
repo_status()  { git -C "$1" status --porcelain 2>/dev/null | LC_ALL=C sort; }
tree_digest()  { ( cd "$1" && find . -type f -not -path './.git/*' -print0 | LC_ALL=C sort -z \
                   | xargs -0 sha256sum 2>/dev/null | sha256sum | cut -d' ' -f1 ); }

OLD_ROOT_DIGEST_BEFORE=$(tree_digest "$OLD")

# ---------------------------------------------------------------------------
# R1. Duplicate-writer prevention, asserted BEFORE any copy happens.
#
# Two manifest rows that resolve to one destination is the shape that silently merges two
# repositories into one directory. The refusal has to happen while the destination is still empty,
# so the check runs over the plan, not over the result.
# ---------------------------------------------------------------------------
plan_conflicts() {
  awk -F'\t' 'NR>1 {print $2}' "$1" | LC_ALL=C sort | uniq -d
}
GOOD_PLAN="$SCRATCH/plan-good.tsv"
BAD_PLAN="$SCRATCH/plan-bad.tsv"
printf 'source\ttarget\n' > "$GOOD_PLAN"
for r in $REPOS; do printf '%s\t%s\n' "$r" "$r" >> "$GOOD_PLAN"; done
cp "$GOOD_PLAN" "$BAD_PLAN"
printf '%s\t%s\n' "internal/renamed-notes" "internal/local-only-notes" >> "$BAD_PLAN"

ELIGIBLE=$((ELIGIBLE+1))
GOOD_DUPES=$(plan_conflicts "$GOOD_PLAN" | wc -l)
BAD_DUPES=$(plan_conflicts "$BAD_PLAN" | wc -l)
BAD_NAMED=$(plan_conflicts "$BAD_PLAN")
if [ "$GOOD_DUPES" -eq 0 ] && [ "$BAD_DUPES" -eq 1 ] && [ ! -d "$NEW" ]; then
  ok "duplicate-writer-refused-before-any-copy (conflict named: $BAD_NAMED; destination still absent)"
else
  bad "duplicate-writer-refused-before-any-copy" "good_plan_dupes=$GOOD_DUPES bad_plan_dupes=$BAD_DUPES new_root_exists=$([ -d "$NEW" ] && echo yes || echo no)"
fi

# ---------------------------------------------------------------------------
# The migration itself: copy, preserving everything, mutating nothing in the source.
# ---------------------------------------------------------------------------
mkdir -p "$NEW"
cp -a "$OLD/." "$NEW/"
OLD_ROOT_DIGEST_AFTER_COPY=$(tree_digest "$OLD")

# The copy itself must not touch the source. Asserted separately from R9 because the two claims are
# different: this one is about the copy, R9 is about what happens next.
ELIGIBLE=$((ELIGIBLE+1))
if [ "$OLD_ROOT_DIGEST_BEFORE" = "$OLD_ROOT_DIGEST_AFTER_COPY" ]; then
  ok "the-copy-does-not-touch-the-source (old root byte-identical across the copy, git internals included)"
else
  bad "the-copy-does-not-touch-the-source" "digest changed during a copy that should only have read"
fi

# ---------------------------------------------------------------------------
# R2. Inventory equality: the same repositories, on the same branches, at the same commits.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
MISMATCH=""
for r in $REPOS; do
  ob=$(git -C "$OLD/$r" rev-parse --abbrev-ref HEAD 2>/dev/null)
  nb=$(git -C "$NEW/$r" rev-parse --abbrev-ref HEAD 2>/dev/null)
  oh=$(git -C "$OLD/$r" rev-parse HEAD 2>/dev/null)
  nh=$(git -C "$NEW/$r" rev-parse HEAD 2>/dev/null)
  [ "$ob" = "$nb" ] && [ "$oh" = "$nh" ] && [ -n "$oh" ] || MISMATCH="$MISMATCH $r"
done
if [ -z "$MISMATCH" ]; then
  ok "inventory-preserved (4 repositories, same branch and same HEAD)"
else
  bad "inventory-preserved" "differs:$MISMATCH"
fi

# ---------------------------------------------------------------------------
# R3. History preserved, commit for commit and tree for tree.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
HIST_DIFF=""
for r in $REPOS; do
  [ "$(repo_history "$OLD/$r")" = "$(repo_history "$NEW/$r")" ] || HIST_DIFF="$HIST_DIFF $r"
done
if [ -z "$HIST_DIFF" ]; then
  ok "history-preserved (commit hashes and tree hashes identical in all 4)"
else
  bad "history-preserved" "differs:$HIST_DIFF"
fi

# ---------------------------------------------------------------------------
# R4. The dirty index and the untracked file, which no clone reproduces. Staged-vs-unstaged is
# checked, not just presence: a copy that flattened the index would still pass a file-hash test.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
OS=$(repo_status "$OLD/internal/local-only-notes")
NS=$(repo_status "$NEW/internal/local-only-notes")
STAGED=$(printf '%s\n' "$NS" | grep -c '^A ')
UNSTAGED=$(printf '%s\n' "$NS" | grep -c '^ M')
UNTRACKED=$(printf '%s\n' "$NS" | grep -c '^??')
if [ "$OS" = "$NS" ] && [ "$STAGED" -eq 1 ] && [ "$UNSTAGED" -eq 1 ] && [ "$UNTRACKED" -eq 1 ]; then
  ok "dirty-index-and-untracked-preserved (1 staged, 1 unstaged, 1 untracked, states identical)"
else
  bad "dirty-index-and-untracked-preserved" "old=[$OS] new=[$NS] staged=$STAGED unstaged=$UNSTAGED untracked=$UNTRACKED"
fi

# ---------------------------------------------------------------------------
# R5. The local-only repository. It has no remote on either side, which is the point: the copy is
# the only other copy that will ever exist, so a failure here is unrecoverable rather than annoying.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
OLD_REMOTE=$(git -C "$OLD/internal/local-only-notes" config --get remote.origin.url 2>/dev/null || printf 'none')
NEW_REMOTE=$(git -C "$NEW/internal/local-only-notes" config --get remote.origin.url 2>/dev/null || printf 'none')
NEW_CONTENT=$(cat "$NEW/internal/local-only-notes/untracked.md" 2>/dev/null)
if [ "$OLD_REMOTE" = "none" ] && [ "$NEW_REMOTE" = "none" ] && [ "$NEW_CONTENT" = "never added to git at all" ]; then
  ok "local-only-repo-arrives-whole (no remote either side, untracked content byte-equal)"
else
  bad "local-only-repo-arrives-whole" "old_remote=$OLD_REMOTE new_remote=$NEW_REMOTE untracked_content=[$NEW_CONTENT]"
fi

# ---------------------------------------------------------------------------
# R6. Linked-worktree metadata, and the failure a copy actually produces.
#
# A linked worktree records absolute paths in two administrative files. The expectation going in was
# that a copied worktree would be reported prunable. It is not, and what actually happens is worse:
# while the old root still exists the copied worktree resolves to the OLD repository, so work done in
# the new root is written into the old root's git directory and the new root's history stays empty.
# Nothing reports an error. The rehearsal asserts that cross-link, then repairs it, then asserts the
# binding moved.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
POINTS_AT_OLD=$(grep -c "$OLD" "$NEW/_worktrees/feature/.git" 2>/dev/null)
printf 'a commit made in the NEW root while still cross-linked\n' > "$NEW/_worktrees/feature/crosslink.md"
git -C "$NEW/_worktrees/feature" add -A >/dev/null 2>&1
git -C "$NEW/_worktrees/feature" commit -q -m "written from the new root" >/dev/null 2>&1
OLD_SAW_IT=$(git -C "$OLD/internal/with-worktree" log --all --oneline 2>/dev/null | grep -c 'written from the new root')
NEW_SAW_IT=$(git -C "$NEW/internal/with-worktree" log --all --oneline 2>/dev/null | grep -c 'written from the new root')

repair_worktrees() {
  local repo="$1" old_root="$2" new_root="$3" name wt_dir gitdir_file
  for gitdir_file in "$repo"/.git/worktrees/*/gitdir; do
    [ -f "$gitdir_file" ] || continue
    name=$(basename "$(dirname "$gitdir_file")")
    wt_dir=$(sed "s#^$old_root#$new_root#" "$gitdir_file" | sed 's#/\.git$##')
    printf '%s/.git\n' "$wt_dir" > "$gitdir_file"
    [ -f "$wt_dir/.git" ] && printf 'gitdir: %s/.git/worktrees/%s\n' "$repo" "$name" > "$wt_dir/.git"
  done
}
repair_worktrees "$NEW/internal/with-worktree" "$OLD" "$NEW"

BOUND_TO_NEW=$(grep -c "$NEW/internal/with-worktree" "$NEW/_worktrees/feature/.git" 2>/dev/null)
PRUNABLE_AFTER=$(git -C "$NEW/internal/with-worktree" worktree list --porcelain 2>/dev/null | grep -c '^prunable')
WT_BRANCH=$(git -C "$NEW/_worktrees/feature" rev-parse --abbrev-ref HEAD 2>/dev/null)
WT_COMMITS=$(git -C "$NEW/_worktrees/feature" log --oneline 2>/dev/null | wc -l)
if [ "$POINTS_AT_OLD" -eq 1 ] && [ "$OLD_SAW_IT" -eq 1 ] && [ "$NEW_SAW_IT" -eq 0 ] \
   && [ "$BOUND_TO_NEW" -eq 1 ] && [ "$PRUNABLE_AFTER" -eq 0 ] && [ "$WT_BRANCH" = "feature" ]; then
  ok "copied-worktree-is-cross-linked-then-repaired (a commit made in the new root landed in the OLD repository; after repair the binding is local and the branch is usable, $WT_COMMITS commits)"
else
  bad "copied-worktree-is-cross-linked-then-repaired" "points_at_old=$POINTS_AT_OLD old_saw=$OLD_SAW_IT new_saw=$NEW_SAW_IT bound_to_new=$BOUND_TO_NEW prunable_after=$PRUNABLE_AFTER branch=$WT_BRANCH"
fi

# ---------------------------------------------------------------------------
# R7. Windows/WSL path mapping. A worktree created by Windows git records C:/..., which a WSL git
# cannot stat, so it is reported prunable while the worktree is alive and holds unmerged work. This
# is the live shape in this estate today, not a hypothetical: starmynd-orchestrator reports three
# such worktrees right now.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
WIN_FORM="C:/new-root"
printf 'gitdir: %s/internal/with-worktree/.git/worktrees/feature\n' "$WIN_FORM" > "$NEW/_worktrees/feature/.git"
printf '%s/_worktrees/feature/.git\n' "$WIN_FORM" > "$NEW/internal/with-worktree/.git/worktrees/feature/gitdir"
WIN_PRUNABLE=$(git -C "$NEW/internal/with-worktree" worktree list --porcelain 2>/dev/null | grep -c '^prunable')
WIN_REASON=$(git -C "$NEW/internal/with-worktree" worktree list --porcelain 2>/dev/null | sed -n 's/^prunable //p' | head -1)
WIN_DIR_EXISTS=$([ -d "$NEW/_worktrees/feature" ] && printf 'yes' || printf 'no')

# The mapping a migration needs: drive letter to mount prefix, lowercased, prefix configurable
# because /mnt is a WSL default rather than a law.
win_to_wsl() { printf '%s' "$2" | sed "s#^\([A-Za-z]\):/#$1/\L\1/#"; }
MAPPED=$(win_to_wsl "$MNT" "$WIN_FORM")
printf 'gitdir: %s/internal/with-worktree/.git/worktrees/feature\n' "$MAPPED" > "$NEW/_worktrees/feature/.git"
printf '%s/_worktrees/feature/.git\n' "$MAPPED" > "$NEW/internal/with-worktree/.git/worktrees/feature/gitdir"
MAPPED_PRUNABLE=$(git -C "$NEW/internal/with-worktree" worktree list --porcelain 2>/dev/null | grep -c '^prunable')
MAPPED_USABLE=$(git -C "$NEW/_worktrees/feature" log --oneline 2>/dev/null | wc -l)

if [ "$WIN_PRUNABLE" -ge 1 ] && [ "$WIN_DIR_EXISTS" = "yes" ] && [ "$MAPPED_PRUNABLE" -eq 0 ] && [ "$MAPPED_USABLE" -ge 2 ]; then
  ok "windows-wsl-path-mapping (Windows-form gitdir: prunable, reason \"$WIN_REASON\", while the directory exists; mapped to the mount prefix it resolves and $MAPPED_USABLE commits are readable)"
else
  bad "windows-wsl-path-mapping" "win_prunable=$WIN_PRUNABLE dir_exists=$WIN_DIR_EXISTS mapped_prunable=$MAPPED_PRUNABLE mapped_usable=$MAPPED_USABLE"
fi

# The destructive half, measured on a throwaway copy rather than argued. In the Windows-form state
# the worktree looks gone to git, so prune deletes the administrative record of a live worktree that
# holds unmerged commits. This is the reason the checklist says repair before prune, and why nobody
# should run prune from WSL in the current estate.
ELIGIBLE=$((ELIGIBLE+1))
PRUNE_DEMO="$SCRATCH/prune-demo"
mkdir -p "$PRUNE_DEMO"
cp -a "$NEW/." "$PRUNE_DEMO/"
printf 'gitdir: %s/internal/with-worktree/.git/worktrees/feature\n' "$WIN_FORM" > "$PRUNE_DEMO/_worktrees/feature/.git"
printf '%s/_worktrees/feature/.git\n' "$WIN_FORM" > "$PRUNE_DEMO/internal/with-worktree/.git/worktrees/feature/gitdir"
ADMIN_BEFORE=$(ls -1 "$PRUNE_DEMO/internal/with-worktree/.git/worktrees" 2>/dev/null | wc -l)
UNMERGED=$(git -C "$PRUNE_DEMO/internal/with-worktree" log --oneline feature 2>/dev/null | wc -l)
git -C "$PRUNE_DEMO/internal/with-worktree" worktree prune >/dev/null 2>&1
ADMIN_AFTER=$(ls -1 "$PRUNE_DEMO/internal/with-worktree/.git/worktrees" 2>/dev/null | wc -l)
DIR_STILL=$([ -d "$PRUNE_DEMO/_worktrees/feature" ] && printf 'yes' || printf 'no')
if [ "$ADMIN_BEFORE" -eq 1 ] && [ "$ADMIN_AFTER" -eq 0 ] && [ "$DIR_STILL" = "yes" ]; then
  demo "prune-in-the-unmapped-state-destroys-live-metadata" "git worktree prune removed the administrative record of a worktree whose directory still exists and whose branch carries $UNMERGED commits ($ADMIN_BEFORE -> $ADMIN_AFTER). Map the paths first. Never prune to tidy up a copied estate."
  PASS=$((PASS+1))
else
  bad "prune-in-the-unmapped-state-destroys-live-metadata" "admin $ADMIN_BEFORE -> $ADMIN_AFTER dir_still=$DIR_STILL (expected 1 -> 0, yes)"
fi

# ---------------------------------------------------------------------------
# R7b. The inventory must not call a Windows-spelled worktree foreign.
#
# The same two-spellings problem, one layer up. A manifest that reports "this worktree lives outside
# the root" for 25 live worktrees sends the operator looking for repositories that are already here.
# The comparison has to fold both spellings, not expand one forward, or it only works when the root
# happens to be written the other way. (Rule from Terminal 12's R06 measurement: their unit
# comparison reported twelve service units changed and buried the one real drift.)
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
printf 'gitdir: %s/internal/with-worktree/.git/worktrees/feature\n' "$WIN_FORM" > "$NEW/_worktrees/feature/.git"
printf '%s/_worktrees/feature/.git\n' "$WIN_FORM" > "$NEW/internal/with-worktree/.git/worktrees/feature/gitdir"
INV_OUT="$SCRATCH/inventory-out"
WSL_MOUNT_PREFIX="$MNT" bash "$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")/inventory.sh" \
  "$NEW" "$INV_OUT" >/dev/null 2>&1
FOREIGN=$(awk -F'\t' 'NR>1 && $2=="internal/with-worktree" {print $10}' "$INV_OUT/estate-inventory.tsv" 2>/dev/null)
OUTSIDE_NOTE=$(grep -c 'OUTSIDE-ROOT' "$INV_OUT/estate-findings.txt" 2>/dev/null)
# Restore the mapped form so the later assertions see a working worktree.
printf 'gitdir: %s/internal/with-worktree/.git/worktrees/feature\n' "$MAPPED" > "$NEW/_worktrees/feature/.git"
printf '%s/_worktrees/feature/.git\n' "$MAPPED" > "$NEW/internal/with-worktree/.git/worktrees/feature/gitdir"
if [ "$FOREIGN" = "0" ] && [ "$OUTSIDE_NOTE" = "0" ]; then
  ok "inventory-folds-both-spellings (a Windows-form worktree inside the root is counted inside, not reported as living elsewhere)"
else
  bad "inventory-folds-both-spellings" "outside_root column=${FOREIGN:-unset} OUTSIDE-ROOT findings=${OUTSIDE_NOTE:-unset} (expected 0 and 0)"
fi

# ---------------------------------------------------------------------------
# R8. The private marker. A migration moves a brain; it does not export one. Every export_class value
# must arrive unchanged, and the private node must still be private and still be present.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
OLD_MARKERS=$(grep -rh '^export_class:' "$OLD" --include='*.md' 2>/dev/null | LC_ALL=C sort | uniq -c | tr -s ' ')
NEW_MARKERS=$(grep -rh '^export_class:' "$NEW" --include='*.md' 2>/dev/null | LC_ALL=C sort | uniq -c | tr -s ' ')
PRIVATE_STILL=$(grep -l 'export_class: "private"' "$NEW/internal/company-brain/knowledge/private-capture.md" 2>/dev/null | wc -l)
if [ "$OLD_MARKERS" = "$NEW_MARKERS" ] && [ "$PRIVATE_STILL" -eq 1 ]; then
  ok "private-marker-unchanged-by-the-move (marker census identical; the private node is present and still private)"
else
  bad "private-marker-unchanged-by-the-move" "old=[$OLD_MARKERS] new=[$NEW_MARKERS] private_present=$PRIVATE_STILL"
fi

# ---------------------------------------------------------------------------
# R9. The rollback frontier, which is the most important thing this rehearsal found.
#
# Rollback was supposed to be a property rather than a procedure: if the source is untouched,
# abandoning the move costs nothing. The copy does leave the source untouched (asserted above). But
# R6 wrote one commit in the new root while its worktree was still cross-linked, and that commit
# landed in the OLD repository. So the old root is mutated not by the migration but by the first use
# of an unrepaired copy.
#
# That is the frontier: rollback is free until someone works in the new root, and from the first
# write into an unrepaired worktree the two roots share history that only one of them can see.
# ---------------------------------------------------------------------------
ELIGIBLE=$((ELIGIBLE+1))
OLD_ROOT_DIGEST_AFTER_USE=$(tree_digest "$OLD")
OLD_GAINED=$(git -C "$OLD/internal/with-worktree" log --all --oneline 2>/dev/null | grep -c 'written from the new root')
OLD_STILL_GIT=$(git -C "$OLD/internal/company-brain" log --oneline 2>/dev/null | wc -l)
OLD_WT_OK=$(git -C "$OLD/internal/with-worktree" worktree list --porcelain 2>/dev/null | grep -c '^prunable')
if [ "$OLD_ROOT_DIGEST_AFTER_USE" != "$OLD_ROOT_DIGEST_AFTER_COPY" ] && [ "$OLD_GAINED" -eq 1 ] \
   && [ "$OLD_STILL_GIT" -eq 1 ] && [ "$OLD_WT_OK" -eq 0 ]; then
  ok "rollback-frontier-is-the-first-write-not-the-copy (source unchanged by the copy; changed by one commit made in the unrepaired new root; old root still viable afterwards)"
else
  bad "rollback-frontier-is-the-first-write-not-the-copy" "digest_changed=$([ "$OLD_ROOT_DIGEST_AFTER_USE" != "$OLD_ROOT_DIGEST_AFTER_COPY" ] && echo yes || echo no) old_gained_commit=$OLD_GAINED old_git_ok=$OLD_STILL_GIT old_prunable=$OLD_WT_OK"
fi

# ---------------------------------------------------------------------------

printf '\n'
printf 'receipt_kind\tmigration-rehearsal\n'
printf 'packet\tD01\n'
printf 'estate\tsynthetic, built and destroyed by this script\n'
printf 'real_root_touched\tno; this script takes no path arguments\n'
printf 'model\tcopy, verify, repair, then retire\n'
printf 'rollback_frontier\tthe first write into an unrepaired copy, not the copy itself\n'
printf 'eligible\t%s\n' "$ELIGIBLE"
printf 'passed\t%s\n' "$PASS"
printf 'failed\t%s\n' "$FAIL"
printf 'demonstrated_hazards\t%s\n' "$DEMOS"

if [ "$FAIL" -gt 0 ]; then
  printf 'verdict\tFAIL\n'
  exit 1
fi
printf 'verdict\tPASS (fixture estate; a real cutover is a separately approved operation)\n'
exit 0
