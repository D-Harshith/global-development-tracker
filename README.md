# Global Development & Climate Tracker

An end-to-end data integration and analysis project examining the relationships between economic prosperity, population, public health, and environmental impact across 21 countries from 1990 to 2023.

## Project Overview

This project was built in response to a policy research initiative requiring a consolidated analytical database that merges economic, demographic, health, and environmental datasets. The final dataset serves as the foundation for evidence-based policy recommendations on sustainable global growth.

## Data Sources

| Source | Dataset | Format |
|--------|---------|--------|
| [World Bank](https://data.worldbank.org/indicator/NY.GDP.PCAP.CD) | GDP per Capita (Current US$) | CSV (wide format) |
| [World Bank](https://data.worldbank.org/indicator/SP.POP.TOTL) | Total Population | CSV (wide format) |
| [Our World in Data](https://github.com/owid/co2-data) | CO2 Emissions by Country | CSV (long format) |
| [Our World in Data](https://ourworldindata.org/grapher/life-expectancy) | Life Expectancy | CSV (long format) |


## Countries Analyzed (21)

**High Income:** USA, Germany, Japan, UK, Australia, Canada, South Korea  
**Upper-Middle Income:** China, Brazil, Mexico, Turkey, South Africa  
**Lower-Middle Income:** India, Indonesia, Nigeria, Egypt, Vietnam, Bangladesh  
**Low Income:** Ethiopia, Mozambique, Chad

## Tech Stack

- **PostgreSQL** — Data cleaning, transformation, integration (all heavy lifting in SQL)
- **Python / Pandas** — Data loading only (CSV ingestion into staging tables)
- **Tableau Public** — Interactive dashboard with 4 visualizations
- **docx-js** — Summary of Findings document generation

## Project Structure

```
├── README.md                          # This file
├── .gitignore                         # Git ignore rules
├── global_development_tracker.sql     # All SQL: schemas, staging, cleaning, production, analysis
├── loading_data.ipynb                 # Jupyter notebook for CSV ingestion into PostgreSQL
├── summary_of_findings.docx           # Final findings document with tables and insights
└── data/
    └── global_development_final.csv   # Final integrated dataset (714 rows)
```

## How to Reproduce

### Prerequisites
- PostgreSQL installed locally
- Python 3.x with `pandas`, `psycopg2-binary`, `sqlalchemy`

### Steps

1. **Download raw data** from World Bank and Our World in Data (links above)

2. **Create the database and schemas:**
   ```sql
   CREATE DATABASE global_development_tracker;
   ```

3. **Run the SQL script** in order — it creates schemas, staging tables, cleaning logic, and the production table:
   ```
   global_development_tracker.sql
   ```

4. **Run the Jupyter notebook** to load CSVs into staging tables:
   ```
   loading_data.ipynb
   ```
   > Note: Update the database connection string with your credentials using an environment variable.

5. **Execute the cleaning and integration sections** of the SQL script to build the final `production.global_development` table.

## Key Technical Decisions

| Decision | Rationale |
|----------|-----------|
| ISO codes as join key | Avoids country name mismatches across sources |
| Spine table (CROSS JOIN generate_series) | Guarantees one row per country per year (714 total) |
| LEFT JOINs throughout | Preserves rows even when individual metrics are missing |
| All TEXT staging tables | Prevents import errors; types cast during cleaning |
| 1990–2023 timeline | Consistent data coverage; avoids Soviet-era entity issues |
| Inflation adjustment (CPI) | Converts nominal GDP to constant 2015 USD for fair comparisons |

## Key Findings

1. **Economic Divergence:** Vietnam grew GDP per capita by 4,276% (1990–2023), while Japan grew only 31%.
2. **Prosperity ↔ Emissions Correlation:** The USA emits 18.55 tonnes CO2/person vs Ethiopia's 0.08 — a 230x difference.
3. **Life Expectancy Gains:** Ethiopia gained 22.2 years of life expectancy; South Africa gained only 3.2 (HIV/AIDS impact).
4. **Emissions Shift:** China overtook the USA as the world's largest emitter between 2005–2010, reaching 12,172 Mt by 2023.

## Data Quality Notes

- **Missing value:** Mozambique GDP 1990 (civil war) — left as NULL, not interpolated
- **No extrapolation:** All NULLs represent genuinely missing source data
- **Non-country filtering:** Removed 37 OWID aggregates and 49 World Bank regional codes
- **Currency:** GDP available in both current USD and constant 2015 USD (inflation-adjusted)


## License

This project uses publicly available data from the World Bank and Our World in Data. Both sources provide data under open licenses.