import axios from 'axios';

const api = axios.create({
	baseURL: 'http://127.0.0.1:5000'
});

export const listAllDiamond = ()=> api.post('/diamondtoken/listAllDiamond');
export const listAllTrade = ()=> api.post('/orderbook/listAllTrade');
export const listAllOrder = ()=> api.post('/expensebook/listAllOrder');

const apis={

	listAllDiamond,
	listAllTrade,
	listAllOrder
}
export default apis;


