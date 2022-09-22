public with sharing class AWS_BigFileUploadController{

    public string bucketName { get; set; }
    public String secret { get; set; }
    public String key { get; set; }
    public String bucketRegion {get; set;}
    public String IdentityPoolId {get; set;}

    ApexPages.StandardController con;

    public AWS_BigFileUploadController(ApexPages.StandardController stdController) {
        this.con = stdController;
        // Fetch the Aws Credentials
        Aws_Credentials__mdt awsCredentials = Aws_Credentials__mdt.getInstance('********');
        bucketName = awsCredentials.Bucket_Name__c;
        secret = awsCredentials.Secret_Key__c;
        key = awsCredentials.Key_Id__c;
        bucketRegion = awsCredentials.Bucket_Region__c;
        IdentityPoolId = awsCredentials.IdentityPoolId__c;

    }

    public List<AWS_File__c> awsFileList {
        get {
            if (awsFileList == null) {
                Id idCon = con.getId();
                awsFileList = [SELECT Id, Asset__c, AWS_File_Id__c, Case__c, CreatedById, Name, File_Size__c, Upload_Date__c FROM AWS_File__c WHERE Case__c = :idCon ORDER BY Upload_Date__c DESC];
            }
            return awsFileList;
        }
        set;
    }
}
