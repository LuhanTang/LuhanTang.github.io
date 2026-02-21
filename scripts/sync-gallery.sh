#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GALLERY_DIR="$ROOT_DIR/assets/gallery"
PAGE_FILE="$ROOT_DIR/gallery.html"

if [[ ! -d "$GALLERY_DIR" ]]; then
  echo "Gallery directory not found: $GALLERY_DIR" >&2
  exit 1
fi

if [[ ! -f "$PAGE_FILE" ]]; then
  echo "Gallery page not found: $PAGE_FILE" >&2
  exit 1
fi

tmp_block="$(mktemp)"
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_block" "$tmp_out"' EXIT

find "$GALLERY_DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
  ! -name '.*' \
  -print \
| sort \
| while IFS= read -r abs_path; do
    base="$(basename "$abs_path")"
    alt_name="${base%.*}"
    rel_path="assets/gallery/$base"
    cat >> "$tmp_block" <<ITEM
          <figure class="gallery-card">
            <img src="$rel_path" alt="$alt_name" loading="lazy" />
          </figure>
ITEM
  done

awk -v block_file="$tmp_block" '
  /<!-- GALLERY_ITEMS_START -->/ {
    print;
    while ((getline line < block_file) > 0) print line;
    close(block_file);
    in_block=1;
    next;
  }
  /<!-- GALLERY_ITEMS_END -->/ {
    in_block=0;
    print;
    next;
  }
  !in_block { print }
' "$PAGE_FILE" > "$tmp_out"

mv "$tmp_out" "$PAGE_FILE"
echo "Updated gallery items from $GALLERY_DIR"
