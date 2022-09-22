/**
 * Description : Set default values for Send Email quick action
 *
 */
global class EmailFromAddressLoader implements QuickAction.QuickActionDefaultsHandler {
  // Static Final Values
  private static final string ORIGIN_EMAIL = 'Email';
  private static final string ORIGIN_WEB = 'Web';

  // Empty constructor
  global EmailFromAddressLoader() {
  }

  // The main interface method
  global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
    try {
      QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;

      // Check if the quick action is the standard case feed Send Email action
      for (Integer j = 0; j < defaults.size(); j++) {
        if (defaults.get(j).getActionName() == 'Case.SendEmail') {
          sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaults.get(
            j
          );
          break;
        }
      }
      if (sendEmailDefaults != null) {
        Case c = [
          SELECT
            Origin,
            Case_Origin__c,
            CustomerSite__c,
            contact.Contact_Language__c
          FROM Case
          WHERE Id = :sendEmailDefaults.getContextId()
        ];
        EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
        // Pull the Deafault Response email from Custom Label
        string fromAddress = System.Label.Default_Response_Email;

        // Set From Address as Case Origin email
        if (
          String.isNotBlank(c.Origin) &&
          c.Origin.equals(ORIGIN_EMAIL) &&
          String.isNotBlank(c.Case_Origin__c) &&
          String.valueof(c.Case_Origin__c).contains('@') &&
          isOrgEmailAddress(c.Case_Origin__c)
        ) {
          fromAddress = c.Case_Origin__c;

          // Set From Address as Case Customer Site Eamil
        } else if (
          String.isNotBlank(c.Origin) &&
          c.Origin.equals(ORIGIN_WEB) &&
          String.isNotBlank(c.CustomerSite__c) &&
          c.CustomerSite__c != 'Not Found'
        ) {
          // get Email Address from Custom Metdata based on Customer Site
          string configEmail = getEmailConfiguration(c.CustomerSite__c);

          if (
            String.isNotBlank(configEmail) && isOrgEmailAddress(configEmail)
          ) {
            fromAddress = configEmail;
          }
          // Set From Address as Case-contact Language code Email
        } else if (
          String.isNotBlank(c.Origin) &&
          !c.Origin.equals(ORIGIN_WEB) &&
          !c.Origin.equals(ORIGIN_EMAIL) &&
          String.isNotBlank(c.contactId)
        ) {
          // get Email Address from Custom Metdata based on case contact language code
          String langEmail = getEmailLanguage(c.contact.Contact_Language__c);

          if (String.isNotBlank(langEmail) && isOrgEmailAddress(langEmail)) {
            fromAddress = langEmail;
          }
        }
        emailMessage.ValidatedFromAddress = fromAddress;
      }
    } catch (exception e) {
    }
  }
  // Check Case Origin Picklist value as Approved Email
  private static boolean isOrgEmailAddress(string emailAddress) {
    string orgEmail = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = :emailAddress
      LIMIT 1
    ]
    ?.Id;
    return String.isNotBlank(orgEmail) ? true : false;
  }

  // get Email Address from Custom Metadata based on Case Customer Site
  private static string getEmailConfiguration(string customersite) {
    return [
      SELECT Email__c
      FROM Email_to_Case_Configuration__mdt
      WHERE Domain__c = :customersite
      LIMIT 1
    ]
    ?.Email__c;
  }

  // get Email Address from Custom Metadata based on Contact Language Code
  private static string getEmailLanguage(string languageCode) {
    return [
      SELECT Email__c
      FROM Language_Email_Address_Configuration__mdt
      WHERE DeveloperName = :languageCode
      LIMIT 1
    ]
    ?.Email__c;
  }
}
