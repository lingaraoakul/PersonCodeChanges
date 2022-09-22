public with sharing class DataTableServerController {
  private static Request parsedRequest;

  @AuraEnabled
  public static List<SObject> getAccountData(String varRequest) {
    parsedRequest = parseRequest(varRequest);
    return Database.query(getSoqlQuery());
  }

  private static String getSoqlQuery() {
    String query = 'SELECT Id, Name, Rating_Ststus__c,CreatedDate, Rating FROM Account ';
    if (
      String.isBlank(parsedRequest.preKey) &&
      String.isBlank(parsedRequest.nextKey)
    ) {
      query += ' ORDER BY Id ASC LIMIT ' + parsedRequest.varLimit;
    } else if (
      String.isBlank(parsedRequest.preKey) &&
      String.isNotBlank(parsedRequest.nextKey)
    ) {
      query +=
        ' WHERE Id > \'' +
        parsedRequest.nextKey +
        '\' ORDER BY Id ASC LIMIT ' +
        parsedRequest.varLimit;
    } else {
      query +=
        ' WHERE Id >= \'' +
        parsedRequest.preKey +
        '\' AND Id <= \'' +
        parsedRequest.nextKey +
        '\' ORDER BY Id';
    }
    system.debug('query : ' + query);
    return query;
  }

  private static Request parseRequest(String varJSON) {
    return (Request) JSON.deserialize(varJSON, Request.class);
  }

  public class Request {
    public String varLimit { get; set; }
    public String preKey { get; set; }
    public String nextKey { get; set; }
  }
}
