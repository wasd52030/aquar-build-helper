#!/bin/bash

# turenas scale 25.10.1
# ubuntu server 24.04
# reference -> https://www.youtube.com/watch?v=gozzdBZV1JQ&t=801s
# reference -> https://github.com/firemakergk/aquar-build-helper

nfspath=$1
if [ "$nfspath" == "" ]; then
    echo "ERROR:未傳入nfs地址作為腳本參數"
    exit 0
fi

echo '********開始初始化aquar環境********'
apt update
echo '********安装&掛載NFS********'
apt install nfs-common -y
mkdir -p /opt/aquar/storages/aquarpool/
echo 'mount nfs'
mount -t nfs $nfspath:/mnt/pool0/main_drive/sobel/aquarpool /opt/aquar/storages/aquarpool/
if ! grep -q '##\[aquar config start\]##' /etc/fstab;
then
    cat >> /etc/fstab <<EOF
##[aquar config start]##
$nfspath:/mnt/pool0/main_drive/sobel/aquarpool /opt/aquar/storages/aquarpool nfs defaults,_netdev 0 0
##[aquar config end]##
EOF
else
    echo '********探測到已配置成功，跳過/etc/fstab的配置********'
fi

echo '********安裝python3及venv********'
apt install curl -y
apt install python3-pip -y
# pip3 install virtualenv
# pip3 install virtualenvwrapper
# if ! grep -q '##\[aquar config start\]##' /root/.bashrc;
# then
# cp /root/.bashrc /root/.bashrc.bak
# cat >> /root/.bashrc <<EOF
# ##[aquar config start]##
# export WORKON_HOME=$HOME/.virtualenvs
# export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
# # source /usr/local/bin/virtualenvwrapper.sh
# ##[aquar config end]##
# EOF
# else
#     echo '********探測到已配置成功，跳過/root/.bashrc的配置********'
# fi
# source /root/.bashrc
cat > /usr/local/bin/aqserv <<EOF
#!/bin/bash
cmd=\$1
if [ "\$cmd" != "start" ] && [ "\$cmd" != "stop" ] && [ "\$cmd" != "restart" ] && [ "\$cmd" != "ps" ]; then
    echo "error： input parameter only accept 'start','stop','restart' or'ps'"
    exit 0
fi
source /root/.bashrc
cd /opt/aquar/src/docker-compose/
if [ "\$cmd" == "start" ]; then
    echo "aquar docker services starting"
    docker compose up -d
elif [ "\$cmd" == "stop" ]; then
    echo "aquar docker services stoping"
    docker compose stop
elif [ "\$cmd" == "restart" ]; then
    echo "aquar docker services restarting"
    docker compose restart

else
    docker compose ps
fi
EOF
chmod +x /usr/local/bin/aqserv

echo '********安裝docker********'
# Add Docker's official GPG key:
sudo apt update
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc


echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y containerd.io=1.7.29-1~ubuntu.24.04~noble docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
# 鎖住containerd版本
apt-mark hold containerd.io
# echo '********創建python環境aquar並安裝docker-compose********'
# source /root/.bashrc
# source /usr/local/bin/virtualenvwrapper.sh
# if ! grep -q 'source /usr/local/bin/virtualenvwrapper.sh' /root/.bashrc;
# then
# cat >> /root/.bashrc <<EOF
# source /usr/local/bin/virtualenvwrapper.sh
##[aquar config end]##
# EOF
# fi
# mkvirtualenv aquar
# workon aquar
# pip install docker-compose

# mkdir -p /opt/aquar/storages/apps/immich/library
# mkdir -p /opt/aquar/storages/apps/immich/postgres

# dashy config init
mkdir -p /opt/aquar/storages/aquarpool/apps/dashy/config
touch /opt/aquar/storages/aquarpool/apps/dashy/config/config.yml

# stirling_pdf init
mkdir -p /opt/aquar/storages/aquarpool/apps/stirling_pdf

# traefik init
mkdir -p /opt/aquar/storages/aquarpool/apps/traefik
mkdir -p /opt/aquar/storages/aquarpool/apps/traefik/letsencrypt
touch /opt/aquar/storages/aquarpool/apps/traefik/letsencrypt/acme.json
chmod 600 /opt/aquar/storages/aquarpool/apps/traefik/letsencrypt/acme.json

mkdir -p /opt/aquar/storages/aquarpool/apps/traefik/dynamic
cat > /opt/aquar/storages/aquarpool/apps/traefik/dynamic/middlewares.yml <<EOF
http:
  middlewares:
    security:
      headers:
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        forceSTSHeader: true
        frameDeny: true
        contentTypeNosniff: true
        #browserXssFilter: true
EOF


echo '********配置docker-compose********'
mkdir -p /opt/aquar/src/docker-compose/
touch /opt/aquar/src/docker-compose/docker-compose.yml
cat > /opt/aquar/src/docker-compose/docker-compose.yml <<EOF
networks:
  core:
    name: core
    internal: true
  app:
    name: app
    driver: bridge
  proxy:
    name: proxy
    driver: bridge
  rustdesk-net:
    external: false
services:
  # reference -> https://gist.github.com/dragonfire1119/ee8c1bc6f0707d8ee0b30afb98efc7eb
  adguardhome:  # Define the service named 'adguardhome'
    image: adguard/adguardhome  # Use the 'adguard/adguardhome' Docker image
    container_name: adguardhome  # Set the container name to 'adguardhome'
    restart: unless-stopped  # Restart the container automatically unless stopped manually
    network_mode: host
    # ports:  # Map container ports to host ports
    #   # Expose port 53 on TCP and UDP for DNS queries
    #   - "53:53/tcp"
    #   - "53:53/udp"

    #   # Expose port 8964 on TCP for HTTP web interface
    #   - "8964:8964/tcp"

    #   # Expose port 443 on TCP and UDP for HTTPS web interface
    #   #- "443:443/tcp"
    #   #- "443:443/udp"

    #   # Expose port 3000 on TCP for AdGuard Home's API
    #   - "3000:3000/tcp"
    environment:
      - TZ=Asia/Taipei
    volumes:  # Mount host directories as volumes inside the container
      - /opt/aquar/storages/aquarpool/apps/adguard-home/work:/opt/adguardhome/work
      - /opt/aquar/storages/aquarpool/apps/adguard-home/conf:/opt/adguardhome/conf
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: tailscale
    network_mode: host
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - /opt/aquar/storages/aquarpool/apps/tailscale/state:/var/lib/tailscale
    environment:
      - TS_AUTHKEY=123456
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_EXTRA_ARGS=--advertise-routes=192.168.0.0/24
    restart: unless-stopped
  traefik:
    image: traefik:latest
    container_name: traefik
    command:
      - --api.dashboard=true
      - --api.insecure=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --log.level=DEBUG
      - --providers.docker.network=proxy

      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --entrypoints.web.http.redirections.entryPoint.to=websecure
      - --entrypoints.web.http.redirections.entryPoint.scheme=https
      
      - --certificatesresolvers.resolverX.acme.dnschallenge=true
      - --certificatesresolvers.resolverX.acme.dnschallenge.provider=cloudflare
      - --certificatesresolvers.resolverX.acme.email=C109152304@nkust.edu.com
      - --certificatesresolvers.resolverX.acme.storage=/letsencrypt/acme.json
    ports:
      - "0.0.0.0:80:80"
      - "0.0.0.0:443:443"
      - "0.0.0.0:8080:8080"
    environment:
      - CF_DNS_API_TOKEN=654321
    networks:
      - app
      - proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/aquar/storages/aquarpool/apps/traefik/letsencrypt:/letsencrypt
    restart: unless-stopped
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    networks:
      - app
      - proxy
    # ports:
      # - "8096:8096"
    labels:
      - traefik.enable=true

      - traefik.http.routers.jellyfin.rule=Host(`jellyfin.haiyaa-sobel.cc`)
      - traefik.http.routers.jellyfin.entrypoints=websecure

      - traefik.http.routers.jellyfin.tls=true # 啟用 TLS
      - traefik.http.routers.jellyfin.tls.certresolver=resolverX

      - traefik.http.routers.jellyfin.service=jellyfin
      - traefik.docker.network=proxy

      - traefik.http.services.jellyfin.loadbalancer.server.port=8096
    environment:
      - TZ=Asia/Taipei
      #- JELLYFIN_PublishedServerUrl="http://192.168.0.118:8096" #optional
    volumes:
      - /opt/aquar/storages/aquarpool/apps/jellyfin/config:/config
      - /opt/aquar/storages/aquarpool/apps/jellyfin/cache:/cache
      - /opt/aquar/storages/aquarpool/movies:/media
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
  # syncthing:
  #   image: ghcr.io/linuxserver/syncthing
  #   container_name: syncthing
  #   # hostname: syncthing #optional
  #   environment:
  #     - PUID=1000
  #     - PGID=1000
  #     - TZ="Asia/Taipei"
  #   volumes:
  #     - /opt/aquar/storages/aquarpool/apps/syncthing/config:/config
  #     - /opt/aquar/storages/aquarpool/aquarpool:/opt/aquarpool
  #     # - /path/to/data1:/data1
  #   ports:
  #     - 8384:8384
  #     - 22000:22000
  #     - 21027:21027/udp
  #   restart: unless-stopped
  # navidrome:
  #   image: deluan/navidrome:latest
  #   container_name: navidrome
  #   user: 0:0 
  #   ports:
  #     - "4533:4533"
  #   restart: unless-stopped
  #   environment:
  #     # Optional: put your config options customization here. Examples:
  #     ND_SCANSCHEDULE: 1h
  #     ND_LOGLEVEL: error  
  #     ND_SESSIONTIMEOUT: 72h
  #     ND_BASEURL: ""
  #   volumes:
  #     - "/opt/aquar/storages/aquarpool/apps/navidrome/data:/data"
  #     - "/opt/aquar/storages/aquarpool/music:/music:ro"
  rustdesk-hbbs:
    container_name: rustdesk-hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r example.com:21117
    volumes:
      - /opt/aquar/storages/aquarpool/apps/rustdesk/hbbs:/root
    networks:
      - rustdesk-net
    depends_on:
      - rustdesk-hbbr
    restart: unless-stopped
  rustdesk-hbbr:
    container_name: rustdesk-hbbr
    ports:
      - 21117:21117
      - 21119:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - /opt/aquar/storages/aquarpool/apps/rustdesk/hbbr:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    networks:
      - app
      - proxy
    #ports:
      #- "8082:8082"
    labels:
      - traefik.enable=true

      - traefik.http.routers.qbittorrent.rule=Host(`qb.haiyaa-sobel.cc`)
      - traefik.http.routers.qbittorrent.entrypoints=websecure
      
      - traefik.http.routers.qbittorrent.tls=true # 啟用 TLS
      - traefik.http.routers.qbittorrent.tls.certresolver=resolverX

      - traefik.http.routers.qbittorrent.service=qbittorrent
      - traefik.docker.network=proxy

      - traefik.http.services.qbittorrent.loadbalancer.server.port=8082
    environment:
      - PUID=1000
      - PGID=1000
      - TZ="Asia/Taipei"
      - WEBUI_PORT=8082
    volumes:
      - /opt/aquar/storages/aquarpool/apps/qbittorrent/config:/config
      - /opt/aquar/storages/aquarpool/qbdownloads:/downloads
      # - /opt/vc/lib:/opt/vc/lib #optional
    #ports:
      #- 8082:8082
      #- 6881:6881
      #- 6881:6881/udp
    restart: unless-stopped
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    # extends:
    #   file: hwaccel.transcoding.yml
    #   service: cpu # set to one of [nvenc, quicksync, rkmpp, vaapi, vaapi-wsl] for accelerated transcoding
    networks:
      - core
      - app
      - proxy
    #ports:
      #- "2283:2283"
    labels:
      - traefik.enable=true

      - traefik.http.routers.immich.rule=Host(`photo.haiyaa-sobel.cc`)
      - traefik.http.routers.immich.entrypoints=websecure

      - traefik.http.routers.immich.tls=true # 啟用 TLS
      - traefik.http.routers.immich.tls.certresolver=resolverX

      - traefik.http.routers.immich.service=immich
      - traefik.docker.network=proxy

      - traefik.http.services.immich.loadbalancer.server.port=2283
    volumes:
      # Do not edit the next line. If you want to change the media storage location on your system, edit the value of UPLOAD_LOCATION in the .env file
      - /opt/aquar/storages/aquarpool/apps/immich/library:/data
      - /etc/localtime:/etc/localtime:ro
    depends_on:
      - immich-redis
      - immich-database
    environment:
      UPLOAD_LOCATION: /opt/aquar/storages/aquarpool/apps/immich/library
      TZ: Asia/Taipei
      DB_HOSTNAME: immich-database
      REDIS_HOSTNAME: immich-redis
    restart: unless-stopped
  # 只有內顯，保留作為debug接螢幕使用，待哪天有錢加獨顯再說
  # immich-machine-learning:
  #   container_name: immich_machine_learning
  #   # For hardware acceleration, add one of -[armnn, cuda, rocm, openvino, rknn] to the image tag.
  #   # Example tag: v2-cuda
  #   image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
  #   # extends: # uncomment this section for hardware acceleration - see https://docs.immich.app/features/ml-hardware-acceleration
  #   #   file: hwaccel.ml.yml
  #   #   service: cpu # set to one of [armnn, cuda, rocm, openvino, openvino-wsl, rknn] for accelerated inference - use the '-wsl' version for WSL2 where applicable
  #   volumes:
  #     - /opt/aquar/storages/aquarpool/apps/immich/immich_machinelearning/model-cache:/cache
  #   environment:
  #     IMMICH_VERSION: v2
  #     TZ: Asia/Taipei
  #   restart: unless-stopped
  #   healthcheck:
  #     disable: false
  immich-redis:
    container_name: immich_redis
    image: docker.io/valkey/valkey:9@sha256:fb8d272e529ea567b9bf1302245796f21a2672b8368ca3fcb938ac334e613c8f
    networks:
      - core
    environment:
      TZ: Asia/Taipei
    healthcheck:
      test: redis-cli ping || exit 1
    restart: unless-stopped
  immich-database:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23
    networks:
      - core
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=immich
      - POSTGRES_INITDB_ARGS='--data-checksums'
      # Uncomment the DB_STORAGE_TYPE: 'HDD' var if your database isn't stored on SSDs
      - DB_STORAGE_TYPE=HDD
    volumes:
      - /opt/aquar/storages/aquarpool/apps/immich/postgres:/var/lib/postgresql/data
    shm_size: 128mb
    restart: unless-stopped
  stirling-pdf:
    image: stirlingtools/stirling-pdf:latest
    networks:
      - app
      - proxy
    #ports:
      #- '8087:8080'
    labels:
      - traefik.enable=true

      - traefik.http.routers.stirling-pdf.rule=Host(`pdf.haiyaa-sobel.cc`)
      - traefik.http.routers.stirling-pdf.entrypoints=websecure

      - traefik.http.routers.stirling-pdf.tls=true # 啟用 TLS
      - traefik.http.routers.stirling-pdf.tls.certresolver=resolverX

      - traefik.http.routers.stirling-pdf.service=stirling-pdf
      - traefik.docker.network=proxy

      - traefik.http.services.stirling-pdf.loadbalancer.server.port=8080    
    volumes:
      - /opt/aquar/storages/aquarpool/apps/stirling_pdf/training_data:/usr/share/tessdata # OCR language files
      - /opt/aquar/storages/aquarpool/apps/stirling_pdf/configs:/configs # Settings & database
      - /opt/aquar/storages/aquarpool/apps/stirling_pdf/logs:/logs                     # Application logs
      - /opt/aquar/storages/aquarpool/apps/stirling_pdf/pipeline:/pipeline             # Automation configs
    environment:
      - DOCKER_ENABLE_SECURITY=false
      - INSTALL_BOOK_AND_ADVANCED_HTML_OPS=true # 安裝全部功能
      - LANGS=zh_TW # 界面語言
      - JAVA_CUSTOM_OPTS=-Dmanagement.endpoints.web.exposure.include=prometheus,health,info -Dmanagement.endpoint.health.show-details=always -Dmanagement.metrics.export.prometheus.enabled=true -Denterprisemanagement.metrics.enabled=true
    restart: unless-stopped
  # heimdall:
  #   image: lscr.io/linuxserver/heimdall:latest
  #   container_name: heimdall
  #   environment:
  #     - PUID=1000
  #     - PGID=1000
  #     - TZ=Asia/Taipei
  #     - ALLOW_INTERNAL_REQUESTS=false #optional
  #   volumes:
  #     - /opt/aquar/storages/aquarpool/apps/heimdall/config:/config
  #   ports:
  #     - 80:80
  #     - 443:443
  #   restart: unless-stopped
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    networks:
      - app
      - proxy
    ports:
      - 8000:8000
      - 9443:9443
      - 9000:9000
    volumes:
      - /opt/aquar/storages/aquarpool/apps/portainer/data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
  dashy:
    # To build from source, replace 'image: lissy93/dashy' with 'build: .'
    # build: .
    image: lissy93/dashy
    container_name: Dashy
    networks:
      - app
      - proxy
    # Pass in your config file below, by specifying the path on your host machine
    # volumes:
      # - /root/my-config.yml:/app/user-data/conf.yml
    volumes:
      - /opt/aquar/storages/aquarpool/apps/dashy/config/dashy_config.yml:/app/user-data/conf.yml
    #ports:
      #- 8086:8080
    # Set any environmental variables
    environment:
      - NODE_ENV=production
    labels:
      - traefik.enable=true

      - traefik.http.routers.dashy.rule=Host(`haiyaa-sobel.cc`)
      - traefik.http.routers.dashy.entrypoints=websecure

      - traefik.http.routers.dashy.tls=true # 啟用 TLS
      - traefik.http.routers.dashy.tls.certresolver=resolverX

      - traefik.http.routers.dashy.service=dashy
      - traefik.docker.network=proxy

      - traefik.http.services.dashy.loadbalancer.server.port=8080
    environment:
      - NODE_ENV=production
    # Specify your user ID and group ID. You can find this by running `id -u` and `id -g`
      - UID=1000
      - GID=1000
    # Specify restart policy
    restart: unless-stopped
    # Configure healthchecks
    healthcheck:
      test: ['CMD', 'node', '/app/services/healthcheck']
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF
# mkdir -p /opt/aquar/src/docker-compose/mariadb.init.d
# touch /opt/aquar/src/docker-compose/mariadb.init.d/init.sql
# cat > /opt/aquar/src/docker-compose/mariadb.init.d/init.sql <<EOF
# -- CREATE DATABASE IF NOT EXISTS nextcloud;
# -- CREATE DATABASE IF NOT EXISTS piwigo;
# -- CREATE DATABASE IF NOT EXISTS shinobi;
# -- CREATE DATABASE IF NOT EXISTS ccio;
# -- CREATE DATABASE IF NOT EXISTS photoprism;
# -- CREATE DATABASE IF NOT EXISTS filerun;
# CREATE USER 'root'@'localhost' IDENTIFIED BY 'root';
# GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
# EOF


echo '********設定開機啟動docker-compose********'
cat >  /lib/systemd/system/aquar.service <<EOF
[Unit]
Description=Aquar service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
Group=root
TimeoutStartSec=0
ExecStart=/usr/local/bin/aqserv start
SyslogIdentifier=aqserv

[Install]
WantedBy=multi-user.target
EOF
systemctl enable aquar

echo '********啟動docker-compose********'
cd /opt/aquar/src/docker-compose/
docker compose up -d
mkdir -p /opt/aquar/storages/apps/filerun/html/system/data/temp
# systemctl start aquar