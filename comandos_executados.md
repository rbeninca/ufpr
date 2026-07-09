# Comandos Executados — sessão de configuração (2026-06-24/25)

Lista completa e fiel de todos os comandos executados, em ordem cronológica.
Nada omitido. Comandos remotos foram disparados do PC via `sshpass + ssh/scp`.

> Notação: `SSHPASS=<senha> sshpass -e ssh ... <host> '<comandos remotos>'`
> Os comandos remotos (dentro das aspas) são o que de fato rodou em cada máquina.

---

## PARTE 1 — OctoPrint no OctoPi (192.168.1.251, usuário pi / senha raspberry)

### 1.1 Verificação de acesso (rodado no PC)
```bash
which sshpass ssh 2>&1; echo "---"; ping -c1 -W2 192.168.1.251 2>&1 | head -3
```

### 1.2 Diagnóstico do serviço octoprint (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'echo "=== systemctl cat ==="; systemctl cat octoprint 2>&1; echo "=== status ==="; systemctl status octoprint --no-pager -l 2>&1 | head -20; echo "=== ss ==="; sudo ss -ltnp 2>/dev/null | egrep ":80|:8080|:8081|:5000"; echo "=== override dir ==="; ls -la /etc/systemd/system/octoprint.service.d/ 2>&1; echo "=== override.conf ==="; cat /etc/systemd/system/octoprint.service.d/override.conf 2>&1'
```

### 1.3 Investigar webcam/mjpg_streamer (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'echo "=== proc 532 ==="; ps -fp 532 2>&1; echo "=== webcamd units ==="; systemctl list-units --type=service --no-pager 2>/dev/null | egrep -i "webcam|mjpg|cam|crow|ustreamer"; echo "=== octopi.txt camera ==="; grep -nv "^#" /boot/octopi.txt 2>/dev/null | egrep -i "port|8080|8081|cam" ; echo "=== webcamd script ==="; ls -l /root/bin/webcamd /usr/local/bin/webcamd /home/pi/scripts/webcamd 2>&1'
```

### 1.4 Achar porta da webcam e proxy do nginx (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'echo "=== webcamd port vars ==="; grep -nE "port|8080|http_options|camera_" /root/bin/webcamd 2>&1 | head -30; echo "=== octopi.txt cam lines (all) ==="; grep -niE "camera|http_options|8080|port" /boot/octopi.txt 2>&1; echo "=== nginx webcam proxy ==="; grep -rniE "8080|webcam|mjpg|proxy_pass" /etc/nginx/ 2>/dev/null | head'
```

### 1.5 Ler linhas exatas dos arquivos a editar (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'echo "=== octopi.txt 44-60 ==="; sed -n "44,60p" /boot/octopi.txt; echo "=== upstreams.conf ==="; cat -n /etc/nginx/conf.d/upstreams.conf'
```

### 1.6 Aplicar as 3 mudanças: webcam 8081, nginx upstream, override octoprint (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'set -e
# 1) Webcam -> 8081 em /boot/octopi.txt
sudo cp /boot/octopi.txt /boot/octopi.txt.bak.$(date +%s)
if grep -q "^camera_http_options=" /boot/octopi.txt; then
  sudo sed -i "s|^camera_http_options=.*|camera_http_options=\"-n --listen 127.0.0.1 -p 8081\"|" /boot/octopi.txt
else
  echo "camera_http_options=\"-n --listen 127.0.0.1 -p 8081\"" | sudo tee -a /boot/octopi.txt >/dev/null
fi
echo "octopi.txt:"; grep -n "^camera_http_options=" /boot/octopi.txt

# 2) nginx upstream mjpgstreamer1 -> 8081
sudo cp /etc/nginx/conf.d/upstreams.conf /etc/nginx/conf.d/upstreams.conf.bak.$(date +%s)
sudo sed -i "0,/server 127.0.0.1:8080;/s||server 127.0.0.1:8081;|" /etc/nginx/conf.d/upstreams.conf
echo "upstreams mjpgstreamer1:"; sed -n "7,10p" /etc/nginx/conf.d/upstreams.conf

# 3) OctoPrint override -> 0.0.0.0:8080
sudo mkdir -p /etc/systemd/system/octoprint.service.d
printf "[Service]\nEnvironment=\"HOST=0.0.0.0\"\nEnvironment=\"PORT=8080\"\n" | sudo tee /etc/systemd/system/octoprint.service.d/override.conf >/dev/null
echo "override.conf:"; cat /etc/systemd/system/octoprint.service.d/override.conf
'
```

### 1.7 Recarregar e reiniciar serviços + validar portas (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'set -e
sudo nginx -t 2>&1
sudo systemctl daemon-reload
sudo systemctl restart webcamd
sudo systemctl restart octoprint
sudo systemctl reload nginx
sleep 6
echo "=== octoprint cmdline real ==="
ps -o args= -C octoprint 2>/dev/null | head -1
echo "=== portas ==="
sudo ss -ltnp | egrep ":80|:8080|:8081|:5000"
'
```

### 1.8 Aguardar octoprint na 8080 + testes HTTP (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'for i in $(seq 1 10); do
  if sudo ss -ltnp | grep -q ":8080 "; then echo "OK 8080 ativo apos ${i}0s"; break; fi
  sleep 10
done
echo "=== portas finais ==="
sudo ss -ltnp | egrep ":80|:8080|:8081|:5000"
echo "=== teste http octoprint ==="
curl -s -o /dev/null -w "octoprint 8080 -> HTTP %{http_code}\n" http://127.0.0.1:8080/ 2>&1
curl -s -o /dev/null -w "mainsail 80   -> HTTP %{http_code}\n" http://127.0.0.1/ 2>&1
curl -s -o /dev/null -w "webcam stream -> HTTP %{http_code}\n" "http://127.0.0.1:8081/?action=snapshot" 2>&1
'
```

### 1.9 Ler seção serial atual do config.yaml (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'echo "=== serial atual ==="; awk "/^serial:/{f=1} f&&/^[a-z]/&&!/^serial:/{exit} f" /home/pi/.octoprint/config.yaml; echo "=== fim ==="'
```

### 1.10 Configurar porta serial do Klipper no OctoPrint (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'set -e
sudo systemctl stop octoprint
cp /home/pi/.octoprint/config.yaml /home/pi/.octoprint/config.yaml.bak.$(date +%s)
/home/pi/oprint/bin/python - <<"PY"
import yaml
p="/home/pi/.octoprint/config.yaml"
d=yaml.safe_load(open(p)) or {}
s=d.setdefault("serial",{})
port="/home/pi/printer_data/comms/klippy.serial"
s["port"]=port
s["baudrate"]=250000
s["autoconnect"]=True
ap=s.get("additionalPorts") or []
if port not in ap: ap.append(port)
s["additionalPorts"]=ap
yaml.safe_dump(d,open(p,"w"),default_flow_style=False,sort_keys=False)
print("OK serial section:")
print(yaml.safe_dump({"serial":s},default_flow_style=False,sort_keys=False))
PY
sudo systemctl start octoprint
echo "aguardando octoprint subir..."
for i in $(seq 1 12); do sudo ss -ltnp | grep -q ":8080 " && { echo "8080 up"; break; }; sleep 5; done'
```

### 1.11 Verificar conexão OctoPrint <-> Klipper (remoto)
```bash
SSHPASS=raspberry sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@192.168.1.251 'sleep 8
echo "=== klippy.serial existe? ==="; ls -l /home/pi/printer_data/comms/klippy.serial
echo "=== klipper ativo? ==="; systemctl is-active klipper
echo "=== octoprint log (conexao) ==="; grep -iE "connect|serial|klippy|operational|printer|baudrate|error" /home/pi/.octoprint/logs/octoprint.log | tail -20'
```

---

## PARTE 2 — Stack Docker no TV Box (192.168.1.101, root/rbeninca senha aluno123)

### 2.1 Avaliação do dispositivo (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== uname/arch ==="; uname -a; echo; cat /etc/os-release 2>/dev/null | egrep "PRETTY|VERSION"
echo "=== cpu ==="; lscpu 2>/dev/null | egrep "Architecture|Model name|CPU\(s\)"
echo "=== memoria ==="; free -h
echo "=== disco ==="; df -h
echo "=== docker? ==="; which docker docker-compose 2>&1; docker --version 2>&1; docker compose version 2>&1
echo "=== blocos/armazenamento ==="; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>&1
echo "=== usb (impressora?) ==="; lsusb 2>&1; ls -l /dev/serial/by-id/ 2>&1; ls -l /dev/ttyUSB* /dev/ttyACM* 2>&1
'
```

### 2.2 Inspecionar conteúdo do pendrive e microSD (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
mkdir -p /mnt/_chk
echo "=== sda1 (pendrive 28.9G) ==="; mount -o ro /dev/sda1 /mnt/_chk 2>&1 && { df -h /mnt/_chk | tail -1; echo "conteudo:"; ls -la /mnt/_chk | head -20; umount /mnt/_chk; }
echo "=== mmcblk0p1 (microSD 14.8G) ==="; mount -o ro /dev/mmcblk0p1 /mnt/_chk 2>&1 && { df -h /mnt/_chk | tail -1; echo "conteudo:"; ls -la /mnt/_chk | head -20; umount /mnt/_chk; }
rmdir /mnt/_chk 2>/dev/null
echo "=== labels ==="; lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL /dev/sda /dev/mmcblk0 2>&1
'
```

### 2.3 Backup + formatar microSD em ext4 + montar + fstab (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
set -e
# Backup dos 2 arquivos do microSD
mkdir -p /root/microsd-backup /mnt/_chk
mount -o ro /dev/mmcblk0p1 /mnt/_chk
cp -v /mnt/_chk/firmware.bin /mnt/_chk/*.cfg /root/microsd-backup/ 2>&1 || true
umount /mnt/_chk
echo "backup em /root/microsd-backup:"; ls -l /root/microsd-backup

# Reformatar microSD para ext4
echo "=== formatando mmcblk0p1 como ext4 ==="
mkfs.ext4 -F -L printerdata /dev/mmcblk0p1 2>&1 | tail -5

# Montar em /mnt/data e fixar no fstab por UUID
mkdir -p /mnt/data
UUID=$(blkid -s UUID -o value /dev/mmcblk0p1)
echo "UUID=$UUID"
sed -i "\#/mnt/data#d" /etc/fstab
echo "UUID=$UUID /mnt/data ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
mount /mnt/data
df -h /mnt/data | tail -1
rmdir /mnt/_chk 2>/dev/null || true
'
```

### 2.4 Mover data-root do Docker para o microSD (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
set -e
systemctl stop docker docker.socket 2>&1 || true
mkdir -p /mnt/data/docker
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "/mnt/data/docker",
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "storage-driver": "overlay2"
}
EOF
systemctl start docker
sleep 3
echo "=== docker data-root ==="
docker info 2>/dev/null | grep -i "docker root dir"
docker info 2>/dev/null | grep -i "storage driver"
echo "=== df ==="; df -h / /mnt/data | tail -2
'
```

### 2.5 Clonar projeto prind de referência (rodado no PC)
```bash
cd /tmp && rm -rf prind && git clone --depth 1 https://github.com/mkuf/prind.git 2>&1 | tail -3 && echo "=== tree ===" && ls -la prind && echo "=== compose ===" && ls prind/docker-compose.yml prind/config 2>&1
```

### 2.6 Ler compose/override/moonraker.conf do prind (PC)
```bash
cd /tmp/prind && echo "=== docker-compose.yaml ===" && cat docker-compose.yaml && echo "=== override ===" && cat docker-compose.override.yaml && echo "=== config/moonraker.conf ===" && cat config/moonraker.conf
```

### 2.7 Criar docker-compose.yaml enxuto (PC)
```bash
rm -rf /tmp/deploy && mkdir -p /tmp/deploy/config && cd /tmp/deploy

cat > docker-compose.yaml <<'YAML'
## Stack minimalista: Klipper + Moonraker + Mainsail
services:

  klipper:
    image: mkuf/klipper:latest
    restart: unless-stopped
    privileged: true
    logging: { driver: none }
    depends_on:
      init: { condition: service_completed_successfully }
    command: >
      -I printer_data/run/klipper.tty
      -a printer_data/run/klipper.sock
      printer_data/config/printer.cfg
      -l printer_data/logs/klippy.log
    volumes:
      - /dev:/dev
      - ./config:/opt/printer_data/config
      - run:/opt/printer_data/run
      - gcode:/opt/printer_data/gcodes
      - log:/opt/printer_data/logs
    labels: { org.prind.service: klipper }

  moonraker:
    image: mkuf/moonraker:latest
    restart: unless-stopped
    pid: host
    logging: { driver: none }
    depends_on:
      init: { condition: service_completed_successfully }
      klipper: { condition: service_started }
    volumes:
      - /dev/null:/opt/klipper/config/null
      - /dev/null:/opt/klipper/docs/null
      - /run/dbus:/run/dbus
      - /run/systemd:/run/systemd
      - run:/opt/printer_data/run
      - gcode:/opt/printer_data/gcodes
      - log:/opt/printer_data/logs
      - moonraker-db:/opt/printer_data/database
      - ./config:/opt/printer_data/config
    labels:
      org.prind.service: moonraker
      traefik.enable: "true"
      traefik.http.services.moonraker.loadbalancer.server.port: "7125"
      traefik.http.routers.moonraker.rule: PathRegexp(`^/(websocket|printer|api|access|machine|server)`)
      traefik.http.routers.moonraker.entrypoints: web

  mainsail:
    image: ghcr.io/mainsail-crew/mainsail:latest
    restart: unless-stopped
    labels:
      org.prind.service: mainsail
      traefik.enable: "true"
      traefik.http.services.mainsail.loadbalancer.server.port: "80"
      traefik.http.routers.mainsail.rule: PathPrefix(`/`)
      traefik.http.routers.mainsail.entrypoints: web

  init:
    image: busybox:latest
    command: chown -R 1000:1000 /prind/config
    volumes:
      - .:/prind
    labels: { org.prind.service: init }

  traefik:
    image: traefik:3.7
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    restart: unless-stopped
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    labels: { org.prind.service: traefik }

volumes:
  run:
    driver_opts: { type: tmpfs, device: tmpfs }
  log:
    driver_opts: { type: tmpfs, device: tmpfs }
  moonraker-db:
  gcode:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/data/gcodes
YAML
echo "compose criado"; ls -l docker-compose.yaml
```

### 2.8 Criar moonraker.conf e primeiro printer.cfg (PC)
```bash
cd /tmp/deploy

cat > config/moonraker.conf <<'EOF'
[server]
host: 0.0.0.0
port: 7125
klippy_uds_address: /opt/printer_data/run/klipper.sock

[file_manager]
# g-codes ficam no microSD via bind-mount (/mnt/data/gcodes)

[machine]
provider: none

[authorization]
trusted_clients:
  0.0.0.0/0
cors_domains:
  *

[octoprint_compat]
[history]
[update_manager]
enable_auto_refresh: False
EOF

cat > config/printer.cfg <<'EOF'
# (primeira versão — AVR/Melzi, depois substituída pela versão STM32/CR10)
[mcu]
serial: /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100
[stepper_x]
step_pin: PD7
dir_pin: PC5
enable_pin: !PD6
microsteps: 16
rotation_distance: 40
endstop_pin: ^PC2
position_endstop: 0
position_max: 300
homing_speed: 50
[stepper_y]
step_pin: PC6
dir_pin: PC7
enable_pin: !PD6
microsteps: 16
rotation_distance: 40
endstop_pin: ^PC3
position_endstop: 0
position_max: 300
homing_speed: 50
[stepper_z]
step_pin: PB3
dir_pin: PB2
enable_pin: !PA5
microsteps: 16
rotation_distance: 8
endstop_pin: ^PC4
position_endstop: 0.0
position_max: 400
[extruder]
step_pin: PB1
dir_pin: PB0
enable_pin: !PD6
microsteps: 16
rotation_distance: 33.500
nozzle_diameter: 0.400
filament_diameter: 1.750
heater_pin: PD5
sensor_type: EPCOS 100K B57560G104F
sensor_pin: PA7
control: pid
pid_Kp: 22.2
pid_Ki: 1.08
pid_Kd: 114
min_temp: 0
max_temp: 250
[heater_bed]
heater_pin: PD4
sensor_type: EPCOS 100K B57560G104F
sensor_pin: PA6
control: watermark
min_temp: 0
max_temp: 130
[fan]
pin: PB4
[virtual_sdcard]
path: /opt/printer_data/gcodes
[pause_resume]
[display_status]
[gcode_macro CANCEL_PRINT]
description: Cancel the actual running print
rename_existing: CANCEL_PRINT_BASE
gcode:
  TURN_OFF_HEATERS
  CANCEL_PRINT_BASE
EOF
echo "configs criadas:"; ls -l config/
```

### 2.9 Criar diretórios no box + enviar arquivos (PC)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 'mkdir -p /mnt/data/prind /mnt/data/gcodes'
SSHPASS=aluno123 sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /tmp/deploy/docker-compose.yaml /tmp/deploy/config root@192.168.1.101:/mnt/data/prind/
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 'ls -R /mnt/data/prind'
```

### 2.10 Primeira tentativa de pull (falhou: TLS handshake timeout) (PC->box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
echo "=== pull (pode demorar) ==="
docker compose --profile mainsail pull 2>&1 | tail -20
'
```

### 2.11 Retry simples do pull (ainda falhou) (PC->box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
for n in 1 2 3; do
  echo "=== tentativa $n ==="
  if docker compose --profile mainsail pull 2>&1 | tail -8; then echo "PULL OK"; break; fi
  sleep 5
done
echo "=== imagens ==="; docker images
echo "=== df ==="; df -h /mnt/data | tail -1
'
```

### 2.12 Limitar downloads concorrentes + retry (PC->box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
python3 - <<PY
import json
f="/etc/docker/daemon.json"
d=json.load(open(f))
d["max-concurrent-downloads"]=1
d["max-concurrent-uploads"]=1
json.dump(d,open(f,"w"),indent=2)
print(open(f).read())
PY
systemctl restart docker
sleep 3
cd /mnt/data/prind
echo "=== pull serial ==="
docker compose --profile mainsail pull 2>&1 | egrep -i "pull complete|pulled|downloaded|error|already" | tail -30
echo "=== imagens ==="; docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}"
'
```

### 2.13 Loop de retry (ainda TLS timeout) (PC->box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
ok=0
for n in $(seq 1 8); do
  echo "=== tentativa $n ==="
  if docker compose --profile mainsail pull >/tmp/pull.log 2>&1; then ok=1; echo "PULL COMPLETO"; break; fi
  tail -2 /tmp/pull.log
  sleep 4
done
echo "ok=$ok"
echo "=== imagens ==="; docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
'
```

### 2.14 Diagnóstico de rede do registry (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== DNS ==="; getent hosts registry-1.docker.io
echo "=== curl https hub (v4) ==="; time curl -4 -s -o /dev/null -w "http=%{http_code} time=%{time_total}\n" --max-time 25 https://registry-1.docker.io/v2/ 2>&1
echo "=== curl https hub (v6) ==="; time curl -6 -s -o /dev/null -w "http=%{http_code} time=%{time_total}\n" --max-time 10 https://registry-1.docker.io/v2/ 2>&1
echo "=== ipv6 habilitado? ==="; cat /proc/sys/net/ipv6/conf/all/disable_ipv6; ip -6 addr show scope global 2>/dev/null | grep inet6 | head
echo "=== MTU ==="; ip link show | egrep "mtu|state UP" | head
echo "=== rota default ==="; ip route | grep default
'
```

### 2.15 Resolver IPv4 dos hosts do Docker Hub (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== A records (IPv4) ==="
for h in registry-1.docker.io auth.docker.io production.cloudflare.docker.com index.docker.io; do
  ip=$(curl -s -4 "https://1.1.1.1/dns-query?name=$h&type=A" -H "accept: application/dns-json" 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print(next((a[\"data\"] for a in d.get(\"Answer\",[]) if a[\"type\"]==1),\"\"))" 2>/dev/null)
  echo "$h -> $ip"
done
'
```

### 2.16 Fixar IPv4 no /etc/hosts + pull (sucesso) (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
sed -i "/docker.io\|cloudflare.docker.com/d" /etc/hosts
cat >> /etc/hosts <<EOF
3.224.9.179 registry-1.docker.io
172.64.144.78 auth.docker.io
104.16.98.215 production.cloudflare.docker.com
54.224.198.86 index.docker.io
EOF
echo "=== /etc/hosts ==="; tail -5 /etc/hosts
cd /mnt/data/prind
ok=0
for n in $(seq 1 6); do
  echo "=== tentativa $n ==="
  if docker compose --profile mainsail pull >/tmp/pull.log 2>&1; then ok=1; echo "PULL COMPLETO"; break; fi
  tail -1 /tmp/pull.log; sleep 3
done
echo "ok=$ok"
docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
'
```

### 2.17 Subir a stack (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
docker compose --profile mainsail up -d 2>&1 | tail -15
sleep 12
echo "=== ps ==="; docker compose --profile mainsail ps 2>&1
echo "=== df /mnt/data ==="; df -h /mnt/data | tail -1
'
```

### 2.18 Verificar web + estado do Klipper (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== Mainsail (porta 80) ==="; curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1/
echo "=== Moonraker via traefik ==="; curl -s http://127.0.0.1/printer/info 2>&1 | head -c 400; echo
echo "=== klippy.log (ultimas linhas) ==="; tail -15 /mnt/data/prind/config/../../prind/config/.. 2>/dev/null; docker exec prind-klipper-1 tail -15 /opt/printer_data/logs/klippy.log 2>&1 | tail -15
'
```

### 2.19 Ler config de backup (descoberta: STM32/Creality 4.2.2) (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 'cat /root/microsd-backup/printer-ender3v2-bltouch-inicial.cfg'
```

### 2.20 Criar mainsail.cfg e printer.cfg definitivo (CR10/STM32) (PC)
```bash
cd /tmp/deploy

cat > config/mainsail.cfg <<'EOF'
# Configuracao requerida pelo Mainsail
[virtual_sdcard]
path: /opt/printer_data/gcodes
on_error_gcode: CANCEL_PRINT

[pause_resume]
[display_status]
[respond]

[gcode_macro CANCEL_PRINT]
description: Cancel the actual running print
rename_existing: CANCEL_PRINT_BASE
gcode:
  TURN_OFF_HEATERS
  CANCEL_PRINT_BASE

[gcode_macro PAUSE]
description: Pause the actual running print
rename_existing: PAUSE_BASE
gcode:
  PAUSE_BASE
  G91
  G1 Z5 F900
  G90

[gcode_macro RESUME]
description: Resume the actual running print
rename_existing: RESUME_BASE
gcode:
  G91
  G1 Z-5 F900
  G90
  RESUME_BASE
EOF

cat > config/printer.cfg <<'EOF'
# Creality CR-10 (300x300x400) - placa Creality 4.2.2 / STM32F103
[include mainsail.cfg]

[mcu]
serial: /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
restart_method: command

[printer]
kinematics: cartesian
max_velocity: 300
max_accel: 3000
max_z_velocity: 5
max_z_accel: 100
square_corner_velocity: 5.0

[stepper_x]
step_pin: PC2
dir_pin: PB9
enable_pin: !PC3
microsteps: 16
rotation_distance: 40
endstop_pin: ^PA5
position_endstop: 0
position_max: 300
homing_speed: 50

[stepper_y]
step_pin: PB8
dir_pin: PB7
enable_pin: !PC3
microsteps: 16
rotation_distance: 40
endstop_pin: ^PA6
position_endstop: 0
position_max: 300
homing_speed: 50

[stepper_z]
step_pin: PB6
dir_pin: !PB5
enable_pin: !PC3
microsteps: 16
rotation_distance: 8
endstop_pin: probe:z_virtual_endstop
position_min: -5
position_max: 400

[extruder]
max_extrude_only_distance: 100.0
step_pin: PB4
dir_pin: PB3
enable_pin: !PC3
microsteps: 16
rotation_distance: 34.4086
nozzle_diameter: 0.400
filament_diameter: 1.750
heater_pin: PA1
sensor_type: EPCOS 100K B57560G104F
sensor_pin: PC5
control: pid
pid_kp: 28.72
pid_ki: 2.62
pid_kd: 78.81
min_temp: 0
max_temp: 250

[heater_bed]
heater_pin: PA2
sensor_type: EPCOS 100K B57560G104F
sensor_pin: PC4
control: pid
pid_kp: 462.10
pid_ki: 85.47
pid_kd: 624.59
min_temp: 0
max_temp: 130

[fan]
pin: PA0

[bltouch]
sensor_pin: ^PB1
control_pin: PB0
x_offset: -42
y_offset: -12
z_offset: 0
speed: 5.0
samples: 2
sample_retract_dist: 8.0

[safe_z_home]
home_xy_position: 150, 150
speed: 50
z_hop: 10
z_hop_speed: 5

[bed_mesh]
speed: 120
horizontal_move_z: 8
mesh_min: 30, 30
mesh_max: 250, 280
probe_count: 4, 4
algorithm: bicubic
fade_start: 1.0
fade_end: 10.0

[gcode_macro G29]
gcode:
  BED_MESH_CALIBRATE

[temperature_sensor mcu_temp]
sensor_type: temperature_mcu
min_temp: 0
max_temp: 100
EOF
echo "config CR10 criada"; ls -l config/
```

### 2.21 Enviar configs + reiniciar klipper + verificar (PC->box)
```bash
SSHPASS=aluno123 sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/deploy/config/printer.cfg /tmp/deploy/config/mainsail.cfg root@192.168.1.101:/mnt/data/prind/config/
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
chown -R 1000:1000 config
docker compose restart klipper 2>&1 | tail -3
sleep 10
echo "=== Mainsail ==="; curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1/
echo "=== printer/info ==="; curl -s http://127.0.0.1/printer/info 2>&1 | head -c 300; echo
echo "=== temps ==="; curl -s "http://127.0.0.1/printer/objects/query?extruder&heater_bed" 2>&1 | head -c 400; echo
'
```

### 2.22 FIRMWARE_RESTART + verificar estado (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
curl -s "http://127.0.0.1/printer/firmware_restart" -X POST 2>&1 | head -c 200; echo
sleep 12
echo "=== printer/info ==="; curl -s http://127.0.0.1/printer/info 2>&1 | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"];print(\"state:\",d[\"state\"]);print(\"msg:\",d[\"state_message\"][:200])"
echo "=== temps ==="; curl -s "http://127.0.0.1/printer/objects/query?extruder&heater_bed&mcu" 2>&1 | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"][\"status\"];print(\"extruder:\",d[\"extruder\"][\"temperature\"]);print(\"bed:\",d[\"heater_bed\"][\"temperature\"])"
echo "=== Mainsail ==="; curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1/
echo "=== mainsail container log ==="; docker logs prind-mainsail-1 2>&1 | tail -5
'
```

### 2.23 Diagnosticar 502 do Mainsail (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== mainsail direto (IP do container) ==="
MIP=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" prind-mainsail-1)
echo "mainsail IP=$MIP"; curl -s -o /dev/null -w "direto HTTP %{http_code}\n" http://$MIP:80/
echo "=== traefik log (erros) ==="; docker logs prind-traefik-1 2>&1 | egrep -i "error|502|mainsail|level=warn" | tail -10
echo "=== headers via traefik ==="; curl -s -D - -o /dev/null http://127.0.0.1/ | head -8
'
```

### 2.24 Corrigir porta do Mainsail no traefik (80 -> 8080) (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
cd /mnt/data/prind
sed -i "s|traefik.http.services.mainsail.loadbalancer.server.port: \"80\"|traefik.http.services.mainsail.loadbalancer.server.port: \"8080\"|" docker-compose.yaml
grep "mainsail.loadbalancer" docker-compose.yaml
docker compose --profile mainsail up -d 2>&1 | tail -4
sleep 6
echo "=== Mainsail via traefik ==="; curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1/
echo "=== titulo da pagina ==="; curl -s http://127.0.0.1/ | grep -i "<title>" | head -1
'
```

### 2.25 Verificação final: boot, g-codes, recursos (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 '
echo "=== docker habilitado no boot? ==="; systemctl is-enabled docker
echo "=== containers ==="; docker compose -f /mnt/data/prind/docker-compose.yaml --profile mainsail ps --format "{{.Name}} {{.Status}}"
echo "=== teste de gravacao g-code no microSD via Moonraker ==="
printf "G28\n" > /tmp/teste.gcode
curl -s -o /dev/null -w "upload HTTP %{http_code}\n" -F "file=@/tmp/teste.gcode" http://127.0.0.1/server/files/upload
echo "conteudo de /mnt/data/gcodes:"; ls -l /mnt/data/gcodes
echo "=== espaco ==="; df -h / /mnt/data | tail -2
echo "=== RAM ==="; free -h | head -2
'
```

### 2.26 Remover g-code de teste (remoto)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 'rm -f /mnt/data/gcodes/teste.gcode; echo limpo'
```

---

## PARTE 3 — Compilação do firmware da CR10 (rodado no PC)

### 3.1 Obter versão do Klipper no container + checar toolchain
```bash
echo "=== versao klipper no container (via moonraker) ==="
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.101 'curl -s http://127.0.0.1/printer/info | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"];print(\"software_version:\",d.get(\"software_version\"))"; echo "--- klipper repo no container ---"; docker exec prind-klipper-1 sh -c "cd /opt/klipper && git describe --tags --always 2>/dev/null; git rev-parse HEAD 2>/dev/null"'
echo "=== toolchain no PC ==="
which docker arm-none-eabi-gcc make git 2>&1
docker --version 2>&1 | head -1
```

### 3.2 Criar script de build do firmware
```bash
mkdir -p /home/rbeninca/projetos/ufpr/firmware-cr10
cat > /tmp/build-fw.sh <<'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git build-essential gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi python3 >/dev/null
cd /build
git clone https://github.com/Klipper3d/klipper.git >/dev/null 2>&1
cd klipper
git checkout c707dd192 2>&1 | tail -1
# .config para Creality 4.2.2 (STM32F103, bootloader 28KiB, cristal 8MHz, serial USART1)
cat > .config <<CFG
CONFIG_MACH_STM32=y
CONFIG_MACH_STM32F103=y
CONFIG_STM32_FLASH_START_7000=y
CONFIG_STM32_CLOCK_REF_8M=y
CONFIG_STM32_SERIAL_USART1=y
CONFIG_SERIAL=y
CONFIG_SERIAL_BAUD=250000
CFG
make olddefconfig >/dev/null
echo "=== resumo da config ==="
grep -E "MACH_STM32F103|FLASH_START|CLOCK_REF|SERIAL_USART1|SERIAL_BAUD" .config
make -j4 2>&1 | tail -8
echo "=== saida ==="
ls -l out/klipper.bin
cp out/klipper.bin /out/firmware-cr10-c707dd192.bin
EOF
```

### 3.3 Tentativa com debian:bookworm-slim (falhou — TLS timeout no PC)
```bash
docker run --rm -v /tmp/build-fw.sh:/build-fw.sh:ro -v /home/rbeninca/projetos/ufpr/firmware-cr10:/out -w /build debian:bookworm-slim bash /build-fw.sh 2>&1 | tail -25
```

### 3.4 Retry de pull do debian (não resolveu)
```bash
for n in 1 2 3 4 5; do
  echo "=== tentativa $n ==="
  if docker pull debian:bookworm-slim 2>&1 | tail -2; then echo PULLOK; break; fi
  sleep 3
done
docker images debian:bookworm-slim --format "{{.Repository}}:{{.Tag}} {{.Size}}"
```

### 3.5 Listar imagens locais (para achar base alternativa)
```bash
echo "=== imagens locais disponiveis ==="; docker images --format "{{.Repository}}:{{.Tag}}" 2>&1 | head -40
```

### 3.6 Build do firmware usando imagem local (sucesso)
```bash
docker run --rm -v /tmp/build-fw.sh:/build-fw.sh:ro -v /home/rbeninca/projetos/ufpr/firmware-cr10:/out -w /build nvidia/cuda:12.2.0-base-ubuntu22.04 bash /build-fw.sh 2>&1 | tail -30
```

### 3.7 Ajustar permissão do .bin (tentativas)
```bash
# tentativa com sudo (falhou: precisa senha)
sudo chown $(id -u):$(id -g) /home/rbeninca/projetos/ufpr/firmware-cr10/*.bin
ls -l /home/rbeninca/projetos/ufpr/firmware-cr10/

sudo chown rbeninca:rbeninca /home/rbeninca/projetos/ufpr/firmware-cr10/firmware-cr10-c707dd192.bin

# solução: chown via container docker (root)
docker run --rm -v /home/rbeninca/projetos/ufpr/firmware-cr10:/out nvidia/cuda:12.2.0-base-ubuntu22.04 chown -R $(id -u):$(id -g) /out
ls -l /home/rbeninca/projetos/ufpr/firmware-cr10/
```

---

## PARTE 4 — CR-10 V2 (placa Creality V2.5.2 / ATmega2560) no TV Box
> Box passou de **192.168.1.101** para **192.168.1.109** após reboot.

### 4.1 Detectar cartão SD no PC e ver conteúdo (PC)
```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,TRAN 2>&1 | grep -viE "nvme0|zram"
ls /dev/mmcblk* /dev/sd* 2>&1
```

### 4.2 Compilar firmware ATmega2560 no PC (container)
```bash
mkdir -p /home/rbeninca/projetos/ufpr/firmware-cr10v2
cat > /tmp/build-fw-2560.sh <<'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git build-essential gcc-avr avr-libc binutils-avr python3 >/dev/null
cd /build
git clone https://github.com/Klipper3d/klipper.git >/dev/null 2>&1
cd klipper
git checkout c707dd192 2>&1 | tail -1
cat > .config <<CFG
CONFIG_MACH_AVR=y
CONFIG_MACH_atmega2560=y
CONFIG_SERIAL_BAUD=250000
CFG
make olddefconfig >/dev/null
grep -E "MACH_AVR|MACH_atmega2560|CLOCK_FREQ|SERIAL_BAUD" .config
make -j4 2>&1 | tail -10
ls -l out/klipper.elf.hex
cp out/klipper.elf.hex /out/klipper-cr10v2-atmega2560-c707dd192.hex
EOF
docker run --rm -v /tmp/build-fw-2560.sh:/build-fw-2560.sh:ro -v /home/rbeninca/projetos/ufpr/firmware-cr10v2:/out -w /build nvidia/cuda:12.2.0-base-ubuntu22.04 bash /build-fw-2560.sh 2>&1 | tail -25
docker run --rm -v /home/rbeninca/projetos/ufpr/firmware-cr10v2:/out nvidia/cuda:12.2.0-base-ubuntu22.04 chown -R $(id -u):$(id -g) /out
```

### 4.3 Detectar porta serial da impressora no PC
```bash
ls -l /dev/serial/by-id/ 2>&1; ls -l /dev/ttyACM* /dev/ttyUSB* 2>&1
lsusb 2>&1 | grep -iE "arduino|atmel|2341|03eb|1a86|ch340|10c4|silicon|mega|serial"
```

### 4.4 Teste de conexão avrdude (ler assinatura) (PC, container)
```bash
cat > /tmp/flash-test.sh <<'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq avrdude >/dev/null
avrdude -p atmega2560 -c wiring -P /dev/ttyUSB0 -b 115200 -D 2>&1 | tail -20
EOF
docker run --rm --device /dev/ttyUSB0 -v /tmp/flash-test.sh:/flash-test.sh:ro nvidia/cuda:12.2.0-base-ubuntu22.04 bash /flash-test.sh 2>&1 | tail -25
```

### 4.5 Gravar firmware com avrdude (PC, container)
```bash
cat > /tmp/flash-write.sh <<'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq avrdude >/dev/null
avrdude -p atmega2560 -c wiring -P /dev/ttyUSB0 -b 115200 -D -U flash:w:/fw/klipper-cr10v2-atmega2560-c707dd192.hex:i 2>&1 | tail -30
EOF
docker run --rm --device /dev/ttyUSB0 \
  -v /tmp/flash-write.sh:/flash-write.sh:ro \
  -v /home/rbeninca/projetos/ufpr/firmware-cr10v2:/fw:ro \
  nvidia/cuda:12.2.0-base-ubuntu22.04 bash /flash-write.sh 2>&1 | tail -30
```

### 4.6 Copiar firmwares para pasta klipper/ (PC)
```bash
mkdir -p /home/rbeninca/projetos/klipper
cp /home/rbeninca/projetos/ufpr/firmware-cr10v2/klipper-cr10v2-atmega2560-c707dd192.hex /home/rbeninca/projetos/klipper/
cp /home/rbeninca/projetos/ufpr/firmware-cr10/firmware-cr10-c707dd192.bin /home/rbeninca/projetos/klipper/ 2>/dev/null || true
ls -l /home/rbeninca/projetos/klipper/
```

### 4.7 Verificar box no novo IP e estado da stack (PC->box .109)
```bash
ping -c1 -W2 192.168.1.109
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
hostname; ip -4 addr show 2>/dev/null | grep -oE "192.168.1.[0-9]+" | head
docker compose -f /mnt/data/prind/docker-compose.yaml --profile mainsail ps --format "{{.Name}} {{.Status}}"
curl -s -o /dev/null -w "Mainsail HTTP %{http_code}\n" http://127.0.0.1/
curl -s http://127.0.0.1/printer/info | python3 -c "import sys,json;print(\"state:\",json.load(sys.stdin)[\"result\"][\"state\"])"
'
```

### 4.8 Listar exemplos de config e ler o cr10-v3 (atmega2560) (box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
docker exec prind-klipper-1 sh -c "ls /opt/klipper/config | grep -iE \"cr-?10|creality|2560\""
docker exec prind-klipper-1 cat /opt/klipper/config/printer-creality-cr10-v3-2020.cfg
'
```

### 4.9 printer.cfg da CR-10 V2 com BLTouch (PC -> box)
> Gerado em `/tmp/deploy/config/printer.cfg` (pinos ATmega2560 do exemplo cr10-v3,
> serial por by-id, `[include mainsail.cfg]`, `[bltouch] sensor_pin ^PD2 control_pin PB5
> set_output_mode 5V`, `[safe_z_home]`, `[bed_mesh]`) e enviado:
```bash
SSHPASS=aluno123 sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/deploy/config/printer.cfg root@192.168.1.109:/mnt/data/prind/config/
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
cd /mnt/data/prind; chown 1000:1000 config/printer.cfg
docker compose restart klipper 2>&1 | tail -1   # (depois descobrimos que restart NAO deve ser usado)
sleep 14
curl -s http://127.0.0.1/printer/info | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"];print(d[\"state\"],d[\"state_message\"][:120])"
'
```

### 4.10 Home: usar G28 (e nao G28 Z) — diagnostico
```bash
# erro observado no log:
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
docker exec prind-klipper-1 grep -iE "Must home X and Y|G28|probe|bltouch" /opt/printer_data/logs/klippy.log | tail
# comando correto:
curl -s "http://127.0.0.1/printer/gcode/script?script=G28" -X POST
curl -s "http://127.0.0.1/printer/objects/query?toolhead" | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"][\"status\"][\"toolhead\"];print(d[\"homed_axes\"], d[\"position\"])"
'
```

### 4.11 Teste do BLTouch sem mover o carro (box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
curl -s "http://127.0.0.1/printer/gcode/script?script=BLTOUCH_DEBUG%20COMMAND=pin_down" -X POST
curl -s "http://127.0.0.1/printer/gcode/script?script=BLTOUCH_DEBUG%20COMMAND=pin_up" -X POST
curl -s "http://127.0.0.1/printer/gcode/script?script=QUERY_PROBE" -X POST
curl -s "http://127.0.0.1/printer/objects/query?probe"
'
```

### 4.12 Diagnóstico do reset/USB (DTR + brownout) (box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
ls -l /dev/serial/by-id/; ls /dev/ttyUSB0
dmesg 2>/dev/null | grep -iE "ch341|usb 1-|ttyUSB|disconnect|reset|over-current|brown" | tail -20
cat /sys/bus/usb/devices/1-1/power/control
docker exec prind-klipper-1 grep -E "Timeout on connect|Serial connection closed|Loaded MCU" /opt/printer_data/logs/klippy.log | tail
'
```

### 4.13 Regra udev anti-reset (-hupcl) (box) — CORREÇÃO PRINCIPAL
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
STTY=$(command -v stty)
cat > /etc/udev/rules.d/99-klipper-noreset.rules <<EOF
# Evita auto-reset do CH340 (placa Creality) ao reabrir a porta serial
ACTION=="add", SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", RUN+="$STTY -F /dev/%k -hupcl"
EOF
udevadm control --reload-rules
# (a regra so se aplica quando o dispositivo REAPARECE: replug do cabo USB / reboot)
'
```

### 4.14 Subir Klipper após power/replug (NÃO usar restart) (box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
ls -l /dev/serial/by-id/
D=$(readlink -f /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0); stty -F "$D" -a | tr " " "\n" | grep -i hupcl
cd /mnt/data/prind
docker compose --profile mainsail up -d klipper 2>&1 | tail -1
sleep 16
curl -s http://127.0.0.1/printer/info | python3 -c "import sys,json;d=json.load(sys.stdin).get(\"result\",{});print(d.get(\"state\"))"
dmesg 2>/dev/null | grep -c "device disconnected"
'
```

### 4.15 Recuperar placa travada (pulso DTR via software) (box)
> Tentativa de tirar do bootloader sem power cycle (nem sempre funciona — replug do USB é o garantido).
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
cd /mnt/data/prind; docker compose stop klipper
DEV=$(readlink -f /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0)
python3 - "$DEV" <<PY
import sys,termios,fcntl,struct,time
fd=open(sys.argv[1]); TIOCM_DTR=0x002
fcntl.ioctl(fd, termios.TIOCMBIC, struct.pack("I", TIOCM_DTR)); time.sleep(0.12)
fcntl.ioctl(fd, termios.TIOCMBIS, struct.pack("I", TIOCM_DTR)); time.sleep(0.2)
fd.close(); print("pulso DTR enviado")
PY
docker compose --profile mainsail up -d klipper
'
```

### 4.16 Calibração do z_offset (BLTouch) — comandos (box)
```bash
SSHPASS=aluno123 sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.1.109 '
# inicia a sonda manual (aparece o modal "Sonda Manual" no Mainsail)
curl -s "http://127.0.0.1/printer/gcode/script?script=PROBE_CALIBRATE" -X POST
# confirmar sessao ativa
curl -s "http://127.0.0.1/printer/objects/query?manual_probe" | python3 -c "import sys,json;print(json.load(sys.stdin)[\"result\"][\"status\"][\"manual_probe\"])"
# descer/subir (ou usar os botoes do modal): TESTZ Z=-1 / Z=-0.1 / Z=+0.1 ...
# no fim: ACCEPT e depois SAVE_CONFIG (este reinicia o Klipper)
# ver z_offset efetivo e se ha config pendente:
curl -s "http://127.0.0.1/printer/objects/query?configfile" | python3 -c "import sys,json;d=json.load(sys.stdin)[\"result\"][\"status\"][\"configfile\"];print(\"z_offset=\",d[\"settings\"][\"bltouch\"][\"z_offset\"],\"pending=\",d.get(\"save_config_pending\"))"
'
```
> Resultado: `SAVE_CONFIG` gravou z_offset = 5.080 e, num segundo ACCEPT, 4.049
> (na seção de autosave `#*#` do printer.cfg, com backups automáticos).
