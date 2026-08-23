@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Group Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_PG
  as select from zarv_d_pr_group
{
      @ObjectModel.text.element: ['Pgname']
      @UI.textArrangement: #TEXT_ONLY
  key pgid       as pgid,
      pgname     as pgname,
      pgimageurl as pgimageurl
}
