--can define the total days you want for dim_date table
create or replace temporary table STAGE.dim_date_temp(days int) as
select datediff('day', '1990-01-01', '2100-01-01');


INSERT INTO
DW.DIM_DATE
(   
     "DATE_DIM_KEY" 
    ,"DATE" 
    ,"CALENDAR_DATE" 
    ,"YEAR" 
    ,"QUARTER" 
    ,"MONTH" 
    ,"DAY_OF_THE_MONTH" 
    ,"DAY_NAME" 
    ,"DAY_SUFFIX" 
    ,"DAY_OF_THE_WEEK" 
    ,"DAY_OF_QUARTER" 
    ,"DAY_OF_YEAR" 
    ,"WEEK_OF_YEAR" 
    ,"MONTH_NAME" 
    ,"MONTH-YEAR"
    ,"QUARTER_NAME" 
    ,"YEAR/QUARTER" 
    ,"MMYYYY" 
    ,"FIRST_DAY_OF_MONTH" 
    ,"LAST_DAY_OF_MONTH" 
    ,"FIRST_DAY_OF_QUARTER"
    ,"LAST_DAY_OF_QUARTER" 
    ,"FIRST_DAY_OF_YEAR" 
    ,"LAST_DAY_OF_YEAR" 
    ,"META_NK_COLUMN_HASH"
    ,"META_IS_CURRENT"
    ,"META_CREATED_DATE"
    ,"META_UPDATED_DATE" 
    ,"META_EFFECTIVE_FROM"
    ,"META_EFFECTIVE_TO"
    ,"META_JOB_ID"
)
WITH 
CTE AS (
    --define your first date
    SELECT DATEADD(DAY, SEQ8(), '1990-01-01') AS "DATE"
      FROM TABLE(GENERATOR(ROWCOUNT=>select max(days)from STAGE.dim_date_temp))  -- Number of days after reference date in dim_date_temp.sql
  )
  SELECT CAST(TO_CHAR("DATE", 'YYYYMMDD') AS NUMBER) AS DATE_DIM_KEY
        ,"DATE" 
        ,DATE("DATE") AS CALENDAR_DATE
        ,YEAR("DATE") AS YEAR
        ,QUARTER("DATE") AS QUARTER
        ,MONTH("DATE") AS MONTH
        ,DAY("DATE") AS DAY_OF_THE_MONTH
        ,DAYNAME("DATE") AS DAY_NAME
        ,CASE 
            WHEN DAY("DATE") = 1 THEN CONCAT(CAST(DAY("DATE") AS VARCHAR), 'st')
            WHEN DAY("DATE") = 2 THEN CONCAT(CAST(DAY("DATE") AS VARCHAR), 'nd')
            WHEN DAY("DATE") = 3 THEN CONCAT(CAST(DAY("DATE") AS VARCHAR), 'rd')
            ELSE CONCAT(CAST(DAY("DATE") AS VARCHAR), 'th')
         END AS DAY_SUFFIX
        ,DAYOFWEEK("DATE") AS DAY_OF_THE_WEEK
        ,CAST(DATEDIFF('day', TO_DATE(DATE_TRUNC('quarter', "DATE")), "DATE")+1 AS VARCHAR) AS DAY_OF_QUARTER
        ,DAYOFYEAR("DATE") AS DAY_OF_YEAR
        ,WEEKOFYEAR("DATE") AS WEEK_OF_YEAR
        ,MONTHNAME("DATE") AS MONTH_NAME
        ,CONCAT(TO_CHAR("DATE", 'MM'), '-', CAST(YEAR("DATE") AS VARCHAR)) AS MONTH-YEAR
        ,CASE
            WHEN QUARTER("DATE") = 1 THEN 'Q1'
            WHEN QUARTER("DATE") = 2 THEN 'Q2'
            WHEN QUARTER("DATE") = 3 THEN 'Q3'
            WHEN QUARTER("DATE") = 4 THEN 'Q4'
         END AS QUARTER_NAME
        ,CONCAT(CAST(YEAR("DATE") AS VARCHAR), '/Q', CAST(QUARTER("DATE") AS VARCHAR)) AS YEAR/QUARTER
        ,TO_CHAR("DATE", 'MMYYYY') AS MMYYYY
        ,TO_DATE(DATE_TRUNC('month', "DATE")) AS FIRST_DAY_OF_MONTH
        ,LAST_DAY("DATE") AS LAST_DAY_OF_MONTH
        ,TO_DATE(DATE_TRUNC('quarter', "DATE")) AS FIRST_DAY_OF_QUARTER
        ,LAST_DAY(ADD_MONTHS("FIRST_DAY_OF_QUARTER",2)) AS LAST_DAY_OF_QUARTER
        ,TO_DATE(DATE_TRUNC('year', "DATE")) AS FIRST_DAY_OF_YEAR
        ,LAST_DAY(ADD_MONTHS("FIRST_DAY_OF_YEAR",11)) AS LAST_DAY_OF_YEAR
        ,HASH("CALENDAR_DATE") AS META_NK_COLUMN_HASH
        ,'1' AS META_IS_CURRENT
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_CREATED_DATE
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_UPDATED_DATE
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_EFFECTIVE_FROM
        ,TO_TIMESTAMP_NTZ('9999-12-31') AS META_EFFECTIVE_TO
        ,'1' AS META_JOB_ID
 
    FROM CTE
