library(tidyverse)

result <- readRDS("benchmark/results/benchmark_result.rds")

daily <- result$daily
measured <- result$measured

expect_equal <- function(actual, expected, tolerance = 1e-10, label = "value") {
  if (length(actual) != length(expected)) {
    stop(label, " length mismatch: ", length(actual), " != ", length(expected))
  }

  both_na <- is.na(actual) & is.na(expected)
  numeric_ok <- if (is.numeric(actual) && is.numeric(expected)) {
    both_na | (!is.na(actual) & !is.na(expected) & abs(actual - expected) <= tolerance)
  } else {
    both_na | (!is.na(actual) & !is.na(expected) & actual == expected)
  }

  if (!all(numeric_ok)) {
    stop(label, " mismatch. actual=", paste(actual, collapse = ","),
         " expected=", paste(expected, collapse = ","))
  }

  invisible(TRUE)
}

# Complete: 4 entities x 46 calendar days.
stopifnot(nrow(daily) == 184L)
stopifnot(nrow(distinct(daily, entity, event_date)) == 184L)

# Missing source day is completed but events/exposure are not silently filled.
b_missing <- daily %>%
  filter(entity == "B", event_date == as.Date("2026-01-03"))

stopifnot(nrow(b_missing) == 1L)
stopifnot(is.na(b_missing$events))
stopifnot(is.na(b_missing$exposed))

# Counts and denominator protection.
entity_counts <- measured$entity$counts %>%
  arrange(entity)

expect_equal(entity_counts$events, c(4, 4, 3, 0), label = "entity event counts")
expect_equal(entity_counts$exposed, c(46, 45, 46, 0), label = "entity exposure counts")

entity_rates <- measured$entity$rates %>%
  arrange(entity)

expect_equal(
  entity_rates$rate,
  c(4/46, 4/45, 3/46, NA_real_),
  label = "entity rates"
)

# Rolling windows: incomplete windows stay NA; missing source day poisons B's
# 30-day window until it leaves the window, then calculation resumes.
a_rolling <- measured$entity$rolling %>%
  filter(
    entity == "A",
    window == 30L,
    event_date == as.Date("2026-02-02")
  )

expect_equal(a_rolling$rolling_events, 3, label = "A rolling events")
expect_equal(a_rolling$rolling_exposed, 30, label = "A rolling exposure")
expect_equal(a_rolling$rolling_rate, 3/30, label = "A rolling rate")

b_rolling_bad <- measured$entity$rolling %>%
  filter(
    entity == "B",
    window == 30L,
    event_date == as.Date("2026-02-01")
  )

stopifnot(is.na(b_rolling_bad$rolling_events))
stopifnot(is.na(b_rolling_bad$rolling_exposed))
stopifnot(is.na(b_rolling_bad$rolling_rate))

b_rolling_good <- measured$entity$rolling %>%
  filter(
    entity == "B",
    window == 30L,
    event_date == as.Date("2026-02-02")
  )

expect_equal(b_rolling_good$rolling_events, 3, label = "B resumed rolling events")
expect_equal(b_rolling_good$rolling_exposed, 30, label = "B resumed rolling exposure")

# Spells: A has one two-day event spell and two one-day event spells.
a_spells <- measured$entity$spells %>%
  filter(entity == "A")

stopifnot(nrow(a_spells) == 3L)
expect_equal(sort(a_spells$duration_days), c(1, 1, 2), label = "A spell durations")

# Before/after intervention.
a_before_after <- measured$entity$before_after %>%
  filter(entity == "A")

expect_equal(a_before_after$events_before, 3, label = "A before events")
expect_equal(a_before_after$events_after, 1, label = "A after events")
expect_equal(a_before_after$exposed_before, 22, label = "A before exposure")
expect_equal(a_before_after$exposed_after, 24, label = "A after exposure")
expect_equal(a_before_after$rate_before, 3/22, label = "A before rate")
expect_equal(a_before_after$rate_after, 1/24, label = "A after rate")

# Monthly aggregation.
a_monthly <- measured$entity$monthly %>%
  filter(entity == "A") %>%
  arrange(month)

expect_equal(a_monthly$events, c(3, 1), label = "A monthly events")
expect_equal(a_monthly$exposed, c(31, 15), label = "A monthly exposure")

# Shape uses nested tibbles/list-columns while Measure exposes the required
# measured[[group]][[metric]] contract.
stopifnot(is.data.frame(result$pieces$entity))
stopifnot("data" %in% names(result$pieces$entity))
stopifnot(is.list(result$pieces$entity$data))
stopifnot(is.list(measured$entity))
stopifnot(is.data.frame(measured$entity$rates))

# Publish produced a real workbook.
stopifnot(length(result$outputs$excel) == 1L)
stopifnot(file.exists(result$outputs$excel))
stopifnot(file.info(result$outputs$excel)$size > 0)

cat("FUNCTIONAL BENCHMARK: PASS\n")
