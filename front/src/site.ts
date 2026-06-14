import { html, raw } from "hono/html";
import { tokens, lpCSS, docCSS } from "./styles";

const SITE = "https://tone.basaapp.com";
const MAIL = "bassa.application@gmail.com";

const head = (title: string, css: string, desc?: string) => html`
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <link rel="icon" href="/icon.png" />
  ${desc ? html`<meta name="description" content="${desc}" />` : ""}
  <style>
    ${raw(tokens)}${raw(css)}
  </style>
`;

const brand = html`<span class="mark"><img src="/icon.png" alt="Tone" /></span>`;

// トップLP
export const homePage = () => html`<!doctype html>
<html lang="ja">
<head>
  ${head(
    "Tone — 気づかれないメンズメイク",
    lpCSS,
    "顔を撮るだけで100点満点で診断。骨格や目鼻の比率から、光と影で整えるメンズメイクを5ステップで。写真も診断も端末内で完結。"
  )}
  <meta property="og:title" content="Tone — 気づかれないメンズメイク" />
  <meta property="og:description" content="顔を撮るだけで診断し、光と影で整える。気づかれない自然な仕上がりを、理屈から。" />
  <meta property="og:image" content="${SITE}/hero.png" />
  <meta property="og:type" content="website" />
</head>
<body>
  <div class="wrap">
    <nav>
      <div class="brand">${brand} Tone</div>
      <div class="links">
        <a href="#features">特徴</a>
        <a href="/support">サポート</a>
        <a href="/privacy">プライバシー</a>
      </div>
    </nav>
  </div>

  <header class="hero">
    <div class="wrap">
      <h1>気づかれない、<br /><span class="em">メンズメイク。</span></h1>
      <p>目指すのは、調子のいい日の自分。顔を撮るだけで診断し、光と影でどこをどう整えるかを教えてくれる。盛らずに、ほんの少し整えるだけ。</p>
      <a class="badge" href="#">App Store で入手<small>iOS 26 以上の iPhone</small></a>
      <div class="heroimg"><img src="/hero.png" alt="Tone のストアイメージ" /></div>
    </div>
  </header>

  <section id="features">
    <div class="wrap">
      <div class="eyebrow">Features</div>
      <h2>素の顔を、理屈で整える。</h2>
      <p class="lead">メイクには、ちゃんと理屈がある。Tone は「結局、光と影」という原則だけで、続けられる形に落とし込みました。</p>
      <div class="grid">
        <div class="card"><div class="n">01 — 診断</div><h3>顔を100点満点で診断</h3><p>骨格バランス・三分割比率・目や鼻の比率まで、7つの指標を自動解析。顔タイプに効く技と、控えるべき技を提示します。</p></div>
        <div class="card"><div class="n">02 — シミュレーション</div><h3>光と影で、Before / After</h3><p>診断をもとに仕上がりをその場でシミュレーション。プリセット比較やカラー調整で、自分に合う加減を探せます。</p></div>
        <div class="card"><div class="n">03 — ガイド</div><h3>手順は、5ステップだけ</h3><p>道具は3つまで。各ステップに理屈と強さスライダー。やりすぎない加減を、自分の顔で覚えられます。</p></div>
        <div class="card"><div class="n">04 — 記録</div><h3>続けるほど、軌跡が残る</h3><p>保存したルックのスコア推移で変化を見返せる。最新・ベスト・平均で続けた手応えを確認できます。</p></div>
      </div>
      <div class="split">
        <img src="/shot_diagnosis.png" alt="診断結果画面" />
        <div>
          <div class="eyebrow">Diagnosis</div>
          <h2>なぜ整うか、<br />数値で示す。</h2>
          <p class="lead">「いちばんの強み」と「伸びしろ」が、A〜B の評価とともにひと目でわかる詳細レポート。感覚ではなく、根拠から納得して進められます。</p>
        </div>
      </div>
    </div>
  </section>

  <section class="privacy">
    <div class="wrap">
      <div class="eyebrow">Privacy</div>
      <h2>全部、この端末の中で。</h2>
      <p class="lead" style="margin-inline:auto">写真も診断も、外に出しません。顔の解析はすべてオンデバイス。アカウント登録もいりません。</p>
      <ul>
        <li>外部サーバー送信なし</li>
        <li>オンデバイス解析</li>
        <li>アカウント不要</li>
        <li>広告・トラッキングなし</li>
      </ul>
    </div>
  </section>

  <footer>
    <div class="wrap row">
      <div class="brand">${brand} Tone</div>
      <div>
        <a href="#features">特徴</a>
        <a href="/support">サポート</a>
        <a href="/privacy">プライバシーポリシー</a>
        <a href="mailto:${MAIL}">お問い合わせ</a>
      </div>
      <div>© 2026 tubasasakunn</div>
    </div>
  </footer>
</body>
</html>`;

// プライバシーポリシー
export const privacyPage = () => html`<!doctype html>
<html lang="ja">
<head>${head("プライバシーポリシー — Tone", docCSS)}</head>
<body>
  <div class="wrap">
    <nav><a href="/">${brand} Tone</a></nav>
    <header>
      <h1>プライバシーポリシー</h1>
      <div class="upd">最終更新日：2026年6月14日</div>
    </header>

    <p class="lead">Tone（以下「本アプリ」）は、ユーザーのプライバシーを最優先に設計されています。本ポリシーは、本アプリが扱う情報とその取り扱いについて説明します。</p>

    <h2>1. 収集する情報</h2>
    <p>本アプリは、ユーザーの個人情報を外部に収集・送信しません。具体的には次のとおりです。</p>
    <ul>
      <li><strong>顔写真</strong>：撮影・選択した写真は、診断とメイクシミュレーションのためにのみ使用し、ユーザーの端末内にのみ保存されます。</li>
      <li><strong>診断結果・保存したルック</strong>：スコアや顔タイプ、保存データは端末内（ローカルストレージ）に保存されます。</li>
      <li>アカウント登録は不要で、氏名・メールアドレス・電話番号などを取得しません。</li>
    </ul>

    <h2>2. 情報の処理場所</h2>
    <p>顔の解析（顔のランドマーク検出・比率の算出など）は、すべてユーザーの端末上（オンデバイス）で行われます。写真や解析結果が外部サーバーやクラウドへ送信されることはありません。</p>

    <h2>3. 第三者への提供・トラッキング</h2>
    <ul>
      <li>本アプリは、第三者に情報を販売・提供しません。</li>
      <li>広告 SDK、アナリティクス SDK、トラッキング技術を使用しません。</li>
      <li>App Tracking Transparency（ATT）の対象となるトラッキングは行いません。</li>
    </ul>

    <h2>4. データの保存と削除</h2>
    <p>本アプリ内のデータは端末内にのみ保存されます。本アプリをアンインストールすると、保存されたデータは端末から削除されます。アプリ内で個別のデータ（保存したルック等）を削除することもできます。</p>

    <h2>5. お子様のプライバシー</h2>
    <p>本アプリは13歳未満の子どもを対象としていません。子どもから意図的に情報を収集することはありません。</p>

    <h2>6. 本ポリシーの変更</h2>
    <p>必要に応じて本ポリシーを更新することがあります。重要な変更がある場合は、本ページの最終更新日を改訂して掲載します。</p>

    <h2>7. お問い合わせ</h2>
    <p>本ポリシーまたはプライバシーに関するお問い合わせは、<a href="mailto:${MAIL}">${MAIL}</a> までご連絡ください。</p>

    <footer>© 2026 tubasasakunn ・ <a href="/">トップへ戻る</a> ・ <a href="/support">サポート</a></footer>
  </div>
</body>
</html>`;

// サポート
export const supportPage = () => html`<!doctype html>
<html lang="ja">
<head>${head("サポート — Tone", docCSS)}</head>
<body>
  <div class="wrap">
    <nav><a href="/">${brand} Tone</a></nav>
    <header>
      <h1>サポート</h1>
      <p class="lead">Tone のご利用でお困りのことがあれば、よくある質問をご確認いただくか、下のメールからお問い合わせください。</p>
    </header>

    <h2>よくある質問</h2>

    <details><summary>写真はどこに保存されますか？外部に送られますか？</summary>
      <p>撮影・選択した写真と診断結果は、すべてお使いの iPhone の中にのみ保存されます。外部サーバーやクラウドへ送信されることはありません。顔の解析も端末内で完結します。</p></details>

    <details><summary>診断はどのように行われますか？</summary>
      <p>顔のランドマーク（目・鼻・輪郭など）を検出し、骨格バランスや三分割・五分割の比率など7つの指標を算出して、100点満点でスコア化します。あわせて顔タイプを判定し、効く技・控える技を提案します。</p></details>

    <details><summary>診断結果やスコアは、医学的・専門的な評価ですか？</summary>
      <p>いいえ。Tone の診断は、メイクで整える箇所を見つけるための目安です。医学的・美容医療的な診断ではありません。</p></details>

    <details><summary>メイクは初めてですが、使えますか？</summary>
      <p>はい。道具は3つまで、手順は5ステップに絞っています。各ステップに理屈の解説と強さスライダーがあり、やりすぎない加減を自分の顔で確認しながら進められます。</p></details>

    <details><summary>保存したデータを消したいです。</summary>
      <p>アプリ内の保存画面から、保存したルックを個別に削除できます。すべてのデータを消したい場合は、本アプリをアンインストールすると端末から削除されます。</p></details>

    <details><summary>動作に必要な環境は？</summary>
      <p>iOS 26 以上の iPhone が必要です。iPad には最適化されていません。</p></details>

    <div class="contact">
      <h2 style="margin-top:0">解決しないときは</h2>
      <p>不具合のご報告・ご要望・その他のお問い合わせは、メールで受け付けています。ご利用の機種と iOS のバージョンを添えていただけると、よりスムーズに対応できます。</p>
      <a class="btn" href="mailto:${MAIL}?subject=Tone%20サポート">お問い合わせ</a>
    </div>

    <footer>© 2026 tubasasakunn ・ <a href="/">トップへ戻る</a> ・ <a href="/privacy">プライバシーポリシー</a></footer>
  </div>
</body>
</html>`;
