package main

deny[msg] {
  input.resource_changes[_].change.after.ingress[_].cidr_blocks[_] == "0.0.0.0/0"
  input.resource_changes[_].change.after.ingress[_].from_port == 22
  msg = "SSH (port 22) must not be open to 0.0.0.0/0"
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_instance"
  not startswith(rc.change.after.instance_type, "t2.micro")
  not startswith(rc.change.after.instance_type, "t3.micro")
  msg = "Instance type must stay within free-tier (t2.micro or t3.micro)"
}
