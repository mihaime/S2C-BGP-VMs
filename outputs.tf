output "spoke3_s2c_local_vm1" {
  value = {
    "public_IP" = module.vm-1-spoke-3.public_ip.ip_address,
    "private_IP" = module.vm-1-spoke-3.nic.private_ip_address
  }
}

output "gw1_s2c_pol_remote" {
  value = {
    "public_IP" = module.vm-1-gw-1.public_ip.ip_address,
    "private_IP" = module.vm-1-gw-1.nic.private_ip_address
  }
}

output "gw2_s2c_routed_remote" {
  value = {
    "public_IP" = module.vm-1-gw-2.public_ip.ip_address,
    "private_IP" = module.vm-1-gw-2.nic.private_ip_address
  }
}

output "spoke1_s2c_local_vm1" {
  value = {
    "public_IP" = module.vm-1-spoke-1.public_ip.ip_address,
    "private_IP" = module.vm-1-spoke-1.nic.private_ip_address
  }
}

output "spoke2_s2c_bgp_remote" {
  value = {
    "public_IP" = module.vm-1-spoke-2.public_ip.ip_address,
    "private_IP" = module.vm-1-spoke-2.nic.private_ip_address
  }
}

output "DNS_spoke3_s2c_local_vm1" {
  value = {
    "DNS_Spoke3_LOCAL_POLROUTED_VM"  = aws_route53_record.vm-1-spoke-3.fqdn
  }
}

output "DNS_gw1_s2c_pol_remote" {
  value = {
    "DNS_GW1_POLICY_REMOTE_VM"  = aws_route53_record.vm-1-gw-1.fqdn
  }
}

output "DNS_gw2_s2c_routed_remote" {
  value = {
    "DNS_GW2_ROUTED_REMOTE_VM"  = aws_route53_record.vm-1-gw-2.fqdn
  }
}

output "DNS_spoke1_s2c_local_vm1" {
  value = {
    "DNS_Spoke1_BGP_Local_VM"  = aws_route53_record.vm-1-spoke-1.fqdn
  }
}

output "DNS_spoke2_s2c_bgp_remote" {
  value = {
    "DNS_Spoke2_BGP_Remote_VM"  = aws_route53_record.vm-1-spoke-2.fqdn
  }
}



