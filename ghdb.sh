#!/usr/bin/env bash
# DorkSearch - buscas avançadas no Google (e outros buscadores) usando Google Dorks.

RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BROWSER="${BROWSER:-}"   # Pode ser definido pelo usuário: BROWSER=chromium ./ghdb.sh alvo
ENGINE="google"
PRINT_ONLY=0
RECON=0
OUTPUT=""
TARGETS_FILE=""
DELAY=2                  # Segundos entre abas abertas no modo de reconhecimento

# Dorks usadas no reconhecimento completo. {T} é substituído pelo alvo.
RECON_DORKS=(
  "Subdomínios|site:*.{T} -site:www.{T}"
  "Diretórios abertos|site:{T} intitle:\"index of\""
  "Páginas de login/admin|site:{T} (inurl:login OR inurl:admin OR inurl:painel OR intitle:login)"
  "Documentos|site:{T} (ext:pdf OR ext:doc OR ext:docx OR ext:xls OR ext:xlsx OR ext:ppt OR ext:pptx)"
  "Arquivos de configuração|site:{T} (ext:env OR ext:ini OR ext:conf OR ext:cfg OR ext:yml OR ext:xml)"
  "Bancos de dados e backups|site:{T} (ext:sql OR ext:db OR ext:bak OR ext:backup OR ext:old OR ext:zip)"
  "Arquivos de log|site:{T} ext:log"
  "Erros de SQL/PHP|site:{T} (intext:\"sql syntax near\" OR intext:\"Warning: mysql\" OR intext:\"Fatal error\")"
  "phpinfo exposto|site:{T} ext:php intitle:phpinfo \"published by the PHP Group\""
  "Repositório .git exposto|site:{T} (inurl:\".git\" OR intitle:\"index of\" \".git\")"
  "WordPress|site:{T} (inurl:wp-content OR inurl:wp-admin OR inurl:wp-json)"
  "Parâmetros de redirecionamento|site:{T} (inurl:redirect= OR inurl:url= OR inurl:return= OR inurl:next=)"
  "Menções em sites de colagem/código|(site:pastebin.com OR site:github.com OR site:trello.com) \"{T}\""
)

banner() {
  echo -e "${RED}=========================="
  echo -e "      DorkSearch"
  echo -e "==========================${NC}"
  echo
}

usage() {
  echo "Modo de uso: $0 [opções] <termo_de_pesquisa>"
  echo "Este script realiza pesquisas usando operadores de Google Dorks."
  echo
  echo "Argumentos:"
  echo "  <termo_de_pesquisa>    Termo ou site a ser pesquisado (use aspas se tiver espaços)"
  echo
  echo "Opções:"
  echo "  -p                     Apenas exibe a URL, sem abrir o navegador"
  echo "  -b <navegador>         Navegador a ser usado (padrão: xdg-open, firefox, chromium...)"
  echo "  -e <buscador>          google (padrão), bing, ddg (DuckDuckGo) ou yandex"
  echo "  -o <arquivo>           Salva as dorks e URLs geradas em um arquivo"
  echo "  -r                     Reconhecimento completo: gera todas as dorks de recon sem menu"
  echo "  -l <arquivo>           Lista de alvos (um por linha) para o modo -r"
  echo "  -d <segundos>          Intervalo entre abas abertas no modo -r (padrão: 2)"
  echo "  -h                     Exibe esta ajuda"
  echo
  echo "Exemplos de uso:"
  echo "  $0 exemplo.com"
  echo "  $0 -p \"senha admin\""
  echo "  $0 -r -p -o recon.txt exemplo.com"
  echo "  $0 -r -p -l alvos.txt -o recon.txt"
  echo "  $0 -e ddg exemplo.com"
  exit "${1:-1}"
}

# Codifica o texto para ser usado com segurança em uma URL (espaços, &, #, aspas...).
urlencode() {
  local LC_ALL=C str="$1" out="" c i
  for (( i = 0; i < ${#str}; i++ )); do
    c="${str:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) out+="$c" ;;
      ' ') out+='+' ;;
      *) printf -v c '%%%02X' "'$c"; out+="$c" ;;
    esac
  done
  echo "$out"
}

engine_url() {
  case "$ENGINE" in
    google) echo "https://www.google.com/search?q=" ;;
    bing)   echo "https://www.bing.com/search?q=" ;;
    ddg)    echo "https://duckduckgo.com/?q=" ;;
    yandex) echo "https://yandex.com/search/?text=" ;;
    *) return 1 ;;
  esac
}

# Escolhe o primeiro navegador disponível, caso nenhum tenha sido informado.
detect_browser() {
  [ -n "$BROWSER" ] && return
  for b in xdg-open firefox chromium google-chrome open; do
    if command -v "$b" &> /dev/null; then
      BROWSER="$b"
      return
    fi
  done
}

search() {
  local query="$1" label="${2:-}"
  local url
  url="$(engine_url)$(urlencode "$query")"

  [ -n "$label" ] && echo -e "${YELLOW}[$label]${NC}"
  echo -e "${GREEN}Dork: ${NC}$query"
  echo -e "${GREEN}URL:  ${NC}$url"

  if [ -n "$OUTPUT" ]; then
    printf '%s\t%s\t%s\n' "${label:-manual}" "$query" "$url" >> "$OUTPUT"
  fi

  if [ "$PRINT_ONLY" -eq 1 ]; then
    return
  fi

  detect_browser
  if [ -z "$BROWSER" ]; then
    echo -e "${YELLOW}Nenhum navegador encontrado. Copie a URL acima.${NC}"
    return
  fi
  "$BROWSER" "$url" &> /dev/null &
}

# Executa todas as dorks de reconhecimento para um alvo.
recon() {
  local target="$1" entry label dork
  echo -e "${BLUE}===== Reconhecimento: $target (${#RECON_DORKS[@]} dorks) =====${NC}"
  for entry in "${RECON_DORKS[@]}"; do
    label="${entry%%|*}"
    dork="${entry#*|}"
    search "${dork//\{T\}/$target}" "$label"
    echo
    # Evita abrir dezenas de abas de uma vez (e ser bloqueado pelo buscador).
    [ "$PRINT_ONLY" -eq 0 ] && sleep "$DELAY"
  done
}

change_engine() {
  echo "Buscadores: google, bing, ddg, yandex"
  read -r -p "Novo buscador: " new_engine
  local old="$ENGINE"
  ENGINE="$new_engine"
  if ! engine_url > /dev/null; then
    echo -e "${RED}Buscador inválido.${NC}"
    ENGINE="$old"
  fi
}

while getopts ":pb:e:o:rl:d:h" opt; do
  case $opt in
    p) PRINT_ONLY=1 ;;
    b) BROWSER="$OPTARG" ;;
    e) ENGINE="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    r) RECON=1 ;;
    l) TARGETS_FILE="$OPTARG" ;;
    d) DELAY="$OPTARG" ;;
    h) usage 0 ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

ALVO="$*"

banner

if ! engine_url > /dev/null; then
  echo -e "${RED}Buscador inválido: $ENGINE${NC}"
  usage
fi

if [ "$RECON" -eq 1 ]; then
  if [ -n "$TARGETS_FILE" ]; then
    if [ ! -f "$TARGETS_FILE" ]; then
      echo -e "${RED}Lista de alvos não encontrada: $TARGETS_FILE${NC}"
      exit 1
    fi
    while IFS= read -r t || [ -n "$t" ]; do
      t="${t%$'\r'}"
      [[ -z "$t" || "$t" == \#* ]] && continue
      recon "$t"
    done < "$TARGETS_FILE"
  elif [ -n "$ALVO" ]; then
    recon "$ALVO"
  else
    usage
  fi
  [ -n "$OUTPUT" ] && echo -e "${GREEN}Resultados salvos em $OUTPUT${NC}"
  exit 0
fi

if [ -z "$ALVO" ]; then
  usage
fi

echo "Software para buscas avançadas usando Google Dorks."
echo "Escolha um operador para refinar suas buscas e obter resultados específicos."
echo

while true; do
  echo -e "Alvo: ${GREEN}$ALVO${NC}   Buscador: ${GREEN}$ENGINE${NC}"
  echo "Escolha o operador de Google Dork para a pesquisa:"
  echo " 1) site:       (pesquisar em um site específico)"
  echo " 2) inurl:      (pesquisar URL com termo específico)"
  echo " 3) intitle:    (pesquisar no título da página)"
  echo " 4) filetype:   (pesquisar por tipo de arquivo)"
  echo " 5) allintext:  (pesquisar texto específico no conteúdo da página)"
  echo " 6) intext:     (pesquisar um termo no conteúdo da página)"
  echo " 7) Arquivos expostos no site     (site: + filetype:)"
  echo " 8) Diretórios abertos no site    (site: + intitle:\"index of\")"
  echo " 9) Páginas de login no site      (site: + inurl:login/admin)"
  echo "10) Subdomínios do site           (site:*.alvo -site:www.alvo)"
  echo "11) Dork personalizada            (você digita os operadores)"
  echo "12) Reconhecimento completo       (${#RECON_DORKS[@]} dorks de uma vez)"
  echo "13) Busca no cache/arquivo        (Wayback Machine)"
  echo "14) Trocar alvo"
  echo "15) Trocar buscador"
  echo " 0) Sair"
  echo

  read -r -p "Digite o número da opção desejada: " OPTION

  case $OPTION in
    1) search "site:$ALVO" ;;
    2) search "inurl:$ALVO" ;;
    3) search "intitle:$ALVO" ;;
    4)
      read -r -p "Digite a extensão do arquivo (ex: pdf, doc): " FILETYPE
      search "filetype:$FILETYPE $ALVO"
      ;;
    5) search "allintext:$ALVO" ;;
    6) search "intext:\"$ALVO\"" ;;
    7)
      read -r -p "Digite a extensão do arquivo (ex: pdf, xls, sql, env, log): " FILETYPE
      search "site:$ALVO filetype:$FILETYPE"
      ;;
    8) search "site:$ALVO intitle:\"index of\"" ;;
    9) search "site:$ALVO (inurl:login OR inurl:admin OR inurl:painel OR intitle:login)" ;;
    10) search "site:*.$ALVO -site:www.$ALVO" ;;
    11)
      read -r -p "Digite a dork completa: " CUSTOM
      search "$CUSTOM"
      ;;
    12)
      if [ "$PRINT_ONLY" -eq 0 ]; then
        read -r -p "Isso abrirá ${#RECON_DORKS[@]} abas no navegador. Continuar? [s/N] " CONFIRM
        [[ "$CONFIRM" =~ ^[sSyY]$ ]] || continue
      fi
      recon "$ALVO"
      ;;
    13)
      # A Wayback Machine lista URLs antigas do domínio, ótimo para achar páginas removidas.
      URL="https://web.archive.org/web/*/$ALVO/*"
      echo -e "${GREEN}URL:  ${NC}$URL"
      [ -n "$OUTPUT" ] && printf 'wayback\t%s\t%s\n' "$ALVO" "$URL" >> "$OUTPUT"
      if [ "$PRINT_ONLY" -eq 0 ]; then
        detect_browser
        [ -n "$BROWSER" ] && "$BROWSER" "$URL" &> /dev/null &
      fi
      ;;
    14) read -r -p "Novo alvo: " ALVO ;;
    15) change_engine ;;
    0|q|"") echo "Saindo."; exit 0 ;;
    *) echo -e "${RED}Opção inválida.${NC}" ;;
  esac
  echo
done
