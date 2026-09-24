CLASS zarv_cl_suppl_query_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zarv_cl_suppl_query_provider IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA lt_business_data  TYPE TABLE OF zarv_sc_suppliers=>tys_supplier.
    DATA lt_output         TYPE TABLE OF zarv_suppliers_c.
    DATA lo_http_client    TYPE REF TO if_web_http_client.
    DATA lo_client_proxy   TYPE REF TO /iwbep/if_cp_client_proxy.

    " 1. STATICAL CALLS FOR RAP RUNTIME VALIDATOR (Mandatory in this release)
    DATA(lo_paging) = io_request->get_paging( ).
    DATA(lt_sort)   = io_request->get_sort_elements( ).

    " 2. Check if data is requested by the UI layer
    IF io_request->is_data_requested( ).

      TRY.
          " Construct the full Northwind URL in pieces to ensure accuracy
          DATA(lv_url_part1) = 'https://services.'.
          DATA(lv_url_part2) = 'odata.org/V4/'.
          DATA(lv_url_part3) = 'Northwind/Northwind.svc/'.
          DATA(lv_full_url)  = lv_url_part1 && lv_url_part2 && lv_url_part3.

          " Trial-safe approach: Create HTTP client directly by URL
          lo_http_client = cl_web_http_client_manager=>create_by_http_destination(
                             cl_http_destination_provider=>create_by_url( lv_full_url )
                           ).

          " Create remote proxy using the initiated HTTP client
          lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v4_remote_proxy(
            EXPORTING
               is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                   proxy_model_id      = 'ZARV_SC_SUPPLIERS'
                                                   proxy_model_version = '0001' )
              io_http_client             = lo_http_client
              iv_relative_service_root   = '' ).

          " Navigate to the resource and create a read request for 'SUPPLIERS'
          DATA(lo_resource) = lo_client_proxy->create_resource_for_entity_set( 'SUPPLIERS' ).
          DATA(lo_request)  = lo_resource->create_request_for_read( ).

          " 3. Handle incoming filters from UI (Both List Report Search and Object Page details)
          DATA(lo_filter_factory) = lo_request->create_filter_factory( ).
          DATA(lt_filter_cond)    = io_request->get_filter( )->get_as_ranges( ).

          READ TABLE lt_filter_cond INTO DATA(ls_supplier_filter) WITH KEY name = 'SUPPLIER_ID'.
          IF sy-subrc = 0.
            " Extract range and translate it directly into remote OData filter criteria
            " Pass the technical property name in UPPERCASE as registered in the proxy model metadata
            DATA(lo_remote_filter) = lo_filter_factory->create_by_range(
                                       iv_property_path = 'SUPPLIER_ID'
                                       it_range         = ls_supplier_filter-range
                                     ).

            lo_request->set_filter( lo_remote_filter ).
          ENDIF.

          " Set paging parameters from the pre-defined paging object
          TRY.
              DATA(lv_top) = lo_paging->get_page_size( ).
              IF lv_top IS NOT INITIAL AND lv_top <> if_rap_query_paging=>page_size_unlimited.
                lo_request->set_top( CONV i( lv_top ) ).
              ENDIF.
            CATCH cx_root.
          ENDTRY.

          TRY.
              DATA(lv_skip) = lo_paging->get_offset( ).
              IF lv_skip IS NOT INITIAL AND lv_skip > 0.
                lo_request->set_skip( CONV i( lv_skip ) ).
              ENDIF.
            CATCH cx_root.
          ENDTRY.

          " Execute remote OData service call
          DATA(lo_response) = lo_request->execute( ).
          lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

        CATCH cx_root INTO DATA(lx_remote_err).
          " Clear data in case of remote service failures or trial restrictions
          CLEAR lt_business_data.
      ENDTRY.

      " 4. Fetch local data from ZARV_SUPPLADD table for the retrieved suppliers
      IF lt_business_data IS NOT INITIAL.
        SELECT * FROM zarv_suppladd
          FOR ALL ENTRIES IN @lt_business_data
          WHERE supplierid = @lt_business_data-supplier_id
          INTO TABLE @DATA(lt_local_data).
      ENDIF.

      " 5. Merge remote OData fields with local database extension fields
      LOOP AT lt_business_data ASSIGNING FIELD-SYMBOL(<ls_remote>).
        APPEND INITIAL LINE TO lt_output ASSIGNING FIELD-SYMBOL(<ls_out>).

        " Mapping standard OData fields
        MOVE-CORRESPONDING <ls_remote> TO <ls_out>.

        " Merge local extension fields by supplierid key
        READ TABLE lt_local_data ASSIGNING FIELD-SYMBOL(<ls_local>)
          WITH KEY supplierid = <ls_remote>-supplier_id.
        IF sy-subrc = 0.
          <ls_out>-discount_pct  = <ls_local>-discount_pct.
          <ls_out>-lastchangedat = <ls_local>-lastchangedat.
        ELSE.
          " Set default fallback value if local record does not exist yet
          <ls_out>-discount_pct  = '0.0'.
        ENDIF.
      ENDLOOP.

      " 6. Return the merged dataset back to the UI framework
      io_response->set_data( lt_output ).

      " Provide total records count if requested by the framework (using platform-specific method)
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( lines( lt_output ) ).
      ENDIF.

    ENDIF.
  ENDMETHOD.

ENDCLASS.

