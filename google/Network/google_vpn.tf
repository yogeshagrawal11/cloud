

provider "google" {
  region  = "us-west1"
  zone    = "us-west1-a"
  project = var.gcpprojectid
  version = "~> 3.0.0-beta.1"

}



resource "google_compute_network" "g_vpc_network" {
  name                    = "g-vpc-network"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

}


resource "google_compute_subnetwork" "g_subnetwork" {
  name          = "sub-us-west1"
  network       = google_compute_network.g_vpc_network.id
  region        = "us-west1"
  ip_cidr_range = "10.100.1.0/24"
}


resource "google_compute_router" "gcp_cloud_router" {
  name    = "gcp-cloud-router"
  network = google_compute_network.g_vpc_network.name
  region  = "us-west1"
  bgp {
    asn               = 65001
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}
/*

resource "google_compute_router_interface" "interface_1" {
  name       = "interface-1"
  router     = google_compute_router.gcp_cloud_router.name
  region     = "us-west1"
  #ip_range   = "169.254.193.36/30"
  ip_range   = var.bgp_cr_session_range[0]
  vpn_tunnel = google_compute_vpn_tunnel.tunnel-dynamic1.name
}

resource "google_compute_router_interface" "interface_2" {
  name       = "interface-2"
  router     = google_compute_router.gcp_cloud_router.name
  region     = "us-west1"
  #ip_range   = "169.254.193.36/30"
  ip_range   = var.bgp_cr_session_range[1]
  vpn_tunnel = google_compute_vpn_tunnel.tunnel-dynamic2.name
}

resource "google_compute_router_interface" "interface_2" {
  name       = "interface-2"
  router     = google_compute_router.gcp_cloud_router.name
  region     = "us-west1"
  ip_range   = aws_vpn_connection.aws_to_gcp.tunnel2_inside_cidr
  vpn_tunnel = google_compute_vpn_tunnel.tunnel-dynamic2.name
}



resource "google_compute_router_peer" "gcp_cloud_router_peer1" {
  name                      = "gcp-cloud-router-peer1"
  router                    = google_compute_router.gcp_cloud_router.name
  region                    = "us-west1"
  peer_ip_address           = aws_vpn_connection.aws_to_gcp.tunnel1_vgw_inside_address
  peer_asn                  = 65002
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_1.name
}

resource "google_compute_router_peer" "gcp_cloud_router_peer2" {
  name                      = "gcp-cloud-router-peer2"
  router                    = google_compute_router.gcp_cloud_router.name
  region                    = "us-west1"
  peer_ip_address           = aws_vpn_connection.aws_to_gcp.tunnel2_vgw_inside_address
  peer_asn                  = 65002
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_2.name

}
*/
/*
resource "google_compute_router_peer" "gcp_cloud_router_peer2" {
  name                      = "gcp-cloud-router-peer2"
  router                    = google_compute_router.gcp_cloud_router.name
  region                    = "us-west1"
  peer_ip_address           = aws_vpn_connection.aws_to_gcp.tunnel2_address
  peer_asn                  = 65002
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_2.name
  advertise_mode            = "CUSTOM"
  advertised_groups         = ["ALL_SUBNETS"]

}

*/


resource "google_compute_vpn_gateway" "gcp_vpn_gateway" {
  name    = "gcp-vpn-gateway"
  network = google_compute_network.g_vpc_network.id
  region  = "us-west1"
}

resource "google_compute_address" "vpn_static_ip" {
  name   = "vpn-static-ip"
  region = "us-west1"
}


resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  region      = "us-west1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  region      = "us-west1"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  region      = "us-west1"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.gcp_vpn_gateway.self_link
}
/*
resource "google_compute_vpn_tunnel" "tunnel-dynamic1" {
  #name          = var.tunnel_count == 1 ? format("%s-%s", local.tunnel_name_prefix, "1") : format("%s-%d", local.tunnel_name_prefix, count.index + 1)

  name = "tunnel-dynamic1"
  #region        = var.region
  #project       = var.project_id
  peer_ip       = aws_vpn_connection.aws_to_gcp.tunnel1_address
  shared_secret = aws_vpn_connection.aws_to_gcp.tunnel1_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gateway.self_link

  router      = google_compute_router.gcp_cloud_router.self_link
  ike_version = "1"

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "tunnel-dynamic2" {
  #name          = var.tunnel_count == 1 ? format("%s-%s", local.tunnel_name_prefix, "1") : format("%s-%d", local.tunnel_name_prefix, count.index + 1)

  name = "tunnel-dynamic2"

  peer_ip       = aws_vpn_connection.aws_to_gcp.tunnel2_address
  shared_secret = aws_vpn_connection.aws_to_gcp.tunnel2_preshared_key

  target_vpn_gateway = google_compute_vpn_gateway.gcp_vpn_gateway.self_link

  router      = google_compute_router.gcp_cloud_router.self_link
  ike_version = "1"

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}


*/
resource "google_compute_firewall" "gcp_firewall" {
  name    = "gcp-firewall"
  network = google_compute_network.g_vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["10.1.1.0/24"]
}







resource "google_compute_instance" "gcp_compute" {
  name         = "test"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }

  }
  // Local SSD disk
  #scratch_disk {
  #  interface = "SCSI"
  #}

  network_interface {
    subnetwork = google_compute_subnetwork.g_subnetwork.name

    access_config {
      // Ephemeral IP
    }
  }


  metadata_startup_script = <<EOF
#!/bin/bash
curl https://cloudtechsavvy.com
EOF

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

