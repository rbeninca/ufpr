#!/usr/bin/env bash
# Script ultra simples para tirar foto da câmera USB (/dev/video0)
NOME_FOTO="foto_$(date +%Y%m%d_%H%M%S).jpg"

echo "📸 Capturando foto da câmera..."
ffmpeg -y -f v4l2 -input_format mjpeg -video_size 1280x720 -i /dev/video0 -vframes 1 "$NOME_FOTO" -loglevel error

if [ -f "$NOME_FOTO" ]; then
    echo "✅ Foto salva com sucesso em: $NOME_FOTO"
else
    echo "❌ Erro ao capturar a foto."
fi
