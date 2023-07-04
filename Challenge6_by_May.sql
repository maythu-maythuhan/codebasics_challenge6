
-- Codebasics Resume_Challenge#6 By May Thu Han


# 1a. Who prefers energy drink more? (male/female/non-binary?)

SELECT Gender, count(Respondent_ID)
FROM dim_repondents
GROUP BY 1
ORDER BY 2 desc;


# Consume Preference in details number of people by Gender
WITH genderCountWithConsumeFrequency AS (
	SELECT Consume_frequency, Gender, count(Gender) AS gender_count 
	FROM dim_repondents d
	JOIN fact_survey_responses fact
	USING (Respondent_ID)
	GROUP BY Consume_frequency, Gender
	ORDER BY 1,2 desc
)
SELECT 
	*, 
	sum(gender_count) over(partition by Gender order by gender_count) AS cumulative_gender_count
FROM genderCountWithConsumeFrequency;

-----------------------------------------------------------------------------------------------------------
# 1b. Which age group prefers energy drinks more?

SELECT Age, count(Respondent_ID)
FROM dim_repondents
GROUP BY 1 
ORDER BY 2 desc;

# This is with the consume_frequency for details
WITH ConsumeFrequencyWithAgeGroup AS (
	SELECT 
		Consume_frequency, Age, count(Age) AS Age_Group_Count
	FROM dim_repondents dim 
	JOIN fact_survey_responses fact 
	USING (Respondent_ID)
	GROUP BY 1,2
	ORDER BY 2
),
cte as (
	SELECT	*,
		sum(Age_Group_Count) over(partition by Age order by Age_Group_Count) AS cumulative_age_count
	FROM ConsumeFrequencyWithAgeGroup
)
SELECT * FROM cte;
	-- Age, cumulative_age_count from cte
-- where cumulative_age_count = (select max(cumulative_age_count) from cte);
    
----------------------------------------------------------------------------------------------------------------    
#1C.  Which type of marketing reaches the most Youth (15-30)?

SELECT Age, Marketing_channels, count(*) AS reach_counts
FROM dim_repondents dim 
JOIN fact_survey_responses f 
USING (Respondent_ID)
WHERE Age IN ("15-18","19-30")
GROUP BY 1,2
ORDER BY 1,3 desc;

# 2A. What are the preferred ingredients of energy drinks among respondents?
SELECT 
	Ingredients_expected,
    count(Respondent_ID) AS count 
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

----------------------------------------------------------------------------------

# 2B. What packaging preferences do respondents have for energy drinks?

SELECT 
	Packaging_preference,
    count(Respondent_ID) AS Preference_Count
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

-----------------------------------------------------------------------

#3A. Who are the current market leaders?

SELECT 
	Current_brands,
    count(*) AS Vote
FROM fact_survey_responses 
GROUP BY 1
ORDER BY 2 desc;

-----------------------------------------------------------------------------

# 3B. What are the primary reasons consumers prefer those brands over ours?

SELECT
	Reasons_for_choosing_brands AS Reasons,
    count(*) as count
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

---------------------------------------------------------------------

# 4A. Which marketing channel can be used to reach more customers?
SELECT
	Marketing_channels,
    count(*) AS reach_count
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

# Going more details with the Age Group Consumers

SELECT 
	Marketing_channels,
	Age,
	COUNT(*) AS reach_count
FROM dim_repondents 
JOIN fact_survey_responses USING (Respondent_ID)
GROUP BY 1, 2
ORDER BY 2, 3 DESC;

-------------------------------------------------------------------

# 4B. How effective are different marketing strategies and channels in reaching our customers?

# by Age Group pct depends on each channel

WITH Marketing_Age AS (
	SELECT 
		Marketing_channels,
		Age,
		COUNT(*) AS reach_count
	FROM dim_repondents 
	JOIN fact_survey_responses USING (Respondent_ID)
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
)
SELECT 
	*,
	reach_count * 100 / (SUM(reach_count) OVER(PARTITION BY Marketing_channels)) AS reach_pct
FROM Marketing_Age
ORDER BY Marketing_channels DESC;

# with Age Group percent on all channel    

WITH cte4 AS (
	SELECT 
		Marketing_channels,
		Age,
		COUNT(*) AS reach_count
	FROM dim_repondents 
	JOIN fact_survey_responses USING (Respondent_ID)
	GROUP BY 1, 2
	ORDER BY 2, 3 DESC
),
cte5 AS (
	SELECT
		*,
		SUM(reach_count) OVER(PARTITION BY Age ORDER BY reach_count) AS cumulative_reach_count
	FROM cte4 
)
SELECT 
	*,
	ROUND((cumulative_reach_count * 100 / (SELECT COUNT(*) FROM fact_survey_responses)), 1) AS percent
FROM cte5
WHERE cumulative_reach_count IN (1488, 5520, 2376, 426, 190);

----------------------------------------------------------------------

# 5A. What do people think about our brand? (overall rating)

SELECT 
    Brand_perception,
    count(*) as vote_count,
    count(*) * 100 / (SELECT count(*) FROM fact_survey_responses) as percent
FROM 
    fact_survey_responses
GROUP BY 
    Brand_perception
ORDER BY 
    percent DESC;


-- We got too many neutral, Why?
-- Let's do some analysis (how many % have tried or not)

SELECT 
    Tried_before,
    count(Tried_before) as count,
    round((count(Tried_before) * 100 / (SELECT count(*) FROM fact_survey_responses)),2) as percent
FROM fact_survey_responses
GROUP BY 1
ORDER BY percent desc;

-- For those who haven't tried, Why??

SELECT 
	Tried_before,
	Reasons_preventing_trying,
    count(Reasons_preventing_trying) as vote
FROM fact_survey_responses
WHERE Tried_before="No"
GROUP BY 2
ORDER BY 3 desc;

-- For those who have tried before, why is it still neutral??

SELECT 
	Tried_before,
	Taste_experience,
    count(Taste_experience) as Vote
FROM fact_survey_responses
WHERE Tried_before="Yes"
GROUP BY 2
ORDER BY 3 desc;

----------------------------------------------------------

#5B. Which cities do we need to focus more on?

#City with HIGHEST "Not" Tried Before
SELECT 
	City,
    Tried_before,
    count(Tried_before) as Count
FROM dim_cities
JOIN dim_repondents
USING (City_ID)
JOIN fact_survey_responses
USING (Respondent_ID)
WHERE Tried_before="No"
GROUP BY 1
ORDER BY 3 desc;


#City with LOWEST "YES" Tried Before
SELECT 
	City,
    Tried_before,
    count(Tried_before) as Count
FROM dim_cities
JOIN dim_repondents
USING (City_ID)
JOIN fact_survey_responses
USING (Respondent_ID)
WHERE Tried_before="Yes"
GROUP BY 1
ORDER BY 3;

--------------------------------------------------------------------

#6B. Where do respondents prefer to purchase energy drinks?

SELECT 
	Purchase_location,
    count(*) as Vote
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

-----------------------------------------------------------------------------------

#6B. What are the typical consumption situations for energy drinks among respondents?

SELECT 
	Typical_consumption_situations,
    count(*) as Vote
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

# Let's see which Age Group has more consumption preference situation

SELECT 
	Typical_consumption_situations,
    Age,
    count(Age) as Vote
FROM dim_repondents
JOIN fact_survey_responses
USING (Respondent_ID)
GROUP BY 1, 2
ORDER BY 1 desc,3 desc;

-------------------------------------------------------------------------------------

#6C. What factors influence respondents' purchase decisions, 
# such as price range and limited edition packaging?

#with price range
SELECT 
    Price_range,
    count(*) as Vote
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;

#with limited_edition packaging

SELECT
	Limited_edition_packaging,
    count(*) as Vote
FROM fact_survey_responses
GROUP BY 1
ORDER BY 2 desc;