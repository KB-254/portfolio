-- Data Cleaning

-- Review the original data in the 'layoffs' table
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns

-- Create a Staging Table with the same structure as the original 'layoffs' table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Verify the structure of the new staging table
SELECT * 
FROM layoffs_staging;

-- Copy all data from the original table into the staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Identify duplicates in the staging table based on selected columns
SELECT *, 
ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
) AS row_num
FROM layoffs_staging;

-- Create a Common Table Expression (CTE) to identify duplicates with additional columns
WITH duplicate_cte AS (
    SELECT *, 
    ROW_NUMBER() OVER(
        PARTITION BY company, location, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
-- Select records that have duplicates (row_num > 1)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Create a second staging table for cleaned data with an additional 'row_num' column
CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verify the structure of the new staging table
SELECT * 
FROM layoffs_staging2;

-- Insert data with row numbers into the new staging table
INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
    PARTITION BY company, location, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Check for remaining duplicates in the new staging table
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Remove duplicate records from the new staging table
SET SQL_SAFE_UPDATES = 0;

DELETE FROM layoffs_staging2
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 1;

-- Standardize Data
-- Trim leading and trailing spaces from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize 'industry' column values to a specific format
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

-- Clean up 'country' column values by removing trailing periods
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert 'date' column from text to DATE format
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- Handle Null or Blank Values
-- Set 'industry' to NULL where it is an empty string
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Fill missing 'industry' values based on other records for the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- Remove records with missing critical information in 'total_laid_off' and 'percentage_laid_off'
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop unnecessary 'row_num' column from the cleaned staging table
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final Review of Cleaned Data
-- Review the cleaned data in the staging table
SELECT *
FROM layoffs_staging2;

-- Count the total number of rows and the number of NULL values in each column
SELECT 
    COUNT(*) AS total_rows,  -- Total number of rows in the table
    SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS null_company,  -- Count of NULL values in 'company' column
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS null_location,  -- Count of NULL values in 'location' column
    SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS null_industry,  -- Count of NULL values in 'industry' column
    SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS null_total_laid_off,  -- Count of NULL values in 'total_laid_off' column
    SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS null_percentage_laid_off  -- Count of NULL values in 'percentage_laid_off' column
FROM layoffs_staging2;

-- Identify any remaining rows with NULL values in critical columns
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR total_laid_off IS NULL
   OR percentage_laid_off IS NULL;

-- Delete rows with NULL values in critical columns
DELETE FROM layoffs_staging2
WHERE industry IS NULL
   OR total_laid_off IS NULL
   OR percentage_laid_off IS NULL;

-- Review the table again to ensure no NULL values remain
SELECT * 
FROM layoffs_staging2;



-- Exploratory Data Analysis (EDA)

-- Step 1: Identify the maximum values of total layoffs and the percentage of layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Step 2: Retrieve all records where the percentage of layoffs is 100% and sort them by the total number of layoffs in descending order
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1  -- Filter for companies that laid off 100% of their workforce
ORDER BY total_laid_off DESC;  -- Order by the total number laid off, with the largest layoffs first

-- Step 3: Calculate the total number of layoffs per company and sort them in descending order
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company  -- Group by company to calculate the total layoffs for each company
ORDER BY 2 DESC;  -- Order by the total layoffs in descending order

-- Step 4: Find the earliest and latest layoff dates in the dataset
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- Step 5: Calculate the total number of layoffs per industry and sort them in descending order
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry  -- Group by industry to calculate the total layoffs for each industry
ORDER BY 2 DESC;  -- Order by the total layoffs in descending order

-- Step 6: Calculate the total number of layoffs per country and sort them in descending order
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country  -- Group by country to calculate the total layoffs for each country
ORDER BY 2 DESC;  -- Order by the total layoffs in descending order

-- Step 7: Calculate the total number of layoffs per year and sort them in descending order
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)  -- Group by year to calculate the total layoffs for each year
ORDER BY 1 DESC;  -- Order by year in descending order (most recent years first)

-- Step 8: Calculate the total number of layoffs by company stage and sort them in ascending order
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage  -- Group by stage (e.g., startup, growth) to calculate the total layoffs for each stage
ORDER BY 1 DESC;  -- Order by stage in ascending order (alphabetically by stage)

-- Step 9: Calculate the total number of layoffs per month and sort them in ascending order
SELECT SUBSTRING(date, 1, 7) as Month, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL  -- Ensure that the month is not NULL
GROUP BY Month  -- Group by month to calculate the total layoffs for each month
ORDER BY 1 ASC;  -- Order by month in ascending order (earliest months first)

-- Step 10: Calculate a rolling total of layoffs by month
WITH Rolling_Total AS (
    SELECT 
        SUBSTRING(date, 1, 7) AS Month,  -- Extract the year and month from the date
        SUM(total_laid_off) AS Monthly_Laid_Off  -- Sum the total layoffs per month and alias it
    FROM 
        layoffs_staging2
    WHERE 
        SUBSTRING(date, 1, 7) IS NOT NULL  -- Ensure the month is not NULL
    GROUP BY 
        Month  -- Group by month to calculate the total layoffs for each month
)
SELECT 
    Month, 
    Monthly_Laid_Off,  -- Select the month and the total layoffs for that month
    SUM(Monthly_Laid_Off) OVER (ORDER BY Month ASC) AS Rolling_Laid_Off  
    -- Calculate the rolling total of layoffs, ordered by month in ascending order
FROM 
    Rolling_Total;

-- Step 11: Calculate the total number of layoffs per company per year and sort them in descending order
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(date)  -- Group by company and year to calculate the total layoffs for each
ORDER BY 3 DESC;  -- Order by total layoffs in descending order

-- Step 12: Create the Company_Year CTE to calculate total layoffs per company per year
WITH Company_Year AS (
    SELECT 
        company,  -- Name of the company
        YEAR(date) AS years,  -- Extract the year from the date and alias it as 'years'
        SUM(total_laid_off) AS total_laid_off  -- Sum the total layoffs for each company in the given year
    FROM 
        layoffs_staging2  -- Source table containing layoffs data
    GROUP BY 
        company,  -- Group by company to calculate totals for each one
        YEAR(date)  -- Group by the year to calculate totals per year
),

-- Step 13: Create the Company_Year_Rank CTE to rank companies based on total layoffs per year
Company_Year_Rank AS (
    SELECT 
        company,  -- Name of the company
        years,  -- The year for which the layoffs are calculated
        total_laid_off,  -- The total number of employees laid off by the company in that year
        DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS company_rank  
        -- Rank the companies within each year (partitioned by 'years') based on the number of layoffs
        -- The companies with the same number of layoffs will receive the same rank (DENSE_RANK)
    FROM
        Company_Year  -- Use the data from the Company_Year CTE
    WHERE 
        years IS NOT NULL  -- Ensure that the year is not NULL before ranking
)

-- Step 14: Select all the data from the Company_Year_Rank CTE
SELECT *
FROM Company_Year_Rank;



