#!/bin/bash

# STIG FINDINGS ######## Should be run AFTER openscap
# STIG Implementations

# V-258134 RHEL 9 must have the AIDE package installed
 dnf install -y aide

# V-258136 Configure AIDE to Use FIPS 140-2 for Validating Hashes
 aide --init

# V-257787 - RHEL 9 must require a boot loader superuser password.
 passwd="1qaz2wsx3edc$RFV"
 echo -e "$passwd\n$passwd" | grub2-mkpasswd-pbkdf2 | awk '/hash of / {print $NF}'

# V-257811 - RHEL 9 must restrict usage of ptrace to descendant processes. 
 echo "kernel.yama.ptrace_scope = 1" >> /etc/sysctl.d/ptrace.conf
 echo 's#kernel.yama.ptrace_scope = 0#kernel.yama.ptrace_scope = 1#g' /usr/lib/sysctl.d/10-default-yama-scope.conf
 echo 's#kernel.yama.ptrace_scope = 0#kernel.yama.ptrace_scope = 1#g' /lib/sysctl.d/10-default-yama-scope.conf

# V-? Enable Authselect
 authselect select sssd with-faillock --force

# V-257789 RHEL 9 must require a unique superusers name upon booting into single-user and maintenance modes.
 sed -i 's/superusers="root"/superusers="bootmaster"/g' /etc/grub.d/01_users
 grubby --update-kernel=ALL

# V-258076 - RHEL 9 must display the date and time of the last successful account logon upon logon.
 sed -i 's/silent//g' /etc/pam.d/postlogin
 sed -i '3i session required pam_lastlog.so showfailed' /etc/pam.d/postlogin

# V-258094 - RHEL 9 must not allow blank or null passwords.
 sed -i 's#nullok##g' /etc/pam.d/password-auth
 sed -i 's#nullok##g' /etc/pam.d/system-auth

# V-258091 - RHEL 9 must ensure the password complexity module in the system-auth file is configured for three retries or less.
 sed -i 's#password    requisite                                    pam_pwquality.so local_users_only#password    required                                    pam_pwquality.so retry=3 local_users_only#g' /etc/pam.d/password-auth
 sed -i 's#password    requisite                                    pam_pwquality.so local_users_only#password    required                                    pam_pwquality.so retry=3 local_users_only#g' /etc/pam.d/system-auth

# V-258099 - RHEL 9 password-auth must be configured to use a sufficient number of hashing rounds.
 sed -i 's/use_authtok/use_authtok rounds=5000/g' /etc/pam.d/password-auth
 sed -i 's/use_authtok/use_authtok rounds=5000/g' /etc/pam.d/system-auth


# V-257782 - RHEL 9 must enable the hardware random number generator entropy gatherer service. #
 dnf install -y rng-tools
 systemctl enable --now rngd

# V-258067 - RHEL 9 must prevent users from disabling session control mechanisms.
 sed -i '/tmux/d' /etc/shells

# USBGuard must be installed and enabled
 dnf install -y usbguard

# V-258037 - RHEL 9 must enable Linux audit logging for the USBGuard daemon.
 sed -i 's/AuditBackend=FileAudit/AuditBackend=LinuxAudit/g' /etc/usbguard/usbguard-daemon.conf

 sysctl --system

# V-257945 RHEL 9 must securely compare internal information system clocks at least every 24 hours.
 sed -i 's/pool 2.rhel.pool.ntp.org iburst maxpoll 16/server 0.us.pool.ntp.mil iburst maxpoll 16/g' /etc/chrony.conf


# V-257989 - RHEL 9 must implement DOD-approved encryption ciphers to protect the confidentiality of SSH server connections.
 sed -i 's/Ciphers aes256-gcm@openssh.com,aes256-ctr,aes128-gcm@openssh.com,aes128-ctr/Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes128-gcm@openssh.com,aes128-ctr/g' /etc/crypto-policies/back-ends/openssh.config


# V-257991 - RHEL 9 SSH server must be configured to use only Message Authentication Codes (MACs) employing FIPS 140-3 validated cryptographic hash algorithms.
 sed -i 's/MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512/MACs hmac-sha2-256-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha1,umac-128@openssh.com,hmac-sha2-512/g' /etc/crypto-policies/back-ends/openssh.config

  # # V-257948 - RHEL 9 systems using Domain Name Servers (DNS) resolution must have at least two name servers configured. # Fix via Terraform init
  # # V-258125 - The pcscd service on RHEL 9 must be active. # WontFix

# V-258228 - RHEL 9 audit system must protect logon UIDs from unauthorized change.
 echo "--loginuid-immutable" >> /etc/audit/rules.d/audit.rules

# V-258229 - RHEL 9 audit system must protect auditing rules from unauthorized change.
 echo "-e 2" >> /etc/audit/rules.d/audit.rules

# V-258236 - RHEL 9 crypto policy must not be overridden.
 rm /etc/crypto-policies/back-ends/nss.config
 rm /etc/crypto-policies/back-ends/opensshserver.config
 rm /etc/crypto-policies/back-ends/openssh.config
 ln -s /usr/share/crypto-policies/FIPS/nss.txt /etc/crypto-policies/back-ends/nss.config
 ln -s /usr/share/crypto-policies/FIPS/opensshserver.txt /etc/crypto-policies/back-ends/opensshserver.config
 ln -s /usr/share/crypto-policies/FIPS/openssh.txt /etc/crypto-policies/back-ends/openssh.config

# STIG MANUAL CHECKS

# V-257937 A RHEL 9 firewall must employ a deny-all, allow-by-exception policy for allowing connections to other systems.
# firewall-cmd --permanent --add-service=ssh --zone=drop
# firewall-cmd --set-default-zone drop
# firewall-cmd --reload

# V-258042 - RHEL 9 user account passwords must have a 60-day maximum password lifetime restriction, V-258105 - RHEL 9 passwords must have a 24 hours minimum password lifetime restriction in /etc/shadow.
 passwd -x 60 -n 1 root

  # # V-258174 RHEL 9 must have mail aliases to notify the information system security officer (ISSO) and system administrator (SA) (at a minimum) in the event of an audit processing failure.
