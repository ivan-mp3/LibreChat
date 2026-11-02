#!/bin/sh
# Bootstrap do LibreChat no Render.
#
# O Render permite um unico disco persistente, montado num unico caminho, mas o
# LibreChat grava em dois lugares diferentes (api/config/paths.js):
#   - imagens e avatares -> /app/client/public/images
#   - demais arquivos     -> /app/uploads
# Esses caminhos sao fixos no codigo. Entao o disco e montado em /data e as
# pastas reais viram symlinks para dentro dele. Sem isso, todo upload some a
# cada deploy.
#
# Nao altera nada do LibreChat: so prepara o sistema de arquivos e entrega o
# processo para o start normal da aplicacao.
set -eux

DISK=/data

echo "[render-start] usuario: $(id)"
echo "[render-start] estado de $DISK:"
ls -ld "$DISK" || echo "[render-start] ATENCAO: $DISK nao existe"

for d in images uploads appdata; do
  mkdir -p "$DISK/$d"
done

link() {
  target=$1
  linkpath=$2
  if [ -L "$linkpath" ]; then
    return 0
  fi
  if [ -d "$linkpath" ]; then
    rmdir "$linkpath"
  fi
  ln -s "$target" "$linkpath"
}

link "$DISK/images"  /app/client/public/images
link "$DISK/uploads" /app/uploads
link "$DISK/appdata" /app/data

echo "[render-start] symlinks prontos:"
ls -ld /app/client/public/images /app/uploads /app/data

exec npm run backend
