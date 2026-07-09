# Relatório de Configuração — Impressoras 3D / Klipper / OctoPrint

Data: 2026-06-25
Autor da execução: assistente (via SSH a partir do PC `rbeninca`)

Este documento descreve **tudo que foi configurado** em duas máquinas:

1. **192.168.1.251** — Raspberry Pi (OctoPi) com Klipper/Mainsail: reativação do OctoPrint.
2. **192.168.1.101** — TV Box Amlogic S905X (Armbian) com stack Klipper + Moonraker + Mainsail em Docker para uma Creality CR10.

---

## Parte 1 — Reativar OctoPrint no OctoPi (192.168.1.251)

**Usuário:** `pi` / senha `raspberry`

### Situação inicial
- Klipper + Moonraker + Mainsail (nginx) funcionando; a impressora migrou para Klipper.
- OctoPrint estava forçado em `127.0.0.1:5000` e desejava-se levá-lo para a rede em `:8080`.
- Webcam (`mjpg_streamer`) deveria ir para `:8081`.

### Problemas encontrados
1. **Override do systemd nunca foi salvo** — `/etc/systemd/system/octoprint.service.d/` não existia; o `systemctl edit` anterior não gravou. O serviço seguia com `Environment="HOST=127.0.0.1"` e `PORT=5000`.
2. **Webcam ainda em `:8080`** (mudança anterior não persistiu) — conflitaria com o OctoPrint.
3. **Mainsail acessa a webcam via nginx** (`/webcam/` → upstream `mjpgstreamer1` → `127.0.0.1:8080`); mover a câmera quebraria o Mainsail se o nginx não fosse atualizado.

### O que foi feito
- Criado `/etc/systemd/system/octoprint.service.d/override.conf`:
  ```ini
  [Service]
  Environment="HOST=0.0.0.0"
  Environment="PORT=8080"
  ```
- Webcam movida para 8081 em `/boot/octopi.txt`:
  ```
  camera_http_options="-n --listen 127.0.0.1 -p 8081"
  ```
- nginx `upstream mjpgstreamer1` atualizado para `127.0.0.1:8081` em `/etc/nginx/conf.d/upstreams.conf`.
- `~/.octoprint/config.yaml` apontado para a **porta serial virtual do Klipper** (o OctoPrint não acessa a USB direto):
  ```yaml
  serial:
    port: /home/pi/printer_data/comms/klippy.serial
    baudrate: 250000
    autoconnect: true
    additionalPorts:
    - /home/pi/printer_data/comms/klippy.serial
  ```
- `daemon-reload`, restart de `octoprint`, `webcamd` e reload do `nginx`.

### Resultado
| Serviço | Endereço | Status |
|---|---|---|
| OctoPrint | `0.0.0.0:8080` | OK, conectado ao Klipper (firmware "Klipper", estado Operational) |
| Mainsail/nginx | `0.0.0.0:80` | OK |
| Webcam | `127.0.0.1:8081` (via `/webcam/`) | OK |
| Porta 5000 | — | desativada |

**Backups:** `config.yaml.bak.*`, `octopi.txt.bak.*`, `upstreams.conf.bak.*`.

> ⚠️ OctoPrint e Moonraker apontam para o mesmo Klipper. Não enviar comandos/impressões pelos dois ao mesmo tempo.

---

## Parte 2 — Stack Klipper/Moonraker/Mainsail em Docker no TV Box (192.168.1.101)

**Usuários:** `root` / `rbeninca`, senha `aluno123`

### Características do dispositivo
- SoC Amlogic S905X, **aarch64** (Cortex-A53), Armbian Noble (base Ubuntu 24.04), kernel 6.18.
- RAM 914 MB + 457 MB swap (apertado).
- eMMC raiz (`/dev/mmcblk1p2`): 5.7 G, só **1.1 G livre** (83% usado).
- Docker 29.4.1 + Compose v5.1.3 já instalados.
- Armazenamento externo (ambos FAT32, desmontados): **pendrive 28.9 G** (`sda1`, dados pessoais — não tocado) e **microSD 14.8 G** (`mmcblk0p1`).
- Impressora detectada: CH340 em `/dev/ttyUSB0` → `usb-1a86_USB_Serial-if00-port0`.

### Decisões
- Usar o **microSD** para tudo (reformatado em **ext4**), pois FAT32 não suporta sockets Unix do Klipper nem overlay2 do Docker, e a eMMC tem pouco espaço.
- Mover o **data-root do Docker** para o microSD.
- g-codes armazenados no microSD via bind-mount.

### Passos executados
1. **Backup** dos 2 arquivos do microSD em `/root/microsd-backup/` (`firmware.bin`, `printer-ender3v2-bltouch-inicial.cfg`).
2. **microSD → ext4**, label `printerdata`, montado em `/mnt/data`, fixado no `/etc/fstab` por UUID com `defaults,noatime,nofail`.
3. **Docker data-root** movido para `/mnt/data/docker` via `/etc/docker/daemon.json`:
   ```json
   {
     "data-root": "/mnt/data/docker",
     "log-driver": "json-file",
     "log-opts": { "max-size": "10m", "max-file": "3" },
     "storage-driver": "overlay2",
     "max-concurrent-downloads": 1,
     "max-concurrent-uploads": 1
   }
   ```
4. **Stack minimalista** baseada no projeto [prind](https://github.com/mkuf/prind) em `/mnt/data/prind/`, só com `klipper + moonraker + mainsail + traefik + init` (imagens multi-arch pré-compiladas, sem build no box). g-codes em bind-mount `/mnt/data/gcodes`.
5. **Problema de rede no `docker pull`:** TLS handshake timeout (o daemon escolhia IPv6 instável). Resolvido limitando downloads concorrentes a 1 e **fixando IPv4 do Docker Hub no `/etc/hosts`**:
   ```
   3.224.9.179    registry-1.docker.io
   172.64.144.78  auth.docker.io
   104.16.98.215  production.cloudflare.docker.com
   54.224.198.86  index.docker.io
   ```
6. **printer.cfg:** os logs mostraram `freq=72 MHz` → a placa **não** é Melzi AVR e sim **STM32F103 (Creality 4.2.2)**, com firmware Klipper já gravado. A placa veio de uma Ender3 v2 mas será usada numa **CR10**, então a config foi escrita para **CR10 (300×300×400) com BLTouch** e pinos STM32.
7. **Correções finais:** `FIRMWARE_RESTART` (saiu de shutdown); porta do Mainsail no traefik corrigida de 80 → **8080** (porta real da imagem `mainsail:latest`).

### Resultado
| Componente | Estado |
|---|---|
| Mainsail | `http://192.168.1.101` (porta 80) — HTTP 200 |
| Moonraker | rodando (via traefik) |
| Klipper | **ready**, MCU conectado, temperaturas reais |
| g-codes | `/mnt/data/gcodes` (microSD) |
| Docker | data-root em `/mnt/data/docker`, habilitado no boot |
| eMMC raiz | intocada (~1.1 G livre) |

### Layout de arquivos no box
```
/mnt/data/                 (microSD ext4, 14 G)
├── docker/                (imagens/volumes Docker)
├── gcodes/                (g-codes — bind mount)
└── prind/
    ├── docker-compose.yaml
    └── config/
        ├── printer.cfg     (CR10 + BLTouch, pinos STM32F103/Creality 4.2.2)
        ├── mainsail.cfg
        └── moonraker.conf
```

Comandos úteis (no box, em `/mnt/data/prind`):
```bash
docker compose --profile mainsail up -d     # subir/atualizar
docker compose --profile mainsail ps        # status
docker compose logs -f klipper              # logs
```

---

## Parte 3 — Firmware da CR10 (placa Creality 4.2.2 / STM32F103)

- Versão do Klipper no host (container): **v0.13.0-699-gc707dd192**.
- Firmware compilado no PC (via container Docker, sem instalar toolchain no host), no mesmo commit `c707dd192`.
- Configuração de build (Creality 4.2.2):
  - Micro-controller: STM32F103
  - Bootloader offset: **28 KiB** (`0x7000`)
  - Clock de referência: **8 MHz** (cristal)
  - Comunicação: **Serial USART1 (PA10/PA9)**, baud 250000
- Saída: `firmware-cr10/` (arquivo `.bin` para flash via cartão SD).

### Como gravar na CR10
1. Copiar o `.bin` para a **raiz de um cartão microSD** formatado em FAT32 (tamanho da unidade de alocação 4096).
2. O arquivo precisa ter um **nome diferente** do último gravado (o bootloader da Creality ignora nomes repetidos). Renomeie se necessário.
3. Inserir na impressora **desligada**, ligar e aguardar ~10 s. A tela fica preta durante o flash.
4. Conferir no Mainsail que o MCU reconecta (estado "ready") após `FIRMWARE_RESTART`.

> ⚠️ Enquanto a placa estiver fisicamente na **Ender3 v2**, NÃO enviar movimentos com a config de CR10 (mesa 300×300) — risco de colisão. Ao montar na CR10, ajustar offsets X/Y do BLTouch, rodar `PROBE_CALIBRATE` (z_offset) e refazer o PID tune.

---

## Parte 4 — Segunda impressora: CR-10 V2 (placa Creality V2.5.2 / ATmega2560) no TV Box

Esta etapa é de **outra impressora/placa**, conectada ao mesmo TV Box (192.168.1.101 →
depois passou a **192.168.1.109** após reboot do box). A placa é uma **Creality 3D
v2.5.2 (2017), 8-bit, com ATMega2560** — confirmado pela assinatura `0x1e9801` e pelo
exemplo oficial `printer-creality-cr10-v3-2020.cfg` do Klipper.

### 4.1 Compilação do firmware (ATmega2560) no PC
- Versão do Klipper do host (container): **v0.13.0-699-gc707dd192**; firmware compilado no
  mesmo commit para casar protocolo.
- Build feito em container Docker no PC (imagem base local `nvidia/cuda:12.2.0-base-ubuntu22.04`,
  pois o pull do `debian` falhava por IPv6), instalando `gcc-avr avr-libc binutils-avr`.
- `.config`: `CONFIG_MACH_AVR=y`, `CONFIG_MACH_atmega2560=y`, clock 16 MHz, `SERIAL_BAUD=250000`.
- Saída: `klipper.elf.hex` → salvo em `firmware-cr10v2/` e `klipper/`.

### 4.2 Gravação do firmware (avrdude, via PC)
- ⚠️ Placa AVR **NÃO grava por cartão SD** (isso é só para placas 32-bit STM32). Gravação por
  `avrdude` pela USB.
- Impressora conectada ao PC: CH340 em `/dev/ttyUSB0` (`usb-1a86_USB_Serial`).
- Teste de conexão e gravação (avrdude em container, com `--device /dev/ttyUSB0`):
  ```
  avrdude -p atmega2560 -c wiring -P /dev/ttyUSB0 -b 115200 -D -U flash:w:<hex>:i
  ```
- Resultado: **43126 bytes escritos e verificados** ✅ (assinatura `0x1e9801` = ATmega2560).

### 4.3 printer.cfg da CR-10 V2 (no TV Box)
- Base: exemplo `printer-creality-cr10-v3-2020.cfg` (pinos do ATmega2560), adaptado:
  serial por `by-id`, `[include mainsail.cfg]`, mesa 300×300×400.
- Primeira versão com **fim-de-curso Z mecânico** deu erro de pinos/`temperature_mcu`
  (config STM32 antiga ainda estava no arquivo) → corrigido com `FIRMWARE_RESTART`.
- Depois trocado para **BLTouch** (a impressora tem o probe):
  `endstop_pin: probe:z_virtual_endstop`, bloco `[bltouch]` (sensor `^PD2`, control `PB5`,
  `set_output_mode: 5V`), `[safe_z_home]` e `[bed_mesh]`.

### 4.4 "Home do Z não funciona" — causa e solução
- Sintoma: home de Z falhava com `Must home X and Y axes first`.
- **Causa:** estava sendo enviado **`G28 Z` sozinho**. Com BLTouch + `safe_z_home`, o Z só
  homa depois de X e Y.
- **Solução:** usar **`G28`** (home all). Validado: `homed_axes: xyz`, posição final
  `[150,150,10]` — BLTouch encontrou o Z. **A config estava correta.**

### 4.5 Resets e perda de comunicação — diagnóstico e correção (importante)
Problema recorrente: a cada `docker compose restart` / `FIRMWARE_RESTART` / `SAVE_CONFIG` a
placa resetava e às vezes travava, exigindo intervenção física.

**Causas (duas somadas):**
1. **Auto-reset por DTR:** a placa Creality reseta sempre que a porta serial é **reaberta**
   (igual ao Arduino). Acontece em restart/firmware_restart/save_config.
2. **USB fraca do TV Box:** no reset há um pico de corrente; a porta USB do box re-enumera/cai
   (visto no `dmesg`: device sumindo e voltando), e o Klipper entra em loop e trava.

**Correções aplicadas:**
- **Regra udev anti-reset** (`/etc/udev/rules.d/99-klipper-noreset.rules`):
  ```
  ACTION=="add", SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", RUN+="/usr/bin/stty -F /dev/%k -hupcl"
  ```
  O `-hupcl` faz a porta **não baixar o DTR ao fechar** → reabrir não gera borda → **a USB
  não cai mais** (confirmado: zero disconnects novos mesmo após vários restarts).
- **Parar de usar `docker compose restart`** para recarregar config. O correto é
  **"Salvar e reiniciar" do Mainsail** (`RESTART`/`FIRMWARE_RESTART`), que não derruba o container.
- `restart_method: command` no `[mcu]` (mantido).

**Aprendizado-chave (decisivo):** a placa é **alimentada pela própria USB**. Logo, **desligar a
fonte da impressora NÃO reseta a placa** — o reset de verdade é **desconectar/reconectar o
cabo USB** (ou o botão RESET da placa). Isso explicava por que às vezes o "desliga/liga da
fonte" não resolvia. A regra udev `-hupcl` só é (re)aplicada quando o dispositivo reaparece
(replug do cabo / reboot).

**Status:** com `-hupcl`, um `FIRMWARE_RESTART` **único** reconecta limpo; vários colados ainda
podem travar no bootloader (recuperação: replug do cabo USB). **Solução definitiva
recomendada: hub USB com fonte própria** entre o TV Box e a impressora.

### 4.6 Calibração do z_offset (BLTouch)
- Conceito esclarecido — há **três** "Z offset" diferentes:
  1. `z_offset` do `[bltouch]` no `printer.cfg` = calibração real (persistente).
  2. Seção de autosave `#*#` no rodapé do `printer.cfg` = onde o `SAVE_CONFIG` grava o valor
     (e comenta a linha original).
  3. "Z offset" do dashboard do Mainsail = **ajuste ao vivo (babystep)**, temporário, começa em `0.0`.
- Procedimento confiável: aquecer (bico ~200°, mesa ~60°) → `PROBE_CALIBRATE` → painel
  "Sonda Manual" no Mainsail → descer com passos (grande longe, pequeno perto) até a folha
  raspar de leve → **ACCEPT** → **SAVE_CONFIG**.
- Refino final: teste de 1ª camada + babystep → **`Z_OFFSET_APPLY_PROBE`** → `SAVE_CONFIG`.
- Histórico do valor: `PROBE_CALIBRATE` rodado gravou **z_offset = 5.080** e depois um novo
  ACCEPT/SAVE_CONFIG ajustou para **z_offset = 4.049** (backups automáticos do Klipper em
  `printer-AAAAMMDD_HHMMSS.cfg`).

### 4.7 Estado final (CR-10 V2)
| Item | Estado |
|---|---|
| Firmware | Klipper atmega2560 `v0.13.0-699-gc707dd192`, gravado e verificado |
| Klipper/Moonraker/Mainsail | mesma stack Docker do TV Box (`/mnt/data/prind`) |
| Conexão | CH340 `/dev/ttyUSB*` (por `by-id`), `ready` |
| Z / BLTouch | `G28` homa OK; z_offset calibrado (≈4.0–5.0, ver autosave) |
| Estabilidade | `-hupcl` evita queda de USB; **hub USB alimentado** é o fix definitivo |

> ⚠️ Pendências da CR-10 V2: refino do z_offset na 1ª camada; **PID tune** (hotend e mesa);
> conferir **direção dos eixos** e **E-steps**; conferir offsets X/Y do BLTouch. O `bed_mesh`
> está com valores genéricos.

### 4.8 Observação de rede
O TV Box mudou de IP **192.168.1.101 → 192.168.1.109** após um reboot (DHCP). Recomenda-se
fixar um **IP estático / reserva DHCP** no roteador para o box, evitando perder o endereço.
