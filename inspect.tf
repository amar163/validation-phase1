# resource "aws_iam_instance_profile" "test_profile" {
#   name = "test_profile"
#   role = aws_iam_role.role.name
# }

# resource "aws_iam_role" "role" {
#   name = "test_role"
#   path = "/"

#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "sts:AssumeRole",
#             "Principal": {
#                "Service": "ec2.amazonaws.com"
#             },
#             "Effect": "Allow",
#             "Sid": ""
#         }
#     ]
# }
# EOF
# }


resource "aws_instance" "inspector-instance" {
  ami = var.AMI_ID
  instance_type = "t2.micro"
  # iam_instance_profile = aws_iam_instance_profile.test_profile.name
  security_groups = ["${aws_security_group.sample_sg.name}"]
  # user_data = file("startup.sh")

  tags = {
    Name = "InspectInstances"
  }
  depends_on = [aws_inspector_resource_group.bar]

}

resource "aws_security_group" "sample_sg" {
  name = "Allow SSH"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_inspector_resource_group" "bar" {
  tags = {
    Name = "InspectInstances"
  }
}

resource "aws_inspector_assessment_target" "myinspect" {
  name = "inspector-instance-assessment"
  resource_group_arn = aws_inspector_resource_group.bar.arn
}

resource "aws_inspector_assessment_template" "bar-template" {
  name       = "bar-template"
  target_arn = aws_inspector_assessment_target.myinspect.arn
  duration   = 180
  rules_package_arns = [
    "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-JnA8Zp85",
    "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-m8r61nnh",
    "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-cE4kTR30",
    "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-AxKmMHPX",
  ]
}

resource "null_resource" "example1" {
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ansible"
      password = "ansible123"
      host = aws_instance.inspector-instance.public_ip
    }
    inline = [
      "wget https://d1wk0tztpsntt1.cloudfront.net/linux/latest/install -P /tmp/",
      "sudo bash /tmp/install",
      "sudo systemctl start awsagent"
    ]
  }
  depends_on = [aws_instance.inspector-instance]
}
