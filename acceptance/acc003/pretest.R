wf_pretest_case_ids <- function() c('empty_array','good','row_shuffle','wrong_sum','wrong_id','NA_as_zero','wrong_rank','duplicate_key',
 'missing_column','adjacent_double','constant_PASS_rejected','missing_report','tool_fault_classified','sql_good','sql_wrong_same_count','sql_wrong_rejected','sql_readonly')
wf_pretest <- function(repo,d,directory) {
  wf_assert(!dir.exists(directory),'Pretest directory exists; use a new attempt');dir.create(directory,recursive=TRUE)
  cp<-list(keys=list('id'),exact_fields=list('state'),numeric_fields=list('amount','rank'),
    numeric_missingness=list(amount=list(flag_field='state',missing_values=list('MISSING'),present_value='PRESENT',missing_token='NA')))
  x<-data.frame(id=c('A','B'),state=c('PRESENT','MISSING'),amount=c('10','NA'),rank=c('1','2'),stringsAsFactors=FALSE)
  bad<-list();bad$wrong_sum<-x;bad$wrong_sum$amount[1]<-'11';bad$wrong_id<-x;bad$wrong_id$id[1]<-'Z'
  bad$NA_as_zero<-x;bad$NA_as_zero$amount[2]<-'0';bad$wrong_rank<-x;bad$wrong_rank$rank[1]<-'2'
  bad$duplicate_key<-x;bad$duplicate_key$id[2]<-'A';bad$missing_column<-x;bad$missing_column$rank<-NULL
  bad$adjacent_double<-x;bad$adjacent_double$amount[1]<-'10.000000000000002'
  discriminate<-function(compare) compare(x,x,cp)&&compare(x,x[2:1,],cp)&&all(vapply(bad,function(b)!compare(x,b,cp),logical(1)))
  outcomes<-c(empty_array=identical(wf_cell(list()),'[]'),good=wf_compare(x,x,cp),row_shuffle=wf_compare(x,x[2:1,],cp),
    setNames(vapply(bad,function(b)!wf_compare(x,b,cp),logical(1)),names(bad)),
    constant_PASS_rejected=!discriminate(function(...)TRUE),
    missing_report=!wf_ref_ok(directory,list(path='absent.json',sha256=paste(rep('0',64),collapse=''))),
    tool_fault_classified=identical(wf_check('crash',function()stop('injected'))$status,'TOOL_ERROR'))
  sql<-wf_sql_pretest(directory)
  outcomes<-c(outcomes,sql_good=sql$good_pass,sql_wrong_same_count=sql$wrong_same_count,sql_wrong_rejected=sql$wrong_rejected,sql_readonly=sql$database_unchanged)
  # Save the actual good and bad inputs used, rather than only PASS strings.
  wf_write(list(checkpoint=cp,good=x,bad=bad),file.path(directory,'pretest-cases.json'))
  files<-list.files(directory,full.names=FALSE)
  evidence<-lapply(files,function(p)wf_ref(directory,p))
  report<-list(evidence=evidence,status=if(all(outcomes))'PASS' else 'TOOL_ERROR',identity=wf_identity(repo,d),
    passed_cases=as.list(names(outcomes)[outcomes]),cases=as.list(outcomes),
    note='Checker discrimination pretest. Builder shuffle/unused-column invariance runs on each new builder.')
  wf_write(report,file.path(directory,'pretest.json'));report
}
