# ================================================
# File: roles/day2_ops/README.md
# ================================================
# Day Two Ops Role


This role performs independent, best-effort maintenance on STIG-hardened RHEL nodes:


* Optional fapolicyd relaxation during maintenance; restored afterwards.
* Backups of containerd, Kubernetes manifests/config, and etcd snapshots (control-plane).
* Kubernetes upgrade (kubeadm/kubelet/kubectl) separate from RHEL packages.
* STIG report generation with `oscap` from SSG.
* Optional ACAS/Nessus agent check-in.
* Log cleanup (journald vacuum, container logs prune, containerd image prune).
* Validation checks.


Every task uses `ignore_errors: yes` so execution continues regardless of failures. Use tags to run subsets.