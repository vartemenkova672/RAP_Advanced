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

ENDCLASS.

