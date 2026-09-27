package main

deny contains msg if {
  ingress_rule := input.resource_changes[_].change.after.ingress[_]
  ingress_rule.from_port == 22
  ingress_rule.cidr_blocks[_] == "0.0.0.0/0"
  msg := "SSH (port 22) must not be open to 0.0.0.0/0"
}

deny contains msg if {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  not startswith(rc.change.after.instance_type, "t2.micro")
  not startswith(rc.change.after.instance_type, "t3.micro")
  msg := "Instance type must stay within free-tier (t2.micro or t3.micro)"
}
