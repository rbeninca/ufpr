document.addEventListener('DOMContentLoaded', () => {
  // DOM Elements
  const videoElem = document.getElementById('webcam-video');
  const mjpegImg = document.getElementById('mjpeg-img');
  const videoViewport = document.getElementById('video-viewport');
  const flashOverlay = document.getElementById('flash-overlay');
  
  // Status & Badges
  const statusChip = document.getElementById('status-chip');
  const statusText = document.getElementById('status-text');
  const fpsBadge = document.getElementById('fps-badge');
  const resBadge = document.getElementById('res-badge');
  
  // Mode Tabs
  const modeWebRtcBtn = document.getElementById('mode-webrtc-btn');
  const modeMjpegBtn = document.getElementById('mode-mjpeg-btn');
  
  // Controls
  const btnSnapshot = document.getElementById('btn-snapshot');
  const btnRecord = document.getElementById('btn-record');
  const recordBtnText = document.getElementById('record-btn-text');
  const recOverlay = document.getElementById('rec-overlay');
  const recTimer = document.getElementById('rec-timer');
  const resolutionSelect = document.getElementById('resolution-select');
  const filterSelect = document.getElementById('filter-select');
  const btnFullscreen = document.getElementById('btn-fullscreen');
  const btnMirror = document.getElementById('btn-mirror');
  
  // Range Sliders
  const sliderBrightness = document.getElementById('slider-brightness');
  const sliderContrast = document.getElementById('slider-contrast');
  const sliderSaturate = document.getElementById('slider-saturate');
  const valBrightness = document.getElementById('val-brightness');
  const valContrast = document.getElementById('val-contrast');
  const valSaturate = document.getElementById('val-saturate');
  const btnResetFilters = document.getElementById('btn-reset-filters');
  
  // Gallery
  const galleryGrid = document.getElementById('gallery-grid');
  const emptyGallery = document.getElementById('empty-gallery');
  const galleryCount = document.getElementById('gallery-count');
  
  // App State
  let currentMode = 'webrtc'; // 'webrtc' | 'mjpeg'
  let mediaStream = null;
  let mediaRecorder = null;
  let recordedChunks = [];
  let isRecording = false;
  let recordStartTime = 0;
  let recordTimerInterval = null;
  let isFlipped = false;
  let galleryItems = [];
  
  // FPS Tracking
  let frameCount = 0;
  let lastFpsCalcTime = performance.now();

  // 1. Fetch System Camera Info
  async function loadCameraInfo() {
    try {
      const response = await fetch('/api/camera/info');
      const data = await response.json();
      
      if (data.status === 'Conectada e Pronta') {
        statusText.textContent = 'Câmera Ativa & Conectada';
        statusChip.style.background = 'rgba(16, 185, 129, 0.12)';
      } else {
        statusText.textContent = 'Dispositivo Indisponível';
        statusChip.style.background = 'rgba(239, 68, 68, 0.12)';
        statusChip.style.color = '#ef4444';
      }

      document.getElementById('info-vendor').textContent = data.vendor || 'SunplusIT, Inc.';
      document.getElementById('info-model').textContent = data.model || 'HD User Facing';
      document.getElementById('info-vidpid').textContent = `${data.vendorId}:${data.modelId}`;
      document.getElementById('info-driver').textContent = data.driver || 'uvcvideo';
      document.getElementById('info-node').textContent = data.device || '/dev/video0';
    } catch (err) {
      console.error('Erro ao buscar dados da câmera:', err);
      statusText.textContent = 'Erro de Comunicação Backend';
    }
  }

  // 2. Start WebRTC Direct Camera Stream
  async function startWebRTCStream(width = 1280, height = 720) {
    stopWebRTCStream();
    
    try {
      const constraints = {
        video: {
          width: { ideal: width },
          height: { ideal: height },
          frameRate: { ideal: 30 }
        },
        audio: false
      };
      
      mediaStream = await navigator.mediaDevices.getUserMedia(constraints);
      videoElem.srcObject = mediaStream;
      videoElem.style.display = 'block';
      mjpegImg.style.display = 'none';
      
      videoElem.onloadedmetadata = () => {
        resBadge.textContent = `${videoElem.videoWidth}x${videoElem.videoHeight}`;
      };

      startFpsCounter();
    } catch (err) {
      console.warn('Falha no WebRTC direto:', err);
      alert('Permissão de câmera negada no navegador ou câmera ocupada por outro processo. Alternando para o modo Servidor MJPEG.');
      switchMode('mjpeg');
    }
  }

  function stopWebRTCStream() {
    if (mediaStream) {
      mediaStream.getTracks().forEach(track => track.stop());
      mediaStream = null;
    }
    videoElem.srcObject = null;
  }

  // 3. Start MJPEG Stream
  function startMJPEGStream() {
    stopWebRTCStream();
    videoElem.style.display = 'none';
    mjpegImg.style.display = 'block';
    mjpegImg.src = `/api/camera/mjpeg?t=${Date.now()}`;
    resBadge.textContent = '640x360 (MJPEG)';
    fpsBadge.textContent = '30 FPS';
  }

  // Switch Stream Modes
  function switchMode(mode) {
    currentMode = mode;
    if (mode === 'webrtc') {
      modeWebRtcBtn.classList.add('active');
      modeMjpegBtn.classList.remove('active');
      const [w, h] = resolutionSelect.value.split('x').map(Number);
      startWebRTCStream(w, h);
    } else {
      modeMjpegBtn.classList.add('active');
      modeWebRtcBtn.classList.remove('active');
      startMJPEGStream();
    }
  }

  modeWebRtcBtn.addEventListener('click', () => switchMode('webrtc'));
  modeMjpegBtn.addEventListener('click', () => switchMode('mjpeg'));

  // 4. Resolution Switcher
  resolutionSelect.addEventListener('change', (e) => {
    if (currentMode === 'webrtc') {
      const [w, h] = e.target.value.split('x').map(Number);
      startWebRTCStream(w, h);
    }
  });

  // 5. FPS Counter Calculation
  function startFpsCounter() {
    function calcFps() {
      if (currentMode !== 'webrtc' || !mediaStream) return;
      frameCount++;
      const now = performance.now();
      if (now - lastFpsCalcTime >= 1000) {
        const fps = Math.round((frameCount * 1000) / (now - lastFpsCalcTime));
        fpsBadge.textContent = `${fps} FPS`;
        frameCount = 0;
        lastFpsCalcTime = now;
      }
      requestAnimationFrame(calcFps);
    }
    requestAnimationFrame(calcFps);
  }

  // 6. Snapshot Capture
  btnSnapshot.addEventListener('click', captureSnapshot);

  async function captureSnapshot() {
    // Flash Animation
    flashOverlay.classList.add('active');
    setTimeout(() => flashOverlay.classList.remove('active'), 150);

    let dataUrl = '';
    const timestamp = new Date().toLocaleTimeString();

    if (currentMode === 'webrtc' && videoElem.videoWidth) {
      const canvas = document.createElement('canvas');
      canvas.width = videoElem.videoWidth;
      canvas.height = videoElem.videoHeight;
      const ctx = canvas.getContext('2d');
      
      if (isFlipped) {
        ctx.translate(canvas.width, 0);
        ctx.scale(-1, 1);
      }
      
      // Apply filters to canvas if set
      ctx.filter = buildCssFilterString();
      ctx.drawImage(videoElem, 0, 0, canvas.width, canvas.height);
      dataUrl = canvas.toDataURL('image/jpeg', 0.95);
    } else {
      // Backend Snapshot API
      try {
        const res = await fetch('/api/camera/snapshot');
        const blob = await res.blob();
        dataUrl = URL.createObjectURL(blob);
      } catch (err) {
        alert('Erro ao capturar foto do backend.');
        return;
      }
    }

    addMediaToGallery({
      type: 'image',
      url: dataUrl,
      title: `Foto ${timestamp}`,
      filename: `camera_foto_${Date.now()}.jpg`
    });
  }

  // 7. Video Recording (MediaRecorder API)
  btnRecord.addEventListener('click', toggleRecording);

  function toggleRecording() {
    if (!isRecording) {
      startRecording();
    } else {
      stopRecording();
    }
  }

  function startRecording() {
    if (currentMode !== 'webrtc' || !mediaStream) {
      alert('A gravação de vídeo por esta interface requer o modo "Navegador Direto (WebRTC)".');
      return;
    }

    recordedChunks = [];
    try {
      mediaRecorder = new MediaRecorder(mediaStream, { mimeType: 'video/webm;codecs=vp9' });
    } catch (e) {
      mediaRecorder = new MediaRecorder(mediaStream, { mimeType: 'video/webm' });
    }

    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        recordedChunks.push(event.data);
      }
    };

    mediaRecorder.onstop = () => {
      const blob = new Blob(recordedChunks, { type: 'video/webm' });
      const videoUrl = URL.createObjectURL(blob);
      const timestamp = new Date().toLocaleTimeString();
      addMediaToGallery({
        type: 'video',
        url: videoUrl,
        title: `Vídeo ${timestamp}`,
        filename: `camera_video_${Date.now()}.webm`
      });
    };

    mediaRecorder.start(100);
    isRecording = true;
    btnRecord.classList.add('recording');
    recordBtnText.textContent = 'Parar Gravação';
    recOverlay.classList.add('active');

    recordStartTime = Date.now();
    recordTimerInterval = setInterval(updateRecTimer, 1000);
    updateRecTimer();
  }

  function stopRecording() {
    if (mediaRecorder && isRecording) {
      mediaRecorder.stop();
      isRecording = false;
      btnRecord.classList.remove('recording');
      recordBtnText.textContent = 'Iniciar Gravação';
      recOverlay.classList.remove('active');
      clearInterval(recordTimerInterval);
    }
  }

  function updateRecTimer() {
    const elapsedSec = Math.floor((Date.now() - recordStartTime) / 1000);
    const m = String(Math.floor(elapsedSec / 60)).padStart(2, '0');
    const s = String(elapsedSec % 60).padStart(2, '0');
    recTimer.textContent = `${m}:${s}`;
  }

  // 8. Filters & Adjustments
  function buildCssFilterString() {
    const b = sliderBrightness.value;
    const c = sliderContrast.value;
    const s = sliderSaturate.value;
    const filterPreset = filterSelect.value;
    
    let base = `brightness(${b}%) contrast(${c}%) saturate(${s}%)`;
    if (filterPreset === 'grayscale') base += ' grayscale(100%)';
    if (filterPreset === 'sepia') base += ' sepia(100%)';
    if (filterPreset === 'contrast') base += ' contrast(200%)';
    if (filterPreset === 'invert') base += ' invert(100%)';
    if (filterPreset === 'nightvision') base += ' hue-rotate(90deg) contrast(150%) brightness(120%)';

    return base;
  }

  function applyFilters() {
    const filterStr = buildCssFilterString();
    videoElem.style.filter = filterStr;
    mjpegImg.style.filter = filterStr;
    
    valBrightness.textContent = `${sliderBrightness.value}%`;
    valContrast.textContent = `${sliderContrast.value}%`;
    valSaturate.textContent = `${sliderSaturate.value}%`;
  }

  sliderBrightness.addEventListener('input', applyFilters);
  sliderContrast.addEventListener('input', applyFilters);
  sliderSaturate.addEventListener('input', applyFilters);
  filterSelect.addEventListener('change', applyFilters);

  btnResetFilters.addEventListener('click', () => {
    sliderBrightness.value = 100;
    sliderContrast.value = 100;
    sliderSaturate.value = 100;
    filterSelect.value = 'none';
    applyFilters();
  });

  // Mirror (Flip Horizontal)
  btnMirror.addEventListener('click', () => {
    isFlipped = !isFlipped;
    videoViewport.classList.toggle('flipped', isFlipped);
  });

  // Fullscreen Toggle
  btnFullscreen.addEventListener('click', () => {
    if (!document.fullscreenElement) {
      videoViewport.requestFullscreen().catch(err => console.error(err));
    } else {
      document.exitFullscreen();
    }
  });

  // 9. Gallery Handling
  function addMediaToGallery(item) {
    galleryItems.unshift(item);
    renderGallery();
  }

  function renderGallery() {
    galleryCount.textContent = galleryItems.length;
    if (galleryItems.length === 0) {
      emptyGallery.style.display = 'flex';
      return;
    }
    emptyGallery.style.display = 'none';

    // Remove existing card elements (keep empty gallery placeholder)
    const cards = galleryGrid.querySelectorAll('.gallery-card');
    cards.forEach(card => card.remove());

    galleryItems.forEach((item, index) => {
      const card = document.createElement('div');
      card.className = 'gallery-card';

      let mediaHtml = '';
      if (item.type === 'image') {
        mediaHtml = `<img src="${item.url}" alt="${item.title}">`;
      } else {
        mediaHtml = `<video src="${item.url}" controls></video>`;
      }

      card.innerHTML = `
        ${mediaHtml}
        <div class="gallery-card-info">
          <span>${item.title}</span>
          <div class="gallery-actions">
            <a href="${item.url}" download="${item.filename}" class="btn-icon-sm" title="Baixar Arquivo">💾 Baixar</a>
            <button class="btn-icon-sm delete" data-index="${index}" title="Excluir">🗑️</button>
          </div>
        </div>
      `;

      card.querySelector('.delete').addEventListener('click', () => {
        galleryItems.splice(index, 1);
        renderGallery();
      });

      galleryGrid.appendChild(card);
    });
  }

  // 10. Secondary Tabs Navigation
  const secTabs = document.querySelectorAll('.sec-tab');
  secTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      secTabs.forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.sec-tab-content').forEach(c => c.classList.remove('active'));

      tab.classList.add('active');
      const targetId = `sec-${tab.dataset.sectab}`;
      document.getElementById(targetId).classList.add('active');
    });
  });

  // Initialize
  loadCameraInfo();
  startWebRTCStream(1280, 720);
});
