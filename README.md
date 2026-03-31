# SCT - Simple CLI Tool

SCT é um navegador e selecionador de arquivos interativo para o terminal, escrito em **Zig**. Filtre arquivos com busca fuzzy, navegue entre diretórios e abra arquivos com qualquer comando — tudo sem sair do terminal.

## Funcionalidades

- **Navegação de pastas** — `Enter` para entrar, `ESC` para voltar
- **Busca fuzzy em tempo real** — filtragem case-insensitive conforme você digita
- **Janela deslizante** — exibe até 20 arquivos por vez com indicadores de arquivos acima/abaixo
- **Execução de comandos** — abre o arquivo selecionado com o prefixo passado (ex: `sct nvim`)
- **Render diferencial** — redesenha apenas o que mudou, eliminando pisca mesmo no TTY puro
- **Raw mode** — captura de teclas instantânea sem necessidade de confirmar com Enter

## Estrutura do Projeto
```text
SCT
├── src
│   ├── utils
│   │   └── Print.zig   # Output bufferizado (flush único por frame)
│   ├── fs.zig          # Leitura de diretório e renderização da lista
│   ├── terminal.zig    # Raw mode do terminal
│   ├── Search.zig      # Lógica principal de busca, navegação e render
│   └── main.zig        # Ponto de entrada
└── scripts
    └── install.sh      # Compilação e instalação
```

## Instalação

Você precisará do [Zig](https://ziglang.org/) instalado (versão 0.15.x ou superior).
```bash
# Clone o repositório
git clone https://github.com/ThiagoHG1/SCT.git
cd SCT

# Dê permissão ao script
chmod +x scripts/install.sh

# Compile e instale
./scripts/install.sh
```

O script compila com otimização `ReleaseSmall` e move o binário para `/usr/local/bin/sct`.

## Como Usar
```bash
sct          # Navega e exibe o caminho do arquivo selecionado ao sair
sct nvim     # Abre o arquivo selecionado no Neovim
sct cat      # Exibe o conteúdo do arquivo no terminal
sct nano     # Edita o arquivo com nano
```

## Controles

| Tecla | Ação |
|---|---|
| Letras / Números | Filtra a lista em tempo real |
| `↑` / `↓` | Move o cursor entre os arquivos |
| `Enter` | Entra na pasta ou abre o arquivo com o comando |
| `ESC` | Volta para o diretório anterior |
| `Backspace` | Apaga um caractere da busca |
| `Ctrl+C` | Encerra o programa |

## Observações Técnicas

- Suporta até 1024 itens por diretório e nomes de até 256 caracteres
- A busca fuzzy ignora maiúsculas e minúsculas
- O raw mode é restaurado corretamente ao sair, inclusive após erros

> [!IMPORTANT]
> Recomenda-se utilizar commits a partir de **8a72e9a**.
> Versões anteriores continham uma falha no gerenciamento do raw mode do terminal que, em alguns casos, corrompía o estado do TTY e causava comportamentos inesperados em processos subsequentes que dependem de input do terminal muitas vezes não sendo corrigidos nem mesmo com reinicialização do SO.