# Ashvale Online

A single-player MMORPG that runs in your web browser: the look of Legend of Mir 2, the heart of Classic World of Warcraft, and a cast of characters who live in the world whether or not you're there.

## Playing it

Double-click `index.html`. That's it — no install. Your character saves itself in the browser every few seconds and when you close the tab.

Once the project is on GitHub (below), it also has a web address you can open from any computer.

## What's in the folder

| | |
|---|---|
| `index.html` | The game. |
| `src/sim/` | The rules of the game: classes, monsters, items, combat, quests, the bots. *(systems worker)* |
| `src/view/` | Everything you see and hear: art, animation, effects, sound, the whole interface. *(presentation worker)* |
| `src/shared/` | The small piece both halves talk through. |
| `docs/DESIGN.md` | The design bible — what the game is and how everything is meant to work. Worth reading if you're curious; it's written in plain language. |
| `docs/ENGINEERING.md` | The technical handover for the systems worker. |
| `docs/START-HERE-WORKER-B.md` | The note to paste to a new systems worker. |
| `CHANGELOG.md` | What each worker did, newest first, with a plain-English note for you at the end of each session. |
| `tests/` | An automatic check that the game still runs. |
| `screenshots/` | Pictures of the first draft, for reference. |

## Putting it on GitHub (one-off, about five minutes)

1. Install **GitHub Desktop** from desktop.github.com and sign in with your GitHub account.
2. In GitHub Desktop: **File → Add local repository → Choose…** and pick this folder (`Desktop\ashvale-online`). It will say the folder isn't a repository yet and offer to **create a repository** — click that, then **Create Repository** (leave everything as it is).
3. Click **Publish repository** at the top. **Untick "Keep this code private"** (the free web address only works for public projects), then **Publish**.
4. On github.com, open the new `ashvale-online` repository → **Settings** (the tab on the right) → **Pages** in the left menu → under *Build and deployment* set **Source: Deploy from a branch**, **Branch: main**, folder **/ (root)** → **Save**. After a minute or two the page shows your address, something like `https://yourname.github.io/ashvale-online/`. Bookmark it.

## Sending up new work (every time)

When a worker tells you a new build is ready: open GitHub Desktop, you'll see the changed files listed on the left. Type a couple of words in the *Summary* box at the bottom-left (for example `new build`), click **Commit to main**, then click **Push origin** at the top. About a minute later, refresh the game in your browser.

## Working with two workers

- Give the systems worker this folder and paste: *"Read docs/START-HERE-WORKER-B.md and follow it."*
- Run **one worker at a time** in this folder. Let one finish and commit before you start the other, or their changes can overwrite each other.
- Each worker leaves you a plain-English note at the top of `CHANGELOG.md`: what changed, what to try, what's next.

## Backing up your character

A *Save to file* / *Load from file* button is coming to the menu. Until then, your save lives in the browser you play in; clearing the browser's site data would remove it.
