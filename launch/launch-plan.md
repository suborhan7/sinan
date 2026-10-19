# Launch Plan: Steam + Google Play

Working assumptions: the game is built in **Godot 4**, ships first on **Steam (PC)**, then on **Google Play (Android)**. Fees and policy numbers below were correct as of mid‑2026; re-check the linked pages before paying anything, because Valve and Google change them.

---

## 1. Accounts and fees

| Platform | Account | Cost | Notes |
|---|---|---|---|
| Steam | Steamworks partner account (partner.steamgames.com) | **$100 per game** (Steam Direct fee) | Refunded to you once the game earns $1,000 gross. You must wait 30 days after paying before you can release. |
| Google Play | Play Console developer account (play.google.com/console) | **$25 one‑time** | Covers unlimited apps. Personal accounts need ID verification; organisation accounts need a D‑U‑N‑S number (free, takes 1–4 weeks). |
| Optional | Company / LLC | Varies by country | Keeps your personal name off store pages and simplifies taxes. Not required to start. |

**Revenue share**
- Steam: Valve keeps 30% (drops to 25% after $10M and 20% after $50M per game).
- Google Play: Google keeps **15% on your first $1M/year**, 30% after that.

**Recommendation:** open the Play account as an individual unless you already have a company, since organisation accounts wait on D‑U‑N‑S. Be aware that **new personal Play accounts must run a closed test with at least 12 testers for 14 continuous days** before they can publish to production. Start recruiting testers early (friends, a Discord).

---

## 2. Technical requirements

### Steam (PC)
- Export Windows (x86_64) from Godot. Linux and macOS are optional; Linux also gets you Steam Deck support.
- Integrate the Steamworks SDK through **GodotSteam** (free plugin) for achievements, cloud saves, overlay and stats.
- Upload builds with **SteamPipe** (the `steamcmd` tool). Set up a default branch and a private `beta` branch.
- Steam Deck: test at 1280×800, full controller support, readable text. "Deck Verified" is a big visibility boost for this genre.
- Steam Cloud: point it at the save folder so players' worlds sync between machines.

### Google Play (Android)
- Export an **Android App Bundle (.aab)**, not an APK. Godot 4 supports this with the Gradle build template.
- **Target API level:** Play requires targeting a recent Android version (API 35 as of 2025, rising every August). Use the newest Godot 4.x stable release, which tracks this.
- Sign with **Play App Signing**. Keep your upload keystore and its passwords backed up in two places; losing it is painful.
- 64‑bit (arm64‑v8a) builds are required.
- Purchases go through **Google Play Billing** (use the official Godot Play Billing plugin). You cannot take payment any other way for in‑game content.
- Touch controls are a real design task for a mining/building game: virtual stick, tap‑to‑mine, a radial hotbar, and auto‑aim for combat. Budget time for this; it is the biggest risk for the mobile version.
- Performance target: 60 fps on a mid‑range phone (e.g. a 3–4 year old Android). Use chunked world rendering and keep lighting cheap.

### Both
- **Privacy policy URL** (required by Play, needed on Steam if you collect any data). A simple hosted page is fine.
- Save‑file versioning from day one, so later updates never break old worlds. This matters because the game is meant to be upgraded over time.
- Crash reporting (e.g. Sentry, which has a Godot SDK) so you hear about problems before reviews do.

---

## 3. Store page assets

### Steam (all required unless marked)
| Asset | Size (px) |
|---|---|
| Header capsule | 920 × 430 |
| Small capsule | 462 × 174 |
| Main capsule | 1232 × 706 |
| Vertical capsule | 748 × 896 |
| Library capsule | 600 × 900 |
| Library header | 920 × 430 |
| Library hero | 3840 × 1240 |
| Library logo | 1280 × 720 (transparent PNG) |
| Page background (optional) | 1438 × 810 |
| Screenshots | at least 5, 1920 × 1080 |
| Trailer | 30–90 s, first 5 s must show gameplay |

Plus: short description (≤300 chars), long description with GIFs, tags (pick "Sandbox", "Survival", "Crafting", "2D", "Pixel Graphics", "Building", "Exploration", "Procedural Generation", plus whatever makes your unique idea searchable), content survey for age ratings, and system requirements.

### Google Play
| Asset | Size |
|---|---|
| App icon | 512 × 512 PNG |
| Feature graphic | 1024 × 500 |
| Phone screenshots | 2–8, 16:9 or 9:16, min 320 px side |
| Tablet screenshots | recommended (7" and 10") |
| Promo video | optional YouTube link |

Plus: short description (≤80 chars), full description (≤4000 chars), **content rating questionnaire (IARC)**, **Data safety form**, target audience declaration, and ads declaration.

**Tip:** design the capsule art and logo once, early, at the largest size; every other asset is a crop of it. The capsule is the single most important marketing image on Steam because it is what people see in lists.

---

## 4. Pricing and monetization

### Steam: premium, one‑time purchase (recommended)
- Genre peers sell at **$9.99–$19.99**. Recommendation: **Early Access at $9.99–$12.99**, raise to $14.99–$19.99 at 1.0.
- Launch with a 10–20% launch discount.
- Free updates keep the community happy; later, paid **expansion DLC** (a new biome set, a new dimension) fits "upgradable later on".
- Free **demo** before launch, especially for **Steam Next Fest**, which is the biggest free visibility event for indies.
- Avoid microtransactions on PC; this audience punishes them in reviews.

### Google Play: three options

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **A. Free + one‑time unlock** (recommended) | Free to download, first world/biome free, one purchase ($4.99–$7.99) unlocks the full game | Low barrier, fair, matches the PC model | Needs a natural cut‑off point in progression |
| B. Paid upfront | $4.99–$7.99 to download | Simplest | Far fewer downloads on mobile |
| C. Free with ads + cosmetics | Rewarded ads, cosmetic IAP | Most installs | Hurts reputation, more dev work, ads require extra policy forms |

Recommendation: **Option A on Play, premium on Steam.** Keep cosmetics only (skins, house decorations) as an optional extra later, never pay‑to‑win.

### Regional pricing
Use Steam's and Play's suggested regional prices rather than one flat price; they are tuned for each market.

---

## 5. Timeline

Assumes one developer working steadily. Adjust once the prototype thread shows real pace.

| Phase | When | What happens |
|---|---|---|
| **0. Prototype** | Months 0–3 | Core loop playable: dig, build, craft, fight, day/night, your unique hook. |
| **1. Accounts & store page** | Month 2–3 | Pay Steam fee, open Play account, start D‑U‑N‑S if organisation. Put up a **Steam "Coming Soon" page early** to collect wishlists (wishlists drive launch visibility). |
| **2. Vertical slice + demo** | Months 3–6 | One polished biome, first boss, trailer, demo build. Start a Discord, devlogs on YouTube/TikTok/Reddit. |
| **3. Steam Next Fest** | Next fest after demo is ready (held Feb, Jun, Oct) | Register in Steamworks about 2 months ahead. |
| **4. Steam Early Access** | Months 6–9 | Store page and build each go through Valve review (budget ~1 week each). Page must be "Coming Soon" for at least 2 weeks. |
| **5. Android port** | Months 8–12 | Touch controls, performance pass, billing. Start the **14‑day / 12‑tester closed test** as soon as a playable build exists. |
| **6. Google Play launch** | Month ~12 | Open testing first, then production. Review usually takes a few days. |
| **7. Steam 1.0** | When content is complete | Price increase, big update, second marketing beat. |
| **Ongoing** | After launch | Regular content updates, seasonal events, DLC, cross‑save between PC and mobile if demand exists. |

---

## 6. Steps only you can do

These need your identity, money or signature, so Claude cannot do them for you.

1. **Pick the game's final name** and check it is free on Steam, Play and as a domain/social handle.
2. **Create a Steamworks account**, complete the **tax interview** and **bank details**, verify identity, and **pay the $100 fee**.
3. **Create a Google Play Console account**, pay **$25**, and complete **identity verification** (or get a **D‑U‑N‑S number** for a company).
4. **Recruit at least 12 closed testers** for the Play 14‑day test.
5. **Host a privacy policy** page (Claude can write the text; you publish it on a site you control).
6. **Create and safely back up the Android upload keystore.**
7. Fill in the **content rating questionnaires** and **Data safety form** truthfully (Claude can draft answers).
8. **Approve final store page text, art and price**, and press **Release** on both stores.
9. Decide whether to form a **company** and talk to a local accountant about **taxes** on sales income.

---

## 7. What Claude can do next

- Write store descriptions, tags and the privacy policy text.
- Set up GodotSteam, Play Billing, and export presets in the prototype repo.
- Build a trailer shot list and a capsule art brief.
- Draft the content rating and Data safety answers.
- Set up a build pipeline that produces the Steam build and the Android .aab automatically.
