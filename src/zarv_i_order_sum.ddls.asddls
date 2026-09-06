@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Aggregation for Markets'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_ORDER_SUM
  as select from zarv_d_order
{
  key mrkt_uuid as MrktUuid,
  
  @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
  sum( quantity ) as TotalQuantity,
  cast( 'PC' as abap.unit(3) ) as QuantityUnit,

  @Semantics.amount.currencyCode: 'OrderCurrency'
  sum( netamount ) as TotalNetAmount,
  
  @Semantics.amount.currencyCode: 'OrderCurrency'
  sum( grossamount ) as TotalGrossAmount,
  
  currency as OrderCurrency
}
group by
  mrkt_uuid,
  currency
