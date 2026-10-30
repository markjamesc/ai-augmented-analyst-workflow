# Project-independent harness for the locked checkpoint/builder interface.
# Builder outputs always come from actual separate Rscript processes.
wf_output <- function(dir,cp) wf_csv(file.path(dir,cp$file))
wf_score <- function(dir,expected,d) all(vapply(d$checkpoints,function(cp) {
  wf_compare(wf_output(dir,cp),wf_oracle_table(expected[[cp$id]],cp),cp)
},logical(1)))
wf_pair <- function(a,b,d,drop_digest=FALSE) all(vapply(d$checkpoints,function(cp) {
  x<-wf_output(a,cp); y<-wf_output(b,cp)
  if(drop_digest && 'source_digest' %in% names(x)) {x$source_digest<-'input-specific';y$source_digest<-'input-specific'}
  wf_compare(x,y,cp)
},logical(1)))
wf_validate <- function(root,repo,fault_probe=FALSE) {
  m<-wf_manifest(root);wf_assert(!is.null(m$lock),'Owner lock required before Execution')
  wf_assert(wf_refs_ok(root,m$lock$files),'Locked inputs changed; owner-approved successor lock required')
  d<-wf_read(wf_path(root,m$lock$contract$path));attempt<-wf_fresh(file.path(root,'attempts'),'execution')
  rel<-function(p)substring(p,nchar(normalizePath(root,winslash='/'))+2L)
  attempt<-normalizePath(attempt,winslash='/');root<-normalizePath(root,winslash='/')
  oracle<-wf_read(wf_path(root,d$fixtures$oracle))$fixtures
  fm<-wf_read(wf_path(root,d$fixtures$manifest));cfg<-wf_read(file.path(root,'builders.json'))
  checks<-list();commands<-list(); details<-list()
  check<-function(id,fun) {x<-wf_check(id,fun);checks[[length(checks)+1L]]<<-x;invisible(x)}
  paths<-c('builders.json',unlist(lapply(cfg$builders,function(b)c(b$script,unlist(b$input_files),b$declaration))))
  # No expected code hashes in design: code is frozen in this execution attempt.
  input_refs<-wf_snapshot(root,c(paths,d$source$path,d$fixtures$oracle,d$fixtures$manifest,vapply(fm$fixtures,function(f)f$path,character(1))))
  check('source',function() {
    wf_assert(identical(wf_hash(wf_path(root,d$fixtures$oracle)),d$fixtures$oracle_sha256),'Oracle changed')
    wf_assert(identical(wf_hash(wf_path(root,d$fixtures$manifest)),d$fixtures$manifest_sha256),'Fixture manifest changed')
    wf_assert(all(vapply(fm$fixtures,function(f)wf_ref_ok(root,f),logical(1))),'Fixture bytes changed')
    file_ok<-identical(wf_hash(wf_path(root,d$source$path)),d$source$sha256)
    if(d$source$kind=='file') return(file_ok && d$source$sql_applicability=='NOT_APPLICABLE')
    wf_assert(file.exists(wf_path(root,d$source$query_path)),'SQL query not saved')
    cp<-d$source$comparison
    wf_assert(is.list(cp),'SQL source needs keyed raw-field comparison contract')
    file_ok && wf_compare(wf_csv(wf_path(root,d$source$path)),wf_csv(wf_path(root,d$source$reference_path)),cp)
  })
  check('independence',function() {
    wf_assert(setequal(names(cfg$builders),c('R-A','R-B')),'Two builders required')
    all(vapply(names(cfg$builders),function(id) {
      b<-cfg$builders[[id]];a<-wf_read(wf_path(root,b$declaration))
      wf_text(b$service)&&wf_text(b$model)&&wf_text(b$chat_id)&&!grepl('^(RECORD|REPLACE)_',b$model)&&!grepl('^(RECORD|REPLACE)_',b$chat_id)&&
        (m$mode=='offline'||!isTRUE(a$simulated))&&wf_strings(b$input_files)&&length(b$input_files)>0&&
        identical(a$builder,id)&&isTRUE(a$independent)&&identical(a$peer_solution_seen,FALSE)&&wf_text(a$basis)
    },logical(1))) && cfg$builders[['R-A']]$chat_id != cfg$builders[['R-B']]$chat_id
  })
  check('pretest',function() {
    wf_assert(wf_ref_ok(root,cfg$pretest),'Pretest report missing/stale')
    p<-wf_read(wf_path(root,cfg$pretest$path))
    wf_refs_ok(dirname(wf_path(root,cfg$pretest$path)),p$evidence) && identical(p$status,'PASS') && identical(p$identity,wf_identity(repo,d)) &&
      identical(sort(unlist(p$passed_cases)),sort(wf_pretest_case_ids()))
  })
  run<-function(b,input,subdir) {
    out<-file.path(attempt,subdir,b);script<-wf_path(root,cfg$builders[[b]]$script)
    result<-wf_command(script,input,out);commands[[length(commands)+1L]]<<-c(list(builder=b,input_sha256=wf_hash(input),script_sha256=wf_hash(script),output=rel(out)),result)
    wf_assert(result$exit==0L,paste(b,'execution failed; inspect console before assigning analysis fault'))
    wf_assert(all(file.exists(file.path(out,vapply(d$checkpoints,function(cp)cp$file,character(1))))),'Builder omitted outputs')
    out
  }
  check('fixtures',function() {
    if(fault_probe) stop('DELIBERATE OFFLINE TOOL FAULT: injected checker crash')
    wf_assert(setequal(names(oracle),vapply(fm$fixtures,function(f)f$id,character(1))),'Oracle/fixture coverage differs')
    ok<-TRUE
    for(f in fm$fixtures) for(b in c('R-A','R-B')) {
      out<-run(b,wf_path(root,f$path),paste0('fixtures/',f$id))
      good<-wf_score(out,oracle[[f$id]],d);details[[paste(f$id,b)]]<<-list(match=good,output=rel(out));ok<-ok&&good
    };ok
  })
  prod<-list()
  check('reconciliation',function() {
    for(b in c('R-A','R-B')) prod[[b]]<<-run(b,wf_path(root,d$source$path),'production')
    wf_pair(prod[['R-A']],prod[['R-B']],d)
  })
  check('invariance',function() {
    wf_assert(length(prod)==2,'Production outputs unavailable')
    # ACC003 valid input has three unquoted header fields and eight ordinary rows.
    # General projects declare their valid transformations; do not apply this adapter blindly.
    if(!identical(d$invariance$adapter,'acc003-csv')) stop('Supply a reviewed project invariance adapter')
    lines<-readLines(wf_path(root,d$source$path),warn=FALSE)
    transformed<-list(shuffle=c(lines[1],rev(lines[-1])),unused=c(paste0(lines[1],',unrelated_739'),paste0(lines[-1],',ignored')))
    ok<-TRUE
    for(n in names(transformed)) {
      input<-file.path(attempt,paste0(n,'.csv'));writeBin(charToRaw(paste0(paste(transformed[[n]],collapse='\n'),'\n')),input)
      for(b in c('R-A','R-B')) {
        out<-run(b,input,paste0('invariance/',n));same<-wf_pair(prod[[b]],out,d,TRUE)
        # Digest may differ, but it must identify the transformed input, not the old input.
        digest_ok<-all(vapply(d$checkpoints,function(cp) {
          x<-wf_output(out,cp);if('source_digest'%in%names(x))all(x$source_digest==wf_hash(input)) else TRUE
        },logical(1)))
        ok<-ok&&same&&digest_ok
      }
    };ok
  })
  if(isTRUE(d$model$predictions_affect_decision)) check('model',function() {
    wf_assert(!is.null(cfg$model_validation),'Decision model requires actual validation evidence')
    wf_assert(wf_ref_ok(root,cfg$model_validation),'Model validation report missing/stale')
    v<-wf_read(wf_path(root,cfg$model_validation$path))
    # Methodological validity is reviewed in Design/Finish, not inferred from agreement.
    isTRUE(v$independent_fits)&&isTRUE(v$predictions_match)&&wf_text(v$prediction_checkpoint)&&
      v$prediction_checkpoint %in% vapply(d$checkpoints,function(cp)cp$id,character(1))
  })
  if(!wf_refs_ok(root,input_refs)) checks[[1]]<-wf_result('source','TOOL_ERROR','Execution inputs changed during checks; investigate and rerun')
  report<-list(run_id=m$run_id,contract_sha256=m$lock$contract$sha256,checks=checks,commands=commands,fixture_details=details,
    sql_source_gate=if(d$source$kind=='file')'NOT_APPLICABLE' else checks[[1]]$status,
    fault_probe=fault_probe,environment=wf_environment(),scope='Executed checks; not proof of scientific truth or profitable action')
  rp<-file.path(attempt,'validation.json');wf_write(report,rp)
  generated<-list.files(attempt,recursive=TRUE,full.names=TRUE);generated<-generated[!dir.exists(generated)]
  dep<-c(vapply(input_refs,function(r)r$path,character(1)),rel(generated),cfg$pretest$path)
  pre<-tryCatch(wf_read(wf_path(root,cfg$pretest$path)),error=function(e)NULL)
  if(!is.null(pre$evidence)) dep<-c(dep,vapply(pre$evidence,function(x)paste0(dirname(cfg$pretest$path),'/',x$path),character(1)))
  if(d$source$kind=='sql') dep<-c(dep,d$source$query_path,d$source$reference_path)
  if(!is.null(cfg$model_validation))dep<-c(dep,cfg$model_validation$path)
  m$validation<-list(report=wf_ref(root,rel(rp)),files=wf_snapshot(root,dep))
  m$engine<-wf_engine_files(repo);m$environment<-wf_environment();m$finish<-NULL
  wf_save_manifest(m,root)
  report
}
