# Anti-Pattern Prevention

Rules derived from session analysis to prevent recurring issues.

## Edit Discipline (prevents edit-thrashing)

- **One complete edit per file**: read the full file, plan all changes, then make ONE edit. Multiple small edits to the same file signal you didn't understand it fully
- **3-edit rule**: if you've edited a file 3+ times in a task, stop. Re-read the user's requirements from scratch. Your mental model drifted
- **Plan before touch**: for files >100 LOC, write out what you'll change before editing. This prevents incremental fumbling

## Goal Alignment (prevents negative-drift)

- **Periodic re-read**: every 3-5 turns, re-read the original request. Quote the specific requirement you're addressing
- **Drift check**: before reporting completion, verify each requirement was addressed. If you can't map your changes to requirements, you drifted
- **User correction protocol**: when corrected, stop immediately. Quote back what they asked for. Confirm understanding before proceeding

## Failure Handling (prevents error-loops)

- **2-failure rule**: after 2 consecutive failures of the same approach, stop. Change strategy entirely. Explain what failed and try something fundamentally different
- **No blind retry**: never retry the exact same command/edit hoping for different results. Diagnose first
- **Stuck protocol**: when stuck, summarize what you've tried, the exact errors, and ask the user for guidance. Don't spiral

## Execution Pace (prevents excessive-exploration)

- **3-5 file limit**: don't read more than 3-5 files before making a change. Get basic understanding, make the change, iterate
- **Verify before report**: double-check your output actually addresses what was asked. Don't assume — verify

## Autonomy Balance

- **Reasonable defaults**: make reasonable decisions without asking for confirmation on routine steps
- **Ask for blockers only**: questions should resolve genuine ambiguity, not seek permission for obvious actions
- **Follow through completely**: re-read the user's last message before responding. Execute every instruction, not just the first one
