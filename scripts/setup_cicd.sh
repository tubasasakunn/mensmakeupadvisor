#!/usr/bin/env bash
# CI/CD 初回セットアップスクリプト
# このスクリプトはローカルの Mac で 1 度だけ実行する
set -euo pipefail

echo "=== MensMakeupAdvisor CI/CD セットアップ ==="

# ── 1. Bundler でライブラリをインストール ──────────────
echo "[1/5] Installing gems..."
bundle install --path vendor/bundle

# ── 2. GitHub Actions self-hosted runner を登録 ─────────
echo ""
echo "[2/5] GitHub Actions self-hosted runner の登録:"
echo "  1. https://github.com/tubasasakunn/mensmakeupadvisor/settings/actions/runners"
echo "  2. [New self-hosted runner] → macOS → 表示されるコマンドを実行"
echo "  3. ラベルに 'macOS' と 'iOS-26' を追加"
echo ""
read -rp "  runner の登録が完了したら Enter を押してください..."

# ── 3. App Store Connect API Key を確認 ─────────────────
echo ""
echo "[3/5] App Store Connect API Key:"
echo "  1. https://appstoreconnect.apple.com/access/integrations/api"
echo "  2. [+] で新規キーを作成 (権限: Developer)"
echo "  3. .p8 をダウンロードして以下を実行:"
echo ""
echo "     KEY_ID=<Key ID>"
echo "     ISSUER_ID=<Issuer ID>"
echo "     ASC_KEY_B64=\$(base64 -i ~/Downloads/AuthKey_\${KEY_ID}.p8)"
echo ""
echo "  4. GitHub Secrets に登録:"
echo "     ASC_KEY_ID       = \$KEY_ID"
echo "     ASC_ISSUER_ID    = \$ISSUER_ID"
echo "     ASC_KEY_CONTENT  = \$ASC_KEY_B64"
echo ""
read -rp "  API Key の設定が完了したら Enter を押してください..."

# ── 4. Fastlane Match 用プライベートリポジトリを作成 ─────
echo ""
echo "[4/5] Match 用の証明書リポジトリを作成:"
echo "  1. GitHub で新規プライベートリポジトリを作成"
echo "     例: https://github.com/tubasasakunn/ios-certs"
echo "  2. GitHub Personal Access Token (repo scope) を作成:"
echo "     https://github.com/settings/tokens/new"
echo "  3. GitHub Secrets に登録:"
echo ""
echo "     MATCH_GIT_URL       = https://github.com/tubasasakunn/ios-certs.git"
echo "     MATCH_GIT_BASIC_AUTH = \$(echo -n 'tubasasakunn:<PAT>' | base64)"
echo "     MATCH_PASSWORD      = <任意のパスフレーズ>"
echo ""
read -rp "  リポジトリとSecrets の設定が完了したら Enter を押してください..."

# ── 5. Match で証明書を初期化 ────────────────────────────
echo ""
echo "[5/5] Match で証明書を生成・暗号化してリポジトリにプッシュ:"
echo "  以下のコマンドを実行してください:"
echo ""
echo "  export MATCH_GIT_URL=https://github.com/tubasasakunn/ios-certs.git"
echo "  export MATCH_PASSWORD=<設定したパスフレーズ>"
echo "  bundle exec fastlane setup_match"
echo ""
echo "  ※ Apple ID と 2FA コードが求められます"
echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "以降のデプロイ方法:"
echo "  TestFlight : git tag v1.0.1 && git push origin v1.0.1"
echo "  手動実行   : GitHub Actions > Deploy > Run workflow"
