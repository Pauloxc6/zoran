#!/usr/bin/env bash

# ==============================================================================
# Definindo variáveis globais de cores com sequências de escape ANSI
# ==============================================================================
export WHITE=$'\e[37;1m'
export GREEN=$'\e[32;1m'
export RED=$'\e[31;1m'
export BLUE=$'\e[34;1m'
export YELLOW=$'\e[33;1m'
export RESET=$'\e[0m'

# ==============================================================================
# Função: search
# Descrição: Pesquisa repositórios do usuário 'Pauloxc6' no GitHub usando a API.
# Parâmetros:
#   $1 - Termo/Nome do projeto para busca
# ==============================================================================
function search(){

    local query="$1"

    # Faz chamadas à API do GitHub e extrai as informações do repositório via jq
    local id_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}"  | jq -r '.items[].id' 2>/dev/null)
    local name_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}"  | jq -r '.items[].name' 2>/dev/null)
    local updated_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}"  | jq -r '.items[].updated_at' 2>/dev/null)
    local size_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}"  | jq -r '.items[].size' 2>/dev/null)
    local url_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}" | jq -r '.items[].clone_url' 2>/dev/null)
    local description_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}" | jq -r '.items[].description' 2>/dev/null)
    local license_project=$(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6+${query}" | jq -r '.items[].license.name' 2>/dev/null)

    # Armazena os dados recuperados em um array para validação
    vars=(
        "${id_project}"
        "${name_project}"
        "${updated_project}"
        "${size_project}"
        "${url_project}"
        "${description_project}"
        "${license_project}"
    )

    # Garante que, se alguma variável estiver vazia (projeto não encontrado/erro), o script encerra
    for var in "${vars[@]}"; do
        if [ -z "${var}" ]; then exit 1; fi
    done

    # Exibe na tela os detalhes formatados do projeto consultado
    cat <<EOF
Nome: ${name_project} | Id: ${id_project}
Projeto: ${url_project} | Tamanho: $( if [[ "${size_project}" -le 1024 ]]; then echo "${size_project}KB"; else echo "$(bc <<< "scale=2; ${size_project} / 1024") MB"; fi )
Última atualização: ${updated_project}

Descrição:
${description_project}

Licença: ${license_project}
EOF

    # Limpa as variáveis locais após a execução
    unset "${id_project}" "${name_project}" "${size_project}" "${updated_project}" "${url_project}" "${description_project}" "${license_project}"
}

# ==============================================================================
# Função: install_pkg
# Descrição: Clona e instala um repositório executando o script install.sh, se existir.
# Parâmetros:
#   $1 - Nome do pacote/repositório
# ==============================================================================
function install_pkg(){

    local pkg="$1"
    local save_path="/tmp/${pkg}"

    # Obtém o URL de clonagem diretamente da API do GitHub
    url_project=$(curl -s "https://api.github.com/repos/Pauloxc6/${pkg}" | jq -r '.clone_url')

    echo -e "${GREEN}[+] Download: ${WHITE}${url_project}${RESET}"

    # Solicita confirmação interativa caso a flag -y não tenha sido fornecida
    if [ -z "${sn}" ]; then read -rp $'\e[33;1mContinuar a instalação [s/n]: \e[0m' sn; fi

    if [ "${sn}" == "s" ]; then

        # Clona o repositório silenciosamente para o diretório temporário
        if git clone "${url_project}" "${save_path}" 2>/dev/null; then : ; fi

        # Entra no diretório e executa o instalador se o arquivo 'install.sh' estiver presente
        cd "${save_path}" || exit 1
        if [ -f "install.sh" ]; then bash install.sh;fi
        cd - >/dev/null || exit 1

        # Limpa os arquivos temporários criados para a instalação
        if ! rm -rf "${save_path}"; then return 1; fi
    else
        echo -e "${GREEN}Saindo...${RESET}"
    fi

    echo -e "${GREEN}[+] Finalizando ${RESET}"
}

# ==============================================================================
# Função: uninstall_pkg
# Descrição: Remove os diretórios locais de um pacote instalados do usuário.
# Parâmetros:
#   $1 - Nome do pacote a ser removido
# ==============================================================================
function uninstall_pkg(){

    local pkg="$1"
    local share_pkg="$HOME/.local/share/${pkg}"
    local bin_pkg="$HOME/.local/bin/${pkg}"

    # Solicita confirmação do usuário
    if [ -z "${sn}" ]; then read -rp $'\e[33;1mContinuar a desinstalação [s/n]: \e[0m' sn; fi

    if [ "${sn}" == "s" ]; then
        echo -e "${GREEN}[*] Uninstall: ${WHITE}${pkg}${RESET}"
        # Itera sobre os diretórios padrão de instalação e remove caso existam
        for i in ${share_pkg} ${bin_pkg}; do
            echo -e "${RED}[!] Removing: ${WHITE}${i}${RESET}"
            if [ -d "${i}" ]; then
                if ! rm -rf "${i}"; then return 1; fi
            fi
        done
    else
        echo -e "${GREEN}Saindo...${RESET}"
    fi

    echo -e "${GREEN}[+] Finalizando ${RESET}"
}

# ==============================================================================
# Função: update
# Descrição: Atualiza via 'git pull' todos os pacotes instalados em ~/.local/share/
# ==============================================================================
function update(){

    # Lê todos os repositórios do usuário 'Pauloxc6' para um array
    mapfile -t name_project < <(curl -s "https://api.github.com/search/repositories?q=owner:Pauloxc6"  | jq -r '.items[].name')

    # Solicita confirmação do usuário
    if [ -z "${sn}" ]; then read -rp $'\e[33;1mContinuar a instalação [s/n]: \e[0m' sn; fi

    if [ "${sn}" == "s" ]; then
        # Percorre a lista de repositórios e executa git pull nos que estiverem instalados localmente
        for name in "${name_project[@]}"; do
            local share_pkg="$HOME/.local/share/${name}"
            if [ -d "${share_pkg}" ]; then
                echo -e "${BLUE}[+] Atualizando o pacote: ${WHITE}${name}${RESET}"
                if [[ "$share_pkg" == "$HOME/.local/share/zoran" ]]; then curl -sfL "https://pauloxc6.github.io/welcome/install.sh" | sh; fi
                cd "${share_pkg}" || exit 1
                git pull 2>/dev/null | sed -e "s/Already\ up\ to\ date./Já\ está\ atualizado./g"
                cd - >/dev/null || exit 1
                echo
            fi
        done
    else
        echo -e "${GREEN}Saindo...${RESET}"
    fi

    echo -e "${GREEN}[+] Finalizando ${RESET}"
}

# ==============================================================================
# Função: __help__
# Descrição: Exibe a arte ASCII do menu e as instruções de uso do programa.
# ==============================================================================
function __help__(){
    echo -e "${RED}
  ___    ___
 ( _<    >_ )
 //        \\\\\\\\
 \\\\\\\\___..___//
  '-(    )-'
    _|__|_
   /_|__|_\\ 
   /_|__|_\\ 
   /_\\__/_\\ 
    \\ || /  _)
      ||   ( )
      \\\\\\\\___//
       '---'
${WHITE}
By: @Pauloxc6
Uso: zoran [opção] [comando] [argumento]

Opções: 
  ${YELLOW}-h, --help${RESET}       Exibe este menu de ajuda
  ${YELLOW}--version, --version${RESET}    Exibe a versão atual do sistema

${WHITE}Comandos: 
  ${BLUE}search <pacote>${RESET}     Procura por um pacote nos repositórios
  ${BLUE}install <pacote>${RESET}    Instala o pacote especificado
  ${BLUE}uninstall <pacote>${RESET}  Remove o pacote do sistema
  ${BLUE}update${RESET}              Atualiza todos os pacotes instalados
"
}

# ==============================================================================
# Lógica Principal / Processamento de Argumentos
# ==============================================================================

# Se nenhum parâmetro for passado, exibe o menu de ajuda e encerra
if [ -z "$1" ]; then __help__; exit 1 ; fi

# Loop para processar múltiplos argumentos informados via linha de comando
while [ "$#" -gt 0 ]; do
    case "$1" in
        "-h") __help__ ;;
        "-y") sn="s" ;;
        "--version") echo -e "${WHITE}Zoran | Version: 1.0${RESET}" ;;
        "search") shift   ; search "$1"      ;;
        "install") shift   ; install_pkg "$1" ;;
        "uninstall") shift ; uninstall_pkg "$1" ;;
        "update") shift ; update ;;
        *) echo -e "${RED}[!] Comando $1 não existe ${RESET}" ; __help__ ; exit 1 ;;
    esac
    shift
done

exit 0