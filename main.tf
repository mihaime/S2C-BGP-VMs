#Aviatrix Provider
provider "aviatrix" {
  username                = "admin"
  password                = var.avx_controller_admin_password
  controller_ip           = var.controller_ip
  skip_version_validation = true
}

# in case ever needing to install stuff or pre-provision on VMs

data "template_file" "cloudconfig" {
  template = file("${path.module}/generic.tpl")
}

#Transit GW
module "mc-transit" {
  source          = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version         = "2.1.6"
  cloud           = "Azure"
  name            = "eon-transit"
  cidr            = "10.10.150.0/23"
  region          = "West Europe"
  account         = "azureaviatrix"
  local_as_number = "65501"
}
#########
#Spoke1 GW
module "mc-spoke-1" {
  source          = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version         = "1.2.4"
  cloud           = "Azure"
  name            = "eon-spoke1"
  cidr            = "10.10.160.0/23"
  region          = "West Europe"
  account         = "azureaviatrix"
  transit_gw      = module.mc-transit.transit_gateway.gw_name
  depends_on      = [module.mc-transit]
  enable_bgp      = true
  local_as_number = "65505"
}

# VM behind Spoke1
module "vm-1-spoke-1" {
  # source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  source = "./vm-azure"

  name            = "vm-1-spoke-1"
  region          = "West Europe"
  rg              = module.mc-spoke-1.vpc.resource_group
  vnet            = module.mc-spoke-1.vpc.name
  subnet          = module.mc-spoke-1.vpc.subnets[1].subnet_id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_file.cloudconfig.rendered
  public_ip       = true
  instance_size   = "Standard_D2s_v3"
  depends_on      = [module.mc-spoke-1]
}

resource "aws_route53_record" "vm-1-spoke-1" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-1.vm.name}.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-1.public_ip.ip_address]
}

resource "aws_route53_record" "vm-1-spoke-1-priv" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-1.vm.name}-priv.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-1.nic.private_ip_address]
}


#########
#Spoke3 GW
module "mc-spoke-3" {
  source     = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version    = "1.2.4"
  cloud      = "Azure"
  name       = "eon-spoke3"
  cidr       = "10.10.170.0/23"
  region     = "West Europe"
  account    = "azureaviatrix"
  transit_gw = module.mc-transit.transit_gateway.gw_name
  depends_on = [module.mc-transit]
}


# VM behind Spoke3
module "vm-1-spoke-3" {
  # source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  source = "./vm-azure"

  name            = "vm-1-spoke-3"
  region          = "West Europe"
  rg              = module.mc-spoke-3.vpc.resource_group
  vnet            = module.mc-spoke-3.vpc.name
  subnet          = module.mc-spoke-3.vpc.subnets[1].subnet_id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_file.cloudconfig.rendered
  public_ip       = true
  instance_size   = "Standard_D2s_v3"
  depends_on      = [module.mc-spoke-3]
}

resource "aws_route53_record" "vm-1-spoke-3" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-3.vm.name}.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-3.public_ip.ip_address]
}

resource "aws_route53_record" "vm-1-spoke-3-priv" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-3.vm.name}-priv.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-3.nic.private_ip_address]
}


########
#Spoke2 VPC
resource "aviatrix_vpc" "Spoke2_vpc" {
  cloud_type           = 8
  account_name         = "azureaviatrix"
  region               = "West Europe"
  name                 = "eon-spokegw2-VPC"
  cidr                 = "10.10.30.0/24"
  aviatrix_firenet_vpc = false
}

#Spoke2 GW
resource "aviatrix_spoke_gateway" "Spoke2-GW" {
  cloud_type                        = 8
  account_name                      = "azureaviatrix"
  gw_name                           = "eon-spoke2"
  vpc_id                            = aviatrix_vpc.Spoke2_vpc.vpc_id
  vpc_reg                           = "West Europe"
  gw_size                           = "Standard_B1ms"
  subnet                            = aviatrix_vpc.Spoke2_vpc.public_subnets[0].cidr
  zone                              = "az-1"
  single_ip_snat                    = false
  local_as_number                   = "65510"
  enable_bgp                        = true
  manage_transit_gateway_attachment = false
  depends_on                        = [aviatrix_vpc.Spoke2_vpc]
  ha_subnet                         = aviatrix_vpc.Spoke2_vpc.public_subnets[1].cidr
  ha_gw_size                        = "Standard_B2ms"
}

# VM behind Spoke2 GW
module "vm-1-spoke-2" {
  # source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  source = "./vm-azure"

  name            = "vm-1-spoke-2"
  region          = "West Europe"
  rg              = aviatrix_vpc.Spoke2_vpc.resource_group
  vnet            = aviatrix_vpc.Spoke2_vpc.name
  subnet          = aviatrix_vpc.Spoke2_vpc.public_subnets[1].subnet_id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_file.cloudconfig.rendered
  public_ip       = true
  instance_size   = "Standard_D2s_v3"
  depends_on      = [aviatrix_gateway.gw_2]
}

resource "aws_route53_record" "vm-1-spoke-2" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-2.vm.name}.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-2.public_ip.ip_address]
}

resource "aws_route53_record" "vm-1-spoke-2-priv" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-spoke-2.vm.name}-priv.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-spoke-2.nic.private_ip_address]
}

#######
#GW1 VPC
resource "aviatrix_vpc" "gw1_vpc" {
  cloud_type           = 8
  account_name         = "azureaviatrix"
  region               = "West Europe"
  name                 = "eon-gw1-VPC"
  cidr                 = "10.10.10.0/24"
  aviatrix_firenet_vpc = false
}
#GW1
resource "aviatrix_gateway" "gw_1" {
  cloud_type         = 8
  account_name       = "azureaviatrix"
  gw_name            = "eon-gw-1"
  vpc_id             = aviatrix_vpc.gw1_vpc.vpc_id
  vpc_reg            = "West Europe"
  gw_size            = "Standard_B2ms"
  subnet             = aviatrix_vpc.gw1_vpc.public_subnets[0].cidr
  depends_on         = [aviatrix_vpc.gw1_vpc]
  peering_ha_subnet  = aviatrix_vpc.gw1_vpc.public_subnets[1].cidr
  peering_ha_gw_size = "Standard_B2ms"
}

# VM behind GW1
module "vm-1-gw-1" {
  # source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  source = "./vm-azure"

  name            = "vm-1-gw-1"
  region          = "West Europe"
  rg              = aviatrix_vpc.gw1_vpc.resource_group
  vnet            = aviatrix_vpc.gw1_vpc.name
  subnet          = aviatrix_vpc.gw1_vpc.public_subnets[1].subnet_id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_file.cloudconfig.rendered
  public_ip       = true
  instance_size   = "Standard_D2s_v3"
  depends_on      = [aviatrix_gateway.gw_1]
}

resource "aws_route53_record" "vm-1-gw-1" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-gw-1.vm.name}.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-gw-1.public_ip.ip_address]
}

resource "aws_route53_record" "vm-1-gw1-priv" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-gw-1.vm.name}-priv.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-gw-1.nic.private_ip_address]
}

# 
#########
#GW2 VPC
resource "aviatrix_vpc" "gw2_vpc" {
  cloud_type           = 8
  account_name         = "azureaviatrix"
  region               = "West Europe"
  name                 = "eon-gw2-VPC"
  cidr                 = "10.10.20.0/24"
  aviatrix_firenet_vpc = false
}
#GW2
resource "aviatrix_gateway" "gw_2" {
  cloud_type         = 8
  account_name       = "azureaviatrix"
  gw_name            = "eon-gw-2"
  vpc_id             = aviatrix_vpc.gw2_vpc.vpc_id
  vpc_reg            = "West Europe"
  gw_size            = "Standard_B2ms"
  subnet             = aviatrix_vpc.gw2_vpc.public_subnets[0].cidr
  depends_on         = [aviatrix_vpc.gw2_vpc]
  peering_ha_subnet  = aviatrix_vpc.gw2_vpc.public_subnets[1].cidr
  peering_ha_gw_size = "Standard_B2ms"
}

# VM behind GW2
module "vm-1-gw-2" {
  # source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  source = "./vm-azure"

  name            = "vm-1-gw-2"
  region          = "West Europe"
  rg              = aviatrix_vpc.gw2_vpc.resource_group
  vnet            = aviatrix_vpc.gw2_vpc.name
  subnet          = aviatrix_vpc.gw2_vpc.public_subnets[1].subnet_id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_file.cloudconfig.rendered
  public_ip       = true
  instance_size   = "Standard_D2s_v3"
  depends_on      = [aviatrix_gateway.gw_2]
}

resource "aws_route53_record" "vm-1-gw-2" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-gw-2.vm.name}.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-gw-2.public_ip.ip_address]
}

resource "aws_route53_record" "vm-1-gw-2-priv" {
  zone_id = data.aws_route53_zone.awslinuxdns.zone_id
  name    = "${module.vm-1-gw-2.vm.name}-priv.${data.aws_route53_zone.awslinuxdns.name}"
  type    = "A"
  ttl     = "1"
  records = [module.vm-1-gw-2.nic.private_ip_address]
}

#########
#########
#########
#Policy Based VPN between Spoke3 and GW1
#Spoke3 Side
resource "aviatrix_site2cloud" "Conn1" {
  vpc_id                     = module.mc-spoke-3.vpc.vpc_id
  connection_name            = "P-Spoke3-GW1"
  connection_type            = "unmapped"
  remote_gateway_type        = "generic"
  tunnel_type                = "policy"
  primary_cloud_gateway_name = module.mc-spoke-3.spoke_gateway.gw_name
  remote_gateway_ip          = aviatrix_gateway.gw_1.eip
  remote_subnet_cidr         = "10.10.10.0/24"
  local_subnet_cidr          = "10.10.170.0/23"
  pre_shared_key             = "12345678"
  ha_enabled                 = true
  backup_gateway_name        = module.mc-spoke-3.spoke_gateway.ha_gw_name
  backup_remote_gateway_ip   = aviatrix_gateway.gw_1.peering_ha_eip
  backup_pre_shared_key      = "12345678"
}

#GW1 side
resource "aviatrix_site2cloud" "Conn2" {
  vpc_id                     = aviatrix_vpc.gw1_vpc.vpc_id
  connection_name            = "P-GW1-Spoke3"
  connection_type            = "unmapped"
  remote_gateway_type        = "generic"
  tunnel_type                = "policy"
  primary_cloud_gateway_name = aviatrix_gateway.gw_1.gw_name
  remote_gateway_ip          = module.mc-spoke-3.spoke_gateway.eip
  remote_subnet_cidr         = "10.10.170.0/23"
  local_subnet_cidr          = "10.10.10.0/24"
  pre_shared_key             = "12345678"
  ha_enabled                 = true
  backup_gateway_name        = aviatrix_gateway.gw_1.peering_ha_gw_name
  backup_remote_gateway_ip   = module.mc-spoke-3.spoke_gateway.ha_eip
  backup_pre_shared_key      = "12345678"
}

############

#Route Based VPN between Spoke3 and GW2
#Spoke3 Side
resource "aviatrix_site2cloud" "Conn3" {
  vpc_id                     = module.mc-spoke-3.vpc.vpc_id
  connection_name            = "R-Spoke3-GW2"
  connection_type            = "unmapped"
  remote_gateway_type        = "generic"
  tunnel_type                = "route"
  primary_cloud_gateway_name = module.mc-spoke-3.spoke_gateway.gw_name
  remote_gateway_ip          = aviatrix_gateway.gw_2.eip
  remote_subnet_cidr         = "10.10.20.0/24"
  pre_shared_key             = "12345678"
  ha_enabled                 = true
  backup_gateway_name        = module.mc-spoke-3.spoke_gateway.ha_gw_name
  backup_remote_gateway_ip   = aviatrix_gateway.gw_2.peering_ha_eip
  backup_pre_shared_key      = "12345678"
}

#GW2 side
resource "aviatrix_site2cloud" "Conn4" {
  vpc_id                     = aviatrix_vpc.gw2_vpc.vpc_id
  connection_name            = "R-GW2-Spoke3"
  connection_type            = "unmapped"
  remote_gateway_type        = "generic"
  tunnel_type                = "route"
  primary_cloud_gateway_name = aviatrix_gateway.gw_2.gw_name
  remote_gateway_ip          = module.mc-spoke-3.spoke_gateway.eip
  remote_subnet_cidr         = "10.10.170.0/23"
  pre_shared_key             = "12345678"
  ha_enabled                 = true
  backup_gateway_name        = aviatrix_gateway.gw_2.peering_ha_gw_name
  backup_remote_gateway_ip   = module.mc-spoke-3.spoke_gateway.ha_eip
  backup_pre_shared_key      = "12345678"
}


############

#BGPoIPSEC between Spoke1 and Spoke2
#Spoke1 Side
resource "aviatrix_spoke_external_device_conn" "Conn5" {
  vpc_id                    = module.mc-spoke-1.vpc.vpc_id
  connection_name           = "B-Spoke1-Spoke2"
  gw_name                   = module.mc-spoke-1.spoke_gateway.gw_name
  connection_type           = "bgp"
  bgp_local_as_num          = "65505"
  bgp_remote_as_num         = "65510"
  remote_gateway_ip         = aviatrix_spoke_gateway.Spoke2-GW.eip
  pre_shared_key            = "12345678"
  local_tunnel_cidr         = "169.254.1.1/30,169.254.2.1/30"
  remote_tunnel_cidr        = "169.254.1.2/30,169.254.2.2/30"
  ha_enabled                = true
  backup_remote_gateway_ip  = aviatrix_spoke_gateway.Spoke2-GW.ha_eip
  backup_pre_shared_key     = "12345678"
  backup_bgp_remote_as_num  = "65510"
  backup_local_tunnel_cidr  = "169.254.3.1/30,169.254.4.1/30"
  backup_remote_tunnel_cidr = "169.254.3.2/30,169.254.4.2/30"
}

#Spoke2 Side
resource "aviatrix_spoke_external_device_conn" "Conn6" {
  vpc_id                    = aviatrix_vpc.Spoke2_vpc.vpc_id
  connection_name           = "B-Spoke2-Spoke1"
  gw_name                   = aviatrix_spoke_gateway.Spoke2-GW.gw_name
  connection_type           = "bgp"
  bgp_local_as_num          = "65510"
  bgp_remote_as_num         = "65505"
  remote_gateway_ip         = module.mc-spoke-1.spoke_gateway.eip
  pre_shared_key            = "12345678"
  local_tunnel_cidr         = "169.254.1.2/30,169.254.3.2/30"
  remote_tunnel_cidr        = "169.254.1.1/30,169.254.3.1/30"
  ha_enabled                = true
  backup_remote_gateway_ip  = module.mc-spoke-1.spoke_gateway.ha_eip
  backup_pre_shared_key     = "12345678"
  backup_bgp_remote_as_num  = "65505"
  backup_local_tunnel_cidr  = "169.254.2.2/30,169.254.4.2/30"
  backup_remote_tunnel_cidr = "169.254.2.1/30,169.254.4.1/30"
}

### DNS

data "aws_route53_zone" "awslinuxdns" {
  name         = var.domain_name
  private_zone = false
}

### the entries are after each VM definition


