variable "gcp_zone" {}
variable "gcp_region" {}
#variable "web_inst_image" {}
variable "gcp_project" {}
variable "instance_image" {}
variable "key_file" {}
variable "name" {}
variable "ssh_pub_key_filepath" {
          type = "string"
}
variable "ssh_pr_key_filepath" {
          type = "string"
}

variable "instance_host_user" {}

variable "my-access-key"{
          type = "string"
}
variable "my-secret-key"{
          type = "string"
}

variable "web_domains"{
         type = "string"
        default = "webserver1"
}


# Configure the AWS  Provider
 provider "aws" {
  region     = "us-west-2"
  access_key = "${var.my-access-key}"
  secret_key = "${var.my-secret-key}"
 }

# Configure AWS zone
 data "aws_route53_zone" "rebrain" {
   name = "devops.rebrain.srwx.net."
   private_zone = false
  }

# Create DNS records for LB

 resource "aws_route53_record" "www" {
  zone_id =  data.aws_route53_zone.rebrain.id #"${var.aws_zoneid}"
  name    =  "${var.name}.devops.rebrain.srwx.net"
  type    = "A"
  ttl     = "300"
  records = ["${google_compute_global_address.default.address}" ]
  depends_on = ["google_compute_global_address.default"]
 }






 provider "google" {
  credentials = "${file(var.key_file)}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
  zone        = "${var.gcp_zone}"
 }

data "google_compute_instance_group" "all" {
    name = "instance-group-name"
    zone = "${var.gcp_zone}"

depends_on = [
    google_compute_instance.web_instance,
 ]
}

resource "google_compute_instance_group" "all" {
  name        = "terraform-webservers"
  description = "Terraform test instance group"

  instances = [
    "${google_compute_instance.web_instance.self_link}",
#    "${google_compute_instance.test2.self_link}",
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "${var.gcp_zone}"
}




# Create  Web Instance 
 resource "google_compute_instance" "web_instance" {
  hostname     = "${var.web_domains}.devops.rebrain.srwx.net"
  name         = "web-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "${var.instance_image}"
    }
  }

   network_interface {
    # A default network is created for all GCP projects
    network       = "default"
    access_config {
    }
  }
 metadata = {
   sshKeys = "devopbyrebrain_gmail_com:${file(var.ssh_pub_key_filepath)}"
}

  provisioner "remote-exec" {
    inline = [
      "whoami"]

    connection {
      type = "ssh"
      user = "${var.instance_host_user}"
      host = "${google_compute_instance.web_instance.network_interface[0].access_config[0].nat_ip}" 
      private_key = "${file(var.ssh_pr_key_filepath)}"
    }
 }
}

resource "google_compute_http_health_check" "default" {
  name    = "instance-hc"
  request_path = "/"
  port               = 80
  check_interval_sec = 5
  timeout_sec        = 5
}

data "google_compute_backend_service" "baz" {
  name = "foobar"
}

resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  health_checks = ["${google_compute_http_health_check.default.self_link}"]

  backend       { group = "${google_compute_instance_group.all.self_link}"}  
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  ip_address = "${google_compute_global_address.default.address}"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "80"
  depends_on = ["google_compute_global_address.default"]
}

resource "google_compute_target_http_proxy" "default" {
  name        = "target-proxy"
  description = "a description"
  url_map     = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name            = "kolesov-url-map-target-proxy"
  description     = "a description"
  default_service = "${google_compute_backend_service.default.self_link}"

  host_rule {
    hosts        = ["${var.name}.devops.rebrain.srwx.net"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.default.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.default.self_link}"
    }
  

    path_rule {
      paths   = ["/"]
      service = "${google_compute_backend_service.default.self_link}"
    }
  }

depends_on = [
        google_compute_backend_service.default, 
       ]

}
# Write credentials to file and run ansible
resource "null_resource" "devstxt" {
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.web_instance.network_interface[0].access_config[0].nat_ip } ansible_user=${var.instance_host_user} ansible_ssh_private_key_file=${var.ssh_pr_key_filepath} >> nginx/inventory/web_prod"
  }

depends_on = [
    google_compute_instance.web_instance,
 ]
}


# Write credentials to file and run ansible
resource "null_resource" "devstxta" {

  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/web_prod  python/main.yml"
}
  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/web_prod  nginx/web.yml  --extra-vars 'nginx_site_name=sitename ,' --vault-password-file ~/.ansible_pass.txt"
  }
depends_on = [
  null_resource.devstxt ]
}

resource  "google_compute_global_address" "default" {
  project    = "${var.gcp_project}"
  name       = "${var.name}-address"
}
