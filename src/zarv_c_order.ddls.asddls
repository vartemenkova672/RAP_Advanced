@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Orders Projection View'
@Metadata.allowExtensions: true
define view entity ZARV_C_ORDER
  as projection on ZARV_I_ORDER
{
  key OrderUuid,
      ProdUuid,
      MrktUuid,
      Orderid,
      Quantity,
      DeliveryDate,
      CalendarYear,
      @Semantics.amount.currencyCode: 'Currency'
      Netamount,
      @Semantics.amount.currencyCode: 'Currency'
      Grossamount,
      Currency,
      
      @Consumption.valueHelpDefinition: [{ 
        entity: { name: 'ZARV_I_BUSINESS_PARTNER_C', element: 'BusinessPartner' },
        additionalBinding: [
          { localElement: 'Busspartnercompany', element: 'CompanyName' },
          { localElement: 'Busspartneremail',   element: 'EmailAddress' },
          { localElement: 'Busspartnerphone',   element: 'PhoneNumber' }
        ] 
      }]
      Busspartner,
      
      Busspartnercompany,
      Busspartneremail,
      Busspartnerphone,
      Createdby,
      Creationtime,
      Changedby,
      Changetime,
      OrderImageUrl,

      /* Associations */
      _Market  : redirected to parent ZARV_C_MARKET,
      _Product : redirected to ZARV_C_PRODUCT
}
