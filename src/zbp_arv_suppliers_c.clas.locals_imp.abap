*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ts_buffer,
             supplier_id   TYPE i,
             discount_pct  TYPE p LENGTH 2 DECIMALS 1,
             lastchangedat TYPE timestampl,
             is_updated    TYPE abap_bool,
           END OF ts_buffer.

    TYPES tt_buffer TYPE SORTED TABLE OF ts_buffer WITH UNIQUE KEY supplier_id.

    CLASS-DATA mt_buffer TYPE tt_buffer.
ENDCLASS.

CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Suppliers RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Suppliers.

    METHODS read FOR READ
      IMPORTING keys FOR READ Suppliers RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Suppliers.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD read.
    " Ensure we read incoming transactional requests cleanly for Fiori elements
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).

      " Map the key fields directly to the response structure
      MOVE-CORRESPONDING <ls_key> TO <ls_result>.

      " Dynamically read transactional local buffer or fetch database snapshot
      READ TABLE lcl_buffer=>mt_buffer ASSIGNING FIELD-SYMBOL(<ls_buf>)
        WITH KEY supplier_id = <ls_key>-supplier_id.
      IF sy-subrc = 0.
        <ls_result>-discount_pct  = <ls_buf>-discount_pct.
        <ls_result>-lastchangedat = <ls_buf>-lastchangedat.
      ELSE.
        SELECT SINGLE discount_pct, lastchangedat
          FROM zarv_suppladd
          WHERE supplierid = @<ls_key>-supplier_id
          INTO (@<ls_result>-discount_pct, @<ls_result>-lastchangedat).
        IF sy-subrc <> 0.
          <ls_result>-discount_pct = '0.0'.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA ls_new_buf LIKE LINE OF lcl_buffer=>mt_buffer.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      READ TABLE lcl_buffer=>mt_buffer ASSIGNING FIELD-SYMBOL(<ls_buf>)
        WITH KEY supplier_id = <ls_entity>-supplier_id.
      IF sy-subrc <> 0.
        " Safely instantiate a new buffer record using a local structure
        CLEAR ls_new_buf.
        ls_new_buf-supplier_id = <ls_entity>-supplier_id.

        SELECT SINGLE lastchangedat
          FROM zarv_suppladd
          WHERE supplierid = @<ls_entity>-supplier_id
          INTO @ls_new_buf-lastchangedat.

        " Insert the complete record into the sorted buffer table
        INSERT ls_new_buf INTO TABLE lcl_buffer=>mt_buffer ASSIGNING <ls_buf>.
      ENDIF.

      " Update the modified discount field and flag record as dirty
      IF <ls_entity>-%control-discount_pct = if_abap_behv=>mk-on.
        <ls_buf>-discount_pct = <ls_entity>-discount_pct.
        <ls_buf>-is_updated   = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


ENDCLASS.

CLASS lcl_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.
ENDCLASS.

CLASS lcl_saver IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DATA lt_db_update TYPE TABLE OF zarv_suppladd.
    DATA lv_timestamp TYPE timestampl.

    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT lcl_buffer=>mt_buffer ASSIGNING FIELD-SYMBOL(<ls_buf_save>) WHERE is_updated = abap_true.
      APPEND INITIAL LINE TO lt_db_update ASSIGNING FIELD-SYMBOL(<ls_db>).
      <ls_db>-client        = sy-mandt.
      <ls_db>-supplierid    = <ls_buf_save>-supplier_id.
      <ls_db>-discount_pct  = <ls_buf_save>-discount_pct.
      <ls_db>-lastchangedat = lv_timestamp.
    ENDLOOP.

    IF lt_db_update IS NOT INITIAL.
      MODIFY zarv_suppladd FROM TABLE @lt_db_update.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>mt_buffer.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

