CLASS zarv_cl_generate_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS get_uuid RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.
ENDCLASS.

CLASS zarv_cl_generate_data IMPLEMENTATION.

  METHOD get_uuid.
    "Generate UUID (this system provides *_STATIC and may raise CX_UUID_ERROR)
    TRY.
        rv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        CLEAR rv_uuid.
    ENDTRY.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA lv_ts   TYPE timestampl.
    DATA lv_date TYPE d.
    DATA lv_year TYPE bdatj.

    GET TIME STAMP FIELD lv_ts.
    lv_date = cl_abap_context_info=>get_system_date( ).
    lv_year = lv_date(4).

    out->write( |Starting test data generation...| ).

    "------------------------------------------------------------
    "1) Cleanup (delete children first)
    "------------------------------------------------------------
    DELETE FROM zarv_d_order.
    DELETE FROM zarv_d_market.
    DELETE FROM zarv_d_product.
    DELETE FROM zarv_d_country.

    "Optional cleanup for dictionaries (keeps demo data consistent)
    DELETE FROM zarv_d_pr_group.
    DELETE FROM zarv_d_phase.
    DELETE FROM zarv_d_uom.

    out->write( |Tables cleaned.| ).

    "------------------------------------------------------------
    "2) Dictionaries (so validations/value helps work)
    "------------------------------------------------------------

    "2.1 Phases
    DATA lt_phase TYPE STANDARD TABLE OF zarv_d_phase WITH EMPTY KEY.
    lt_phase = VALUE #(
      ( mandt = sy-mandt phaseid = 'PLAN' phase = 'Planning' )
      ( mandt = sy-mandt phaseid = 'DEV'  phase = 'Development' )
      ( mandt = sy-mandt phaseid = 'PROD' phase = 'Production' )
      ( mandt = sy-mandt phaseid = 'TEST' phase = 'Testing' )
      ( mandt = sy-mandt phaseid = 'DISC' phase = 'Discontinued' )
    ).
    INSERT zarv_d_phase FROM TABLE @lt_phase.

    "2.2 Units of Measure (several entries)
    DATA lt_uom TYPE STANDARD TABLE OF zarv_d_uom WITH EMPTY KEY.
    lt_uom = VALUE #(
      ( mandt = sy-mandt msehi = 'MM' dimid = 'LENGTH' isocode = 'MMT' )
      ( mandt = sy-mandt msehi = 'CM' dimid = 'LENGTH' isocode = 'CMT' )
      ( mandt = sy-mandt msehi = 'M'  dimid = 'LENGTH' isocode = 'MTR' )
      ( mandt = sy-mandt msehi = 'IN' dimid = 'LENGTH' isocode = 'INH' )
    ).
    INSERT zarv_d_uom FROM TABLE @lt_uom.

    "2.3 Product Groups (create 5 groups)
    DATA lv_pgid_cooker TYPE sysuuid_x16.
    DATA lv_pgid_oven   TYPE sysuuid_x16.
    DATA lv_pgid_kettle TYPE sysuuid_x16.
    DATA lv_pgid_mixer  TYPE sysuuid_x16.
    DATA lv_pgid_fridge TYPE sysuuid_x16.

    lv_pgid_cooker = get_uuid( ).
    lv_pgid_oven   = get_uuid( ).
    lv_pgid_kettle = get_uuid( ).
    lv_pgid_mixer  = get_uuid( ).
    lv_pgid_fridge = get_uuid( ).

    DATA lt_pg TYPE STANDARD TABLE OF zarv_d_pr_group WITH EMPTY KEY.
    lt_pg = VALUE #(
      ( mandt = sy-mandt pgid = lv_pgid_cooker pgname = 'Cooker'
        pgimageurl = 'https://example.com/cooker.png' )
      ( mandt = sy-mandt pgid = lv_pgid_oven   pgname = 'Oven'
        pgimageurl = 'https://example.com/oven.png' )
      ( mandt = sy-mandt pgid = lv_pgid_kettle pgname = 'Kettle'
        pgimageurl = 'https://example.com/kettle.png' )
      ( mandt = sy-mandt pgid = lv_pgid_mixer  pgname = 'Mixer'
        pgimageurl = 'https://example.com/mixer.png' )
      ( mandt = sy-mandt pgid = lv_pgid_fridge pgname = 'Fridge'
        pgimageurl = 'https://example.com/fridge.png' )
    ).
    INSERT zarv_d_pr_group FROM TABLE @lt_pg.

    out->write( |Dictionaries inserted (Phase/UoM/Product Groups).| ).

    "------------------------------------------------------------
    "3) Countries (5)
    "------------------------------------------------------------
    DATA lt_country TYPE STANDARD TABLE OF zarv_d_country WITH EMPTY KEY.
    lt_country = VALUE #(
      ( mandt = sy-mandt mrktid = 'US' country = 'United States' code = 'US'
        imageurl = 'https://example.com/us.png' )
      ( mandt = sy-mandt mrktid = 'DE' country = 'Germany'       code = 'DE'
        imageurl = 'https://example.com/de.png' )
      ( mandt = sy-mandt mrktid = 'FR' country = 'France'        code = 'FR'
        imageurl = 'https://example.com/fr.png' )
      ( mandt = sy-mandt mrktid = 'ES' country = 'Spain'         code = 'ES'
        imageurl = 'https://example.com/es.png' )
      ( mandt = sy-mandt mrktid = 'IT' country = 'Italy'         code = 'IT'
        imageurl = 'https://example.com/it.png' )
    ).
    INSERT zarv_d_country FROM TABLE @lt_country.

    out->write( |Countries inserted: { lines( lt_country ) }| ).

    "------------------------------------------------------------
    "4) Products (5)
    "------------------------------------------------------------
    DATA lt_prod_uuid TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY.
    DO 5 TIMES.
      APPEND get_uuid( ) TO lt_prod_uuid.
    ENDDO.

    DATA lt_product TYPE STANDARD TABLE OF zarv_d_product WITH EMPTY KEY.
    lt_product = VALUE #(
      ( mandt = sy-mandt prod_uuid = lt_prod_uuid[ 1 ]
        prodid = 'P-0001' pgid = lv_pgid_cooker phaseid = 'PLAN'
        height = '10.000' depth = '20.000' width = '30.000' sizeuom = 'CM'
        price = '199.99' currency = 'USD' taxrate = '20.00'
        pgname_trans = 'Cooker' trans_code = 'EN'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt prod_uuid = lt_prod_uuid[ 2 ]
        prodid = 'P-0002' pgid = lv_pgid_oven phaseid = 'DEV'
        height = '400.000' depth = '600.000' width = '500.000' sizeuom = 'MM'
        price = '499.99' currency = 'EUR' taxrate = '19.00'
        pgname_trans = 'Oven' trans_code = 'EN'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt prod_uuid = lt_prod_uuid[ 3 ]
        prodid = 'P-0003' pgid = lv_pgid_kettle phaseid = 'PROD'
        height = '0.300' depth = '0.200' width = '0.250' sizeuom = 'M'
        price = '59.99' currency = 'EUR' taxrate = '21.00'
        pgname_trans = 'Kettle' trans_code = 'EN'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt prod_uuid = lt_prod_uuid[ 4 ]
        prodid = 'P-0004' pgid = lv_pgid_mixer phaseid = 'PLAN'
        height = '12.000' depth = '9.000' width = '11.000' sizeuom = 'IN'
        price = '89.99' currency = 'EUR' taxrate = '18.00'
        pgname_trans = 'Mixer' trans_code = 'EN'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt prod_uuid = lt_prod_uuid[ 5 ]
        prodid = 'P-0005' pgid = lv_pgid_fridge phaseid = 'DEV'
        height = '1.800' depth = '0.700' width = '0.600' sizeuom = 'M'
        price = '899.99' currency = 'EUR' taxrate = '22.00'
        pgname_trans = 'Fridge' trans_code = 'EN'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )
    ).
    INSERT zarv_d_product FROM TABLE @lt_product.

    out->write( |Products inserted: { lines( lt_product ) }| ).

    "------------------------------------------------------------
    "5) Markets (5) - one market per product
    "------------------------------------------------------------
    DATA lt_mrkt_uuid TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY.
    DO 5 TIMES.
      APPEND get_uuid( ) TO lt_mrkt_uuid.
    ENDDO.

    DATA lt_market TYPE STANDARD TABLE OF zarv_d_market WITH EMPTY KEY.
    lt_market = VALUE #(
      ( mandt = sy-mandt mrkt_uuid = lt_mrkt_uuid[ 1 ] prod_uuid = lt_prod_uuid[ 1 ]
        mrktid = 'US' status = 'NEW'
        startdate = lv_date enddate = lv_date + 180 isocode = 'US'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt mrkt_uuid = lt_mrkt_uuid[ 2 ] prod_uuid = lt_prod_uuid[ 2 ]
        mrktid = 'DE' status = 'NEW'
        startdate = lv_date enddate = lv_date + 180 isocode = 'DE'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt mrkt_uuid = lt_mrkt_uuid[ 3 ] prod_uuid = lt_prod_uuid[ 3 ]
        mrktid = 'FR' status = 'NEW'
        startdate = lv_date enddate = lv_date + 180 isocode = 'FR'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt mrkt_uuid = lt_mrkt_uuid[ 4 ] prod_uuid = lt_prod_uuid[ 4 ]
        mrktid = 'ES' status = 'NEW'
        startdate = lv_date enddate = lv_date + 180 isocode = 'ES'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt mrkt_uuid = lt_mrkt_uuid[ 5 ] prod_uuid = lt_prod_uuid[ 5 ]
        mrktid = 'IT' status = 'NEW'
        startdate = lv_date enddate = lv_date + 180 isocode = 'IT'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )
    ).
    INSERT zarv_d_market FROM TABLE @lt_market.

    out->write( |Markets inserted: { lines( lt_market ) }| ).

    "------------------------------------------------------------
    "6) Orders (5) - one order per market/product
    "------------------------------------------------------------
    DATA lt_ord_uuid TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY.
    DO 5 TIMES.
      APPEND get_uuid( ) TO lt_ord_uuid.
    ENDDO.

    DATA lt_order TYPE STANDARD TABLE OF zarv_d_order WITH EMPTY KEY.
    lt_order = VALUE #(
      ( mandt = sy-mandt order_uuid = lt_ord_uuid[ 1 ]
        prod_uuid = lt_prod_uuid[ 1 ] mrkt_uuid = lt_mrkt_uuid[ 1 ]
        orderid = 1001 quantity = 2
        delivery_date = lv_date + 14
        calendar_year = lv_year
        netamount = '199.99' grossamount = '239.99' currency = 'USD'
        busspartner = 'BP00000001' busspartnercompany = 'Demo Corp US'
        busspartneremail = 'demo.us@example.com' busspartnerphone = '+1-555-0101'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt order_uuid = lt_ord_uuid[ 2 ]
        prod_uuid = lt_prod_uuid[ 2 ] mrkt_uuid = lt_mrkt_uuid[ 2 ]
        orderid = 1002 quantity = 1
        delivery_date = lv_date + 10
        calendar_year = lv_year
        netamount = '499.99' grossamount = '594.99' currency = 'EUR'
        busspartner = 'BP00000002' busspartnercompany = 'Demo GmbH'
        busspartneremail = 'demo.de@example.com' busspartnerphone = '+49-555-0102'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt order_uuid = lt_ord_uuid[ 3 ]
        prod_uuid = lt_prod_uuid[ 3 ] mrkt_uuid = lt_mrkt_uuid[ 3 ]
        orderid = 1003 quantity = 3
        delivery_date = lv_date + 21
        calendar_year = lv_year
        netamount = '59.99' grossamount = '72.59' currency = 'EUR'
        busspartner = 'BP00000003' busspartnercompany = 'Demo SAS'
        busspartneremail = 'demo.fr@example.com' busspartnerphone = '+33-555-0103'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt order_uuid = lt_ord_uuid[ 4 ]
        prod_uuid = lt_prod_uuid[ 4 ] mrkt_uuid = lt_mrkt_uuid[ 4 ]
        orderid = 1004 quantity = 1
        delivery_date = lv_date + 7
        calendar_year = lv_year
        netamount = '89.99' grossamount = '106.19' currency = 'EUR'
        busspartner = 'BP00000004' busspartnercompany = 'Demo SL'
        busspartneremail = 'demo.es@example.com' busspartnerphone = '+34-555-0104'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )

      ( mandt = sy-mandt order_uuid = lt_ord_uuid[ 5 ]
        prod_uuid = lt_prod_uuid[ 5 ] mrkt_uuid = lt_mrkt_uuid[ 5 ]
        orderid = 1005 quantity = 2
        delivery_date = lv_date + 12
        calendar_year = lv_year
        netamount = '899.99' grossamount = '1097.99' currency = 'EUR'
        busspartner = 'BP00000005' busspartnercompany = 'Demo SRL'
        busspartneremail = 'demo.it@example.com' busspartnerphone = '+39-555-0105'
        createdby = sy-uname creationtime = lv_ts changedby = sy-uname changetime = lv_ts )
    ).
    INSERT zarv_d_order FROM TABLE @lt_order.

    COMMIT WORK.

    out->write( |Orders inserted: { lines( lt_order ) }| ).
    out->write( |Done.| ).

  ENDMETHOD.

ENDCLASS.
