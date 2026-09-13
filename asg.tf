# Sucht dynamisch nach der aktuellsten "Amazon Linux 2023" Server-Image-ID (AMI)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 1. Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = data.aws_ami.amazon_linux_2023.id
  # t3.micro bietet 2 vCPUs und 1 GiB RAM - komplett ausreichend und im AWS Free-Tier
  instance_type = "t3.micro" 
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  /*
   * USER DATA SCRIPT:
   * Bash-Skript, das nur beim ersten Hochfahren der Instanz ausgeführt wird.
   * Es installiert Nginx und baut eine Webseite, die Server-Metadaten (Instanz-ID & AZ) anzeigt.
   */
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl start nginx
    systemctl enable nginx

    # Abrufen von Metadaten über IMDSv2 (benötigt ein Token)
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    
    echo "<h1>Cloud Computing Portfolio</h1>
          <p>Instanz-ID: <strong>$INSTANCE_ID</strong></p>
          <p>Availability Zone: <strong>$AZ</strong></p>" > /usr/share/nginx/html/index.html
  EOF
  )
}

# 2. Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg"
  # Die ASG startet neue Instanzen NUR in den privaten Subnetzen
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  
  # Bindet die erstellten Server automatisch an den Load Balancer an
  target_group_arns   = [aws_lb_target_group.main.arn]

  # Skalierungsgrenzen (Kostenkontrolle)
  min_size         = 2 # Mindestens 2 (für High Availability)
  desired_capacity = 2 # Normalzustand
  max_size         = 4 # Maximales Limit bei Lastspitzen

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest" # Nutzt immer die neueste Version des Templates
  }
}

# 3. Scaling Policy (Regeln für das automatische Hoch- und Herunterskalieren)
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project_name}-cpu-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.main.name

  # AWS fügt automatisch Server hinzu oder entfernt welche, 
  # um die CPU-Auslastung der gesamten Gruppe bei ca. 60% zu halten.
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0 
  }
}