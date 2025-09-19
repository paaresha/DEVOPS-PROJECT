resource "aws_db_subnet_group" "vprofile-rds-subgrp" {
  name       = "vprofile-rds-subgrp"                                     # Unique name for RDS subnet group
  subnet_ids = [module.vpc.private_subnets[0],                          # First private subnet for multi-AZ deployment
               module.vpc.private_subnets[1],                           # Second private subnet for high availability
               module.vpc.private_subnets[2]]                          # Third private subnet for disaster recovery

  tags = {
    Name = "Subnet group for RDS"                                       # Resource identification tag
  }
}

resource "aws_elasticache_subnet_group" "vprofile-ecache-subgrp" {
  name       = "vprofile-ecache-subgrp"                                  # Unique name for ElastiCache subnet group
  subnet_ids = [module.vpc.private_subnets[0],                          # First private subnet for cache deployment
               module.vpc.private_subnets[1],                           # Second private subnet for cache redundancy
               module.vpc.private_subnets[2]]                          # Third private subnet for cache availability

  tags = {
    Name = "Subnet group for Elasticache"                               # Resource identification tag
  }
}

resource "aws_db_instance" "vprofile-rds" {
  allocated_storage      = 20                                           # Initial storage size in GB (gp3 type)
  storage_type           = "gp3"                                        # General Purpose SSD storage type
  engine                 = "mysql"                                      # MySQL database engine
  engine_version         = "8.0.39"                                     # Specific MySQL version (latest patch)
  instance_class         = "db.t4g.micro"                               # Burstable performance instance (free tier eligible)
  db_name                = var.dbname                                   # Database name from variables
  username               = var.dbuser                                   # Master username from variables
  password               = var.dbpass                                   # Master password from variables (should use secrets)
  parameter_group_name   = "default.mysql8.0"                          # Default parameter group for MySQL 8.0
  multi_az               = "false"                                      # Single AZ deployment (cost optimization)
  publicly_accessible    = "false"                                     # Private database (security best practice)
  skip_final_snapshot    = true                                        # Skip snapshot on deletion (dev environment)
  db_subnet_group_name   = aws_db_subnet_group.vprofile-rds-subgrp.name  # Link to subnet group for VPC deployment
  vpc_security_group_ids = [aws_security_group.vprofile-backend-sg.id]   # Attach backend security group for network access
}

resource "aws_elasticache_cluster" "vprofile-cache" {
  cluster_id           = "vprofile-cache"                               # Unique cluster identifier
  engine               = "memcached"                                    # Memcached engine for session storage
  node_type            = "cache.t3.micro"                               # Burstable performance cache node (free tier)
  engine_version       = "1.6.22"                                      # Memcached engine version
  num_cache_nodes      = 1                                             # Single node deployment (cost optimization)
  parameter_group_name = "default.memcached1.6"                        # Default parameter group for Memcached 1.6
  port                 = 11211                                         # Standard Memcached port
  security_group_ids   = [aws_security_group.vprofile-backend-sg.id]    # Backend security group for network access
  subnet_group_name    = aws_elasticache_subnet_group.vprofile-ecache-subgrp.name  # Link to ElastiCache subnet group
}

resource "aws_mq_broker" "vprofile-rmq" {
  broker_name                = "vprofile-rmq"                           # Unique broker name identifier
  engine_type                = "RabbitMQ"                               # RabbitMQ message broker engine
  engine_version             = "3.13"                                   # RabbitMQ version (latest stable)
  host_instance_type         = "mq.t3.micro"                           # Burstable performance instance for broker
  auto_minor_version_upgrade = true                                     # Enable automatic minor version updates
  security_groups            = [aws_security_group.vprofile-backend-sg.id]  # Backend security group for network access
  subnet_ids                 = [module.vpc.private_subnets[0]]          # Single private subnet deployment (single-instance)

  user {
    username = var.rmquser                                             # RabbitMQ admin username from variables
    password = var.rmqpass                                             # RabbitMQ admin password from variables
  }
}
