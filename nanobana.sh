#!/usr/bin/env bash
# ================================================
# nanobana.sh - Nano Banana Pro (Gemini 3 Pro Image) CLI
# Usage:
#   ./nanobana.sh "猫がコーヒーを飲んでいるイラスト"
#   ./nanobana.sh "A futuristic city" --aspect 16:9 --size 2K
#   ./nanobana.sh "edit this image" --input photo.png
# ================================================

set -euo pipefail

# ---------- CONFIG ----------
API_URL="https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent"
OUTPUT_DIR="./generated"

# ---------- DEFAULTS ----------
ASPECT_RATIO="1:1"
IMAGE_SIZE="1K"
INPUT_IMAGE=""
PROMPT=""

# ---------- PARSE ARGS ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --aspect)  ASPECT_RATIO="$2"; shift 2 ;;
    --size)    IMAGE_SIZE="$2"; shift 2 ;;
    --input)   INPUT_IMAGE="$2"; shift 2 ;;
    --output)  OUTPUT_DIR="$2"; shift 2 ;;
    --key)     GEMINI_API_KEY="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: nanobana.sh \"<prompt>\" [options]"
      echo ""
      echo "Options:"
      echo "  --aspect <ratio>   Aspect ratio: 1:1, 16:9, 9:16, 4:3, 3:4 (default: 1:1)"
      echo "  --size <size>      Image size: 1K, 2K, 4K (default: 1K)"
      echo "  --input <file>     Input image for editing"
      echo "  --output <dir>     Output directory (default: ./generated)"
      echo "  --key <api_key>    Gemini API key (or set GEMINI_API_KEY env var)"
      exit 0
      ;;
    *)
      if [[ -z "$PROMPT" ]]; then
        PROMPT="$1"
      else
        PROMPT="$PROMPT $1"
      fi
      shift
      ;;
  esac
done

# ---------- VALIDATE ----------
if [[ -z "$PROMPT" ]]; then
  echo "Error: プロンプトを指定してください"
  echo "Usage: nanobana.sh \"猫のイラスト\" [--aspect 16:9] [--size 2K]"
  exit 1
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "Error: GEMINI_API_KEY が設定されていません"
  echo "  export GEMINI_API_KEY='your-api-key'"
  echo "  または --key オプションで指定してください"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ---------- BUILD REQUEST BODY ----------
PARTS_JSON=""

# Add text prompt
PARTS_JSON=$(jq -n --arg text "$PROMPT" '[{"text": $text}]')

# Add input image if specified
if [[ -n "$INPUT_IMAGE" ]]; then
  if [[ ! -f "$INPUT_IMAGE" ]]; then
    echo "Error: 入力画像が見つかりません: $INPUT_IMAGE"
    exit 1
  fi

  MIME_TYPE="image/png"
  case "$INPUT_IMAGE" in
    *.jpg|*.jpeg) MIME_TYPE="image/jpeg" ;;
    *.webp)       MIME_TYPE="image/webp" ;;
    *.gif)        MIME_TYPE="image/gif" ;;
  esac

  BASE64_DATA=$(base64 < "$INPUT_IMAGE")

  PARTS_JSON=$(echo "$PARTS_JSON" | jq --arg mime "$MIME_TYPE" --arg data "$BASE64_DATA" \
    '. + [{"inline_data": {"mime_type": $mime, "data": $data}}]')
fi

REQUEST_BODY=$(jq -n \
  --argjson parts "$PARTS_JSON" \
  --arg aspect "$ASPECT_RATIO" \
  --arg size "$IMAGE_SIZE" \
  '{
    "contents": [{"parts": $parts}],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"],
      "imageConfig": {
        "aspectRatio": $aspect,
        "imageSize": $size
      }
    }
  }')

# ---------- CALL API ----------
echo "Generating image..."
echo "  Prompt: $PROMPT"
echo "  Aspect: $ASPECT_RATIO | Size: $IMAGE_SIZE"
echo ""

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${API_URL}?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ne 200 ]]; then
  echo "Error: API returned HTTP $HTTP_CODE"
  echo "$RESPONSE_BODY" | jq -r '.error.message // .' 2>/dev/null || echo "$RESPONSE_BODY"
  exit 1
fi

# ---------- EXTRACT & SAVE ----------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
IMAGE_SAVED=false
TEXT_RESPONSE=""

# Parse response parts
PARTS_COUNT=$(echo "$RESPONSE_BODY" | jq '.candidates[0].content.parts | length')

for ((i=0; i<PARTS_COUNT; i++)); do
  PART_TYPE=$(echo "$RESPONSE_BODY" | jq -r ".candidates[0].content.parts[$i] | keys[]" | head -1)

  if [[ "$PART_TYPE" == "inline_data" ]]; then
    MIME=$(echo "$RESPONSE_BODY" | jq -r ".candidates[0].content.parts[$i].inline_data.mime_type")
    EXT="png"
    [[ "$MIME" == "image/jpeg" ]] && EXT="jpg"
    [[ "$MIME" == "image/webp" ]] && EXT="webp"

    OUTPUT_FILE="${OUTPUT_DIR}/nanobana_${TIMESTAMP}.${EXT}"
    echo "$RESPONSE_BODY" | jq -r ".candidates[0].content.parts[$i].inline_data.data" | base64 -d > "$OUTPUT_FILE"
    IMAGE_SAVED=true
    echo "Image saved: $OUTPUT_FILE"

  elif [[ "$PART_TYPE" == "text" ]]; then
    TEXT_RESPONSE=$(echo "$RESPONSE_BODY" | jq -r ".candidates[0].content.parts[$i].text")
  fi
done

if [[ "$IMAGE_SAVED" == false ]]; then
  echo "Warning: レスポンスに画像が含まれていませんでした"
  if [[ -n "$TEXT_RESPONSE" ]]; then
    echo "Response: $TEXT_RESPONSE"
  else
    echo "$RESPONSE_BODY" | jq '.candidates[0].content.parts' 2>/dev/null || echo "$RESPONSE_BODY"
  fi
  exit 1
fi

if [[ -n "$TEXT_RESPONSE" ]]; then
  echo "Description: $TEXT_RESPONSE"
fi

echo ""
echo "Done!"
