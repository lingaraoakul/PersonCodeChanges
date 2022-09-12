import { LightningElement, api } from 'lwc';

const RECORDS_PER_PAGE_OPTIONS = [
    { label: '10', value: 10 },
    { label: '20', value: 20 },
    { label: '30', value: 30 },
    { label: '100', value: 100 }
];

export default class ServerPaginationUtils extends LightningElement {
    @api pageNo;
    @api recordsTotal;

    recordsPerPage = 10;

    recordsPerPageOptions = RECORDS_PER_PAGE_OPTIONS;

    get pageSummary() {
        return `Page: ${this.pageNo}`;
    }

    get isPreviousButtonDisabled() {
        return parseInt(this.pageNo, 10) === 0;
    }

    get isNextButtonDisabled() {
        return this.recordsTotal !== parseInt(this.recordsPerPage, 10);
    }

    handlePreviousPage(event) {
        this.firePaginationChangeEvent(event.target.name);
    }

    handleNextPage(event) {
        this.firePaginationChangeEvent(event.target.name);
    }

    handleRecordsPerPageChange(event) {
        this.recordsPerPage = event.detail.value;
        this.firePaginationChangeEvent(event.target.name);
    }

    firePaginationChangeEvent(action) {
        this.dispatchEvent(
            new CustomEvent('paginationchange', {
                detail: {
                    action,
                    varLimit: this.recordsPerPage
                }
            })
        );
    }
}
