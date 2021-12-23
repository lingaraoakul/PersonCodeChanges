/**    
    * Created By     : Linga
    * Created Date   : 15/11/2021
    * Description    : Article Search, based on Selected Term and Language
    * Class     	 : CaseKnowledgeSearchController
    * Aura Component : Case_knowledgeSearchAura
    * LWC            : case_knowledgeSearch
 */
import { LightningElement, wire, track, api } from 'lwc';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_LANGUAGE from '@salesforce/schema/Case.Language';
import CONTACT_LANGUAGE from '@salesforce/schema/Case.Contact.Contact_Language__c';

// Import Server call modules
import getLanguageOptions from '@salesforce/apex/CaseKnowledgeSearchController.getLanguageOptions';
import getSetupData from '@salesforce/apex/CaseKnowledgeSearchController.getSetupData';
import getSearchKnowledgeList from '@salesforce/apex/CaseKnowledgeSearchController.getSearchKnowledgeList';

// Import Page Navigation Modules
import { NavigationMixin } from 'lightning/navigation';

const DELAY_TIME = 1000;

export default class Case_knowledgeSearch extends NavigationMixin(LightningElement) {

    @api recordId;    
    // UI Attributes
    searchTerm = '';
    languageCode = '';   
    searching = 'Searching...';

    //Class variables     
    searchList = [];    
    initialData = [];
    displayArticles = [];
    langOptions = [];    
    languageMetadata;
    defaultLanguageCode = '';
    
    searchDone = false;
    @track blurTimeout;  

    //default css styles
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = ''; 
    
    // get Language options from metadata records and sort the Language options for dropdown
    @wire(getLanguageOptions)
    languageOptions({error, data}){
        if(data){  
            this.languageMetadata = data;
            let siteLanguageOptions = [];
            let _langOptions = [];

            [...data].forEach(item=>{
                if(item && item["Is_Site_Language__c"]){
                    siteLanguageOptions = [...siteLanguageOptions, {
                        "label":item["MasterLabel"],
                        "value":item["DeveloperName"],
                        "description":item["Domain__c"]
                    }]
                }else if(item && !item["Is_Site_Language__c"]){
                    _langOptions = [..._langOptions,{
                        "label":item["MasterLabel"],
                        "value":item["DeveloperName"]
                    }]
                }
            })
            siteLanguageOptions.sort((a,b)=> (a.label > b.label) ? 1 : -1);                        
            _langOptions.sort((a,b)=> (a.label > b.label) ? 1 : -1); 

            this.langOptions = [...siteLanguageOptions, ..._langOptions];
            
        }else if(error){
          
        }
    }
    // It fires when ever Case record is updated
    @wire(getRecord, {recordId: '$recordId', fields:[CASE_LANGUAGE, CONTACT_LANGUAGE]})
    caseData({error, data}){
        if(data){
            let caseLang = getFieldValue(data, CASE_LANGUAGE);
            let conLan = getFieldValue(data, CONTACT_LANGUAGE);
            this.searchDone = false;
            // Set up Initial suggested Articles for case
            this.setInitialData(this.recordId);           
        }
    }  
    // Get suggested articles for case based on case Subject, case Description and case Language or contact Language or default Enaglish
    setInitialData(caseId){        
        getSetupData({recordId: caseId})
        .then(result => {
            this.searchTerm = '';
            this.languageCode = result.defaultLanguage;   
            this.defaultLanguageCode = result.defaultLanguage;        
            this.initialData = result.articlesData; 
            this.displayArticles = result.articlesData;                          
        })
        .catch(error => {
            this.displayArticles =[];      
        })
    } 
    
    // Search Articles, based on search term and selected language
    SearchKnowledgeList(){
        getSearchKnowledgeList({searchKey : this.searchTerm, languageCode :this.languageCode, caseId : this.recordId})        
        .then(result => {
            this.searching = 'Search Results';
            this.searchList = result;           
            if(this.searchDone) {
                this.displayArticles = result;                          
            } 
        })
        .catch(error => {
            this.displayArticles =[];  
            this.searching = 'Search Results';
        })
    }

    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    searchKnowledge(event){

        const searchKey = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.searchTerm = searchKey;       
        this.searching = 'Searching...';
        if(event.keyCode === 13){    
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';        
            this.searchDone = true;           
           this.SearchKnowledgeList();
        }else {
            this.delayTimeout = setTimeout(() =>{
            this.SearchKnowledgeList();            
                }, DELAY_TIME); 
        }        
        
    }

    // Handle Click events for Input Search box
    handleClick() {        
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }
    // Handle onblur event
    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    // Redirect to Article Detail page when agent select record over a search dropdown
    handleSelect(event){
        let selectedId = event.currentTarget.dataset.recordId;              
       if(this.blurTimeout) {
        clearTimeout(this.blurTimeout);
       }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';

        if(selectedId){                       
          this.reDirectToKnowledge(selectedId);  
        }
        
    }
    // search Articles, based on selected Language
    handleLanguage(event){
        this.searching = 'Searching...';
        this.languageCode = event.target.value;  
        this.searchDone = true; 
        this.SearchKnowledgeList();      
    }   
    // Set Initial data to Search List
    backToInitialData(event){
        this.searchTerm = '';
        this.languageCode = this.defaultLanguageCode;
        this.searchDone = false;
        this.displayArticles = this.initialData;
    }
    // Handle Dropdown actions
    handleOnselect(event){

        try{
            let selectedValue = event.detail.value;
            let selectedRecord = event.target.dataset.recordId;
         
            let data = this.displayArticles.find(item => item["articleRecord"]["Id"] === selectedRecord );
            let site = this.domainName;            
            
            if(!site && selectedValue === 'InsertURL') return;            

            data = {...data["articleRecord"], "actionType":selectedValue, "caseId":this.recordId, "siteName":site};
            data = JSON.stringify(data);  
                  
            // Pass a data to Parent component through custom event
            const selectedEvt = new CustomEvent("handleaction",
                                        {detail: {"data" : data}});
            this.dispatchEvent(selectedEvt);

        }catch(error){
          
        }     
        
    }     

    // get Search list length
    get isListAvailable(){
        return this.displayArticles && this.displayArticles.length > 0 ;
    }    

    // get Site Name
    get domainName(){
        let _siteName;
        if(this.languageMetadata && this.languageCode){
            _siteName = [...this.languageMetadata].find(item => item["DeveloperName"] === this.languageCode)?.["Domain__c"];
        }
        return _siteName;
    }

    // Redirect To Article detail Page.
    reDirectToKnowledge(selectedId) {        
        
        this[NavigationMixin.Navigate]({
            type : 'standard__recordPage',
            attributes : {
                recordId : selectedId,
                actionName : 'view'
            }
        });
        
    }   
    
}