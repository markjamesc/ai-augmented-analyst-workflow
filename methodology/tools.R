# Reusable mechanical helpers. Source contracts.R before this file.
# These do not share project judged logic across R-A/R-B.
m_file_ref <- function(path, root) list(path = gsub("\\\\", "/", path), sha256 = m_hash(file.path(root, path)))
m_save_attempt <- function(value, directory, prefix) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  path <- tempfile(paste0(prefix, "-"), tmpdir = directory, fileext = ".json")
  jsonlite::write_json(value, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  path
}
m_environment <- function(directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  writeLines(capture.output(sessionInfo()), file.path(directory, "sessionInfo.txt"))
  pkgs <- as.data.frame(installed.packages()[, c("Package", "Version", "Built"), drop = FALSE])
  write.csv(pkgs, file.path(directory, "installed-packages.csv"), row.names = FALSE)
  list(r_version = R.version.string, os = Sys.info()[["sysname"]], locale = Sys.getlocale(),
    timezone = Sys.timezone(), encoding = l10n_info(), rng = RNGkind(),
    threads = Sys.getenv(c("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS")),
    note = "Inventory is not a restorable lockfile. Supply renv.lock or equivalent retrievable dependency specification separately.")
}
# Each independent builder supplies its own adapter. The same dumb comparator may be reused.
m_metamorphic <- function(run, input, transform, compare, relation_id, preconditions, path_id, directory) {
  stopifnot(is.function(run), is.function(transform), is.function(compare),
    m_text(relation_id), m_text(preconditions), path_id %in% c("R-A", "R-B"))
  result <- tryCatch({
    before <- run(input); after <- run(transform(input))
    list(result = if (isTRUE(compare(before, after))) "PASS" else "FAIL",
      before_sha256 = digest::digest(before, algo = "sha256"), after_sha256 = digest::digest(after, algo = "sha256"))
  }, error = function(e) list(result = "FAIL", error = conditionMessage(e)))
  m_save_attempt(c(list(id = relation_id, path_id = path_id, preconditions = preconditions,
    checked_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)), result), directory, "metamorphic")
}
# Run a reviewed project replay script in a new R process. It takes two arguments:
# frozen input root and an initially empty output root. It must not overwrite originals.
m_replay <- function(script, frozen_root, output_root, outputs, report_directory) {
  stopifnot(file.exists(script), dir.exists(frozen_root), m_strings(outputs))
  outputs <- unlist(outputs)
  if (any(grepl("^(/|[A-Za-z]:|\\\\)", outputs)) || any(vapply(strsplit(gsub("\\\\", "/", outputs), "/", fixed = TRUE), function(x) any(x %in% c("", ".", "..")), logical(1)))) stop("Replay outputs must be safe relative paths")
  if (dir.exists(output_root) && length(list.files(output_root, all.files = TRUE, no.. = TRUE))) stop("Replay output root must be empty")
  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(report_directory, recursive = TRUE, showWarnings = FALSE)
  frozen_paths <- list.files(frozen_root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  frozen_paths <- frozen_paths[!dir.exists(frozen_paths)]
  frozen_hashes <- vapply(frozen_paths, m_hash, character(1))
  original_hashes <- vapply(outputs, function(p) m_hash(file.path(frozen_root, p)), character(1))
  script_hash <- m_hash(script)
  log <- tempfile("replay-console-", tmpdir = report_directory, fileext = ".txt")
  status <- system2(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(normalizePath(script)), shQuote(normalizePath(frozen_root)), shQuote(normalizePath(output_root))), stdout = log, stderr = log)
  pairs <- lapply(outputs, function(path) {
    original <- file.path(frozen_root, path); replayed <- file.path(output_root, path)
    list(path = path, original_sha256 = unname(original_hashes[[path]]),
      replayed_sha256 = if (file.exists(replayed)) m_hash(replayed) else NULL)
  })
  inputs_unchanged <- all(file.exists(frozen_paths)) && identical(frozen_hashes, vapply(frozen_paths, m_hash, character(1)))
  ok <- status == 0L && inputs_unchanged && all(vapply(pairs, function(x) m_text(x$original_sha256) && identical(x$original_sha256, x$replayed_sha256), logical(1)))
  m_save_attempt(list(status = if (ok) "PASS" else "FAIL", clean_session = TRUE,
    exit_status = status, inputs_unchanged = inputs_unchanged, script_sha256 = script_hash, outputs = pairs, console = log,
    limitation = "Exact deterministic-output replay; use canonical keyed output serialization. Hosted AI text is not regenerated."), report_directory, "replay")
}

# Execute a reviewed test closure against bound component bytes. Not an AI-response simulator.
m_bound_test <- function(id, components, root, run, report_directory = "reports/versioned-tests") {
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  if(!m_text(id) || !is.function(run) || !m_refs_ok(components,root)) stop("Invalid test inputs")
  before <- components
  failure <- NULL
  passed <- tryCatch(isTRUE(run()),error=function(e) {failure <<- conditionMessage(e); FALSE})
  passed <- passed && m_refs_ok(before,root)
  report <- list(id=id,result=if(passed) "PASS" else "FAIL",components=before,failure=failure,
                 recorded_at_utc=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"))
  dir.create(file.path(root,report_directory),recursive=TRUE,showWarnings=FALSE)
  path <- tempfile("test-",tmpdir=file.path(root,report_directory),fileext=".json")
  jsonlite::write_json(report,path,auto_unbox=TRUE,pretty=TRUE)
  report$report <- m_file_ref(substring(path,nchar(root)+2),root)
  report
}


# D-20: freeze a candidate before dispatch; never overwrite an existing snapshot.
m_freeze_file <- function(path, root, directory="artifacts/versions") {
  stopifnot(m_text(path),m_text(directory))
  ref<-m_file_ref(path,root)
  if(!m_ref_ok(ref,root))stop("Unsafe or missing candidate")
  target<-paste0(directory,"/",ref$sha256,"-",basename(path))
  if(grepl("^(/|[A-Za-z]:)",target) || any(strsplit(target,"/",fixed=TRUE)[[1]] %in% c("",".","..")))stop("Unsafe snapshot directory")
  dir.create(file.path(root,directory),recursive=TRUE,showWarnings=FALSE)
  if(file.exists(file.path(root,target))) {
    if(!identical(m_hash(file.path(root,target)),ref$sha256))stop("Conflicting immutable snapshot")
  } else if(!file.copy(file.path(root,path),file.path(root,target),overwrite=FALSE))stop("Snapshot failed")
  m_file_ref(target,root)
}
# D-27: set inherited environment explicitly; system2(env=) is not used.
m_run_child <- function(script,args=character(),environment=character(),log) {
  if(!file.exists(script) || file.exists(log))stop("Existing script and a new log path required")
  if(length(environment) && (is.null(names(environment)) || any(!nzchar(names(environment))) || anyDuplicated(names(environment))))stop("Named environment required")
  before<-setNames(Sys.getenv(names(environment),unset=NA_character_),names(environment))
  on.exit({for(k in names(environment))if(is.na(before[[k]]))Sys.unsetenv(k) else do.call(Sys.setenv,setNames(list(before[[k]]),k))},add=TRUE)
  if(length(environment)) do.call(Sys.setenv,as.list(environment))
  system2(file.path(R.home("bin"),"Rscript"),c("--vanilla",shQuote(normalizePath(script,winslash="/")),vapply(args,shQuote,character(1))),stdout=log,stderr=log)
}
