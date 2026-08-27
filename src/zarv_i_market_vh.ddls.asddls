@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Market Value Help'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true 
define view entity ZARV_I_MARKET_VH
  as select from zarv_d_market
  association [1..1] to zarv_d_country as _Country on $projection.Mrktid = _Country.mrktid
{
      @Search.defaultSearchElement: true 
      @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: ['CountryName']
      @EndUserText.label: 'Market ID'
  key mrktid           as Mrktid,
  
      @EndUserText.label: 'Status'
      status           as Status,
      
      @Search.defaultSearchElement: true 
      @Search.fuzzinessThreshold: 0.8
      @EndUserText.label: 'Country Name'
      _Country.country as CountryName
}
