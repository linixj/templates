--DIM TABLE DDL
CREATE OR REPLACE TABLE DW.DIM_DATE
(   
       --METADATA
     META_NK_COLUMN_HASH VARCHAR NOT NULL
    ,META_IS_CURRENT BOOLEAN NOT NULL
    ,META_CREATED_DATE TIMESTAMP_NTZ NOT NULL
    ,META_UPDATED_DATE TIMESTAMP_NTZ NOT NULL
    ,META_EFFECTIVE_FROM TIMESTAMP_NTZ NOT NULL
    ,META_EFFECTIVE_TO TIMESTAMP_NTZ NOT NULL
    ,META_JOB_ID VARCHAR NULL

    ,DATE_DIM_KEY VARCHAR NULL
    ,DATE DATETIME NULL
    ,CALENDAR_DATE VARCHAR NULL
    ,YEAR VARCHAR NULL
    ,QUATER VARCHAR NULL
    ,MONTH VARCHAR NULL
    ,DAY_OF_THE_MONTH VARCHAR NULL
    ,DAY_NAME VARCHAR NULL
    ,DAY_SUFFIX VARCHAR NULL
    ,DAY_OF_THE_WEEK VARCHAR NULL
    ,DAY_OF_QUARTER VARCHAR NULL
    ,DAY_OF_YEAR VARCHAR NULL
    ,WEEK_OF_QUARTER NUMBER NULL
    ,WEEK_OF_YEAR VARCHAR NULL
    ,MONTH_NAME VARCHAR NULL
    ,MONTH-YEAR VARCHAR NULL
    ,QUARTER_NAME VARCHAR NULL
    ,YEAR/QUARTER VARCHAR NULL
    ,MMYYYY VARCHAR NULL
    ,FIRST_DAY_OF_MONTH DATE NULL
    ,LAST_DAY_OF_MONTH DATE NULL
    ,FIRST_DAY_OF_QUARTER DATE NULL
    ,LAST_DAY_OF_QUARTER DATE NULL
    ,FIRST_DAY_OF_YEAR DATE NULL
    ,LAST_DAY_OF_YEAR DATE NULL
    ,HOLIDAYS VARCHAR NULL
    ,BUSINESS_DAYS_FLAG BOOLEAN NULL
    ,WEEK_DAYS_FLAG BOOLEAN NULL
    
)
;


--can define the total days you want for dim_date table
create or replace temporary table STAGE.dim_date_temp(days int) as
select datediff('day', '1990-01-01', '2100-01-01');


--INSERT VALUES
INSERT INTO
DW.DIM_DATE
(   
     "DATE_DIM_KEY" 
    ,"DATE" 
    ,"CALENDAR_DATE" 
    ,"YEAR" 
    ,"QUATER" 
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
        ,TO_CHAR("DATE",'YYYY-MM-DD') AS CALENDAR_DATE
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
        ,HASH("DATE_DIM_KEY", "DATE", "DAY_OF_THE_WEEK", "WEEK_OF_YEAR") AS META_NK_COLUMN_HASH
        ,'1' AS META_IS_CURRENT
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_CREATED_DATE
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_UPDATED_DATE
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS META_EFFECTIVE_FROM
        ,TO_TIMESTAMP_NTZ('9999-12-31') AS META_EFFECTIVE_TO
        ,'1' AS META_JOB_ID
 
    FROM CTE


--UPDATE HOLIDAYS, BUSINESS DAYS AND WEEK DAYS
UPDATE DW.DIM_DATE AS D 
SET D.DAY_OF_WEEK_IN_MONTH = A.new_day_of_week_in_month
FROM 
(
SELECT DATE, YEAR, MONTH, DAY_NAME, ROW_NUMBER() over(partition by YEAR, MONTH, DAY_NAME ORDER BY DATE) as new_day_of_week_in_month
from DW.DIM_DATE
)A
WHERE A.DATE = D.DATE AND D.YEAR = A.YEAR AND D.MONTH = A.MONTH AND D.DAY_NAME = A.DAY_NAME


--INCLUDING OBSERVED HOLIDAYS
UPDATE DW.DIM_DATE
SET HOLIDAYS = 
(
CASE
    WHEN MONTH = '1' 
        THEN
          CASE WHEN DAY_OF_THE_MONTH = '1'
                    THEN 'New Year???s Day'
               WHEN DAY_OF_THE_MONTH = '2' AND (DAY_NAME = 'Sun' or DAY_NAME = 'Mon')
                    THEN 'New Year???s Day - holiday'
               WHEN DAY_OF_THE_MONTH = '3' AND DAY_NAME = 'Mon'
                    THEN 'New Year???s Day - holiday'
           END
   WHEN MONTH = '1' AND DAY_NAME = 'Mon' AND DAY_OF_WEEK_IN_MONTH = '3'
        THEN 'Martin Luther King, Jr. Day'
    WHEN MONTH = '2' AND DAY_NAME = 'Mon' AND DAY_OF_WEEK_IN_MONTH = '3'
        THEN 'President???s Day'
    WHEN DATE_DIM_KEY IN (SELECT MAX(DATE_DIM_KEY) FROM STAGE.DIM_DATE WHERE DAY_NAME = 'Mon' AND MONTH = '5' GROUP BY YEAR, MONTH)
        THEN 'Memorial Day'
    WHEN MONTH = '7' 
        THEN
        CASE WHEN DAY_OF_THE_MONTH = '3' AND DAY_NAME = 'Fri'
                THEN 'Independence Day - holiday'
             WHEN DAY_OF_THE_MONTH = '5' AND DAY_NAME = 'Mon'
                THEN 'Independence Day - holiday'
             WHEN DAY_OF_THE_MONTH = '4' 
                THEN 'Independence Day'
        END
   
    WHEN MONTH = '9' AND DAY_NAME = 'Mon' AND DAY_OF_WEEK_IN_MONTH ='1'
        THEN 'Labor Day'
    WHEN MONTH = '11' AND DAY_NAME = 'Thu' AND DAY_OF_WEEK_IN_MONTH = '4'
        THEN 'Thanksgiving'
    WHEN MONTH = '11' AND DAY_NAME = 'Fri' AND DAY_OF_WEEK_IN_MONTH = '4'
        THEN 'Day after Thanksgiving'
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '25' 
        THEN 'Christmas Day'
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '24' AND DAY_NAME = 'Fri'
        THEN 'Christmas Day - holiday'  
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '26' AND DAY_NAME = 'Mon'
        THEN 'Christmas Day - holiday'  
        
        
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '24' AND DAY_NAME IN ('Mon', 'Tue', 'Wed','Thu','Sat', 'Sun')
        THEN 'Christmas Eve'
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '23' AND (DAY_NAME = 'Thu' OR DAY_NAME = 'Fri')
         THEN 'Christmas Eve - holiday'  

    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '31' 
        THEN 'New Year???s Eve'
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '30' AND DAY_NAME = 'Fri'
        THEN 'New Year???s Eve - holiday'
    WHEN MONTH = '12' AND DAY_OF_THE_MONTH = '29' AND DAY_NAME = 'Fri'
        THEN 'New Year???s Eve - holiday'
 END
 )


 UPDATE DW.DIM_DATE
SET WEEK_DAYS_FLAG = (
CASE WHEN DAY_NAME = 'Sat' OR DAY_NAME = 'Sun'
   THEN 'FALSE'
  ELSE 'TRUE'
END
)


UPDATE DW.DIM_DATE
SET BUSINESS_DAYS = (
CASE WHEN HOLIDAYS <> '' OR (DAY_NAME = 'Sat' OR DAY_NAME = 'Sun')
   THEN 'FALSE'
  ELSE 'TRUE'
END
)