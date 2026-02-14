# 🧠 GPU トラブル診断フローチャート

NVIDIA GPU が正しく認識されない、または速度が遅い場合の診断フローです。

```mermaid
graph TD
    Start([GPUが遅い/認識されない]) --> CheckSMI[nvidia-smi を実行]
    CheckSMI -- 認識されない/エラー --> Driver[ドライバが最新か確認]
    Driver -- 古い/不整合 --> UpdateDriver[NVIDIAドライバを更新]
    UpdateDriver --> Restart[PCを再起動]
    Restart --> CheckSMI
    
    CheckSMI -- 認識される --> CheckCuda[torch.cuda.is_available を確認]
    CheckCuda -- False --> ReinstallTorch[PyTorch を再インストール]
    ReinstallTorch -- CUDA版を指定 --> CheckCuda
    
    CheckCuda -- True --> CheckPower[電源プランを確認]
    CheckPower -- 省電力/静音 --> Highperf[高パフォーマンスモードに変更]
    Highperf --> CheckVRAM[VRAM 使用量を確認]
    
    CheckVRAM -- 足りない --> OptimizeModel[モデルやバッチサイズを調整]
    CheckVRAM -- 余裕あり --> Ready([正常稼働])
```

## 💡 各ステップの詳細

### 1. nvidia-smi の実行
PowerShell で `nvidia-smi` と入力してください。GPU 名とドライババージョンが表示されれば、ハードウェアレベルでは認識されています。

### 2. PyTorch (torch) の確認
Python 環境で以下を実行します：
```python
import torch
print(torch.cuda.is_available()) # True である必要があります
```
ここが `False` の場合、プログラムは CPU で動いています。

### 3. 電源プランの重要性
ゲーミングノート PC では、バッテリー駆動や「静音モード」の際、dGPU（外付け GPU）が低速動作したり、無効化されたりすることがあります。必ず AC アダプタを接続し、「最適なパフォーマンス」に設定してください。

### 4. ドライバとライブラリの不一致
ドライバを新しくした際、過去にインストールしたライブラリが古い CUDA バージョンを探し続けてエラーになることがあります。その場合は、`pip install` をやり直すのが最も確実です。
