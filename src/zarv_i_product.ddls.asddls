@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Root Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZARV_I_PRODUCT
  as select from zarv_d_product
  composition [0..*] of ZARV_I_MARKET   as _Market
  association [1..1] to zarv_d_pr_group as _ProductGroup on $projection.Pgid = _ProductGroup.pgid
  association [1..1] to zarv_d_phase    as _Phase        on $projection.Phaseid = _Phase.phaseid
  association [1..1] to zarv_d_uom      as _Uom          on $projection.Sizeuom = _Uom.msehi
{
  key prod_uuid    as ProdUuid,
      prodid       as Prodid,
      @ObjectModel.text.association: '_ProductGroup'
      pgid         as Pgid,
      phaseid      as Phaseid,
      case phaseid
        when 'PROD' then 3
        when 'DEV'  then 2
        when 'PLAN' then 1
        else 0
      end          as PhaseCriticality,

      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      height       as Height,
      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      depth        as Depth,
      @Semantics.quantity.unitOfMeasure: 'Sizeuom'
      width        as Width,
      sizeuom      as Sizeuom,

      @Semantics.amount.currencyCode: 'Currency'
      price        as Price,
      currency     as Currency,
      taxrate      as Taxrate,

      @Semantics.user.createdBy: true
      createdby    as Createdby,
      @Semantics.systemDateTime.createdAt: true
      creationtime as Creationtime,
      @Semantics.user.lastChangedBy: true
      changedby    as Changedby,
      @Semantics.systemDateTime.lastChangedAt: true
      changetime   as Changetime,

      pgname_trans as PgnameTrans,
      trans_code   as TransCode,

      _Market,
      _ProductGroup,
      _Phase,
      _Uom
}
