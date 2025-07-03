---
machine:
  network:
    hostname: ${hostname}
    interfaces:
      - interface: ${interface}
        dhcp: false
        addresses:
          - ${address}
        routes:
          - network: 0.0.0.0/0
            gateway: ${gateway}
        mtu: 1500
    nameservers:
      ${nameservers}
