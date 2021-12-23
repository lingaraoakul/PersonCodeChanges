({
    checkPermission : function(component, event, helper){        
        helper.serverRequestCall(component,event,"c.checkUserPermission", '', function(result){           
            var state = result.getState();
            if(state === 'SUCCESS'){
                let serverValue = result.getReturnValue();
                component.set("v.isAccessible",serverValue);                
            }else if(state === 'ERROR'){
                component.set("v.isAccessible",false);
            }
        });
    },

    handleActions : function(component, event, helper) {
        // get data from Child LWC in string format and convert in to js object
        component.set("v.isShowSpinner", true);
        var selectData = event.getParam("data");
        selectData = JSON.parse(selectData);
        
        if(typeof selectData === 'object'){

            try{
				
                switch(selectData.actionType){
                    
                    case 'AttachArticle' : {                       
                        helper.attachArticleToCase(component,event, selectData);
                        break;
                    }
                    case 'InsertURL' : {
                        helper.insertURLToEmail(component,event, selectData);
                        break;
                    }
                    case 'InsertArticle' : {
                        helper.insertArticleToEmail(component,event, selectData);
                        break;
                    }
                    default : { break;}
                }

            }catch(error){
                component.set("v.isShowSpinner", false);
                helper.showToastMessage(error.message, 'error', 'Error!');
            }            
            
        }       
        
    }
})