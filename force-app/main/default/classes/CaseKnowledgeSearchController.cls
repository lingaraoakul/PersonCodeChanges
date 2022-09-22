/**
 * Created By     : Linga
 * Created Date   : 15/11/2021
 * Description    : Article Search, based on Selected Term and Language
 * Test Class     : CaseKnowledgeSearchControllerTest
 * Aura Component : Case_knowledgeSearchAura
 * LWC            : case_knowledgeSearch
 */
public class CaseKnowledgeSearchController {
  // static variables
  private static final String ENGLISH_CODE = 'en_US';
  private static final String SYSTEM_ADMIN = 'System Administrator';
  private static final String KNOWLEDGE_ARTICLE_VERSION = 'Knowledge__kav';

  // Get language and language code from Custom metadata
  @AuraEnabled(cacheable=true)
  public static List<Knowledge_Language_Codes__mdt> getLanguageOptions() {
    try {
      return getMetadataCodes();
    } catch (exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
  }

  /** Here are initial set up details
   * Language Options - Data comes from Custom metadata
   * Search the Articles, based on case subject, description words and Case Language/ Contact Language / Site Language
   */
  @AuraEnabled
  public static InitialSetUpData getSetupData(String recordId) {
    InitialSetUpData setData = new InitialSetUpData();
    try {
      List<String> lanCodes = new List<String>();
      List<Knowledge__kav> kavList = new List<Knowledge__kav>();
      List<ArticleData> articlesData = new List<ArticleData>();

      String defaultLanguage = '';

      // get Case Details
      Case[] caseRecord = [
        SELECT
          Id,
          Subject,
          Description,
          Language,
          ContactId,
          Contact.Contact_Language__c,
          CustomerSite__c
        FROM Case
        WHERE Id = :recordId
        LIMIT 1
      ];
      // get Language and language codes from custom metadta
      List<Knowledge_Language_Codes__mdt> codes = getMetadataCodes();

      for (Knowledge_Language_Codes__mdt meta : codes) {
        lanCodes.add(meta.DeveloperName);
      }
      if (lanCodes.size() > 0 && caseRecord.size() > 0) {
        Set<String> searchWordsSet = new Set<String>();
        List<String> searchWords = new List<String>();

        Case ca = caseRecord[0];
        String description = ca.Description;

        // Prepare search Words from Case Subject
        if (String.isNotBlank(ca.Subject)) {
          searchWordsSet.addAll(parseSubjectDescription(ca.Subject));
        }
        // Prepare search Words from Case Description
        if (String.isNotBlank(description)) {
          Integer strLength = description.length();
          description = (strLength > 600
            ? description.substring(0, 600)
            : description);
          searchWordsSet.addAll(parseSubjectDescription(description));
        }
        // Add set values to List
        searchWords.addAll(searchWordsSet);
        kavList.clear();
        // search a articles based on Case Language
        if (String.isNotBlank(ca.Language) && lanCodes.contains(ca.Language)) {
          defaultLanguage = ca.Language;
          kavList = getSearchResults(searchWords, defaultLanguage);
        }
        // If List as empty then choose Case contact Language
        if (
          kavList.isEmpty() &&
          String.isNotBlank(ca.ContactId) &&
          String.isNotBlank(ca.Contact.Contact_Language__c) &&
          !ca.Contact.Contact_Language__c.equalsIgnoreCase(ca.Language) &&
          lanCodes.contains((ca.Contact.Contact_Language__c))
        ) {
          defaultLanguage = ca.Contact.Contact_Language__c;
          kavList = getSearchResults(searchWords, defaultLanguage);
        }
        // If List as empty then choose default as english
        if (
          kavList.isEmpty() && !ENGLISH_CODE.equalsIgnoreCase(defaultLanguage)
        ) {
          defaultLanguage = ENGLISH_CODE;
          kavList = getSearchResults(searchWords, defaultLanguage);
        }

        articlesData = setArticleWrapperData(kavList, ca.Id);
      }
      // Set data
      setData.articlesData = articlesData;
      setData.defaultLanguage = defaultLanguage;
    } catch (exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
    return setData;
  }
  // Prepare List of Words from Case Subject and Description
  private static Set<String> parseSubjectDescription(
    String subjectorDescription
  ) {
    Set<String> terms = new Set<String>();
    List<String> words = ((subjectorDescription.replaceAll(
          '[ \r\n \n \r ? @ & $ | < /> ! { } ( ) ^ ~ * : \", \' + -]',
          ' '
        ))
        .replaceAll('-', ' '))
      .split(' ');
    for (String str : words) {
      String localStr = str;
      if (String.isNotBlank(localStr)) {
        if (localStr.contains('[')) {
          localStr = localStr.replace('[', '');
        }
        if (localStr.contains(']')) {
          localStr = localStr.replace(']', '');
        }
        if (localStr.length() > 4) {
          terms.add(localStr.trim());
        }
      }
    }
    return terms;
  }

  // Prepare Article WraperData
  private static List<ArticleData> setArticleWrapperData(
    List<Knowledge__kav> kavList,
    String caseId
  ) {
    // InitialSetUpData wrapData = new InitialSetUpData();
    List<ArticleData> articlesData = new List<ArticleData>();
    Map<String, String> siteLang_siteDomain = new Map<String, String>();

    for (Knowledge_Language_Codes__mdt meta : getMetadataCodes()) {
      if (
        meta != null &&
        meta.Is_Site_Language__c &&
        String.isNotBlank(meta.Domain__c)
      ) {
        siteLang_siteDomain.put(meta.DeveloperName, meta.Domain__c);
      }
    }

    String systemAdmin = [
      SELECT Id, Profile.Name
      FROM User
      WHERE Id = :UserInfo.getUserId() AND Profile.Name = :SYSTEM_ADMIN
    ]
    ?.Id;
    Boolean isNotAdmin = String.isBlank(systemAdmin) ? true : false;

    // Set Knowledge article Records and UI Option Visiablity
    for (Knowledge__kav article : kavList) {
      boolean isSiteLanguage = false;
      if (
        String.isNotBlank(article.Language) &&
        siteLang_siteDomain.containskey(article.Language)
      ) {
        isSiteLanguage = true;
      }
      ArticlesData.add(
        new ArticleData(article, false, isNotAdmin, isSiteLanguage)
      );
    }
    //wrapData.articlesData = articlesData;

    return articlesData;
  }

  // get Metadata
  private static List<Knowledge_Language_Codes__mdt> getMetadataCodes() {
    return Knowledge_Language_Codes__mdt.getAll()?.values();
  }

  // Check User permission
  @AuraEnabled
  public static boolean checkUserPermission() {
    boolean isAccessable = false;
    try {
      isAccessable = (Schema.sObjectType.CaseArticle.isAccessible() &&
      Schema.sObjectType.CaseArticle.isCreateable() &&
      Schema.sObjectType.Knowledge__kav.isAccessible());
    } catch (exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
    return isAccessable;
  }

  /** Get knowledge articles from Knowledge Entity, based on search term and Selected Language */
  @AuraEnabled(cacheable=true)
  public static List<ArticleData> getSearchKnowledgeList(
    String searchKey,
    String languageCode,
    String caseId
  ) {
    try {
      List<Knowledge__kav> kavlist = getSearchResults(
        new List<String>{ searchKey },
        languageCode
      );
      return setArticleWrapperData(kavlist, caseId);
    } catch (Exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
  }

  // create a CaseArticle Record from Custom component
  @AuraEnabled
  public static boolean insertCaseArticleRecord(string data, String versionId) {
    boolean isCreated = false;
    try {
      CaseArticle ca = (CaseArticle) System.JSON.deserialize(
        data,
        CaseArticle.class
      );
      string caseArticleId = [
        SELECT Id
        FROM CaseArticle
        WHERE CaseId = :ca.CaseId AND KnowledgeArticleVersionId = :versionId
        LIMIT 1
      ]
      ?.Id;
      if (String.isBlank(caseArticleId)) {
        isCreated = true;
        insert ca;
      }
    } catch (exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
    return isCreated;
  }
  // get Site Url, Based on Selected Site Master Label
  @AuraEnabled
  public static String getSiteUrl(String siteLabel) {
    try {
      String siteId = [
        SELECT Id
        FROM Site
        WHERE
          MasterLabel = :siteLabel
          AND status = 'Active'
          AND Subdomain != NULL
        LIMIT 1
      ]
      ?.Id;
      String siteUrl = [
        SELECT SecureUrl
        FROM SiteDetail
        WHERE DurableId = :siteId AND DurableId != NULL
        LIMIT 1
      ]
      ?.SecureUrl;
      return siteUrl;
    } catch (exception e) {
      throw new AuraHandledException(
        e.getMessage() +
        ' - at Line Number :' +
        e.getLineNumber()
      );
    }
  }

  // Prepare Query, To Search Results of Knowledge articles
  private static List<Knowledge__kav> getSearchResults(
    List<String> input,
    String language
  ) {
    String searchTerm;
    String query = '';

    List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();

    if (input.size() > 0 && input != null && String.isNotBlank(language)) {
      for (String term : input) {
        if (
          String.isBlank(searchTerm) &&
          String.isNotBlank(term) &&
          term.length() > 2
        ) {
          searchTerm = '\"' + term + '\"';
        } else if (String.isNotBlank(term) && term.length() > 2) {
          searchTerm += ' OR \"' + term + '\"';
        }
      }

      if (String.isNotBlank(searchTerm)) {
        query =
          'FIND {' +
          searchTerm +
          '} IN ALL FIELDS RETURNING Knowledge__kav' +
          '(Id, UrlName,LastPublishedDate,ValidationStatus,Description__c,IsVisibleInPkb,IsVisibleInCsp,' +
          'KnowledgeArticleId, Language,ArticleNumber,VersionNumber, Title' +
          ' WHERE Language = \'' +
          language +
          '\' AND PublishStatus = \'Online\' AND IsLatestVersion = True) LIMIT 50';

        knowledgeArticles = generateResult(query);
      }
    }
    return knowledgeArticles;
  }

  // Get a Suggested artiles, based on Query
  private static List<Knowledge__kav> generateResult(String query) {
    List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
    Search.SearchResults results = Search.find(query);
    List<Search.SearchResult> articlelist = results.get(
      KNOWLEDGE_ARTICLE_VERSION
    );

    for (Search.SearchResult searchResult : articlelist) {
      Knowledge__kav article = (Knowledge__kav) searchResult.getSObject();
      knowledgeArticles.add(article);
    }
    return knowledgeArticles;
  }
  // Wrap the Intial data
  public class InitialSetUpData {
    @AuraEnabled
    public String defaultLanguage { get; set; }
    @AuraEnabled
    public List<ArticleData> articlesData { get; set; }
  }
  // Set Article data
  public class ArticleData {
    @AuraEnabled
    public Knowledge__kav articleRecord { get; set; }
    @AuraEnabled
    public boolean isAttachDisable { get; set; }
    @AuraEnabled
    public boolean isUrlDisable { get; set; }
    @AuraEnabled
    public boolean isBodyDisable { get; set; }

    public ArticleData(
      Knowledge__kav articleRecord,
      boolean isAttachDisable,
      boolean isBodyDisable,
      boolean isSiteLanguage
    ) {
      this.articleRecord = articleRecord;
      this.isAttachDisable = isAttachDisable;
      this.isUrlDisable = ((articleRecord.IsVisibleInPkb ||
        articleRecord.IsVisibleInCsp) && isSiteLanguage
        ? false
        : true);
      this.isBodyDisable = isBodyDisable;
    }
  }
}
