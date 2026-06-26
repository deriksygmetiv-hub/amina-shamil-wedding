# Amina &amp; Mohammed Shamil — Nikah Invitation (Supabase + Vercel)

The public invitation is unchanged in look and feel. What changed is the
**backend**: RSVPs, guest photos, and settings now live in **Supabase** instead
of the browser, and there is a separate **secure admin dashboard at `/admin`**.

```
/
├── index.html                  Public invitation (design preserved)
├── admin/
│   └── index.html              Secure admin dashboard (Supabase Auth)
├── scripts/
│   └── supabase-config.js      Public URL + anon key (generated at build time)
├── supabase/
│   └── schema.sql              Tables, RLS policies, storage bucket, settings
├── build-config.js             Injects env vars into supabase-config.js on Vercel
├── vercel.json                 Routing (/admin) + build command
├── package.json
└── .gitignore
```

The public site and the admin dashboard use the **same Supabase project**.

---

## 1. Create the Supabase project

1. Go to <https://supabase.com> → **New project**. Pick a name and a strong
   database password and wait for it to provision.
2. Open **Project Settings → API** and copy:
   - **Project URL** → this is your `VITE_SUPABASE_URL`
   - **anon public** key → this is your `VITE_SUPABASE_ANON_KEY`
   - Leave the **service_role** key alone. It must **never** appear in the
     frontend, this repo, or any committed file.

## 2. Create the database, policies, storage, and settings

1. In Supabase, open **SQL Editor → New query**.
2. Paste the entire contents of [`supabase/schema.sql`](supabase/schema.sql) and
   **Run**. This creates:
   - `rsvps` table (with a trigger that forces adults/children to 0 and requires
     a message when `attendance_status = 'no'`).
   - `guest_photos` table (defaults new photos to `pending`).
   - `website_settings` table (seeded with sensible defaults).
   - **Row-Level Security** policies (see the security summary below).
   - The **`wedding-memories`** storage bucket and its access policies.
   - Realtime enabled on `guest_photos` so the public gallery updates instantly
     when you approve a photo.

## 3. Create the admin account

Admins are simply authenticated Supabase users — the RLS policies grant every
authenticated user admin rights, so **keep public sign-ups closed** and only
create accounts you trust.

1. **Authentication → Providers → Email**: turn **off** "Allow new users to sign
   up" (so only you can create admins).
2. **Authentication → Users → Add user**: enter the couple's/admin email and a
   strong password. (Tick "Auto-confirm" so they can log in immediately.)

The old hard-coded password `ami8511` is **gone** — it no longer exists anywhere
in the code.

## 4. Local preview (optional)

For a quick local test you can temporarily paste your URL and anon key into
`scripts/supabase-config.js`, then serve the folder:

```bash
npx serve .
# open http://localhost:3000  and  http://localhost:3000/admin
```

Don't commit real keys. The `.gitignore` already excludes
`scripts/supabase-config.js`.

## 5. Deploy on Vercel

1. Push this folder to a Git repo and **Import** it in Vercel (or run
   `vercel` from the CLI). It's a static site — no framework preset needed.
2. In **Vercel → Project → Settings → Environment Variables**, add:

   | Name | Value |
   |------|-------|
   | `VITE_SUPABASE_URL` | your Supabase Project URL |
   | `VITE_SUPABASE_ANON_KEY` | your Supabase anon public key |

3. Deploy. On every build, `build-config.js` writes those values into
   `scripts/supabase-config.js`, so **no secrets are committed** to the repo.
4. Routes:
   - `/` → public invitation
   - `/admin` → secure dashboard (rewritten to `/admin/index.html`)

Your existing public invitation URL keeps working.

---

## What the admin dashboard does

- **Overview** — live cards: total responses, attending, declined, adults,
  children, total guests (= adults + children), pending photos, approved photos.
  All values come straight from Supabase; nothing is hard-coded.
- **RSVPs** — full name, mobile, status, adults, children, total guests, message,
  submission date/time. Search by name or mobile, filter attending/declined,
  sort newest/oldest, edit, delete, and export **all / attending / declined** to
  CSV. On phones the list switches from a wide table to cards.
- **Photos** — Pending / Approved / Rejected tabs. Each card shows the image,
  guest name, caption, upload date/time, and status, with Approve, Reject,
  Feature/Unfeature, Edit (name + caption), Download original, and Delete.
  Deleting removes **both** the database row and the storage file.
- **Settings** — toggles for RSVP form, photo uploads, gallery, automatic photo
  approval, music, and a max-images-per-submission number. These write to
  `website_settings`; the public site reads them on load.
- **Logout** and **Forgot password** use Supabase Auth.

When you **approve** a photo it appears in the public "Our Nikah Memories"
gallery immediately via Supabase realtime — no redeploy. **Rejected** photos stay
hidden. The public gallery only ever reads `approval_status = 'approved'`,
featured first, then newest.

---

## Security summary (Row-Level Security)

**Public visitors (anon) may:** insert an RSVP; upload a photo file into
`guest-uploads/`; insert a `guest_photos` row; read **approved** photos only;
read website settings.

**Public visitors may NOT:** read, edit, or delete any RSVP; read pending or
rejected photos; approve/reject/delete photos; change settings.

**Authenticated admins may:** read/edit/delete all RSVPs; read all photos;
approve/reject/delete photos; delete storage files; change settings; export data.

The service-role key is never used in the frontend.

---

## Final testing checklist

Test with at least two separate devices (e.g. a phone and a laptop).

1. Submit a **Yes** RSVP from one phone.
2. Confirm it appears in the admin dashboard on another device (realtime, or
   refresh).
3. Confirm adult and child totals update on the Overview cards.
4. Submit a **No** RSVP — confirm the message/reason is mandatory.
5. Confirm declined totals update.
6. Upload multiple guest photographs.
7. Confirm they appear under **Pending**.
8. Approve one — confirm it appears in the public memories gallery (no redeploy).
9. Reject one — confirm it stays hidden from the public gallery.
10. Delete one — confirm both the database row and the storage file are gone
    (check **Storage → wedding-memories** in Supabase).
11. Export RSVP data to CSV (all / attending / declined).
12. Confirm admin **login** and **logout** work.
13. Open `/admin` while logged out — confirm no RSVP or photo data is visible.
14. Confirm all public invitation features still work (cover, countdown,
    calendar dropdown, venue, schedule, WhatsApp share, music, footer).
15. Confirm the site remains fully responsive on mobile.

---

## Event details (unchanged)

- **Bride:** Amina A.M.
- **Groom:** Mohammed Shamil Saeed
- **Groom's location:** Vythiri, Wayanad
- **Date:** 18 July 2026 (Saturday) · **Hijri:** 1448 Safar 4
- **Nikah:** 11:00 AM · **Event:** 11:00 AM to 3:00 PM
- **Venue:** Saleena Palace, Pokkunnu, Calicut
- **Admin route:** `/admin`

## Adding background music (optional)

Host an MP3 (e.g. in the `wedding-memories` bucket or any CDN) and set its URL in
`index.html` at `CONFIG.musicUrl`. The music toggle in admin Settings controls
whether it plays.
