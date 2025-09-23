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

resource "vkcs_networking_port" "vm_port" {
  name       = "port-ITHUB-${var.lastname}"
  admin_state_up = true
  network_id = vkcs_networking_network.private_net.id
  full_security_groups_control = true

  fixed_ip {
    subnet_id  = vkcs_networking_subnet.private_subnet.id
    ip_address = "192.168.250.101"
  }
}

resource "vkcs_networking_port_secgroup_associate" "port_sg_assoc" {
  port_id            = vkcs_networking_port.vm_port.id
  security_group_ids = [vkcs_networking_secgroup.web_sg.id]
}

resource "vkcs_compute_instance" "compute" {
  name              = "ITHUBterraforubuntuper1-${var.lastname}"
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
    hostname: "ITHUBterraforubuntuper1-${var.lastname}"
    fqdn: "ITHUBterraforubuntuper1-${var.lastname}"
    package_update: true
    package_upgrade: true
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl restart nginx
  EOF

  network {
    port = vkcs_networking_port.vm_port.id
  }

  depends_on = [
    vkcs_networking_port.vm_port,
    vkcs_networking_port_secgroup_associate.port_sg_assoc
  ]
}

resource "vkcs_networking_floatingip" "fip" {
  pool = data.vkcs_networking_network.extnet.name
  port_id = vkcs_networking_port.vm_port.id
}

output "instance_name" {
  description = "Hostname / instance name"
  value       = vkcs_compute_instance.compute.name
}

output "private_ip" {
  description = "Reserved fixed (private) IP on subnet"
  value       = vkcs_networking_port.vm_port.fixed_ip[0].ip_address
}

output "public_ip" {
  description = "Floating IP assigned"
  value       = vkcs_networking_floatingip.fip.address
}
