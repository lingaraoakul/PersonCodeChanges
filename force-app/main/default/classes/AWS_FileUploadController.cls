/**
 * upload a file in to AWS s3 From Local Syatem Through Salesforce.
 */
public class AWS_FileUploadController {
  public string bucketName { get; set; }
  public String secret { get; set; }
  public String key { get; set; }
  public string policy { get; set; }
  public string signedPolicy { get; set; }
  ApexPages.StandardController con;

  public AWS_FileUploadController(ApexPages.StandardController stdController) {
    this.con = stdController;
    // Fetch the Aws Credentials
    Aws_Credentials__mdt awsCredentials = Aws_Credentials__mdt.getInstance(
      '********'
    );

    bucketName = awsCredentials.Bucket_Name__c;
    secret = awsCredentials.Secret_Key__c;
    key = awsCredentials.Key_Id__c;

    // Authorization Signature for IAM User
    datetime expire = system.now().addDays(1);
    String formattedexpire =
      expire.formatGmt('yyyy-MM-dd') +
      'T' +
      expire.formatGmt('HH:mm:ss') +
      '.' +
      expire.formatGMT('SSS') +
      'Z';
    String BPolicy =
      '{ "expiration": "' +
      formattedexpire +
      '","conditions": [' +
      '{"bucket": "' +
      bucketName +
      '" },' +
      '["starts-with", "$key", ""],' +
      '{ "acl": "public-read" },' +
      '{"content-type":""}]}';

    this.policy = EncodingUtil.base64Encode(Blob.valueOf(BPolicy));
    SignedPolicy = make_sig(EncodingUtil.base64Encode(Blob.valueOf(BPolicy)));
  }
  private String make_sig(string canonicalBuffer) {
    String macUrl;
    String signingKey = EncodingUtil.base64Encode(Blob.valueOf(secret));
    Blob mac = Crypto.generateMac(
      'HMACSHA1',
      blob.valueof(canonicalBuffer),
      blob.valueof(secret)
    );
    macUrl = EncodingUtil.base64Encode(mac);
    return macUrl;
  }

  public List<AWS_File__c> awsFileList {
    get {
      if (awsFileList == null) {
        Id idCon = con.getId();
        awsFileList = [
          SELECT
            Id,
            Asset__c,
            AWS_File_Id__c,
            Case__c,
            CreatedById,
            Name,
            File_Size__c,
            Upload_Date__c
          FROM AWS_File__c
          WHERE Case__c = :idCon
          ORDER BY Upload_Date__c DESC
        ];
      }
      return awsFileList;
    }
    set;
  }
}
