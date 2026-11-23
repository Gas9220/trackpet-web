# Trackpet website

The website of Trackpet (`../Trackpet`), a static site built by `build.py` and served by GitHub Pages from `main`, live at https://gas9220.github.io/trackpet-web/. `README.md` describes how it's made: read it first.

- Edit the sources (`src/`), never the generated pages, then `python3 build.py`, and commit both.
- Every text change goes in the four languages (`src/strings/*.json`, `src/guide/*.html`), in the app's own words: its string catalog, `../Trackpet/Trackpet/Localizable.xcstrings`.
- **Screenshots** are taken on the Mac with the simulator (the MacBook Pro), never on the 8 GB MacBook Air: `./take-screenshots.sh` (README, "Screenshots"), then look at every image before `./make-images.sh`, `python3 build.py` and `swift make-social-images.swift`. The screenshot test lives here, in `screenshots/`, and is never committed to Trackpet.
- Commit and push only when the user asks. Commits aren't signed (`git -c commit.gpgsign=false commit`), with the author set in this repository's config; messages as the history's: a short title in lowercase and the imperative, then what changed and why.
- Reply in the user's language, Italian or English: the one their last message is in.
