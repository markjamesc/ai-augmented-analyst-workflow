# Explicit owner-authorized exception: disposable synthetic SQLite database only.
# Setup writes once, closes it, then reopens READ ONLY. No live connection parameters.
wf_sql_pretest <- function(directory) {
  wf_assert(requireNamespace('DBI',quietly=TRUE)&&requireNamespace('RSQLite',quietly=TRUE),'Install DBI and RSQLite for synthetic SQL pretest')
  db<-file.path(directory,'synthetic-practice.sqlite');wf_assert(!file.exists(db),'Never reuse/overwrite a database')
  con<-DBI::dbConnect(RSQLite::SQLite(),db)
  expected<-data.frame(id=c('A','B','C','D'),category=c('x','x','y','y'),amount=c('1','2','3','4'),stringsAsFactors=FALSE)
  tryCatch(DBI::dbWriteTable(con,'practice',expected),finally=DBI::dbDisconnect(con))
  before<-wf_hash(db)
  con<-DBI::dbConnect(RSQLite::SQLite(),db,flags=RSQLite::SQLITE_RO)
  on.exit(DBI::dbDisconnect(con),add=TRUE)
  good<-'SELECT id, category, amount FROM practice ORDER BY id'
  bad<-"SELECT id, category, amount FROM practice WHERE category='x' UNION ALL SELECT id, category, amount FROM practice WHERE category='x'"
  writeLines(good,file.path(directory,'good.sql'));writeLines(bad,file.path(directory,'wrong.sql'))
  a<-DBI::dbGetQuery(con,good);b<-DBI::dbGetQuery(con,bad)
  cp<-list(keys=list('id'),exact_fields=list('category'),numeric_fields=list('amount'),numeric_missingness=list())
  result<-list(good_pass=wf_compare(a,expected,cp),wrong_same_count=nrow(b)==nrow(expected),wrong_rejected=!wf_compare(b,expected,cp),database_unchanged=identical(before,wf_hash(db)))
  wf_write(result,file.path(directory,'sql-pretest.json'));result
}
