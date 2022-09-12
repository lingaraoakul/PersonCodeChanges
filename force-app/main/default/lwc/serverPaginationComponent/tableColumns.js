export const columns = [
    {
        label: 'Account Name',
        type:'url',
        fieldName: 'accountUrl',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            }
        }
    },
    {
        label:'Rating',
        type:'imageValue',
        fieldName:'Rating',
        typeAttributes: {
            imageUrl: {
                fieldName:'Rating_Ststus__c'
            }
        }
    },
    {
        label: "Created Date",
        fieldName: "CreatedDate",
        type: "date",
        typeAttributes:{
            year: "numeric",
            month: "numeric",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit"
        }
    }
];
