-- pen the DB. Not needed if not for manual inspection
-- .open output/dbvar_v1.sqlite 

CREATE TABLE temp_dbvar_tsv(
  "chr" TEXT,
  "roi_start" INT,
  "roi_end" INT,
  "variant_count" INT,
  "variant_type" TEXT,
  "method" TEXT,
  "analysis" TEXT,
  "platform" TEXT,
  "study" TEXT,
  "variant" TEXT,
  "clinical_assertion" TEXT,
  "clinvar_accession" TEXT,
  "bin_size" TEXT,
  "min_insertion_length" INT,
  "max_insertion_length" INT
);

CREATE TABLE dbvar_tsv(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "chr" TEXT,
  "roi_start" INTEGER,
  "roi_end" INTEGER,
  "variant_count" INTEGER,
  "variant_type" TEXT,
  "method" TEXT,
  "analysis" TEXT,
  "platform" TEXT,
  "study" TEXT,
  "variant" TEXT,
  "clinical_assertion" TEXT,
  "clinvar_accession" TEXT,
  "bin_size" TEXT,
  "min_insertion_length" INTEGER,
  "max_insertion_length" INTEGER
);

-- Just exploring the schemas
.schema temp_dbvar_tsv
.schema dbvar_tsv

-- import tsv data into a temporary table
.separator "\t"
.import processing/GRCh38.nr_duplications.tsv temp_dbvar_tsv
.import processing/GRCh38.nr_insertions.tsv temp_dbvar_tsv
.import processing/GRCh38.nr_deletions.tsv temp_dbvar_tsv

-- Insert the data from the temporary table to the final table. As the final table has an AUTOINCREMENT on the primary key, it will automatically generate a unique id for each non-redundant cnv. Can be removed if undesired
INSERT INTO dbvar_tsv(chr, roi_start, roi_end, variant_count, variant_type, method, analysis, platform, study, variant, clinical_assertion, clinvar_accession, bin_size, min_insertion_length, max_insertion_length)
SELECT chr, roi_start, roi_end, variant_count, variant_type, method, analysis, platform, study, variant, clinical_assertion, clinvar_accession, bin_size, min_insertion_length, max_insertion_length FROM temp_dbvar_tsv;

-- Drop temporary tables
DROP TABLE temp_dbvar_tsv;

-- create indexes on chr, start and stop position
CREATE INDEX dbvar_tsv_chr ON dbvar_tsv (chr);
CREATE INDEX dbvar_tsv_start ON dbvar_tsv (roi_start);
CREATE INDEX dbvar_tsv_stop ON dbvar_tsv (roi_end);

-- Manual check
-- select count (*) from dbvar_tsv;
-- select variant_type, count (*) from dbvar_tsv GROUP BY variant_type;
-- select * from dbvar_tsv LIMIT 10;
-- select * from dbvar_tsv WHERE variant_type == "duplication" LIMIT 10;

-- This is to prove that a valid superkey can be formed only considering chr, roi_start, roi_end and variant_type
-- select chr, roi_start, roi_end, count (*) from dbvar_tsv GROUP BY chr, roi_start, roi_end HAVING COUNT(*) > 1;
-- select chr, roi_start, roi_end, variant_type, count (*) from dbvar_tsv GROUP BY chr, roi_start, roi_end, variant_type HAVING COUNT(*) > 1;

