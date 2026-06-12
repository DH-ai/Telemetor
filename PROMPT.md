# Overnight prompt for Fable 5 (paste everything below the line)

Fill the INPUTS block first. Keep the prompt this short on purpose — all project context
lives in GOALS.md inside the repo, so the model reads it once from disk instead of you
paying for it in every message.

---

Repo: /home/dhruv/obscureP/Telemetor (Flutter telemetry visualizer, Python test backend).
Read GOALS.md and follow it exactly — tech decisions there are final, do not revisit them.

Task: complete **Goal 1, milestones G1-M1 through G1-M6**, in order, on branch `v2`.

Rules:
- One commit per milestone, message `G1-M<n>: <summary>`. Never commit broken builds:
  before each commit run `flutter analyze` (zero issues) and `flutter test` (all pass).
- Verify the final result end-to-end: start `python Backend/serverImp.py`, run the app
  headless or on linux desktop, confirm data flows into charts (check logs/screenshot).
- Do not modify anything under Backend/ except if a one-line fix is needed to run it;
  if its protocol is ambiguous, treat Backend/serverImp.py + Backend/ACK.md as the spec.
- Do not add dependencies beyond: provider, yaml, and existing pubspec entries. Ask
  nothing; if blocked, make the smallest reasonable assumption, note it in the commit
  message, and continue.
- If a milestone proves impossible as written, implement the closest working version,
  document the gap in GOALS.md under that milestone, and move on.
- Do not push. When done, write SUMMARY.md at repo root: what was completed, assumptions
  made, known issues, and exact commands for me to run and verify each test gate.

INPUTS (fill before sending):
- Primary test platform: <linux desktop | web | android>          [default: linux]
- Theme seed color: <hex or "your choice">                        [default: your choice]
- Sample data rate to test at: <Hz>                                [default: 50]
- Anything in the current UI to preserve: <none | describe>        [default: none]
