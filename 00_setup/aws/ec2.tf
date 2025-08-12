module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0.2"

  for_each = var.instances

  name = "${var.instance_name}-${var.env}-${each.key}"
  ami  = var.ami

  instance_type          = each.value.instance_type
  availability_zone      = element(module.vpc.azs, 0)
  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [module.security_group.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_role.name
  user_data              = var.user_data
  enable_volume_tags     = false

  metadata_options = {
    http_tokens = "required"
  }

  root_block_device = {
      encrypted   = true
      type = "gp3"
      # throughput  = 100
      size = each.value.volume_size
      tags        = local.tags
    }

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "seccamp-${var.env}"
  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]

  tags = local.tags
}
