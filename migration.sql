migration
User

INSERT INTO ab_admin ( adminID, name, user_name, email, role, created_date, created_by, lastLogin, mobile_number ) SELECT adminID, name, userName, email, '1', created_date, created_by, lastLogin, contactNo FROM iverifycarbon_live.ab_admin;

SET SESSION sql_mode = '';
update ab_training_point set modified_date = null  where modified_date = '0000-00-00 00:00:00';


INSERT INTO training_sites(training_point_id,m_training_point_id,training_site,road_access,`village_head_name`,`gvh_name`,`total_people`,`house_holds_count`,`cookstoves_count`,`house_hold_radius`, `latitude`, `longitude`,`server_time`,`created_by`,`modified_by`,`created_date`, `modified_date`, `number_of_people_present`)SELECT training_point_id,m_training_point_id,training_site,road_access,village_head_contact_no,gvh_name,total_people,house_holds_count,cookstoves_count,house_hold_radius,latitude,longitude,CURRENT_TIMESTAMP,created_by,modified_by,created_date,modified_date,no_people from iverifycarbon_live.ab_training_point where created_by NOT IN(3,55);

SELECT 
	atp.training_point_id,
    atp.district,
    iv2.district_name,
    iv2.district_id
FROM ab_training_point AS atp
JOIN iverifycarbon_live_v_2.ab_district AS iv2
    ON iv2.district_name COLLATE utf8mb4_general_ci = atp.district
WHERE atp.district IS NOT NULL

training_sites

SELECT atp.training_point_id, atp.district, iv2.district_name, iv2.district_id FROM  iverifycarbon_live
.ab_training_point AS atp JOIN iverifycarbon_live_v_2.ab_district AS iv2 ON iv2.district_name COLLATE utf8mb4_general_ci = atp.district WHERE atp.district IS NOT NULL;


UPDATE iverifycarbon_live.ab_training_point AS atp JOIN iverifycarbon_live_v_2.ab_district AS d ON d.district_name COLLATE utf8mb4_general_ci = atp.district SET atp.district = d.district_id WHERE atp.district IS NOT NULL;

UPDATE iverifycarbon_live_v_2.training_sites AS ts
JOIN iverifycarbon_live.ab_training_point AS atp
    ON ts.training_point_id = atp.training_point_id
JOIN iverifycarbon_live_v_2.ab_district AS d
    ON d.district_name COLLATE utf8mb4_general_ci = atp.district
SET ts.district = d.district_id
WHERE atp.district IS NOT NULL;

UPDATE iverifycarbon_live_v_2.training_sites AS ts
JOIN iverifycarbon_live.ab_training_point AS atp
    ON ts.training_point_id = atp.training_point_id
JOIN iverifycarbon_live_v_2.ab_traditional_authority AS ta
    ON ta.authority_name COLLATE utf8mb4_general_ci = atp.traditional_authority
SET ts.traditional_authority = ta.authority_id
WHERE atp.traditional_authority IS NOT NULL;

SELECT * FROM `training_sites` where traditional_authority IS NOT NULL and district IS NULL;

## ALTER TABLE `beneficiaries` CHANGE `training_site` `training_site_id` INT NULL; 

UPDATE `training_sites` as ts set ts.district = (select district_id from ab_traditional_authority where authority_id = ts.traditional_authority) where traditional_authority IS NOT NULL and district IS NULL;

update ab_user_registration set latitude= null and longitude = null
WHERE latitude NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR longitude NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

update ab_user_registration set latitude= null
WHERE latitude NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';
update ab_user_registration set longitude= null
WHERE longitude NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

SELECT * FROM `ab_user_registration` WHERE district_name='O';

UPDATE `ab_user_registration` set district_name = 0 WHERE district_name='O';

SET SESSION sql_mode = '';
update `ab_user_registration` set signature_timestamp = NULL where signature_timestamp="0000-00-00 00:00:00";
update `ab_user_registration` set signature_timestamp=created_date where signature_timestamp IS NULL; 

SELECT * FROM `ab_user_registration` WHERE `national_id_attachment` ='';
update `ab_user_registration` set `national_id_attachment` = NULL WHERE `national_id_attachment` =''; 

SET SESSION sql_mode = '';
update `ab_user_registration` set national_id_timestamp = NULL where national_id_timestamp="0000-00-00 00:00:00" and national_id_attachment IS NOT NULL;

SELECT * FROM ab_user_registration WHERE district_name NOT REGEXP '^[0-9]+$';
update `ab_user_registration` set district_name = 0 WHERE district_name NOT REGEXP '^[0-9]+$';


SET SESSION sql_mode = '';
update ab_user_registration set modified_date = null  where modified_date = '0000-00-00 00:00:00';

SET SESSION sql_mode = '';
update ab_user_registration set cookstove_pic_timestamp = null  where cookstove_pic_timestamp = '0000-00-00 00:00:00';

SET SESSION sql_mode = '';
update ab_user_registration set house_pic_timestamp = null  where house_pic_timestamp = '0000-00-00 00:00:00';

SET SESSION sql_mode = '';
update ab_user_registration set national_id_timestamp = null  where national_id_timestamp = '0000-00-00 00:00:00';



INSERT INTO `beneficiaries`(`beneficiary_id`, `training_site_id`, `m_user_id`, `first_name`, `last_name`, `mobile_no`, `other_cookstove`, `females_below_18`, `females_above_18`, `males_below_18`, `males_above_18`, `cooking_method`, `national_id`, `national_id_attachment`, `house_pic`, `cookstove_pic`, `signature`, `language`, `read_doc`, `understood_doc`, `emp_sign`, `read_to_you`, `stove_status_delivery`, `no_other_cook_stove_present`, `primary_residence_confirmation`, `cookstove_pic_timestamp`, `house_pic_timestamp`, `national_id_timestamp`, `signature_timestamp`, `device_serial_no`, `latitude`, `longitude`, `geo_address`, `created_date`, `created_by`, `modified_date`, `modified_by`, `status`, `server_time`, `distribution_date`)SELECT user_id,site_id,m_user_id,name,surname,mobile_no,other_cookstove,children_count,adult_count,males_infant,district_name,cooking_method,TRIM(national_id),national_id_attachment,house_pic,cookstove_pic,signature,`language`,read_doc,understood_doc,emp_sign,read_to_you,stove_status_delivery,no_other_cook_stove_present,primary_residence_confirmation,cookstove_pic_timestamp,house_pic_timestamp,national_id_timestamp,signature_timestamp,device_serial_no,latitude,longitude,geo_address,created_date,created_by,modified_date,modified_by,`status`,CURRENT_TIMESTAMP,house_pic_timestamp from iverifycarbon_live.ab_user_registration;

UPDATE beneficiaries SET national_id_attachment = CONCAT( '/uploads/beneficiary/', beneficiary_id, '/', national_id_attachment ) WHERE national_id_attachment NOT LIKE '/uploads/beneficiary/%';

UPDATE beneficiaries SET house_pic = CONCAT( '/uploads/beneficiary/', beneficiary_id, '/', house_pic ) WHERE house_pic NOT LIKE '/uploads/beneficiary/%';

UPDATE beneficiaries SET cookstove_pic = CONCAT( '/uploads/beneficiary/', beneficiary_id, '/', cookstove_pic ) WHERE cookstove_pic NOT LIKE '/uploads/beneficiary/%';


UPDATE beneficiaries SET signature = CONCAT( '/uploads/beneficiary/', beneficiary_id, '/', signature ) WHERE signature NOT LIKE '/uploads/beneficiary/%';

UPDATE `beneficiaries` set cooking_method='Three Stone Fire' where cooking_method='Three Stone Fir';