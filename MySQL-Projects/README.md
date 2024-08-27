# MySQL Layoffs Data Cleaning and Analysis Project

## Project Overview
This project involves cleaning and analyzing a dataset of layoffs using MySQL. The goal is to prepare the data for meaningful analysis by removing duplicates, standardizing entries, handling null values, and conducting exploratory data analysis (EDA).

## Project Structure
- **Data Cleaning:** The data cleaning process involves creating staging tables, removing duplicates, standardizing data, and handling null or blank values. 
- **Exploratory Data Analysis (EDA):** Various SQL queries are used to analyze the cleaned data, providing insights such as the total number of layoffs per company, industry, and country, as well as trends over time.

You can view the SQL scripts used for this project in the [MySQL Projects folder](https://github.com/KB-254/portfolio/tree/main/MySQL-Projects).

## SQL Scripts
- **1. Data Cleaning:**
  - Created staging tables to preserve the original data.
  - Removed duplicate records based on multiple columns.
  - Standardized columns such as `industry` and `country`.
  - Converted date formats and handled null values appropriately.

- **2. Exploratory Data Analysis:**
  - Calculated total layoffs by company, industry, country, and year.
  - Identified the maximum and minimum layoff percentages.
  - Analyzed layoffs trends by month and year.
  - Used Common Table Expressions (CTEs) to rank companies based on layoffs per year.

## How to Run the Project
1. **Set Up the Database:**
   - Create a MySQL database and table to hold the 'layoffs' data.
   - Import your dataset into the table.

2. **Run the SQL Scripts:**
   - Execute the data cleaning scripts first to prepare the data.
   - Run the EDA queries to gain insights from the cleaned data.

3. **Review the Results:**
   - Check the cleaned data for accuracy.
   - Analyze the results of the EDA queries to understand layoff patterns.

## Conclusion
This project showcases the process of cleaning and analyzing a real-world dataset using SQL. The skills demonstrated include data cleaning, transformation, and exploratory analysis, which are essential for data-driven decision-making.

## Contact
For any questions or further discussion, feel free to reach out to me through [GitHub](https://github.com/KB-254).

