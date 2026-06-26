/* ============================================================
   build-config.js
   Runs on Vercel at deploy time (vercel.json buildCommand).
   It writes the PUBLIC Supabase URL + anon key from the project's
   Environment Variables into scripts/supabase-config.js, replacing
   the __PLACEHOLDER__ tokens.

   Required Vercel Environment Variables:
     VITE_SUPABASE_URL
     VITE_SUPABASE_ANON_KEY

   Only the public anon key is used here. Never reference the
   service-role key in this file or anywhere in the frontend.
   ============================================================ */
const fs = require("fs");
const path = require("path");

const url = process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL || "";
const anon = process.env.VITE_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY || "";

if (!url || !anon) {
  console.warn("\n[build-config] WARNING: Supabase env vars are not set.");
  console.warn("[build-config] Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in Vercel.\n");
}

const target = path.join(__dirname, "scripts", "supabase-config.js");
const contents =
`/* Generated at build time from Vercel Environment Variables. Do not edit. */
window.SUPABASE_CONFIG = {
  url: ${JSON.stringify(url)},
  anonKey: ${JSON.stringify(anon)}
};
`;

fs.writeFileSync(target, contents, "utf8");
console.log("[build-config] Wrote scripts/supabase-config.js");
