a<-commandArgs(TRUE)
if(as.character(getRversion())!='4.6.1')stop('Release preflight requires R 4.6.1; other-version test results are compatibility evidence only.')
p<-c('jsonlite','digest','DBI','RSQLite');missing<-p[!vapply(p,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)&&'--install'%in%a)install.packages(missing,repos='https://cloud.r-project.org')
stopifnot(all(vapply(p,requireNamespace,logical(1),quietly=TRUE)))
print(sessionInfo());cat('PREFLIGHT_PASS\n')
