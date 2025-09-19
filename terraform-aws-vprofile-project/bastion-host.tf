# Data source to fetch the latest Ubuntu 22.04 LTS AMI
# This ensures we always use the most recent patched version
data "aws_ami" "Ubuntu22ami" {
  most_recent = true                    # Get the latest available AMI

  # Filter for Ubuntu 22.04 Jammy server images
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Ensure we get HVM virtualization type (required for most instance types)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]             # Canonical's official AWS account ID
}


# Bastion host EC2 instance for secure access to private resources
# Acts as a jump server to access RDS and other private subnet resources
resource "aws_instance" "vprofile-bastion" {
  ami                    = data.aws_ami.Ubuntu22ami.id              # Use dynamically fetched Ubuntu AMI
  instance_type          = "t3.micro"                               # Smallest burstable instance (free tier eligible)
  key_name               = aws_key_pair.vprofilekey.key_name        # SSH key pair for secure access
  subnet_id              = module.vpc.public_subnets[0]             # Deploy in first public subnet for internet access
  count                  = var.instance_count                      # Variable-controlled instance count
  vpc_security_group_ids = [aws_security_group.vprofile-bastion-sg.id] # Bastion-specific security group

  # Resource tagging for organization and cost tracking
  tags = {
    Name    = "vprofile-bastion"        # Instance identifier in AWS console
    PROJECT = "vprofile"                # Project grouping for billing/management
  }

  # File provisioner: Upload database deployment script to bastion
  # Template file allows dynamic RDS endpoint injection
  provisioner "file" {
    content = templatefile("templates/db-deploy.tmpl", { 
      rds-endpoint = aws_db_instance.vprofile-rds.address,  # RDS instance endpoint
      dbuser       = var.dbuser,                            # Database username from variables
      dbpass       = var.dbpass                             # Database password from variables
    })
    destination = "/tmp/vprofile-dbdeploy.sh"              # Remote file location on bastion
  }

  # SSH connection configuration for provisioners
  # Establishes secure connection to newly created instance
  connection {
    type        = "ssh"                                     # Connection protocol
    user        = var.USERNAME                              # SSH username (typically 'ubuntu' for Ubuntu AMI)
    private_key = file(var.PRIV_KEY_PATH)                   # Private key file path for authentication
    host        = self.public_ip                            # Connect to instance's public IP
  }

  # Remote execution provisioner: Run database setup script
  # Executes after file upload completes successfully
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/vprofile-dbdeploy.sh",                 # Make script executable
      "sudo /tmp/vprofile-dbdeploy.sh"                      # Execute database deployment with sudo privileges
    ]
  }
}
