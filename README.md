# SCT - Simple CLI Tool

SCT é um selecionador e navegador de arquivos interativo desenvolvido em **Zig**. Ele permite filtrar arquivos rapidamente via busca fuzzy, navegar entre diretórios e abrir arquivos com comandos específicos (como `nvim`, `nano`, `cat`) diretamente do terminal.

## 🚀 Funcionalidades

- **Navegação de Pastas:** `Enter` para entrar, `ESC` para voltar uma pasta.
- **Busca Rápida:** Filtro em tempo real (case-insensitive) conforme você digita.
- **Execução de Comandos:** Abre o arquivo selecionado usando o prefixo passado (ex: `sct nvim`).
- **Raw Mode:** Captura de teclas instantânea, sem necessidade de confirmar com Enter para filtrar.
- **Interface Visual:** Cores para diferenciar diretórios e exibição do caminho atual (CWD).

## 📂 Estrutura do Projeto

```text
SCT
├── src
│   ├── main.zig    # Ponto de entrada
│   ├── Search.zig  # Lógica de busca e navegação
│   └── Utils.zig   # Utilitários de print e formatação
└── scripts
    └── install.sh  # Script de compilação e instalação

## 🛠️ Instalação

Você precisará do Zig instalado (testado com a versão 0.15.0 ou superior).

# Clone o repositório
git clone [https://github.com/ThiagoHG1/SCT.git](https://github.com/ThiagoHG1/SCT.git)
cd SCT

# Garanta que o script de instalação tenha permissão
chmod +x scripts/install.sh

# Execute a instalação
./scripts/install.sh

O script irá compilar o binário com otimização (ReleaseSmall) e movê-lo para /usr/local/bin/sct.

## 💡 Como Usar

Exemplos de Comandos

sct          # Apenas navega e mostra o caminho do arquivo ao sair
sct nvim     # Busca um arquivo e abre diretamente no Neovim
sct cat      # Busca um arquivo e exibe o conteúdo no terminal

## Controles de Teclado
Tecla	Ação
Letras/Números	Digite para filtrar a lista em tempo real.
Enter	Entra em uma pasta ou seleciona o arquivo para abrir com o comando.
ESC	Volta para o diretório anterior (..).
Backspace	Apaga um caractere (Em versões anteriores volta uma pasta assim como ESC).
Ctrl + C	Encerra o programa e volta ao terminal.

## ⚠️ Observações Técnicas

    Limites: Suporta até 1024 itens por diretório e nomes de arquivos com até 256 caracteres.

    Fuzzy Match: A busca ignora maiúsculas/minúsculas para facilitar a digitação rápida.

    Raw Mode: O programa desativa o modo canônico do terminal para processar teclas individualmente, restaurando as configurações originais ao sair.

> [!IMPORTANT]
> Recomenda-se utilizar commits a partir de **8a72e9a**.  
> Versões anteriores podem causar problemas no TTY, como travamentos ou falhas ao digitar a senha no `sudo`.

