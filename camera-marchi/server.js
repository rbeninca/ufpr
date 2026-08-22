const express = require('express');
const cors = require('cors');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Helper to get system camera info
function getCameraInfo() {
  const deviceExists = fs.existsSync('/dev/video0');
  let udevDetails = {};

  if (deviceExists) {
    try {
      const udevOutput = execSync('udevadm info --query=all --name=/dev/video0', { encoding: 'utf8' });
      udevOutput.split('\n').forEach(line => {
        if (line.startsWith('E: ID_VENDOR=')) udevDetails.vendor = line.split('=')[1];
        if (line.startsWith('E: ID_MODEL=')) udevDetails.model = line.split('=')[1];
        if (line.startsWith('E: ID_VENDOR_ID=')) udevDetails.vendorId = line.split('=')[1];
        if (line.startsWith('E: ID_MODEL_ID=')) udevDetails.modelId = line.split('=')[1];
        if (line.startsWith('E: ID_USB_DRIVER=')) udevDetails.driver = line.split('=')[1];
      });
    } catch (err) {
      console.error('Erro ao ler udevadm:', err.message);
    }
  }

  return {
    device: '/dev/video0',
    status: deviceExists ? 'Conectada e Pronta' : 'Não Encontrada',
    vendor: udevDetails.vendor || 'SunplusIT_Inc',
    model: udevDetails.model || 'HD_User_Facing',
    vendorId: udevDetails.vendorId || '0408',
    modelId: udevDetails.modelId || 'a061',
    driver: udevDetails.driver || 'uvcvideo',
    resolutions: [
      { width: 1280, height: 720, label: '1280x720 (HD 720p)' },
      { width: 640, height: 480, label: '640x480 (VGA 4:3)' },
      { width: 640, height: 360, label: '640x360 (nHD 16:9)' }
    ],
    formats: ['MJPEG', 'YUYV 4:2:2']
  };
}

// Route: Camera Information
app.get('/api/camera/info', (req, res) => {
  res.json(getCameraInfo());
});

// Route: Single Frame Snapshot via FFmpeg
app.get('/api/camera/snapshot', (req, res) => {
  if (!fs.existsSync('/dev/video0')) {
    return res.status(404).json({ error: 'Dispositivo /dev/video0 não encontrado.' });
  }

  const ffmpeg = spawn('ffmpeg', [
    '-y',
    '-f', 'v4l2',
    '-input_format', 'mjpeg',
    '-video_size', '1280x720',
    '-i', '/dev/video0',
    '-vframes', '1',
    '-f', 'image2',
    '-'
  ]);

  const chunks = [];
  ffmpeg.stdout.on('data', (chunk) => chunks.push(chunk));
  
  ffmpeg.on('close', (code) => {
    if (code === 0 && chunks.length > 0) {
      const imgBuffer = Buffer.concat(chunks);
      res.writeHead(200, {
        'Content-Type': 'image/jpeg',
        'Content-Length': imgBuffer.length,
        'Cache-Control': 'no-cache'
      });
      res.end(imgBuffer);
    } else {
      res.status(500).json({ error: 'Falha ao capturar imagem da câmera com FFmpeg.' });
    }
  });

  ffmpeg.on('error', (err) => {
    console.error('FFmpeg snapshot error:', err);
    if (!res.headersSent) {
      res.status(500).json({ error: err.message });
    }
  });
});

// Route: Live MJPEG Video Stream Server
let activeMjpegStreams = 0;

app.get('/api/camera/mjpeg', (req, res) => {
  if (!fs.existsSync('/dev/video0')) {
    return res.status(404).send('Dispositivo /dev/video0 não encontrado.');
  }

  res.writeHead(200, {
    'Content-Type': 'multipart/x-mixed-replace; boundary=ffmpeg-boundary',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Connection': 'close'
  });

  activeMjpegStreams++;
  console.log(`[MJPEG] Novo cliente conectado. Total: ${activeMjpegStreams}`);

  const ffmpeg = spawn('ffmpeg', [
    '-f', 'v4l2',
    '-input_format', 'mjpeg',
    '-video_size', '640x360',
    '-framerate', '30',
    '-i', '/dev/video0',
    '-c:v', 'copy',
    '-f', 'mpjpeg',
    '-boundary_tag', 'ffmpeg-boundary',
    '-'
  ]);

  ffmpeg.stdout.pipe(res);

  const cleanup = () => {
    activeMjpegStreams = Math.max(0, activeMjpegStreams - 1);
    console.log(`[MJPEG] Cliente desconectado. Restantes: ${activeMjpegStreams}`);
    ffmpeg.kill('SIGINT');
  };

  req.on('close', cleanup);
  req.on('end', cleanup);
  ffmpeg.on('error', (err) => {
    console.error('[MJPEG FFmpeg Error]', err.message);
    cleanup();
  });
});

function startServer(port) {
  const server = app.listen(port, () => {
    console.log(`=======================================================`);
    console.log(`   Câmera Web App rodando em http://localhost:${port}`);
    console.log(`   Dispositivo detectado: /dev/video0`);
    console.log(`=======================================================`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`Porta ${port} ocupada, tentando porta ${port + 1}...`);
      startServer(port + 1);
    } else {
      console.error('Erro no servidor:', err);
    }
  });
}

startServer(PORT);

