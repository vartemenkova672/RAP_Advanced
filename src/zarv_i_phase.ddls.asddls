@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Phase Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_PHASE
  as select from zarv_d_phase
{
  key phaseid as phaseid,
      phase   as phase
}
