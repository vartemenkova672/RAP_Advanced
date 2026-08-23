@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Root Projection View'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZARV_C_PRODUCT
  provider contract transactional_query
  as projection on ZARV_I_PRODUCT
{
  key ProdUuid,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Prodid,

      @ObjectModel.text.element: ['ProductGroupName']
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZARV_I_PG', element: 'pgid' } }]
      @UI.textArrangement: #TEXT_ONLY
      Pgid,
      _ProductGroup.pgname as ProductGroupName,

      @ObjectModel.text.element: ['PhaseName']
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZARV_I_PHASE', element: 'phaseid' } }]
      Phaseid,
      _Phase.phase         as PhaseName,

      PhaseCriticality,

      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      Height,
      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      Depth,
      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      Width,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZARV_I_UOM', element: 'msehi' } }]
      Sizeuom,

      @Semantics.amount.currencyCode: 'Currency'
      Price,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZARV_I_CURRENCY', element: 'Currency' } }]
      Currency,
      Taxrate,

      Createdby,
      Creationtime,
      Changedby,
      Changetime,
      PgnameTrans,
      TransCode,
      _ProductGroup.pgimageurl as ProductGroupImage,

      /* Associations */
      _Market : redirected to composition child ZARV_C_MARKET,
      _ProductGroup,
      _Phase,
      _Uom
}
