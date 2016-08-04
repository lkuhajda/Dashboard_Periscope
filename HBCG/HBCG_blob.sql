DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]
DECLARE @ReportMonthName VARCHAR(400)
DECLARE @DateString VARCHAR(20) --= '1900-9-1'

SELECT @DateString = '1900-' + CONVERT(VARCHAR(2),@ReportMonth) + '-1'
SELECT @ReportMonthName = datename(month, @DateString)

select 'https://harvestbible.sharepoint.com/portal/acc/Team%20Documents/DashboardImages/HBCG/'
+ CONVERT(VARCHAR(4),@ReportYear)
+ '/HBCG_Dashboard_' 
+ CONVERT(VARCHAR(4),@ReportYear) 
+ '-'
+ RIGHT( '00' + CONVERT(VARCHAR(4),@ReportMonth), 2)
--+ CONVERT(VARCHAR(4),@ReportMonth) 
+ '.PNG'