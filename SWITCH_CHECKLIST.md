# Device Switch Checklist

## Before Leaving Device A
- [ ] `git status` is reviewed
- [ ] update `HANDOFF.md` sections 1-5
- [ ] commit changes (or create a WIP commit)
- [ ] `git push` to remote branch
- [ ] send one short context message in the same Codex thread:
  - `Continue <task-name>. See HANDOFF.md.`

## After Opening Device B
- [ ] open the same Codex thread
- [ ] `git pull`
- [ ] read `HANDOFF.md` sections 1-5
- [ ] run project startup/test command
- [ ] continue from `Next Actions`

## Recovery Rules
- If local branch diverged:
  - stop and check `git status` + `git log --oneline --decorate --graph -20`
- If context feels missing:
  - treat `HANDOFF.md` as source of truth
  - summarize current understanding in-thread before coding
- If urgent switch with uncommitted changes:
  - create checkpoint commit:
    - `git add -A && git commit -m "chore: emergency checkpoint"`

