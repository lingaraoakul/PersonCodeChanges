({
    // Article attach to Case
    attachArticleToCase : function(component, event, selectedData) {           
        this.createRecord(component, event, selectedData, true);
    },
    
    // Insert a Article URL into Email Body
    insertURLToEmail : function(component, event, selectedData) {
        /** Get public Site url from server, based on case customer site and then prepare 
         * Article access url on site page.         
         */       
        var params = {"siteLabel": selectedData.siteName};      
        this.serverRequestCall(component, event,'c.getSiteUrl',params, function(result){
            var state = result.getState();
            if(state === 'SUCCESS'){
                var siteUrl = result.getReturnValue();
                
                if(siteUrl != null){                    
                    let url = siteUrl.endsWith('/') ? siteUrl : siteUrl+'/';
                    	url += selectedData.KnowledgeArticleId+'?name='+selectedData.UrlName+'&language='+selectedData.Language;                      
                    
                    let targetURL = '<a href="'+url+'">'+selectedData.Title+'</a>';
                    /** insert article url to Email body through quick action api */
                    this.handleQuickAction(component, event, selectedData, targetURL);
                }else{
                   component.set("v.isShowSpinner", false);  
                  this.showToastMessage('Site URL Not Found', 'error','Error!');  
                }
            } else if(state === 'ERROR'){   
              component.set("v.isShowSpinner", false);  
              this.showToastMessage('Site URL Not Found', 'error','Error!');  
            }
        });
        
    },
    // Insert Article description to Email Body
    insertArticleToEmail : function(component, event, selectedData) {
        /** insert article Description to Email body through quick action api */        
        this.handleQuickAction(component, event, selectedData, selectedData.Description__c);        
    },
    
    //Handle Lightning quick action api
    handleQuickAction : function(component, event, selectedData, fieldValue){
        var self = this;
        var actionAPI = component.find("quickActionAPI");  
        
        //Assign Quick Action field values
        var fields = {HtmlBody: {value: fieldValue, insertType: "cursor"}};
        // Invoke action to Api
        var args = {actionName: "Case.SendEmail",entityName:"Case", targetFields: fields};
        
        // set Action field values 
        actionAPI.setActionFieldValues(args).then(function(){            
            self.createRecord(component, event, selectedData, false);
        }).catch(function(e){            
            component.set("v.isShowSpinner", false);           
            self.showToastMessage('Article was not attached to Email Body.', 'error','Error!');
        });
        
    },
    
    // Create CaseArticle Record
    createRecord : function(component, event, selectedData, isRefresh){ 
        // set field values for New caseArticle Record
        var fields = {
            "attributes":{"type":"CaseArticle"},
            "ArticleLanguage":selectedData.Language,
            "ArticleVersionNumber":selectedData.VersionNumber,
            "CaseId":selectedData.caseId,
            "KnowledgeArticleId":selectedData.KnowledgeArticleId
        };   
        // Invoke server class method for New Case Article Creation
        
        var params = {"data": JSON.stringify(fields), "versionId":selectedData.Id};        
        this.serverRequestCall(component, event,"c.insertCaseArticleRecord", params, function(response){
            var state = response.getState(); 
            
             component.set("v.isShowSpinner", false);
            if(state === 'SUCCESS'){
                var result = response.getReturnValue(); 
                
                if(result){
                   this.showToastMessage(selectedData.Title+' was Attached to Case.', 'success','Success!');                
                }else if(isRefresh){
					this.showToastMessage(selectedData.Title+' has already been inserted.', 'info','Info!');                    
                }                
                if(isRefresh){$A.get('e.force:refreshView').fire();}                 
            }else if(state === 'ERROR'){                
                this.showToastMessage('Article was not Inserted.', 'error','Error!');
            } 
        } );       
    },
    
    // Generic code for Server Api call
    serverRequestCall : function(component, event, method,params, callback){
        var action = component.get(method);
        if(params){
            action.setParams(params);
        }        
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    },
    
    // Toast Message
    showToastMessage : function(msg, type, title) {
        var toastEvt = $A.get('e.force:showToast');
        toastEvt.setParams({
            "message":msg,
            "type" : type,
            "title":title
        });
        toastEvt.fire();
    }
})