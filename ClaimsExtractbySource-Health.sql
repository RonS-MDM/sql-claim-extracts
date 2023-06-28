-- This is a clamis extract for Co-Op Renewal for Health Claims
Declare @FromDate datetime, @ToDate datetime, @Source varchar(20),@ClientNumber varchar(4)
set @FromDate = '20220801'
set @ToDate = '20220831'
set @Source = 'Associum'
set @ClientNumber = '6312'

IF OBJECT_ID('tempdb..#TempClaimsExtract', 'U') IS NOT NULL
/*Then it exists*/
DROP TABLE #TempClaimsExtract

select
	cl.CLI_NO as [Client Number],
	cl.EMP_NO as [MDM Employee Number],
	map.COO_CLI_NO as [Co-Op Client Number],
	emp.last_name as [Employee Last Name],
	emp.first_name as [Employee First Name],
	emp.dob as [Employee DOB],
	hd.P_NO as [Patient Number],
	case hd.p_NO
		when 1 then emp.last_name
		else '                         '
	end as [Patient Last Name],
	case hd.p_NO
		when 1 then emp.first_name
		else '                         '
	end as [Patient First Name],
	case hd.p_NO
		when 1 then emp.dob
		else '                         '
	end as [Patient DOB],
	case hd.p_NO
		when 1 then 'Self'
		else '                         '
	end as [Patient Relationship],
	cl.CLAIM_NO as [Claim Number],
	hd.LINE_NO as [Line Number],
	cl.CHQ_DATE as [Date Paid],
	hd.DATE1 as [Service Date],
	case trim(hd.TYPE)
		when '10' then 'Drug Expense'
		else hd.TYPE_DESC
	end as [Service Description],
	hd.DEDUCTIBLE as [Deductible Amount],
	hd.ELIGIBLE as [Eligible Amount],
	hd.BENEFIT as [Paid Amount],
	case trim(hd.TYPE)
		when '10' then convert(varchar(10),hd.DIN)
		else ''
	end as [DIN]
into #TempClaimsExtract
from claim cl
	inner join claimhd hd on
		cl.CLAIM_NO = hd.CLAIM_NO
	inner join Import_client_map map on
		cl.CLI_NO = map.OUR_CLI_NO
		and SOURCE = @Source
	inner join emp emp on
		cl.EMP_NO = emp.emp_no
where
	cl.CLAIM_TYPE = 'H'
	and len(hd.Date1) > 5
	and convert(datetime,hd.DATE1,101) between @FromDate and @ToDate
	and cl.STATUS in ('P','X')
	and left(convert(varchar(10),cl.cli_no),4) = @ClientNumber
	--and cl.CLI_NO = 6312017 --Use for testing

update #TempClaimsExtract
	set [Patient Relationship] = 'Spouse'
where
	[Patient Number] = 2

update #TempClaimsExtract
	set [Patient Relationship] = 'Child'
where
	[Patient Number] > 2

update #TempClaimsExtract
	set 
		[Patient Last Name] = dep.LAST_NAME,
		[Patient First Name] = dep.FIRST_NAME,
		[Patient DOB] = dep.BIRTH_DATE
from #TempClaimsExtract temp
	inner join depends dep on
		temp.[Client Number] = dep.CLI_NO
		and temp.[MDM Employee Number]= dep.EMP_NO
		and (temp.[Patient Number] - 1) = dep.DEP_NO
where
	[Patient Number] > 1


select *
from #TempClaimsExtract
