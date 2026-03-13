#!/bin/bash

BINARY_NAME="sct"
INSTALL_DIR="/usr/local/bin"

cd "$(dirname "$0")/.." || { echo "Falha ao mudar para a raiz do projeto"; exit 1; }

echo "Compilando $BINARY_NAME com otimização..."
zig build-exe src/main.zig -O ReleaseSmall --name "$BINARY_NAME"

if [ $? -eq 0 ]; then
    echo "Compilação concluída com sucesso."

    echo "Movendo para $INSTALL_DIR (pode pedir senha de sudo)..."
    sudo mv "./$BINARY_NAME" "$INSTALL_DIR/"

    if [ $? -eq 0 ]; then
        echo "Instalação finalizada! Agora você pode usar o comando '$BINARY_NAME'."
    else
        echo "Erro ao mover o binário. Verifique as permissões."
        exit 1
    fi
else
    echo "Erro na compilação. Certifique-se de que o Zig está instalado e o caminho src/main.zig existe."
    exit 1
fi
