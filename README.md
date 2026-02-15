# mokumoku-0210-test-1

このリポジトリは、複数の静的HTMLデモをまとめたプレーンフロントエンド作品集です。

- `index.html` + `style.css` + `script.js`: NexTech Solutions
- `business/` 配下: BrightWorks（ITサービス会社想定）
- `cafe/` 配下: komorebi Cafe & Bakery
- `cats/` 配下: Neko Gallery
- `nanobana.sh`: Gemini 3 Pro Image Preview を使った画像生成CLI
- `image.png` / `test/*` / `*/images/*`: サンプル画像

## ファイル構成

- `index.html` : ルートのコーポレート風ランディングページ
- `style.css` : ルートページのデザイン
- `script.js` : ルートページのアニメーション（ヒーローcanvas、スクロールアニメーション、フォーム擬似送信）
- `business/index.html` : ビジネス向けランディング
- `business/style.css` : businessページのデザイン
- `cafe/index.html` : カフェ向けランディング
- `cafe/style.css` : cafeページのデザイン
- `cafe/images/*` : cafeページ用画像
- `cats/index.html` : 猫ギャラリーページ（インラインCSS）
- `cats/images/*` : ギャラリー画像
- `test/cat.png` : テスト用画像
- `nanobana.sh` : 画像生成スクリプト
- `.env.example` : `GEMINI_API_KEY` の例
- `.gitignore` : `generated/` 等を除外

## 使い方

### 1) ページを開く

いずれも静的HTMLなので、ローカルでそのまま確認できます。

```bash
cd /Users/funakoshiakira/workspace/mokumoku-0210-test-1
python3 -m http.server 8000
```

ブラウザで以下にアクセス:

- ルートページ: <http://localhost:8000/>
- BrightWorks: <http://localhost:8000/business/>
- カフェ: <http://localhost:8000/cafe/>
- ネコギャラリー: <http://localhost:8000/cats/>

### 2) nanobana.sh の使い方

前提: `curl` と `jq` が必要。

```bash
cp .env.example .env
# .env に GEMINI_API_KEY を設定
# または実行時に --key で指定
chmod +x nanobana.sh
./nanobana.sh "A cozy cat café" --aspect 16:9 --size 2K
./nanobana.sh --input input.png --aspect 4:3 "edit this image" --output generated
```

出力画像はデフォルトで `./generated/` に保存されます。

## 補足

- すべてフロントエンドのみの構成で、ビルド工程は不要です。
- ルートの `script.js` は `index.html` の要素IDに依存しています。
- `nanobana.sh` は `GEMINI_API_KEY` 未設定時はエラーになります。
