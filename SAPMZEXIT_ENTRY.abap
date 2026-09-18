*&---------------------------------------------------------------------*
*& Module Pool      SAPMZEXIT_ENTRY
*&---------------------------------------------------------------------*
*&
*&----------------------------------------------------------------------*
PROGRAM SAPMZEXIT_ENTRY.

TABLES: zemp_exit, zdept_clear, zemp_dues.

" Global Screen Work Areas & OK_CODE
DATA: gv_pernr      TYPE ze_pernr,
      gv_exit_id    TYPE ze_exit_id,
      gv_ok_code100 TYPE sy-ucomm.

INCLUDE mzexit_entry_pbo_0100o01.

INCLUDE mzexit_entry_pai_0100i01.