USE Analytics
/*
Projected expenses for HBCG line chart 
*/

DECLARE @ReportYear INT = [Calendar_Year|datepart(yy, getdate())]
DECLARE @ReportMonth TINYINT = [Calendar_Month|datepart(mm, getdate())]

DECLARE @NumSun TINYINT,
@WeeklyBudgetAmount money = 460000,
@BeginningDate DATETIME, @EndingDate DATETIME

-- SELECT @BeginningDate = '1-1-2016', @EndingDate = '12-31-2016'
SELECT @BeginningDate = concat('1-1-', @ReportYear), @EndingDate = concat('12-31-', @ReportYear)
-----------------------------------------------------
--Calculate HBC Budget Expense 
-----------------------------------------------------
;WITH dates (date)
AS
(
SELECT @BeginningDate
UNION all
SELECT dateadd(d,1,date)
FROM dates
WHERE date < @EndingDate
)

SELECT  month(date) as BudgetMonth
, year(date) as BudgetYear
--, count(1) as NumSundaysInMonth
,  count(1) * @WeeklyBudgetAmount as Amount
into #t1
from dates d1 where datename(dw, date) = 'sunday'

group by year(date), month(date)
option (maxrecursion 1000)

-----------------------------------------------------
--Calculate 'HCA', 'WITW', 'HBF Budget Expense' 
-----------------------------------------------------
;WITH Expenses AS (
	SELECT 
	BudgetMonth, BudgetYear, SUM(t1.amount) as Amount
	FROM [Analytics].[DW].[FactBudgetExpense] t1
	INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	WHERE   t2.TenantID = 3
	and Budgetyear = @ReportYear
	AND
	(
		(t4.Code = 'WITW' AND t2.fundcode IN  ('025', '086')) 
		OR
		(t4.Code IN ('HCA',  'HBF') AND t2.fundcode = '025')
    )

	 GROUP BY BudgetMonth, BudgetYear --, t4.Code
	 )
	 --	 select * from expenses


-----------------------------------------------------
--Combine and Calculate all projected expenses
-----------------------------------------------------
	 ,  ExpensesAll AS
	 (
	SELECT 
	BudgetMonth, BudgetYear,  Amount
	FROM Expenses
	 UNION
	 SELECT 
	 BudgetMonth, BudgetYear,   Amount
	 FROM #t1
	 )

	--select * from ExpensesAll

	,  ExpensesAllSummary AS
	 (
	SELECT BudgetMonth, BudgetYear,  SUM(Amount) as Amount
	,  ROW_NUMBER() OVER(ORDER BY [BudgetYear] , [BudgetMonth]) AS RowNum
	FROM ExpensesAll
	GROUP BY BudgetMonth, BudgetYear
	 )

  , Expenses_Actual AS (
	SELECT 
	 t3.[CalendarMonth] , t3.[CalendarYear] , SUM(t1.amount) as Amount --, t4.Code as entitycode
 -- , ROW_NUMBER() OVER(ORDER BY t3.[CalendarYear] , t3.[CalendarMonth] ) AS RowNum
	FROM [Analytics].[DW].[FactExpense] t1
	INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	INNER JOIN dw.DimEntity t4
	ON t1.EntityID = t4.EntityID
	AND t1.TenantID = t4.TenantID
	WHERE   t2.TenantID = 3
	AND t3.[CalendarYear] = @ReportYear
	AND
		(
			(t4.Code IN ('HCA', 'HBF') AND t2.fundcode = '025') 
			OR
			(t4.Code = 'HBC' AND t2.fundcode = '025' AND t2.GLCode NOT IN ('30010', '30058', '30075', '30046', '90139', '90145', '90260') AND t2.DepartmentCode <> '9120')
			OR
			(t4.Code  = 'WITW' 
				AND
					(fundcode = '025'  --for WITW only, department is loaded into "staff code"
					AND [StaffCode]  IN ( '5055', '5158', '5160', '5163', '6207' , '6217', '5162', '7217', '5178', '5180', '7219'
					, '4106', '4056', '4036', '5038', '4016', '5058', '4096', '5078', '5098', '5138' ))
				OR
				(fundcode = '086')
				OR
				(fundcode = '025' AND [StaffCode] = '5018' AND  GLCode = '49099')
			)
		--
		)
		GROUP BY  t3.[CalendarYear], t3.[CalendarMonth]
		)

-----------------------------------------------------
-- Actual HBF and WITW and HBC Additional Expenses
-----------------------------------------------------
, HBFXtaexpenses_Actual as (
	SELECT t3.[CalendarMonth], t3.[CalendarYear]
	  , SUM(t1.amount) as amount --, t2.entitycode
	FROM [DW].[FactFinancialOther] T1
	INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
	ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
	INNER JOIN [Analytics].DW.DimDate T3
	ON t1.DateID = t3.DateID
	WHERE  t3.[CalendarYear] = @ReportYear 
	AND t3.[CalendarMonth] <= @ReportMonth 
	AND (
		 (GLCode = '15141' and t2.entitycode = 'HBF')
		 OR
		 (GLCode IN ('15151', '15146' ) and t2.entitycode = 'WITW' AND fundcode = '086')
		 OR
		 (GLCode IN ('24225', '24230', '24233',  '24235', '24272', '15026','15146','15151') and t2.entitycode = 'HBC' AND fundcode = '025')
	 )
	GROUP BY t3.[CalendarYear], t3.[CalendarMonth]--, t2.entitycode
)

	, HBCRev_Actual as (
		SELECT t3.[CalendarMonth] , t3.[CalendarYear] 
		  , -1 * SUM(t1.amount) as Amount
		FROM [DW].[FactRevenue] T1
		INNER JOIN [Analytics].[DW].[DimFinancialCategory] t2
		ON t1.[FinancialCategoryID] = t2.[FinancialCategoryID]
		INNER JOIN [Analytics].DW.DimDate T3
		ON t1.DateID = t3.DateID

		WHERE  t3.[CalendarYear] = @ReportYear 
		AND t3.[CalendarMonth] <= @ReportMonth 
		and t2.entitycode = 'HBC'
		AND t2.fundcode = '025'  
		--AND t2.GLCode  IN ('30010', '30058', '30075', '30046')

		 AND t2.GLCode  IN ('30030','30042','31025','32010','32012','35115','35004', '37010','37020','37021','37025')
		--AND t2.DepartmentCode = '9120'
		AND t2.TenantID = 3
		GROUP BY  t3.[CalendarYear], t3.[CalendarMonth]
	)

,  ExpensesAll_Actual AS
	 (
	select [CalendarMonth], [CalendarYear], Amount from Expenses_Actual
	UNION ALL
	select [CalendarMonth], [CalendarYear],  Amount from HBFXtaexpenses_Actual
	UNION ALL
	select [CalendarMonth], [CalendarYear],  Amount from HBCRev_Actual
	)

,  ExpensesAllSummary_Actual AS
	 (
	SELECT [CalendarMonth], [CalendarYear],  SUM(Amount) as Amount --, entitycode
	,  ROW_NUMBER() OVER(ORDER BY [CalendarYear] , [CalendarMonth]) AS RowNum
	FROM ExpensesAll_Actual
	GROUP BY  [CalendarYear], [CalendarMonth] --, entitycode
	 )

-----------------------------------------------------
-- Actual HBF Additional Expenses
-----------------------------------------------------


	 select [BudgetMonth], month_name, [BudgetYear], 'Budget',  Amount
		,	(SELECT SUM(t2.Amount) from ExpensesAllSummary t2 WHERE t2.RowNum <= t1.RowNum ) AS CumulativeSum
	 FROM ExpensesAllSummary t1
   JOIN [month_map] on t1.BudgetMonth = month_map.month_num

 union

	 select [CalendarMonth], month_name, [CalendarYear], 'Actual Burn', Amount
		,	(SELECT SUM(t2.Amount) from ExpensesAllSummary_Actual t2 WHERE t2.RowNum <= t1.RowNum ) AS CumulativeSum
	 FROM ExpensesAllSummary_Actual t1
   JOIN [month_map] on CalendarMonth = month_map.month_num
   WHERE t1.CalendarMonth <= @ReportMonth
   order by BudgetYear, BudgetMonth



	 drop table #t1