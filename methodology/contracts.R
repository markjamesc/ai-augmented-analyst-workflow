# Lean contracts. Pure comparisons; no AI-send, deadline or formatting gates.
wf_text <- function(x) is.character(x) && length(x)==1L && !is.na(x) && nzchar(trimws(x))
wf_assert <- function(ok, message) if(!isTRUE(ok)) stop(message, call.=FALSE)
wf_read <- function(p) jsonlite::fromJSON(p,simplifyVector=FALSE)
wf_hash <- function(p) digest::digest(file=p,algo='sha256')
wf_write <- function(x,p) {
  dir.create(dirname(p),recursive=TRUE,showWarnings=FALSE)
  jsonlite::write_json(x,p,pretty=TRUE,auto_unbox=TRUE,null='null',digits=NA)
}
wf_rel <- function(p) wf_text(p) && !grepl('^(/|[A-Za-z]:|\\\\)',p) &&
  !any(strsplit(gsub('\\\\','/',p),'/',fixed=TRUE)[[1]] %in% c('','..','.'))
wf_path <- function(root,p) {
  wf_assert(wf_rel(p),paste('Unsafe relative path:',p)); file.path(root,p)
}
wf_ref <- function(root,p) {
  f <- wf_path(root,p); wf_assert(file.exists(f) && !dir.exists(f),paste('Missing file:',p))
  list(path=p,sha256=wf_hash(f))
}
wf_ref_ok <- function(root,r) tryCatch(wf_text(r$sha256) && identical(wf_ref(root,r$path)$sha256,r$sha256),error=function(e)FALSE)
wf_refs_ok <- function(root,refs) length(refs)>0 && all(vapply(refs,function(r)wf_ref_ok(root,r),logical(1)))
wf_rows <- function(x) is.list(x) && (length(x)==0L || is.null(names(x)))
wf_strings <- function(x) (is.character(x)||wf_rows(x)) && all(vapply(as.list(x),wf_text,logical(1)))
# The deliberately small schema vocabulary is validated here, in R (no Python runtime).
wf_schema <- function(x,s,path='$') {
  errors <- character(); add <- function(ok,msg) if(!isTRUE(ok)) errors <<- c(errors,paste(path,msg))
  types <- list(object=is.list(x) && (length(x)==0L || !is.null(names(x))),array=wf_rows(x),
    string=wf_text(x),boolean=is.logical(x)&&length(x)==1L&&!is.na(x),
    number=is.numeric(x)&&length(x)==1L&&is.finite(x),integer=is.numeric(x)&&length(x)==1L&&is.finite(x)&&x==floor(x))
  if(!is.null(s$type)) add(isTRUE(types[[s$type]]),paste('must be',s$type))
  if(!is.null(s$enum)) add(any(vapply(s$enum,function(v)identical(x,v),logical(1))),'invalid enum')
  if(identical(s$type,'object') && is.list(x)) {
    for(k in unlist(s$required)) add(k %in% names(x),paste('missing',k))
    for(k in intersect(names(s$properties),names(x))) errors <- c(errors,wf_schema(x[[k]],s$properties[[k]],paste0(path,'.',k)))
  }
  if(identical(s$type,'array') && wf_rows(x)) {
    if(!is.null(s$minItems)) add(length(x)>=s$minItems,'too few items')
    if(!is.null(s$items)) for(i in seq_along(x)) errors <- c(errors,wf_schema(x[[i]],s$items,paste0(path,'[',i,']')))
  }
  errors
}
wf_design_errors <- function(d,repo) {
  e <- wf_schema(d,wf_read(file.path(repo,'methodology/schema.json')))
  add <- function(ok,msg) if(!isTRUE(ok)) e <<- c(e,msg)
  if(length(e)) return(e)
  add(wf_rel(d$source$path),'source path unsafe')
  add(grepl('^[a-f0-9]{64}$',d$source$sha256),'source hash required')
  add(identical(d$source$sql_applicability,if(d$source$kind=='sql')'REQUIRED' else 'NOT_APPLICABLE'),'SQL applicability contradicts source kind')
  if(d$source$kind=='sql') add(all(vapply(c('query_path','reference_path','snapshot'),function(k)wf_text(d$source[[k]]),logical(1))),'SQL needs query, independent raw reference and snapshot')
  ids <- vapply(d$checkpoints,function(x)x$id,character(1));add(!anyDuplicated(ids),'duplicate checkpoint ID')
  for(cp in d$checkpoints) {
    f <- c(unlist(cp$keys),unlist(cp$exact_fields),unlist(cp$numeric_fields))
    add(length(cp$keys)>0 && !anyDuplicated(f),paste(cp$id,'fields/keys overlap or empty'))
    add(wf_rel(cp$file),paste(cp$id,'unsafe output path'))
    add(identical(cp$absolute_tolerance,0L)||identical(cp$absolute_tolerance,0),paste(cp$id,'ACC003 comparison must be exact'))
    add(identical(cp$relative_tolerance,0L)||identical(cp$relative_tolerance,0),paste(cp$id,'ACC003 comparison must be exact'))
    for(n in names(cp$numeric_missingness)) {
      r <- cp$numeric_missingness[[n]]
      add(n %in% unlist(cp$numeric_fields) && r$flag_field %in% unlist(cp$exact_fields) &&
        wf_strings(r$missing_values) && length(r$missing_values)>0 && wf_text(r$present_value) &&
        !r$present_value %in% unlist(r$missing_values) && r$missing_token %in% c('NA','null',''),paste(cp$id,n,'invalid missingness'))
    }
  }
  for(s in d$safeguards) if(isTRUE(s$applies)) add(wf_text(s$plan),paste('Applicable safeguard needs plan:',s$id))
  add(!anyDuplicated(vapply(d$safeguards,function(s)s$id,character(1))),'duplicate safeguard')
  required <- c('confounding','uncertainty','multiplicity','segments','small_denominator','sensitivity','research_return','monitoring','leakage')
  add(setequal(vapply(d$safeguards,function(s)s$id,character(1)),required),'safeguard applicability incomplete')
  if(isTRUE(d$model$predictions_affect_decision)) {
    leak <- Filter(function(x) x$id=='leakage', d$safeguards)
    add(length(leak)==1 && isTRUE(leak[[1]]$applies), 'Decision model needs applicable leakage safeguard')
    add(isTRUE(d$model$present),'decision model cannot be absent')
    for(k in c('target','features','split','leakage_rule','algorithm','solver','seed','evaluation','prediction_fields','action_mapping')) add(wf_text(d$model[[k]]),paste('Decision model needs',k))
  }
  if(!isTRUE(d$model$present)) add(!isTRUE(d$model$predictions_affect_decision),'absent model affects decision')
  add(wf_rel(d$fixtures$oracle) && wf_rel(d$fixtures$manifest),'fixture references unsafe')
  add(grepl('^[a-f0-9]{64}$',d$fixtures$oracle_sha256) && grepl('^[a-f0-9]{64}$',d$fixtures$manifest_sha256),'fixture hashes required')
  e
}
wf_csv <- function(p) read.csv(p,colClasses='character',check.names=FALSE,na.strings=character(),stringsAsFactors=FALSE)
wf_cell <- function(x) if(is.null(x)) 'null' else if(is.list(x) && !length(x)) '[]' else if(is.list(x)) as.character(jsonlite::toJSON(unlist(x),auto_unbox=FALSE)) else as.character(x)
wf_oracle_table <- function(rows,cp) {
  wf_assert(!is.null(rows),'Missing oracle checkpoint'); f <- c(unlist(cp$keys),unlist(cp$exact_fields),unlist(cp$numeric_fields))
  if(!length(rows)) return(as.data.frame(setNames(rep(list(character()),length(f)),f)))
  cols <- lapply(f,function(n) vapply(rows,function(r){wf_assert(n %in% names(r),paste('Oracle field absent:',n));wf_cell(r[[n]])},character(1)))
  as.data.frame(setNames(cols,f),check.names=FALSE,stringsAsFactors=FALSE)
}
wf_canon <- function(x,cp) {
  f <- c(unlist(cp$keys),unlist(cp$exact_fields),unlist(cp$numeric_fields))
  wf_assert(is.data.frame(x) && !anyDuplicated(names(x)) && setequal(names(x),f),'Checkpoint schema mismatch')
  x <- x[,f,drop=FALSE]
  key <- vapply(seq_len(nrow(x)),function(i) as.character(jsonlite::toJSON(as.list(x[i,unlist(cp$keys),drop=FALSE]),auto_unbox=TRUE)),character(1))
  wf_assert(!anyDuplicated(key),'Duplicate checkpoint key')
  for(n in unlist(cp$numeric_fields)) {
    rule <- cp$numeric_missingness[[n]]; missing <- rep(FALSE,nrow(x))
    if(!is.null(rule)) {
      flags <- x[[rule$flag_field]]
      wf_assert(all(flags %in% c(unlist(rule$missing_values),rule$present_value)),'Unknown missingness flag')
      missing <- flags %in% unlist(rule$missing_values)
      wf_assert(all(x[[n]][missing]==rule$missing_token),'Missing value token differs')
    }
    num <- suppressWarnings(as.numeric(x[[n]][!missing]));wf_assert(all(is.finite(num)),'Invalid/nonfinite numeric')
    x[[n]][!missing] <- sprintf('%.17g',num)
  }
  x <- x[order(key,method='radix'),,drop=FALSE];rownames(x)<-NULL;x
}
wf_compare <- function(a,b,cp) tryCatch(identical(wf_canon(a,cp),wf_canon(b,cp)),error=function(e)FALSE)
wf_result <- function(id,status,detail) list(id=id,status=status,detail=detail)
wf_check <- function(id,fun) tryCatch({x<-fun();wf_assert(is.logical(x)&&length(x)==1L&&!is.na(x),'Checker did not return a boolean');
 wf_result(id,if(x)'PASS' else 'ANALYSIS_DEFECT',if(x)'Comparison satisfied' else 'Observed evidence differs from locked requirement')},error=function(e)wf_result(id,'TOOL_ERROR',conditionMessage(e)))
wf_all_pass <- function(checks) length(checks)>0 && all(vapply(checks,function(x)identical(x$status,'PASS'),logical(1)))

wf_finish_content_hash <- function(f) digest::digest(jsonlite::toJSON(f[c('answer','limitations','claims','exploratory_changes_decision','safeguard_disposition')],auto_unbox=TRUE,null='null',digits=NA),algo='sha256',serialize=FALSE)
