resource "aws_elastic_beanstalk_environment" "vprofile-bean-prod" {
  name                = "vprofile-bean-prod"                            # Unique environment name for production
  application         = aws_elastic_beanstalk_application.vprofile-prod.name  # Links to Beanstalk application resource
  solution_stack_name = "64bit Amazon Linux 2023 v5.4.1 running Tomcat 10 Corretto 21"  # Java runtime platform version
  cname_prefix        = "vprofile-bean-prod-pulsar"                     # Custom URL prefix for the environment

  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # EC2 instance configuration namespace
    name      = "IamInstanceProfile"                                     # IAM role for EC2 instances
    value     = "aws-elasticbeanstalk-ec2-role"                          # Default Beanstalk service role
  }
  
  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # Storage configuration
    name      = "RootVolumeType"                                         # Root volume storage type
    value     = "gp3"                                                    # General Purpose SSD v3 (cost-effective)
  }
  
  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # Security configuration
    name      = "DisableIMDSv1"                                          # Instance Metadata Service version control
    value     = true                                                     # Force IMDSv2 for enhanced security
  }
  
  setting {
    namespace = "aws:ec2:vpc"                                            # VPC networking configuration
    name      = "AssociatePublicIpAddress"                               # Public IP assignment for instances
    value     = true                                                     # Enable public IPs (needed for internet access)
  }

  setting {
    namespace = "aws:ec2:vpc"                                            # Instance subnet placement
    name      = "Subnets"                                                # EC2 instances deployment subnets
    value     = join(",", [module.vpc.private_subnets[0],               # All three private subnets for multi-AZ
                          module.vpc.private_subnets[1], 
                          module.vpc.private_subnets[2]])
  }
  
  setting {
    namespace = "aws:ec2:vpc"                                            # Load balancer subnet placement
    name      = "ELBSubnets"                                             # Application Load Balancer subnets
    value     = join(",", [module.vpc.public_subnets[0],                # All three public subnets for internet-facing LB
                          module.vpc.public_subnets[1], 
                          module.vpc.public_subnets[2]])
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # Instance type configuration
    name      = "InstanceType"                                           # EC2 instance size
    value     = "t3.micro"                                               # Burstable performance (free tier eligible)
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # SSH access configuration
    name      = "EC2KeyName"                                             # Key pair for SSH access
    value     = aws_key_pair.vprofilekey.key_name                       # Reference to created key pair resource
  }

  setting {
    namespace = "aws:autoscaling:asg"                                    # Auto Scaling Group configuration
    name      = "Availability Zones"                                     # AZ distribution strategy
    value     = "Any 3"                                                  # Use any 3 available zones for high availability
  }
  
  setting {
    namespace = "aws:autoscaling:asg"                                    # Minimum capacity setting
    name      = "MinSize"                                                # Minimum number of instances
    value     = "1"                                                      # Always maintain at least 1 instance
  }
  
  setting {
    namespace = "aws:autoscaling:asg"                                    # Maximum capacity setting
    name      = "MaxSize"                                                # Maximum number of instances
    value     = "8"                                                      # Scale up to 8 instances under load
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"           # Application environment variables
    name      = "environment"                                            # Environment type identifier
    value     = "prod"                                                   # Production environment designation
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"           # Logging configuration
    name      = "LOGGING_APPENDER"                                       # Log destination configuration
    value     = "GRAYLOG"                                                # Use Graylog for centralized logging
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"            # Health monitoring configuration
    name      = "SystemType"                                             # Health reporting system type
    value     = "enhanced"                                               # Enhanced health reporting for detailed metrics
  }
  
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"             # Deployment strategy configuration
    name      = "RollingUpdateEnabled"                                   # Enable rolling updates
    value     = "true"                                                   # Allow zero-downtime deployments
  }
  
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"             # Rolling update method
    name      = "RollingUpdateType"                                      # Update strategy type
    value     = "Health"                                                 # Health-based rolling updates
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"             # Batch update size
    name      = "MaxBatchSize"                                           # Maximum instances updated simultaneously
    value     = "1"                                                      # Update one instance at a time (safest)
  }
  
  setting {
    namespace = "aws:elb:loadbalancer"                                   # Load balancer configuration
    name      = "CrossZone"                                              # Cross-zone load balancing
    value     = "true"                                                   # Enable traffic distribution across AZs
  }

  setting {
    name      = "StickinessEnabled"                                      # Session persistence configuration
    namespace = "aws:elasticbeanstalk:environment:process:default"       # Target group settings
    value     = "true"                                                   # Enable sticky sessions for stateful apps
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"                           # Deployment command configuration
    name      = "BatchSizeType"                                          # Batch size calculation method
    value     = "Fixed"                                                  # Use fixed number instead of percentage
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"                           # Deployment batch size
    name      = "BatchSize"                                              # Number of instances in deployment batch
    value     = "1"                                                      # Deploy to one instance at a time
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:command"                           # Deployment strategy
    name      = "DeploymentPolicy"                                       # How deployments are executed
    value     = "Rolling"                                                # Rolling deployment for zero downtime
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"                    # Instance security group
    name      = "SecurityGroups"                                         # Security groups for EC2 instances
    value     = aws_security_group.vprofile-prodbean-sg.id              # Application layer security group
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"                                 # Load balancer security group
    name      = "SecurityGroups"                                         # Security groups for Application Load Balancer
    value     = aws_security_group.vprofile-bean-elb-sg.id              # Load balancer security group
  }

  depends_on = [aws_security_group.vprofile-bean-elb-sg,                 # Explicit dependency on security groups
               aws_security_group.vprofile-prodbean-sg]                  # Ensures SGs are created before environment
}
