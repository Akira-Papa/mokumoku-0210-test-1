---
name: nanobana
description: Nano Banana Pro (Gemini 3 Pro) で画像を生成・編集する。画像生成、イラスト作成、画像編集、ロゴ作成、バナー作成などのリクエストで使用する。
argument-hint: "[プロンプト] [--aspect 16:9] [--size 2K] [--input image.png]"
allowed-tools: Bash(curl *), Bash(base64 *), Bash(mkdir *), Bash(cat *), Bash(echo *), Bash(source *), Bash(export *), Bash(set *), Bash(grep *), Read, Glob
---

# Nano Banana Pro 画像生成スキル

Nano Banana Pro (Gemini 3 Pro Image Preview) APIを使って画像を生成・編集する。

## 前提条件

プロジェクトルートの `.env` ファイルから `GEMINI_API_KEY` を読み込む。

## APIキーの読み込み

**毎回最初に必ず実行すること:**

```bash
set -a && source .env && set +a
```

`.env` が見つからない、または `GEMINI_API_KEY` が空の場合はユーザーに以下を案内して停止する:

> プロジェクトルートの `.env` ファイルに以下を追加してください:
> ```
> GEMINI_API_KEY=your-api-key
> ```

## API仕様

- **エンドポイント**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent`
- **メソッド**: POST
- **認証**: クエリパラメータ `key=$GEMINI_API_KEY`

## 実行手順

### 1. .env 読み込みとAPIキー確認

```bash
set -a && source .env && set +a && echo "GEMINI_API_KEY=${GEMINI_API_KEY:+OK}"
```

`OK` が出なければ `.env` の設定を案内して停止する。

### 2. 出力ディレクトリの準備

```bash
mkdir -p ./generated
```

### 3. API呼び出し

**テキストから画像生成の場合:**

```bash
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts": [{"text": "プロンプト内容"}]}],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"],
      "imageConfig": {
        "aspectRatio": "1:1",
        "imageSize": "1K"
      }
    }
  }' -o /tmp/nanobana_response.json
```

**既存画像を編集する場合:**

入力画像をbase64エンコードして `inline_data` に含める:

```bash
BASE64_IMG=$(base64 < input.png)
```

リクエストの parts に追加:
```json
{"inline_data": {"mime_type": "image/png", "data": "<base64>"}}
```

### 4. レスポンス解析と画像保存

```bash
# 画像データを抽出して保存
cat /tmp/nanobana_response.json | jq -r '.candidates[0].content.parts[] | select(.inline_data) | .inline_data.data' | base64 -d > ./generated/nanobana_$(date +%Y%m%d_%H%M%S).png
```

```bash
# テキストレスポンスも取得
cat /tmp/nanobana_response.json | jq -r '.candidates[0].content.parts[] | select(.text) | .text'
```

### 5. エラーハンドリング

APIエラーの場合:
```bash
cat /tmp/nanobana_response.json | jq -r '.error.message // empty'
```

画像が含まれていない場合はユーザーにプロンプトの修正を提案する。

## パラメータリファレンス

| パラメータ | 値 | デフォルト |
|---|---|---|
| aspectRatio | `1:1`, `16:9`, `9:16`, `4:3`, `3:4` | `1:1` |
| imageSize | `1K`, `2K`, `4K` | `1K` |

## 使用例

ユーザーが「猫のイラストを生成して」と言った場合:
1. APIキーを確認
2. プロンプトを英語に翻訳（精度向上のため）
3. APIを呼び出し
4. 生成画像を `./generated/` に保存
5. 保存パスをユーザーに報告し、Read ツールで画像を表示

ユーザーが「この画像の背景を変えて」と言った場合:
1. 入力画像をbase64エンコード
2. 編集指示とともにAPIを呼び出し
3. 結果を保存・表示

## 注意事項

- プロンプトは英語の方が高精度。日本語入力は英語に翻訳してからAPIに送る
- 生成画像にはSynthIDの透かしが含まれる
- 4Kサイズはコストが高いため、必要な場合のみ使用
- `/tmp/nanobana_response.json` は一時ファイル。毎回上書きされる
- 生成後は Read ツールで画像をユーザーに表示すること
