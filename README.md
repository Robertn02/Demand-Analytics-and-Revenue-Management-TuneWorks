# TuneWorks — Demand Analytics & Revenue Management


---

## 📘 Project Overview

**TuneWorks** is a mid-sized entertainment agency that manages musical performers, agents, and customer bookings.  
While the company collects and stores event data, it lacks a dedicated analytics function.  
This project establishes a foundational data analytics framework to identify **key business drivers**, **revenue trends**, and **operational improvement opportunities**.

---

## 🎯 Objectives

1. **Understand and document the dataset**  
   Build a complete data dictionary and assess data quality, completeness, and reliability.  

2. **Clean and prepare the data**  
   Identify and fix missing values, inconsistencies, and structural issues for accurate analysis.  

3. **Generate insights through SQL and visualization**  
   - Revenue seasonality and customer engagement trends  
   - Agent performance and ROI analysis  
   - Customer segmentation and retention insights  
   - Musical style profitability and entertainer performance  

4. **Provide actionable recommendations**  
   Use analytical findings to propose strategies that improve **revenue management**, **customer retention**, and **resource allocation**.

---

## 🧠 Key Findings (Summary)

- **Seasonality:** Revenue peaks in **January**, **October**, and **February**, highlighting post-holiday demand.  
- **Agents:** ROI analysis identified high-performing agents (e.g., Marianne Wier, Karen Smith) and underperformers.  
- **Customers:** Top 20% of clients generate the majority of revenue — loyalty and reactivation programs recommended.  
- **Music Styles:** 60’s Music, Country, and Contemporary are the top-performing genres by bookings and revenue.  
- **Entertainers:** Country Feeling and JV & The Deep Six lead both in booking frequency and contract value.

---

## 🧩 Data Sources

The project uses internal TuneWorks relational data, organized in the following tables:

- `agents` — agent profiles and compensation  
- `engagements` — booking transactions (customer ↔ entertainer)  
- `entertainers`, `members`, `entertainer_members` — performer roster data  
- `musical_styles`, `musical_preferences`, `entertainer_styles` — genre mapping and preferences  
- `customers` — client directory and demographics  
- `ztbl*` — reference time dimension tables for days, weeks, and months  

A complete **[Data Dictionary](#full-data-dictionary)** is included below.

---

## 🛠️ Tools & Technologies

| Category | Tools Used |
|-----------|-------------|
| Database Querying | PostgreSQL / SQL |
| Data Cleaning | SQL, Excel |
| Visualization | Tableau / Google Sheets |
| Documentation | Markdown, GitHub |
| Analytics Focus | Descriptive analytics, segmentation, ROI evaluation, seasonality analysis |

