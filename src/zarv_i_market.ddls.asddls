@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Markets Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_MARKET
  as select from zarv_d_market
  association to parent ZARV_I_PRODUCT as _Product on $projection.ProdUuid = _Product.ProdUuid
  composition [0..*] of ZARV_I_ORDER as _Order
  association [1..1] to zarv_d_country as _Country on $projection.Mrktid = _Country.mrktid
{
  key mrkt_uuid    as MrktUuid,
      prod_uuid    as ProdUuid,
      mrktid       as Mrktid,
      status       as Status,
      startdate    as Startdate,
      enddate      as Enddate,
      isocode      as Isocode,
      
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
