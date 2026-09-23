# R Workflow Engine benchmark output
# Generated against docs/ENGINE.md on 2026-09-23.

library(tidyverse)
library(janitor)
library(lubridate)
library(readxl)
library(openxlsx)
library(zoo)

`%not_in%` <- negate(`%in%`)

# ---- CONFIG ---------------------------------------------------------------

CONFIG <- list(
  entity_key  = "entity",
  time_key    = "event_date",
  grain       = "entity-day",
  window_days = 46L,
  groups      = c("entity", "class"),
  paths       = list(
    daily  = "benchmark/fixtures/daily.csv",
    lookup = "benchmark/fixtures/lookup.xlsx"
  ),
  expand      = FALSE,
  horizon     = 30L,
  method      = NULL,
  publish     = c("excel"),
  recodes     = list(intervention_date = as.Date("2026-01-23")),
  pack        = "usual"
)

# ---- Small reusable helpers ----------------------------------------------

safe_rate <- function(events, exposed) {
  if_else(is.na(exposed) | exposed <= 0, NA_real_, events / exposed)
}

strict_sum <- function(x) {
  if (length(x) == 0L || any(is.na(x))) NA_real_ else sum(x)
}

build_synthetic_inputs <- function(CONFIG) {
  dates <- seq.Date(as.Date("2026-01-01"), as.Date("2026-02-15"), by = "day")

  lookup <- tibble(
    entity = c("A", "B", "C", "D"),
    class = c("alpha", "alpha", "beta", "beta")
  )

  daily <- crossing(
    entity = lookup$entity,
    event_date = dates
  ) %>%
    group_by(entity) %>%
    mutate(
      day_index = row_number(),
      events = case_when(
        entity == "A" & day_index %in% c(5L, 6L, 20L, 40L) ~ 1,
        entity == "B" & day_index %in% c(10L, 11L, 12L, 35L) ~ 1,
        entity == "C" & day_index %in% c(15L, 30L, 45L) ~ 1,
        TRUE ~ 0
      ),
      exposed = if_else(entity == "D", 0, 1),
      flag = as.integer(events > 0)
    ) %>%
    ungroup() %>%
    filter(!(entity == "B" & day_index == 3L)) %>%
    select(-day_index)

  list(daily = daily, lookup = lookup)
}

shape_one <- function(daily, group, CONFIG) {
  daily %>%
    select(all_of(c(group, CONFIG$time_key, "events", "exposed", "flag"))) %>%
    nest(.by = all_of(group))
}

summarize_nested <- function(nested, group, summarizer) {
  nested %>%
    mutate(result = map(data, summarizer)) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]])
}

aggregate_group_day <- function(data, CONFIG) {
  data %>%
    group_by(.data[[CONFIG$time_key]]) %>%
    summarize(
      events = strict_sum(events),
      exposed = strict_sum(exposed),
      flag = if (any(is.na(flag))) NA_integer_ else as.integer(any(flag == 1L)),
      .groups = "drop"
    ) %>%
    arrange(.data[[CONFIG$time_key]])
}

metric_counts <- function(nested, group, CONFIG) {
  summarize_nested(
    nested,
    group,
    \(data)
      data %>%
        summarize(
          events = sum(events, na.rm = TRUE),
          exposed = sum(exposed, na.rm = TRUE),
          rows = n()
        )
  )
}

metric_rates <- function(nested, group, CONFIG) {
  metric_counts(nested, group, CONFIG) %>%
    mutate(
      rate = safe_rate(events, exposed),
      annualized_rate = rate * 365.25
    )
}

rolling_one_group <- function(data, CONFIG) {
  daily <- aggregate_group_day(data, CONFIG)
  windows <- c(30L, 90L, 180L, 360L, 540L)

  windows %>%
    map_dfr(
      \(window)
        daily %>%
          mutate(
            window = window,
            rolling_events = zoo::rollapplyr(
              events,
              width = window,
              FUN = sum,
              fill = NA_real_,
              partial = FALSE,
              na.rm = FALSE
            ),
            rolling_exposed = zoo::rollapplyr(
              exposed,
              width = window,
              FUN = sum,
              fill = NA_real_,
              partial = FALSE,
              na.rm = FALSE
            ),
            rolling_rate = safe_rate(rolling_events, rolling_exposed),
            rolling_annualized_rate = rolling_rate * 365.25
          )
    )
}

metric_rolling <- function(nested, group, CONFIG) {
  nested %>%
    mutate(result = map(data, \(data) rolling_one_group(data, CONFIG))) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]], window, .data[[CONFIG$time_key]])
}

spells_one_group <- function(data, CONFIG) {
  daily <- aggregate_group_day(data, CONFIG) %>%
    mutate(
      active = replace_na(flag, 0L) == 1L,
      new_spell = active & !lag(active, default = FALSE),
      spell_id = cumsum(new_spell)
    )

  daily %>%
    filter(active) %>%
    group_by(spell_id) %>%
    summarize(
      start_date = min(.data[[CONFIG$time_key]]),
      end_date = max(.data[[CONFIG$time_key]]),
      duration_days = as.integer(end_date - start_date) + 1L,
      status = if_else(
        end_date == max(daily[[CONFIG$time_key]]),
        "OPEN",
        "CLOSED"
      ),
      .groups = "drop"
    ) %>%
    select(-spell_id)
}

metric_spells <- function(nested, group, CONFIG) {
  nested %>%
    mutate(result = map(data, \(data) spells_one_group(data, CONFIG))) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]], start_date)
}

episodes_one_group <- function(data, CONFIG) {
  daily <- aggregate_group_day(data, CONFIG)
  spells <- spells_one_group(data, CONFIG)

  before <- daily %>%
    transmute(
      join_date = .data[[CONFIG$time_key]] + 1,
      events_before = events,
      exposed_before = exposed
    )

  after <- daily %>%
    transmute(
      join_date = .data[[CONFIG$time_key]] - 1,
      events_after = events,
      exposed_after = exposed
    )

  spells %>%
    left_join(before, by = c("start_date" = "join_date")) %>%
    left_join(after, by = c("end_date" = "join_date"))
}

metric_episodes <- function(nested, group, CONFIG) {
  nested %>%
    mutate(result = map(data, \(data) episodes_one_group(data, CONFIG))) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]], start_date)
}

monthly_one_group <- function(data, CONFIG) {
  data %>%
    mutate(month = floor_date(.data[[CONFIG$time_key]], unit = "month")) %>%
    group_by(month) %>%
    summarize(
      events = strict_sum(events),
      exposed = strict_sum(exposed),
      .groups = "drop"
    ) %>%
    mutate(rate = safe_rate(events, exposed))
}

metric_monthly <- function(nested, group, CONFIG) {
  nested %>%
    mutate(result = map(data, \(data) monthly_one_group(data, CONFIG))) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]], month)
}

before_after_one_group <- function(data, CONFIG) {
  intervention_date <- CONFIG$recodes$intervention_date

  data %>%
    mutate(period = if_else(
      .data[[CONFIG$time_key]] < intervention_date,
      "before",
      "after"
    )) %>%
    group_by(period) %>%
    summarize(
      events = sum(events, na.rm = TRUE),
      exposed = sum(exposed, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(rate = safe_rate(events, exposed)) %>%
    select(period, events, exposed, rate) %>%
    pivot_wider(
      names_from = period,
      values_from = c(events, exposed, rate)
    ) %>%
    mutate(rate_change = rate_after - rate_before)
}

metric_before_after <- function(nested, group, CONFIG) {
  nested %>%
    mutate(result = map(data, \(data) before_after_one_group(data, CONFIG))) %>%
    select(-data) %>%
    unnest(result) %>%
    arrange(.data[[group]])
}

# ---- Required stage functions --------------------------------------------

configure <- function(CONFIG) {
  required <- c(
    "entity_key", "time_key", "grain", "window_days", "groups",
    "paths", "expand", "horizon", "method", "publish", "recodes"
  )

  missing <- required[required %not_in% names(CONFIG)]
  if (length(missing) > 0L) {
    stop("CONFIG is missing: ", paste(missing, collapse = ", "))
  }

  if (is.null(CONFIG$pack)) CONFIG$pack <- "usual"
  CONFIG
}

load <- function(CONFIG) {
  if (file.exists(CONFIG$paths$daily) && file.exists(CONFIG$paths$lookup)) {
    daily <- read_csv(
      CONFIG$paths$daily,
      col_types = cols(
        !!CONFIG$entity_key := col_character(),
        !!CONFIG$time_key := col_date(),
        events = col_double(),
        exposed = col_double(),
        flag = col_integer()
      )
    )

    lookup <- read_xlsx(CONFIG$paths$lookup, col_types = "text")
  } else {
    synthetic <- build_synthetic_inputs(CONFIG)
    daily <- synthetic$daily
    lookup <- synthetic$lookup
  }

  pre_rows <- nrow(daily)
  lookup_duplicate_keys <- lookup %>%
    count(.data[[CONFIG$entity_key]], name = "n") %>%
    filter(n > 1L)

  joined <- daily %>%
    left_join(lookup, by = CONFIG$entity_key)

  qa <- tibble(
    check = c("pre_rows", "post_rows", "lookup_duplicate_keys"),
    value = c(pre_rows, nrow(joined), nrow(lookup_duplicate_keys))
  )

  list(data = joined, qa = qa)
}

clean <- function(daily, CONFIG) {
  daily %>%
    clean_names() %>%
    mutate(
      !!CONFIG$entity_key := as.character(.data[[CONFIG$entity_key]]),
      !!CONFIG$time_key := as.Date(.data[[CONFIG$time_key]]),
      events = as.numeric(events),
      exposed = as.numeric(exposed),
      flag = as.integer(flag)
    ) %>%
    arrange(.data[[CONFIG$entity_key]], .data[[CONFIG$time_key]])
}

complete <- function(daily, CONFIG) {
  if (CONFIG$grain %not_in% c("entity-day", "entity-time")) {
    return(daily)
  }

  attribute_cols <- setdiff(
    intersect(CONFIG$groups, names(daily)),
    CONFIG$entity_key
  )

  start_date <- max(daily[[CONFIG$time_key]], na.rm = TRUE) - (CONFIG$window_days - 1L)
  end_date <- max(daily[[CONFIG$time_key]], na.rm = TRUE)

  daily %>%
    group_by(.data[[CONFIG$entity_key]]) %>%
    tidyr::complete(
      !!sym(CONFIG$time_key) := seq.Date(
        min(.data[[CONFIG$time_key]], na.rm = TRUE),
        end_date,
        by = "day"
      )
    ) %>%
    fill(all_of(attribute_cols), .direction = "downup") %>%
    ungroup() %>%
    filter(.data[[CONFIG$time_key]] >= start_date) %>%
    arrange(.data[[CONFIG$entity_key]], .data[[CONFIG$time_key]])
}

shape <- function(daily, CONFIG) {
  CONFIG$groups %>%
    set_names() %>%
    map(\(group) shape_one(daily, group, CONFIG))
}

measure <- function(pieces, CONFIG) {
  pack_funs <- list(
    counts = metric_counts,
    rates = metric_rates,
    rolling = metric_rolling,
    spells = metric_spells,
    episodes = metric_episodes,
    monthly = metric_monthly
  )

  if (inherits(CONFIG$recodes$intervention_date, "Date")) {
    pack_funs$before_after <- metric_before_after
  }

  if (identical(CONFIG$pack, "short")) {
    pack_funs <- pack_funs[c("counts", "rates")]
  }

  pieces %>%
    imap(
      \(nested, group)
        map(pack_funs, \(metric_fun) metric_fun(nested, group, CONFIG))
    )
}

expand <- function(measured, CONFIG) {
  if (!isTRUE(CONFIG$expand)) return(measured)

  stop("Benchmark CONFIG keeps Expand off; no predictive model is required.")
}

assure <- function(object, CONFIG, gate = c("complete", "measure"), join_qa = NULL) {
  gate <- match.arg(gate)
  problems <- tibble(problem = character())

  if (gate == "complete") {
    duplicate_rows <- object %>%
      count(
        .data[[CONFIG$entity_key]],
        .data[[CONFIG$time_key]],
        name = "n"
      ) %>%
      filter(n > 1L)

    if (nrow(duplicate_rows) > 0L) {
      problems <- add_row(problems, problem = "duplicate entity-time rows")
    }

    if (any(is.na(object[[CONFIG$entity_key]]))) {
      problems <- add_row(problems, problem = "missing entity key")
    }

    span_check <- object %>%
      group_by(.data[[CONFIG$entity_key]]) %>%
      summarize(
        n_days = n_distinct(.data[[CONFIG$time_key]]),
        .groups = "drop"
      ) %>%
      filter(n_days != CONFIG$window_days)

    if (nrow(span_check) > 0L) {
      problems <- add_row(problems, problem = "window length mismatch")
    }

    if (!is.null(join_qa)) {
      pre_rows <- join_qa %>% filter(check == "pre_rows") %>% pull(value)
      post_rows <- join_qa %>% filter(check == "post_rows") %>% pull(value)
      duplicate_keys <- join_qa %>% filter(check == "lookup_duplicate_keys") %>% pull(value)

      if (length(pre_rows) != 1L || length(post_rows) != 1L || post_rows != pre_rows) {
        problems <- add_row(problems, problem = "lookup join multiplied rows")
      }

      if (length(duplicate_keys) != 1L || duplicate_keys != 0L) {
        problems <- add_row(problems, problem = "lookup duplicate keys")
      }
    }
  }

  if (gate == "measure") {
    structure_ok <- is.list(object) &&
      all(CONFIG$groups %in% names(object)) &&
      all(map_lgl(object, is.list)) &&
      all(map_lgl(object, \(metric_list) all(map_lgl(metric_list, is.data.frame))))

    if (!structure_ok) {
      problems <- add_row(problems, problem = "measured structure invalid")
    }
  }

  if (nrow(problems) > 0L) {
    stop(paste(problems$problem, collapse = "; "))
  }

  invisible(problems)
}

publish <- function(measured, CONFIG) {
  output_dir <- file.path("benchmark", "results", as.character(Sys.Date()))
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  output_paths <- list()

  if ("excel" %in% CONFIG$publish) {
    wb <- createWorkbook()

    imap(
      measured,
      \(metric_list, group)
        imap(
          metric_list,
          \(data, metric) {
            sheet <- paste(group, metric, sep = "__")
            sheet <- substr(sheet, 1L, 31L)

            addWorksheet(wb, sheet)
            freezePane(wb, sheet, firstActiveRow = 2, firstActiveCol = 2)
            writeData(wb, sheet, data)

            rate_cols <- which(str_detect(names(data), "rate"))
            if (length(rate_cols) > 0L && nrow(data) > 0L) {
              addStyle(
                wb,
                sheet = sheet,
                style = createStyle(numFmt = "PERCENTAGE"),
                rows = 2:(nrow(data) + 1L),
                cols = rate_cols,
                gridExpand = TRUE
              )
            }
          }
        )
    )

    rates <- measured$entity$rates
    p <- rates %>%
      ggplot(aes(x = entity, y = rate)) +
      geom_col() +
      labs(
        title = "Benchmark Event Rate by Entity",
        x = "Entity",
        y = "Rate"
      )

    print(p)
    insertPlot(
      wb,
      sheet = "entity__rates",
      width = 6,
      height = 4,
      startRow = 2,
      startCol = max(8, ncol(rates) + 3),
      fileType = "png"
    )

    workbook_path <- file.path(
      output_dir,
      paste0("r_workflow_engine_benchmark_", Sys.Date(), ".xlsx")
    )

    saveWorkbook(wb, workbook_path, overwrite = TRUE)
    output_paths$excel <- workbook_path
  }

  output_paths
}

# ---- Runner ---------------------------------------------------------------

run_report <- function(CONFIG) {
  CONFIG <- configure(CONFIG)

  loaded <- load(CONFIG)
  daily <- clean(loaded$data, CONFIG)
  daily <- complete(daily, CONFIG)

  assure(
    daily,
    CONFIG,
    gate = "complete",
    join_qa = loaded$qa
  )

  pieces <- shape(daily, CONFIG)
  measured <- measure(pieces, CONFIG)

  assure(
    measured,
    CONFIG,
    gate = "measure"
  )

  if (isTRUE(CONFIG$expand)) {
    measured <- expand(measured, CONFIG)
  }

  outputs <- publish(measured, CONFIG)

  list(
    daily = daily,
    pieces = pieces,
    measured = measured,
    outputs = outputs
  )
}

# ---- Benchmark run --------------------------------------------------------

benchmark_result <- run_report(CONFIG)

dir.create("benchmark/results", recursive = TRUE, showWarnings = FALSE)
saveRDS(benchmark_result, "benchmark/results/benchmark_result.rds")
