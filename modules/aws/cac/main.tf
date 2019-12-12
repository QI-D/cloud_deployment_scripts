/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  prefix         = var.prefix != "" ? "${var.prefix}-" : ""
  startup_script = "cac-startup.sh"
}

data "template_file" "startup-script" {
  template = file("${path.module}/${local.startup_script}.tmpl")

  vars = {
    cam_url                  = var.cam_url,
    cac_installer_url        = var.cac_installer_url,
    cac_token                = var.cac_token,
    pcoip_registration_code  = var.pcoip_registration_code,

    domain_controller_ip     = var.domain_controller_ip,
    domain_name              = var.domain_name,
    domain_group             = var.domain_group,
    service_account_username = var.service_account_username,
    service_account_password = var.service_account_password,
  }
}

# Need to do this to look up AMI ID, which is different for each region
data "aws_ami" "ami" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

resource "aws_instance" "cac" {
  count = var.instance_count

  ami           = data.aws_ami.ami.id
  instance_type = var.instance_type

  root_block_device {
    volume_type = "gp2"
    volume_size = var.disk_size_gb
  }

  subnet_id                   = var.subnet
  associate_public_ip_address = true

  vpc_security_group_ids = var.security_group_ids

  key_name = var.admin_ssh_key_name

  user_data = data.template_file.startup-script.rendered

  tags = {
    Name = "${local.prefix}${var.host_name}-${count.index}"
  }
}
