@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Orders Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_ORDER
  as select from zarv_d_order
  association to parent ZARV_I_MARKET as _Market on $projection.MrktUuid = _Market.MrktUuid
  association [0..1] to ZARV_I_PRODUCT as _Product on $projection.ProdUuid = _Product.ProdUuid
{
  key order_uuid         as OrderUuid,
      prod_uuid          as ProdUuid,
      mrkt_uuid          as MrktUuid,
      orderid            as Orderid,
      quantity           as Quantity,
      delivery_date      as DeliveryDate,
      calendar_year      as CalendarYear,
      @Semantics.amount.currencyCode: 'Currency'
      netamount          as Netamount,
      @Semantics.amount.currencyCode: 'Currency'
      grossamount        as Grossamount,
      currency           as Currency,
      busspartner        as Busspartner,
      busspartnercompany as Busspartnercompany,
      busspartneremail   as Busspartneremail,
      busspartnerphone   as Busspartnerphone,
      
      @Semantics.user.createdBy: true
      createdby          as Createdby,
      @Semantics.systemDateTime.createdAt: true
      creationtime       as Creationtime,
      @Semantics.user.lastChangedBy: true
      changedby          as Changedby,
      @Semantics.systemDateTime.lastChangedAt: true
      changetime         as Changetime,
      
      _Market,
      _Product
}
