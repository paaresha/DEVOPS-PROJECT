resource "aws_security_group" "vprofile-bean-elb-sg" {
  name        = "vprofile-bean-elb-sg"                                   # Load balancer security group name
  description = "Security group for bean-elb"                           # ALB/ELB security group description
  vpc_id      = module.vpc.vpc_id                                        # Attach to custom VPC
  tags = {
    Name      = "vprofile-bean-elb"                                      # Resource identification tag
    ManagedBy = "Terraform"                                              # Infrastructure management tracking
    Project   = "Vprofile"                                               # Project grouping tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_forELB" {
  security_group_id = aws_security_group.vprofile-bean-elb-sg.id        # Target security group for rule
  cidr_ipv4         = "0.0.0.0/0"                                       # Allow HTTP from anywhere on internet
  ip_protocol       = "tcp"                                             # TCP protocol for HTTP traffic
  from_port         = 80                                                # HTTP port (start range)
  to_port           = 80                                                # HTTP port (end range)
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv4forELB" {
  security_group_id = aws_security_group.vprofile-bean-elb-sg.id        # Target security group for outbound rule
  cidr_ipv4         = "0.0.0.0/0"                                       # Allow outbound to any IPv4 address
  ip_protocol       = "-1"                                              # All protocols and ports allowed
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv6forELB" {
  security_group_id = aws_security_group.vprofile-bean-elb-sg.id        # Target security group for IPv6 outbound
  cidr_ipv6         = "::/0"                                            # Allow outbound to any IPv6 address
  ip_protocol       = "-1"                                              # All protocols and ports for IPv6
}







resource "aws_security_group" "vprofile-bastion-sg" {
  name        = "vprofile-bastion-sg"                                    # Bastion host security group name
  description = "Security group for bastionisioner ec2 instance"        # Jump box/bastion host description
  vpc_id      = module.vpc.vpc_id                                        # Associate with custom VPC
  tags = {
    Name      = "vprofile-bastion-sg"                                    # Resource identification
    ManagedBy = "Terraform"                                              # IaC management tracking
    Project   = "Vprofile"                                               # Project association
  }
}

resource "aws_vpc_security_group_ingress_rule" "sshfromyIPforBastion" {
  security_group_id = aws_security_group.vprofile-bastion-sg.id         # Target bastion security group
  cidr_ipv4         = "0.0.0.0/0"                                       # SSH from anywhere (should be restricted to admin IP)
  from_port         = 22                                                # SSH port (start)
  ip_protocol       = "tcp"                                             # TCP protocol for SSH
  to_port           = 22                                                # SSH port (end)
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv4forBastion" {
  security_group_id = aws_security_group.vprofile-bastion-sg.id         # Bastion outbound IPv4 rule
  cidr_ipv4         = "0.0.0.0/0"                                       # Allow outbound to any IPv4
  ip_protocol       = "-1"                                              # All protocols for bastion outbound
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv6forBastion" {
  security_group_id = aws_security_group.vprofile-bastion-sg.id         # Bastion outbound IPv6 rule
  cidr_ipv6         = "::/0"                                            # Allow outbound to any IPv6
  ip_protocol       = "-1"                                              # All protocols for IPv6 outbound
}






resource "aws_security_group" "vprofile-prodbean-sg" {
  name        = "vprofile-prodbean-sg"                                   # Beanstalk instances security group
  description = "Security group for beanstalk instances"                # Application layer security group
  vpc_id      = module.vpc.vpc_id                                        # Attach to custom VPC
  tags = {
    Name      = "vprofile-prodbean-sg"                                   # Resource identification
    ManagedBy = "Terraform"                                              # Infrastructure tracking
    Project   = "Vprofile"                                               # Project grouping
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_fromELB" {
  security_group_id            = aws_security_group.vprofile-bean-elb-sg.id     # WRONG: Should target prodbean-sg
  referenced_security_group_id = aws_security_group.vprofile-bean-elb-sg.id     # Allow HTTP from load balancer SG
  from_port                    = 80                                             # HTTP port (start)
  ip_protocol                  = "tcp"                                          # TCP protocol
  to_port                      = 80                                             # HTTP port (end)
}

resource "aws_vpc_security_group_ingress_rule" "sshfromAnywhere" {
  security_group_id = aws_security_group.vprofile-prodbean-sg.id        # Target beanstalk instances
  cidr_ipv4         = "0.0.0.0/0"                                       # SSH from anywhere (security risk)
  from_port         = 22                                                # SSH port (start)
  ip_protocol       = "tcp"                                             # TCP protocol for SSH
  to_port           = 22                                                # SSH port (end)
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv4forBeanInst" {
  security_group_id = aws_security_group.vprofile-prodbean-sg.id        # Beanstalk outbound IPv4 rule
  cidr_ipv4         = "0.0.0.0/0"                                       # Allow outbound to any IPv4
  ip_protocol       = "-1"                                              # All protocols for application outbound
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv6forBeanInst" {
  security_group_id = aws_security_group.vprofile-prodbean-sg.id        # Beanstalk outbound IPv6 rule
  cidr_ipv6         = "::/0"                                            # Allow outbound to any IPv6
  ip_protocol       = "-1"                                              # All protocols for IPv6
}







resource "aws_security_group" "vprofile-backend-sg" {
  name        = "vprofile-backend-sg"                                    # Backend services security group
  description = "Security group for RDS, active mq, elastic cache"      # Database and messaging layer
  vpc_id      = module.vpc.vpc_id                                        # Associate with custom VPC
  tags = {
    Name      = "vprofile-backend-sg"                                    # Resource identification
    ManagedBy = "Terraform"                                              # IaC management
    Project   = "Vprofile"                                               # Project association
  }
}

resource "aws_vpc_security_group_ingress_rule" "AllowAllFromBeanInstance" {
  security_group_id            = aws_security_group.vprofile-backend-sg.id      # Target backend services
  referenced_security_group_id = aws_security_group.vprofile-prodbean-sg.id     # Allow from Beanstalk instances
  from_port                    = 0                                              # All ports (start range)
  to_port                      = 65535                                          # All ports (end range)
  ip_protocol                  = "tcp"                                          # TCP protocol only
}

resource "aws_vpc_security_group_ingress_rule" "Allow3306FromBastionInstance" {
  security_group_id            = aws_security_group.vprofile-backend-sg.id      # Target backend for MySQL access
  referenced_security_group_id = aws_security_group.vprofile-bastion-sg.id      # Allow from bastion host
  from_port                    = 3306                                           # MySQL/MariaDB port (start)
  ip_protocol                  = "tcp"                                          # TCP protocol for database
  to_port                      = 3306                                           # MySQL/MariaDB port (end)
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv4forbackend" {
  security_group_id = aws_security_group.vprofile-backend-sg.id         # Backend outbound IPv4 rule
  cidr_ipv4         = "0.0.0.0/0"                                       # Allow outbound to any IPv4
  ip_protocol       = "-1"                                              # All protocols for backend outbound
}

resource "aws_vpc_security_group_egress_rule" "allowAllOutbound_ipv6forBeanBackend" {
  security_group_id = aws_security_group.vprofile-backend-sg.id         # Backend outbound IPv6 rule
  cidr_ipv6         = "::/0"                                            # Allow outbound to any IPv6
  ip_protocol       = "-1"                                              # All protocols for IPv6 outbound
}

resource "aws_vpc_security_group_ingress_rule" "Backendsec_group_allow_itself" {
  security_group_id            = aws_security_group.vprofile-backend-sg.id      # Self-referencing rule
  referenced_security_group_id = aws_security_group.vprofile-backend-sg.id      # Allow communication within backend SG
  from_port                    = 0                                              # All ports for internal communication
  ip_protocol                  = "tcp"                                          # TCP protocol for internal traffic
  to_port                      = 65535                                          # All ports (end range)
}
