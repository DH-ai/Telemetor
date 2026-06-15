# Overnight prompt for Fable 5 (paste everything below the line)

Fill the INPUTS block first. Keep the prompt this short on purpose — all project context
lives in GOALS.md inside the repo, so the model reads it once from disk instead of you
paying for it in every message.

---

Repo: /home/dhruv/obscureP/Telemetor (Flutter telemetry visualizer, Python test backend).
Read GOALS.md and follow it exactly — tech decisions there are final, do not revisit them.

Task: complete **Goal 1, milestones G1-M0 through G1-M8**, in order, on branch `v2`.

Rules:
- One commit per milestone, message `G1-M<n>: <summary>`. Never commit broken builds:
  before each commit run `flutter analyze` (zero issues), `flutter test`, and — once
  Backend tests exist — `pytest Backend/` (all pass).
- Verify the final result end-to-end: start `python Backend/serverImp.py`, run the app
  headless or on linux desktop, confirm data flows into charts (check logs/screenshot),
  and confirm `curl localhost:8000/latest` returns live values.
- The TCP+ACK wire protocol is frozen: Backend/serverImp.py + Backend/ACK.md are the
  spec, and after G1-M7 the unmodified M3 Dart client must still connect and stream.
- Dependencies — Dart: provider, yaml + existing pubspec entries only. Python: fastapi,
  uvicorn, pytest, httpx + stdlib; pin them in Backend/requirements.txt. Ask nothing;
  if blocked, make the smallest reasonable assumption, note it in the commit message,
  and continue.
- If a milestone proves impossible as written, implement the closest working version,
  document the gap in GOALS.md under that milestone, and move on.
- Do not push. When done, write SUMMARY.md at repo root: what was completed, assumptions
  made, known issues, and exact commands for me to run and verify each test gate.

INPUTS (fill before sending):
- Primary test platform: <linux desktop | web | android>          [default: linux]
- Theme seed color: <hex or "your choice">                        [default: your choice]
- Sample data rate to test at: <Hz>                                [default: 50]
- Anything in the current UI to preserve: <none | describe>        [default: none]
