# Zero-Trust Quests

Daily quests for your own goals, with XP, gold and levels (on the phone:
**ZT Quests**). Same account, settings and look as the other Zero-Trust apps,
built on [Zero-Trust-Core](https://github.com/EdoSag/Zero-Trust-Core), and
end-to-end encrypted like them.

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

## Build

```bash
# .env (not committed; CI writes its own)
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<publishable key>

flutter pub get
dart run zt_release_checks --app quests   # shared release checks
flutter analyze && flutter test test/
flutter run
```

Flutter 3.47.9 (3.50 deprecates `material.dart` and fails analyze).

Pushing to `main` builds a signed APK and a Play bundle and publishes them as
a GitHub Release (`.github/workflows/android-apk.yml`). It needs the
repository secrets `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD`,
the same keystore as the other Zero-Trust apps. Pull requests target `Dev`;
releases are one `Dev` → `main` pull request.

Play Store text and graphics: `fastlane/metadata/android/` (English and
Hebrew).

## License

AGPL-3.0. See [LICENSE](LICENSE).
