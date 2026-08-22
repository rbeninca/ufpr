#!/usr/bin/env bash
# Script ultra simples para visualizar o stream ao vivo da câmera em uma janela

echo "🎥 Abrindo janela de visualização ao vivo..."
if command -v ffplay >/dev/null 2>&1; then
    ffplay -f v4l2 -input_format mjpeg -video_size 1280x720 -i /dev/video0 -window_title "Câmera USB Live" -loglevel quiet
elif command -v vlc >/dev/null 2>&1; then
    vlc v4l2:///dev/video0 --title "Câmera USB Live"
else
    echo "Abra o navegador em http://localhost:3001"
    node server.js
fi
