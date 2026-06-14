// LP・サポート・プライバシー共通のブランド配色（アプリのダーク×ウォームラグジュアリーと一致）。
export const tokens = `
  :root{
    --bg:#16120f; --bg2:#1f1916; --ink:#f0e9e0; --sub:#9c9289;
    --red:#ca4636; --gold:#d6b060; --line:rgba(240,233,224,.12);
  }
  *{box-sizing:border-box;margin:0;padding:0}
  html{scroll-behavior:smooth}
  body{background:var(--bg);color:var(--ink);
    font-family:-apple-system,BlinkMacSystemFont,"Hiragino Sans","Noto Sans JP",sans-serif;
    line-height:1.7;-webkit-font-smoothing:antialiased}
  a{color:inherit}
  .mark{width:30px;height:30px;border-radius:8px;background:var(--red);
    display:grid;place-items:center;color:#fff;font-weight:800;font-size:18px;overflow:hidden}
  .mark img{width:100%;height:100%;object-fit:cover}
`;

// トップLP専用。
export const lpCSS = `
  .wrap{max-width:1040px;margin:0 auto;padding:0 24px}
  nav{display:flex;align-items:center;justify-content:space-between;padding:22px 0}
  .brand{display:flex;align-items:center;gap:11px;font-weight:700;letter-spacing:.02em;font-size:20px}
  nav .links a{color:var(--sub);text-decoration:none;margin-left:22px;font-size:14px}
  nav .links a:hover{color:var(--ink)}
  .hero{padding:64px 0 40px;text-align:center;
    background:radial-gradient(900px 460px at 50% -8%, rgba(202,70,54,.20), transparent 70%)}
  .hero h1{font-size:clamp(34px,6vw,58px);font-weight:800;letter-spacing:.01em;line-height:1.25}
  .hero h1 .em{color:var(--gold)}
  .hero p{color:var(--sub);font-size:clamp(15px,2.4vw,19px);margin:22px auto 0;max-width:620px}
  .badge{display:inline-block;margin-top:30px;padding:13px 26px;border-radius:999px;
    background:var(--red);color:#fff;font-weight:700;text-decoration:none;font-size:15px}
  .badge small{display:block;font-weight:500;opacity:.85;font-size:11px}
  .heroimg{margin:48px auto 0;max-width:920px}
  .heroimg img{width:100%;border-radius:18px;border:1px solid var(--line)}
  section{padding:56px 0;border-top:1px solid var(--line)}
  .eyebrow{color:var(--red);font-size:12px;letter-spacing:.22em;font-weight:700;text-transform:uppercase}
  h2{font-size:clamp(24px,4vw,34px);font-weight:800;margin:10px 0 6px;line-height:1.3}
  .lead{color:var(--sub);max-width:640px}
  .grid{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;margin-top:36px}
  .card{background:var(--bg2);border:1px solid var(--line);border-radius:16px;padding:24px}
  .card h3{font-size:18px;margin-bottom:8px}
  .card p{color:var(--sub);font-size:14px}
  .card .n{color:var(--gold);font-weight:800;font-size:13px;letter-spacing:.1em}
  .split{display:grid;grid-template-columns:1fr 1fr;gap:40px;align-items:center;margin-top:34px}
  .split img{width:100%;border-radius:16px;border:1px solid var(--line)}
  .privacy{background:linear-gradient(180deg,var(--bg2),var(--bg));text-align:center}
  .privacy h2{max-width:680px;margin-inline:auto}
  .privacy ul{list-style:none;display:flex;flex-wrap:wrap;gap:12px;justify-content:center;margin-top:26px}
  .privacy li{border:1px solid var(--line);border-radius:999px;padding:9px 18px;color:var(--sub);font-size:14px}
  footer{border-top:1px solid var(--line);padding:40px 0 64px;color:var(--sub);font-size:13px}
  footer .row{display:flex;flex-wrap:wrap;gap:18px;justify-content:space-between;align-items:center}
  footer a{color:var(--sub);text-decoration:none;margin-right:18px}
  footer a:hover{color:var(--ink)}
  @media(max-width:720px){.grid,.split{grid-template-columns:1fr}}
`;

// プライバシー・サポートの文書ページ共通。
export const docCSS = `
  .wrap{max-width:760px;margin:0 auto;padding:0 24px}
  nav{display:flex;align-items:center;gap:11px;padding:22px 0;font-weight:700}
  nav a{color:inherit;text-decoration:none;display:flex;align-items:center;gap:11px}
  header{padding:24px 0 8px;border-bottom:1px solid var(--line)}
  h1{font-size:30px;font-weight:800}
  .upd{color:var(--sub);font-size:13px;margin-top:8px}
  .lead{color:var(--sub);margin-top:14px}
  h2{font-size:19px;font-weight:700;margin:32px 0 8px;color:var(--ink)}
  p,li{color:#d8cfc6;font-size:15px}
  ul{margin:8px 0 8px 22px}
  a{color:var(--red)}
  details{background:var(--bg2);border:1px solid var(--line);border-radius:12px;padding:4px 18px;margin:12px 0}
  summary{cursor:pointer;font-weight:600;padding:14px 0;list-style:none}
  summary::-webkit-details-marker{display:none}
  summary::before{content:"＋";color:var(--red);margin-right:10px;font-weight:800}
  details[open] summary::before{content:"−"}
  details p{padding-bottom:14px}
  .contact{background:var(--bg2);border:1px solid var(--line);border-radius:16px;padding:24px;margin-top:30px}
  .btn{display:inline-block;margin-top:12px;padding:11px 22px;border-radius:999px;background:var(--red);color:#fff;text-decoration:none;font-weight:700}
  footer{border-top:1px solid var(--line);margin-top:48px;padding:28px 0 60px;color:var(--sub);font-size:13px}
  footer a{color:var(--sub)}
`;
