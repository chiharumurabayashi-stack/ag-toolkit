# TROUBLESHOOTING GUIDE (Antigravity v1.1.0)

## 1. Python 関連
- **"python" is not recognized**: `ag_quickstart.ps1 -Global` を実行してインストールするか、Windows の「アプリ実行エイリアス」から Microsoft Store 版の Python を OFF にしてください。
- **venv creation failed**: パスに日本語や空白が含まれていないか確認してください。

## 2. Node.js 関連
- **winget failed**: プロキシ環境や、管理者権限の欠如が原因です。手動で [Node.js LTS](https://nodejs.org/) をインストールしてください。

## 3. GPU / CUDA 関連
- **Torch not detecting GPU**: NVIDIA ドライバが最新か確認してください。ドライバ更新後は `auto_fix.ps1 -Mode Execute -Level Moderate` でライブラリを再リンクしてください。

## 4. パーミッション関連
- **Permission Denied**: PowerShell を「管理者として実行」しているか確認してください。
- **Execution Policy Error**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process` を実行してください。

---
Analysis Complete - All tasks finished
