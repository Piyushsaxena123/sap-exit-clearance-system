*&---------------------------------------------------------------------*
*& Report ZPRG_EXIT_CLEARANCE_DASHBOARD
*&---------------------------------------------------------------------*
*& HR Dashboard for Offboarding & F&F Settlement Monitoring
*&---------------------------------------------------------------------*
REPORT zprg_exit_clearance_dashboard.

" Include standard SAP icon constants
TYPE-POOLS: icon.

" Type definitions for ALV Output Table
TYPES: BEGIN OF ty_alv_out,
         exit_id      TYPE ze_exit_id,
         pernr        TYPE ze_pernr,
         resign_date  TYPE datum,
         lwd_date     TYPE datum,
         overall_stat TYPE ze_clear_stat,
         status_icon  TYPE char4, " Stores SAP Icon String
         pending_dept TYPE text100,
       END OF ty_alv_out.

" Global Data Declarations
DATA: gt_exit_master TYPE TABLE OF zemp_exit,
      gs_exit_master TYPE zemp_exit,
      gt_alv_out     TYPE TABLE OF ty_alv_out,
      gs_alv_out     TYPE ty_alv_out.

" Data Declarations for Reuse ALV
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv.

"----------------------------------------------------------------------
" SELECTION SCREEN SETUP
"----------------------------------------------------------------------
TABLES: zemp_exit, zdept_clear.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: s_exitid FOR zemp_exit-exit_id,
                s_pernr  FOR zemp_exit-pernr,
                s_date   FOR zemp_exit-resign_date.
PARAMETERS:     p_stat   TYPE ze_clear_stat AS LISTBOX VISIBLE LENGTH 10 DEFAULT 'P'.
SELECTION-SCREEN END OF BLOCK b1.

"----------------------------------------------------------------------
" INITIALIZATION
"----------------------------------------------------------------------
INITIALIZATION.

"----------------------------------------------------------------------
" START-OF-SELECTION
"----------------------------------------------------------------------
START-OF-SELECTION.
  PERFORM fetch_data.
  PERFORM process_data.

"----------------------------------------------------------------------
" END-OF-SELECTION
"----------------------------------------------------------------------
END-OF-SELECTION.
  PERFORM build_fieldcatalog.
  PERFORM set_layout.
  PERFORM display_alv_grid.

*&---------------------------------------------------------------------*
*& Form FETCH_DATA
*&---------------------------------------------------------------------*
FORM fetch_data.
  REFRESH gt_exit_master.
  IF p_stat IS INITIAL.
    SELECT * FROM zemp_exit
      INTO TABLE gt_exit_master
      WHERE exit_id     IN s_exitid
        AND pernr       IN s_pernr
        AND resign_date IN s_date.
  ELSE.
    SELECT * FROM zemp_exit
      INTO TABLE gt_exit_master
      WHERE exit_id     IN s_exitid
        AND pernr       IN s_pernr
        AND resign_date IN s_date
        AND overall_stat = p_stat.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PROCESS_DATA
*&---------------------------------------------------------------------*
FORM process_data.
  DATA: lv_cleared TYPE char1,
        lv_depts   TYPE text100,
        lv_has_rej TYPE char1,
        ls_dept    TYPE zdept_clear.

  REFRESH gt_alv_out.

  LOOP AT gt_exit_master INTO gs_exit_master.
    CLEAR: gs_alv_out, lv_cleared, lv_depts, lv_has_rej, ls_dept.

    gs_alv_out-exit_id      = gs_exit_master-exit_id.
    gs_alv_out-pernr        = gs_exit_master-pernr.
    gs_alv_out-resign_date  = gs_exit_master-resign_date.
    gs_alv_out-lwd_date     = gs_exit_master-lwd_date.
    gs_alv_out-overall_stat = gs_exit_master-overall_stat.

    " Pure Classical SQL Query using work area target to eliminate strict mode checks
    SELECT SINGLE * FROM zdept_clear
      INTO ls_dept
      WHERE exit_id    = gs_exit_master-exit_id
        AND clear_stat = 'R'.

    IF sy-subrc = 0.
      lv_has_rej = 'X'.
    ENDIF.

    " Call Function Module to check clearance status
    CALL FUNCTION 'Z_FM_CHECK_CLEARANCE_STATUS'
      EXPORTING
        iv_exit_id       = gs_exit_master-exit_id
      IMPORTING
        ev_all_cleared   = lv_cleared
        ev_pending_depts = lv_depts
      EXCEPTIONS
        exit_not_found   = 1
        OTHERS           = 2.

    " Assign Standard LED Icons cleanly based on real-time clearance status
    IF lv_has_rej = 'X' OR gs_exit_master-overall_stat = 'R'.
      gs_alv_out-status_icon  = icon_led_red.     " Red LED for Rejection
      gs_alv_out-pending_dept = 'Clearance Rejected by Dept'.
    ELSEIF lv_cleared = 'X' OR gs_exit_master-overall_stat = 'C'.
      gs_alv_out-status_icon  = icon_led_green.   " Green LED for Cleared
      gs_alv_out-pending_dept = 'None (Fully Cleared)'.
    ELSE.
      gs_alv_out-status_icon = icon_led_yellow.   " Yellow LED for Pending
      IF lv_depts IS INITIAL.
        gs_alv_out-pending_dept = 'HR, IT, Finance, Assets (Pending)'.
      ELSE.
        gs_alv_out-pending_dept = lv_depts.
      ENDIF.
    ENDIF.

    APPEND gs_alv_out TO gt_alv_out.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
FORM build_fieldcatalog.
  REFRESH gt_fieldcat.

  " Column 1: Status Icon
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'STATUS_ICON'.
  gs_fieldcat-seltext_m = 'Status'.
  gs_fieldcat-icon      = 'X'. " Display as ALV Icon Column
  gs_fieldcat-col_pos   = 1.
  APPEND gs_fieldcat TO gt_fieldcat.

  " Column 2: Exit ID
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'EXIT_ID'.
  gs_fieldcat-seltext_m = 'Exit Request ID'.
  gs_fieldcat-key       = 'X'.
  gs_fieldcat-col_pos   = 2.
  APPEND gs_fieldcat TO gt_fieldcat.

  " Column 3: Personnel Number
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'PERNR'.
  gs_fieldcat-seltext_m = 'Employee No'.
  gs_fieldcat-col_pos   = 3.
  APPEND gs_fieldcat TO gt_fieldcat.

  " Column 4: Resignation Date
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'RESIGN_DATE'.
  gs_fieldcat-seltext_m = 'Resignation Date'.
  gs_fieldcat-col_pos   = 4.
  APPEND gs_fieldcat TO gt_fieldcat.

  " Column 5: Last Working Day
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'LWD_DATE'.
  gs_fieldcat-seltext_m = 'Last Working Day'.
  gs_fieldcat-col_pos   = 5.
  APPEND gs_fieldcat TO gt_fieldcat.

  " Column 6: Pending Departments
  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'PENDING_DEPT'.
  gs_fieldcat-seltext_m = 'Pending Dept Clearances'.
  gs_fieldcat-col_pos   = 6.
  APPEND gs_fieldcat TO gt_fieldcat.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_LAYOUT
*&---------------------------------------------------------------------*
FORM set_layout.
  CLEAR gs_layout.
  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV_GRID
*&---------------------------------------------------------------------*
FORM display_alv_grid.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat
    TABLES
      t_outtab                = gt_alv_out
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form USER_COMMAND (Interactive Double-Click Event)
*&---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  IF r_ucomm = '&IC1'.
    READ TABLE gt_alv_out INTO gs_alv_out INDEX rs_selfield-tabindex.
    IF sy-subrc = 0.
      MESSAGE i000(83) WITH 'Selected Exit ID:' gs_alv_out-exit_id.
    ENDIF.
  ENDIF.
ENDFORM.
