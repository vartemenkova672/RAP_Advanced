@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Group Value Help'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZARV_I_PG
  as select from zarv_d_pr_group
{
      @ObjectModel.text.element: ['Pgname']
      @UI.textArrangement: #TEXT_ONLY
  key pgid       as pgid,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      pgname     as pgname,
      pgimageurl as pgimageurl
}
