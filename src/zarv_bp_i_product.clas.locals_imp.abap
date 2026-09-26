CLASS lcl_custom_text_msg DEFINITION INHERITING FROM cx_no_check.
  PUBLIC SECTION.
    INTERFACES if_abap_behv_message.
    INTERFACES if_t100_message.

    DATA mv_text TYPE string.

    METHODS constructor
      IMPORTING
        iv_text     TYPE string
        is_severity TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error.

    METHODS if_message~get_text REDEFINITION.
ENDCLASS.

CLASS lcl_custom_text_msg IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_text = iv_text.
    if_abap_behv_message~m_severity = is_severity.

    DATA(lo_msg) = CAST if_abap_behv_message( me ).

    ASSIGN lo_msg->('V1') TO FIELD-SYMBOL(<lv_v1>).
    IF sy-subrc <> 0.
      ASSIGN lo_msg->('M_V1') TO <lv_v1>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN lo_msg->('MV_V1') TO <lv_v1>.
    ENDIF.

    ASSIGN lo_msg->('V2') TO FIELD-SYMBOL(<lv_v2>).
    IF sy-subrc <> 0.
      ASSIGN lo_msg->('M_V2') TO <lv_v2>.
    ENDIF.
    IF sy-subrc <> 0.
      ASSIGN lo_msg->('MV_V2') TO <lv_v2>.
    ENDIF.

    if_t100_message~t100key = VALUE #(
      msgid = '00'
      msgno = '001'
      attr1 = COND #( WHEN <lv_v1> IS ASSIGNED THEN 'IF_ABAP_BEHV_MESSAGE~V1' )
      attr2 = COND #( WHEN <lv_v2> IS ASSIGNED THEN 'IF_ABAP_BEHV_MESSAGE~V2' )
    ).

    IF if_t100_message~t100key-attr1 IS INITIAL.
      if_t100_message~t100key-attr1 = 'IF_ABAP_BEHV_MESSAGE~M_V1'.
      if_t100_message~t100key-attr2 = 'IF_ABAP_BEHV_MESSAGE~M_V2'.
    ENDIF.

    DATA(lv_len) = numofchar( iv_text ).

    IF lv_len <= 50.
      IF <lv_v1> IS ASSIGNED.
        <lv_v1> = substring( val = iv_text off = 0 len = lv_len ).
      ENDIF.
    ELSE.
      IF <lv_v1> IS ASSIGNED.
        <lv_v1> = substring( val = iv_text off = 0 len = 50 ).
      ENDIF.
      IF <lv_v2> IS ASSIGNED.
        <lv_v2> = substring( val = iv_text off = 50 len = lv_len - 50 ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD if_message~get_text.
    result = mv_text.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR Product RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR Product RESULT result.

    " Dynamic feature control handler to enable/disable buttons
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Product RESULT result.

    METHODS make_copy FOR MODIFY
       keys FOR ACTION Product~make_copy RESULT result.

    METHODS move_to_next_phase FOR MODIFY
       keys FOR ACTION Product~move_to_next_phase RESULT result.

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
    METHODS get_pgname_transl FOR MODIFY
       keys FOR ACTION Product~get_pgname_transl RESULT result.

    METHODS set_pgname_translation FOR DETERMINE ON SAVE
       keys FOR Product~set_pgname_translation.

    METHODS call_google_translate
      IMPORTING iv_text         TYPE string
                iv_target_lang  TYPE string
      RETURNING VALUE(rv_trans) TYPE string.

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      FIELDS ( Phaseid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products).

    result = VALUE #( FOR ls_key IN keys
      LET ls_prod = VALUE #( lt_products[ %tky = ls_key-%tky ] OPTIONAL ) IN
      (
        %tky = ls_key-%tky

        %action-move_to_next_phase = COND #(
          WHEN ls_prod-Phaseid = 'OUT'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )

        %field-prodid = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

         %field-pgid = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

        %field-price = COND #(
          WHEN ls_prod-Phaseid = 'PROD' OR ls_prod-Phaseid = 'OUT' THEN if_abap_behv=>fc-f-read_only
          WHEN ls_prod-Phaseid = 'DEV' THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-unrestricted
        )

        %field-currency = COND #(
          WHEN ls_prod-Phaseid = 'PROD' OR ls_prod-Phaseid = 'OUT' THEN if_abap_behv=>fc-f-read_only
          WHEN ls_prod-Phaseid = 'DEV' THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-unrestricted
        )

        %field-height = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-unrestricted
          WHEN ls_prod-Phaseid = 'DEV'  THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

        %field-depth = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-unrestricted
          WHEN ls_prod-Phaseid = 'DEV'  THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

        %field-width = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-unrestricted
          WHEN ls_prod-Phaseid = 'DEV'  THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

        %field-sizeuom = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-unrestricted
          WHEN ls_prod-Phaseid = 'DEV'  THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )

        %field-taxrate = COND #(
          WHEN ls_prod-Phaseid = 'PLAN' THEN if_abap_behv=>fc-f-unrestricted
          WHEN ls_prod-Phaseid = 'DEV'  THEN if_abap_behv=>fc-f-mandatory
          ELSE if_abap_behv=>fc-f-read_only
        )
      )
    ).
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

      " Generate new temporary UUID beforehand to guarantee proper mapping identification
      TRY.
          ls_create_product-ProdUuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
          CONTINUE.
      ENDTRY.

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
        CREATE FIELDS ( ProdUuid Prodid Pgid Phaseid Height Depth Width Price Currency Taxrate )
        WITH lt_create_products
        MAPPED DATA(lt_mapped)
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

      " Transfer errors and messages to global RAP handler structures
      failed   = CORRESPONDING #( DEEP lt_failed ).
      reported = CORRESPONDING #( DEEP lt_reported ).

      " Read the freshly created instances back from the transactional buffer
      IF lt_mapped-product IS NOT INITIAL.
        READ ENTITIES OF zarv_i_product IN LOCAL MODE
          ENTITY Product
          ALL FIELDS WITH CORRESPONDING #( lt_mapped-product )
          RESULT DATA(lt_read_created).
      ENDIF.

      " 4. Fill the RESULT table to update the UI
      LOOP AT lt_create_products ASSIGNING FIELD-SYMBOL(<ls_created>).
        DATA(lv_current_index) = sy-tabix.

        " Find the key mapping for the processed instance
        READ TABLE lt_mapped-product ASSIGNING FIELD-SYMBOL(<ls_map>)
          WITH KEY %cid = <ls_created>-%cid.

        IF sy-subrc = 0 AND <ls_map> IS ASSIGNED.

          " Find the detailed created data from our buffer read
          READ TABLE lt_read_created ASSIGNING FIELD-SYMBOL(<ls_created_data>)
            WITH KEY ProdUuid = <ls_map>-ProdUuid.

          IF sy-subrc = 0 AND <ls_created_data> IS ASSIGNED.

            " Find the initial key for result mapping
            READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_orig_key>)
              WITH KEY %cid_ref = <ls_created>-%cid.

            IF sy-subrc <> 0.
              READ TABLE keys ASSIGNING <ls_orig_key> INDEX lv_current_index.
            ENDIF.

            IF <ls_orig_key> IS ASSIGNED.
              APPEND VALUE #(
                %tky   = <ls_orig_key>-%tky
                %param = CORRESPONDING #( <ls_created_data> )
              ) TO result.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD move_to_next_phase.
    " 1. Read the current data of selected instances
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products)
      FAILED DATA(lt_read_failed).

    failed = CORRESPONDING #( DEEP lt_read_failed ).
    IF lt_products IS INITIAL.
      RETURN.
    ENDIF.

    " NEW STEP: Read all associated Markets for the processed products
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      BY \_Market
      ALL FIELDS WITH CORRESPONDING #( lt_products )
      RESULT DATA(lt_all_markets).

    DATA lt_update_products TYPE TABLE FOR UPDATE zarv_i_product.
    DATA ls_update_product  LIKE LINE OF lt_update_products.

    " 2. Process workflow rules for each product
    LOOP AT lt_products ASSIGNING FIELD-SYMBOL(<ls_prod>).
      CLEAR ls_update_product.
      DATA(lv_error_text) = ``.

      " Safe and universal way to filter markets for the current product
      DATA lt_prod_markets LIKE lt_all_markets.
      CLEAR lt_prod_markets.

      LOOP AT lt_all_markets ASSIGNING FIELD-SYMBOL(<ls_m>) WHERE ProdUuid = <ls_prod>-ProdUuid.
        APPEND <ls_m> TO lt_prod_markets.
      ENDLOOP.

      CASE <ls_prod>-Phaseid.

        WHEN 'PLAN'.
          " --- Rule 1: Move from PLAN to DEV ---
          " Check: A product must have at least one assigned Market.
          IF lt_prod_markets IS NOT INITIAL.
            ls_update_product-%tky    = <ls_prod>-%tky.
            ls_update_product-Phaseid = 'DEV'.
          ELSE.
            lv_error_text = |Product must have at least one assigned Market to move to Development|.
          ENDIF.

        WHEN 'DEV'.
          " --- Rule 2: Move from DEV to PROD ---
          " Check: At least one market of the product must be confirmed.
          " (Change 'X' or 'CONFIRMED' depending on what value your status field stores)
          IF line_exists( lt_prod_markets[ Status = 'X' ] ) OR line_exists( lt_prod_markets[ Status = 'CONFIRMED' ] ).
            ls_update_product-%tky    = <ls_prod>-%tky.
            ls_update_product-Phaseid = 'PROD'.
          ELSE.
            lv_error_text = |At least one market of the product must be confirmed to move to Production|.
          ENDIF.

        WHEN 'PROD'.
          " --- Rule 3: Move from PROD to OUT ---
          " Check: All markets must be completed (End Date <= today's date).
          " If any market has Enddate > today or initial, the check fails.
          DATA(lv_has_active_markets) = abap_false.
          LOOP AT lt_prod_markets ASSIGNING FIELD-SYMBOL(<ls_mrkt>).
            IF <ls_mrkt>-Enddate IS INITIAL OR <ls_mrkt>-Enddate > sy-datum.
              lv_has_active_markets = abap_true.
              EXIT.
            ENDIF.
          ENDLOOP.

          IF lt_prod_markets IS NOT INITIAL AND lv_has_active_markets = abap_false.
            ls_update_product-%tky    = <ls_prod>-%tky.
            ls_update_product-Phaseid = 'OUT'.
          ELSEIF lt_prod_markets IS INITIAL.
            lv_error_text = |Cannot phase out a product with no markets assigned|.
          ELSE.
            lv_error_text = |All markets must be completed (End Date <= Today) to phase out the product|.
          ENDIF.

        WHEN OTHERS.
          CONTINUE.
      ENDCASE.

      " 3. If validation failed, block transaction and report message to UI
      IF lv_error_text IS NOT INITIAL.
        APPEND VALUE #( %tky = <ls_prod>-%tky ) TO failed-Product.

        APPEND VALUE #(
          %tky = <ls_prod>-%tky
          %msg = NEW lcl_custom_text_msg( iv_text = lv_error_text )

          %element-Phaseid = if_abap_behv=>mk-on
        ) TO reported-Product.

        " Otherwise, collect for update
      ELSEIF ls_update_product-%tky IS NOT INITIAL.
        APPEND ls_update_product TO lt_update_products.
      ENDIF.

    ENDLOOP.

    " 4. Apply new phases to database buffer
    IF lt_update_products IS NOT INITIAL.
      MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
        ENTITY Product
        UPDATE FIELDS ( Phaseid )
        WITH lt_update_products
        FAILED DATA(lt_mod_failed)
        REPORTED DATA(lt_mod_reported).

      failed   = CORRESPONDING #( DEEP lt_mod_failed ).
      reported = CORRESPONDING #( DEEP lt_mod_reported ).
    ENDIF.

    " 5. Read back modified data to refresh the Fiori UI properly
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_refreshed_products).

    LOOP AT lt_refreshed_products ASSIGNING FIELD-SYMBOL(<ls_refresh>).
      APPEND VALUE #(
        %tky   = <ls_refresh>-%tky
        %param = CORRESPONDING #( <ls_refresh> )
      ) TO result.
    ENDLOOP.
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

    LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<ls_prod>).
      "Generate UUID only if initial
      IF <ls_prod>-ProdUuid IS INITIAL.
        CLEAR ls_upd.
        TRY.
            ls_upd-ProdUuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
            CONTINUE.
        ENDTRY.
        "Use %tky to address instances during create
        ls_upd-%tky = <ls_prod>-%tky.
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

    LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<ls_prod>).
      "Set default phase only on create (when Phaseid is initial)
      IF <ls_prod>-Phaseid IS INITIAL.
        CLEAR ls_upd.
        ls_upd-%tky    = <ls_prod>-%tky.
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
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
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

    LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<ls_prod>).
      IF <ls_prod>-Pgid IS INITIAL.
        CONTINUE.
      ENDIF.

      READ TABLE lt_exist TRANSPORTING NO FIELDS WITH KEY pgid = <ls_prod>-Pgid.
      IF sy-subrc <> 0.
        "Block save for this instance
        APPEND VALUE #( %tky = <ls_prod>-%tky ) TO failed-Product.

        "Return message to UI
        APPEND VALUE #(
          %tky = <ls_prod>-%tky
          %msg = new_message(
                   id       = '00'
                   number   = '001'
                   severity = if_abap_behv_message=>severity-error
                   v1       = |Unknown Product Group (PGID): { <ls_prod>-Pgid }| )
          %element-Pgid = if_abap_behv=>mk-on
        ) TO reported-Product.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateprodid.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      FIELDS ( Prodid ProdUuid )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_prod).

    LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<ls_prod>).
      IF <ls_prod>-Prodid IS INITIAL.
        CONTINUE.
      ENDIF.

      SELECT SINGLE prod_uuid
        FROM zarv_d_product
        WHERE prodid = @<ls_prod>-Prodid
          AND prod_uuid <> @<ls_prod>-ProdUuid
        INTO @DATA(lv_other).

      IF sy-subrc = 0.
        APPEND VALUE #( %tky = <ls_prod>-%tky ) TO failed-Product.

        APPEND VALUE #(
          %tky = <ls_prod>-%tky
          %msg = new_message(
                   id       = '00'
                   number   = '001'
                   severity = if_abap_behv_message=>severity-error
                   v1       = |Duplicate Product ID: { <ls_prod>-Prodid }| )
          %element-Prodid = if_abap_behv=>mk-on
        ) TO reported-Product.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatecurrency.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
      FIELDS ( Currency )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky ) )
      RESULT DATA(lt_prod).

    LOOP AT lt_prod ASSIGNING FIELD-SYMBOL(<ls_prod>).
      IF <ls_prod>-Currency IS INITIAL.
        APPEND VALUE #( %tky = <ls_prod>-%tky ) TO failed-Product.

        APPEND VALUE #(
          %tky = <ls_prod>-%tky
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

  METHOD set_pgname_translation.
    " 1. Read ProdUuid, Pgid, and TransCode for the instances being saved
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
        FIELDS ( Pgid TransCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products).

    DATA lt_update TYPE TABLE FOR UPDATE zarv_i_product.

    LOOP AT lt_products ASSIGNING FIELD-SYMBOL(<ls_product>).
      IF <ls_product>-Pgid IS NOT INITIAL AND <ls_product>-TransCode IS NOT INITIAL.

        " 2. Read the source English text directly from the database table
        DATA lv_pgname TYPE string.
        SELECT SINGLE pgname
          FROM zarv_d_pr_group
          WHERE pgid = @<ls_product>-Pgid
          INTO @lv_pgname.

        IF sy-subrc = 0 AND lv_pgname IS NOT INITIAL.
          " Call the integration with Google Translate API
          DATA(lv_translation) = me->call_google_translate(
                                   iv_text        = lv_pgname
                                   iv_target_lang = CONV string( <ls_product>-TransCode ) ).

          " Prepare the update structure for the translation field
          APPEND VALUE #( %tky        = <ls_product>-%tky
                          PgnameTrans = lv_translation ) TO lt_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " 3. Write the translation back to the transactional buffer before saving to DB
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
        ENTITY Product
          UPDATE FIELDS ( PgnameTrans ) WITH lt_update.
    ENDIF.
  ENDMETHOD.

  METHOD get_pgname_transl.
    " 1. Read data of the currently selected instance
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
        FIELDS ( Pgid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products).

    CHECK lt_products IS NOT INITIAL.
    " Read the first row of the table using index syntax to get a proper structure
    DATA(ls_product) = lt_products[ 1 ].

    " 2. Read the source English text directly from the database table
    DATA lv_source_text TYPE string.
    SELECT SINGLE pgname
      FROM zarv_d_pr_group
      WHERE pgid = @ls_product-Pgid
      INTO @lv_source_text.

    CHECK sy-subrc = 0 AND lv_source_text IS NOT INITIAL.

    " 3. Target languages list strictly according to the task requirements (RU, DE, EN, ES, FR)
    DATA(lt_languages) = VALUE string_table( ( `RU` ) ( `DE` ) ( `EN` ) ( `ES` ) ( `FR` ) ).

    LOOP AT lt_languages INTO DATA(lv_lang).
      " Request the translation from Google API
      DATA(lv_trans) = me->call_google_translate( iv_text = lv_source_text iv_target_lang = lv_lang ).

      " Format the message string exactly as shown in the layout mockup
      DATA(lv_msg) = |Translation on { lv_lang } is '{ lv_trans }'|.

      " 4. Pass information messages to display them in the Fiori dialog
      APPEND VALUE #( %tky = ls_product-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-information
                               text     = lv_msg )
                    ) TO reported-product.
    ENDLOOP.

    " Return the instance back to the framework
    APPEND VALUE #( %tky = ls_product-%tky %param = ls_product ) TO result.
  ENDMETHOD.

  METHOD call_google_translate.
    TRY.
        " Create HTTP client directly to the Google Translate endpoint verified in ReqBin
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
          cl_http_destination_provider=>create_by_url( 'https://translate.googleapis.com/translate_a/single') ).

        DATA(lo_request) = lo_http_client->get_http_request( ).

        " Pass all query parameters as a single string according to your system syntax
        lo_request->set_query( |client=gtx&dt=t&sl=en&tl={ to_lower( iv_target_lang ) }&q={ iv_text }| ).

        DATA(lo_response) = lo_http_client->execute( if_web_http_client=>get ).
        DATA(lo_json) = lo_response->get_text( ).

        " Parse the simple Google array response by looking for quotation marks
        IF lo_json CS '"'.
          SPLIT lo_json AT '"' INTO DATA(lv_dummy1) rv_trans DATA(lv_dummy2).
        ENDIF.

      CATCH cx_root.
        rv_trans = 'Error'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


