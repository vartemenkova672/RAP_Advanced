@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_CURRENCY
  as select from I_Currency
{
  key Currency  as Currency,
      CurrencyISOCode,
      Decimals
}
