#!/usr/bin/env bash
set -eo pipefail

total=0

# Исключаем .git и .DS_Store; при необходимости поправь паттерны
while IFS= read -r -d '' file; do
  # Пропустим нулевой размер (опционально)
  # [ ! -s "$file" ] && continue

  lines=$(wc -l < "$file" 2>/dev/null || echo 0)
  printf "%8d %s\n" "$lines" "$file"
  total=$((total + lines))
done < <(find . -type f \
    -not -path '*/.git/*' \
    -not -name '.DS_Store' \
    -print0)

echo
printf "Total lines: %d\n" "$total"
