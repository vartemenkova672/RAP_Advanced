@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Markets Projection View'
@Metadata.allowExtensions: true
define view entity ZARV_C_MARKET
  as projection on ZARV_I_MARKET
{
      @ObjectModel.text.element: ['CountryName']
  key MrktUuid,
      ProdUuid,

      @ObjectModel.text.element: ['CountryName'] 
      Mrktid,
      Status,
      Startdate,
      Enddate,
      MarketFlagUrl,
      MarketCriticality,

      _Country.country                          as CountryName,

      Createdby,
      Creationtime,
      Changedby,
      Changetime,

      /* Associations */
      _Product : redirected to parent ZARV_C_PRODUCT,
      _Order   : redirected to composition child ZARV_C_ORDER,
      _Country
}
