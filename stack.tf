variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "master_instance_ip" {
    default = "10.0.0.11"
}
variable "worker_instance_ips" {
    default = {
      "0" = "10.0.0.12"
      "1" = "10.0.0.13"
      "2" = "10.0.0.14"
    }
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_ami" "sparkery-common-ami" {
  owners = ["self"]
  filter {
    name = "name"
    values = ["sparkery-packer-common"]
  }
}

resource "aws_vpc" "sparkery-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags {
        Name = "sparkery-vpc"
        Environment = "sparkery"
    }
}

resource "aws_subnet" "sparkery-vpc-subnet-a" {
    vpc_id = "${aws_vpc.sparkery-vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "${var.region}a"

    tags {
        Name = "sparkery-vpc-subnet-a"
        Environment = "sparkery"
    }
}

resource "aws_subnet" "sparkery-vpc-subnet-b" {
    vpc_id = "${aws_vpc.sparkery-vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.region}b"

    tags {
        Name = "sparkery-vpc-subnet-b"
        Environment = "sparkery"
    }
}

resource "aws_internet_gateway" "sparkery-vpc-gw" {
    vpc_id = "${aws_vpc.sparkery-vpc.id}"

    tags {
        Name = "sparkery-vpc-gw"
        Environment = "sparkery"
    }
}

resource "aws_route_table" "sparkery-vpc-route-table" {
    vpc_id = "${aws_vpc.sparkery-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.sparkery-vpc-gw.id}"
    }

    tags {
        Name = "sparkery-vpc-route-table"
        Environment = "sparkery"
    }
}

resource "aws_route_table_association" "sparkery-vpc-route-table-assoc-a" {
    subnet_id = "${aws_subnet.sparkery-vpc-subnet-a.id}"
    route_table_id = "${aws_route_table.sparkery-vpc-route-table.id}"
}

resource "aws_route_table_association" "sparkery-vpc-route-table-assoc-b" {
    subnet_id = "${aws_subnet.sparkery-vpc-subnet-b.id}"
    route_table_id = "${aws_route_table.sparkery-vpc-route-table.id}"
}

resource "aws_security_group" "sparkery-security-group-common" {
    name = "sparkery-common"
    description = "Allow incoming SSH connections, outbound internet access and ICMP"
    vpc_id = "${aws_vpc.sparkery-vpc.id}"

    tags {
        Name = "sparkery-security-group-common"
        Environment = "sparkery"
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "sparkery-security-group-inside" {
    name = "sparkery-inside"
    description = "Allow all incoming connection inside vpc"
    vpc_id = "${aws_vpc.sparkery-vpc.id}"


    tags {
        Name = "sparkery-security-group-inside"
        Environment = "sparkery"
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = ["${aws_security_group.sparkery-security-group-common.id}"]
    }
}

resource "aws_security_group" "sparkery-security-group-web" {
    name = "sparkery-web"
    description = "Allow incoming HTTP(S)/Spark UI/Hadoop UI connections"
    vpc_id = "${aws_vpc.sparkery-vpc.id}"

    tags {
        Name = "sparkery-security-group-web"
        Environment = "sparkery"
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "sparkery-aws-instance-master" {
    key_name = "sparkery"
    instance_type = "m4.large"
    tags {
       Environment = "sparkery"
       Name = "sparkery-master"
    }
    ami = "${data.aws_ami.sparkery-common-ami.id}"
    vpc_security_group_ids = [
      "${aws_security_group.sparkery-security-group-common.id}",
      "${aws_security_group.sparkery-security-group-inside.id}",
      "${aws_security_group.sparkery-security-group-web.id}"
    ]
    subnet_id = "${aws_subnet.sparkery-vpc-subnet-a.id}"
    associate_public_ip_address = true
    availability_zone = "${var.region}a"
    private_ip = "${var.master_instance_ip}"

    // root_block_device {
    //   volume_type = "standard"
    //   volume_size = 200
    // }
}

resource "aws_instance" "sparkery-aws-instance-worker" {
    key_name = "sparkery"
    count = "3"
    instance_type = "m4.large"
    tags {
       Environment = "sparkery"
       Name = "sparkery-worker"
    }
    ami = "${data.aws_ami.sparkery-common-ami.id}"
    vpc_security_group_ids = [
      "${aws_security_group.sparkery-security-group-common.id}",
      "${aws_security_group.sparkery-security-group-inside.id}",
      "${aws_security_group.sparkery-security-group-web.id}"
    ]
    subnet_id = "${aws_subnet.sparkery-vpc-subnet-a.id}"
    associate_public_ip_address = true
    availability_zone = "${var.region}a"
    private_ip = "${lookup(var.worker_instance_ips, count.index)}"

    // root_block_device {
    //   volume_type = "standard"
    //   volume_size = 200
    // }
}
