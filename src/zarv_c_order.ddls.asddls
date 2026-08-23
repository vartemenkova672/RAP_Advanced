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
      Busspartner,
      Busspartnercompany,
      Busspartneremail,
      Busspartnerphone,
      Createdby,
      Creationtime,
      Changedby,
      Changetime,
      
      /* Associations */
      _Market : redirected to parent ZARV_C_MARKET,
      _Product: redirected to ZARV_C_PRODUCT
}

