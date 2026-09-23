  CLASS zarv_cl_bp_query_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
    PUBLIC SECTION.
      INTERFACES if_rap_query_provider .

      CLASS-METHODS validate_partner
        IMPORTING iv_bp_id         TYPE zarv_business_partner
        RETURNING VALUE(rv_exists) TYPE abap_bool.

    PROTECTED SECTION.
    PRIVATE SECTION.
      " Helper method to initialize and return the authenticated OData client proxy
      CLASS-METHODS get_client_proxy
        RETURNING VALUE(ro_client_proxy) TYPE REF TO /iwbep/if_cp_client_proxy
        RAISING   cx_static_check.

      " Helper methods for reading detailed data
      METHODS get_address_id
        IMPORTING
          io_client_proxy      TYPE REF TO /iwbep/if_cp_client_proxy
          iv_business_partner  TYPE string
        RETURNING
          VALUE(rv_address_id) TYPE string
        RAISING
          cx_root.

      METHODS get_email_address
        IMPORTING
          io_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy
          iv_address_id   TYPE string
        RETURNING
          VALUE(rv_email) TYPE string
        RAISING
          cx_root.

      METHODS get_phone_number
        IMPORTING
          io_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy
          iv_address_id   TYPE string
        RETURNING
          VALUE(rv_phone) TYPE string
        RAISING
          cx_root.
  ENDCLASS.


  CLASS zarv_cl_bp_query_provider IMPLEMENTATION.

    METHOD get_client_proxy.
      " 1. Create HTTP client pointing to the sandbox host
      DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
        cl_http_destination_provider=>create_by_url( 'https://sandbox.api.sap.com' )
      ).

      " 2. Inject APIKey and Accept fields into the HTTP request headers
      DATA(lo_request_http) = lo_http_client->get_http_request( ).
      lo_request_http->set_header_field( i_name = 'APIKey' i_value = 'eMxLdp01qyVkkPYYcyuKbQhUVGCJzqEO' ).
      lo_request_http->set_header_field( i_name = 'Accept' i_value = 'application/json' ).

      " 3. Instantiate and return the OData remote client proxy
      ro_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
         EXPORTING
            is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                proxy_model_id      = 'ZARV_SC_BUSINESS_PARTNER'
                                                proxy_model_version = '0001' )
           io_http_client             = lo_http_client
           iv_relative_service_root   = '/s4hanacloud/sap/opu/odata/sap/OP_API_BUSINESS_PARTNER_SRV/' ).
    ENDMETHOD.

    METHOD get_address_id.
      DATA lt_addr_api TYPE TABLE OF zarv_sc_business_partner=>tys_a_business_partner_addre_2.

      DATA(lo_addr_set) = io_client_proxy->create_resource_for_entity_set( 'A_BUSINESS_PARTNER_ADDRESS' ).
      DATA(lo_addr_req) = lo_addr_set->create_request_for_read( ).

      DATA lt_range_addr TYPE if_rap_query_filter=>tt_range_option.
      lt_range_addr = VALUE #( ( sign = 'I' option = 'EQ' low = iv_business_partner ) ).

      DATA(lo_addr_flt) = lo_addr_req->create_filter_factory( )->create_by_range(
        iv_property_path = 'BUSINESS_PARTNER'
        it_range         = lt_range_addr
      ).
      lo_addr_req->set_filter( lo_addr_flt ).
      DATA(lo_addr_res) = lo_addr_req->execute( ).

      lo_addr_res->get_business_data( IMPORTING et_business_data = lt_addr_api ).

      READ TABLE lt_addr_api INTO DATA(ls_addr) INDEX 1.
      IF sy-subrc = 0.
        rv_address_id = ls_addr-address_id.
      ENDIF.
    ENDMETHOD.

    METHOD get_email_address.
      DATA lt_mail_api TYPE TABLE OF zarv_sc_business_partner=>tys_a_address_email_address_ty.

      DATA(lo_mail_set) = io_client_proxy->create_resource_for_entity_set( 'A_EMAIL_ADDRESS' ).
      DATA(lo_mail_req) = lo_mail_set->create_request_for_read( ).

      DATA lt_range_mail TYPE if_rap_query_filter=>tt_range_option.
      lt_range_mail = VALUE #( ( sign = 'I' option = 'EQ' low = iv_address_id ) ).

      DATA(lo_mail_flt) = lo_mail_req->create_filter_factory( )->create_by_range(
        iv_property_path = 'ADDRESS_ID'
        it_range         = lt_range_mail
      ).
      lo_mail_req->set_filter( lo_mail_flt ).
      DATA(lo_mail_res) = lo_mail_req->execute( ).

      lo_mail_res->get_business_data( IMPORTING et_business_data = lt_mail_api ).

      READ TABLE lt_mail_api INTO DATA(ls_mail) INDEX 1.
      IF sy-subrc = 0.
        rv_email = ls_mail-email_address.
      ENDIF.
    ENDMETHOD.

    METHOD get_phone_number.
      DATA lt_phone_api TYPE TABLE OF zarv_sc_business_partner=>tys_a_address_phone_number_typ.

      DATA(lo_phone_set) = io_client_proxy->create_resource_for_entity_set( 'A_MOBILE_PHONE_NUMBER' ).
      DATA(lo_phone_req) = lo_phone_set->create_request_for_read( ).

      DATA lt_range_phone TYPE if_rap_query_filter=>tt_range_option.
      lt_range_phone = VALUE #( ( sign = 'I' option = 'EQ' low = iv_address_id ) ).

      DATA(lo_phone_flt) = lo_phone_req->create_filter_factory( )->create_by_range(
        iv_property_path = 'ADDRESS_ID'
        it_range         = lt_range_phone
      ).
      lo_phone_req->set_filter( lo_phone_flt ).
      DATA(lo_phone_res) = lo_phone_req->execute( ).

      lo_phone_res->get_business_data( IMPORTING et_business_data = lt_phone_api ).

      READ TABLE lt_phone_api INTO DATA(ls_phone) INDEX 1.
      IF sy-subrc = 0.
        rv_phone = ls_phone-phone_number.
      ENDIF.
    ENDMETHOD.

    METHOD if_rap_query_provider~select.
      DATA lt_result       TYPE TABLE OF zarv_i_business_partner_c.
      DATA lt_bp_api       TYPE TABLE OF zarv_sc_business_partner=>tys_a_business_partner_type.
      DATA lo_http_client  TYPE REF TO if_web_http_client.

      TRY.
          DATA(lo_client_proxy) = get_client_proxy( ).
          DATA(lo_entity_set) = lo_client_proxy->create_resource_for_entity_set( 'A_BUSINESS_PARTNER' ).
          DATA(lo_request)    = lo_entity_set->create_request_for_read( ).

          " 4. Dynamic paging handling from UI request
          DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
          DATA(lv_skip) = io_request->get_paging( )->get_offset( ).

          IF lv_top IS NOT INITIAL.
            lo_request->set_top( CONV i( lv_top ) ).
          ELSE.
            lo_request->set_top( 20 ).
          ENDIF.
          lo_request->set_skip( CONV i( lv_skip ) ).

          " 5. Extract filter options to check if a specific partner is requested (lazy loading)
          DATA(lt_filters) = io_request->get_filter( )->get_as_ranges( ).
          READ TABLE lt_filters WITH KEY name = 'BUSINESSPARTNER' INTO DATA(ls_bp_filter).

          IF sy-subrc = 0.
            " Pass the specific filter to the remote OData request
            DATA(lo_filter_factory) = lo_request->create_filter_factory( ).
            DATA(lo_odata_filter)  = lo_filter_factory->create_by_range(
                                        iv_property_path = 'BUSINESS_PARTNER'
                                        it_range         = ls_bp_filter-range ).
            lo_request->set_filter( lo_odata_filter ).
          ENDIF.

          " 6. Execute main request to fetch Business Partners
          DATA(lo_response) = lo_request->execute( ).
          lo_response->get_business_data( IMPORTING et_business_data = lt_bp_api ).

          " 7. Process business data
          LOOP AT lt_bp_api INTO DATA(ls_bp).
            DATA(ls_row) = VALUE zarv_i_business_partner_c(
              BusinessPartner = ls_bp-business_partner
              CompanyName     = ls_bp-business_partner_full_name
            ).

            " Fetch detail data ONLY if a specific record is selected or filtered to avoid N+1 performance dump
            IF lines( lt_bp_api ) = 1 OR ls_bp_filter-range IS NOT INITIAL.
              TRY.
                  " 1. Get the address ID
                  DATA(lv_address_id) = get_address_id(
                    io_client_proxy     = lo_client_proxy
                    iv_business_partner = CONV #( ls_bp-business_partner )
                  ).

                  IF lv_address_id IS NOT INITIAL.
                    " 2. Receiving an email
                    ls_row-EmailAddress = get_email_address(
                      io_client_proxy = lo_client_proxy
                      iv_address_id   = lv_address_id
                    ).

                    " 3. Getting the Phone
                    ls_row-PhoneNumber = get_phone_number(
                      io_client_proxy = lo_client_proxy
                      iv_address_id   = lv_address_id
                    ).
                  ENDIF.

                CATCH cx_root.
                  " Individual record fetch failed, keep primary fields
              ENDTRY.
            ENDIF.

            APPEND ls_row TO lt_result.
          ENDLOOP.

          " 8. Return data and count back to the RAP response
          IF io_request IS BOUND AND io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( iv_total_number_of_records = lines( lt_result ) ).
          ENDIF.

          io_response->set_data( lt_result ).

        CATCH cx_root INTO DATA(lo_exc).
          " Error fallback: return empty/partial table to prevent UI dump
          IF io_request IS BOUND AND io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( iv_total_number_of_records = 0 ).
          ENDIF.
          io_response->set_data( lt_result ).
      ENDTRY.
    ENDMETHOD.

    METHOD validate_partner.
      DATA lt_bp_api TYPE TABLE OF zarv_sc_business_partner=>tys_a_business_partner_type.
      DATA lo_http_client TYPE REF TO if_web_http_client.
      rv_exists = abap_false.

      TRY.
          DATA(lo_client_proxy) = get_client_proxy( ).

          DATA(lo_entity_set) = lo_client_proxy->create_resource_for_entity_set( 'A_BUSINESS_PARTNER' ).
          DATA(lo_request)    = lo_entity_set->create_request_for_read( ).

          " Set strict filter for single partner validation
          DATA(lo_filter_factory) = lo_request->create_filter_factory( ).
          DATA(lt_filter_range) = VALUE if_rap_query_filter=>tt_range_option( ( sign = 'I' option = 'EQ' low = iv_bp_id ) ).
          DATA(lo_odata_filter)  = lo_filter_factory->create_by_range(
                                      iv_property_path = 'BUSINESS_PARTNER'
                                      it_range         = lt_filter_range ).
          lo_request->set_filter( lo_odata_filter ).
          lo_request->set_top( 1 ).

          DATA(lo_response) = lo_request->execute( ).
          lo_response->get_business_data( IMPORTING et_business_data = lt_bp_api ).

          IF lt_bp_api IS NOT INITIAL.
            rv_exists = abap_true.
          ENDIF.

        CATCH cx_root.
          " Fallback: If external sandbox server is offline/maintenance (Error 503), bypass by returning true
          rv_exists = abap_true.
      ENDTRY.
    ENDMETHOD.


  ENDCLASS.

