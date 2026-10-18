source('methodology/contracts.R')
checks<-logical(); ck<-function(name,value){ok<-isTRUE(value);checks<<-c(checks,ok);cat(if(ok)'PASS'else'FAIL',name,'\n')}
p<-list(keys=list('id'),exact_fields=list('amount_status'),numeric_fields=list('amount_value'),absolute_tolerance=0,relative_tolerance=0,numeric_missingness=list(amount_value=list(flag_field='amount_status',missing_values=list('blank','nonnumeric','nonfinite'),present_value='finite',missing_token='')))
a<-read.csv('examples/acceptance-successor/r_a_ledger.csv',colClasses='character',na.strings=character())
b<-read.csv('examples/acceptance-successor/r_b_ledger.csv',colClasses='character',na.strings=character())
ck('received ledgers agree',m_compare(a,b,p))
for(st in c('blank','nonnumeric','nonfinite')){a$amount_status[7]<-st;b$amount_status[7]<-st;ck(paste('missing status',st),m_compare(a,b,p))}
b$amount_status[7]<-'blank';ck('different missing reasons rejected',!m_compare(a,b,p))
b<-a;b$amount_value[7]<-'0';ck('missing versus zero rejected',!m_compare(a,b,p))
for(token in c('garbage','Inf','NaN','NA','null')){b<-a;b$amount_value[7]<-token;ck(paste('wrong token',token),!m_compare(a,b,p))}
b<-a;b$amount_status[7]<-'unknown';ck('unknown enum rejected',!m_compare(b,b,p))
r<-p$numeric_missingness$amount_value;r$missing_values<-list('blank','finite');ck('overlapping status rejected',!m_missing_rule(r,p))
r$missing_values<-list('blank','blank');ck('duplicate status rejected',!m_missing_rule(r,p))
r<-p$numeric_missingness$amount_value;r$missing_value<-'blank';ck('ambiguous singular/plural rejected',!m_missing_rule(r,p))
# Evaluate only pure parsing definitions from the adapted project harness (not its run).
e<-new.env(); expr<-parse('examples/acceptance-successor/acceptance_harness.R')
for(x in expr)if(is.call(x)&&identical(x[[1]],as.name('<-'))&&is.symbol(x[[2]])&&as.character(x[[2]]) %in% c('NULLTOK','num'))eval(x,e)
ck('declared null tokens retained',all(is.na(e$num(c('','NA','null')))))
for(token in c('garbage','Inf','NaN','-Inf'))ck(paste('harness refuses',token),inherits(try(e$num(token),silent=TRUE),'try-error'))
ck('finite values retained',identical(e$num(c('0','10','11')),c(0,10,11)))
invisible(parse('examples/acceptance-successor/restore_project.R'))
cat(sum(checks),'/',length(checks),'passed\n');stopifnot(all(checks))
