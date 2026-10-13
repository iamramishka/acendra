import {createHandler as reportingHandler} from '../admin-dashboard-stats/handler.mjs';
export const createHandler=options=>reportingHandler({...options,report:true});
