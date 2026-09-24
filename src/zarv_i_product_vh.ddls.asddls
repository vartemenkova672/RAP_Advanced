@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@EndUserText.label: 'Translation Value Help'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZARV_I_PRODUCT_VH as select from zarv_d_product
{
    @Aggregation.default: #NONE
    key trans_code as TransCode
}
group by trans_code
