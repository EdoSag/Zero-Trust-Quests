# Zero-Trust Quests

Daily quests for your own goals, with XP, gold and levels, end-to-end
encrypted. On the phone it is called **ZT Quests**; in stores and on release
pages, **Zero-Trust Quests**. Same account, settings and look as the other
Zero-Trust apps, built on
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core). Part of the
[Zero-Trust suite](https://zerotrust.bz).

## What it does

- **Goals:** get fitter, be more productive, eat healthier, sleep better,
  learn something, feel calmer, or your own goal with your own habits. A few
  questions per goal (current level, push-ups in a row, longest run, time per
  day, what gets in the way...) size the quests.
- **Daily quests:** one per goal per day, made of 1 to 3 steps
  ("25 push-ups, run 2 km, plank for 45 seconds"). Steps are ticked or logged
  with an amount.
- **Difficulty that adapts**, per goal: it starts at 1× (your answers). Each
  completed quest raises it 5%, a quest left under half done lowers it 7%, and
  declining as too hard / too easy moves it 15% at once. Kept between 0.5×
  and 3×.
- **Declining:** too hard, too easy, something else (other activities, same
  difficulty) or not today (skip the goal for the day). The first decline of
  the day is free, more cost 10 gold. Up to 3 swaps per goal per day.
- **Epic quests:** after 3 completed daily quests a goal offers a bigger,
  one-time quest with a deadline (a long run, 7 days in a row, 15× your daily
  push-ups in two weeks...). Daily quests count towards it. You can also write
  your own ("Read 3 books in 30 days").
- **Rewards:** XP and gold per quest (more for harder ones), a streak bonus
  of 5% per day in a row (up to 50%), levels (level L needs 50·L·(L−1) XP) and
  titles from Novice to Legend.
- **Shop:** streak freezes (60 gold, keep a streak through one missed day, hold
  up to 3), emblems and colours for your hero. Some unlock free with levels.
- **Party quests:** start a party with friends and hunt a boss together.
  Every daily quest anyone in the party finishes hits it (ZT Tasks tasks hit
  a little too); beat it before the hunt ends (3, 7 or 14 days) and everyone
  who helped gets XP and gold. The boss's hit points grow with the party.
  Invite by link or QR code, compare a short code, end-to-end encrypted. The
  party sees your name, level, hero look and damage, nothing about your goals.
- **ZT Tasks as quests** (optional, Settings → ZT Tasks): pick which ZT Tasks
  lists count. Each task you tick off in them earns 5 to 12 XP by priority,
  and gold, up to 10 tasks a day (repeating tasks count each round). Quests
  only reads your tasks; it never changes them.
- **Achievements:** a gallery on the Hero tab (first quest, streaks, levels,
  epic quests, tasks, bosses, events...), worked out from your progress.
- **Seasonal events:** limited-time epic quests anyone can join while they
  run: a fresh start in January, a Hanukkah streak (all eight days) and a
  summer step challenge (300,000 steps in July and August). Each wins an
  emblem you can't get any other way.
- **Health Connect** (optional, Settings): fills steps, distance, workout
  minutes, sleep and water on its own, from ZT Fitness (with Health write-back
  on), a watch or other apps. Read on the phone only; never lowers what you
  logged by hand.
- **Home screen widgets** (Android): today's quest (tick steps right there),
  hero card (level, title, XP, gold), streak flame (amber until a quest is
  done today) and next step (1x1, with a tick when wider; offered on the lock
  screen where the phone supports lock screen widgets). By default they show
  only numbers; step texts and goal names need "Show details on the home
  screen" in Settings. A tick is saved by the app the next time it opens.
- **Daily reminder** (optional, Settings): "Your quests are waiting" at a time
  you pick. It never names a goal, and it skips days you have already finished.

## Privacy

Like every Zero-Trust app, it is zero-knowledge: your data is encrypted on
your device, with keys made from your password, before anything is sent.
The server stores only ciphertext and your password itself is never
sent, so neither we nor anyone who breaks into the server can read your
data. The recovery key shown at sign-up is the only way back in if you
forget the password. How the keys work:
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core#key-hierarchy) and
[zerotrust.bz/security](https://zerotrust.bz/security/).

- Quests are made on the phone, by rules, not by an AI service: nothing
  about your goals leaves the device unencrypted.
- A party sees your name, level, hero look and damage, nothing about your
  goals.
- Widgets show only numbers until "Show details on the home screen" is on.
- Health Connect is read on the phone only, and ZT Tasks is only read,
  never changed.

## One account, one core

One Zero-Trust account opens every app in the suite. Sign-in, unlock
(fingerprint or face, auto-lock), the recovery key, settings, the look,
sync and languages come from
[Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core), so they work
the same in every app. Accounts made before the core still sign in and
see their data.

## Install

Android: get the latest signed APK from this repository's
[Releases](https://github.com/EdoSag/Zero-Trust-Quests/releases/latest),
or from [zerotrust.bz/install](https://zerotrust.bz/install/#quests),
which also shows each file's SHA-256, the signing fingerprint and an
Obtainium link. GitHub Releases are the main way the apps are published.

Builds from GitHub check for a newer release themselves (Settings > About,
one anonymous request a day, can be turned off). Every Zero-Trust app is signed
with the same key, and Android only installs an update signed with it.

## Languages

English and Hebrew, with right-to-left layout. Choose under
Settings > Appearance > Language.

## How it is built

- Quests are made **on the phone**, by rules (`lib/engine/`), not by an AI
  service: nothing about your goals leaves the device unencrypted.
- The same goal and day always make the same quest (seeded by a stable hash),
  and daily quest ids are `daily-<goal>-<day>-<swap>`, so two phones agree.
- XP, gold, level, streak and difficulty are **worked out** from the synced
  quests and purchases every time, never stored as counters, so two phones
  can't overwrite each other's progress.
- Items in the shared `vault_items` table, sealed with the Quests app key
  (`app = 'quests'`): kinds `goal`, `quest`, `purchase`, `reward`, `hero` and
  `tasks_link`. No database change was needed.
- Parties are Z24 shared spaces of app `quests` (the core's sharing, with the
  shared sharing screens from `zt_sharing_ui`): item `party` (owners only:
  name, boss strength, current hunt) and `member/<userId>` (only that member
  can write it: damage, level, hero look). A beaten boss becomes a `reward`
  item `party-<space>-<hunt>` in each helper's own vault.
- ZT Tasks is read the way ZT Calendar reads it: at unlock Quests also
  derives ZT Tasks' key and keeps its own encrypted, read-only copy of ZT
  Tasks' items. A ticked-off task becomes a `reward` item `task-<id>` (or
  `task-<id>-<due day>` for a round of a repeating task), so two phones make
  the same one.
- Health Connect and the reminder are per phone (kept with the core's
  preferences, not synced).

## Build from source

Flutter 3.47.9, the version CI pins (3.50 deprecates `material.dart` and
fails analyze).

```bash
# .env (not committed; CI writes its own). Public client values only:
# never a service-role key, because .env is bundled into the APK.
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<publishable key>

flutter pub get
dart run zt_release_checks --app quests   # shared release checks
flutter analyze && flutter test test/
flutter run
```

Never add `cryptography_flutter`: it breaks the core's key derivation and
sign-in fails.

## Branches and releases

Work happens on `Dev`: pull requests target `Dev`, never `main`, and get a
test build. A release is one `Dev` → `main` pull request. Every push to
`main` runs the suite's release checks, builds a signed APK and a Google Play bundle
and publishes them as a GitHub Release named "Zero-Trust Quests"
(`.github/workflows/android-apk.yml`). The workflow needs the repository
secrets `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD`, the
keystore shared by all Zero-Trust apps.

Play Store text and graphics: `fastlane/metadata/android/` (English and
Hebrew).

## Support and security

- Help centre: [zerotrust.bz/help](https://zerotrust.bz/help/). Questions and
  account deletion: support@zerotrust.bz.
- Security problems: please report them privately to cyber@zerotrust.bz. What
  the encryption does and doesn't protect against is on
  [zerotrust.bz/security](https://zerotrust.bz/security/).
- [Privacy policy](https://zerotrust.bz/privacy/) and
  [terms](https://zerotrust.bz/terms/).

## License

Copyright (C) 2026 Edo Sagron (https://zerotrust.bz)

Zero-Trust is open source under the [GNU Affero General Public License v3.0](LICENSE)
(AGPL-3.0-only), the same licence Signal uses.

- You may use, study, change and share the code, including in your own projects.
- If you share a changed version, or run it for other people over a network, you must
  publish your full source code under the same licence.
- This program comes with no warranty; see the licence for details.

Third-party libraries keep their own licences; the app lists them under
Settings > Open-source licences.

### Name and logo

The AGPL covers the code, not the brand. "Zero-Trust", "ZT", the app names and icons are
reserved. If you publish a fork, give it a different name and icon so nobody mistakes it
for an official Zero-Trust app.

### Servers

The official apps use the Zero-Trust servers. A fork must use its own backend (for
example its own Supabase project) and must not connect to the official servers.

### Contributing

Pull requests are welcome. By sending one you agree that your contribution is licensed
under the AGPL-3.0 and that the copyright holder may also license it under other terms,
including commercially. This keeps the project able to offer paid plans and other licences.
