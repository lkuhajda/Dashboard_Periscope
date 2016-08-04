USE Analytics
/*
WITW Net Income Monthly Current Year
*/
	DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
	DECLARE @PrevFiscalYear INT = @ReportYear -1
  DECLARE @FiscalYear INT = [Calendar_Year|datepart(yy, getdate())]
	
	;WITH witwExpense_prev AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	--, [StaffCode]
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum

	FROM [Analytics].[DW].[FactExpense] t1
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
	
	AND
	(
		(fundcode = '025'  --for WITW only, department is loaded into "staff code"
		AND [StaffCode]  IN ( '5055', '5158', '5160', '5163', '6207' , '6217', '5162', '7217', '5178', '5180', '7219'
		, '4106', '4056', '4036', '5038', '4016', '5058', '4096', '5078', '5098', '5138' ))
		OR
		(fundcode = '086')
	)

	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] --, [StaffCode] --, [DepartmentCode]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)
	
, witwRevenue_prev AS
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
	--AND t4.Code = 'witw'
	AND t2.EntityCode  = 'WITW'
	AND fundcode in ('025', 086)
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	),

witwExpense AS
	(
	SELECT
	  t3.[FiscalYear]
	, t3.[FiscalMonth] 
	, t3.[CalendarYear] 
	, t3.[CalendarMonth] 
	, SUM(t1.amount) as Amount
	--, [StaffCode]
	, ROW_NUMBER() OVER(ORDER BY t3.[FiscalYear] , t3.[FiscalMonth]) AS RowNum

	FROM [Analytics].[DW].[FactExpense] t1
	LEFT JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	
	WHERE 
	t3.[FiscalYear] = @FiscalYear --year(getdate())
	AND t2.EntityCode  = 'WITW'
	
	AND
	(
		(fundcode = '025'  --for WITW only, department is loaded into "staff code"
		AND [StaffCode]  IN ( '5055', '5158', '5160', '5163', '6207' , '6217', '5162', '7217', '5178', '5180', '7219'
		, '4106', '4056', '4036', '5038', '4016', '5058', '4096', '5078', '5098', '5138' ))
		OR
		(fundcode = '086')
	)

	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth] --, [StaffCode] --, [DepartmentCode]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)
	
, witwRevenue AS
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
	AND t2.[TenantID] = 3
	
	GROUP BY  t3.[FiscalYear] , t3.[FiscalMonth] 
	 , t3.[CalendarYear], t3.[CalendarMonth]
	 --t3.[MinistryYear], t3.[MinistryMonth]
	)
		select t1.fiscalyear,t1.fiscalmonth,  t1.calendaryear,t1.calendarmonth, month_name, concat('FY', right(@ReportYear,2)) as year,
	--t1.amount as RevenueAmount, t2.amount as ExpenseAmount,  
	t1.amount - t2.amount as NetIncome
	from witwRevenue t1
	inner join witwExpense t2
	on t1.fiscalyear = t2.fiscalyear
	and t1.fiscalmonth = t2.fiscalmonth
  JOIN [month_map] on t1.CalendarMonth = month_map.month_num
  where t1.CalendarMonth <> 6

union


	select t1.fiscalyear,t1.fiscalmonth,  t1.calendaryear,t1.calendarmonth, month_name, concat('FY', right(@PrevFiscalYear,2)) as year,
	--t1.amount as RevenueAmount, t2.amount as ExpenseAmount, 
	 t1.amount - t2.amount as NetIncome
	from witwRevenue_prev t1
	inner join witwExpense_prev t2
	on t1.fiscalyear = t2.fiscalyear
	and t1.fiscalmonth = t2.fiscalmonth
  JOIN [month_map] on t1.CalendarMonth = month_map.month_num
order by 6 desc