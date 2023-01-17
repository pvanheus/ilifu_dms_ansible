terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.45.0"
    }
  }
}

provider "openstack" {}


resource "openstack_compute_instance_v2" "overture_vm" {
  name        = "overture"
  flavor_name = "ilifu-E"
  key_pair    = data.openstack_compute_keypair_v2.keypair.name
  image_name  = data.openstack_images_image_v2.overture_image.name

  block_device {
    uuid                  = data.openstack_images_image_v2.overture_image.id
    source_type           = "image"
    volume_size           = 100
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    uuid = data.openstack_networking_network_v2.sanbi_net.id
  }

#  provisioner "local-exec" {
#    command = ". ./cloudns_settings.sh && cloudns-api/bin/cloudns_api.sh -f delrecord sanbi.ac.za $(cloudns-api/bin/cloudns_api.sh listrecords sanbi.ac.za showid=true|awk '/${self.name}\t/ {sub(/.*;/, empty); print; exit;}')"
#    when = destroy
#  }
  security_groups = ["default", "server_secgroup"]

  provisioner "local-exec" {
    when = destroy
    command = "id=$(. ./cloudns_settings.sh && cloudns-api/bin/cloudns_api.sh listrecords sanbi.ac.za type=A host=${self.name} showid=true|cut -d';' -f 2|cut -d= -f2) && . ./cloudns_settings.sh && cloudns-api/bin/cloudns_api.sh -f delrecord sanbi.ac.za id=$id"
  }
}

# output "floating_ips" {
#   value = {
#     for i, fip in openstack_compute_floatingip_associate_v2.fip:
#       openstack_compute_instance_v2.workbench_vm[i].name => fip.floating_ip
#   }
# }

output "ext_ip" {
  value = openstack_compute_floatingip_associate_v2.fip.floating_ip
}

data "openstack_networking_network_v2" "sanbi_net" {
  name = "SANBI-net"
}

data "openstack_compute_keypair_v2" "keypair" {
  name = "${var.keypair_name}"
}

data "openstack_images_image_v2" "overture_image" {
  name = "${var.image_name}"
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  instance_id = openstack_compute_instance_v2.overture_vm.id
  wait_until_associated = true

  provisioner "local-exec" {
    command = ". ./cloudns_settings.sh && cloudns-api/bin/cloudns_api.sh addrecord sanbi.ac.za host=${openstack_compute_instance_v2.overture_vm.name} record=${self.floating_ip} type=A  ttl=60"
  }

}

resource "openstack_networking_floatingip_v2" "fip" {
  pool = "Ext_Floating_IP"
}
