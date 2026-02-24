USE Telecom_Customer_chrun 

-------------------------------------------try to answer business questions with sql from basic to advanced analysis  --------------------------------------------

-------------------------------------------------Basic  Analysis with Aggregations & Filtering----------------------------------------------------------

-------1-What is the overall churn rate in the customer base?------------------

select 
COUNT(*) AS Total_Customers ,
COUNT(CASE WHEN Churn ='Yes' THEN 1 END ) AS Churn_customers ,
COUNT(CASE WHEN Churn ='Yes' THEN 1 END )*100.0/count(Churn) AS churn_rate_percentage 
from dbo.[Telco-Customer-Churn]

------2--How many customers have each type of contract (Month-to-month, One year, Two year)?----------------------------
select count(CustomerID) AS  Customers_Count , Contract
from dbo.[Telco-Customer-Churn]
group by Contract 

-----3--What is the average monthly charge for customers who churned vs. those who stayed?-------------------------------------------

SELECT 
AVG(Convert (Float,(CASE WHEN Churn ='Yes' Then MonthlyCharges END)))AS Avg_Monthly_Charge_for_Stayed ,
AVG(Convert(Float,(CASE WHEN Churn ='No' Then MonthlyCharges END))) AS Avg_Monthly_Charge_for_Churn
FROM dbo.[Telco-Customer-Churn]

----------------- ------------another way -------------------------------------------------------------------------

SELECT 
AVG(CAST ((CASE WHEN Churn ='Yes' Then MonthlyCharges END)AS Float))AS Avg_Monthly_Charge_for_Stayed ,
AVG(CAST((CASE WHEN Churn ='No' Then MonthlyCharges END) AS Float)) AS Avg_Monthly_Charge_for_Churn
FROM dbo.[Telco-Customer-Churn]

------4---------How many customers use each payment method?------------------------------------------------------
SELECT PaymentMethod, Count(CustomerID)
From dbo.[Telco-Customer-Churn] 
Group BY PaymentMethod

------5---------What percentage of customers have paperless billing enabled?----------------------------------------

SELECT COUNT(CASE WHEN PaperlessBilling = 'Yes' THEN CustomerID END)* 100.0 /Count(CustomerID)
FROM dbo.[Telco-Customer-Churn]

-------------------------------------Intermediate Level (Grouping & Multi-dimensional Analysis)-------------------------------

-----6----------What is the churn rate by contract type? Which contract has the highest retention?

SELECT COUNT(CASE WHEN Churn ='Yes' THEN 1 END) * 100.0 /COUNT(*)  AS Churn_Rate ,Contract
FROM dbo.[Telco-Customer-Churn]
GROUP BY Contract 
ORDER BY Churn_Rate 

----7-----------Compare average tenure for churned vs. non-churned customers---------------------------------------------------
SELECT Churn , Avg(CAST(tenure AS Float))
FROM dbo.[Telco-Customer-Churn]
Group by Churn

-----8----------Which internet service type has the highest churn rate?-----------------------------------------------------------
SELECT  InternetService,
COUNT(*) AS Total_Customers,
COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) AS Churned,
COUNT(CASE WHEN Churn = 'Yes' THEN 1 END)* 100.0 /Count(*) AS CHURN_Rate 
FROM dbo.[Telco-Customer-Churn]
Group by InternetService
ORDER BY CHURN_Rate DESC 

------9---------What is the revenue impact of churn (total charges lost from churned customers)?-------------------------------------------------
SELECT SUM(CAST(TotalCharges AS Float)) AS Total_Charges  
FROM dbo.[Telco-Customer-Churn] 
Where Churn = 'Yes'

-------------another solution -------------------------------------------------------------------------
SELECT 
SUM( CASE WHEN Churn = 'Yes' THEN 1 END) AS Revenue_lost ,
SUM( CASE WHEN Churn = 'No' THEN 1 END) AS Revenue_Retained
FROM dbo.[Telco-Customer-Churn] 



-----10--------How does churn rate vary by gender and senior citizen status?------------------------------------------------
SELECT 
COUNT(CASE WHEN Churn = 'Yes' THEN 1 END)* 100.0 /Count(*) AS CHURN_Rate ,
CASE WHEN SeniorCitizen = 1 THEN 'Senior' ELse 'Non_Senior' End AS SeniorCitizen,
gender 
FROM dbo.[Telco-Customer-Churn]
Group by gender , SeniorCitizen
ORDER BY CHURN_Rate DESC

-----11------What combination of services (phone, internet, streaming) has the lowest churn?------------------------------------
SELECT COUNT(CASE WHEN Churn = 'Yes' THEN 1 END)* 100.0 /Count(*) AS CHURN_Rate , PhoneService, InternetService
FROM dbo.[Telco-Customer-Churn]
group by PhoneService, InternetService
order by CHURN_Rate ASC 

------12------Calculate average monthly charges by tenure groups (0-12 months, 13-24 months, 25+ months)-------------------------------

SELECT AVG(CAST (MonthlyCharges AS float)) AS AVG_Monthly_Charge, tenure_Group 
FROM (
SELECT MonthlyCharges , 
CASE WHEN CAST (tenure AS INT) <= 12 THEN '0-12 months' 
     WHEN CAST (tenure AS INT) > 12  AND  CAST (tenure AS INT) <=  24THEN '13-24 months' 
	 ELSE '25+ months' END AS tenure_Group 
FROM dbo.[Telco-Customer-Churn]
) AS Inner_Join 
group by tenure_Group  
ORDER BY AVG_Monthly_Charge

--------------------- same solution but sort by tenure group not Avg monthly charge -----------------------------------

SELECT AVG(CAST (MonthlyCharges AS float)) AS AVG_Monthly_Charge, tenure_Group 
FROM (
SELECT MonthlyCharges , 
CASE WHEN CAST (tenure AS INT) <= 12 THEN '0-12 months' 
     WHEN CAST (tenure AS INT) > 12  AND  CAST (tenure AS INT) <=  24THEN '13-24 months' 
	 ELSE '25+ months' END AS tenure_Group 
FROM dbo.[Telco-Customer-Churn]
) AS Inner_Join 
group by tenure_Group  
ORDER BY CASE WHEN tenure_Group  = '0-12 months'  then 1
              WHEN tenure_Group  = '13-24 months' THEN 2
			  ELSE 3 END 

-----------------------------------------------Advanced Level (Complex Analysis & Business Insights)--------------------------------
--13--Identify high-risk customer segments: customers with month-to-month contracts, high monthly charges, and low tenure---------------

SELECT 
Customer_Segmentation,
Count(*) AS Customers_Numbers,
Round(Count(CASE WHEN Churn ='Yes' THEN 1 END) * 100.0/Count(*),2) AS Churn_Ratw_Parecent ,
AVG(CAST(MonthlyCharges AS float)) AS Average_Monthly_Charges,
SUM(CAST(MonthlyCharges as Float)) AS Total_Monthly_Charges
FROM (
SELECT 
CASE
    WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 80 AND CAST(tenure AS FLOAT) < 6  THEN 'Very High Risk'
    WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 70 AND CAST(tenure AS FLOAT) < 12  THEN 'High Risk '
	WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 60 AND CAST(tenure AS FLOAT) < 24  THEN 'Mediam Risk'
	Else 'Low Risk'
END AS Customer_Segmentation ,
MonthlyCharges,
Churn,
customerID
FROM dbo.[Telco-Customer-Churn]) AS Inner_Query
Group by Customer_Segmentation


------------------------another Solution without Subquery ----------------------------------------------------------------------------

SELECT 
Count(*) AS Customers_Numbers,
Round(Count(CASE WHEN Churn ='Yes' THEN 1 END) * 100.0/Count(*),2) AS Churn_Ratw_Parecent ,
AVG(CAST(MonthlyCharges AS float)) AS Average_Monthly_Charges,
SUM(CAST(MonthlyCharges as Float)) AS Total_Monthly_Charges,
 
CASE
    WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 80 AND CAST(tenure AS FLOAT) < 6  THEN 'Very High Risk'
    WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 70 AND CAST(tenure AS FLOAT) < 12  THEN 'High Risk '
	WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 60 AND CAST(tenure AS FLOAT) < 24  THEN 'Mediam Risk'
	Else 'Low Risk'
END AS Customer_Segmentation 
FROM dbo.[Telco-Customer-Churn]
GROUP BY 
     CASE
        WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 80 AND CAST(tenure AS FLOAT) < 6  THEN 'Very High Risk'
        WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 70 AND CAST(tenure AS FLOAT) < 12  THEN 'High Risk '
	    WHEN Contract = 'Month_to_month' AND CAST(MonthlyCharges AS FLOAT) >= 60 AND CAST(tenure AS FLOAT) < 24  THEN 'Mediam Risk'
	Else 'Low Risk' 
	END 


------14------- Calculate customer lifetime value (CLV) for different segments---------------------------------------------------------

/*
CLV = Total revenue a customer generates during their lifetime 
it can be basice and historical to calculate total chargers for every customrt  ot it can be segmented with contract ot churn status 
or any other segemnted based on business 
or it can be more advanced
*/
---basic one 
SELECT 
CustomerID,
CAST (TotalCharges AS FLOAT) AS total_charges,
AVG(CAST (TotalCharges AS FLOAT)) AS AVG_OF_total_charges, 
SUM(CAST (MonthlyCharges AS FLOAT)) AS Total_monthly_charges,
AVG(CAST (MonthlyCharges AS FLOAT)) AS AVG_of_monthly_charges,
Churn AS Churn_status 
FROM dbo.[Telco-Customer-Churn]
GROUP BY customerID, TotalCharges, Churn
ORDER BY  total_charges

------------or for only churned customers 
SELECT 
CustomerID,
CAST (TotalCharges AS FLOAT) AS total_charges,
AVG(CAST (TotalCharges AS FLOAT)) AS AVG_OF_total_charges, 
SUM(CAST (MonthlyCharges AS FLOAT)) AS Total_monthly_charges,
AVG(CAST (MonthlyCharges AS FLOAT)) AS AVG_of_monthly_charges,
Churn AS Churn_status 
FROM dbo.[Telco-Customer-Churn]
WHERE Churn ='Yes'
GROUP BY customerID, TotalCharges, Churn
ORDER BY  total_charges

---------Another Approch CLV by Service Bundle--------------------------------------------------

SELECT 
CASE 
    WHEN PhoneService = 'Yes' AND InternetService = 'Yes' THEN 'Phone and internet'
	WHEN PhoneService = 'Yes' AND InternetService != 'Yes' THEN 'Phone Only'
	WHEN PhoneService = 'No' AND InternetService = 'Yes' THEN 'Internet Only'  
	ELSE 'No Service'
END AS  Service_Bundle ,
COUNT(*) AS Customer_Count,
CAST (TotalCharges AS FLOAT) AS total_charges,
AVG(CAST (TotalCharges AS FLOAT)) AS AVG_OF_total_charges, 
SUM(CAST (MonthlyCharges AS FLOAT)) AS Total_monthly_charges,
AVG(CAST (MonthlyCharges AS FLOAT)) AS AVG_of_monthly_charges,
ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*),2) AS Churn_Rate_Percent
FROM dbo.[Telco-Customer-Churn]
GROUP BY 
CASE 
    WHEN PhoneService = 'Yes' AND InternetService = 'Yes' THEN 'Phone and internet'
	WHEN PhoneService = 'Yes' AND InternetService != 'Yes' THEN 'Phone Only'
	WHEN PhoneService = 'No' AND InternetService = 'Yes' THEN 'Internet Only'  
ELSE 'No Service' END, TotalCharges
ORDER BY  total_charges

---------another Approch ----------------------------------------------------------------------------
With CLV_Segmentation  AS (
SELECT 
CASE WHEN Contract = 'Month_to_month' AND tenure < 5 THEN ' New month to month customer'
     WHEN Contract = 'Month_to_month' AND tenure >= 12 THEN 'loyal Month to month customer'
	 WHEN Contract = 'One year' THEN 'one Year contract'
	 WHEN Contract ='Two year' THEN ' Tow year contract ' 
END AS Customer_segment ,
CAST(TotalCharges AS FLOAT) AS TotalCharges ,
CAST(MonthlyCharges AS FLOAT) AS MonthlyCharges,
tenure,
Churn 
FROM  dbo.[Telco-Customer-Churn])
SELECT 
Customer_segment, 
ROUND(SUM(TotalCharges),2) AS Total_segment_revenue ,
ROUND(AVG(TotalCharges),2) AS AVG_Historical_CLV,
ROUND(MIN(TotalCharges),2) AS MIN_TotalCharges,
ROUND(MAX(TotalCharges),2) AS MAX_TotalCharges,
ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
ROUND(SUM(CASE WHEN Churn ='No' THEN MonthlyCharges END),2) AS Monthly_revenue 
FROM CLV_Segmentation
GROUP BY Customer_segment

-------15-----Which customers generate the most revenue but are at high risk of churning (high monthly charges + month-to-month contract)?--
SELECT CustomerID
     Contract,
    tenure,
    MonthlyCharges,
    TotalCharges,
    Churn,
    PaymentMethod,
    InternetService
FROM dbo.[Telco-Customer-Churn]
where  CAST(MonthlyCharges AS FLOAT) >= 70.0 AND Contract ='Month_to_Month'


----------try to solve question in another view ----------------------------------------
WITH HighRiskHighValue AS (
SELECT 
CASE WHEN CAST(MonthlyCharges AS FLOAT) >=80 THEN 'Very Hight value'
     WHEN CAST(MonthlyCharges AS FLOAT) >=70 THEN 'Hight value'
	 WHEN CAST(MonthlyCharges AS FLOAT) >=60 THEN 'Medium value'
	 ELSE 'low value'
END AS Value_Segment ,
   tenure,
    MonthlyCharges,
    TotalCharges,
    Churn,
    PaymentMethod,
    InternetService
FROM dbo.[Telco-Customer-Churn]
where Contract ='Month_to_Month' 
)
SELECT 
    Value_Segment,
    COUNT(*) AS Customer_Count,
    COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) AS Already_Churned,
    COUNT(CASE WHEN Churn = 'No' THEN 1 END) AS Still_Active,
    ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS Actual_Churn_Rate,
    ROUND(AVG(CAST(MonthlyCharges AS FLOAT)), 2) AS Avg_Monthly_Revenue,
    ROUND(SUM(CASE WHEN Churn = 'No' THEN MonthlyCharges ELSE 0 END), 2) AS Monthly_Revenue_At_Risk,
    ROUND(SUM(CASE WHEN Churn = 'No' THEN MonthlyCharges * 12 ELSE 0 END), 2) AS Annual_Revenue_At_Risk,
    ROUND(AVG(CAST(tenure AS INT)), 2) AS Avg_Tenure_Months
FROM HighRiskHighValue
GROUP BY Value_Segment
ORDER BY 
    CASE Value_Segment
        WHEN 'Very High Value' THEN 1
        WHEN 'High Value' THEN 2
        WHEN 'Medium-High Value' THEN 3
        ELSE 4
    END

---16---------Create a customer score based on multiple risk factors (contract type, tenure, payment method, services)

WITH Risk_score AS(
SELECT CustomerID,
       Contract,
	   tenure,
	   MonthlyCharges,
	   TotalCharges,
	   Churn,
	--- identify risk score for each segment ------------------
	---contract risk 
	CASE WHEN Contract = 'Month_to_Month' THEN 3
	      WHEN Contract = 'One_year' THEN 2
		  ELSE 1 --two year 
	END AS Contract_Risk_score,
	
	--tenur risk 
	CASE WHEN CAST(tenure AS INT) < 6 THEN 4
	     WHEN CAST(tenure AS INT) < 12 THEN 3
		 WHEN CAST(tenure AS INT) < 24 THEN 2
		 ELSE 1 
	END AS tenur_Risk ,

	CASE WHEN PaymentMethod = 'Electronic check' THEN 4 
	     WHEN PaymentMethod = 'Mailed check' THEN 3
		 WHEN PaymentMethod = 'Bank transfer (automatic)' THEN 2
		 ELSE 1
	END AS Payement_Method_Risk ,

	-----service Counrt 
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) AS Service_Count ,
	
	--identify service risk based on service count 
CASE WHEN
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 0  THEN 7  -- high risk 

	WHEN 
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 1 THEN 6

	WHEN 
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 2 then 5

	WHEN 
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 3 THEN 4

	WHEN (CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 4 then 3

	when (CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) = 5 THEN 2 --low risk 
    ELSE 1 
END AS Service_Risk_Score 
FROM dbo.[Telco-Customer-Churn]
WHERE Churn = 'No')

SELECT CustomerID,
       Contract,
	   tenure,
	   MonthlyCharges,
	   TotalCharges,
	   Churn,
	    Contract_Risk_score,
		tenur_Risk ,
		Payement_Method_Risk ,
		Service_Risk_Score ,
		ROUND( 
		 (Contract_Risk_score * 0.40)+
		(tenur_Risk * 0.30) + 
		(Payement_Method_Risk * 0.20) +
		(Service_Risk_Score * 0.10),2) AS Overall_Risk_Score ,


		CASE 
        WHEN ROUND((Contract_Risk_score  * 0.40) + (tenur_Risk * 0.30) + (Payement_Method_Risk * 0.20) + (Service_Risk_Score * 0.10), 2) >= 4.0 THEN 'Critical'
        WHEN ROUND((Contract_Risk_score  * 0.40) + (tenur_Risk * 0.30) + (Payement_Method_Risk * 0.20) + (Service_Risk_Score * 0.10), 2) >= 3.0 THEN 'High'
        WHEN ROUND((Contract_Risk_score  * 0.40) + (tenur_Risk * 0.30) + (Payement_Method_Risk * 0.20) + (Service_Risk_Score * 0.10), 2) >= 2.0 THEN 'Medium'
        ELSE 'Low'
    END AS Risk_Level
		     
FROM Risk_score 

---17----Analyze churn patterns by service bundles - which combinations of services have best/worst retention?

with service_bundles_analysis AS
(
SELECT customerID,
       tenure,
	   MonthlyCharges,
	   TotalCharges,
	   Churn,

	   CASE WHEN PhoneService = 'Yes' AND InternetService != 'No' AND 
	            (StreamingTV = 'Yes' OR StreamingMovies = 'Yes') THEN 'Tripple Service Bundle'
			WHEN PhoneService = 'Yes'AND InternetService != 'No'  THEN 'Double Service Bundle'
			WHEN PhoneService = 'Yes'AND InternetService = 'No'  THEN 'Phone only'
			WHEN PhoneService = 'No'AND InternetService != 'No'   THEN 'Internet Only'
			ELSE 'No Service' 
			END AS service_Bundle_Segments,

	 CASE 
            WHEN OnlineSecurity = 'Yes' AND TechSupport = 'Yes' AND OnlineBackup = 'Yes' THEN 'Full Protection Bundle'
            WHEN OnlineSecurity = 'Yes' OR TechSupport = 'Yes' OR OnlineBackup = 'Yes' THEN 'Partial Protection'
            ELSE 'No Protection Services'
        END AS Protection_Bundle,

	-----service Counrt 
	(CASE WHEN PhoneService = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END  +
	CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END + 
	CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END +
	CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END ) AS Service_Count
FROM dbo.[Telco-Customer-Churn])

SELECT 
    service_Bundle_Segments,
	Protection_Bundle,
	Service_Count,
	COUNT(CASE WHEN Churn = 'Yes' THEN 1 END ) AS Churned_Count,
	COUNT(CASE WHEN Churn = 'No' THEN 1 END ) AS Retained_Count,
	ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END ) * 100 /COUNT(*),0) AS Churned_rate
FROM service_bundles_analysis 
GROUP BY service_Bundle_Segments,Protection_Bundle, Service_Count

---18------Calculate cohort retention rates by signup period
/*
 Group customers by when they signed up (cohorts) and track how many stay over time.
 See if newer customers churn more than older ones, identify when churn happens. */
 WITH Cohort_Retention_Analysis AS(
 SELECT 
       customerID,
	   MonthlyCharges,
	   TotalCharges,
	   Churn,
	   tenure,

	   CASE WHEN tenure <= 6 THEN '0-6 Months'
	        WHEN tenure <=12 THEN '7-12 Months'
			WHEN tenure <= 24 THEN '13-24 Months'
		    WHEN tenure <= 36 THEN '25-36 months'
            WHEN tenure <= 48 THEN '37-48 months'
            ELSE '49+ months (Loyal)'
        END AS Tenure_Cohort,

		CASE WHEN tenure <= 6 THEN 1
	        WHEN tenure <=12 THEN 2
			WHEN tenure <= 24 THEN 3
		    WHEN tenure <= 36 THEN 4
            WHEN tenure <= 48 THEN 5
            ELSE 6
        END AS Tenure_Cohort_order

from dbo.[Telco-Customer-Churn])
SELECT Tenure_Cohort,
      Tenure_Cohort_order,
	  COUNT(CASE WHEN Churn = 'Yes' THEN 1 END ) AS Churned_Count,
	 COUNT(CASE WHEN Churn = 'No' THEN 1 END ) AS Retained_Count,
	ROUND(COUNT(CASE WHEN Churn = 'Yes' THEN 1 END ) * 100 /COUNT(*),0) AS Churned_rate
FROM Cohort_Retention_Analysis
GROUP BY Tenure_Cohort, Tenure_Cohort_order
ORDER BY Churned_rate DESC 

------------------------------------
-- Compare ARPU (Average Revenue Per User) Across Segments
---What it means: ARPU = Average Revenue Per User. Compare how much revenue different customer segments generate
WITH Customer_segmentation AS (
SELECT customerID,
        tenure,
		churn,
		Contract,
		MonthlyCharges,
		TotalCharges,
		CASE When tenure <= 12 THEN '0-12 Months'
		     When tenure <= 24 THEN '12-24 Months'
			 When tenure <= 36 THEN 'Established Customer(24 to 36 months)'
			 ELSE 'Loyal'
		END AS Tenure_segment,

		CASE WHEN PhoneService = 'Yes' AND InternetService !='No' THEN 'Bundled Service'
		     WHEN PhoneService = 'Yes' AND InternetService ='No' THEN 'Single Service'
			 ELSE 'No core service'
	   END AS Service_Segment 
FROM dbo.[Telco-Customer-Churn]
)

SELECT 'Contract Type' AS Segment_type ,
        Contract AS Segment_name ,
		Count(*) AS Customer_Count,
		ROUND(AVG(CAST(MonthlyCharges AS FLOAT)),2) AS ARPU_Monthly,
		ROUND(SUM(CAST(MonthlyCharges AS FLOAT)),2) AS Total_Monthly_Revenue,
		ROUND(AVG(CAST(TotalCharges AS FLOAT)),2) AS Average_total_Revenue_Per_Customer,
		COUNT(CASE WHEN churn = 'Yes' THEN 1 END)*100/COUNT(*) AS Churn_Rate
FROM Customer_segmentation 
GROUP BY Contract

UNION ALL 

SELECT 'Service Bundle' AS Segment_type ,
        Service_Segment  AS Segment_name ,
		Count(*) AS Customer_Count,
		ROUND(AVG(CAST(MonthlyCharges AS FLOAT)),2) AS ARPU_Monthly,
		ROUND(SUM(CAST(MonthlyCharges AS FLOAT)),2) AS Total_Monthly_Revenue,
		ROUND(AVG(CAST(TotalCharges AS FLOAT)),2) AS Average_total_Revenue_Per_Customer,
		COUNT(CASE WHEN churn = 'Yes' THEN 1 END)*100/COUNT(*) AS Churn_Rate
FROM Customer_segmentation 
Group by Service_Segment
UNION ALL 

SELECT 'Tenure Segment' AS Segment_type ,
        Tenure_segment  AS Segment_name ,
		Count(*) AS Customer_Count,
		ROUND(AVG(CAST(MonthlyCharges AS FLOAT)),2) AS ARPU_Monthly,
		ROUND(SUM(CAST(MonthlyCharges AS FLOAT)),2) AS Total_Monthly_Revenue,
		ROUND(AVG(CAST(TotalCharges AS FLOAT)),2) AS Average_total_Revenue_Per_Customer,
		COUNT(CASE WHEN churn = 'Yes' THEN 1 END)*100/COUNT(*) AS Churn_Rate
FROM Customer_segmentation 
Group by Tenure_segment


---------------------------------------------------------------------------
-- Service Pattern Analysis for Churned vs. Retained
---What it means: Do churned customers have similar service combinations? Do they lack certain services?

WITH service_combination AS(
SELECT churn,
       PhoneService,
       InternetService,
       OnlineSecurity,
       TechSupport,
       OnlineBackup,
       DeviceProtection,
       StreamingTV,
       StreamingMovies,
       COUNT(*) AS Customer_Count
from dbo.[Telco-Customer-Churn]
GROUP BY churn,
       PhoneService,
       InternetService,
       OnlineSecurity,
       TechSupport,
       OnlineBackup,
       DeviceProtection,
       StreamingTV,
       StreamingMovies)

SELECT churn,
       PhoneService,
       InternetService,
       OnlineSecurity,
       TechSupport,
       OnlineBackup,
       DeviceProtection,
       StreamingTV,
       StreamingMovies,
ROUND( Customer_Count * 100 /SUM( Customer_Count ) OVER (PARTITION BY Churn),2) AS Churn_rate_for_each_category 
FROM service_combination 
WHERE Customer_count >=10
ORDER BY Churn DESC ,Customer_Count DESC
---insights : 15% of the churned customers have phone service and internet service (faberic optic ) and do not have the remain services 
---business action for this insights 
-- Find active customers with risky service patterns
SELECT 
    CustomerID,
    MonthlyCharges,
    PhoneService,
    InternetService,
    OnlineSecurity,
    TechSupport,
    OnlineBackup
FROM dbo.[Telco-Customer-Churn]
WHERE Churn = 'Yes'
  AND InternetService = 'Fiber optic'
  AND OnlineSecurity = 'No'
  AND TechSupport = 'No'
  AND OnlineBackup = 'No'
ORDER BY MonthlyCharges DESC
-----19--- Create a score that predicts likelihood of churn based on customer characteristics.-------------------------------------------------------------------------------------------------------------
WITH ChurnFeatures AS (
    SELECT 
        CustomerID,
        Contract,
        tenure,
        CAST(MonthlyCharges AS FLOAT) AS MonthlyCharges ,
        CAST(TotalCharges AS FLOAT) AS TotalCharges,
        Churn,
        
        -- Feature 1: Contract Risk (0-10 points)
        CASE 
            WHEN Contract = 'Month-to-month' THEN 10
            WHEN Contract = 'One year' THEN 4
            ELSE 0
        END AS Contract_Risk_Points,
        
        -- Feature 2: Tenure Risk (0-10 points)
        CASE 
            WHEN tenure < 3 THEN 10
            WHEN tenure < 6 THEN 8
            WHEN tenure < 12 THEN 6
            WHEN tenure < 24 THEN 3
            ELSE 1
        END AS Tenure_Risk_Points,
        
        -- Feature 3: Payment Risk (0-10 points)
        CASE 
            WHEN PaymentMethod = 'Electronic check' THEN 10
            WHEN PaymentMethod = 'Mailed check' THEN 5
            ELSE 2
        END AS Payment_Risk_Points,
        
        -- Feature 4: Service Depth Risk (0-10 points)
        10 - (
            (CASE WHEN PhoneService = 'Yes' THEN 2 ELSE 0 END) +
            (CASE WHEN InternetService != 'No' THEN 2 ELSE 0 END) +
            (CASE WHEN OnlineSecurity = 'Yes' THEN 2 ELSE 0 END) +
            (CASE WHEN TechSupport = 'Yes' THEN 2 ELSE 0 END) +
            (CASE WHEN OnlineBackup = 'Yes' THEN 2 ELSE 0 END)
        ) AS Service_Risk_Points,
        
        -- Feature 5: Billing Risk (0-5 points)
        CASE 
            WHEN PaperlessBilling = 'Yes' THEN 5
            ELSE 1
        END AS Billing_Risk_Points,
        
        -- Feature 6: Demographics Risk (0-5 points)
        CASE WHEN SeniorCitizen = 1 THEN 3 ELSE 0 END +
        CASE WHEN Partner = 'No' AND Dependents = 'No' THEN 2 ELSE 0 END AS Demographics_Risk_Points,
        
        -- Feature 7: Value Risk (0-5 points)
        CASE 
            WHEN CAST(MonthlyCharges AS FLOAT) < 30 THEN 5
            WHEN CAST(MonthlyCharges AS FLOAT) < 50 THEN 3
            ELSE 0
        END AS Value_Risk_Points,
        
        -- Feature 8: Internet Type Risk (0-5 points)
        CASE 
            WHEN InternetService = 'Fiber optic' THEN 5
            WHEN InternetService = 'DSL' THEN 2
            ELSE 0
        END AS Internet_Risk_Points
        
    FROM dbo.[Telco-Customer-Churn]
    WHERE Churn = 'No'  -- Only active customers for prediction
),
PredictiveScores AS (
    SELECT 
        *,
        -- Total Predictive Score (0-60 range)
        Contract_Risk_Points + Tenure_Risk_Points + Payment_Risk_Points + 
        Service_Risk_Points + Billing_Risk_Points + Demographics_Risk_Points + 
        Value_Risk_Points + Internet_Risk_Points AS Total_Churn_Risk_Score,
        
        -- Normalize to 0-100 scale
        ROUND((Contract_Risk_Points + Tenure_Risk_Points + Payment_Risk_Points + 
               Service_Risk_Points + Billing_Risk_Points + Demographics_Risk_Points + 
               Value_Risk_Points + Internet_Risk_Points) * 100.0 / 60.0, 2) AS Normalized_Risk_Score
               
    FROM ChurnFeatures
)
SELECT 
    CustomerID,
    Contract,
    tenure,
    MonthlyCharges,
    
    -- Individual feature scores
    Contract_Risk_Points,
    Tenure_Risk_Points,
    Payment_Risk_Points,
    Service_Risk_Points,
    
    -- Total scores
    Total_Churn_Risk_Score,
    Normalized_Risk_Score,
    
    -- Risk Category
    CASE 
        WHEN Normalized_Risk_Score >= 70 THEN 'Extreme Risk'
        WHEN Normalized_Risk_Score >= 55 THEN 'High Risk'
        WHEN Normalized_Risk_Score >= 40 THEN 'Medium Risk'
        WHEN Normalized_Risk_Score >= 25 THEN 'Low Risk'
        ELSE 'Minimal Risk'
    END AS Churn_Risk_Category
FROM PredictiveScores
ORDER BY Normalized_Risk_Score DESC, MonthlyCharges DESC

--20-- Which Services Act as Retention Anchors?---------------------------------
WITH ServiceRetention AS (
    SELECT 
        'PhoneService' AS Service_Name,
        COUNT(CASE WHEN PhoneService = 'Yes' THEN 1 END) AS Total_With_Service,
        COUNT(CASE WHEN PhoneService = 'Yes' AND Churn = 'No' THEN 1 END) AS Retained_With_Service,
        COUNT(CASE WHEN PhoneService = 'No' THEN 1 END) AS Total_Without_Service,
        COUNT(CASE WHEN PhoneService = 'No' AND Churn = 'No' THEN 1 END) AS Retained_Without_Service
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'OnlineSecurity',
        COUNT(CASE WHEN OnlineSecurity = 'Yes' THEN 1 END),
        COUNT(CASE WHEN OnlineSecurity = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN OnlineSecurity = 'No' THEN 1 END),
        COUNT(CASE WHEN OnlineSecurity = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'TechSupport',
        COUNT(CASE WHEN TechSupport = 'Yes' THEN 1 END),
        COUNT(CASE WHEN TechSupport = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN TechSupport = 'No' THEN 1 END),
        COUNT(CASE WHEN TechSupport = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'OnlineBackup',
        COUNT(CASE WHEN OnlineBackup = 'Yes' THEN 1 END),
        COUNT(CASE WHEN OnlineBackup = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN OnlineBackup = 'No' THEN 1 END),
        COUNT(CASE WHEN OnlineBackup = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'DeviceProtection',
        COUNT(CASE WHEN DeviceProtection = 'Yes' THEN 1 END),
        COUNT(CASE WHEN DeviceProtection = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN DeviceProtection = 'No' THEN 1 END),
        COUNT(CASE WHEN DeviceProtection = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'StreamingTV',
        COUNT(CASE WHEN StreamingTV = 'Yes' THEN 1 END),
        COUNT(CASE WHEN StreamingTV = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN StreamingTV = 'No' THEN 1 END),
        COUNT(CASE WHEN StreamingTV = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
    
    UNION ALL
    
    SELECT 
        'StreamingMovies',
        COUNT(CASE WHEN StreamingMovies = 'Yes' THEN 1 END),
        COUNT(CASE WHEN StreamingMovies = 'Yes' AND Churn = 'No' THEN 1 END),
        COUNT(CASE WHEN StreamingMovies = 'No' THEN 1 END),
        COUNT(CASE WHEN StreamingMovies = 'No' AND Churn = 'No' THEN 1 END)
    FROM dbo.[Telco-Customer-Churn]
)
SELECT 
    Service_Name,
    
    -- Retention rates
    ROUND(Retained_With_Service * 100.0 / NULLIF(Total_With_Service, 0), 2) AS Retention_Rate_With_Service,
    ROUND(Retained_Without_Service * 100.0 / NULLIF(Total_Without_Service, 0), 2) AS Retention_Rate_Without_Service,
    
    -- Retention lift (how much better retention is WITH this service)
    ROUND(
        (Retained_With_Service * 100.0 / NULLIF(Total_With_Service, 0)) - 
        (Retained_Without_Service * 100.0 / NULLIF(Total_Without_Service, 0))
    , 2) AS Retention_Lift_Percentage,
    
    -- Rank services by retention impact
    RANK() OVER (ORDER BY 
        (Retained_With_Service * 100.0 / NULLIF(Total_With_Service, 0)) - 
        (Retained_Without_Service * 100.0 / NULLIF(Total_Without_Service, 0))
    DESC) AS Retention_Anchor_Rank
    
FROM ServiceRetention
ORDER BY Retention_Lift_Percentage DESC