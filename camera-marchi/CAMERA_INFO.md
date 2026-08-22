# Documentação da Câmera USB & Métodos de Acesso

## 1. Identificação do Dispositivo Câmera

A mini câmera USB foi detectada e identificada com sucesso no sistema Linux:

- **Nome do Dispositivo / Produto**: HD User Facing Camera
- **Fabricante / Vendor**: SunplusIT, Inc. / Quanta Computer, Inc.
- **ID USB (VID:PID)**: `0408:a061`
- **Revisão USB**: `0004`
- **Barramento / Porta USB**: Bus `001`, Porta `005` (Dispositivo `006`, alta velocidade 480 Mbps)
- **Driver Linux**: `uvcvideo` (Driver padrão USB Video Class integrado ao Kernel Linux)
- **Nós de Dispositivo V4L2 (Video4Linux2)**:
  - `/dev/video0` *(Dispositivo principal de captura de vídeo)*
  - `/dev/video1` *(Nó de metadados / sinalização V4L2)*
- **Caminho Simbólico Único**:
  - `/dev/v4l/by-id/usb-SunplusIT_Inc_HD_User_Facing-video-index0`

---

## 2. Formatos e Resoluções Suportadas

A câmera fornece captura em dois formatos principais:

1. **MJPEG (Motion-JPEG)**:
   - `1280x720` (720p HD) @ até 30 fps
   - `640x480` (VGA) @ até 30 fps
   - `640x360` @ até 30 fps

2. **YUYV 4:2:2 (Uncompressed Raw)**:
   - `1280x720` @ até 30 fps
   - `640x480` @ até 30 fps
   - `640x360` @ até 30 fps

---

## 3. Métodos de Acesso ao Dispositivo

### A. Acesso Direto via Navegador Web (HTML5 API)
Os navegadores web modernos (Chrome, Firefox, Edge, Opera) possuem suporte nativo a câmeras UVC via **WebRTC / MediaDevices API**:
```javascript
// Exemplo JavaScript client-side
navigator.mediaDevices.getUserMedia({
    video: {
        width: { ideal: 1280 },
        height: { ideal: 720 }
    }
})
.then(stream => {
    videoElement.srcObject = stream;
})
.catch(err => console.error("Erro ao acessar câmera:", err));
```

### B. Acesso via Servidor Web Streamer (Node.js / Python + FFmpeg)
Se a aplicação precisar transmitir o vídeo em rede local/remota ou processar frames no backend:
- O backend abre `/dev/video0` usando `ffmpeg` ou OpenCV.
- Serve um fluxo **MJPEG HTTP** (ex: `http://localhost:3000/video_feed`) ou WebRTC.

### C. Acesso via Linha de Comando (CLI / Terminal)
- **Capturar uma foto com FFmpeg**:
  ```bash
  ffmpeg -y -f v4l2 -input_format mjpeg -video_size 1280x720 -i /dev/video0 -vframes 1 foto.jpg
  ```
- **Visualizar stream com MPV**:
  ```bash
  mpv /dev/video0
  ```
- **Visualizar stream com VLC**:
  ```bash
  vlc v4l2:///dev/video0
  ```

---

## 4. Aplicação Web Desenvolvida nesta Pasta

Criamos nesta pasta uma aplicação web completa e interativa para controle e transmissão da câmera.

### Recursos da Aplicação:
1. **Modo WebRTC Direto (Client-Side)**: Visualização em tempo real sem latência, ajuste de resolução (720p, 480p, 360p), controle de espelhamento, gravação de vídeos `.webm` e fotos em alta resolução.
2. **Modo Backend Streamer (MJPEG HTTP Server)**: Transmissão ao vivo via servidor Node.js + FFmpeg na rota `/video_feed` e endpoint de fotos `/snapshot`.
3. **Diagnósticos e Informações do Dispositivo**: Painel com métricas de FPS, resolução ativa, status do driver `uvcvideo` e detalhes do hardware.

---

## 5. Scripts Shell Prontos (Execução Rápida via Terminal)

Além da aplicação web, foram criados scripts Shell muito simples e prontos para uso direto no terminal usando `ffmpeg` e `ffplay`:

1. **Menu Interativo**:
   ```bash
   ./menu_camera.sh
   ```
2. **Visualizar Imagem ao Vivo em Janela (ffplay/vlc)**:
   ```bash
   ./ver_camera.sh
   ```
3. **Tirar Foto Instantânea**:
   ```bash
   ./tirar_foto.sh
   ```
4. **Gravar Vídeo de N Segundos**:
   ```bash
   ./gravar_video.sh 10
   ```

