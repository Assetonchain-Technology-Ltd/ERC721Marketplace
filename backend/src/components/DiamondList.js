import React, { Component } from 'react';
import api from '../api';
import MUIDataTable from 'mui-datatables';
import Button from '@material-ui/core/Button';

class DiamondList extends Component {
	constructor(props){
		super(props);
		this.state = {
			diamonds :[],
			isLoading: false
		}
	}

	componentDidMount = async()=>{
		this.setState({isLoading:true});
			await api.listAllDiamond().then(res=>{
					this.setState({
						diamonds:res.data,
						isLoading: false
					});
			}) // end await
	}//end async()
	
	render() {
		const {diamonds, isLoading} = this.state;
		const columns = [
			{
				label : 'ItemID',
				name : 'itemID',
				options : {
					filter: true,
					sort: true
				}


			},{
				label: 'URL',
				name : 'itemURL',
			},{
				label : 'CurrentOwner',
				name : 'currentOwner',
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
				title={"Diamond List"}
				columns={columns}
				data={diamonds}
				options={options}
			/>
		)
	}

}

export default DiamondList
