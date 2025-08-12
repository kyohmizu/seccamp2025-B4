module "ec2" {
  source = "../../"

  instance_name = "seccamp2025-b4"
  env           = "prd"
  region        = "ap-northeast-1"
  # aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --region ap-northeast-1 --query "Parameters[0].Value"
  ami           = "ami-0c48fa60af31d0d5b"
  user_data     = file("${path.module}/userdata-slim.bash")

  instances = {
    "00" = {
      instance_type = "m5.2xlarge"
      volume_size   = 100
    }
    "01" = {
      instance_type = "m5.2xlarge"
      volume_size   = 100
    }
    # "02" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
    # "03" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
    # "04" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
    # "05" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
    # "06" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
    # "07" = {
    #   instance_type = "m5.2xlarge"
    #   volume_size   = 100
    # }
  }
}
