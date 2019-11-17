-- Manual check
select count (*) from dbvar_vcf_cnv_roi;
select count (*) from dbvar_vcf_cnv_call;
select variant_type, count (*) from dbvar_vcf_cnv_call GROUP BY variant_type;
select * from dbvar_vcf_cnv_call LIMIT 10;
select * from dbvar_vcf_cnv_call WHERE variant_type == "duplication" LIMIT 10;

-- This is to prove that a valid superkey can be formed only considering chr, roi_start, roi_end and variant_type
-- select chr, roi_start, roi_end, count (*) from dbvar_vcf_cnv_roi GROUP BY chr, roi_start, roi_end HAVING COUNT(*) > 1;
-- select chr, roi_start, roi_end, variant_type, count (*) from dbvar_vcf_cnv_roi GROUP BY chr, roi_start, roi_end, variant_type HAVING COUNT(*) > 1;


-- DISTINCT
select * FROM dbvar_vcf_cnv_roi, dbvar_vcf_cnv_call
WHERE dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id
AND dbvar_vcf_cnv_roi.chr == 1
AND dbvar_vcf_cnv_roi.roi_start <= 1535692
AND dbvar_vcf_cnv_roi.roi_end >= 10001;


select * FROM dbvar_vcf_cnv_roi, dbvar_vcf_cnv_call
WHERE dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id
AND dbvar_vcf_cnv_roi.chr == 17
AND dbvar_vcf_cnv_roi.roi_start == 7668402
AND dbvar_vcf_cnv_roi.roi_end == 7687550;
