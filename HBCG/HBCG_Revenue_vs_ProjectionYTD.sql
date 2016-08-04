DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())];

with t1 as
(
select 'YTD Projected Revenue' as type, (select cumulative_sum from [hbcg_projected_revenue] where BudgetMonth = @ReportMonth) as value
union
select 'YTD Actual Revenue', (select cumulative_sum from [hbcg_actual_revenue] where CalendarMonth = @ReportMonth)
union
select 'YTD (Under) / Over Revenue', (select cumulative_sum from [hbcg_actual_revenue] where CalendarMonth = @ReportMonth) - (select cumulative_sum from [hbcg_projected_revenue] where BudgetMonth = @ReportMonth)
)
select * from t1 
order by case when type = 'YTD Projected Revenue' then 1 when type = 'YTD Actual Revenue' then 2 else 3 end