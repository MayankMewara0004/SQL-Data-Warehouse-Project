/*
====================================================================================
Stored Procedure: Load silver layer(Bronze -> Silver)
====================================================================================
Script Purpose:
    This stored procedure perfoms The ETL(extract, transform, load) process to
    populate the Silver schema tables from the bronze schema.
Actions Performed:
   -Truncate silver tables
   - Inserts transformed and cleansed data from bronze into silver tables.

Usage example:
  exec silver.load_silver
====================================================================================



Create or alter procedure silver.load_silver as
begin

    truncate table silver.crm_cust_info
    Insert Into  silver.crm_cust_info(
     cst_id,
     cst_key,
     cst_firstname,
     cst_lastname,
     cst_material_status,
     cst_gndr,
     cst_create_date)

    select
    cst_id,
    cst_key,
    trim(cst_firstname) as cst_firstname,
    trim(cst_lastname) as cst_lastname,
    case 
        when upper(trim(cst_material_status)) = 'M' then 'Married'
        when upper(trim(cst_material_status)) = 'S' then 'Single'
        else 'n/a' end 
        as cst_material_status,

    case 
       when Upper(trim(cst_gndr)) = 'M' then 'Male'
       when upper(trim(cst_gndr)) = 'F' then 'Female'
       else 'n/a' end 
       as 
    cst_gndr,
    cst_create_date
    from(
    select
    *,
    ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flag_id
    from bronze.crm_cust_info 
    where cst_id is not null)n
    where flag_id = 1 


    truncate table silver.crm_prd_info
    insert into silver.crm_prd_info
    (prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt)
    select
    prd_id,
    replace(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
    SUBSTRING(prd_key,7,len(prd_key)) as prd_key,
    prd_nm,
    isnull(prd_cost,0) as prd_cost,
    case when upper(trim(prd_line)) = 'M' then 'Mountain'
         when upper(trim(prd_line)) = 'R' then 'Road'
         when upper(trim(prd_line)) = 'S' then 'Other Sales'
         when upper(trim(prd_line)) = 'T' then 'Touring'
         else 'n/a'
         end as prd_line,
    cast(prd_start_dt as date) as prd_start_dt,
    cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
    from bronze.crm_prd_info


    truncate table silver.crm_sale_details
    insert into silver.crm_sale_details
    (sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price)
    select 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
         else cast(cast(sls_order_dt as nvarchar) as date) 
         end as sls_order_dt,
    case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
         else cast(cast(sls_ship_dt as nvarchar) as date) 
         end as sls_ship_dt,
    case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
         else cast(cast(sls_due_dt as nvarchar) as date) 
         end as sls_due_dt,
    case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price)
         then sls_quantity * abs(sls_price)
         else sls_sales
         end as sls_sales,
    sls_quantity,
    case when sls_price is null or sls_price <=0 
         then sls_sales/ nullif(sls_quantity,0)
         else sls_price
         end as sls_price
    from bronze.crm_sales_details

    truncate table silver.erp_cust_AZ12
    insert into silver.erp_cust_AZ12
    (CID,
    BDATE,
    GEN)
    select
    case when CID like 'NAS%' then SUBSTRING(CID,4,LEN(CID)) 
    else CID
    end as CID,
    Case when BDATE > GETDATE() then null
    else BDATE 
    end as BDATE,
    Case when GEN = 'F' then 'Female'
         when GEN = 'M' then 'Male'
         When GEN = null then 'n/a'
         when GEN = ' ' then 'n/a'
         else GEN
         end as GEN
    from bronze.erp_cust_AZ12


    truncate table silver.erp_LOC_A101
    insert into silver.erp_LOC_A101
    (CID,
    CNTRY)
    select
    REPLACE(CID,'-','') as	CID,
    case when trim(cntry) = 'DE' then 'Germany'
         when trim(cntry) in ('US', 'USA') then 'United States'
         when trim(cntry) = '' or CNTRY is null then 'n/a'
         else trim(cntry)
    end as CNTRY
    from bronze.erp_LOC_A101

    truncate table silver.erp_PX_CAT_G1V2
    insert into silver.erp_PX_CAT_G1V2
    (ID,
    CAT,
    SUBCAT,
    MAINTENANCE)
    select
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
    from bronze.erp_PX_CAT_G1V2

end

