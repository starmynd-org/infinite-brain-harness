#!/usr/bin/env bash
# Read-only estate inventory. The first step of a migration, and the only one that is safe to run
# without an approval.
#
# It walks a workspace root, records what every child repository actually is, and writes one row per
# repository plus the hazard flags a move has to survive. It runs `git` only in read-only modes.
# It never fetches, never prunes, never stages, never checks out and never writes inside the estate
# it is reading.
#
#   bash migration/andrew/inventory.sh <root> <output-dir>
#
# The output is deliberately NOT written into this repository. See migration/andrew/README.md: a real
# estate inventory names client repositories and their remote URLs, and those URLs carry per-client
# path identifiers. This repo is published. The machinery ships; the inventory of a particular
# person's estate does not, and the script refuses to write into its own working tree.
#
# Exit 0 on a completed inventory (findings are data, not failures). Exit 2 on a usage or safety
# refusal.
set -uo pipefail

ROOT="${1:-}"
OUT="${2:-}"

if [ -z "$ROOT" ] || [ -z "$OUT" ]; then
  printf 'usage: inventory.sh <root> <output-dir>\n' >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  printf 'inventory: root does not exist: %s\n' "$ROOT" >&2
  exit 2
fi

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SELF_DIR/../.." && pwd)
# Resolve without creating: a refusal that has already made a directory inside the repository has
# half-done the thing it is refusing.
OUT_ABS=$(readlink -f "$OUT" 2>/dev/null || printf '%s' "$OUT")

# The refusal that keeps a private inventory out of a public repo. It is a refusal rather than a
# warning because the failure it prevents is publication, which cannot be undone by noticing later.
case "$OUT_ABS/" in
  "$REPO_ROOT"/*)
    printf 'inventory: refusing to write the inventory inside %s.\n' "$REPO_ROOT" >&2
    printf 'inventory: this repository is published. An estate inventory names client repositories\n' >&2
    printf 'inventory: and their remote URLs. Write it outside the repo and keep it with the operator.\n' >&2
    exit 2 ;;
esac

mkdir -p "$OUT_ABS" || { printf 'inventory: cannot create %s\n' "$OUT_ABS" >&2; exit 2; }
TSV="$OUT_ABS/estate-inventory.tsv"
NOTES="$OUT_ABS/estate-findings.txt"
: > "$TSV"
: > "$NOTES"

note() { printf '%s\n' "$1" >> "$NOTES"; }

# One repository. Every git invocation here is a query.
scan_repo() {
  local dir="$1" kind="$2"
  [ -e "$dir/.git" ] || return 0

  local rel branch head remote dirty untracked wt_total wt_prunable wt_foreign default_branch
  rel="${dir#$ROOT/}"
  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'UNKNOWN')
  head=$(git -C "$dir" rev-parse HEAD 2>/dev/null || printf 'UNKNOWN')
  remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || printf 'local-only')
  [ -z "$remote" ] && remote='local-only'
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null | grep -c '^ *[MADRC]')
  untracked=$(git -C "$dir" status --porcelain 2>/dev/null | grep -c '^??')

  # Linked worktree metadata, which is the part of a repository a copy silently breaks. A worktree is
  # counted as foreign when its recorded path is not under the root being inventoried, and as
  # prunable when git says its gitdir points nowhere. On a Windows-created worktree read from WSL the
  # second is a PATH FORM problem, not a dead worktree: see README.md.
  wt_total=$(git -C "$dir" worktree list --porcelain 2>/dev/null | grep -c '^worktree ')
  wt_total=$((wt_total > 0 ? wt_total - 1 : 0))
  wt_prunable=$(git -C "$dir" worktree list --porcelain 2>/dev/null | grep -c '^prunable')
  # A worktree recorded as C:/Users/... is INSIDE this root when the root is /mnt/c/Users/...; only the
  # path form differs. Normalising before the comparison is the difference between a manifest that
  # says "25 worktrees live elsewhere" and one that says "25 live here and are unreadable from WSL".
  wt_foreign=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | tail -n +2 \
    | sed 's#^\([A-Za-z]\):/#/mnt/\L\1/#' | grep -vc "^$ROOT" 2>/dev/null)

  default_branch=$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
  [ -z "$default_branch" ] && default_branch='unknown'

  # Risk class. It ranks by what is lost if the move goes wrong, not by repository size.
  local risk="routine"
  [ "$remote" = "local-only" ] && risk="irreplaceable"
  if [ "$risk" != "irreplaceable" ] && { [ "$dirty" -gt 0 ] || [ "$untracked" -gt 0 ]; }; then risk="carries-uncommitted"; fi
  [ "$wt_prunable" -gt 0 ] && risk="worktree-metadata-at-risk"
  [ "$remote" = "local-only" ] && risk="irreplaceable"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$kind" "$rel" "$branch" "$default_branch" "$head" "$dirty" "$untracked" \
    "$wt_total" "$wt_prunable" "$wt_foreign" "$risk" >> "$TSV"

  [ "$remote" = "local-only" ] && note "LOCAL-ONLY   $rel has no remote. The move is its only copy."
  [ "$wt_prunable" -gt 0 ] && note "WORKTREE     $rel reports $wt_prunable prunable worktree(s). Verify every directory before believing it, and do NOT prune: a Windows-form gitdir read from WSL is reported prunable while the worktree is alive and holds unmerged commits."
  [ "$wt_foreign" -gt 0 ] && note "OUTSIDE-ROOT $rel has $wt_foreign linked worktree(s) whose recorded path is outside this root even after drive-letter normalisation; they do not travel with it."
  if [ "$branch" != "$default_branch" ] && [ "$default_branch" != "unknown" ]; then
    note "BRANCH       $rel is checked out on '$branch', not '$default_branch'. A move that assumes the default branch loses the working context."
  fi
  if [ "$dirty" -gt 0 ] || [ "$untracked" -gt 0 ]; then
    note "UNCOMMITTED  $rel carries $dirty modified and $untracked untracked path(s), which no clone reproduces."
  fi
  return 0
}

printf 'kind\tpath\tbranch\tdefault_branch\thead\tdirty\tuntracked\tworktrees\tprunable\toutside_root\trisk\n' >> "$TSV"

scan_repo "$ROOT" "root"
for d in "$ROOT"/internal/*/; do [ -d "$d" ] && scan_repo "${d%/}" "internal"; done
for d in "$ROOT"/external/*/; do
  [ -d "$d" ] || continue
  if [ -e "${d}.git" ]; then
    scan_repo "${d%/}" "external"
  else
    for g in "$d"*/; do [ -d "$g" ] && scan_repo "${g%/}" "external-group"; done
  fi
done

# The parts of the estate that are not repositories and are therefore invisible to every git-shaped
# inventory. Each one is a way a move can succeed on paper and fail in use.
note ""
note "NOT A REPOSITORY, and therefore not in the table above:"
for extra in "$ROOT/_migration-checkpoints" "$ROOT/node_modules"; do
  [ -e "$extra" ] && note "  present: ${extra#$ROOT/} (untracked by design; confirm whether it travels)"
done
if [ -d "$HOME/.claude/projects" ]; then
  key=$(printf '%s' "$ROOT" | sed 's#/#-#g')
  if [ -d "$HOME/.claude/projects/$key" ]; then
    n=$(ls -1 "$HOME/.claude/projects/$key" 2>/dev/null | wc -l)
    note "  agent state: ~/.claude/projects/$key holds $n entr(ies). The directory name IS the workspace path, so renaming the root orphans it silently."
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      note "  symlink into the estate: $link -> $(readlink "$link"). An absolute link breaks on a rename and fails silently."
    done < <(find "$HOME/.claude/projects/$key" -maxdepth 1 -type l 2>/dev/null)
  fi
  other=$(ls -1 "$HOME/.claude/projects" 2>/dev/null | grep -c "^${key}-" )
  [ "$other" -gt 0 ] && note "  agent state: $other further project director(ies) are keyed to paths INSIDE this root and are orphaned by the same rename."
fi

ROWS=$(( $(wc -l < "$TSV") - 1 ))
printf 'receipt_kind\testate-inventory\n'
printf 'packet\tD01\n'
printf 'root\t%s\n' "$ROOT"
printf 'repositories\t%s\n' "$ROWS"
printf 'local_only\t%s\n' "$(awk -F'\t' 'NR>1 && $11=="irreplaceable"' "$TSV" | wc -l)"
printf 'carrying_uncommitted\t%s\n' "$(awk -F'\t' 'NR>1 && ($6>0 || $7>0)' "$TSV" | wc -l)"
printf 'off_default_branch\t%s\n' "$(awk -F'\t' 'NR>1 && $3!=$4 && $4!="unknown"' "$TSV" | wc -l)"
printf 'prunable_worktrees\t%s\n' "$(awk -F'\t' 'NR>1 {s+=$9} END {print s+0}' "$TSV")"
printf 'mutations\tnone; every git call is a query\n'
printf 'table\t%s\n' "$TSV"
printf 'findings\t%s\n' "$NOTES"
exit 0
