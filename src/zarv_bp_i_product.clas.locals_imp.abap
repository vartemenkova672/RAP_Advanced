CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Product RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Product RESULT result.

    METHODS make_copy FOR MODIFY
       keys FOR ACTION Product~make_copy RESULT result.

    METHODS calculateProdUUID FOR DETERMINE ON MODIFY
       keys FOR Product~calculateProdUUID.

    METHODS setFirstPhase FOR DETERMINE ON MODIFY
       keys FOR Product~setFirstPhase.

    METHODS validatePG FOR VALIDATE ON SAVE
       keys FOR Product~validatePG.

    METHODS validateProdID FOR VALIDATE ON SAVE
       keys FOR Product~validateProdID.

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD make_copy.
  ENDMETHOD.

METHOD calculateproduuid.

  "Read affected Product instances
  READ ENTITIES OF zarv_i_product IN LOCAL MODE
    ENTITY Product
    FIELDS ( ProdUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_prod).

  "Prepare update table for Product
  DATA lt_upd TYPE TABLE FOR UPDATE zarv_i_product.
  DATA ls_upd LIKE LINE OF lt_upd.

  LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<p>).

    "Generate UUID only if initial
    IF <p>-ProdUuid IS INITIAL.

      CLEAR ls_upd.

      TRY.
          ls_upd-ProdUuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
          "No messaging possible here in this release (no FAILED/REPORTED tables in determinations)
          "If UUID generation fails, we simply skip this instance.
          CONTINUE.
      ENDTRY.

      "Use %tky to address instances during create
      ls_upd-%tky = <p>-%tky.
      APPEND ls_upd TO lt_upd.

    ENDIF.
  ENDLOOP.

  "Persist calculated UUIDs
  IF lt_upd IS NOT INITIAL.
    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      UPDATE FIELDS ( ProdUuid )
      WITH lt_upd.
  ENDIF.

ENDMETHOD.

METHOD setfirstphase.

  "Read current instances
  READ ENTITIES OF zarv_i_product IN LOCAL MODE
    ENTITY Product
    FIELDS ( Phaseid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_prod).

  DATA lt_upd TYPE TABLE FOR UPDATE zarv_i_product.
  DATA ls_upd LIKE LINE OF lt_upd.

  LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<p>).

    "Set default phase only on create (when Phaseid is initial)
    IF <p>-Phaseid IS INITIAL.
      CLEAR ls_upd.
      ls_upd-%tky    = <p>-%tky.
      ls_upd-Phaseid = 'PLAN'.
      APPEND ls_upd TO lt_upd.
    ENDIF.

  ENDLOOP.

  IF lt_upd IS NOT INITIAL.
    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      UPDATE FIELDS ( Phaseid )
      WITH lt_upd.
  ENDIF.

ENDMETHOD.

 METHOD validatepg.

  "Read PGID from current instances
  READ ENTITIES OF zarv_i_product IN LOCAL MODE
    ENTITY Product
    FIELDS ( Pgid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_prod).

  IF lt_prod IS INITIAL.
    RETURN.
  ENDIF.

  "Collect unique PGIDs
  DATA lt_pgid TYPE SORTED TABLE OF sysuuid_x16 WITH UNIQUE KEY table_line.
  lt_pgid = VALUE #( FOR p IN lt_prod WHERE ( Pgid IS NOT INITIAL ) ( p-Pgid ) ).

  "Read existing product groups
  SELECT pgid
    FROM zarv_d_pr_group
    FOR ALL ENTRIES IN @lt_pgid
    WHERE pgid = @lt_pgid-table_line
    INTO TABLE @DATA(lt_exist).
  SORT lt_exist BY pgid.

  LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<p>).

    IF <p>-Pgid IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE lt_exist TRANSPORTING NO FIELDS WITH KEY pgid = <p>-Pgid.
    IF sy-subrc <> 0.

      "Block save for this instance
      APPEND VALUE #( %tky = <p>-%tky ) TO failed-Product.

      "Return message to UI
      APPEND VALUE #(
        %tky = <p>-%tky
        %msg = new_message(
                 id       = '00'
                 number   = '001'
                 severity = if_abap_behv_message=>severity-error
                 v1       = |Unknown Product Group (PGID): { <p>-Pgid }| )
        %element-Pgid = if_abap_behv=>mk-on
      ) TO reported-Product.

    ENDIF.
  ENDLOOP.

ENDMETHOD.

 METHOD validateprodid.

  READ ENTITIES OF zarv_i_product IN LOCAL MODE
    ENTITY Product
    FIELDS ( Prodid ProdUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_prod).

  LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<p>).
    IF <p>-Prodid IS INITIAL.
      CONTINUE.
    ENDIF.

    SELECT SINGLE prod_uuid
      FROM zarv_d_product
      WHERE prodid = @<p>-Prodid
        AND prod_uuid <> @<p>-ProdUuid
      INTO @DATA(lv_other).

    IF sy-subrc = 0.
      APPEND VALUE #( %tky = <p>-%tky ) TO failed-Product.

      APPEND VALUE #(
        %tky = <p>-%tky
        %msg = new_message(
                 id       = '00'
                 number   = '001'
                 severity = if_abap_behv_message=>severity-error
                 v1       = |Duplicate Product ID: { <p>-Prodid }| )
        %element-Prodid = if_abap_behv=>mk-on
      ) TO reported-Product.
    ENDIF.
  ENDLOOP.

ENDMETHOD.

ENDCLASS.
