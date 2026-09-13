/*
 * Outputs geben wichtige Informationen nach dem erfolgreichen 'terraform apply'
 * direkt in der Konsole aus, da z.B. DNS-Namen erst bei der Erstellung in AWS
 * generiert werden und vorher nicht bekannt sind.
 */

output "alb_dns_name" {
  description = "URL des Load Balancers. Zeigt Traffic ohne CDN (ungeschuetzt via HTTP)."
  value       = "http://${aws_lb.main.dns_name}"
}

output "cloudfront_domain_name" {
  description = "Die URL des globalen CDNs (sicher via HTTPS). Dies ist der Haupt-Link für die Präsentation!"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}