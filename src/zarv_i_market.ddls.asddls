@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Markets Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_MARKET
  as select from zarv_d_market
  association        to parent ZARV_I_PRODUCT as _Product on $projection.ProdUuid = _Product.ProdUuid
  composition [0..*] of ZARV_I_ORDER          as _Order
  association [1..1] to zarv_d_country        as _Country on $projection.Mrktid = _Country.mrktid
{
  key mrkt_uuid    as MrktUuid,
      prod_uuid    as ProdUuid,
      mrktid       as Mrktid,
      status       as Status,
      startdate    as Startdate,
      enddate      as Enddate,
      isocode      as Isocode,
      case isocode
        when 'US' then cast( 'sap-icon://shipping-status' as abap.char(100) )
        when 'DE' then cast( 'sap-icon://supplier' as abap.char(100) )
        when 'FR' then cast( 'sap-icon://customer-financial-fact-sheet' as abap.char(100) )
        when 'ES' then cast( 'sap-icon://functional-location' as abap.char(100) )
        when 'IT' then cast( 'sap-icon://it-system' as abap.char(100) )
        else           cast( 'sap-icon://world' as abap.char(100) )
           end     as MarketFlagUrl,

      case status
        when 'X'         then 3
        when 'CONFIRMED' then 3
        else                  1
      end          as MarketCriticality,

      @Semantics.user.createdBy: true
      createdby    as Createdby,
      @Semantics.systemDateTime.createdAt: true
      creationtime as Creationtime,
      @Semantics.user.lastChangedBy: true
      changedby    as Changedby,
      @Semantics.systemDateTime.lastChangedAt: true
      changetime   as Changetime,

      _Product,
      _Order,
      _Country
}
