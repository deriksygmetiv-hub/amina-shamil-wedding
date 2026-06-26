/* ============================================================
   Supabase public configuration
   ------------------------------------------------------------
   Only the PUBLIC project URL and the PUBLIC anon key belong here.
   Never put the service-role key in this file or anywhere in the
   frontend — it must stay server-side only.

   HOW THE VALUES GET HERE ON VERCEL
   ---------------------------------
   This file ships with __PLACEHOLDER__ tokens. The repo's build step
   (see package.json "build" script) replaces them with the values of
   your Vercel Environment Variables at deploy time:

       VITE_SUPABASE_URL       -> window.SUPABASE_CONFIG.url
       VITE_SUPABASE_ANON_KEY  -> window.SUPABASE_CONFIG.anonKey

   For quick local testing you can paste the values in directly,
   but do NOT commit real keys to a public repository.
   ============================================================ */
window.SUPABASE_CONFIG = {
  url: "__VITE_SUPABASE_URL__",
  anonKey: "__VITE_SUPABASE_ANON_KEY__"
};
