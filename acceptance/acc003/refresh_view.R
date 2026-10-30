a<-commandArgs(TRUE);if(length(a)!=2)stop('Usage: refresh_view.R REPO PROJECT')
source(file.path(a[1],'methodology/contracts.R'));root<-a[2];d<-wf_read(file.path(root,'design.json'))
e<-wf_design_errors(d,a[1]);wf_assert(!length(e),paste(e,collapse='; '))
v<-d;v$fixtures<-NULL;v$expected_primary<-NULL
wf_write(v,file.path(root,'builder_contract.json'))
writeBin(charToRaw(d$implementation_rules),file.path(root,'builder_spec.md'))
cat('BUILDER_VIEW_REFRESHED from the single contract; oracle/expected results omitted.\n')
