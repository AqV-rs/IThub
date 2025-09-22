data "vkcs_compute_flavor" "db" {
  name = var.db-instance-flavor
}

resource "vkcs_db_instance" "db-instance" {
  name        = "db-instance"
  datastore {
    type    = "mysql"
    version = "8.0"
  }
  floating_ip_enabled = true
  flavor_id   = data.vkcs_compute_flavor.db.id
  size        = 30
  volume_type = "ceph-ssd"
  disk_autoexpand {
    autoexpand    = true
    max_disk_size = 100
  }
  network {
    uuid = vkcs_networking_network.db.id
  }
}

resource "vkcs_db_database" "db-database" {
  name        = "db1"
  dbms_id = vkcs_db_instance.db-instance.id
  charset     = "utf8"
}

resource "vkcs_db_user" "db-user" {
  name        = "nliskov"
  password    = var.db_user_password
  dbms_id = vkcs_db_instance.db-instance.id
  databases   = [vkcs_db_database.db-database.name]
}