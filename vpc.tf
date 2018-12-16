resource "aws_vpc" "this" {
  cidr_block = "${var.vpc_cidr_block}"

  tags {
    Name        = "${var.resource_prefix}vpc"
    Provisioner = "${var.provisioner}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name        = "${var.resource_prefix}gw"
    Provisioner = "${var.provisioner}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.this.id}"

  tags {
    Name        = "${var.resource_prefix}public-route-table"
    Provisioner = "${var.provisioner}"
  }
}

resource "aws_route" "public" {
  route_table_id = "${aws_route_table.public.id}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
}

resource "aws_subnet" "public" {
  count = "${local.az_count}"

  vpc_id     = "${aws_vpc.this.id}"
  cidr_block = "${cidrsubnet("${aws_vpc.this.cidr_block}", 8, count.index)}"

  map_public_ip_on_launch = true

  tags {
    Name        = "${var.resource_prefix}subnet-${data.aws_availability_zones.available.names[count.index]}"
    Provisioner = "${var.provisioner}"
  }
}

resource "aws_route_table_association" "public" {
  count = "${local.az_count}"

  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}
