variable "region" {
  default = "us-east-1"                                                 # Primary AWS region for deployment
}


variable "zone1" {
  default = "us-east-1a"                                                # Availability zone within the region
}



variable "amiID" {
  type = map(any)                                                       # Map variable to store AMI IDs by region
  default = {
    us-east-2 = "ami-036841078a4b68e14"                                 # Ohio region AMI ID
    us-east-1 = "ami-0e2c8caa4b6378d8c"                                 # N. Virginia region AMI ID
  }
}
