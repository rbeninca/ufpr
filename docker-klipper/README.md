# Stack Klipper + Moonraker + Mainsail em Docker

Configuração da impressora Creality CR10 rodando no **TV Box Amlogic S905X (Armbian)**,
em `192.168.1.101` (passou a `192.168.1.109` após reboot). Stack baseada no projeto
[prind](https://github.com/mkuf/prind).

> ⚠️ O `docker-compose.yaml` deste diretório foi **reconstruído** a partir do
> `relatório_config.md`. O arquivo de produção fica no box em
> `/mnt/data/prind/docker-compose.yaml` — confira/substitua quando tiver acesso.

## Layout no box

```
/mnt/data/                 (microSD ext4, 14 G)
├── docker/                (data-root do Docker via /etc/docker/daemon.json)
├── gcodes/                (g-codes — bind mount)
└── prind/
    ├── docker-compose.yaml
    └── config/
        ├── printer.cfg     (CR10 + BLTouch, STM32F103 / Creality 4.2.2)
        ├── mainsail.cfg
        └── moonraker.conf
```

## Comandos (em /mnt/data/prind)

```bash
docker compose --profile mainsail up -d     # subir/atualizar
docker compose --profile mainsail ps        # status
docker compose logs -f klipper              # logs
```

## Notas de setup

- microSD reformatado em **ext4** (FAT32 não suporta sockets Unix do Klipper nem overlay2).
- data-root do Docker movido para `/mnt/data/docker`.
- `docker pull` falhava (TLS handshake timeout por IPv6); resolvido fixando IPv4 do
  Docker Hub em `/etc/hosts` e limitando downloads concorrentes a 1.
- Porta do Mainsail no traefik corrigida de 80 → **8080**.
- Klipper no container: **v0.13.0-699-gc707dd192**.

Detalhes completos em [`../relatório_config.md`](../relatório_config.md).
