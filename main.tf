# variables

variable "my-access-key"{
          type = "string"
}
variable "my-secret-key"{
          type = "string"
}
variable "my_login" {}
variable "gcp_zone" {}
variable "gcp_region" {}
variable "lb_inst_image" {}
variable "web_inst_image" {}
variable "gcp_project" {}
variable "key_file" {}
variable "ssh_pub_key_filepath" {
          type = "string"
}

variable "lb_host_user" {}
variable "web_host_user" {}

variable "ssh_pr_key_filepath" {
          type = "string"
}

variable "web_domains"{
         type = "list"
         default = ["dimank"]#, "dimankv"]
}


variable "lb_domains"{
         type = "list"
         default = ["loadbvsite"]#,"lbstack"]
}



# Configure the AWS  Provider
 provider "aws" {
  region     = "us-west-2"
  access_key = "${var.my-access-key}"
  secret_key = "${var.my-secret-key}"
 }

# Configure the GCP  Provider

 provider "google" {
  credentials = "${file(var.key_file)}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
  zone        = "${var.gcp_zone}"
 }



# Configure AWS zone
 data "aws_route53_zone" "rebrain" {
   name = "devops.rebrain.srwx.net."
   private_zone = false
  }





# Create DNS records for LB

 resource "aws_route53_record" "www" {

  count   = "${length(var.lb_domains)}"
  zone_id =  data.aws_route53_zone.rebrain.id #"${var.aws_zoneid}"
  name    =  "${element(var.lb_domains, count.index)}.devops.rebrain.srwx.net"
  type    = "A"
  ttl     = "300"
  records = ["${google_compute_instance.lb_instance[count.index].network_interface[count.index].access_config[count.index].nat_ip}" ,]
 }



# Create a new Load Balancer Instance 
 resource "google_compute_instance" "lb_instance" {
  count        = "${length(var.lb_domains)}"
  hostname     = "${element(var.lb_domains, count.index)}.devops.rebrain.srwx.net"
  name         = "lb-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "${var.lb_inst_image}"
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
      user = "${var.lb_host_user}"
      host = "${google_compute_instance.lb_instance[count.index].network_interface[count.index].access_config[count.index].nat_ip}" 
      private_key = "${file(var.ssh_pr_key_filepath)}"
    }
 }
}

# Write credentials to file and run ansible
resource "null_resource" "devstxt" {
  count = "${length(var.lb_domains)}"
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.lb_instance[count.index].network_interface[count.index].access_config[count.index].nat_ip} ansible_user=${var.lb_host_user} ansible_ssh_private_key_file=${var.ssh_pr_key_filepath} >> nginx/inventory/lb_prod"
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/lb_prod  python/main.yml" 
}
  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/lb_prod  nginx/lb.yml  --extra-vars 'nginx_site_name=${var.lb_domains[count.index]} , backend=${google_compute_instance.web_instance[count.index].network_interface[count.index].network_ip}' --vault-password-file ~/.ansible_pass.txt" 
  }
}

 resource "google_compute_network" "vpc_network" {
   name                    = "ops-ans-13"
   auto_create_subnetworks = "true"
 } 
#----------------------------------------------------------

# Create a new Load Web Instance 
 resource "google_compute_instance" "web_instance" {
  count        = "${length(var.lb_domains)}"
  hostname     = "${element(var.web_domains, count.index)}.devops.rebrain.srwx.net"
  name         = "web-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "${var.web_inst_image}"
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
      user = "${var.web_host_user}"
      host = "${google_compute_instance.web_instance[count.index].network_interface[count.index].access_config[count.index].nat_ip}" 
      private_key = "${file(var.ssh_pr_key_filepath)}"
    }
 }
}

# Write credentials to file and run ansible
resource "null_resource" "a" {
  count = "${length(var.web_domains)}"
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.web_instance[count.index].network_interface[count.index].access_config[count.index].nat_ip} ansible_user=${var.web_host_user} ansible_ssh_private_key_file=${var.ssh_pr_key_filepath} >> nginx/inventory/web_prod"
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/web_prod  python/main.yml" 
}
  provisioner "local-exec" {
    command = "ansible-playbook  -i nginx/inventory/web_prod  nginx/web.yml  --extra-vars 'nginx_site_name=${var.web_domains[count.index]}' --vault-password-file ~/.ansible_pass.txt" 
  }
}
