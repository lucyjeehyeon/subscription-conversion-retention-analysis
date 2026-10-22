"""Reproduce selected aggregates from project marts; never emit individual rows.

Added during repository preparation. It preserves the final team notebook's
four-segment logic and shows distinct retention cohort definitions separately.
It does not rebuild the marts or establish a causal treatment effect.
"""
import argparse
import csv
import json
import math
from pathlib import Path


def read_mart(path, numeric_columns):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        required = {"user_id", "period_group", *numeric_columns}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"{path.name}: missing columns {sorted(missing)}")
        rows = list(reader)
    seen = set()
    for index, row in enumerate(rows, start=2):
        key = row["user_id"]
        if not key or key in seen:
            raise ValueError(f"{path.name}: empty or duplicate user key at row {index}")
        seen.add(key)
        for column in numeric_columns:
            try:
                value = float(row[column])
            except (ValueError, TypeError):
                raise ValueError(f"{path.name}: invalid {column} at row {index}") from None
            if not math.isfinite(value) or value < 0:
                raise ValueError(f"{path.name}: invalid {column} at row {index}")
            if column in {"paid_30d", "renewed_60d", "can_observe_60d", "is_post_removed"} and value not in (0, 1):
                raise ValueError(f"{path.name}: non-binary {column} at row {index}")
            row[column] = value
    if not rows:
        raise ValueError(f"{path.name}: no data rows")
    return rows


def aggregate(rows, target):
    positives = int(sum(row[target] for row in rows))
    return {
        "users": len(rows),
        "positive_users": positives,
        "rate_pct": round(100 * positives / len(rows), 2) if rows else None,
    }


def segment(row):
    count = row["lesson_complete_prepay_7d"]
    if count >= 7:
        return "strong_learner"
    if count >= 1:
        return "weak_learner"
    if any(row[col] > 0 for col in ("unique_content_prepay_7d", "content_view_7d", "content_start_7d")):
        return "explorer"
    return "inactive"


def retention_table(rows):
    groups = {"0-4": [], "5-13": [], "14+": []}
    for row in rows:
        days = row["active_learning_days_postpay_30d"]
        group = "0-4" if days <= 4 else "5-13" if days <= 13 else "14+"
        groups[group].append(row)
    return {key: aggregate(group, "renewed_60d") for key, group in groups.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("results/key_metrics.json"))
    args = parser.parse_args()
    users = read_mart(args.data_dir / "dm_user_activation_payment.csv", [
        "paid_30d", "lesson_complete_prepay_7d", "unique_content_prepay_7d",
        "content_view_7d", "content_start_7d",
    ])
    retention = read_mart(args.data_dir / "dm_user_subscription_retention_core.csv", [
        "is_post_removed", "can_observe_60d", "renewed_60d", "active_learning_days_postpay_30d",
    ])
    post = [r for r in users if r["period_group"] == "post_2023_05_11"]
    if not post:
        raise ValueError("No post-removal activation cohort")
    conversion = {key: aggregate([r for r in post if segment(r) == key], "paid_30d")
                  for key in ("inactive", "explorer", "weak_learner", "strong_learner")}
    retention_post = [r for r in retention if r["is_post_removed"] == 1]
    periods = {key: aggregate([r for r in users if r["period_group"] == key], "paid_30d")
               for key in sorted({r["period_group"] for r in users})}
    for key, value in periods.items():
        payers = [r for r in users if r["period_group"] == key and r["paid_30d"] == 1]
        for column in ("first_paid_amount", "first_discount_amount"):
            amounts = [float(r[column]) for r in payers]
            if not all(math.isfinite(v) for v in amounts):
                raise ValueError(f"Invalid monetary values: {column}")
            value["mean_" + column] = round(sum(amounts) / len(amounts), 2) if amounts else None
    result = {
        "method": "Reaggregation of supplied marts, not reconstruction from raw event logs.",
        "activation_cohorts": periods,
        "conversion_segments_post": conversion,
        "retention_conditions": {
            "all_periods_no_observability_filter": retention_table(retention),
            "all_periods_observable_60d": retention_table([r for r in retention if r["can_observe_60d"] == 1]),
            "post_removal_no_observability_filter": retention_table(retention_post),
            "post_removal_observable_60d": retention_table([r for r in retention_post if r["can_observe_60d"] == 1]),
        },
        "data_checks": {
            "activation_users": len(users),
            "retention_users": len(retention),
            "duplicate_or_missing_user_keys": 0,
            "max_activity_days": max(r["active_learning_days_postpay_30d"] for r in retention),
            "activity_days_over_30": sum(r["active_learning_days_postpay_30d"] > 30 for r in retention),
        },
        "limits": [
            "Content experience mixes prepayment and full 7-day behavior windows.",
            "The activity-day field exceeds 30 in some rows; confirm its construction before calling it a rolling 30-day window.",
            "Retrospective group differences are not the causal effect of onboarding or learning interventions.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    print(f"Saved aggregate results: {args.output}")


if __name__ == "__main__":
    main()
