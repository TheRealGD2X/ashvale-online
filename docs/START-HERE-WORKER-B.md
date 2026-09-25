# Start here — systems worker

You are the **systems worker** on Ashvale Online, a single-player browser MMORPG (Legend of Mir 2 look, Classic World of Warcraft feel) owned by GD2X, who is not technical and wants a game that is polished, balanced, cozy, challenging, and gives back the more it is played. A second worker (the presentation worker) owns everything the player sees and hears. You own the rules.

Do these, in order, before writing any code:

1. Read `docs/DESIGN.md` end to end. It is the source of truth for what the game is. If something is unclear, write the question in `docs/QUESTIONS.md` with the default you will take, and carry on with the default.
2. Read `docs/ENGINEERING.md`. It defines what you own (`src/sim/**`), what you must never touch (`src/view/**`, `index.html`), the seam between us (`S` state, `EV` events in `src/shared/events.js`, the `G` command API you will build), conventions, tests, and the milestones M1–M6 with acceptance criteria.
3. Open `index.html` in a browser and play the current draft for ten minutes so you know what exists. Run `python3 tests/smoke_test.py` once so you know it passes today.
4. Read `CHANGELOG.md` for anything the presentation worker has flagged `[need]` or `[cross]` since the last session.

Then start **M1 — combat core**, as specified in ENGINEERING.md §8, and don't move to M2 until M1's acceptance criterion holds and the smoke test is green.

Rules that matter most:
- The sim never touches the DOM, the canvas or audio. Emit events.
- Never depend on any DOM id, CSS class or `UI.*` field — the view is being rebuilt under you.
- Every commit: smoke test green, one line in `CHANGELOG.md`.
- Change `docs/DESIGN.md` when the numbers change, in the same commit.
- Potions on a 120 s cooldown, a real threat table, and monsters that keep up with the player are not optional. They are the difference between a game and a toy.

When you finish a session, end with a short plain-English note for GD2X in the changelog: what changed, what to try in the game, and what's next.
