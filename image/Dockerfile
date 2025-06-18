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

# Install and configure SemaphoreUI, Ansible, Terraform
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

# Enable and start required services
RUN systemctl enable crond.service
RUN systemctl enable postfix.service

RUN curl -L https://github.com/projectcalico/calico/releases/download/v3.30.1/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
RUN chmod +x /usr/local/bin/calicoctl
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
RUN dnf install -y azure-cli
RUN yum-config-manager --add-repo https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
RUN dnf install -y kubectl
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

ENV container=oci
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CMD ["/etc/semaphore/semaphore.sh", "start"]
