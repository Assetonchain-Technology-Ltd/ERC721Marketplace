import React, { Component } from 'react';
import api from '../api';
import MUIDataTable from 'mui-datatables';
import Button from '@material-ui/core/Button';

class Expensebook extends Component {
	constructor(props){
		super(props);
		this.state = {
			orders :[],
			isLoading: false
		}
	}

	componentDidMount = async()=>{
		this.setState({isLoading:true});
			await api.listAllOrder().then(res=>{
					this.setState({
						orders:res.data,
						isLoading: false
					});
			}) // end await
	}//end async()
	
	render() {
		const {orders, isLoading} = this.state;
		const columns = [
			{
				label : 'TradeID',
				name : 'TradeID',
				options : {
					filter: true,
					sort: true
				}
			},
			{
				label : 'OrderID',
				name : 'OrderID',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Seller',
				name : 'seller',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Buyer',
				name : 'buyer',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Item',
				name : 'itemID',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Price',
				name : 'price',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Min.Deposit',
				name : 'mindeposit',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'Payment',
				name : 'payment',
				options : {
					filter: true,
					sort: true
				}
				
			},
			{
				label : 'fees %',
				name : 'feesprecentage',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'State',
				name : 'state',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'OPEN Datetime',
				name : 'OPEN_createdate',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'PSET Datetime',
				name : 'PSET_createdate',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'PART Datetime',
				name : 'PART_createdate',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'EXEC Datetime',
				name : 'EXEC_createdate',
				options : {
					filter : true,
					sort : true
				}
			},
			{
				label : 'CANC Datetime',
				name : 'CANC_createdate',
				options : {
					filter : true,
					sort : true
				}
			}
		];
		const options={
			filterType:'dropdown',
			serverSide: true,
		}
		return(
			<MUIDataTable 
				title={"Trade List"}
				columns={columns}
				data={trades}
				options={options}
			/>
		)
	}

}

export default Orderbook
