----UPDATE WEEK_OF_QUARTER
--add attributes
ALTER TABLE DW.DIM_DATE
ADD COLUMN DAY_IN_QUARTER NUMBER;

--first set week start on Sunday in this session
ALTER SESSION 
SET WEEK_OF_YEAR_POLICY = 1, WEEK_START = 7


--day in quarter: count the sequence of day_name in each quarter, 
--decide whether if it's first Mon or second Mon in a month
UPDATE DW.DIM_DATE AS D
SET D.DAY_IN_QUARTER = A.DAY_IN_QUARTER
FROM
(
    SELECT DATE
    , ROW_NUMBER() OVER(partition BY YEAR, QUARTER, DAY_NAME ORDER BY DATE) AS DAY_IN_QUARTER
    FROM DW.DIM_DATE
)A 
WHERE D.DATE = A.DATE


UPDATE DW.DIM_DATE D
SET D.WEEK_OF_QUARTER = N.WEEK_OF_QUARTER
FROM
(
  
with cte as (
    select 
        date_dim_key
        ,date
        ,year
        ,month
        ,quarter
        ,day_name
    from dw.dim_date 
        where day_in_quarter = 1 
            and day_name = 'Sun' 
            and day_of_the_month not in (1,7,8) 
)

select d.date, d.day_name, d.year, d.quarter,
week(d.date) as week_of_year_start_on_Sunday,

case when d.quarter = 1 then dense_rank() over(partition by d.year, d.quarter order by week_of_year_start_on_Sunday)
     when d.quarter = 2 then dense_rank() over(partition by d.year, d.quarter order by week_of_year_start_on_Sunday)
     when d.quarter = 3 then dense_rank() over(partition by d.year, d.quarter order by week_of_year_start_on_Sunday)
     when d.quarter = 4 then dense_rank() over(partition by d.year, d.quarter order by week_of_year_start_on_Sunday)
end as week_of_quarter_original,

case when d.month in (1,4,7,10) and d.date_dim_key < cte.date_dim_key then 0
     when d.date_dim_key >= cte.date_dim_key then week_of_quarter_original -1 
     else week_of_quarter_original 
end as week_of_quarter

from
dw.dim_date as d
left join cte on d.year = cte.year and d.quarter = cte.quarter
  
)N
WHERE D.DATE = N.DATE

/*
Validation script:

select year,quarter,  week_of_quarter, count(date_dim_key)
from dw.dim_date
where week_of_quarter not in (0,13,1,14)
group by 1,2,3
having count(date_dim_key) <> 7
order by 1,2,3


*/