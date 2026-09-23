@EndUserText.label: 'Custom Entity for Business Partner'
@ObjectModel.query.implementedBy: 'ABAP:ZARV_CL_BP_QUERY_PROVIDER'
define custom entity ZARV_I_BUSINESS_PARTNER_C
{
  @ObjectModel.text.element: ['CompanyName']
  key BusinessPartner : zarv_business_partner;
  CompanyName         : zarv_business_partner_company;
  EmailAddress        : zarv_business_partner_email;
  PhoneNumber         : zarv_business_partner_phone;
}
