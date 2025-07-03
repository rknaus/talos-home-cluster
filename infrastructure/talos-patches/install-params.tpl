---
machine:
  install:
    image: ghcr.io/siderolabs/installer:${talos_version}
    disk: none
    diskSelector:
      wwid: ${talos_install_disk_selector}
