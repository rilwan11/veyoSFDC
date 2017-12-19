/**
 * Created on 12/12/17.
 */

public with sharing class uploadAttachmentController {
    public String selectedType {get;set;}
    public Attachment__c theAttachment {get;set;}
    public String description {get;set;}
    @testvisible private string parentRecord;
    public String fileName {get;set;}
    public Blob fileBody {get;set;}
    public Case gn { get; set; }

    public uploadAttachmentController(ApexPages.StandardController stdCon) {
        parentRecord = '5005B000003FMqWQAW'; //ApexPages.currentPage().getParameters().get('Id');
        system.debug(ApexPages.currentPage().getParameters());
        System.debug('uploadAttachmentController::: controller:: parentRecord: ' + string.valueOf(parentRecord));
        gn = [SELECT Id, CaseNumber
                FROM Case
                WHERE Id =: parentRecord
                LIMIT 1];

        this.theAttachment = new Attachment__c();
    }

    // creates a new Attachment__c record
    private Database.SaveResult saveCustomAttachment() {
        theAttachment.Name = fileName;
        theAttachment.Case__c = parentRecord;
     //   theAttachment.File__c = fileName;
    //    theAttachment.opportunity__c = parentRecord.left(3) == '006'? parentRecord: null;//theAttachment.opportunity__c != null ? theAttachment.Opportunity__c : null;
    //    theAttachment.account__c = parentRecord.left(3) == '001'? parentRecord: null;//theAttachment.account__c != null ? theAttachment.account__c : null;
        // fill out custom obj fields
        return Database.insert(theAttachment);
    }

    // create an actual Attachment record with the Attachment__c as parent
    private Database.SaveResult saveStandardAttachment(Id parentId) {
        Database.SaveResult result;

        Attachment attachment = new Attachment();
        attachment.body = this.fileBody;
        attachment.name = this.fileName;
        attachment.parentId = parentId;
        // insert the attachment
        result = Database.insert(attachment);
        // reset the file for the view state
        fileBody = Blob.valueOf('');

        //Save Attachment to Attachment__c
        theAttachment.File_Attachment__c = result.Id;

        return result;
    }

    /**
    * Upload process is:
    *  1. Insert new Attachment__c record
    *  2. Insert new Attachment with the new Attachment__c record as parent
    *  3. Update the Attachment__c record with the ID of the new Attachment
    **/
    public PageReference processUpload() {
        try {
            Database.SaveResult customAttachmentResult = saveCustomAttachment();

            if (customAttachmentResult == null || !customAttachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Could not save attachment.'));
                return null;
            }

            Database.SaveResult attachmentResult = saveStandardAttachment(customAttachmentResult.getId());

            if (attachmentResult == null || !attachmentResult.isSuccess()) {
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not save attachment.'));
                return null;
            } else {
                // update the custom attachment record with some attachment info
                Attachment__c customAttachment = [SELECT Id, Name FROM Attachment__c WHERE Id = :customAttachmentResult.getId()];
                customAttachment.File_Attachment__c = attachmentResult.getId();
                update customAttachment;
            }

        } catch (Exception e) {
            ApexPages.AddMessages(e);
            return null;
        }

        return new PageReference('/'+parentRecord);
    }
}