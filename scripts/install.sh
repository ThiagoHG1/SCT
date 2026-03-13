#!/bin/bash

BINARY_NAME="sct"
INSTALL_DIR="/usr/local/bin"

echo "Compilando $BINARY_NAME com otimizacao..."
zig build-exe src/main.zig -O ReleaseSmall --name sct

if [ $? -eq 0 ]; then
    echo "Compilacao concluida com sucesso."

    echo "Movendo para $INSTALL_DIR (pode pedir senha de sudo)..."
    sudo mv "./$BINARY_NAME" "$INSTALL_DIR/"

    if [ $? -eq 0 ]; then
        echo "Instalacao finalizada! Agora voce pode usar o comando '$BINARY_NAME'."
    else
        echo "Erro ao mover o binario. Verifique as permissoes."
        exit 1
    fi
else
    echo "Erro na compilacao. Certifique-se de que o zig esta instalado."
    exit 1
fi
