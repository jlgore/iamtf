terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "~> 4.0"

    }

     random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }

  }

}

variable "profile_name" {
  type = string
  default = "default"
}

variable "bucket_name" {
  type = string
  default = "mybucketname"
}


variable "pubilc_subnet_cidrs" {
  type = string
  description = "Public Subnet CIDR values"
  default = "10.0.1.0/24"
}

variable "ssh_key_pair" {
  type = string
  description = "Your ssh public key"
}


provider "random" {

}


provider "aws" {

  region = "us-east-1"
  profile = var.profile_name
}

resource "random_pet" "bucket" {
  keepers = {
    bucket_name = var.bucket_name
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-${random_pet.bucket.id}"
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key = "flag.txt"
  source = "flag.txt"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${random_pet.bucket.id}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.pubilc_subnet_cidrs
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${random_pet.bucket.id}"
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${random_pet.bucket.id}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${random_pet.bucket.id}-rt"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_iam_role" "example_role" {

  name = "examplerole"



  assume_role_policy = <<EOF

{

  "Version": "2012-10-17",

  "Statement": [

    {

      "Effect": "Allow",

      "Principal": {

        "Service": "ec2.amazonaws.com"

      },

      "Action": "sts:AssumeRole"

    }

  ]

}

EOF

}



resource "aws_iam_role_policy_attachment" "example_attachment" {

  role       = aws_iam_role.example_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

}
resource "aws_security_group" "mariadb_sg" {
  name        = "mariadb-sg"
  description = "Allow inbound traffic for MariaDB RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] 
  }

  tags = {
    Name = "mariadb-sg"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.public_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "mariadb_instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mariadb"
  engine_version         = "10.4"
  instance_class         = "db.t2.micro"
  db_name                   = "mymariadbdatabase"
  username               = "admin"
  password               = "yourpassword" # Consider AWS Secrets Manager or a Terraform variable
  parameter_group_name   = "default.mariadb10.4"
  skip_final_snapshot    = true
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.default.id
  vpc_security_group_ids = [aws_security_group.mariadb_sg.id]

  tags = {
    Name = "mariadb-instance"
  }
}

resource "aws_iam_policy" "rds_connect_policy" {
  name        = "RDSMariaDBConnect"
  description = "Allow IAM authentication to RDS MariaDB instance"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "rds-db:connect",
        Resource = "${aws_db_instance.mariadb_instance.arn}/*"
      }
    ]
  })
}

# If connecting from EC2:
resource "aws_iam_role" "ec2_rds_connect_role" {
  name = "EC2RDSConnectRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_rds_attach" {
  role       = aws_iam_role.ec2_rds_connect_role.name
  policy_arn = aws_iam_policy.rds_connect_policy.arn
}

resource "aws_iam_instance_profile" "ec2_rds_profile" {
  name = "EC2RDSInstanceProfile"
  role = aws_iam_role.ec2_rds_connect_role.name
}

resource "aws_iam_instance_profile" "example_profile" {

  name = "example_profile"

  role = aws_iam_role.example_role.name

}

resource "aws_key_pair" "mykeypair" {
  key_name = "${random_pet.bucket.id}-key"
  public_key = var.ssh_key_pair
}


resource "aws_security_group" "ssh-sg" {
  name = "${random_pet.bucket.id}-sg"
  description = "allow ssh to ec2"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "ssh from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${random_pet.bucket.id}-sg"
  }
}
resource "aws_instance" "example_instance" {

  ami           = "ami-06ca3ca175f37dd66"

  instance_type = "t2.micro"

  key_name = aws_key_pair.mykeypair.id

  iam_instance_profile = aws_iam_instance_profile.example_profile.name
  subnet_id = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.ssh-sg.id]

  tags = {

    Name = "exampleinstance"

  }

}




resource "aws_s3_bucket_policy" "example_bucket_policy" {

  bucket = aws_s3_bucket.bucket.id



  policy = jsonencode({

    "Version": "2012-10-17",

    "Statement": [

      {

        "Effect": "Allow",

        "Principal": {

          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.example_role.name}"

        },

        "Action": [

          "s3:GetObject",

          "s3:ListBucket"

        ],

        "Resource": [

          "${aws_s3_bucket.bucket.arn}",

          "${aws_s3_bucket.bucket.arn}/*"

        ]

      }

    ]

  })

}

output "instance_ip_addr" {
  value = aws_instance.example_instance.public_ip
}


output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.id
}
data "aws_caller_identity" "current" {}
