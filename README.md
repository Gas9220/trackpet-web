# Trackpet website

The website of Trackpet, the app for pets' health records for iPhone, iPad and Mac: what the app does, screenshots, privacy and how to get in touch, in the app's four languages (English, Italian, French and Spanish). A static site, built the same way as HabitTracker's (`../habitTracker-web`): GitHub Pages serves the files as they are.

**Meant for https://gas9220.github.io/trackpet-web/**, published by GitHub Pages from the root of `main` of a public repository named `trackpet-web` (`BASE_URL` in `build.py`). Pages is free only for public repositories. `.nojekyll` tells Pages to serve the files as they are, without running Jekyll.

## Files

```
src/layout.html          The head, header and footer every page shares, with {{key}} where each language's text goes
src/pages/               Each page's content: home, support (questions and answers, contact), privacy (the policy) and guide
src/guide/<lang>.html    The guide's text in each language: long, so in files of its own rather than strings
src/strings/<lang>.json  The text in each language: en, it, fr, es
build.py                 Writes the pages from those, and sitemap.xml with every page in every language
make-app-icons.sh        Renders the app's icon into images/ (app-icon, apple-touch-icon, favicon)
take-screenshots.sh      Takes the iPhone screenshots in the simulator, with screenshots/TrackpetScreenshots.swift
make-images.sh           Writes the screenshots in WebP from the originals in ../trackpet-assets
make-social-images.swift Draws images/<lang>/social.jpg, the picture shown with links to the site
make-guide-pdfs.sh       Prints each language's guide to its guide/trackpet-guide.pdf
src/404.html             The page for an address that doesn't exist: one page, whose script picks the language
index.html               English, the home page (generated), with support/, privacy/ and guide/ beside it
it/, fr/, es/            The other languages' pages, the same four in each (generated)
styles.css               Styles, with the light and dark themes and layouts for phones
images/                  The app icon
images/<lang>/           The screenshots in each language, in WebP, with their -dark versions, and social.jpg
```

## Changing the text or the page

Edit `src/layout.html`, `src/pages/*.html`, `src/guide/*.html` or `src/strings/*.json`, never the generated `index.html` files, then run:

```bash
python3 build.py
```

and commit the sources together with the pages it writes. A key missing from a language, or one the page doesn't use, stops the build. Strings can contain HTML (`<br>`, `<span class="accent">`); `{{key|attr}}` in the template escapes a string for an attribute, like an `alt` text.

Each language uses the app's own words, from its string catalog (`../Trackpet/Trackpet/Localizable.xcstrings`): Italian says "Animali", "Centro veterinario" and "Scheda sanitaria"; French "Relevés", "Traitements", "Fiche de santé" and "vous"; Spanish "Mascotas", "Tratamientos", "Ficha de salud" and "tú". Menus are named as the app names them (Impostazioni › Aiuto e feedback, Réglages › Aide et commentaires, Ajustes › Ayuda y comentarios).

## Before the screenshots

The site can go up before the screenshots are taken. What needs a file that isn't there yet sits between `<!-- if:screenshots -->` and `<!-- end:screenshots -->` in the templates, and `build.py` leaves it out until `images/en/pets.webp` exists: the hero's phone, the Screenshots section and its menu link, and the health report's phone. The Mac's window and panel wait for `images/en/mac-window.webp` the same way (`mac-screenshots`). Until then the hero and the For the Vet section show a pet's records and its health report drawn in HTML (`<!-- if:no-screenshots -->`, the `.record-card` and `.report-sheet` styles), with Paco's sample data, and the Mac section is text alone. The guide's Download PDF button works the same way, with `guide/trackpet-guide.pdf` (`<!-- if:guide-pdf -->`).

Once the screenshots are in `images/<lang>/`, `python3 build.py` puts them all in, and leaves the drawn ones out.

## Screenshots

Take them on the Mac that runs the simulator well (the MacBook Pro M1 Pro; this site was made on the 8 GB MacBook Air, too slow for it), with the projects side by side: `Trackpet/`, `trackpet-web/` and, made by the script, `trackpet-assets/`. The full-size originals go in `../trackpet-assets/screenshots/<lang>/iphone/`, `iphone-dark/`, `mac/` and `mac-dark/`, outside this repository, so they can be reused for the App Store page.

### iPhone, automatically

```bash
git -C ../Trackpet pull
./take-screenshots.sh
```

It boots the iPhone 18 Pro Max simulator (another one: `./take-screenshots.sh "iPhone 17 Pro Max"`, or a few languages: `./take-screenshots.sh "iPhone 18 Pro Max" it fr`), sets the status bar to 9:41 and full, builds Trackpet once, then runs `screenshots/TrackpetScreenshots.swift`, a UI test, once per language and appearance, with the app's sample data, whose breeds, allergies and notes are translated too. It finds every element by its accessibility identifier, so one test serves the four languages. Each run takes about a minute, so the whole set about ten. The test is copied into Trackpet's UI tests for the run and taken out again, so Trackpet's repository is left as it was: the app's CLAUDE.md asks that screenshot tests are never committed. When a run fails, the script says which and keeps its log; a changed screen or identifier in the app is fixed in the test here.

The screens, named as `make-images.sh` expects them:

| File | Screen |
|---|---|
| `01-pets.png` | The Pets list |
| `02-pet.png` | Paco's page, its Records |
| `03-weights.png` | Paco's weights over a year |
| `04-vaccinations.png` | Paco's vaccinations, the boosters first |
| `05-therapy.png` | The therapy for Paco's fever, this morning's dose given |
| `06-calendar.png` | The Calendar tab, on today |
| `07-documents.png` | Paco's documents, by year |
| `08-costs.png` | Harry's costs |
| `09-clinic.png` | Clinica Veterinaria Rossi's page |
| `10-settings.png` | Settings, scrolled to the units and the app icons |
| `11-health-report.png` | Paco's health report, open in Quick Look |

Then look at them (they're the site's first impression: a screen caught mid-animation or with a banner is taken again), and with `cwebp` (`brew install webp`):

```bash
./make-images.sh
python3 build.py
swift make-social-images.swift
```

The first build with them turns on the hero's phone, the Screenshots section and the health report's phone, and leaves the drawn ones out.

### Mac, by hand

Optional: until they're there, the Mac section is text alone (`<!-- if:mac-screenshots -->`). Build and run Trackpet for the Mac with the sample data, the window at its default size:

```bash
xcodebuild -project ../Trackpet/Trackpet.xcodeproj -scheme Trackpet -destination 'platform=macOS' -derivedDataPath /tmp/trackpet-mac.noindex build
open /tmp/trackpet-mac.noindex/Build/Products/Debug/Trackpet.app --args -ui-testing -sample-data
```

Select Paco, then, for each language (`-AppleLanguages "(it)"` after `--args`) and each appearance (System Settings › Appearance):

```bash
screencapture -o -W ../trackpet-assets/screenshots/en/mac/01-window.png     # click the window
screencapture -o -W ../trackpet-assets/screenshots/en/mac/02-menu-bar.png   # open the paw's panel, then click it
```

(`mac-dark/` for the dark ones; `-o` leaves out the shadow.) Then put each image's size in the `width` and `height` of `mac-window` and `mac-menu-bar` in `src/pages/home.html` (the window 1100 wide, the panel 360, as `make-images.sh` writes them), and run the three commands above.

## The app icon

The icons are the app's Classic icon (`../Trackpet/Trackpet/AppIcons/AppIcon.icon`), rendered with Icon Composer's `ictool`, which comes with Xcode, and resized with `sips`. After the icon changes:

```bash
./make-app-icons.sh
swift make-social-images.swift
```

## The guide

`guide/` explains every feature, written from the app's CLAUDE.md, and names each button and setting in the words the app uses for it in each language, so what the guide says is what's on screen. When a feature ships or changes, change the guide with it, in all four files of `src/guide/`. `build.py` makes the table of contents from their `<h2 id="…">` headings.

The Download PDF button saves a PDF printed from the page itself, with Chrome or Edge. It shows only once the PDFs are there, so print them on a Mac with one of them, and again after any change to the guide:

```bash
python3 build.py
./make-guide-pdfs.sh
python3 build.py
```

The print styles at the end of `styles.css` decide how they look: A4, the brand on top, without the menus, the footer or the button.

## Languages

A menu in the header lists the four languages by their own names, as the app's language picker does. English is at the root and the others in their own folder, each page linking to the others with `hreflang`. On the first visit to the English page, a browser set to Italian, French or Spanish opens that language instead; choosing one in the menu is remembered (`localStorage`), and from then on nothing redirects.

## Themes

The site starts in the device's theme (`prefers-color-scheme`), and the sun or moon button in the header switches to the other. The choice is kept in `localStorage` (`theme`), and a small script in the head sets it as `data-theme` on `<html>` before the page draws. `styles.css` has the dark colors twice, once for each way of getting there: change both. Each screenshot is a `<picture>` whose dark `<source>` is its `-dark.webp`, which the layout's script turns on or off while a theme is chosen. The health report's drawn page stays light in both, as the PDF is.

## Search engines

`sitemap.xml` lists every page in every language, with its translations; submit it in Google Search Console. A `robots.txt` pointing to it would be ignored here: crawlers read one only at the domain's root, `gas9220.github.io`, which isn't this repository.

## Preview

```bash
python3 -m http.server 8765 --directory .
```

Then open http://localhost:8765 (the pages in other languages need a server, since their links point to folders).

## Before release

- **Support email**: `support@example.com` is a placeholder, the same as `AppInfo.supportEmail` in the app. Replace both with the real address (it's in `src/pages/home.html`, `support.html` and `privacy.html`).
- **App Store link**: the hero says the app is coming soon; add the badge and link once it's out.
- **Whether this replaces the App Store's Trackpet** (PetManager) is still the user's decision, as the app's CLAUDE.md says; if it does, the site may need to say what happens to PetManager's data.
- **Translations**: written to match the app's wording; a native speaker's review is still to do, as for the app.
- **Privacy policy** (`privacy/`): it describes the app as it is, with no iCloud sync. If sync ships, say how it works (Apple's iCloud, under the user's account), and change the date at the top in every language.
