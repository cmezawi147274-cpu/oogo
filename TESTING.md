# Testing Oogo on your iPhone (from Windows)

Every push to `main` makes GitHub build the app on one of its Macs. About 15 minutes later
an installable file is ready. Sideloadly puts it on your iPhone using your normal Apple ID.

## One-time setup

1. Install **iTunes** from apple.com/itunes (the download from Apple, not the Microsoft Store
   version). Sideloadly needs its iPhone drivers.
2. Install **Sideloadly** from sideloadly.io.
3. Plug the iPhone into the PC with a cable. Tap **Trust** on the phone.

## After each change

1. Open the repository on GitHub, then **Actions**, then the newest **iOS** run.
2. When it shows a green tick, scroll to **Artifacts** and download **oogo-ipa**.
   Unzip it to get `Oogo-xxxxxxx-unsigned.ipa`.
3. Open Sideloadly, drag the `.ipa` in, type your Apple ID, press **Start**.
4. First time only, on the iPhone:
   - Settings, General, VPN & Device Management: tap your Apple ID, then **Trust**.
   - Settings, Privacy & Security, **Developer Mode**: turn on, restart, confirm.
5. Open Oogo.

## Limits of a free Apple ID

- The app stops opening after 7 days. Install it again with Sideloadly to refresh.
- At most 3 sideloaded apps on the phone at once.
- Sign-in and cloud sync are off in these builds unless the Rork/Supabase settings are added as
  repository secrets (see `.github/workflows/ios.yml`). Onboarding skips the sign-in wall when
  sign-in is not configured, so everything else works offline.

## Checking a build without the phone

Each run also uploads **oog-snapshots**: PNG pictures of every Oog animation and of the
workout screen on two iPhone sizes.
