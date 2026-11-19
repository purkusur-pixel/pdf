#!/usr/bin/env bash
# =============================================================================
#  GitHub'a gönder / Push to GitHub — "gönder tuşu / send button"
#
#  Kullanım / Usage:
#    bash github-gonder.sh                   # ilk gönderim ve güncellemeler / first push & updates
#    bash github-gonder.sh "mesaj"           # kendi commit mesajınla / with your commit message
#    FORCE=1 bash github-gonder.sh           # depodaki her şeyin üzerine yaz / overwrite remote
#
#  Giriş / Authentication: GitHub şifre kabul etmez. Şifre sorulursa
#  bir Personal Access Token yapıştır (Settings → Developer settings → Tokens),
#  ya da önce `gh auth login` çalıştır.  GitHub doesn't accept passwords;
#  paste a Personal Access Token when asked, or run `gh auth login` first.
# =============================================================================
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

REPO_URL="${REPO_URL:-https://github.com/purkusur-pixel/pdf.git}"
BRANCH="${BRANCH:-main}"
MSG="${1:-}"

command -v git >/dev/null 2>&1 || { echo "git yok / git not installed (apt install git)"; exit 1; }

if [ ! -d .git ]; then
  git init -q -b "$BRANCH" 2>/dev/null || { git init -q; git checkout -q -b "$BRANCH"; }
  echo "✔ Yeni git deposu / new git repository"
  MSG="${MSG:-PDF Araçları: ilk sürüm / initial release}"
fi

if [ -z "$(git config user.name || true)" ]; then
  read -rp "Git adın / your name: " n;  git config user.name "$n"
fi
if [ -z "$(git config user.email || true)" ]; then
  read -rp "Git e-postan / your e-mail: " e; git config user.email "$e"
fi

git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$REPO_URL" || git remote add origin "$REPO_URL"

git add -A
if git diff --cached --quiet; then
  echo "• Yeni değişiklik yok / nothing new to commit"
else
  git commit -q -m "${MSG:-Güncelleme / Update $(date '+%Y-%m-%d %H:%M')}"
  echo "✔ Commit: $(git log -1 --pretty=%s)"
fi

if [ "${FORCE:-0}" = "1" ]; then
  git push -u --force origin "$BRANCH"
elif ! git push -u origin "$BRANCH"; then
  echo
  echo "Uzaktaki depoda burada olmayan değişiklikler var (ör. GitHub'da oluşturulan README)."
  echo "The remote has commits that aren't here (e.g. a README created on GitHub)."
  read -rp "Birleştirip tekrar göndereyim mi? / Merge and push again? [E/h] " a
  if [[ "${a:-E}" =~ ^[EeYy]$ ]]; then
    git pull --no-rebase --allow-unrelated-histories -X ours --no-edit origin "$BRANCH"
    git push -u origin "$BRANCH"
  else
    echo "İptal. Üzerine yazmak için / To overwrite:  FORCE=1 bash github-gonder.sh"; exit 1
  fi
fi
echo "✔ Gönderildi / Pushed → ${REPO_URL%.git}"
