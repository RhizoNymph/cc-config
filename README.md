# cc-config

This is just my claude code config, only global for now. 

I wanted to be able to easily clone it anywhere and thought maybe it would be useful for other people so I made it public.

Just copy everything in global to ~/.claude/ but if you already have a ~/.claude/CLAUDE.md or ~/.claude/settings.json make sure to handle merging what you want manually instead.

## Scripts

- `./install.sh` — copies `global/` into `~/.claude/`. Skips `CLAUDE.md`, `settings.json`, `settings.local.json` if they differ; pass `--force` to overwrite.
- `./diff.sh` — shows what differs between `global/` in this repo and `~/.claude/`. Pass `-d` for full unified diffs, `-r` to reverse the diff direction (target → source). Exits non-zero if anything differs.
