/*******************************************************
*                                                      *
*    Report: Claims Extract - Health                   *
*                                                      *
********************************************************/

declare @FromDate datetime, @ToDate datetime, @ClientNumber int

set @FromDate = '2021-07-01'
set @ToDate = '2022-06-30'
set @ClientNumber = 1000461

IF OBJECT_ID('tempdb..#TempGainReport', 'U') IS NOT NULL
/*Then it exists*/
DROP TABLE #TempGainReport


select  --distinct
	ftClientNumber as [Client number],
	ftEmployeeNumber as [MDM Employee No],
	ftPatientNo,
	--map.COO_CLI_NO as [Co-op Client No],
	ftEmpLastName as [Employee Last Name],
	ftEmpFirstName as [Employee First Name],
	'Needs to be populated' as [Employee Date of Birth],
	ftPatientLastName as [Patient Last Name],
	ftPatientFirstName as [Patient First Name],
	'Needs to be populated' as [Patient Date of Birth],
	'Needs to be Populated' as [Patient Relationship],
	ftClaimNumber as [Claim Number],
	ftSubMDate as [Date Paid],
	ftServiceDate as [Service Date],
	case ftBenDetail
		when 'Drug' then 'Drugs'
		else ftServiceCodeDesc
	end as [Service Description],
	ftTotDeductAmt as [Deductable Amount],
	ftTotSubAmt as [Submitted Amount],
	ftPayAmt as [Paid Amount],
	ftToothCode as [Tooth],
	ftToothSurface as [Surface],
	case ftBenDetail
		when 'Drug' then ftServiceCode
		else ''
	end as [DIN]
into #TempGainReport
from ftClaimsFactTable
	
where
	ftSubMDate between @FromDate and @ToDate
	--and left(convert(varchar(10),ftClientNumber),4) = '6312'
	and ftBenefit = 'Health'
	and ftClaimStatus not in ('History','Pred','This status is not defined B')
	and ftClientNumber = @ClientNumber
order by ftClientNumber,ftEmpLastName,ftEmpFirstName


update #TempGainReport
	set 
		[Employee Date of Birth] = emp.dob
from #TempGainReport gain
	inner join emp emp on
		gain.[Client number] = emp.cli_no
		and gain.[MDM Employee No] = emp.emp_no
	


update #TempGainReport
	set 
		[Patient Relationship] = 'Self',
		[Patient Date of Birth] = emp.dob
from #TempGainReport gain
	inner join emp emp on
		gain.[Client number] = emp.cli_no
		and gain.[MDM Employee No] = emp.emp_no
	where ftPatientNo = 1

update #TempGainReport
	set [Patient Relationship] = 'Spouse'
where ftPatientNo = 2

update #TempGainReport
	set [Patient Relationship] = 'Child'
where ftPatientNo > 2

update #TempGainReport
	set [Patient Date of Birth] = dep.BIRTH_DATE
from #TempGainReport gain
	inner join depends dep on
		gain.[Client number] = dep.CLI_NO
		and gain.[MDM Employee No] = dep.EMP_NO
		and gain.[Patient Last Name] = dep.LAST_NAME
		and gain.[Patient First Name] = dep.FIRST_NAME

select *
from #TempGainReport
--where [Claim Number] = 1431299  
order by [Employee Last Name],[Employee First Name]


select sum([Paid Amount])
from #TempGainReport
--where [Claim Number] = 30382174  






