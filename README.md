# DorkSearch

Script em Bash para buscas avançadas usando **Google Dorks**. Monta a consulta, codifica a URL corretamente e abre no navegador, ou apenas exibe/salva as URLs para uso posterior.

## Funcionalidades

- Operadores clássicos: `site:`, `inurl:`, `intitle:`, `filetype:`, `allintext:`, `intext:`
- Dorks prontas para reconhecimento: arquivos expostos, diretórios abertos (`index of`), páginas de login, subdomínios
- **Reconhecimento completo** (`-r`): gera 13 dorks de uma vez (backups, `.env`, logs, erros de SQL, `phpinfo`, `.git` exposto, WordPress, parâmetros de redirecionamento, menções no Pastebin/GitHub...)
- Vários alvos de uma vez com uma lista (`-l`)
- Buscadores: Google, Bing, DuckDuckGo e Yandex (`-e`)
- Salva as dorks e URLs geradas em arquivo (`-o`)
- Atalho para a Wayback Machine do alvo
- Menu em loop: dá para trocar o alvo e o buscador sem sair do script

## Instalação

```bash
git clone https://github.com/knxbrenno/DorkSearch.git
cd DorkSearch
chmod +x ghdb.sh
```

Requisitos: `bash` e um navegador (`xdg-open`, `firefox`, `chromium`...). Sem navegador, o script apenas exibe as URLs.

## Uso

```bash
./ghdb.sh [opções] <termo_de_pesquisa>
```

| Opção | Descrição |
|---|---|
| `-p` | Apenas exibe a URL, sem abrir o navegador |
| `-b <navegador>` | Navegador a ser usado (também aceita a variável `BROWSER`) |
| `-e <buscador>` | `google` (padrão), `bing`, `ddg` ou `yandex` |
| `-o <arquivo>` | Salva as dorks e URLs em um arquivo (separado por TAB) |
| `-r` | Reconhecimento completo, sem menu |
| `-l <arquivo>` | Lista de alvos (um por linha) para o modo `-r` |
| `-d <segundos>` | Intervalo entre as abas abertas no modo `-r` (padrão: 2) |
| `-h` | Ajuda |

### Exemplos

```bash
# Menu interativo
./ghdb.sh exemplo.com

# Termo com espaços e caracteres especiais
./ghdb.sh -p "senha & admin"

# Reconhecimento completo, salvando as URLs sem abrir o navegador
./ghdb.sh -r -p -o recon.txt exemplo.com

# Reconhecimento de vários domínios
./ghdb.sh -r -p -l alvos.txt -o recon.txt

# Usando o DuckDuckGo no Chromium
./ghdb.sh -e ddg -b chromium exemplo.com
```

## Aviso

Ferramenta para fins educacionais e testes autorizados. Use apenas em alvos que você tem permissão para avaliar.
