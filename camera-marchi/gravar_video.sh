#!/usr/bin/env bash
# Script ultra simples para gravar um vídeo da câmera USB
DURACAO=${1:-10}
NOME_VIDEO="video_$(date +%Y%m%d_%H%M%S).mp4"

echo "🎥 Gravando $DURACAO segundos de vídeo da câmera..."
ffmpeg -y -f v4l2 -input_format mjpeg -video_size 1280x720 -i /dev/video0 -t "$DURACAO" -c:v copy "$NOME_VIDEO" -loglevel error

if [ -f "$NOME_VIDEO" ]; then
    echo "✅ Vídeo salvo com sucesso em: $NOME_VIDEO"
else
    echo "❌ Erro ao gravar o vídeo."
fi
