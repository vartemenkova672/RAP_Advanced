@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unit of Measure Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZARV_I_UOM
  as select from zarv_d_uom
{
  key msehi  as msehi,
      dimid  as dimid,
      isocode as isocode
}
