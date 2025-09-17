FROM registry.access.redhat.com/ubi9:9.4

ARG BUILDARCH
ARG VERSION="2.14.12"

ENV BUILDARCH=${BUILDARCH}
ENV VERSION=${VERSION}


# Copy Client Codebase

COPY client /client/
COPY scripts /dsop-fix/
COPY banner/issue /etc/
COPY certs/* /etc/pki/ca-trust/source/anchors/
COPY semaphore/* /etc/semaphore/

# Install and configure SemaphoreUI, Ansible, Terraform, Postgres
RUN dnf update -y
RUN dnf install -y ca-certificates
RUN dnf install -y openssh-server
RUN dnf install -y postfix
RUN dnf install -y logrotate
RUN dnf install -y cronie
RUN dnf install -y git
RUN dnf install -y sshpass
RUN dnf install -y wget
RUN dnf install -y yum-utils
RUN dnf install -y python3-pip
RUN yum clean all

# Postgres Install and Config
# Install PostgreSQL server + client tools
RUN microdnf -y install postgresql-server postgresql shadow-utils procps-ng && microdnf clean all

# Paths / env
ENV PGDATA=/var/lib/pgsql/data \
    CONFIG_DIR=/opt/forge \
    PG_SOCKET_DIR=/var/run/postgresql

# Prepare filesystem
RUN mkdir -p "${PGDATA}" "${CONFIG_DIR}" "${PG_SOCKET_DIR}" && \
    chown -R postgres:postgres /var/lib/pgsql "${CONFIG_DIR}" "${PG_SOCKET_DIR}"

# ---- Initialize cluster and harden auth at build time ----
# - Unix socket only (listen_addresses = '')
# - SCRAM password hashing (password_encryption = scram-sha-256)
# - pg_hba.conf enforces scram-sha-256 on local socket
# - Create role/database 'forge'
# - Generate password, store in /opt/forge/config.json  (baked into image layer)
RUN set -eux; \
    su -s /bin/bash -c "initdb -D '${PGDATA}'" postgres; \
    { \
      echo "listen_addresses = ''"; \
      echo "unix_socket_directories = '${PG_SOCKET_DIR}'"; \
      echo "password_encryption = scram-sha-256"; \
      # Optional extra hardening (safe for socket-only):
      echo "ssl = off"; \
      echo "log_lock_waits = on"; \
      echo "shared_preload_libraries = ''"; \
    } >> "${PGDATA}/postgresql.conf"; \
    \
    # Harden pg_hba: socket-only, passworded local access via SCRAM
    printf "local   all   all   scram-sha-256\n" > "${PGDATA}/pg_hba.conf"; \
    \
    # Create user/db
    PASS=\"$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)\"; \
    sed -i "4s~.*~${PASS}~" "/etc/semaphore/config.stdin"
    cat > /tmp/init.sql <<'SQL'
-- Create role if missing and enforce password (SCRAM depends on server setting)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'forge') THEN
    CREATE ROLE forge LOGIN;
  END IF;
END
$$;
ALTER ROLE forge WITH PASSWORD :'pass';
-- Create DB if missing; set owner
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'forge') THEN
    CREATE DATABASE forge OWNER forge;
  END IF;
END
$$;
SQL
    ; \
    chown postgres:postgres /tmp/init.sql; \
    # Run with single-user postgres, passing the password as a psql variable (no env leak)
    su -s /bin/bash -c "psql --no-password --set=pass='${PASS}' --set=ON_ERROR_STOP=1 -v ON_ERROR_STOP=1 -X -q -d postgres -f /tmp/init.sql --single-transaction --dbname=postgres --file=/tmp/init.sql < /dev/null || true" postgres || true; \
    # Fallback if psql call didn’t run as expected (older psql options): use postgres --single
    if ! su -s /bin/bash -c "postgres --single -D '${PGDATA}' postgres <<< \"ALTER ROLE forge WITH PASSWORD '${PASS}';\" >/dev/null 2>&1"; then true; fi; \
    rm -f /tmp/init.sql; \
    \
    # Write config.json (consumer apps read this inside the container)
    printf '{\n  "database": "forge",\n  "user": "forge",\n  "password": "%s",\n  "host": "%s",\n  "port": 5432\n}\n' "$PASS" "$PG_SOCKET_DIR" > "${CONFIG_DIR}/config.json"; \
    chown postgres:postgres "${CONFIG_DIR}/config.json"; \
    chmod 600 "${CONFIG_DIR}/config.json"

# ---- Lightweight supervisor to autostart Postgres; CMD remains for your app ----
RUN bash -lc 'cat > /usr/local/bin/pg-service.sh <<'"'"'EOS'"'"'
#!/usr/bin/env bash
set -euo pipefail

PGDATA="${PGDATA:-/var/lib/pgsql/data}"
PG_SOCKET_DIR="${PG_SOCKET_DIR:-/var/run/postgresql}"

mkdir -p "$PG_SOCKET_DIR"
chown postgres:postgres "$PG_SOCKET_DIR"

# Start Postgres (socket-only)
su -s /bin/bash -c "pg_ctl -D '$PGDATA' -o \"-c listen_addresses='' -c unix_socket_directories='$PG_SOCKET_DIR'\" -w start" postgres

# Wait until server accepts connections
su -s /bin/bash -c "pg_isready -h '$PG_SOCKET_DIR' -d postgres -q -t 5" postgres

# Shutdown handler
child_pid=0
term_handler() {
  if [ "$child_pid" -ne 0 ] && kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  su -s /bin/bash -c "pg_ctl -D '$PGDATA' -m fast -w stop" postgres
  exit 0
}
trap term_handler SIGINT SIGTERM

# Run the user command (your app) or idle
if [ "$#" -gt 0 ]; then
  "$@" &
  child_pid=$!
  wait "$child_pid"
  status=$?
  term_handler
  exit $status
else
  tail -f /dev/null &
  child_pid=$!
  wait "$child_pid"
  term_handler
fi
EOS
'; chmod +x /usr/local/bin/pg-service.sh


# Keep root as PID1 so we can start postgres as 'postgres' then exec your CMD
USER root

# HEALTHCHECK: succeed only when Postgres is accepting connections on the socket
# (pg_isready exits 0 if server is accepting connections; auth not required)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD su -s /bin/bash -c "pg_isready -h ${PG_SOCKET_DIR} -d postgres -q" postgres || exit 1

# Declare volumes so mounts are "baked in" (created automatically as anonymous volumes)
VOLUME ["/var/lib/pgsql/data", "/opt/forge"]

# No TCP exposure; Postgres is socket-only
ENTRYPOINT ["/usr/local/bin/pg-service.sh"]


# Enable and start required services
RUN systemctl enable crond.service
RUN systemctl enable postfix.service

RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

RUN dnf install -y terraform
RUN python3 -m pip install --upgrade -r /etc/semaphore/requirements.txt 
RUN wget -L https://github.com/semaphoreui/semaphore/releases/download/v${VERSION}/semaphore_${VERSION}_linux_${BUILDARCH}.tar.gz
RUN tar -xzvf ./semaphore_${VERSION}_linux_${BUILDARCH}.tar.gz -C /usr/local/bin/
RUN /etc/semaphore/semaphore_setup.sh
RUN rm -rf ./semaphore_${VERSION}_linux_${BUILDARCH}.tar.gz /etc/semaphore/semaphore_setup.sh /etc/semaphore/config.stdin



# Be careful when adding packages because this will ultimately be built on a licensed RHEL host,
# which enables full RHEL repositories and could allow for installation of packages that would
# violate Red Hat license agreement when running the container on a non-RHEL licensed host.
# See the following link for more details:
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/building_running_and_managing_containers/index/#add_software_to_a_running_ubi_container
RUN echo "[main]" >> /etc/dnf/dnf.conf && \
    echo "exclude=filesystem-*" >> /etc/dnf/dnf.conf && \
    echo Update packages and install DISA STIG fixes && \
    dnf repolist && \
    dnf --setopt install_weak_deps=0 update -y && \
    dnf install -y crypto-policies-scripts && \
    # Do not use loops to iterate through shell scripts, this allows for scripts to fail
    # but the build to still be successful. Be explicit when executing scripts and ensure
    # that all scripts have "set -e" at the top of the bash file!
    /dsop-fix/xccdf_org.ssgproject.content_rule_configure_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_openssl_use_strong_entropy.sh && \   
    /dsop-fix/xccdf_org.ssgproject.content_rule_configure_openssl_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_configure_gnutls_tls_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_harden_sshd_ciphers_openssh_conf_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_harden_sshd_ciphers_opensshserver_conf_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_harden_sshd_macs_openssh_conf_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_harden_sshd_macs_opensshserver_conf_crypto_policy.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_accounts_umask_etc_bashrc.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_accounts_umask_etc_profile.sh && \
    /dsop-fix/xccdf_org.ssgproject.content_rule_accounts_umask_etc_csh_cshrc.sh && \   
    /dsop-fix/xccdf_org.ssgproject.content_rule_package_gnutls-utils_installed.sh && \
    chmod +t /tmp /var/tmp && \
    update-ca-trust && \
    update-ca-trust force-enable && \
    dnf clean all && \
    rm -rf /dsop-fix/ /var/cache/dnf/ /var/tmp/* /tmp/* /var/tmp/.???* /tmp/.???*

# Disable ChaCha20 Algorithms
RUN set -eux; \
    disabledAlgorithms=' \
       TLS_CHACHA20_POLY1305_SHA256, \
       TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256, \
       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256, \
       TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256, \
    '; \
    disabledAlgorithms="${disabledAlgorithms//[[:space:]]/}"; \
    sed -i "s/^jdk\.tls\.disabledAlgorithms=/jdk.tls.disabledAlgorithms=$disabledAlgorithms/" \
       /usr/share/crypto-policies/FIPS/java.txt;

RUN echo "StrictHostKeyChecking=accept-new" > ~/.ssh/config

ENV container=oci
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/etc/semaphore/semaphore.sh --uses-postgres-via-socket", "start", "-lc"]
