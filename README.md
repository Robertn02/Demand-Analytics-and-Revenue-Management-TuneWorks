# TuneWorks — Data Dictionary

> This README documents the schema used in the **“Demand Analytics and Revenue Management — TuneWorks”** project.  

<details>
  <summary><strong>Table of Contents</strong></summary>

- [Conventions](#conventions)
- [agents](#agents--entertainer-agent-information)
- [engagements](#engagements--event-bookings-customer--entertainer)
- [entertainers](#entertainers--entertainer-master-data)
- [entertainer_styles](#entertainer_styles--mapping-entertainer--musical-style)
- [musical_styles](#musical_styles--musical-style-reference)
- [musical_preferences](#musical_preferences--customer-style-preferences)
- [customers](#customers--customer-master-data)
- [entertainer_members](#entertainer_members--mapping-entertainer--member)
- [members](#members--individual-members-eg-band-members)
- [ztbl*](#ztbl--calendarlabel-reference-tables-prefix-family)
- [Open Questions](#open-questions-to-clarify-with-data-owner)
- [Data Quality Notes](#data-quality-notes-initial)
- [Quick Links](#quick-links-suggested-readme-section)
</details>

---

## Conventions

- Table names use `snake_case`  
- Primary keys (PK) end with `_id`; foreign keys (FK) reference the PK of another table  
- Data types: `int`, `numeric(… )`, `date`, `time`, `timestamp`, `text`, `char`

---

## `agents` — entertainer agent information
| Column | Type | Description | Notes |
|---|---|---|---|
| `agent_id` | int (PK) | Unique agent identifier |  |
| `agt_first_name` | text | First name |  |
| `agt_last_name` | text | Last name |  |
| `agt_street_address` | text | Street address |  |
| `agt_city` | text | City |  |
| `agt_state` | text | State (abbr) |  |
| `agt_zip_code` | text | ZIP/postal code | store as text to preserve leading zeros |
| `agt_phone_number` | text | Phone number | store as text (formatting) |
| `date_hired` | date | Hire date |  |
| `salary` | numeric(12,2) | Annual base salary (USD) | **Anomaly:** Agent 9 shows “50” → likely data error |
| `commission_rate` | numeric(5,4) | Commission rate (0–1) | confirm range & caps |

---

## `engagements` — event bookings (customer ↔ entertainer)
| Column | Type | Description | Notes |
|---|---|---|---|
| `engagement_id` | int (PK) | Unique engagement identifier | **DQ:** exported counts appear inconsistent; re-verify extract |
| `start_date` | date | Event start date |  |
| `end_date` | date | Event end date | enforce `start_date ≤ end_date` |
| `start_time` | time | Start time | if stored as datetime, normalize |
| `stop_time` | time | End time |  |
| `contract_price` | numeric(12,2) | Flat contract price (USD) | non-negative |
| `customer_id` | int (FK → `customers.customer_id`) | Customer |  |
| `agent_id` | int (FK → `agents.agent_id`) | Handling agent | confirm mapping consistency |
| `entertainer_id` | int (FK → `entertainers.entertainer_id`) | Entertainer |  |

---

## `entertainers` — entertainer master data
| Column | Type | Description | Notes |
|---|---|---|---|
| `entertainer_id` | int (PK) | Unique entertainer |  |
| `ent_stage_name` | text | Stage name |  |
| `ent_ssn` | char(11) | SSN `XXX-XX-XXXX` | **PII:** restrict access |
| `ent_street_address` | text | Address |  |
| `ent_city` | text | City |  |
| `ent_state` | text | State (abbr) |  |
| `ent_zip_code` | text | ZIP/postal code | keep as text |
| `ent_phone_number` | text | Phone number | keep as text |
| `ent_web_page` | text | Website URL | nullable |
| `ent_email_address` | text | Email | nullable |
| `date_entered` | date | Date joined company |  |

---

## `entertainer_styles` — mapping: entertainer ↔ musical style
| Column | Type | Description | Notes |
|---|---|---|---|
| `entertainer_id` | int (FK) | Entertainer | many-to-many |
| `style_id` | int (FK) | Musical style |  |
| `style_strength` | int | Strength 1–3 | **Open Q:** is 1 strongest or weakest? |

---

## `musical_styles` — musical style reference
| Column | Type | Description | Notes |
|---|---|---|---|
| `style_id` | int (PK) | Unique style |  |
| `style_name` | text | Style name | controlled vocabulary |

---

## `musical_preferences` — customer style preferences
| Column | Type | Description | Notes |
|---|---|---|---|
| `customer_id` | int (FK) | Customer |  |
| `style_id` | int (FK) | Musical style |  |
| `preference_sequence` | int | Rank 1–3 | **Open Q:** direction vs `style_strength`? |

---

## `customers` — customer master data
| Column | Type | Description | Notes |
|---|---|---|---|
| `customer_id` | int (PK) | Unique customer |  |
| `cust_first_name` | text | First name |  |
| `cust_last_name` | text | Last name |  |
| `cust_street_address` | text | Address |  |
| `cust_city` | text | City |  |
| `cust_state` | text | State (abbr) |  |
| `cust_zip_code` | text | ZIP/postal code | keep as text |
| `cust_phone_number` | text | Phone number | keep as text |

---

## `entertainer_members` — mapping: entertainer ↔ member
| Column | Type | Description | Notes |
|---|---|---|---|
| `entertainer_id` | int (FK) | Entertainer | one-to-many from entertainer |
| `member_id` | int (FK) | Member |  |
| `status` | text | Relationship/status | **Open Q:** allowed values & meaning |

---

## `members` — individual members (e.g., band members)
| Column | Type | Description | Notes |
|---|---|---|---|
| `member_id` | int (PK) | Unique member |  |
| `mbr_first_name` | text | First name |  |
| `mbr_last_name` | text | Last name |  |
| `mbr_phone_number` | text | Phone number | keep as text |
| `gender` | char(1) | `F` or `M` | **DQ:** one `NULL` present |

---

## `ztbl*` — calendar/label reference tables (prefix family)
| Table | Columns (examples) | Purpose | Notes |
|---|---|---|---|
| `ztblmonths` | `month_start`, `month_end`, `month_year`, `year_number`, `month_number` | Month bucketing for trends | used in monthly metrics |
| `ztbldays`, `ztblweeks` | calendar fields | Day/week bucketing | confirm join keys |
| `ztbl_ski_labels` *(name uncertain)* | `label_count` (1–60) | Unknown label mapping | **Open Q:** define semantics |

---

## Open Questions
1. Are lower numbers stronger or weaker for `style_strength` and `preference_sequence`?  
2. Why do exported `engagement_id` counts appear inconsistent? Can we re-extract and provide a schema spec?  
3. Is **Agent 9 salary = “50”** a unit issue ($50 vs $50,000) or placeholder?  
4. What are the valid values and definitions for `entertainer_members.status`?  
5. What is the intended use of `ztbl*` tables, especially the meaning of `label_count`?  
6. Are `start_time` / `stop_time` in local time or UTC? Any timezone standard?

---

## Data Quality Notes

1. **Agent salary anomaly**  
   In `agents.salary`, **Agent 9 = 50** while peers are in the tens of thousands. This likely indicates a data-entry or unit error, or a special case (e.g., part-time/tenure). Verify with HR/payroll.

2. **Engagement ID gaps / record count mismatch**  
   In `engagements.engagement_id`, the **max ID is 131** but only **~111 records** are present and some IDs are missing. This suggests deletions, partial loads, or ID gaps; re-verify the extract and PK continuity.

3. **Preference score direction is undefined**  
   All preference-related scores range **1–3** (e.g., `preference_sequence`, `style_strength`), but it is unclear whether **1 = highest** or **lowest**. Define the scale to avoid inverted rankings.

4. **Binary status encoding not documented**  
   Member/entertainer relationship `status` appears binary (values **1** and **2**), but semantics are not defined. Standardize to **0/1** (inactive/active) or provide a clear codebook.

5. **Redundant date/time storage in `engagements`**  
   Dates and times are split across `start_date`/`end_date` and `start_time`/`stop_time`. Consider consolidating into **`start_timestamp` / `end_timestamp`** (or keep both with clear purpose) after confirming business needs (e.g., timezone handling).

6. **Phone number datatype**  
   All phone numbers are stored as `char/text`. While this supports formatting and leading zeros, some workflows may prefer numeric handling for dialers. **Recommendation:** keep as `text` (best practice for E.164/formatting), and handle click-to-call at the application layer.

7. **Duplicate rows / duplicate relationships**  
   Multiple duplicates exist, including repeated pairs in `entertainer_members` with different or repeated `status`. Enforce **PK/unique constraints** (e.g., `(entertainer_id, member_id)`), dedupe, and define status update rules.

8. **`ztbl*` table family lacks relational keys**  
   The `ztbl` series (days/weeks/months/labels) store calendar-like attributes but **lack join keys** and consistent relationships. Introduce a **shared date key** (e.g., `date_key`) and normalize structure.

9. **Redundant month attributes in `ztblmonths`**  
   `ztblmonths` includes 12 boolean “is_Jan…is_Dec” columns plus `year_number`, `month_number`, `month_start`, `month_end`, and `month_year`. This repeats the same information. Prefer a **single `month_date`** (first of month) plus derived fields.

10. **`month_year` stored as `char`**  
   `ztblmonths.month_year` is `char`, making time functions harder (e.g., `EXTRACT`). Store as a **date** (e.g., first day of month) or **`yyyy-mm`** as a typed **`date`/`timestamp`**.

11. **Purpose of `ztbldays` unclear**  
   `ztbldays` enumerates calendar dates but lacks documented use. Define its intended role (date dimension, holiday logic, seasonality flags) or remove if redundant.

12. **`ztbl_ski_labels` appears to be an unused 1–60 list**  
   The table lists labels **1–60** without context. If not referenced, **remove** or document the intended mapping.

13. **`ztblweeks` overlaps with built-in week functions**  
   Week attributes are provided but can be derived via **date functions** (e.g., ISO week). If custom fiscal weeks are required, keep with a proper **fiscal calendar spec**; otherwise consider removal.
