talos_version      = "v1.9.5"
talos_cluster_name = "k8s.local"
talos_cluster_vip  = "192.168.0.200"
gateway            = "192.168.0.254"
nameservers        = ["192.168.0.253"]
talos_master_nodes = [
  {
    hostname              = "master0"
    interface             = "eno1"
    address               = "192.168.0.201/24"
    install_disk_selector = "eui.0025388981b8*"
  },
  {
    hostname              = "master1"
    interface             = "eno1"
    address               = "192.168.0.202/24"
    install_disk_selector = "eui.0025388981b8*"
  },
  {
    hostname              = "master2"
    interface             = "eno1"
    address               = "192.168.0.203/24"
    install_disk_selector = "eui.0025388981b8*"
  }
]
talos_worker_nodes = [
  {
    hostname              = "worker0"
    interface             = "eno1"
    address               = "192.168.0.204/24"
    install_disk_selector = "eui.0025388981b8*"
  },
  {
    hostname              = "worker1"
    interface             = "eno1"
    address               = "192.168.0.205/24"
    install_disk_selector = "eui.0025388981b8*"
  },
  {
    hostname              = "worker2"
    interface             = "eno1"
    address               = "192.168.0.206/24"
    install_disk_selector = "eui.0025388981b8*"
  },
  {
    hostname              = "worker3"
    interface             = "eno1"
    address               = "192.168.0.207/24"
    install_disk_selector = "eui.0025388981b8*"
  }
]
