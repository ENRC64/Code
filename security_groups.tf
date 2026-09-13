/* 
 * Security Groups (SG) fungieren als virtuelle Firewalls auf Instanz-Ebene.
 */

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Erlaubt Web-Traffic (HTTP/HTTPS) von ueberall (0.0.0.0/0)"
  vpc_id      = aws_vpc.main.id

  # Port 80 (HTTP) für unverschlüsselten Traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 443 (HTTPS) für verschlüsselten Traffic (Relevant in Kombination mit CloudFront)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Erlaube dem Load Balancer, Anfragen an die EC2-Instanzen weiterzuleiten
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" bedeutet: Alle Protokolle
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Erlaubt Traffic ausschliesslich vom Load Balancer (Zero Trust Prinzip)"
  vpc_id      = aws_vpc.main.id

  /*
   * ZERO TRUST ARCHITEKTUR:
   * Statt eine IP-Range freizugeben, wird Traffic nur dann erlaubt, wenn er
   * den "Ausweis" der Load Balancer Security Group trägt. Selbst wenn jemand
   * die IP-Adresse der EC2-Instanz herausfindet, blockt die Firewall ihn ab.
   */
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Die Server müssen Updates laden können (ausgehend)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}