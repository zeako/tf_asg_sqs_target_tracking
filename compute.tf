data "aws_subnet_ids" "public" {
  vpc_id = "${aws_vpc.this.id}"

  depends_on = ["aws_vpc.this"]
}

data "aws_ami" "linux_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "asg" {
  key_name   = "${var.resource_prefix}asg-key"
  public_key = "${base64decode(file("${path.module}/keys/ec2_pub_key_base64"))}"
}

resource "aws_autoscaling_group" "this" {
  name_prefix = "${var.resource_prefix}asg-"

  min_size          = "${local.az_count}"
  max_size          = "${local.az_count * 6}"
  health_check_type = "EC2"

  launch_template {
    id      = "${aws_launch_template.this.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier = ["${data.aws_subnet_ids.public.ids}"]

  tags = [
    {
      key                 = "Name"
      value               = "${var.resource_prefix}asg"
      propagate_at_launch = true
    },
    {
      key                 = "Provisioner"
      value               = "${var.provisioner}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.resource_prefix}launch-template-"

  iam_instance_profile {
    arn = "${aws_iam_instance_profile.asg.arn}"
  }

  image_id      = "${data.aws_ami.linux_ami.image_id}"
  instance_type = "${var.ec2_instance_type}"

  key_name = "${aws_key_pair.asg.key_name}"

  vpc_security_group_ids = ["${aws_security_group.public.id}"]

  tags {
    Name        = "${var.resource_prefix}launch-template"
    Provisioner = "${var.provisioner}"
  }
}

resource "aws_iam_instance_profile" "asg" {
  name_prefix = "${var.resource_prefix}asg-profile-"
  role        = "${aws_iam_role.asg.name}"
}

resource "aws_iam_role" "asg" {
  name_prefix        = "${var.resource_prefix}asg-role-"
  assume_role_policy = "${data.aws_iam_policy_document.asg.json}"

  tags {
    Name        = "${var.resource_prefix}asg-role"
    Provisioner = "${var.provisioner}"
  }
}

data "aws_iam_policy_document" "asg" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "public" {
  name_prefix = "${var.resource_prefix}sg-"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name        = "${var.resource_prefix}sg"
    Provisioner = "${var.provisioner}"
  }
}
