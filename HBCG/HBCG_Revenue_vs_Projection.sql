USE Analytics
/*
Projected revenue for HBCG line chart 1
*/

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

select *, 'Projected Revenue' from [hbcg_projected_revenue]
union
select *, 'Actual Revenue' from [hbcg_actual_revenue]