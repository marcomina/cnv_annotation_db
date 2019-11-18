source('src/2_cnv_query/lib.0_query_functions_v2.R')
options(width=300)
# Open a connection (i.e. create or access an existing sqlite file)
db = "output/dbvar_v2.sqlite"
conn = dbConnect(drv=SQLite(), dbname=db)


# Example of exact match
chr = '1'; start = 10001; stop = 1535693
gen_matching_query(chr, start, stop, strategy = 'exact')
cnv_match(conn, chr, start, stop, strategy = 'exact')

# Example of non exact match
chr = '1'; start = 10001; stop = 1535692
gen_matching_query(chr, start, stop, strategy = 'partial')
pp = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 10, max_dist = NULL)
pp %>% head(20)

print('')
print('')
print('=============================================================================')
print('')
print('NRAS Example')
# Example relevant to oncology
# NRAS, overactivation of MAPK/MEK pathway
chr = '1'; start = 114704464; stop = 114716894
print("chr = '1'; start = 114704464; stop = 114716894")
print('')
pp = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 100, max_dist = 10000)
pp %>% head(5)

print('')
print('')
print('=============================================================================')
print('')
print('KIF1B Example')
# Example relevant to oncology
# KIF1B, predisposition factor to Neuroblastoma
chr = '1'; start = 10210569; stop = 10381602
print("chr = '1'; start = 10210569; stop = 10381602")
print('')
res = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 100, max_dist = 100000)
res %>% head(5)

print('')
print('')
print('=============================================================================')
print('')
print('TP53 Example')
# Example relevant to oncology
# TP53 loss
# TP53, shutdown of p53 pathway
chr = '17'; start = 7668402; stop = 7687550
print("chr = '17'; start = 7668402; stop = 7687550")
print('')
res = cnv_match(conn, chr, start, stop, strategy = 'partial', top = NULL, max_dist = NULL)
dim(res)
res %>% head(20)
write.table(res, file='example_TP53_cnvs.tsv', sep="\t", quote=FALSE, row.names=FALSE, col.names = TRUE)


dbDisconnect(conn)
