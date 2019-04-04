resource "aws_kms_key" "examplekms" {
  description             = "KMS key 1"
  deletion_window_in_days = 7
}                                                                                                                                                                                                       
 
resource "aws_s3_bucket" "examplebucket" {
  bucket = "indexbuckethtml"
  acl    = "private"
  region = "${var.aws_region}"
}
  
resource "aws_s3_bucket_object" "examplebucket_object" {
  key        = "index.html"
  bucket     = "${aws_s3_bucket.examplebucket.id}"
  source     = "/home/tantalum/aws/files/index.hmtl"
  kms_key_id = "${aws_kms_key.examplekms.arn}"
}

resource "aws_vpc" "vpcts" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "test-vpc"
  }
}
resource "aws_subnet" "public-subnet1" {
  vpc_id = "${aws_vpc.vpcts.id}"
  cidr_block = "${var.public_subnet1}"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

}
resource "aws_subnet" "public-subnet2" {
  vpc_id = "${aws_vpc.vpcts.id}"
  cidr_block = "${var.public_subnet2}"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpcts.id}"
}
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpcts.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.vpcts.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}
resource "aws_route_table_association" "web-public-rt1" {
  subnet_id = "${aws_subnet.public-subnet1.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}
resource "aws_route_table_association" "web-public-rt2" {
  subnet_id = "${aws_subnet.public-subnet2.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}
resource "aws_security_group" "sgweb" {
  name = "vpc_test_web"


  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
   ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress{
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

  vpc_id="${aws_vpc.vpcts.id}"
}
resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "s3-role"
  assume_role_policy = "${file("/home/tantalum/aws/policy/rolepolicy.json")}"
}

resource "aws_iam_instance_profile" "test_profile" {                            
  name  = "test_profile"                         
  roles = ["${aws_iam_role.ec2_s3_access_role.name}"]
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = "${file("policy/s3.json")}"
}
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.ec2_s3_access_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}



resource "aws_instance" "testInstance1" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  subnet_id = "${aws_subnet.public-subnet1.id}"
  vpc_security_group_ids = ["${aws_security_group.sgweb.id}"]
  key_name = "amazon"
  user_data = "${file("/home/tantalum/aws/files/user-data.txt")}"



}
resource "aws_instance" "testInstance2" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  subnet_id = "${aws_subnet.public-subnet2.id}"
  vpc_security_group_ids = ["${aws_security_group.sgweb.id}"]
  key_name = "amazon"
  user_data = "${file("/home/tantalum/aws/files/user-data.txt")}"

}
resource "aws_eip" "ip-test-env1" {
  instance = "${aws_instance.testInstance1.id}"
  vpc      = true
}
resource "aws_eip" "ip-test-env2" {
  instance = "${aws_instance.testInstance2.id}"
  vpc      = true
}
resource "aws_iam_server_certificate" "for_lb" {
  name      = "url1_valouille_fr"
  certificate_body = "${file("/home/tantalum/elbssl/domain.crt")}"
  private_key      = "${file("/home/tantalum/elbssl/domain.key")}"
}
resource "aws_elb" "bar" {
   name               = "foobar-terraform-elb"
   security_groups	=	["${aws_security_group.sgweb.id}"]
   subnets		=	["${aws_subnet.public-subnet1.id}",
                     "${aws_subnet.public-subnet2.id}"]
   internal = true


   listener {
     instance_port     = 8080
     instance_protocol = "http"
     lb_port           = 80
     lb_protocol       = "http"
   }

   listener {
     instance_port      = 8080
     instance_protocol  = "http"
     lb_port            = 443
     lb_protocol        = "https"
     ssl_certificate_id = "${aws_iam_server_certificate.for_lb.arn}"
   }

   health_check {
     healthy_threshold   = 2
     unhealthy_threshold = 2
     timeout             = 3
     target              = "HTTP:8080/"
     interval            = 30
   }

   instances                   = ["${aws_instance.testInstance1.id}",
                                  "${aws_instance.testInstance2.id}"]
   cross_zone_load_balancing   = true
   idle_timeout                = 400
   connection_draining         = true
   connection_draining_timeout = 400

   tags = {
     Name = "foobar-terraform-elb"
   }
}
