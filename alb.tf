# 1. Der eigentliche Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  # internal = false bedeutet, er ist aus dem Internet erreichbar (Internet-facing)
  internal           = false
  # Typ "application" operiert auf Layer 7 (OSI-Modell) und versteht HTTP-Header
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # Ein ALB benötigt zwingend mindestens 2 Subnetze in unterschiedlichen AZs
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# 2. Die Target Group (Das logische Ziel für den Load Balancer)
# Nur eine Target Group nötig, da alle Server die selbe Aufgabe haben
# Auto Scaling Group weist einen hochgefahreren Server später der Target Group zu
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Der ALB prüft regelmäßig, ob die Server gesund sind.
  health_check {
    path                = "/"       # Ruft die Startseite auf
    protocol            = "HTTP"
    matcher             = "200"     # Erwartet den HTTP-Statuscode 200 (OK)
    interval            = 15        # Prüft alle 15 Sekunden
    timeout             = 3         # Wenn nach 3 Sekunden keine Antwort kommt = Fehler
    healthy_threshold   = 2         # Nach 2 erfolgreichen Checks gilt der Server als gesund
    unhealthy_threshold = 2         # Nach 2 fehlgeschlagenen Checks wird kein Traffic mehr an diesen Server gesendet
  }
}

# 3. Der Listener (Die Regel, was mit eingehenden Verbindungen passiert)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Standardaktion: Schiebe alle Anfragen unveraendert in die Target Group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}