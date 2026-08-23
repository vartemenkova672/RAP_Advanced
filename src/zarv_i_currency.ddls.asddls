@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_CURRENCY
  as select from I_Currency as C
  association [0..1] to I_CurrencyText as _Text
    on  $projection.Currency = _Text.Currency
    and _Text.Language       = $session.system_language
{
  key C.Currency        as Currency,
      C.CurrencyISOCode as CurrencyISOCode,

      _Text.CurrencyName as CurrencyName
}
