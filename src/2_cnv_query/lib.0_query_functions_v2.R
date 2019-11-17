library(plyr)
library(dplyr)
library(DBI)
library(RSQLite)
# library(tidyr)

gen_exact_matching_query <- function(chr, start, stop) {
	# only retrieves cnvs overlapping exactly with the query range
	# query = paste(
	# 	'select * FROM', dbvar_main_roi_table, ',', dbvar_main_call_table,
	# 	'WHERE',
	# 	paste0(dbvar_main_roi_table, '.id'), '=', paste0(dbvar_main_call_table, '.cnv_roi_id'),
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.chr =='), paste0('"',chr,'"'),
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.roi_start =='), start,
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.roi_end >='), stop
	# 	)
	query = paste(
		'select * FROM', 
		dbvar_main_roi_table, 'LEFT JOIN', dbvar_main_call_table,
		'ON',
		paste0(dbvar_main_roi_table, '.id'), '=', paste0(dbvar_main_call_table, '.cnv_roi_id'),
		'WHERE',
		paste0(dbvar_main_roi_table, '.chr =='), paste0('"',chr,'"'),
		'AND',
		paste0(dbvar_main_roi_table, '.roi_start =='), start,
		'AND',
		paste0(dbvar_main_roi_table, '.roi_end >='), stop
		)

	return(query)
}

gen_overlapping_matching_query <- function(chr, start, stop) {
	# only retrieves cnvs overlapping partially with the query range

	# version 1. No join
	# query = paste(
	# 	'select * FROM', dbvar_main_roi_table, ',', dbvar_main_call_table,
	# 	'WHERE',
	# 	paste0(dbvar_main_roi_table, '.id'), '=', paste0(dbvar_main_call_table, '.cnv_roi_id'),
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.chr =='), paste0('"',chr,'"'),
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.roi_start <='), stop,
	# 	'AND',
	# 	paste0(dbvar_main_roi_table, '.roi_end >='), start
	# 	)

	# version 2. Use LEFT JOIN
	query = paste(
		'select * FROM', 
		dbvar_main_roi_table, 'LEFT JOIN', dbvar_main_call_table,
		'ON',
		paste0(dbvar_main_roi_table, '.id'), '=', paste0(dbvar_main_call_table, '.cnv_roi_id'),
		'WHERE',
		paste0(dbvar_main_roi_table, '.chr =='), paste0('"',chr,'"'),
		'AND',
		paste0(dbvar_main_roi_table, '.roi_start <='), stop,
		'AND',
		paste0(dbvar_main_roi_table, '.roi_end >='), start
		)
	return(query)
}

gen_matching_query <- function(chr, start, stop, strategy = 'exact') {
	query = switch(strategy,
		'exact' = gen_exact_matching_query(chr, start, stop),
		'partial' = gen_overlapping_matching_query(chr, start, stop),
		error(paste(strategy, 'not implemented yet.'))
	)
	return(query)
}

cnv_match <- function(conn, chr, start, stop, strategy = 'partial', max_dist = NULL, top=NULL) {
	query = gen_matching_query(chr, start, stop, strategy = strategy)
	pp = dbGetQuery(conn, query)
	# res <- dbSendQuery(conn, query)
	# pp = dbFetch(res)
	# batch process
	# while(!dbHasCompleted(res)){
	#   chunk <- dbFetch(res, n = 5)
	#   print(nrow(chunk))
	# }
	#  clear results
	# dbClearResult(res)

	pp$cnv_roi_id = NULL
	# Sort and filter by matching criteria
	pp = pp %>% mutate(mismatch = abs(start - roi_start) + abs(stop - roi_end))
	pp = pp %>% arrange(mismatch)
	if(!is.null(max_dist)) pp = pp %>% filter(mismatch <= max_dist)
	if(!is.null(top)) pp = pp %>% head(top)
	return(pp)
}

dbvar_main_roi_table = 'dbvar_vcf_cnv_roi'
dbvar_main_call_table = 'dbvar_vcf_cnv_call'
db = "output/dbvar_v2.sqlite"
