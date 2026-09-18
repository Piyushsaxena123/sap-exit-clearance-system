FUNCTION z_fm_check_clearance_status.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_EXIT_ID) TYPE  ZE_EXIT_ID
*"  EXPORTING
*"     VALUE(EV_ALL_CLEARED) TYPE  CHAR1
*"     VALUE(EV_PENDING_DEPTS) TYPE  TEXT100
*"  EXCEPTIONS
*"      EXIT_NOT_FOUND
*"----------------------------------------------------------------------

  DATA: lt_clear TYPE TABLE OF zdept_clear,
        ls_clear TYPE zdept_clear,
        lv_count TYPE i VALUE 0,
        lv_dept_str TYPE string.

  FIELD-SYMBOLS: <fs_stat> TYPE any,
                 <fs_dept> TYPE any.

  CLEAR: ev_all_cleared, ev_pending_depts.

  " 1. Read department clearance records for this Exit ID
  SELECT * FROM zdept_clear
    INTO TABLE lt_clear
    WHERE exit_id = iv_exit_id.

  IF sy-subrc <> 0.
    RAISE exit_not_found.
  ENDIF.

  " 2. Evaluate clearance status dynamically
  LOOP AT lt_clear INTO ls_clear.

    " Assign clearance status field
    ASSIGN COMPONENT 'CLEAR_STAT' OF STRUCTURE ls_clear TO <fs_stat>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'CLEARANCE_STAT' OF STRUCTURE ls_clear TO <fs_stat>.
    ENDIF.

    " Assign department name/ID field
    ASSIGN COMPONENT 'DEPT_NAME' OF STRUCTURE ls_clear TO <fs_dept>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'DEPT' OF STRUCTURE ls_clear TO <fs_dept>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'DEPARTMENT' OF STRUCTURE ls_clear TO <fs_dept>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'DEPT_ID' OF STRUCTURE ls_clear TO <fs_dept>.
    ENDIF.

    " If non-cleared / pending ('P' or blank), append department
    IF <fs_stat> IS ASSIGNED AND <fs_stat> <> 'C' AND <fs_stat> <> 'A'.
      IF <fs_dept> IS ASSIGNED.
        lv_dept_str = <fs_dept>.
        IF ev_pending_depts IS INITIAL.
          ev_pending_depts = lv_dept_str.
        ELSE.
          CONCATENATE ev_pending_depts ',' lv_dept_str
            INTO ev_pending_depts SEPARATED BY space.
        ENDIF.
      ENDIF.
      lv_count = lv_count + 1.
    ENDIF.

  ENDLOOP.

  " 3. Final clearance status determination
  IF lv_count = 0.
    ev_all_cleared = 'X'.
    ev_pending_depts = 'None (Fully Cleared)'.
  ELSE.
    ev_all_cleared = ' '.
  ENDIF.

ENDFUNCTION.
