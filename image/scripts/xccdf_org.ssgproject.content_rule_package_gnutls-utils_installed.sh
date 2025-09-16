#!/bin/sh
set -e

(>&2 echo "Remediating: 'xccdf_org.ssgproject.content_rule_package_gnutls-utils_installed'")

if ! rpm -q --quiet "gnutls-utils" ; then
    dnf install -y "gnutls-utils"
fi

