@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Markets Projection View'
@Metadata.allowExtensions: true
define view entity ZARV_C_MARKET
  as projection on ZARV_I_MARKET
{
  key MrktUuid,
      ProdUuid,
      Mrktid,
      Status,
      Startdate,
      Enddate,
      Isocode,
      Createdby,
      Creationtime,
      Changedby,
      Changetime,
      
      /* Associations */
      _Product : redirected to parent ZARV_C_PRODUCT,
      _Order   : redirected to composition child ZARV_C_ORDER,
      _Country
}
