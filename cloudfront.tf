# -----------------------------------------------------------------------------
# CACHE POLICY
# -----------------------------------------------------------------------------
# Importiert ein von AWS fertiges Regelwerk für das Caching. 
# Diese Policy bestimmt, wie lange Dateien im Zwischenspeicher bleiben (TTL) 
# und welche HTTP-Header an den Server durchgereicht werden.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# -----------------------------------------------------------------------------
# CLOUDFRONT DISTRIBUTION (Das CDN)
# -----------------------------------------------------------------------------
# Erstellt die eigentliche CloudFront-Instanz. Das CDN nimmt Nutzeranfragen 
# weltweit entgegen und liefert die angefragte Webseite aus dem Zwischenspeicher aus.
resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  
  # Legt fest, welche weltweiten Knotenpunkte (Edge Locations) aktiv sind.
  # "PriceClass_100" aktiviert nur die Server in Nordamerika und Europa.
  price_class     = "PriceClass_100" 

  # --- ORIGIN (Die Datenquelle) ---
  # Definiert, woher CloudFront die Daten holen soll, wenn sie noch nicht 
  # im Cache liegen. Hier wird der DNS-Name des Load Balancers referenziert.
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALBOrigin"

    # Konfiguriert die direkte Kommunikation zwischen CloudFront und dem Load Balancer.
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      
      # Legt fest, dass CloudFront Anfragen nur über HTTP (Port 80) an den 
      # Load Balancer weiterreicht, da dieser über keinen HTTPS-Listener verfügt.
      origin_protocol_policy = "http-only" 
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- CACHE BEHAVIOR (Das Verhalten am Edge-Knoten) ---
  # Bestimmt, wie Nutzer-Anfragen verarbeitet werden, bevor sie an den Origin gehen.
  default_cache_behavior {
    # Erlaubt lesende HTTP-Anfragen an das CDN.
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    
    # Definiert, dass die Antworten auf GET- und HEAD-Anfragen gecached werden.
    cached_methods   = ["GET", "HEAD"]
    
    # Verknüpft dieses Verhalten mit dem definierten Load Balancer (Origin).
    target_origin_id = "ALBOrigin"

    # Zwingt jede unverschlüsselte HTTP-Anfrage eines Nutzers direkt am 
    # CloudFront-Server in eine verschlüsselte HTTPS-Verbindung (301 Redirect).
    viewer_protocol_policy = "redirect-to-https"
    
    # Wendet die oben importierte AWS Cache-Policy auf diese Distribution an.
    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  # Konfiguriert Ländersperren (Geo-Blocking). 
  # "none" bedeutet, dass der Zugriff weltweit ohne Einschränkung möglich ist.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # --- ZERTIFIKAT ---
  # Stellt das SSL/TLS-Zertifikat bereit, das für die HTTPS-Verbindung zum Endnutzer nötig ist.
  # "true" nutzt das kostenlose Standard-Zertifikat für die von AWS generierte *.cloudfront.net Domain.
  viewer_certificate {
    cloudfront_default_certificate = true 
  }

  tags = {
    Name = "${var.project_name}-cloudfront"
  }
}