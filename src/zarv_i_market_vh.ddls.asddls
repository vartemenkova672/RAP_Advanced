@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Market Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_MARKET_VH
  as select from zarv_d_market
{
  key mrkt_uuid as MrktUuid,
      mrktid    as Mrktid,
      isocode   as Isocode,
      status    as Status,
      startdate as Startdate,
      enddate   as Enddate
}
