  data "vkcs_networking_network" "extnet" {
    name = "internet"
  }

  data "vkcs_images_image" "ubuntu2204" {
    visibility = "public"
    default    = true
    properties = {
      mcs_os_distro  = "ubuntu"
      mcs_os_version = "22.04"
    }
  }

  data "vkcs_compute_flavor" "compute" {
    name = var.compute_flavor
  }

  resource "vkcs_networking_network" "private_net" {
    name = "ITHUBterraformnetwork-${var.lastname}"
  }

  resource "vkcs_networking_subnet" "private_subnet" {
    name       = "ITHUBterraformsubnet-${var.lastname}"
    network_id = vkcs_networking_network.private_net.id
    cidr       = "192.168.250.0/24"
    dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  }

  resource "vkcs_networking_router" "router" {
    name                = "ITHUBterraformrouter-${var.lastname}"
    external_network_id = data.vkcs_networking_network.extnet.id
  }

  resource "vkcs_networking_router_interface" "ri" {
    router_id = vkcs_networking_router.router.id
    subnet_id = vkcs_networking_subnet.private_subnet.id
    depends_on = [vkcs_networking_router.router]
  }

  resource "vkcs_networking_secgroup" "web_sg" {
    name        = "ITHUBterraform-sg-${var.lastname}"
    description = "Allow ssh(22), http(80), https(443) ingress; allow udp/53 egress"
  }

  resource "vkcs_networking_secgroup_rule" "ingress_ssh" {
    security_group_id = vkcs_networking_secgroup.web_sg.id
    direction         = "ingress"
    protocol          = "tcp"
    port_range_min    = 22
    port_range_max    = 22
    remote_ip_prefix  = "0.0.0.0/0"
    description       = "SSH"
  }

  resource "vkcs_networking_secgroup_rule" "ingress_http" {
    security_group_id = vkcs_networking_secgroup.web_sg.id
    direction         = "ingress"
    protocol          = "tcp"
    port_range_min    = 80
    port_range_max    = 80
    remote_ip_prefix  = "0.0.0.0/0"
    description       = "HTTP"
  }

  resource "vkcs_networking_secgroup_rule" "ingress_https" {
    security_group_id = vkcs_networking_secgroup.web_sg.id
    direction         = "ingress"
    protocol          = "tcp"
    port_range_min    = 443
    port_range_max    = 443
    remote_ip_prefix  = "0.0.0.0/0"
    description       = "HTTPS"
  }

  resource "vkcs_networking_secgroup_rule" "egress_dns" {
    security_group_id = vkcs_networking_secgroup.web_sg.id
    direction         = "egress"
    protocol          = "udp"
    port_range_min    = 53
    port_range_max    = 53
    remote_ip_prefix  = "0.0.0.0/0"
    description       = "DNS"
  }

  resource "vkcs_networking_port" "haproxy_port" {
    name       = "port-haproxy-${var.lastname}"
    admin_state_up = true
    network_id = vkcs_networking_network.private_net.id
    full_security_groups_control = true

    fixed_ip {
      subnet_id  = vkcs_networking_subnet.private_subnet.id
      ip_address = "192.168.250.101"
    }
  }

  resource "vkcs_networking_port" "be1_port" {
    name       = "port-be1-${var.lastname}"
    admin_state_up = true
    network_id = vkcs_networking_network.private_net.id
    full_security_groups_control = true

    fixed_ip {
      subnet_id  = vkcs_networking_subnet.private_subnet.id
      ip_address = "192.168.250.102"
    }
  }

  resource "vkcs_networking_port" "be2_port" {
    name       = "port-be2-${var.lastname}"
    admin_state_up = true
    network_id = vkcs_networking_network.private_net.id
    full_security_groups_control = true

    fixed_ip {
      subnet_id  = vkcs_networking_subnet.private_subnet.id
      ip_address = "192.168.250.103"
    }
  }


  resource "vkcs_networking_port_secgroup_associate" "haproxy_sg_assoc" {
    port_id            = vkcs_networking_port.haproxy_port.id
    security_group_ids = [vkcs_networking_secgroup.web_sg.id]
  }

  resource "vkcs_networking_port_secgroup_associate" "be1_sg_assoc" {
    port_id            = vkcs_networking_port.be1_port.id
    security_group_ids = [vkcs_networking_secgroup.web_sg.id]
  }

  resource "vkcs_networking_port_secgroup_associate" "be2_sg_assoc" {
    port_id            = vkcs_networking_port.be2_port.id
    security_group_ids = [vkcs_networking_secgroup.web_sg.id]
  }


  resource "vkcs_compute_instance" "haproxy" {
    name              = "haproxy-${var.lastname}"
    flavor_id         = data.vkcs_compute_flavor.compute.id
    key_pair          = var.key_pair_name
    availability_zone = var.me1

    block_device {
      uuid                  = data.vkcs_images_image.ubuntu2204.id
      source_type           = "image"
      destination_type      = "volume"
      volume_type           = "ceph-ssd"
      volume_size           = 20
      boot_index            = 0
      delete_on_termination = true
    }

  //  user_data = <<-EOF
  //    #cloud-config
  //    hostname: "ITHUBterraforubuntuper1-${var.lastname}"
  //    fqdn: "ITHUBterraforubuntuper1-${var.lastname}"
  //    package_update: true
  //    package_upgrade: true
  //    packages:
  //      - nginx
  //    runcmd:
  //      - systemctl enable nginx
  //      - systemctl restart nginx
  //  EOF

  network {
    port = vkcs_networking_port.haproxy_port.id
  }


    depends_on = [
      vkcs_networking_port.haproxy_port,
      vkcs_networking_port_secgroup_associate.haproxy_sg_assoc
    ]
  }


  resource "vkcs_compute_instance" "be1" {
    name              = "be1-${var.lastname}"
    flavor_id         = data.vkcs_compute_flavor.compute.id
    key_pair          = var.key_pair_name
    availability_zone = var.ms1

    block_device {
      uuid                  = data.vkcs_images_image.ubuntu2204.id
      source_type           = "image"
      destination_type      = "volume"
      volume_type           = "ceph-ssd"
      volume_size           = 20
      boot_index            = 0
      delete_on_termination = true
    }

  //  user_data = <<-EOF
  //    #cloud-config
  //    hostname: "ITHUBterraforubuntuper1-${var.lastname}"
  //    fqdn: "ITHUBterraforubuntuper1-${var.lastname}"
  //    package_update: true
  //    package_upgrade: true
  //    packages:
  //      - nginx
  //    runcmd:
  //      - systemctl enable nginx
  //      - systemctl restart nginx
  //  EOF

  network {
    port = vkcs_networking_port.be1_port.id
  }


    depends_on = [
      vkcs_networking_port.be1_port,
      vkcs_networking_port_secgroup_associate.be1_sg_assoc
    ]
  }

  resource "vkcs_compute_instance" "be2" {
    name              = "be2-${var.lastname}"
    flavor_id         = data.vkcs_compute_flavor.compute.id
    key_pair          = var.key_pair_name
    availability_zone = var.gz1

    block_device {
      uuid                  = data.vkcs_images_image.ubuntu2204.id
      source_type           = "image"
      destination_type      = "volume"
      volume_type           = "ceph-ssd"
      volume_size           = 20
      boot_index            = 0
      delete_on_termination = true
    }

  //  user_data = <<-EOF
  //    #cloud-config
  //    hostname: "ITHUBterraforubuntuper1-${var.lastname}"
  //    fqdn: "ITHUBterraforubuntuper1-${var.lastname}"
  //    package_update: true
  //    package_upgrade: true
  //    packages:
  //      - nginx
  //    runcmd:
  //      - systemctl enable nginx
  //      - systemctl restart nginx
  //  EOF

    network {
      port = vkcs_networking_port.be2_port.id
    }

    depends_on = [
      vkcs_networking_port.be2_port,
      vkcs_networking_port_secgroup_associate.be2_sg_assoc
    ]
  }

  resource "vkcs_networking_floatingip" "fip" {
    pool = data.vkcs_networking_network.extnet.name
    port_id = vkcs_networking_port.haproxy_port.id
  }

  data "vkcs_compute_flavor" "db" {
    name = var.db-instance-flavor
  }

resource "vkcs_db_instance" "db_instance" {
  name = "db-instance-${var.lastname}"

  datastore {
    type    = "mysql"
    version = "8.0"
  }

  floating_ip_enabled = false
  flavor_id           = data.vkcs_compute_flavor.db.id
  size                = 30
  volume_type         = "ceph-ssd"

  disk_autoexpand {
    autoexpand    = true
    max_disk_size = 100
  }

  network {
    uuid            = vkcs_networking_network.private_net.id
    subnet_id       = vkcs_networking_subnet.private_subnet.id   # ← ОБЯЗАТЕЛЬНО
    security_groups = [vkcs_networking_secgroup.db_sg.id]
  }
}

  resource "vkcs_db_database" "db_database" {
    name    = "db1"
    dbms_id = vkcs_db_instance.db_instance.id
    charset = "utf8"
  }

  resource "vkcs_db_user" "db_user" {
    name     = "nliskov"
    password = var.db_user_password
    dbms_id  = vkcs_db_instance.db_instance.id
    databases = [
      vkcs_db_database.db_database.name
    ]
  }

  resource "vkcs_networking_secgroup" "db_sg" {
    name        = "db-sg-${var.lastname}"
    description = "Allow MySQL only from BE servers"
  }

  resource "vkcs_networking_secgroup_rule" "db_allow_be1" {
    security_group_id = vkcs_networking_secgroup.db_sg.id
    direction         = "ingress"
    protocol          = "tcp"
    port_range_min    = 3306
    port_range_max    = 3306
    remote_ip_prefix  = "192.168.250.102/32"  # BE1
  }

  resource "vkcs_networking_secgroup_rule" "db_allow_be2" {
    security_group_id = vkcs_networking_secgroup.db_sg.id
    direction         = "ingress"
    protocol          = "tcp"
    port_range_min    = 3306
    port_range_max    = 3306
    remote_ip_prefix  = "192.168.250.103/32"  # BE2
  }

resource "local_file" "ansible_inventory" {
  content = <<EOF
[haproxy]
${vkcs_compute_instance.haproxy.access_ip_v4} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[backends]
${vkcs_compute_instance.be1.access_ip_v4} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
${vkcs_compute_instance.be2.access_ip_v4} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

  filename = "${path.module}/inventory.ini"
}

