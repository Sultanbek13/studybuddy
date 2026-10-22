# StudyBuddy

**A study & habit tracker for students** — plan tasks, focus with a 25-minute timer, keep a daily streak and compete with friends.

🔗 **Live demo:** https://sultanbek13.github.io/studybuddy/

## Features

- **Tasks** grouped by subject — add, tick off, delete
- **Focus timer** — 25 min focus / 5 min break (Pomodoro), with *Demo speed* for presentations
- **Daily streak** and daily goal progress
- **Friends leaderboard** — weekly focus minutes
- **Profile** — best streak, total hours, minutes by subject, settings

## Project structure

| Path | What it is |
| --- | --- |
| `index.html` | Web app (HTML/CSS/JS, single file, works offline) |
| `flutter/lib/main.dart` | Same app as a Flutter mobile app (iOS / Android / web) |

## Run it

**Web:** open `index.html` in any browser, or use the live demo link above.

**Flutter:**
```bash
flutter create study_buddy
cp flutter/lib/main.dart study_buddy/lib/main.dart
cd study_buddy && flutter run -d chrome
```

## How it was made — AI Integration Challenge

Built with **Claude** as the central workspace, connected to other tools:

| Tool | Contribution |
| --- | --- |
| Claude Docs | Product requirements document (PRD) |
| Figma | 4 mobile screens + component library |
| GitHub | This repository and the live demo (GitHub Pages) |
| Claude Artifacts | Interactive web version |

Author: Sultanbek
