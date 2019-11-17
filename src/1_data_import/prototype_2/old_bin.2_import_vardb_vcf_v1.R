library("data.table")
library(readr)
library(plyr)
library(dplyr)
library(DBI)
library(RSQLite)
library(tidyr)

db = "output/dbvar_v2.sqlite"

# Open a connection (i.e. create or access an existing sqlite file)
conn = dbConnect(drv=SQLite(), dbname=db)



# CHUNK_SIZE = 1000
# src_fname = 'data/raw/GRCh38.2019_11_03.variant_call.vcf.gz'
# src_h = gzfile(src_fname)
src_fname = 'processing/temp_GRCh38.2019_11_03.variant_call.vcf'
src_h = src_fname



############
# Derive header infos
header = read_tsv(src_h, skip=1, comment='', col_names=FALSE, n_max=45)
header %>% data.frame
offset = read_tsv(src_h, skip=34, comment='', col_names=FALSE, n_max=1)
infile_colnames = gsub('#', '', offset %>% data.frame %>% unlist)
names(infile_colnames) = NULL
print(infile_colnames)




split_info <- function(data) {
	INFOs = strsplit(data %>% pull(INFO), ';', fixed=TRUE)
	# Split infos
	INFOs = lapply(INFOs, function(x) {
		if(length(grep('=', x, fixed=TRUE))==0) return(c('no_info' = TRUE))
		x = x[(grep('=', x, fixed=TRUE))]
		x = strsplit(x, '=', fixed=TRUE)
		values = sapply(x, function(x) x[[2]])
		names(values) = sapply(x, function(x) x[[1]])
		return(values)
	})
	return(INFOs)
}

interpret_info <- function(df) {
	# annotate the call with its precision
	df = df %>% mutate(imprecise = grepl('IMPRECISE', INFO, fixed=TRUE))
	df = df %>% mutate(ALT = gsub('<|>', '', ALT))
	# Aggregate the event according to the guidelines
	df$ALT_class = 'other'
	df = df %>% mutate(ALT_class = ifelse(grepl('INV', ALT, fixed=TRUE), 'inversion', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('DUP', ALT, fixed=TRUE), 'duplication', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('CNV', ALT, fixed=TRUE), 'duplication', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('DEL', ALT, fixed=TRUE), 'deletion', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('INS', ALT, fixed=TRUE), 'insertion', ALT_class))
	# process INFOs
	dfi = split_info(df)
	df$INFO = NULL
	# retain useful INFO fields, as described in the header of the vcf file
	# fields_to_retain = c('END', 'CIPOS', 'CIEND', 'SVLEN', 'EXPERIMENT', 'REGIONID', 'CLNSIG', 'clinical_source', 'SOMATIC', 'PHENO', 'ORIGIN', 'CLNACC')
	# dfi = lapply(dfi, function(x) x[intersect(names(x), fields_to_retain)]) # speed up downstream analysis. can be removed if needed to 
	dfi = lapply(dfi, function(x) data.frame(t(x), stringsAsFactors=FALSE))
	dfi2 = plyr::rbind.fill(dfi)

	# merge back INFO and othr fields
	if(nrow(dfi2) != nrow(df)) stop('Error in interpret_info!')
	df = cbind(df, dfi2)
	# convert some fields into INTegers
	# df = df %>% mutate(CHROM = as.character(CHROM)) # should not be necessary
	df = df %>% mutate(POS = as.numeric(POS))
	df = df %>% mutate(END = as.numeric(END))
	df = df %>% mutate(SVLEN = as.numeric(SVLEN))
	df = df %>% mutate(cnv_roi_id = paste(CHROM, POS, END, REGIONID, sep='_'))

	return(df)
}


# ########################################
# # Get sample of data to play with 
# data = read_tsv(src_h, skip=34, comment='#', col_names=infile_colnames, n_max= 1000)
# df = data
# df %>% head()
# # df1 = tidyr::separate_rows(df, variant, sep=";\\s*")
# nrow(df)

# # dfi = split_info(df)
# df1 = interpret_info(df)
# df1 %>% head





#########  #########  #########  #########  #########  #########  #########  

# to_mask = c("REF", "QUAL", "FILTER", "SVTYPE", "EXPERIMENT", "SAMPLE", "SAMPLESET", "AC", "AF", "AN", "LINKS", "DESC", "SEQ")

# df1 = df1 %>% select(-to_mask)
# df1 %>% head




# # df1 %>% count(ALT, SVTYPE) %>% arrange(-n)
# df1 %>% count(ALT_class) %>% arrange(-n)
# nrow(df1)

# df1 %>% count(cnv_roi_id) %>% arrange(-n)

# df1 %>% count(cnv_roi_id) %>% nrow
# df1 %>% count(CHROM, POS, END) %>% nrow
# df1 %>% count(REGIONID) %>% nrow


# df1 %>% count(CHROM, POS, END, ALT, REGIONID) %>% arrange(-n)
# df1 %>% count(CHROM, POS, END, ALT, REGIONID, CIPOS, CIEND) %>% arrange(-n)
# df1 %>% count(ALT, REGIONID) %>% arrange(-n)


# df1 %>% filter(REGIONID == 'esv2757715') %>% count(CHROM, POS, END, ALT, REGIONID) %>% arrange(-n)
# df1 %>% filter(REGIONID == 'esv2757715') %>% count(CHROM, POS, END, ALT, REGIONID, ID) %>% arrange(-n)
# df1 %>% filter(REGIONID == 'esv2757715') %>% count(ID) %>% arrange(-n)
# df1 %>% filter(REGIONID == 'esv2757715') %>% count(CHROM, POS, END, ALT, REGIONID, CIPOS, CIEND) %>% arrange(-n)


# df1 %>% group_by(CHROM, POS, END) %>% summarize(n=length(unique(REGIONID))) %>% arrange(-n)
# df1 %>% group_by(CHROM, POS, END) %>% summarize(n=length(unique(CIEND))) %>% arrange(-n)

# df1 %>% group_by(CHROM, POS, END, REGIONID) %>% summarize(n=length(unique(CIEND))) %>% arrange(-n)

# df1 %>% filter(CHROM=='1' & POS==629054 & END==714367) 

# df1 %>% group_by(CHROM, POS, END) %>% summarize(n=length(unique(ID))) %>% arrange(-n)
# df1 %>% group_by(ID) %>% summarize(n=length(unique(CHROM, POS, END))) %>% arrange(-n)
# df1 %>% group_by(ID) %>% summarize(n=length(unique(REGIONID))) %>% arrange(-n)

# df1 %>% group_by(REGIONID) %>% summarize(n=length(unique(CIEND))) %>% arrange(-n)


# df1 %>% filter(CHROM=='1' & POS==10001 & END==82189) 


# (df1 %>% count(CHROM, POS, END, ALT, REGIONID, SVLEN) %>% arrange(-n) %>% nrow) == (df1 %>% count(CHROM, POS, END, ALT, REGIONID, CIPOS, CIEND, SVLEN) %>% arrange(-n) %>% nrow)

# #########  #########  #########  #########  #########  #########  #########  



# # cnv roi table
# # taking the unique values
# 'cnv_roi_id' <- key
# "CHROM"
# "POS"
# "END"
# "CIPOS"
# "CIEND"
# "SVLEN"

# # cnv call table
# "ID" <- important and unique
# "cnv_roi_id" <- external key
# "ALT_class"
# "imprecise"
# "ALT"
# "CLNSIG"
# "clinical_source"
# "PHENO"
# "ORIGIN"
# "CLNACC"

# # cnv region table
# "cnv_roi_id" <- external key
# "REGIONID" <= primary key


#########  #########  #########  #########  #########  #########  #########  

#INFO=<ID=DBVARID,Number=0,Type=Flag,Description="ID is a dbVar accession">
##INFO=<ID=CIEND,Number=2,Type=Integer,Description="Confidence interval around END for imprecise variants">
##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS for imprecise variants">
##INFO=<ID=DESC,Number=1,Type=String,Description="Any additional information about this call (free text, enclose in double quotes)">
##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant described in this record">
##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description="Imprecise structural variation">
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
##INFO=<ID=SVLEN,Number=.,Type=String,Description="Difference in length between REF and ALT alleles">
##INFO=<ID=CHR2,Number=1,Type=String,Description="Second (To) Chromosome in a translocation pair">
##INFO=<ID=REGIONID,Number=.,Type=String,Description="The parent variant region accession(s)">
##INFO=<ID=EXPERIMENT,Number=1,Type=Integer,Description="The experiment_id (from EXPERIMENTS tab) of the experiment that was used to generate this call">
##INFO=<ID=EVENT,Number=.,Type=String,Description="The parent variant region accession of a mutation event">
##INFO=<ID=LINKS,Number=.,Type=String,Description="Link(s) to external database(s) - see LINKS tab of dbVar submission template for examples">
##INFO=<ID=CLNSIG,Number=1,Type=String,Description="Clinical significance for this single variant">
##INFO=<ID=CLNACC,Number=.,Type=String,Description="Accessions and version numbers assigned by ClinVar">
##INFO=<ID=clinical_source,Number=1,Type=String,Description="Source of clinical significance">
##INFO=<ID=SOMATIC,Number=0,Type=Flag,Description="Indicates that the record is a somatic mutation. NOT for clinical assertions, i.e. cancer. See also ORIGIN.">
##INFO=<ID=ORIGIN,Number=1,Type=String,Description="Origin of allele, if known; should be one of (biparental, de novo, germline, inherited, maternal, not applicable, not provided, not-reported, paternal, tested-inconclusive, uniparental, unknown, see ClinVar for details). See also SOMATIC">
##INFO=<ID=PHENO,Number=.,Type=String,Description="Phenotype(s) thought to associated with this call. NOT for clinical assertions (submit to ClinVar). (free text, enclose in double quotes)">
##INFO=<ID=SAMPLE,Number=1,Type=String,Description="sample_id from dbVar submission; every call must have SAMPLE or SAMPLESET, but NOT BOTH">
##INFO=<ID=SAMPLESET,Number=1,Type=Integer,Description="sampleset_id from dbVar submission; every call must have SAMPLESET or SAMPLE but NOT BOTH">
##INFO=<ID=VALIDATED,Number=0,Type=Flag,Description="Validated by follow-up experiment">
##INFO=<ID=AC,Number=.,Type=Integer,Description="Allele count'">
##INFO=<ID=AF,Number=.,Type=Float,Description="Allele frequency'">
##INFO=<ID=AN,Number=.,Type=String,Description="Allele name'">
##INFO=<ID=SEQ,Number=1,Type=String,Description="Variation sequence">






fields_to_mask = c("DBVARID", "CHR2", "EVENT", "REF", "QUAL", "FILTER", "SVTYPE", "EXPERIMENT", "SAMPLE", "SAMPLESET", "AC", "AF", "AN", "LINKS", "DESC", "SEQ")

fields_to_cnv_roi_table = c("cnv_roi_id", "CHROM", "POS", "END", 'REGIONID')
cnv_roi_table_schema = "
  id TEXT PRIMARY KEY,
  chr TEXT,
  outermost_start INTEGER,
  outermost_stop INTEGER,
  REGIONID TEXT
  "

fields_to_cnv_call_table = c("ID", "cnv_roi_id", "ALT_class", "ALT", "CLNSIG", "clinical_source", "PHENO", "ORIGIN", "CLNACC", "SVLEN", "CIPOS", "CIEND", "imprecise", "VALIDATED", "SOMATIC")
cnv_call_table_schema = "
  id TEXT PRIMARY KEY,
  cnv_roi_id TEXT EXTERNAL KEY,
  variant_type TEXT,
  variant_type_detailed TEXT,
  CLNSIG TEXT,
  clinical_source TEXT,
  PHENO TEXT,
  ORIGIN TEXT,
  CLNACC TEXT,
  SVLEN INTEGER,
  CIPOS TEXT,
  CIEND TEXT,
  imprecise BOOL,
  somatic INTEGER,
  validated BOOL
  "

if(length(intersect(fields_to_mask, c(fields_to_cnv_call_table, fields_to_cnv_roi_table)))>0) stop('Inconsistent field selection.')
schemas = list('dbvar_vcf_cnv_roi' = cnv_roi_table_schema, 'dbvar_vcf_cnv_call' = cnv_call_table_schema)



init_tables <- function(conn, schemas) {
	nil = lapply(names(schemas), function(x) {
		temp_query = paste("CREATE TABLE", x,"(", schemas[[x]], ");")
		if(x %in% dbListTables(conn)) a = DBI::dbSendQuery(conn, paste('DROP TABLE', x))
		a = DBI::dbSendQuery(conn, temp_query)
	})

	# cnv_roi_table_creation_query = paste("CREATE TABLE dbvar_vcf_cnv_roi(", cnv_roi_table_schema, ");")
	# if('dbvar_vcf_cnv_roi' %in% dbListTables(conn)) a = DBI::dbSendQuery(conn, 'DROP TABLE dbvar_vcf_cnv_roi')
	# a = DBI::dbSendQuery(conn, cnv_roi_table_creation_query)

	# cnv_call_table_creation_query = paste("CREATE TABLE dbvar_vcf_cnv_call(", cnv_call_table_schema, ");")
	# if('dbvar_vcf_cnv_call' %in% dbListTables(conn)) a = DBI::dbSendQuery(conn, 'DROP TABLE dbvar_vcf_cnv_call')
	# a = DBI::dbSendQuery(conn, cnv_call_table_creation_query)
}


insert_batch <- function(conn, df1) {

	# take care of mssing columns, if any
	good_fields = unique(c(fields_to_cnv_roi_table, fields_to_cnv_call_table))

	if(length(setdiff(colnames(df1), c(good_fields, fields_to_mask)))>0) {
		warning(paste('Unaccounted for fields:', paste(setdiff(colnames(df1), c(good_fields, fields_to_mask)), collapse = ', ')))
	}
	df1 = df1 %>% select(setdiff(colnames(df1), fields_to_mask))

	if(length(setdiff(good_fields, colnames(df1)))>0) df1[, setdiff(good_fields, colnames(df1))] = NA

	# split input data in tables
	df_roi = df1 %>% select(fields_to_cnv_roi_table)
	df_call = df1 %>% select(fields_to_cnv_call_table)


	###############
	# Insert rois
	# Get unique
	df_roi = df_roi %>% unique()
	# Ignore rois already inserted
	res <- dbGetQuery(conn, 'SELECT id FROM dbvar_vcf_cnv_roi') %>% pull(id)
	df_roi = df_roi %>% filter(! cnv_roi_id %in% res)

	# check that all is fine
	# df_roi %>% count(cnv_roi_id) %>% arrange(-n)
	df_roi <<- df_roi
	if((nrow(df_roi) > 0) & ((df_roi %>% count(cnv_roi_id) %>% arrange(-n) %>% pull(n) %>% max) > 1)) stop('Error.')
	# nrow(df_roi)
	# nrow(df_call)
	# df_call %>% head

	# Insert 
	# print('A')
	dbBegin(conn)
	res <- dbSendQuery(conn, 'INSERT INTO dbvar_vcf_cnv_roi VALUES (:cnv_roi_id, :CHROM, :POS, :END, :REGIONID);', df_roi)
	dbClearResult(res)
	dbCommit(conn)


	###############
	# Insert cnv calls
	# print('B')
	dbBegin(conn)
	res <- dbSendQuery(conn, 'INSERT INTO dbvar_vcf_cnv_call VALUES (:ID, :cnv_roi_id, :ALT_class, :ALT, :CLNSIG, :clinical_source, :PHENO, :ORIGIN, :CLNACC, :SVLEN, :CIPOS, :CIEND, :imprecise, :VALIDATED, :SOMATIC);', df_call)
	dbClearResult(res)
	dbCommit(conn)
}

# df_roi %>% filter(cnv_roi_id == '1_14948229_14953121_esv3585294')


# col_types = rep('c', length(infile_colnames))
########################################
# Get sample of data to play with 
data = read_tsv(src_h, skip=34, comment='#', col_types = cols(.default = "c"), col_names=infile_colnames, n_max= 1000)
df = data
df %>% head()
# df1 = tidyr::separate_rows(df, variant, sep=";\\s*")
nrow(df)

# dfi = split_info(df)
df1 = interpret_info(df)
df1 %>% head

# Init tables
init_tables(conn, schemas)
# check all is fine
# dbListFields(conn, "dbvar_vcf_cnv_roi")
# dbListFields(conn, "dbvar_vcf_cnv_call")


if(length(setdiff(colnames(df1), unique(c(fields_to_mask, fields_to_cnv_roi_table, fields_to_cnv_call_table)))>0)) stop('Unaccounted for fields!')
df1 = df1 %>% select(-fields_to_mask)
df1 %>% head

insert_batch(conn, df1)


# verify
res <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_roi')
dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_roi' )
res %>% head

res1 <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_call')
dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_call' )
res1 %>% head

df_call %>% nrow


#######################################

rebase.chunk = function(df, pos) {
	# df <<- df
	to.append = ifelse(pos > 1, TRUE, FALSE)
	if(!to.append) init_tables(conn, schemas)
	df1 = interpret_info(df)
	print(paste(pos))
	# df1 <<- df1
	insert_batch(conn, df1)
}

# init_tables(conn, schemas)
CHUNK_SIZE = 100000
a = read_tsv_chunked(
  src_h, 
  callback=SideEffectChunkCallback$new(rebase.chunk), 
  chunk_size = CHUNK_SIZE,
  col_types = cols(.default = "c"),
  col_names = infile_colnames,
  comment = '#',
  skip=1,
  progress = TRUE,
)

# Build indexes for fast sarch
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_chr ON dbvar_vcf_cnv_roi (chr);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_start ON dbvar_vcf_cnv_roi (outermost_start);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_stop ON dbvar_vcf_cnv_roi (outermost_stop);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_external_roi_id ON dbvar_vcf_cnv_call (cnv_roi_id);')


# verify
dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_roi' )
res <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_roi LIMIT 100')
res %>% head


dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_call' )
res1 <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_call LIMIT 100')
res1 %>% head

res1 <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_call WHERE variant_type == "other" AND variant_type_detailed != "INV"')

