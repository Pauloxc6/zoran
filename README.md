# Zoran 🚀

**Zoran** é um gerenciador de pacotes CLI simples e dinâmico construído em **Bash**, projetado para pesquisar, instalar, atualizar e remover ferramentas e repositórios mantidos pelo usuário `@Pauloxc6` via API do GitHub.

---

## ⚡ Instalação Rápida

Você pode instalar o **Zoran** diretamente via terminal através do site com o seguinte comando:

```bash
curl -sfL https://pauloxc6.github.io/welcome/install.sh | sh
```

## 📋 Pré-requisitos

Certifique-se de que seu sistema operacional possue as seguintes dependências instaladas:

- `bash`
- `curl`
- `jq`
- `git`
- `bc`

## 🛠️ Como Usar

A sintaxe geral do Zoran é:

```bash
zoran [opção] [comando] [argumento]
```

### Comandos Disponíveis

| Comando | Descrição | Exemplo |
| :--- | :--- | :--- |
| `search <pacote>` | Busca e exibe informações detalhadas de um pacote | `zoran search meu-projeto` |
| `install <pacote>` | Baixa e executa o script de instalação do pacote especificado | `zoran install meu-projeto` |
| `uninstall <pacote>`| Remove do sistema o pacote especificado | `zoran uninstall meu-projeto` |
| `update` | Atualiza via Git todos os pacotes previamente instalados | `zoran update` |

---

### Opções Globais

| Opção | Descrição | Exemplo |
| :--- | :--- | :--- |
| `-y` | Responde automaticamente "sim" (`s`) para todas as confirmações | `zoran -y install meu-projeto` |
| `-h, --help` | Exibe a interface gráfica ASCII e o menu de ajuda | `zoran -h` |
| `--version` | Exibe a versão atual do sistema Zoran | `zoran --version` |

---

**⚠️ Ponto de Atenção (Rate Limit do GitHub):**

>O comando search realiza requisições diretas à API pública do GitHub sem autenticação. A API do GitHub possui um limite de requisições por IP (Rate Limit de 60 requisições/hora para requisições não autenticadas). Caso muitas buscas sejam feitas em um curto período, a API pode bloquear temporariamente as respostas ou retornar dados vazios, fazendo com que o comando falhe.

## ⚙️ Como Funciona o Ciclo dos Pacotes

1. **`search`**: Faz uma requisição à API do GitHub e formata os dados do repositório (Nome, ID, URL, Tamanho em KB/MB, Data de Atualização e Licença).
2. **`install`**: Clona temporariamente o projeto em `/tmp/` e executa o script `install.sh` do próprio pacote se ele existir.
3. **`uninstall`**: Remove as pastas instaladas em `~/.local/share/<pacote>` e `~/.local/bin/<pacote>`.
4. **`update`**: Alterna por todos os repositórios em `~/.local/share/` e executa um `git pull` para trazer as últimas atualizações.

## 👤 Autor

Desenvolvido por **[@Pauloxc6](https://github.com/Pauloxc6)**.
