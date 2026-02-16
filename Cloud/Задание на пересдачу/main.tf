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
  name            = "ITHUBterraformsubnet-${var.lastname}"
  network_id      = vkcs_networking_network.private_net.id
  cidr            = "192.168.250.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "vkcs_networking_router" "router" {
  name                = "ITHUBterraformrouter-${var.lastname}"
  external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "ri" {
  router_id  = vkcs_networking_router.router.id
  subnet_id  = vkcs_networking_subnet.private_subnet.id
  depends_on = [vkcs_networking_router.router]
}

resource "vkcs_networking_secgroup" "control_sg" {
  name        = "control-sg-${var.lastname}"
  description = "Control VM: allow SSH from Internet"
}

resource "vkcs_networking_secgroup_rule" "control_ingress_ssh" {
  security_group_id = vkcs_networking_secgroup.control_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "SSH to control"
}

resource "vkcs_networking_secgroup" "vm_sg" {
  name        = "vm-sg-${var.lastname}"
  description = "vm1/vm2: allow SSH/HTTP/HTTPS/ICMP only from control vm"
}

resource "vkcs_networking_secgroup_rule" "vm_ingress_ssh_from_control" {
  security_group_id = vkcs_networking_secgroup.vm_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = vkcs_networking_secgroup.control_sg.id
  description       = "SSH from control"
}

resource "vkcs_networking_secgroup_rule" "vm_ingress_http_from_control" {
  security_group_id = vkcs_networking_secgroup.vm_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = vkcs_networking_secgroup.control_sg.id
  description       = "HTTP from control"
}

resource "vkcs_networking_secgroup_rule" "vm_ingress_https_from_control" {
  security_group_id = vkcs_networking_secgroup.vm_sg.id
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_group_id   = vkcs_networking_secgroup.control_sg.id
  description       = "HTTPS from control"
}

resource "vkcs_networking_secgroup_rule" "vm_ingress_icmp_from_control" {
  security_group_id = vkcs_networking_secgroup.vm_sg.id
  direction         = "ingress"
  protocol          = "icmp"
  remote_group_id   = vkcs_networking_secgroup.control_sg.id
  description       = "ICMP from control"
}

resource "vkcs_networking_secgroup_rule" "vm_egress_all" {
  security_group_id = vkcs_networking_secgroup.vm_sg.id
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Egress all"
}

resource "vkcs_networking_secgroup_rule" "control_egress_all" {
  security_group_id = vkcs_networking_secgroup.control_sg.id
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "Egress all"
}


resource "vkcs_networking_port" "control_port" {
  name                        = "port-control-${var.lastname}"
  admin_state_up              = true
  network_id                  = vkcs_networking_network.private_net.id
  full_security_groups_control = true

  fixed_ip {
    subnet_id  = vkcs_networking_subnet.private_subnet.id
    ip_address = "192.168.250.10"
  }
}

resource "vkcs_networking_port_secgroup_associate" "control_port_sg" {
  port_id            = vkcs_networking_port.control_port.id
  security_group_ids = [vkcs_networking_secgroup.control_sg.id]
}

resource "vkcs_networking_port" "vm1_port" {
  name                        = "port-vm1-${var.lastname}"
  admin_state_up              = true
  network_id                  = vkcs_networking_network.private_net.id
  full_security_groups_control = true

  fixed_ip {
    subnet_id  = vkcs_networking_subnet.private_subnet.id
    ip_address = "192.168.250.101"
  }
}

resource "vkcs_networking_port_secgroup_associate" "vm1_port_sg" {
  port_id            = vkcs_networking_port.vm1_port.id
  security_group_ids = [vkcs_networking_secgroup.vm_sg.id]
}

resource "vkcs_networking_port" "vm2_port" {
  name                        = "port-vm2-${var.lastname}"
  admin_state_up              = true
  network_id                  = vkcs_networking_network.private_net.id
  full_security_groups_control = true

  fixed_ip {
    subnet_id  = vkcs_networking_subnet.private_subnet.id
    ip_address = "192.168.250.102"
  }
}

resource "vkcs_networking_port_secgroup_associate" "vm2_port_sg" {
  port_id            = vkcs_networking_port.vm2_port.id
  security_group_ids = [vkcs_networking_secgroup.vm_sg.id]
}

resource "vkcs_compute_instance" "control" {
  name              = "control-${var.lastname}"
  flavor_id         = data.vkcs_compute_flavor.compute.id
  key_pair          = var.key_pair_name
  availability_zone = var.availability_zone_name

  block_device {
    uuid                  = data.vkcs_images_image.ubuntu2204.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 10
    boot_index            = 0
    delete_on_termination = true
  }

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - ansible
  EOF

  network {
    port = vkcs_networking_port.control_port.id
  }

  depends_on = [vkcs_networking_port_secgroup_associate.control_port_sg]
}

resource "vkcs_compute_instance" "vm1" {
  name              = "vm1-${var.lastname}"
  flavor_id         = data.vkcs_compute_flavor.compute.id
  key_pair          = var.key_pair_name
  availability_zone = "MS1"

  block_device {
    uuid                  = data.vkcs_images_image.ubuntu2204.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 10
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = vkcs_networking_port.vm1_port.id
  }

  depends_on = [vkcs_networking_port_secgroup_associate.vm1_port_sg]
}

resource "vkcs_compute_instance" "vm2" {
  name              = "vm2-${var.lastname}"
  flavor_id         = data.vkcs_compute_flavor.compute.id
  key_pair          = var.key_pair_name
  availability_zone = "GZ1"

  block_device {
    uuid                  = data.vkcs_images_image.ubuntu2204.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 10
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = vkcs_networking_port.vm2_port.id
  }

  depends_on = [vkcs_networking_port_secgroup_associate.vm2_port_sg]
}


resource "vkcs_networking_floatingip" "control_fip" {
  pool    = data.vkcs_networking_network.extnet.name
  port_id = vkcs_networking_port.control_port.id
}

output "control_public_ip" {
  value = vkcs_networking_floatingip.control_fip.address
}

output "control_private_ip" {
  value = vkcs_networking_port.control_port.fixed_ip[0].ip_address
}

output "vm1_private_ip" {
  value = vkcs_networking_port.vm1_port.fixed_ip[0].ip_address
}

output "vm2_private_ip" {
  value = vkcs_networking_port.vm2_port.fixed_ip[0].ip_address
}
