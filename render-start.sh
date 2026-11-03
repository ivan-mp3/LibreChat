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
set -eu

DISK=/data

echo "[render-start] usuario: $(id -un) ($(id -u):$(id -g))"
ls -ld "$DISK" || {
  echo "[render-start] ERRO: $DISK nao existe."
  echo "[render-start] O disco persistente nao esta montado. Abortando em vez de"
  echo "[render-start] gravar em disco efemero e perder os arquivos no proximo deploy."
  exit 1
}

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

# Inventario do disco a cada boot. Se estes numeros zerarem de um deploy para o
# outro, o disco deixou de ser montado e os arquivos dos usuarios sumiram.
echo "[render-start] disco: $(find "$DISK/uploads" -type f 2>/dev/null | wc -l) arquivo(s) em uploads," \
     "$(find "$DISK/images" -type f 2>/dev/null | wc -l) em images," \
     "ocupando $(du -sh "$DISK" 2>/dev/null | cut -f1)"

# O Render descarta variaveis de ambiente de valor vazio, e o LibreChat so
# esconde o rodape quando CUSTOM_FOOTER existe COMO string vazia
# (routes/config.js testa `typeof === "string"`, e Footer.tsx cai no texto
# padrao quando o campo nao vem). Esta linha garante a string vazia sem
# atropelar um valor que alguem venha a definir no painel.
export CUSTOM_FOOTER="${CUSTOM_FOOTER-}"

exec npm run backend
