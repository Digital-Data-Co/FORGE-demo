#!/bin/bash

# Extend Logical Volume
sudo growpart /dev/sda 4

# /var/log
sudo lvcreate -L 20g -n var-log-lv rootvg

# /var/log/audit
sudo lvcreate -L 20g -n var-log-audit-lv rootvg

# /var/tmp
sudo lvcreate -L 20g -n var-tmp-lv rootvg

# /datadrive
sudo lvcreate -L 380g -n datadrive-lv rootvg

# Create File Systems

# /var/log
sudo mkfs.xfs /dev/mapper/rootvg-var--log--lv

# /var/log/audit
sudo mkfs.xfs /dev/mapper/rootvg-var--log--audit--lv

# /var/tmp
sudo mkfs.xfs /dev/mapper/rootvg-var--tmp--lv

# /datadrive
sudo mkfs.xfs /dev/mapper/rootvg-datadrive--lv

#Edit /etc/fstab
echo "/dev/mapper/rootvg-var--log--lv /var/log               xfs   defaults,nodev,nosuid,noexec        0 0" | sudo tee -a /etc/fstab
echo "/dev/mapper/rootvg-var--tmp--lv /var/tmp               xfs   defaults,nodev,nosuid,noexec        0 0" | sudo tee -a /etc/fstab
echo "/dev/mapper/rootvg-datadrive--lv /datadrive            xfs   defaults,nodev,nosuid,noexec        0 0" | sudo tee -a /etc/fstab



