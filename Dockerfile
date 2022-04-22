FROM alpine

RUN apk update \
    && apk add samba tzdata

RUN mkdir -p /mnt

ARG SMB_USER
ARG SMB_PASSWORD

RUN adduser -S $SMB_USER
RUN echo $SMB_PASSWORD | tee - | smbpasswd -a -s $SMB_USER

RUN { \
    echo "[global]"; \
    echo "  security = user"; \
    echo "  map to guest = Bad User"; \
    echo "  server min protocol = SMB2"; \
    echo "  log level = 1"; \
    echo "  log file = /var/log/samba/%I.log"; \
    echo "  max log size = 4096"; \
    echo ""; \
    echo "[mnt]"; \
    echo "  path = /mnt"; \
    echo "  valid users = ${SMB_USER}"; \
    echo "  guest ok = no"; \
    echo "  browsable = yes"; \
    echo "  writable = yes"; \
    echo "  create mode = 0666"; \
    echo "  directory mode = 0777"; \
    echo "  vfs objects = full_audit"; \
    echo "  full_audit:prefix = %m|%I"; \
    echo "  full_audit:success = open"; \
    echo "  full_audit:failure = connect"; \
    echo "  full_audit:facility = local1"; \
} > /etc/samba/smb.conf

EXPOSE 137/udp \
       138/udp \
       139/tcp \
       445/tcp

ENTRYPOINT ["/bin/ash", "-c", "smbd --foreground --no-process-group"]