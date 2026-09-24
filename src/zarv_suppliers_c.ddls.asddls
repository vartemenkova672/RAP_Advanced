@EndUserText.label: 'Custom Entity for Suppliers Extension'
@ObjectModel.query.implementedBy: 'ABAP:ZARV_CL_SUPPL_QUERY_PROVIDER'
@Search.searchable: true

define root custom entity ZARV_SUPPLIERS_C
{
      @UI.facet: [ {
        id: 'GeneralInfo',
        type: #IDENTIFICATION_REFERENCE,
        label: 'General Information',
        position: 10
      } ]

      @UI.lineItem: [ { position: 10, label: 'Supplier ID' } ]
      @UI.identification: [ { position: 10, label: 'Supplier ID' } ]
      @UI.selectionField: [ { position: 10 } ]
  key supplier_id   : abap.int4;

      @UI.lineItem: [ { position: 20, label: 'Company Name' } ]
      @UI.identification: [ { position: 20, label: 'Company Name' } ]
      @UI.selectionField: [ { position: 20 } ]
      @Search.defaultSearchElement: true
      company_name  : abap.char( 40 );

      @UI.lineItem: [ { position: 30, label: 'Contact Name' } ]
      @UI.identification: [ { position: 30, label: 'Contact Name' } ]
      @UI.selectionField: [ { position: 30 } ]
      @Search.defaultSearchElement: true
      contact_name  : abap.char( 30 );

      @UI.lineItem: [ { position: 40, label: 'Contact Title' } ]
      @UI.identification: [ { position: 40, label: 'Contact Title' } ]
      contact_title : abap.char( 30 );

      @UI.lineItem: [ { position: 50, label: 'Country' } ]
      @UI.identification: [ { position: 50, label: 'Country' } ]
      @UI.selectionField: [ { position: 40 } ]
      country       : abap.char( 15 );

      @UI.lineItem: [ { position: 60, label: 'City' } ]
      @UI.identification: [ { position: 60, label: 'City' } ]
      city          : abap.char( 15 );

      @UI.lineItem: [ { position: 70, label: 'Address' } ]
      @UI.identification: [ { position: 70, label: 'Address' } ]
      address       : abap.char( 60 );

      @UI.lineItem: [ { position: 80, label: 'Phone' } ]
      @UI.identification: [ { position: 80, label: 'Phone' } ]
      phone         : abap.char( 24 );

      @UI.identification: [ { position: 90, label: 'Fax' } ]
      fax           : abap.char( 24 );

      @UI.identification: [ { position: 100, label: 'Region' } ]
      region        : abap.char( 15 );

      @UI.identification: [ { position: 110, label: 'Postal Code' } ]
      postal_code   : abap.char( 10 );

      @UI.identification: [ { position: 120, label: 'Home Page' } ]
      home_page     : abap.char( 255 );

      @UI.lineItem: [ { position: 130, label: 'Discount (%)' } ]
      @UI.identification: [ { position: 130, label: 'Discount (%)' } ]
      discount_pct  : abap.dec( 3, 1 );
      
      @Semantics.systemDateTime.lastChangedAt: true
      @UI.identification: [ { position: 140, label: 'Last Changed At' } ]
      lastchangedat : timestampl;
}
