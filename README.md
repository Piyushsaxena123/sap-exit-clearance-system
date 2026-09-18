# SAP Employee Exit & Full-and-Final (F&F) Settlement System

An end-to-end offboarding management solution developed in SAP ABAP to monitor real-time departmental clearances and F&F settlement statuses.

## Architecture & Components
* **Data Dictionary (DDIC):** Custom relational tables `ZEMP_EXIT` (Exit Master) and `ZDEPT_CLEAR` (Department Clearance Checklist).
* **Module Pool Program (`SAPMZEXIT_ENTRY`):** Resignation submission screen with PBO/PAI validations and automatic ID sequencing.
* **Function Module (`Z_FM_CHECK_CLEARANCE_STATUS`):** Business logic aggregating multi-department clearance states (`P` = Pending, `C` = Cleared, `R` = Rejected).
* **Interactive ALV Dashboard (`ZPRG_EXIT_CLEARANCE_DASHBOARD`):** Real-time monitoring report with dynamic traffic light indicators (Red/Yellow/Green LEDs) and interactive drill-down event handling.

## System Preview
![ALV Dashboard](dashboard_preview.png)
