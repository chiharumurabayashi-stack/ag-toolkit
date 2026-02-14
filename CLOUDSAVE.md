# ☁️ Antigravity Cloud-Safe Environment

Google DriveやOneDriveなどのクラウド同期ディレクトリ、および日本語などの非ASCIIパスを含む環境で安全に開発を行うためのマニュアルです。

## 🛡️ 実装された安全機能

### 1. Virtual Path Layer (SUBST)
`ag_toolkit\fix_virtual_path.ps1` を実行することで、物理パスを `X:` などの仮想ドライブに割り当てます。
- **メリット**: 日本語パスの影響を完全に排除し、Node.jsやRustツールのクラッシュを防ぎます。
- **永続化**: Windowsレジストリ (`HKCU\...\Run`) に登録されるため、再起動後も自動で再マッピングされます。

### 2. Hashed External Venv
仮想環境をプロジェクトディレクトリ外の `C:\.ag_venv\<hash>\` に作成します。
- **メリット**: クラウド同期による`.venv`内の大量ファイルの衝突や、パス長制限の問題を回避します。
- **Hash**: プロジェクトの物理パスを元にハッシュ化されているため、複数プロジェクトが混ざることはありません。

### 3. Cloud Detection
`check_env.ps1` が Google Drive / OneDrive を自動検知します。
- **Cloud-only Alert**: ファイルが「オンラインのみ（実体がない）」状態で同期されている場合、警告を出します。必ず「オフラインで使用可能」に設定してください。

---

## 🛠️ トラブルシューティング

### 仮想ドライブを変更したい
`fix_virtual_path.ps1 -TargetDrive Y: -Force` のように実行すると、指定したドライブへの再割り当てとレジストリの更新が行われます。

### マニフェストの場所
`state/path_map.json` に、現在の物理・仮想・venvの対応関係が記録されています。Self-Healing機能はこれを利用して自動修復を行います。

---

> [!TIP]
> Google Driveのアイコンを右クリックし、**「オフラインで使用可能（Available offline）」**に設定することを強く推奨します。
