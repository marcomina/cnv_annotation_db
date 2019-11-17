-- Manual check
select count (*) from dbvar_vcf_cnv_roi;
select count (*) from dbvar_vcf_cnv_call;
select variant_type, count (*) from dbvar_vcf_cnv_call GROUP BY variant_type;
select * from dbvar_vcf_cnv_call LIMIT 10;
select * from dbvar_vcf_cnv_call WHERE variant_type == "duplication" LIMIT 10;

-- This is to prove that a valid superkey can be formed only considering chr, roi_start, roi_end and variant_type
-- select chr, roi_start, roi_end, count (*) from dbvar_vcf_cnv_roi GROUP BY chr, roi_start, roi_end HAVING COUNT(*) > 1;
-- select chr, roi_start, roi_end, variant_type, count (*) from dbvar_vcf_cnv_roi GROUP BY chr, roi_start, roi_end, variant_type HAVING COUNT(*) > 1;


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

-- Check that REGIONID alone is not enough to define a roi, as multiple rois map to the same REGIONID an vice versa
select REGIONID, count (*) from dbvar_vcf_cnv_roi GROUP BY REGIONID HAVING COUNT(*) > 1;
select * from dbvar_vcf_cnv_roi WHERE REGIONID == "nsv9912";


-- Check what happens for TP53 case
select * FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id WHERE dbvar_vcf_cnv_roi.chr == "17" AND dbvar_vcf_cnv_roi.roi_start <= 7687550 AND dbvar_vcf_cnv_roi.roi_end >= 7668402;
select REGIONID, count (*) FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id WHERE dbvar_vcf_cnv_roi.chr == "17" AND dbvar_vcf_cnv_roi.roi_start <= 7687550 AND dbvar_vcf_cnv_roi.roi_end >= 7668402 GROUP BY REGIONID HAVING COUNT(*) > 1;

select * FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id WHERE dbvar_vcf_cnv_roi.chr == "17" AND dbvar_vcf_cnv_roi.roi_start <= 7687550 AND dbvar_vcf_cnv_roi.roi_end >= 7668402 AND REGIONID == "nsv1185025";
select dbvar_vcf_cnv_call.id, count (*) FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id WHERE dbvar_vcf_cnv_roi.chr == "17" AND dbvar_vcf_cnv_roi.roi_start <= 7687550 AND dbvar_vcf_cnv_roi.roi_end >= 7668402 AND REGIONID == "nsv1185025"  GROUP BY dbvar_vcf_cnv_call.id HAVING COUNT(*) > 1;
select dbvar_vcf_cnv_call.id, count (*) FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id WHERE dbvar_vcf_cnv_roi.chr == "17" AND dbvar_vcf_cnv_roi.roi_start <= 7687550 AND dbvar_vcf_cnv_roi.roi_end >= 7668402  GROUP BY dbvar_vcf_cnv_call.id HAVING COUNT(*) > 1;

-- Is cnv call unique? yes it is! good :)
select dbvar_vcf_cnv_call.id, count (*) FROM dbvar_vcf_cnv_roi LEFT JOIN dbvar_vcf_cnv_call ON dbvar_vcf_cnv_roi.id = dbvar_vcf_cnv_call.cnv_roi_id  GROUP BY dbvar_vcf_cnv_call.id HAVING COUNT(*) > 1;
