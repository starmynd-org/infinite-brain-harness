# brains/

This folder holds the brains this workspace routes between. It starts empty. `/start` clones them in from
the remotes listed in `.claude/brains.conf`:

- a shared brain (a company or department brain): the default working surface;
- your individual brain (`individual-<your-name>/`): your own scratch and research layer.

Each brain is its own independent git repo with its own remote. The workspace never tracks their
contents; `.gitignore` keeps everything under `brains/` (except this README) out of git so the brains
sync independently through `/sync`. If this folder is empty, run `/start`.
