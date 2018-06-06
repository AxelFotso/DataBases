/1/
select sum(Price), dateYear, phoneRateType
from DWABD.Facts F, DWABD TimeDim T, DWABD.PhoneRate P
where F.Id_time = T.Id_time and F.Id_phoneRate = P.Id_phoneRate
group by cube(phoneRateType, dateYear)



/2/

SELECT DateMonth,DateYear, SUM(NumberOfCalls) as TotNumOfCalls, SUM(price) as totalIncome,
RANK() over (ORDER BY SUM(price) DESC) as RankIncome
FROM DWABD.FACTS F, DWABD.TIMEdim Te
WHERE F.id_time=Te.id_time
GROUP BY DateMonth,DateYear;

/3/

SELECT DateMonth, SUM(NumberOfCalls) as TotNumOfCalls,
RANK() over (ORDER BY SUM(NumberOfCalls) DESC) as RankNumOfCalls
FROM dwabd.FACTS F, dwabd.TIMEDIM Te
WHERE F.id_time=Te.id_time
AND DateYear=2003
GROUP BY DateMonth;

/4/

SELECT DayOfMonth , SUM(Price), 
 AVG(SUM(Price)) OVER ( ORDER BY DayOfMonth RANGE BETWEEN INTERVAL '2' day preceding 
and current row) as avglast3days
 FROM DWABD.FACTS F, DWABD.TIMEDIM Te
WHERE F.ID_time=Te.ID_time
 AND DateYear=2003 AND DateMonth=7
GROUP BY DayOfMonth ;

/5/

SELECT DATEYEAR, DATEMONTH, SUM(PRICE) AS TOTINCOME,
SUM(SUM(PRICE)) OVER( PARTITION BY DATEYEAR ORDER BY DATEMONTH ROWS UNBOUNDED PRECEDING) AS CUMULATIVEINCOME
 FROM DWABD.FACTS F, DWABD.TIMEDIM Te
WHERE F.ID_time=Te.ID_time
GROUP BY DATEMONTH, DATEYEAR;

