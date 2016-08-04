USE Analytics

/*
Actual Revenue for WITW #1A Line Graph: Broadcase Ministry FY16 YTD REVENUE VS. EXPENSE ($000's)
*/
	DECLARE @FiscalYear INT = [Calendar_Year|datepart(yy, getdate())],
  @PrevFiscalYear INT = [Calendar_Year|datepart(yy, getdate())] - 1,
	@CalendarMonth varchar(2) = [Calendar_Month| datepart(mm, getdate())], 
	@CalendarYear varchar(4) = [Calendar_Year|datepart(yy, getdate())]
	
	;WITH witwRevenue_current AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum
	
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear --year(getdate())
	--AND t4.Code = 'witw'
	AND t2.EntityCode  = 'WITW'
	AND fundcode in ('025', 086)
	--and actualdate <  dateadd(month, +1, convert(date, @CalendarMonth + '/01/'+  @CalendarYear ))
	--AND t2.FundCode  IN ('084','088') 
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	),

witwRevenue_prev AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum
	
	FROM [Analytics].[DW].[FactRevenue] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @PrevFiscalYear --year(getdate())
	AND t2.EntityCode  = 'WITW'
	AND fundcode in ('025', 086)
	--and actualdate <  dateadd(month, +1, convert(date, @CalendarMonth + '/01/'+  @CalendarYear ))
	--AND t2.FundCode  IN ('084','088') 
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)

	

	SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name, concat('FY', right(@FiscalYear,2)), Amount
	,	(SELECT SUM(tc.Amount) from witwRevenue_current tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
	FROM witwRevenue_current tr
  JOIN [month_map] on CalendarMonth = month_map.month_num

  union 

	SELECT FiscalYear, FiscalMonth, [CalendarYear] 
	, [CalendarMonth], month_name, concat('FY', right(@PrevFiscalYear,2)), Amount
	,	(SELECT SUM(tc.Amount) from witwRevenue_prev tc WHERE tc.RowNum <= tr.RowNum ) AS CumulativeSum
	FROM witwRevenue_prev tr
  JOIN [month_map] on CalendarMonth = month_map.month_num