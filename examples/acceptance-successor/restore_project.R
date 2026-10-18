# Adapted from restore_check.v2.R SHA256 ad62fdc41d6bbdad245366db7452523171f20d4e47207bbe557bf84715dc330f.
# Prospective adapter: ROOT and NEW_LIBRARY supplied by tools/run_restore.R.
args <- commandArgs(TRUE)
if(length(args)!=2L) stop("Expected ROOT NEW_LIBRARY")
setwd(normalizePath(args[[1]],winslash="/"))
lib <- normalizePath(args[[2]],winslash="/")
allowed <- c(lib,normalizePath(.Library,winslash="/"))
if(!identical(normalizePath(.libPaths()[1],winslash="/"),lib) || !all(normalizePath(.libPaths(),winslash="/") %in% allowed)) stop("Unexpected library path")
spec_p <- "environment/restore-spec.txt"; spec <- readLines(spec_p)
rows <- grep("^pkg ",spec,value=TRUE)
if(!length(rows)||any(!grepl("^pkg [^ ]+ [^ ]+$",rows))) stop("Invalid package spec")
w <- sub("^pkg ","",rows);want <- setNames(sub(".* ","",w),sub(" .*","",w))
if(anyDuplicated(names(want))) stop("Duplicate package spec")
dir.create("artifacts/stage4/env_restore",recursive=TRUE,showWarnings=FALSE)
W <- tempfile("successor-",tmpdir="artifacts/stage4/env_restore")
if(!dir.create(W)) stop("Cannot create fresh attempt")
rs <- file.path(R.home("bin"),if(.Platform$OS.type=="windows")"Rscript.exe" else "Rscript")
q <- function(x) encodeString(x,quote='"')
icode <- paste0("install.packages(c(",paste(q(names(want)),collapse=","),"),lib=",q(lib),",repos='https://cloud.r-project.org',dependencies=FALSE,type=",q(if(.Platform$OS.type=="windows")"binary"else"source"),")")
t0 <- Sys.time()
ix <- system2(rs, c("--vanilla", "-e", shQuote(icode)), stdout = file.path(W, "install_stdout.txt"), stderr = file.path(W, "install_stderr.txt"))
if(ix!=0L) stop("Package installation failed; preserve attempt logs")
got <- setNames(vapply(names(want),function(p){f<-file.path(lib,p,"DESCRIPTION");if(!file.exists(f))return(NA_character_);read.dcf(f,fields="Version")[1,1]},""),names(want))
if(anyNA(got)||!identical(unname(got),unname(want))) stop("Version mismatch: do not change frozen spec")
suppressPackageStartupMessages({library(jsonlite,lib.loc=lib);library(digest,lib.loc=lib)})
sha <- function(p) digest(file=p,algo="sha256");ref<-function(p)list(path=p,sha256=sha(p))
now<-function()format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC")
cmp <- lapply(names(want), function(p) list(package = p, spec = unname(want[p]), restored = if (p %in% names(got)) unname(got[p]) else NA, match = isTRUE(unname(got[p]) == unname(want[p]))))
lp <- system2(rs, c("--vanilla", "-e", shQuote("cat(.libPaths(),sep='|')")), stdout = TRUE)
runs <- list(); outs <- list()
for (b in c("r_a", "r_b")) {
  out <- file.path(W, b); lo <- paste0(out, ".stdout.txt"); le <- paste0(out, ".stderr.txt")
  ex <- system2(rs, vapply(c("--vanilla", file.path("analysis", b, "main.R"), "--input", "data/fixture_8row.csv", "--design", "config/measurement_design.json", "--capacity", "2", "--out", out),shQuote,""), stdout = lo, stderr = le)
  runs[[b]] <- list(exit = ex, stdout = ref(lo), stderr = ref(le))
  for (f in c("selected.csv", "qualified.csv", "ledger.csv", "summary.json")) { o <- file.path("artifacts/stage4", b, f); p <- file.path(out, f)
    outs[[length(outs) + 1L]] <- list(original = ref(o), restored = if (file.exists(p)) ref(p) else NULL, identical = file.exists(p) && identical(sha(o), sha(p))) }
}

con <- file(file.path(W, "console.txt"), "w")
writeLines(c(paste("fresh library:", lib), paste("install exit:", ix, " seconds:", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)), paste("child .libPaths():", paste(lp, collapse = " ")),
  capture.output(print(do.call(rbind, lapply(cmp, as.data.frame)))), paste("builder exits:", runs$r_a$exit, runs$r_b$exit), capture.output(print(do.call(rbind, lapply(outs, function(x) data.frame(file = x$original$path, identical = x$identical)))))), con); close(con)
vers_ok <- all(vapply(cmp, function(x) x$match, TRUE)); outs_ok <- all(vapply(outs, function(x) x$identical, TRUE)) && all(vapply(runs, function(x) identical(x$exit, 0L), TRUE))
paths <- strsplit(paste(lp,collapse="|"),"|",fixed=TRUE)[[1]]
paths <- normalizePath(paths,winslash="/",mustWork=TRUE)
child_fresh <- length(paths)>0 && identical(paths[[1]],lib) && all(paths %in% allowed)
rep <- list(status = if (identical(ix, 0L) && vers_ok && outs_ok && child_fresh) "PASS" else "FAIL", fresh_environment = isTRUE(child_fresh), recorded_at_utc = now(),
  fresh_environment_definition = "new empty package library; every spec package installed explicitly from CRAN binaries in a child process; builders run in new Rscript --vanilla processes whose library path is that library plus the R installation's own library (user library excluded, verified from the child's .libPaths())",
  environment_spec = ref(spec_p), child_libpaths = lp, package_versions = cmp, versions_match_spec = vers_ok, install_exit = ix, runs = runs, outputs = outs, outputs_identical = outs_ok,
  console = ref(file.path(W, "console.txt")), tool = ref("environment/restore_project.R"))
writeLines(toJSON(rep, auto_unbox = TRUE, pretty = TRUE, null = "null"), file.path(W, "restore_report.json")); cat(rep$status, "\n")

quit(status=if(identical(rep$status,"PASS"))0L else 1L)
