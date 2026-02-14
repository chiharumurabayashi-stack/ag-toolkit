# Antigravity Distribution Kit (v1.1.0)
**Last Verified: 2026-02-14**

このフォルダーは、Antigravity 環境を「箱出し状態の Windows PC」からでも数分で完全再現するための、再現性に特化したセットアップ・キットです。v1.1.0 では、プロ仕様の **「自己修復モード (Self-Healing)」** を搭載し、環境のドリフト（変質）や競合を自動で検知・修正できるようになりました。

## 📋 0. 前提条件 (IMPORTANT)
トラブルの 9 割を防ぐため、以下の条件を確認してください。

- **PowerShell 5.1 以上** (Windows 10/11 標準。7.x 推奨)
- **Microsoft Store版 Python の混在禁止** (自動修復対象ですが、事前に避けるのが無難です)
- **管理者権限あり** (一部の修復・インストールに必要)
- **インターネット接続あり**
- **OneDrive 配下での実行禁止** (同期エラーやパスの問題を避けるため)
- **非ASCII文字・空白を含まないパス** 推奨:
  - Google Drive 等の日本語パスを回避するため、`ag_toolkit/fix_virtual_path.ps1` を実行すると **`C:\.ag_work\`** 配下にジャンクション（フォルダリンク）が作成されます。
  - 開発作業は常にこの `C:\.ag_work\project-name` フォルダ内で行ってください。

## 📂 フォルダ構成
- `ag_toolkit/`: 環境構築スクリプト（リサイクル・リファクタリング済み）
- `.agent/`: ポータブルな AI 設計図
  - `skills/`: スキル（`ag_env_diagnostic` 等）
  - `workflows/`: ワークフロー（`setup.md` 等）
- `knowledge/`: **[Option]** AI の記憶（過去の分析結果、ナレッジアイテム）

## 🚀 1. セットアップ手順

### Step A: 配置
新しいプロジェクトフォルダ（例: `C:\Dev\MyProject\`）を作成し、その中に `.agent` と `ag_toolkit` フォルダをそのまま配置します。

### Step B: 実行
管理者権限で PowerShell を開き、以下のコマンドを実行します。
```powershell
# 実行ポリシーを一時的に許可（このセッションのみ有効）
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

cd [Google Drive Physical Path]\ag_toolkit
./ag_quickstart.ps1

# その後、自動生成されたリンクへ移動して作業開始
cd C:\.ag_work\antigravity-runtime
```

> [!NOTE]
> **-Global オプションについて**: 
> システムの Python/Node.js 環境に直接インストールを試みます。既に適切なバージョンが存在する場合は、それを利用して環境を統合します。

## 🛠 2. 自己修復モード (Self-Healing)
もし環境診断でエラーが出た場合、以下のコマンドで安全に修復を試みることができます。

| Level | 内容 | リスク | 備考 |
| :--- | :--- | :--- | :--- |
| **Safe** | 診断・権限調整 | 無 | プロセス内での調整 |
| **Moderate** | 仮想環境・PATH・Alias変更 | 低 | **Snapshot 自動作成** |
| **Aggressive** | パス移動・構成変更 | 中 | ユーザー確認必須 |

```powershell
# まずは修復プランの確認 (DryRun) - 何も変更しません
./auto_fix.ps1 -Mode DryRun

# 修復の実行 (Moderate レベル) - スナップショットが自動作成されます
./auto_fix.ps1 -Mode Execute -Level Moderate

# もし修復で問題が出た場合のロールバック
# ※実行前に、すべての仮想環境・Pythonプロセスを終了してください。
./auto_fix.ps1 -Mode Rollback -RollbackTag Last
```

## 💬 3. 実行結果の目安
実行中、以下のような表示が出れば正常です：
- `[READY] Python detected`
- `[READY] Node detected`
- `[WARN] GPU not configured (Optional)` → GPU無し環境や設定未完了時は正常です。
- `[READY] Venv created / Dependencies installed.`

## 🧠 4. ブラウザ自動化 (Playwright)
本キットは **Playwright** によるブラウザ自動化環境の自動構築に対応しています。
- **インストール**: `ag_quickstart.ps1` 実行時に自動で行われます。
- **バイナリ管理**: Google Drive同期を避けるため、`C:\.ag_browser` ルートに保存されます。
- **検証**: `verify_browser.py` を実行して動作を確認できます。

## 🧠 5. オプション：AIナレッジの引き継ぎ
過去の分析文脈や「記憶」を新しいPCでも利用したい場合のみ、以下の操作を行ってください。
1. `C:\Users\（ユーザー名）\.gemini\antigravity\knowledge\` を探します。
2. 本キットの `knowledge/` フォルダの中身をそこへコピーします。

## 🧯 5. トラブルシューティング
詳細な原因と対策については、[./ag_toolkit/TROUBLESHOOTING.md](./ag_toolkit/TROUBLESHOOTING.md) を参照してください。

- **Python not found**: `-Global` を付けて再実行するか、ストア版 Python のエイリアスを無効化してください。
- **Permission Denied**: PowerShell を「管理者として実行」しているか確認してください。

## 🔁 6. 運用チェック（推奨）
- **Windows Update 後**: `ag_health.ps1` で動作確認。
- **NVIDIA ドライバ更新後**: `ag_health.ps1` で GPU 連携確認。
- **新規ライブラリ追加後**: `check_env.ps1` で環境のドリフト（変質）を確認。
