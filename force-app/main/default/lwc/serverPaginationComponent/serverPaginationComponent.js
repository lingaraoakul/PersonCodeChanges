/** Server Side Pagination component */
import { LightningElement } from 'lwc';
import { columns } from './tableColumns.js';
import getAccountData from '@salesforce/apex/DataTableServerController.getAccountData';

export default class ServerPaginationComponent extends LightningElement {

    columns = columns;
    records;
    preKey;
    nextKey;
    recordsPerPage = 10;

    dataMap = [];
    count = 0;
    isLoading = false;

    connectedCallback() {
        this.serverCalls();
    }

    serverCalls() {
        this.isLoading = true;
        getAccountData({varRequest : JSON.stringify(this.request)})
        .then((result) => {

            if(result?.length === 0) {
                return;
            }

            const index = this.dataMap?.findIndex( item => item.key === this.count);
            if(index !== -1) {
                this.dataMap[index].value = [result[0].Id, result[result.length -1].Id];
            } else {
                this.dataMap.push({
                    key: this.count,
                    value: [result[0].Id, result[result.length -1].Id]
                });
            }

            this.records = result?.map((record) => {
                return {
                    ...record,
                    accountUrl:`/lightning/r/Account/${record.Id}/view`
                }
            }) || [];
        })
        .catch((err) => {
            console.log('Error : '+JSON.stringify(err))
        })
        .finally(() => {
            this.isLoading = false;
        })
    }

    get recordsCount(){
        return this.records?.length ?? 0;
    }

    handlePaginationChange(event) {
        const {action, varLimit} = event.detail;
        this.recordsPerPage = varLimit;
        this.preKey = undefined;
        this.nextKey = undefined;

        switch (action) {
            case 'previous': {
                this.preKey = this.dataMap[this.count-1].value[0];
                this.nextKey = this.dataMap[this.count-1].value[1];
                this.dataMap.pop();
                this.count--;
                break;
            }
            case 'next': {
                this.nextKey = this.dataMap[this.count].value[1];
                this.count++;
                break;
            }
            case 'show': {
                this.dataMap = [];
                this.count = 0;
                break;
            }
            default: break;
        }
        this.serverCalls();
    }

    get request() {
        return {
            varLimit: this.recordsPerPage,
            preKey: this.preKey,
            nextKey: this.nextKey
        }
    }
}
