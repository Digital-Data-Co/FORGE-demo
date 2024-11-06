#!/bin/sh

# 2023-05-12 update logic per upstream https://static.open-scap.org/ssg-guides/ssg-rhel9-guide-stig.html#xccdf_org.ssgproject.content_rule_accounts_umask_etc_bashrc
# remediates CCE-83644-5

set -e

(>&2 echo "Remediating: 'xccdf_org.ssgproject.content_rule_accounts_umask_etc_bashrc'")

var_accounts_user_umask="077"

grep -q "^\s*umask" /etc/bashrc && \
  sed -i -E -e "s/^(\s*umask).*/\1 $var_accounts_user_umask/g" /etc/bashrc
if ! [ $? -eq 0 ]; then
    echo "umask $var_accounts_user_umask" >> /etc/bashrc
fi
