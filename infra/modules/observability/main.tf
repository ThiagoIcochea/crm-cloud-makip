resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Alertas Makip (correo)"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

locals {
  checks = { for k, v in var.uptime_targets : k => v if v.enabled }
}

resource "google_monitoring_uptime_check_config" "https" {
  for_each     = local.checks
  project      = var.project_id
  display_name = "uptime-${each.key}"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = each.value.path
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }
}

resource "google_monitoring_alert_policy" "uptime" {
  for_each     = local.checks
  project      = var.project_id
  display_name = "Caída: ${each.key}"
  combiner     = "OR"

  conditions {
    display_name = "Uptime fallido ${each.key}"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.https[each.key].uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "600s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.*"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# Errores 5xx en la API de catálogo
resource "google_monitoring_alert_policy" "api_5xx" {
  project      = var.project_id
  display_name = "API de catálogo: errores 5xx"
  combiner     = "OR"

  conditions {
    display_name = "5xx > 5 en 5 min"
    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\" AND resource.label.service_name=\"${var.cloud_run_service}\" AND metric.label.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# Presupuesto con alertas (FinOps). Se omite si no hay cuenta de facturación.
resource "google_billing_budget" "monthly" {
  count           = var.billing_account == "" ? 0 : 1
  billing_account = var.billing_account
  display_name    = "Presupuesto mensual Makip"

  budget_filter {
    projects = ["projects/${var.project_number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  threshold_rules { threshold_percent = 0.5 }
  threshold_rules { threshold_percent = 0.9 }
  threshold_rules { threshold_percent = 1.0 }
}
