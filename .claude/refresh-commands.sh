#!/usr/bin/env bash
# Refresh this harness's runtime layer from the brains mounted under internal/.
#
# Claude Code loads only the .claude/ at the folder you open (this harness root); it never loads a
# child repo's .claude/. So this script (1) COPIES each mounted brain's .claude/{commands,skills,
# agents,rules} up into this root's .claude/ so they work as slash commands here, and (2) regenerates
# .claude/CAPABILITIES.md, a brain-selection index of what each brain holds. Run by /start and /sync.
#
# WHICH CHILDREN COUNT AS BRAINS. internal/ holds everything this operation owns: brains AND ordinary
# app repos. Plenty of app repos carry a .claude/ of their own, and sweeping those up would pollute
# this root with commands that have nothing to do with any brain. So a child of internal/ is a mount
# source only when it carries BOTH .claude/ AND _system/validate.sh, the marker every brain built from
# the Infinite Brain starter has and no app repo does. That is a structural test, not a hand-kept
# list: add a brain and it is picked up with nothing to register, which matters because the failure
# mode of a hand-kept list is silent (the new brain's commands simply never appear and nobody is told
# why).
#
# WHY THIS IS NOT A PLAIN COPY. A seat mounts at least two brains here (a shared work brain and an
# individual brain), and they descend from the same starter, so nearly every entity name exists in
# BOTH. A last-one-wins copy would silently hand you one brain's version of a name the other also
# carries, and the day the two diverge you would have no way to tell which one ran. Worse, two agents
# cannot register under one frontmatter `name:` at all. So every collision is resolved instead:
#
#   1. A name only one brain carries is copied under its plain name.
#   2. A name several brains carry with BYTE-IDENTICAL content is copied once, under its plain name.
#      Provenance credits every brain that has it. On day one this is almost every name, because the
#      brains are fresh copies of the same starter.
#   3. A name several brains carry with DIFFERENT content is copied once per brain under a tagged name
#      (`co-promote.md`, `me-promote.md`). No ambiguous plain-name copy is written, so a tagged name
#      is the only way to invoke it and you always know which brain's version you ran. For agents the
#      frontmatter `name:` is rewritten to match, because a subagent's identity is its frontmatter
#      name, not its filename.
#
# Rule 3 is what makes this harness safe to diverge. Edit a skill in one brain and only that brain's
# copy changes name; the other stays where it was.
#
# Safe to re-run. Files copied by a previous refresh are cleared first (so a deletion in a brain
# propagates), then everything is re-copied. This root's own commands and settings are never touched.
#
# NOTE: newly copied slash commands appear only after Claude Code is RESTARTED (it reads .claude/ at
# startup).
#
# Portability: this may run on a Mac, so it stays inside bash 3.2 and POSIX tools. No associative
# arrays, no `sed -i`, no GNU-only flags.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."          # the harness root (the folder holding .claude/)

CLAUDE=".claude"
MANIFEST="$CLAUDE/.copied-manifest"
PROVENANCE="$CLAUDE/COPIED-FROM.md"
CAPS="$CLAUDE/CAPABILITIES.md"
KINDS="commands skills agents rules"

# Root-owned commands. Never copied over, never tagged, never overwritten by a brain's version.
#
# ADDING A COMMAND HERE: protect a name only when this root OWNS a copy of it under
# .claude/commands/. Protection is implemented as "skip this name when indexing the brains" (see the
# `continue` in the indexing loop below), so protecting a name this root does NOT own means the
# command is not copied up from either brain and does not exist at this root AT ALL. That is the
# opposite of what protecting it is usually meant to achieve. A brain-owned command that must stay
# reachable under its plain name belongs in the brain, NOT on this list, and it stays plain for as
# long as only one brain carries that name.
#
# The negation list in .gitignore must name this same set: a protected name with no root copy does
# not exist here, and a root copy with no negation is not versioned.
PROTECTED_COMMANDS="start.md sync.md save.md promote-to-department.md workspace-help.md register-repo.md"

# MOUNT_ROOT: where brains live. This harness mounts them under internal/, alongside the operation's
# own app repos; the _system/validate.sh test below is what tells the two apart.
MOUNT_ROOT="internal"

# Each source resolves to `path:tag:label`. The tag prefixes a collided filename; the label prefixes a
# collided agent's frontmatter name. Both are DERIVED from the folder name, so a seat works with no
# configuration at all. Override one here only when the derived tag is unwieldy to type.
#
# The derivation:
#   individual-<name>  ->  tag `me`,  label `Mine`
#   <slug>-brain       ->  tag `<slug>`, label `<slug>`
#   anything else      ->  tag `<folder>`, label `<folder>`
#
# `me` is deliberately not the person's name. On a two-person seat both people mount the same shared
# brain plus their own, so `me-` means "the brain of whoever is sitting here"; a command tagged
# `alice-` on one machine and `bob-` on the other would make the two seats disagree about what to
# type for the same thing.
#
# Format: space-separated `folder:tag:label` triples. Example:
#   TAG_OVERRIDES="acme-brain:co:Acme"
TAG_OVERRIDES="${TAG_OVERRIDES:-}"

derive_tag() {
  case "$1" in
    individual-*) printf 'me' ;;
    *-brain)      printf '%s' "${1%-brain}" ;;
    *)            printf '%s' "$1" ;;
  esac
}

derive_label() {
  case "$1" in
    individual-*) printf 'Mine' ;;
    *-brain)      printf '%s' "${1%-brain}" ;;
    *)            printf '%s' "$1" ;;
  esac
}

discover_sources() {
  [ -d "$MOUNT_ROOT" ] || return 0
  for child in "$MOUNT_ROOT"/*; do
    [ -d "$child" ] || continue
    folder="$(basename "$child")"
    # A brain, not an app: it carries a .claude/ AND the starter's validator. An app repo with its own
    # .claude/ is skipped here on purpose, and that is not an error.
    [ -d "$child/$CLAUDE" ] || continue
    [ -f "$child/_system/validate.sh" ] || continue
    tag=""; label=""
    for ov in $TAG_OVERRIDES; do
      if [ "${ov%%:*}" = "$folder" ]; then
        rest="${ov#*:}"; tag="${rest%%:*}"; label="${rest#*:}"; break
      fi
    done
    if [ -z "$tag" ]; then
      tag="$(derive_tag "$folder" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '-' | sed 's/-*$//')"
      label="$(derive_label "$folder")"
    fi
    printf '%s:%s:%s\n' "$child" "$tag" "$label"
  done
}

if [ ! -d "$MOUNT_ROOT" ]; then
  echo "refresh-commands: no $MOUNT_ROOT/ yet; run /start first."
  exit 0
fi

SOURCES="$(discover_sources)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

hash_file() {
  if command -v shasum >/dev/null 2>&1; then shasum "$1" | awk '{print $1}'
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then md5 -q "$1"
  else cksum "$1" | awk '{print $1 "-" $2}'
  fi
}

# Copy an agent while rewriting the first frontmatter `name:` so the tagged copies of one agent do not
# both try to register as the same subagent. Body is untouched.
retag_agent() {
  awk -v label="$3" '
    BEGIN { fm = 0; done = 0 }
    NR == 1 && $0 == "---" { fm = 1; print; next }
    fm == 1 && $0 == "---" { fm = 2; print; next }
    fm == 1 && done == 0 && /^name:[ \t]/ {
      sub(/^name:[ \t]*/, ""); print "name: " label " " $0; done = 1; next
    }
    { print }
  ' "$1" > "$2"
}

# ---------------------------------------------------------------------------
# 1. Remove what a previous refresh copied (leaves root-owned files untouched).
# ---------------------------------------------------------------------------
if [ -f "$MANIFEST" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] && rm -rf "$CLAUDE/$rel"
  done < "$MANIFEST"
fi

# ---------------------------------------------------------------------------
# 2. Index every entity in every present brain: kind | basename | tag | label | brain | content hash.
# ---------------------------------------------------------------------------
INDEX="$TMP/index"
: > "$INDEX"
present=""

for spec in $SOURCES; do
  path="${spec%%:*}"; rest="${spec#*:}"; tag="${rest%%:*}"; label="${rest#*:}"
  present="$present $path"
  src="$path/$CLAUDE"
  for kind in $KINDS; do
    [ -d "$src/$kind" ] || continue
    for entry in "$src/$kind"/*; do
      [ -e "$entry" ] || continue
      base="$(basename "$entry")"
      if [ "$kind" = "commands" ]; then
        case " $PROTECTED_COMMANDS " in *" $base "*) continue ;; esac
      fi
      # A directory-shaped entity (skills/<name>/SKILL.md) is never treated as identical to another
      # brain's, so a name shared by two of them always resolves to tagged copies.
      if [ -d "$entry" ]; then h="dir-$tag"; else h="$(hash_file "$entry")"; fi
      printf '%s|%s|%s|%s|%s|%s\n' "$kind" "$base" "$tag" "$label" "$path" "$h" >> "$INDEX"
    done
  done
done

# ---------------------------------------------------------------------------
# 3. Decide each entity's fate: plain (unique) | same (identical across brains) | tagged (differs).
# ---------------------------------------------------------------------------
awk -F'|' '
  { key = $1 "|" $2
    n[key]++
    if (!((key SUBSEP $6) in seen)) { seen[key SUBSEP $6] = 1; distinct[key]++ }
    line[NR] = $0 }
  END {
    for (i = 1; i <= NR; i++) {
      split(line[i], a, "|"); key = a[1] "|" a[2]
      if (n[key] == 1)             mode = "plain"
      else if (distinct[key] == 1) mode = "same"
      else                         mode = "tagged"
      print line[i] "|" mode
    }
  }' "$INDEX" > "$TMP/decided"

# ---------------------------------------------------------------------------
# 4. Copy, recording provenance as we go.
# ---------------------------------------------------------------------------
: > "$MANIFEST"
: > "$TMP/seenkeys"
: > "$TMP/prov"
: > "$TMP/collide"
copied=0; tagged=0; shared=0

while IFS='|' read -r kind base tag label path h mode; do
  [ -n "${kind:-}" ] || continue
  src="$path/$CLAUDE/$kind/$base"
  case "$mode" in
    plain)
      target="$base" ;;
    same)
      key="$kind|$base"
      if grep -Fxq "$key" "$TMP/seenkeys" 2>/dev/null; then
        # Already copied from an earlier brain; just credit this brain in the provenance line.
        printf '%s|%s|%s\n' "$kind/$base" "$path" "identical" >> "$TMP/prov"
        continue
      fi
      echo "$key" >> "$TMP/seenkeys"
      shared=$((shared + 1))
      target="$base" ;;
    tagged)
      target="$tag-$base"
      tagged=$((tagged + 1))
      printf '%s|%s|%s\n' "$base" "$kind/$target" "$path" >> "$TMP/collide" ;;
    *)
      continue ;;
  esac

  mkdir -p "$CLAUDE/$kind"
  rel="$kind/$target"
  rm -rf "$CLAUDE/$rel"
  if [ "$mode" = "tagged" ] && [ "$kind" = "agents" ] && [ -f "$src" ]; then
    retag_agent "$src" "$CLAUDE/$rel" "$label"
  else
    cp -a "$src" "$CLAUDE/$rel"
  fi
  echo "$rel" >> "$MANIFEST"
  printf '%s|%s|%s\n' "$rel" "$path" "$mode" >> "$TMP/prov"
  copied=$((copied + 1))
done < "$TMP/decided"

# Drop any kind folder the refresh emptied out.
for kind in $KINDS; do
  [ -d "$CLAUDE/$kind" ] || continue
  rmdir "$CLAUDE/$kind" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 5. Write the provenance file.
# ---------------------------------------------------------------------------
{
  echo "# Copied command layer (auto-generated by /start and /sync; do not hand-edit)"
  echo
  echo "These entities were copied up from the brains mounted under \`internal/\` so they work as slash"
  echo "commands, agents and skills at this root. Claude Code does not load a child repo's \`.claude/\`,"
  echo "so without this copy-up they would not exist here."
  echo
  echo "IMPORTANT: a command copied from a brain assumes THAT brain's folder as its working directory"
  echo "(its relative paths resolve there). When you run one, \`cd\` into its source brain first, per"
  echo "the mapping below."
  echo
  echo "This file is regenerated on every sync. Editing a copy here is pointless: the edit is"
  echo "overwritten. Edit the entity in its source brain and re-sync."
  echo
  if [ -s "$TMP/collide" ]; then
    echo "## Names that exist in both brains, with different content"
    echo
    echo "Each is copied once per brain under a tagged name, so nothing is shadowed and you always"
    echo "know whose version you are running. There is deliberately no untagged copy."
    echo
    echo "| Original name | Invoke as | From brain |"
    echo "|---------------|-----------|------------|"
    sort "$TMP/collide" | while IFS='|' read -r orig target path; do
      echo "| \`$orig\` | \`$target\` | \`$path/\` |"
    done
    echo
  fi
  echo "## Every copied entity"
  echo
  echo "\`identical\` marks a brain that carries the same file byte for byte, so one copy serves both."
  echo "\`plain\` means only that brain carries the name. \`tagged\` means the name collided."
  echo
  echo "| Entity | Source brain | Run it from | How it resolved |"
  echo "|--------|--------------|-------------|-----------------|"
  sort "$TMP/prov" | while IFS='|' read -r rel path mode; do
    echo "| \`$rel\` | \`$(basename "$path")\` | \`$path/\` | $mode |"
  done
} > "$PROVENANCE"

# ---------------------------------------------------------------------------
# 6. Regenerate the brain-selection index: what each brain holds, with a one-line when-to-use.
# ---------------------------------------------------------------------------
{
  echo "# Capabilities: which brain holds what (auto-generated by /start and /sync; do not hand-edit)"
  echo
  echo "Use this to route work to the right brain. Regenerated on every sync from each brain's own"
  echo "structure. Default posture: real and shared work in the shared brain, anything new, uncertain"
  echo "or disruptive in your own."
  echo
  for braindir in "$MOUNT_ROOT"/*/; do
    [ -d "$braindir" ] || continue
    brain="$(basename "$braindir")"
    case "$brain" in
      individual-*) role="individual brain (your scratch and research; fewer guardrails)" ;;
      *)            role="shared brain (the default working surface; canon others rely on)" ;;
    esac
    echo "## $brain"
    echo "_${role}_"
    # a when-to-use summary from the brain's own orientation, if present: the whole
    # first prose paragraph (wrapped lines joined), not just its first line.
    for f in "$braindir"README.md "$braindir"CLAUDE.md; do
      if [ -f "$f" ]; then
        line="$(awk '/^[A-Za-z]/ { found=1 } found { if (/^[[:space:]]*$/) exit; printf "%s ", $0 }' "$f" 2>/dev/null | sed 's/[[:space:]]*$//')"
        [ -n "$line" ] && echo "- summary: $line"
        break
      fi
    done
    if [ -d "$braindir"knowledge ]; then
      ns="$(ls -1 "$braindir"knowledge 2>/dev/null | grep -v '^_' | awk 'NR > 1 { printf ", " } { printf "%s", $0 } END { print "" }')"
      [ -n "$ns" ] && echo "- knowledge namespaces: $ns"
    fi
    for area in tools workflows departments; do
      if [ -d "$braindir$area" ]; then
        c="$(ls -1 "$braindir$area" 2>/dev/null | grep -vi readme | wc -l | tr -d ' ')" || true
        [ "$c" != 0 ] && echo "- $area: $c" || true
      fi
    done
    for etype in commands agents skills; do
      d="$braindir.claude/$etype"
      if [ -d "$d" ]; then
        c="$(ls -1 "$d" 2>/dev/null | wc -l | tr -d ' ')" || true
        [ "$c" != 0 ] && echo "- $etype: $c (copied up; usable here after a restart)" || true
      fi
    done
    echo
  done
} > "$CAPS"

# ---------------------------------------------------------------------------
# 7. Report.
# ---------------------------------------------------------------------------
echo "refresh-commands: copied $copied entities into $CLAUDE/ ($tagged tagged to resolve a name collision, $shared shared byte-for-byte across brains)."
if [ -n "$present" ]; then
  echo "  brains read:$present"
else
  echo "  no brain under $MOUNT_ROOT/ carries a .claude/ and _system/validate.sh yet. Run /start."
fi
echo "  provenance: $PROVENANCE"
echo "  capabilities: $CAPS   (restart Claude Code to load new slash commands)"
