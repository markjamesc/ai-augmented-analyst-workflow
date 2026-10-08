# Synthetic diagnostic only. No production gate changes; never use as real evidence.
source("procedure-gate/tests/test_procedure_gate.R")

# Extract and execute the actual setup block from the master prompt.
lines <- readLines("docs/MASTER_PROMPT.md")
first <- which(lines == "```r")[[1]]
last <- which(seq_along(lines) > first & lines == "```")[[1]]
setup <- paste(lines[seq.int(first + 1L, last - 1L)], collapse = "\n")
root <- file.path(tempdir(), "synthetic project with spaces")
dir.create(root)
setup <- gsub("{{PROJECT_NAME}}", "Synthetic diagnostic", setup, fixed = TRUE)
setup <- gsub("{{RUN_ID}}", "SIMULATION-001", setup, fixed = TRUE)
setup <- gsub("{{WORKFLOW_REPOSITORY_PATH}}", getwd(), setup, fixed = TRUE)
setup <- gsub("{{PROJECT_ROOT_PATH}}", root, setup, fixed = TRUE)
eval(parse(text = setup))

observed <- function(label, expression) {
  outcome <- tryCatch({ force(expression); "ACCEPTED" }, error = function(e) "BLOCKED")
  cat("\nSIMULATION |", label, "|", outcome, "\n")
  outcome
}

run_procedure_gate("start", run_id)
stopifnot(observed("Skip to Design", run_procedure_gate("begin", "design")) == "BLOCKED")
stopifnot(observed("Finalize incomplete run", run_procedure_gate("finalize")) == "BLOCKED")
write_stage1(root)
stopifnot(observed("Complete without begin", run_procedure_gate("complete", "start")) == "BLOCKED")
run_procedure_gate("begin", "start")
receipt_file <- file.path(root, "artifacts", "stage1_decision.json")
writeLines("not JSON", receipt_file)
stopifnot(observed("Malformed receipt", run_procedure_gate("complete", "start")) == "BLOCKED")
write_stage1(root)
run_procedure_gate("complete", "start")
run_procedure_gate("begin", "framing")
write_stage2(root)
run_procedure_gate("complete", "framing")
run_procedure_gate("begin", "design")
write_stage3(root)
run_procedure_gate("complete", "design")
run_procedure_gate("begin", "execution")
write_stage4(root)
evidence_file <- file.path(root, "evidence-v2", "source.json")
original_evidence <- readLines(evidence_file)
writeLines("changed evidence", evidence_file)
stopifnot(observed("Alter evidence before Execution release", run_procedure_gate("complete", "execution")) == "BLOCKED")
writeLines(original_evidence, evidence_file)
run_procedure_gate("complete", "execution")
run_procedure_gate("begin", "finish")
write_stage5(root)
run_procedure_gate("complete", "finish")
stopifnot(observed("Valid five-stage run via master-prompt helper", run_procedure_gate("finalize")) == "ACCEPTED")

# Probes expose coverage gaps rather than declaring them successful controls.
writeLines("changed evidence after release", evidence_file)
observed("Re-finalize after supporting evidence changed", run_procedure_gate("finalize"))
writeLines(original_evidence, evidence_file)

cat("\nSIMULATION | Stage 5 named deliverables actually exist |",
    all(file.exists(file.path(root, c("stage5-evidence.md", "stage5-decision.md", "monitoring-plan.md")))), "\n")
cat("SIMULATION | Actual independent AI reviews or human approval obtained | FALSE (synthetic receipt claims only)\n")

# Existing certificate behavior when a completed receipt changes.
writeLines("changed completed receipt", receipt_file)
stopifnot(observed("Re-finalize after completed receipt changed", run_procedure_gate("finalize")) == "BLOCKED")
old_certificate <- jsonlite::read_json(file.path(root, "artifacts", "final_certificate.json"))
cat("SIMULATION | Prior certificate still says PASS after failed recheck |",
    identical(old_certificate$result, "PASS"), "\n")
cat("SIMULATION | Diagnostic finished; no real analysis or AI calls performed\n")
