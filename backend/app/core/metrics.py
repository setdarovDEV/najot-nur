"""Prometheus metrics for the NotiqAI backend."""
from __future__ import annotations

from prometheus_client import Counter, Gauge, Histogram

http_requests_total = Counter(
    "notiqai_http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

http_request_duration_seconds = Histogram(
    "notiqai_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)

http_requests_in_progress = Gauge(
    "notiqai_http_requests_in_progress",
    "HTTP requests currently being processed",
)

rate_limit_rejections_total = Counter(
    "notiqai_rate_limit_rejections_total",
    "Requests rejected by rate limiter",
    ["endpoint"],
)

auth_failures_total = Counter(
    "notiqai_auth_failures_total",
    "Authentication failures",
    ["reason"],
)

ai_requests_total = Counter(
    "notiqai_ai_requests_total",
    "AI analysis requests",
    ["provider", "analysis_type", "status"],
)

ai_request_duration_seconds = Histogram(
    "notiqai_ai_request_duration_seconds",
    "AI analysis duration in seconds",
    ["provider", "analysis_type"],
    buckets=(0.5, 1.0, 2.5, 5.0, 10.0, 15.0, 30.0, 60.0),
)

db_query_duration_seconds = Histogram(
    "notiqai_db_query_duration_seconds",
    "Database query duration in seconds",
    ["operation"],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0),
)

redis_operations_total = Counter(
    "notiqai_redis_operations_total",
    "Redis operations",
    ["operation", "status"],
)

active_users = Gauge(
    "notiqai_active_users",
    "Currently active users (sessions with heartbeat in last 5 min)",
)

security_events_total = Counter(
    "notiqai_security_events_total",
    "Security events from mobile clients",
    ["event_type"],
)

uploads_total = Counter(
    "notiqai_uploads_total",
    "File uploads",
    ["file_type"],
)

upload_size_bytes = Histogram(
    "notiqai_upload_size_bytes",
    "File upload sizes in bytes",
    ["file_type"],
    buckets=(1024, 10240, 102400, 1048576, 10485760, 52428800, 104857600),
)
