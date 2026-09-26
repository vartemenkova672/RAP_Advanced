CLASS lcl_context_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gv_skip_validations TYPE abap_bool.
ENDCLASS.

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
    METHODS determineISO FOR DETERMINE ON MODIFY
       keys FOR Market~determineISO.

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

    lcl_context_buffer=>gv_skip_validations = abap_true.

    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'YES' ) )
      REPORTED DATA(lt_reported).

    reported = CORRESPONDING #( DEEP lt_reported ).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated).

    result = VALUE #( FOR ls_upd IN lt_updated ( %tky = ls_upd-%tky %param = ls_upd ) ).

    lcl_context_buffer=>gv_skip_validations = abap_false.
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
          Status    = COND #( WHEN ls_market-Status IS INITIAL THEN 'NEW' ELSE ls_market-Status )
          Startdate = COND #( WHEN ls_market-Startdate IS INITIAL THEN cl_abap_context_info=>get_system_date( ) ELSE ls_market-Startdate )
        ) )
      REPORTED DATA(lt_reported).
  ENDMETHOD.

METHOD validateStartDate.
    IF lcl_context_buffer=>gv_skip_validations = abap_true. RETURN. ENDIF.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Startdate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Startdate < lv_today.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          %tky = ls_market-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Start Date must be greater than today'
                 )
        ) TO reported-market.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateMarket.
    IF lcl_context_buffer=>gv_skip_validations = abap_true. RETURN. ENDIF.

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Mrktid ProdUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Mrktid IS INITIAL OR condense( ls_market-Mrktid ) = ''.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          ProdUuid  = ls_market-ProdUuid
          %is_draft = ls_market-%is_draft
          %msg      = new_message_with_text(
                        severity = if_abap_behv_message=>severity-error
                        text     = 'Market ID is required and cannot be blank.'
                      )
        ) TO reported-product.
      ENDIF.
    ENDLOOP.

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
            ProdUuid  = ls_market-ProdUuid
            %is_draft = ls_market-%is_draft
            %msg      = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Market doesn''t exist'
                        )
          ) TO reported-product.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

 METHOD validateDates.
    IF lcl_context_buffer=>gv_skip_validations = abap_true. RETURN. ENDIF.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Startdate Enddate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets INTO DATA(ls_market).
      IF ls_market-Enddate IS NOT INITIAL.
        IF ls_market-Enddate <= lv_today.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #(
            %tky = ls_market-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'End Date must greater than today'
                   )
          ) TO reported-market.
          CONTINUE.
        ENDIF.

        IF ls_market-Enddate < ls_market-Startdate.
          APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.
          APPEND VALUE #(
            %tky = ls_market-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'End Date must be greater than Start Date'
                   )
          ) TO reported-market.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

 METHOD checkDuplicates.
    IF lcl_context_buffer=>gv_skip_validations = abap_true. RETURN. ENDIF.

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
                                  WHERE ( mrktid = ls_market-Mrktid )
                                  NEXT count = count + 1 ).
      IF lv_matches > 1.
        APPEND VALUE #( %tky = ls_market-%tky ) TO failed-market.

        APPEND VALUE #(
          ProdUuid  = ls_market-ProdUuid
          %is_draft = ls_market-%is_draft
          %msg      = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'This market is already assigned to the product'
                        )
        ) TO reported-product.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineISO.
    " 1. Read market data from the transactional buffer (Draft instance)
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Mrktid Isocode ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_markets).

    LOOP AT lt_markets ASSIGNING FIELD-SYMBOL(<ls_market>).
      " Check if the trigger field is populated by the user
      IF <ls_market>-Mrktid IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          " 1. Create a raw HTTP destination and client (Bypasses SOAP proxy framework database issues)
          DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url(
            i_url = 'http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso'
          ).

          DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_http_destination
          ).

          DATA(lo_request) = lo_http_client->get_http_request( ).

          " 2. Set headers required for a standard SOAP 1.1 / 1.2 request
          lo_request->set_header_field( i_name = 'Content-Type' i_value = 'text/xml; charset=utf-8' ).

          " 2.5 Initialize country code variable (takes 'JP' immediately if length is 2)
          DATA(lv_country_code) = COND string( WHEN strlen( <ls_market>-Mrktid ) = 2
                                               THEN <ls_market>-Mrktid
                                               ELSE '' ).

          " 3. STEP 1: Only if full name is entered (length > 2), convert it to 2-letter ISO code
          IF strlen( <ls_market>-Mrktid ) > 2.
            DATA(lv_soap_conv_xml) =
              `<?xml version="1.0" encoding="utf-8"?>` &&
              `<soap:Envelope xmlns:xsi="http://www.` && `w3.org/2001/XMLSchema-instance" ` &&
              `xmlns:xsd="http://www.` && `w3.org/2001/XMLSchema" ` &&
              `xmlns:soap="http://schemas.` && `xmlsoap.org/soap/envelope/">` &&
              `  <soap:Body>` &&
              `    <CountryISOCode xmlns="http://www.` && `oorsprong.org/websamples.countryinfo">` &&
              `      <sCountryName>` && <ls_market>-Mrktid && `</sCountryName>` &&
              `    </CountryISOCode>` &&
              `  </soap:Body>` &&
              `</soap:Envelope>`.

            lo_request->set_text( lv_soap_conv_xml ).
            DATA(lo_response_conv) = lo_http_client->execute( if_web_http_client=>post ).
            DATA(lv_xml_conv) = lo_response_conv->get_text( ).

            FIND REGEX '<[^>]*:?CountryISOCodeResult>([^<]*)</[^>]*:?CountryISOCodeResult>'
                 IN lv_xml_conv
                 SUBMATCHES lv_country_code.
          ENDIF.
          " 4. STEP 2: Executed for BOTH scenarios ('JP' and 'Japan') using the resolved lv_country_code
          IF lv_country_code IS NOT INITIAL AND lv_country_code <> 'No country found by that name'.

            DATA(lv_soap_xml) =
              `<?xml version="1.0" encoding="utf-8"?>` &&
              `<soap:Envelope xmlns:xsi="http://www.` && `w3.org/2001/XMLSchema-instance" ` &&
              `xmlns:xsd="http://www.` && `w3.org/2001/XMLSchema" ` &&
              `xmlns:soap="http://schemas.` && `xmlsoap.org/soap/envelope/">` &&
              `  <soap:Body>` &&
              `    <CountryCurrency xmlns="http://www.` && `oorsprong.org/websamples.countryinfo">` &&
              `      <sCountryISOCode>` && lv_country_code && `</sCountryISOCode>` &&
              `    </CountryCurrency>` &&
              `  </soap:Body>` &&
              `</soap:Envelope>`.

            lo_request->set_text( lv_soap_xml ).
            DATA(lo_response) = lo_http_client->execute( if_web_http_client=>post ).
            DATA(lv_response_xml) = lo_response->get_text( ).

            " Parse the currency tag: <sISOCode>
            FIND REGEX '<[^>]*:?sISOCode>([^<]*)</[^>]*:?sISOCode>'
                 IN lv_response_xml
                 SUBMATCHES DATA(lv_result_currency_iso).

            " Update the RAP transactional buffer with the final currency code (e.g., 'JPY')
            IF sy-subrc = 0 AND lv_result_currency_iso IS NOT INITIAL.
              MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
                ENTITY Market
                  UPDATE FIELDS ( Isocode )
                  WITH VALUE #( ( %tky    = <ls_market>-%tky
                                  Isocode = lv_result_currency_iso ) )
                REPORTED DATA(ls_reported).
            ELSE.
              " Optional: If country not found, you can clear the Isocode field or handle it
              MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
                ENTITY Market
                  UPDATE FIELDS ( Isocode )
                  WITH VALUE #( ( %tky    = <ls_market>-%tky
                                  Isocode = '-' ) )
                REPORTED DATA(ls_reported_err).
            ENDIF.
          ENDIF.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

