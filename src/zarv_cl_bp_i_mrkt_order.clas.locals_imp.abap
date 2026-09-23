CLASS lcl_order DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculate_orderid FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MarketOrder~calculate_orderid.

    METHODS set_calendar_year FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MarketOrder~set_calendar_year.

    METHODS calculate_amount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MarketOrder~calculate_amount.

    METHODS validate_delivery_date FOR VALIDATE ON SAVE
      IMPORTING keys FOR MarketOrder~validate_delivery_date.
    METHODS determineBusinessPartner FOR DETERMINE ON MODIFY
       keys FOR MarketOrder~determineBusinessPartner.
    METHODS validate_business_partner FOR VALIDATE ON SAVE
       keys FOR MarketOrder~validate_business_partner.
ENDCLASS.

CLASS lcl_order IMPLEMENTATION.

  " =========================================================================
  " 1. DETERMINATION: CALCULATE_ORDERID
  " =========================================================================
  METHOD calculate_orderid.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( Orderid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    DELETE lt_orders WHERE Orderid IS NOT INITIAL.
    IF lt_orders IS INITIAL. RETURN. ENDIF.

    SELECT MAX( orderid ) FROM zarv_d_order INTO @DATA(lv_max_id).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      lv_max_id += 1.
      <fs_order>-Orderid = |{ lv_max_id }|.
    ENDLOOP.

    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        UPDATE FIELDS ( Orderid ) WITH CORRESPONDING #( lt_orders )
      REPORTED DATA(lt_reported).
  ENDMETHOD.

  " =========================================================================
  " 2. DETERMINATION: SET_CALENDAR_YEAR
  " =========================================================================
  METHOD set_calendar_year.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( DeliveryDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      IF <fs_order>-DeliveryDate IS NOT INITIAL.
        <fs_order>-CalendarYear = <fs_order>-DeliveryDate(4).
      ELSE.
        CLEAR <fs_order>-CalendarYear.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        UPDATE FIELDS ( CalendarYear ) WITH CORRESPONDING #( lt_orders ).
  ENDMETHOD.

  " =========================================================================
  " 3. DETERMINATION: CALCULATE_AMOUNT
  " =========================================================================
  METHOD calculate_amount.
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( Quantity ProdUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    IF lt_orders IS INITIAL. RETURN. ENDIF.

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Product
        FIELDS ( Price Taxrate Currency ) WITH CORRESPONDING #( lt_orders MAPPING ProdUuid = ProdUuid )
      RESULT DATA(lt_products).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      READ TABLE lt_products INTO DATA(ls_prod) WITH KEY ProdUuid = <fs_order>-ProdUuid.
      IF sy-subrc = 0.
        <fs_order>-Currency    = ls_prod-Currency.
        <fs_order>-Netamount   = <fs_order>-Quantity * ls_prod-Price.
        <fs_order>-Grossamount = <fs_order>-Netamount + ( <fs_order>-Netamount * ls_prod-Taxrate / 100 ).
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        UPDATE FIELDS ( Netamount Grossamount Currency ) WITH CORRESPONDING #( lt_orders ).
  ENDMETHOD.

  " =========================================================================
  " 4. VALIDATION: VALIDATE_DELIVERY_DATE
  " =========================================================================
  METHOD validate_delivery_date.
    " Check if global flag bypasses validations (from your lcl_context_buffer example)
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( DeliveryDate MrktUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    IF lt_orders IS INITIAL. RETURN. ENDIF.

    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY Market
        FIELDS ( Startdate Enddate ) WITH CORRESPONDING #( lt_orders MAPPING MrktUuid = MrktUuid )
      RESULT DATA(lt_markets).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      READ TABLE lt_markets INTO DATA(ls_market) WITH KEY MrktUuid = <fs_order>-MrktUuid.
      IF sy-subrc = 0.

        " Validation 1: Delivery Date must be greater than Market Start Date
        IF <fs_order>-DeliveryDate <= ls_market-Startdate.
          APPEND VALUE #( %tky = <fs_order>-%tky ) TO failed-marketorder.

          APPEND VALUE #(
            %tky        = <fs_order>-%tky
            %state_area = 'VALIDATE_DELIVERY_START'
            %element-deliverydate = if_abap_behv=>mk-on
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Delivery date must be greater than Market Start Date'
                          )
          ) TO reported-marketorder.
        ENDIF.

        " Validation 2: Delivery Date must be less than or equal to Market End Date
        IF ls_market-Enddate IS NOT INITIAL AND <fs_order>-DeliveryDate > ls_market-Enddate.
          APPEND VALUE #( %tky = <fs_order>-%tky ) TO failed-marketorder.

          APPEND VALUE #(
            %tky        = <fs_order>-%tky
            %state_area = 'VALIDATE_DELIVERY_END'
            %element-deliverydate = if_abap_behv=>mk-on
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Delivery date cannot exceed Market End Date'
                          )
          ) TO reported-marketorder.
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineBusinessPartner.
    " 1. Read the selected business partner ID from changing order rows
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( BussPartner ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    DELETE lt_orders WHERE BussPartner IS INITIAL.
    IF lt_orders IS INITIAL. RETURN. ENDIF.

    DATA lt_bp_data TYPE TABLE OF zarv_i_business_partner_c.

    " 2. Directly call provider's interface method safely
    TRY.
        DATA(lo_provider) = NEW zarv_cl_bp_query_provider( ).

        " Declare empty object reference variables compatible with older NetWeaver signatures
        DATA lo_req TYPE REF TO if_rap_query_request.
        DATA lo_res TYPE REF TO if_rap_query_response.

        " Execute the real OData deep read call by triggering select method directly
        lo_provider->if_rap_query_provider~select(
          io_request  = lo_req
          io_response = lo_res
        ).
      CATCH cx_root.
        CLEAR lt_bp_data.
    ENDTRY.

    DATA lt_orders_update TYPE TABLE FOR UPDATE zarv_i_product\\MarketOrder.

    " 3. Map and distribute data fields dynamically back to the orders buffer
    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      READ TABLE lt_bp_data INTO DATA(ls_bp) WITH KEY BusinessPartner = <fs_order>-BussPartner.
      IF sy-subrc = 0.
        APPEND VALUE #(
          %tky               = <fs_order>-%tky
          BussPartnerCompany = ls_bp-CompanyName
          BussPartnerEmail   = ls_bp-EmailAddress
          BussPartnerPhone   = ls_bp-PhoneNumber
        ) TO lt_orders_update.
      ENDIF.
    ENDLOOP.

    " 4. Update draft elements to push values directly to Fiori UI
    IF lt_orders_update IS NOT INITIAL.
      MODIFY ENTITIES OF zarv_i_product IN LOCAL MODE
        ENTITY MarketOrder
          UPDATE FIELDS ( BussPartnerCompany BussPartnerEmail BussPartnerPhone )
          WITH lt_orders_update
        REPORTED DATA(lt_reported).

      reported-marketorder = CORRESPONDING #( lt_reported-marketorder ).
    ENDIF.
  ENDMETHOD.

  METHOD validate_business_partner.
    " Read the business partner ID from the application state using correct field name
    READ ENTITIES OF zarv_i_product IN LOCAL MODE
      ENTITY MarketOrder
        FIELDS ( Busspartner )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      " Check if the field is initial
      IF ls_order-Busspartner IS INITIAL.
        APPEND VALUE #( %tky = ls_order-%tky ) TO failed-marketorder.
        APPEND VALUE #( %tky = ls_order-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Business Partner ID cannot be empty.' )
                        %element-busspartner = if_abap_behv=>mk-on
                      ) TO reported-marketorder.
        CONTINUE.
      ENDIF.

      " Call the custom global validation method directly without complex framework objects
      DATA(lv_partner_exists) = zarv_cl_bp_query_provider=>validate_partner( ls_order-Busspartner ).

      " If partner does not exist on remote SAP API Hub, trigger UI error
      IF lv_partner_exists = abap_false.
        APPEND VALUE #( %tky = ls_order-%tky ) TO failed-marketorder.
        APPEND VALUE #( %tky = ls_order-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Business Partner { ls_order-Busspartner } does not exist in SAP Hub| )
                        %element-busspartner = if_abap_behv=>mk-on
                      ) TO reported-marketorder.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

