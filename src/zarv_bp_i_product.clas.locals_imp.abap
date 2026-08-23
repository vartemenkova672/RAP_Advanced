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

    METHODS validateCurrency FOR VALIDATE ON SAVE
      keys FOR Product~validateCurrency.

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

    METHOD make_copy.
    " 1. Read original data of selected instances for copying
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_original_products)
      FAILED DATA(lt_read_failed).

    " Transfer read errors if any occurred
    failed = CORRESPONDING #( DEEP lt_read_failed ).

    IF lt_original_products IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_create_products TYPE TABLE FOR CREATE zarv_i_product.
    DATA ls_create_product  LIKE LINE OF lt_create_products.

    " 2. Process each instance to be copied
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      " Find original data for the current key
      READ TABLE lt_original_products ASSIGNING FIELD-SYMBOL(<ls_orig>)
        WITH KEY %tky = <ls_key>-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CLEAR ls_create_product.

      " Fill create structure with original data
      ls_create_product = CORRESPONDING #( <ls_orig> ).

      " Reset system and key fields that must be regenerated
      CLEAR: ls_create_product-ProdUuid,
             ls_create_product-Createdby,
             ls_create_product-Creationtime,
             ls_create_product-Changedby,
             ls_create_product-Changetime.

      " Pass the new Product ID entered by the user in the UI dialog
      ls_create_product-Prodid = <ls_key>-%param-prodid.

      " Set default phase for the new copy instance
      ls_create_product-Phaseid = 'PLAN'.

      " %cid_ref is a temporary unique identifier linking instances during the transaction
      ls_create_product-%cid = <ls_key>-%cid_ref.
      IF ls_create_product-%cid IS INITIAL.
        ls_create_product-%cid = |COPY_{ sy-tabix }_{ cl_uuid_factory=>create_system_uuid( )->create_uuid_c32( ) }|.
      ENDIF.

      APPEND ls_create_product TO lt_create_products.
    ENDLOOP.

    " 3. Create new product instances in the database
    IF lt_create_products IS NOT INITIAL.
      MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
        ENTITY Product
        CREATE FIELDS ( Prodid Pgid Phaseid Height Depth Width Price Currency Taxrate )
        WITH lt_create_products
        MAPPED DATA(lt_mapped)
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      " Transfer errors and messages to global RAP handler structures
      failed   = CORRESPONDING #( DEEP lt_failed ).
      reported = CORRESPONDING #( DEEP lt_reported ).

      " 4. Fill the RESULT table to update the UI
      " This is critical for Fiori Elements to know which new instance to display
      LOOP AT lt_create_products ASSIGNING FIELD-SYMBOL(<ls_created>).

        " Find the generated UUID in the MAPPED structure
        READ TABLE lt_mapped-product ASSIGNING FIELD-SYMBOL(<ls_map>)
          WITH KEY %cid = <ls_created>-%cid.
        IF sy-subrc = 0.

          " Find the initial key for result mapping
          READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_orig_key>) WITH KEY %cid_ref = <ls_created>-%cid.
          IF sy-subrc <> 0.
            READ TABLE keys ASSIGNING <ls_orig_key> INDEX sy-tabix. " Fallback by index
          ENDIF.

          APPEND VALUE #(
            %tky   = <ls_orig_key>-%tky          " Original instance
            %param = CORRESPONDING #( <ls_map> ) " New created instance (returns $self)
          ) TO result.

        ENDIF.
      ENDLOOP.
    ENDIF.
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

METHOD validatecurrency.

  READ ENTITIES OF zarv_i_product IN LOCAL MODE
    ENTITY Product
    FIELDS ( Currency )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_prod).

  LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<p>).
    IF <p>-Currency IS INITIAL.

      APPEND VALUE #( %tky = <p>-%tky ) TO failed-Product.

      APPEND VALUE #(
        %tky = <p>-%tky
        %msg = new_message(
                 id       = '00'
                 number   = '001'
                 severity = if_abap_behv_message=>severity-error
                 v1       = |Currency is mandatory| )
        %element-Currency = if_abap_behv=>mk-on
      ) TO reported-Product.

    ENDIF.
  ENDLOOP.

ENDMETHOD.

ENDCLASS.
