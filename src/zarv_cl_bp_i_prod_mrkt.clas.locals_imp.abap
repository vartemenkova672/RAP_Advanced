CLASS lhc_Market DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Market RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Market RESULT result.

    METHODS confirmMarketByProduct FOR MODIFY
      IMPORTING keys FOR ACTION Market~confirmMarketByProduct RESULT result.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Market~setInitialStatus.

    METHODS validateMarket FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validateMarket.

    METHODS validateStartDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validateStartDate.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~validateDates.

    METHODS checkDuplicates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Market~checkDuplicates.

ENDCLASS.

CLASS lhc_Market IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    " 1. Read current status of the selected markets
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    " 2. Dynamic features control: disable button if already confirmed ('Yes' / 'C')
    result = VALUE #( FOR ls_market IN lt_markets (
      %tky = ls_market-%tky
      %action-confirmMarketByProduct = COND #(
        WHEN ls_market-Status = 'C' OR ls_market-Status = 'Yes'
        THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled
      )
    ) ).
  ENDMETHOD.

 METHOD confirmMarketByProduct.
    " FIXED: Modifying STATUS field to 'CONFIRMED' to match your database text format
    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'CONFIRMED' ) )
      REPORTED DATA(lt_reported).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated).

    result = VALUE #( FOR ls_upd IN lt_updated ( %tky = ls_upd-%tky %param = ls_upd ) ).
  ENDMETHOD.

   METHOD setInitialStatus.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Status Startdate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        UPDATE FIELDS ( Status Startdate )
        WITH VALUE #( FOR ls_market IN lt_markets (
          %tky      = ls_market-%tky
          " FIXED: Setting default status value to 'NEW' text string
          Status    = COND #( WHEN ls_market-Status IS INITIAL THEN 'NEW' ELSE ls_market-Status )
          Startdate = COND #( WHEN ls_market-Startdate IS INITIAL THEN cl_abap_context_info=>get_system_date( ) ELSE ls_market-Startdate )
        ) )
      REPORTED DATA(lt_reported).
  ENDMETHOD.

  METHOD validateStartDate.
    " VALIDATE_START_DATE: STARTDATE must be >= today's date
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Startdate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Startdate < lv_today.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          %tky        = ls_market-%tky
          %state_area = 'VALIDATE_START'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Start Date must be greater than today'
                        )
          %element-startdate = if_abap_behv=>mk-on
        ) TO reported-market.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

   METHOD validateMarket.
    " VALIDATE_MARKET: MRKTID value must be present and exist in SAP standard CDS view (I_Country)
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Mrktid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      " 1. Strict check for empty/blank values
      IF ls_market-Mrktid IS INITIAL OR condense( ls_market-Mrktid ) = ''.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          %tky        = ls_market-%tky
          %state_area = 'VALIDATE_MARKET_EMPTY'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Market ID is required and cannot be blank.'
                        )
          %element-mrktid = if_abap_behv=>mk-on
        ) TO reported-market.
      ENDIF.
    ENDLOOP.

    " 2. Existence check for non-empty values
    IF lt_markets IS NOT INITIAL.
      DATA lt_countries_to_check TYPE STANDARD TABLE OF I_Country WITH DEFAULT KEY.

      lt_countries_to_check = VALUE #( FOR ls_mrkt IN lt_markets WHERE ( Mrktid IS NOT INITIAL )
                                        ( Country = ls_mrkt-Mrktid ) ).

      IF lt_countries_to_check IS NOT INITIAL.
        SORT lt_countries_to_check BY Country.
        DELETE ADJACENT DUPLICATES FROM lt_countries_to_check COMPARING Country.

        SELECT Country FROM I_Country
          FOR ALL ENTRIES IN @lt_countries_to_check
          WHERE Country = @lt_countries_to_check-Country
          INTO TABLE @DATA(lt_valid_countries).
      ENDIF.

      LOOP AT lt_markets INTO ls_market.
        IF ls_market-Mrktid IS INITIAL.
          CONTINUE.
        ENDIF.

        IF NOT line_exists( lt_valid_countries[ Country = ls_market-Mrktid ] ).
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

          APPEND VALUE #(
            %tky        = ls_market-%tky
            %state_area = 'VALIDATE_MARKET'
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Market doesn''t exist'
                          )
            %element-mrktid = if_abap_behv=>mk-on
          ) TO reported-market.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD validateDates.
    " VALIDATE_END_DATE: if present, must be > today and STARTDATE
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Startdate Enddate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Enddate IS NOT INITIAL.
        " Check against today
        IF ls_market-Enddate <= lv_today.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #(
            %tky        = ls_market-%tky
            %state_area = 'VALIDATE_END_TODAY'
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'End Date must greater than today'
                          )
            %element-enddate = if_abap_behv=>mk-on
          ) TO reported-market.
          CONTINUE.
        ENDIF.

        " Check against Startdate
        IF ls_market-Enddate < ls_market-Startdate.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #(
            %tky        = ls_market-%tky
            %state_area = 'VALIDATE_END_START'
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'End Date must be greater than Start Date'
                          )
            %element-enddate = if_abap_behv=>mk-on
          ) TO reported-market.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

   METHOD checkDuplicates.
    " CHECK_DUPLICATES: product cannot have markets with the same MRKTID
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( ProdUuid Mrktid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Mrktid IS INITIAL.
        CONTINUE.
      ENDIF.

      READ ENTITIES OF zarv_i_product IN LOCAL MODE
        ENTITY Product BY \_Market
          FIELDS ( Mrktid ) WITH VALUE #( ( %tky-ProdUuid = ls_market-ProdUuid ) )
        RESULT DATA(lt_all_product_markets).

      DATA(lv_matches) = REDUCE i( INIT count = 0
                                  FOR lm IN lt_all_product_markets
                                  WHERE ( MRKTID = ls_market-Mrktid )
                                  NEXT count = count + 1 ).
      IF lv_matches > 1.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          %tky        = ls_market-%tky
          %state_area = 'CHECK_DUPLICATES'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'This market is already assigned to the product'
                        )
          %element-mrktid = if_abap_behv=>mk-on
        ) TO reported-market.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

