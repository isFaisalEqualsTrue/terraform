provider "aws" {
   region = "us-east-2"

}


resource "aws_security_group" "instance" {
     name = "web_sg01"

     ingress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

}

}


resource "aws_instance" "WEBAPP" {
   ami   = "ami-0c55b159cbfafe1f0"
   instance_type = "t2.micro"
   vpc_security_group_ids = [aws_security_group.instance.id]
   
   user_data = <<-EOF
		#!/bin/bash
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDsMvbjudxwULVOY9VXjPsxDlypc85DMmZP73XE6rPJF90wL9SjRyB0GOpiTbELTaCarb/CkG1KU1VugCGK9tf2XSVYRHhfEOU8BYi+jemqU6zN+b6nAy2DK6tTATGtUd7deW00dr7wLnr/94qwz2GcaQsX68JtkAcbOcBYYPhRrxSK+ToLZfykyTxRmUtlHQyGjRBoh72az/VhBMB21uFoIfmx1dfSNHxpq5SuaJGI9r3dk/21gQMvOyAlvPomA+DHf+0yiMsDvoghcdIyiXKYrwCpJTILr113MHakEMIR42zU4tWP8tGB722F1br0Z3z/uPT73upJyWyP2sZTyyxebFiDiUQkIZyxd1Bu8ttq86IEIoSI6Gg2dFU46qCc6SiBPAJDt0Qlk2se7Yc59gPz6NS8yGS7C5nyPWga5xuO2NMV6hc6LYOdxD/3U7BJLx2Ljrt6BvkDhI1Z/7pLtQu2Vu6HXfT+C++20lv5+kmOHzEdy0ZDxc51fNHKVoUzfkE= mdfaisal@Faisal-Laptop" >> ~/.ssh/authorized_keys
		echo "Hello, World" > index.html
		nohup busybox httpd -f -p 80 &
		EOF
   tags = {
     Name = "app01"

}
}

