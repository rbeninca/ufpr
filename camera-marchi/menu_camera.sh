#!/usr/bin/env bash
# Menu Interativo para Câmera USB

while true; do
    echo ""
    echo "=========================================="
    echo "       📹 MENU DA CÂMERA USB LINUX"
    echo "=========================================="
    echo " 1) 🎥 Visualizar imagem ao vivo em Janela (ffplay)"
    echo " 2) 📸 Tirar uma Foto instantânea"
    echo " 3) 🎬 Gravar 10 segundos de vídeo"
    echo " 4) 🌐 Iniciar Servidor Web (Navegador)"
    echo " 5) 🚪 Sair"
    echo "=========================================="
    read -p "Escolha uma opção (1-5): " OPCAO

    case $OPCAO in
        1)
            ./ver_camera.sh
            ;;
        2)
            ./tirar_foto.sh
            ;;
        3)
            read -p "Digite a duração em segundos (Padrão 10): " SECS
            SECS=${SECS:-10}
            ./gravar_video.sh "$SECS"
            ;;
        4)
            echo "Iniciando servidor web..."
            echo "Abra o seu navegador em http://localhost:3001"
            node server.js
            ;;
        5)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done
