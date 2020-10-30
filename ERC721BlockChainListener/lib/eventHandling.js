
const arequest = require('axios');
const logger = require('./logger');

exports.handleNewTokenEvent = function(res,baseURL){
	let blockNumber = res.blockNumber;
	let txhash = res.transactionHash;
	let owner = res.data.owner;
	let url = res.data.url;
	let itemID = res.data.itemid;
	let insertobj = {"batch": [
						 {
							"itemID": itemID,
							"itemURL": url,
							"currentOwner": owner,
							"latesttxHash": txhash,
							"creationtxHash": txhash,
							"blockchainstatus" : blockNumber?"Mined":"Pending"
						 }	
					]};
	logger.info(`[APP] Event NewToken Triggered : ${itemID}`);	
	//add token to ERC721 table
	arequest.post(`${baseURL}/diamondtoken/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event NewToken Insert new diamond token : ${itemID}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event NewToken Insert fail : ${error}`);	
	})
	if(blockNumber){
		arequest.post(`${baseURL}/configdata/update`,{"key" :{"contract":this.contractname} ,"value":{"lastblock": blockNumber}})
		.then((res)=>{
			logger.info(`[APP] Event ${this.contractname} lastblock updated : ${blockNumber}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event ${this.contractname} lastblock updated fail : ${blockNumber}`);	
		})

	}

}

exports.handleNewOrderRequest = function(res,baseURL){
	let blockNumber = res.blockNumber;
	let txhash = res.transactionHash;
	let orderid = res.data.ad;
	let seller = res.data.seller;
	let itemID = res.data.itemID;
	let price = res.data.p;
	let feesprecentage = res.data.f;
	let currency = res.data.c;
	let paymenttype = res.data.pt;
	let date = res.data.d;
	let insertobj = {"batch": [
						 {
							"orderID": orderid,
							"seller": seller,
							"itemID": itemID,
							"price": price,
							"feesprecentage": feesprecentage,
							"currency": currency,
							"paymenttype": paymenttype,
							"state" : "OI",
							"OI_createdate" : date,
							"blockchainstatus" : blockNumber?"Mined":"Pending"
						 }	
					]};
	logger.info(`[APP] Event Expensebook NewOrderRequest Triggered : ${orderid} for item ${itemID}`);	
	//add token to ERC721 table
	arequest.post(`${baseURL}/expensebook/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Expensebook Insert Order : ${orderid} for item ${itemID}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Expensebook Insert Order fail : ${orderid} : ${error}`);	
	})
	insertobj = {"batch": [
						 {
							"orderID": orderid,
							"action": "createOrderRequest", 
							"txhash": txhash,
							"state" : "OI",
							"date"  : date
						 }	
	]};
	arequest.post(`${baseURL}/expensetxhash/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Expensebook Insert ExpenseTxHash Order : ${orderid} for item ${itemID}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Expensebook Insert ExpenseTxHash Order fail : ${orderid} : ${error}`);	
	})
	if(blockNumber){
		arequest.post(`${baseURL}/configdata/update`,{"key" :{"contract":this.contractname} ,"value":{"lastblock": blockNumber}})
		.then((res)=>{
			logger.info(`[APP] Event ${this.contractname} lastblock updated : ${blockNumber}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event ${this.contractname} lastblock updated fail : ${blockNumber}`);	
		})

	}

}


exports.erc721TransferEvent = function(res,baseURL){
							let blockNumber = res.blockNumber;
							let txhash = res.transactionHash;
							let to = res.data.to;
							let itemID = res.data.tokenId;
							let key = {"itemID": itemID};
							let value = { "currentOwner" : to , "latesttxHash" : txhash , "blockchainstatus" : blockNumber?"Mined":"Pending" };
							console.log(value);
							logger.info(`[APP] Event Transfer diamond Triggered : ${itemID}`);	
							//add token to ERC721 table
							arequest.post(`${baseURL}/diamondtoken/update`,{key,value})
							.then((res)=>{
								logger.info(`[APP] Event Transfer diamond token update : ${itemID}`);	
							})
							.catch((error)=>{
								logger.error(`[APP] Event Transfer diamond update fail : ${error.toString()}`);	
							})

							if(blockNumber){
								arequest.post(`${baseURL}/configdata/update`,{"key" :{"contract":this.contractname} ,"value":{"lastblock": blockNumber}})
								.then((res)=>{
									logger.info(`[APP] Event ${this.contractname} lastblock updated : ${blockNumber}`);	
								})
								.catch((error)=>{
									logger.error(`[APP] Event ${this.contractname} lastblock updated fail : ${blockNumber}`);	
								})
							}
}

exports.handleOrderStatusChangeEvent = function(res,baseURL){
		let blockNumber = res.blockNumber;
		let txhash = res.transactionHash;
		let orderid = res.data.ad;
		let action = res.data.action;
		let ostatus = res.data.status;
		let datetime= res.data._datetime;
		let key = {"orderID":orderid};
		let fieldname = `${ostatus}_createdate`;
		let value = {"state":ostatus,[fieldname]:datetime};
		logger.info(`[APP] Event OrderStatusChange Triggered : ${orderid} , staus :${ostatus}`);	
		arequest.post(`${baseURL}/expensebook/update`,{key ,value})
		.then((res)=>{
			logger.info(`[APP] Event OrderStatusChange Update Order ${orderid} state : ${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event OrderStatusChange Update Order ${orderid} Fail state : ${ostatus}`);	
		})
		//add token to ERC721 table
		let insertobj = {"batch": [
							 {
								"orderID": orderid,
								"action": action, 
								"txhash": txhash,
								"state" : ostatus,
								"date"  : datetime, 
							 }	
		]};
		arequest.post(`${baseURL}/expensetxhash/insert`,insertobj)
		.then((res)=>{
		logger.info(`[APP] Event OrderStatusChange epensetxhash Insert : ${orderid} , staus :${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event OrderStatusChange expensetxhash Insert fail : ${error.toString()}`);	
		})

}

exports.handleNewTrade = function(res,baseURL){
	let blockNumber = res.blockNumber;
	let txhash = res.transactionHash;
	let tradeid = res.data.t;
	let orderid = res.data.o;
	let seller = res.data.seller;
	let itemID = res.data.itemID;
	let price = res.data.p;
	let mindeposit = res.data.m
	let date = res.data._datetime;
	let insertobj = {"batch": [
						 {
							"OrderID": orderid,
							"TradeID": tradeid,
							"seller": seller,
							"itemID": itemID,
							"price": price,
							"mindeposit": mindeposit,
							"state" : "OPEN",
							"OPEN_createdate" : date,
						 }	
					]};
	logger.info(`[APP] Event Orderbook NewTrade Triggered : ${tradeid} for item ${itemID}`);	
	//add token to ERC721 table
	arequest.post(`${baseURL}/orderbook/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Orderbook Insert Trade : ${tradeid} for item ${itemID}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Orderbook Insert Trade fail : ${tradeid} : ${error}`);	
	})
	insertobj = {"batch": [
						 {
							"tradeID": tradeid,
							"action": "OpenTrade", 
							"txhash": txhash,
							"state" : "OPEN",
							"date"  : date
						 }	
	]};
	arequest.post(`${baseURL}/ordertxhash/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Orderbook Insert OrderTxHash Trade : ${tradeid} for item ${itemID}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Orderbook Insert OrderTxHash Trade fail : ${tradeid} : ${error}`);	
	})
	if(blockNumber){
		arequest.post(`${baseURL}/configdata/update`,{"key" :{"contract":this.contractname} ,"value":{"lastblock": blockNumber}})
		.then((res)=>{
			logger.info(`[APP] Event ${this.contractname} lastblock updated : ${blockNumber}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event ${this.contractname} lastblock updated fail : ${blockNumber}`);	
		})

	}

}


exports.handleTradeStatusChangeEvent = function(res,baseURL){
		let blockNumber = res.blockNumber;
		let txhash = res.transactionHash;
		let tradeid = res.data.ad;
		let action = res.data.action;
		let buyer = res.data.b;
		let payment = res.data.p;
		let date = res.data.d;
		let ostatus = res.data.status;
		let key = {"TradeID":tradeid};
		let fieldname = `${ostatus}_createdate`;
		let value = {"state":ostatus,"buyer":buyer,[fieldname]:date,"payment":payment};
		logger.info(`[APP] Event TradeStatusChange Triggered : ${tradeid} , staus :${ostatus}`);	
		arequest.post(`${baseURL}/orderbook/update`,{key ,value})
		.then((res)=>{
			logger.info(`[APP] Event TradeStatusChange Update Trade ${tradeid} state : ${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event TradeStatusChange Update Trade ${tradeid} Fail state : ${ostatus}`);	
		})
		//add token to ERC721 table
		let insertobj = {"batch": [
							 {
								"tradeID": tradeid,
								"action": action, 
								"txhash": txhash,
								"state" : ostatus,
								"date"  : date
							 }	
		]};
		arequest.post(`${baseURL}/ordertxhash/insert`,insertobj)
		.then((res)=>{
		logger.info(`[APP] Event TradeStatusChange ordertxhash Insert : ${tradeid} , staus :${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event TradeStatusChange ordertxhash Insert fail : ${error.toString()}`);	
		})

}

exports.handleNewPayment = function(res,baseURL){
	let blockNumber = res.blockNumber;
	let txhash = res.transactionHash;
	let salesid = res.data.s;
	let paymentid = res.data.pid;
	let payer = res.data.p;
	let amount = res.data.a;
	let status = res.data.state;
	let ptype = res.data.ptype;
	let seq = res.data._seq;
	let date = res.data._datetime;
	let insertobj = {"batch": [
						 {
							"salesID": salesid,
							"paymentID": paymentid,
							"payer": payer,
							"amount": amount,
							"state": status,
							"paymentType": ptype,
							"seq" : seq,
							"P-SETTLE_createdate" : date,
						 }	
					]};
	logger.info(`[APP] Event Paymentbook New Payment Triggered : ${paymentid} for Trade ${salesid}`);	
	//add token to ERC721 table
	arequest.post(`${baseURL}/paymentbook/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Paymentbook Insert Payment : ${paymentid} for Trade ${salesid}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Paymentbook Insert Payment fail : ${paymentid} for Trade ${salesid}`);	
	})
	insertobj = {"batch": [
						 {
							"paymentID": paymentid,
							"action": status, 
							"txhash": txhash,
							"state" : status,
							"date"  : date
						 }	
	]};
	arequest.post(`${baseURL}/paymenttxhash/insert`,insertobj)
	.then((res)=>{
		logger.info(`[APP] Event Paymentbook Insert PaymentTxHash  : ${paymentid} for trade ${salesid}`);	
	})
	.catch((error)=>{
		logger.error(`[APP] Event Paymentbook Insert PaymentTxHash Fail  : ${paymentid} for trade ${salesid}`);	
	})
	if(blockNumber){
		arequest.post(`${baseURL}/configdata/update`,{"key" :{"contract":this.contractname} ,"value":{"lastblock": blockNumber}})
		.then((res)=>{
			logger.info(`[APP] Event ${this.contractname} lastblock updated : ${blockNumber}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event ${this.contractname} lastblock updated fail : ${blockNumber}`);	
		})

	}

}

exports.handlePaymentStatusChangeEvent = function(res,baseURL){
		let blockNumber = res.blockNumber;
		let txhash = res.transactionHash;
		let paymentid = res.data.ad;
		let ostatus = res.data.status;
		let tx = res.data.tx;
		let br = res.data.br;
		let settlementdate  = res.data.s;
		let date = res.data._datetime;
		let paymentType = res.data._ptype;
		let key = {"paymentID":paymentid};
		let fieldname = `${ostatus}_createdate`;
		let value = {"state":ostatus,"tx":tx,"br":br,"settlementDate":settlementdate,[fieldname]:date};
		logger.info(`[APP] Event PaymentStatusChange Triggered : ${paymentid} , status :${ostatus}`);	
		arequest.post(`${baseURL}/paymentbook/update`,{key ,value})
		.then((res)=>{
			logger.info(`[APP] Event PaymentStatusChange Update Payment ${paymentid} state : ${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event PaymentStatusChange Update Payment ${paymentid} Fail state : ${ostatus}`);	
		})
		//add token to ERC721 table
		let insertobj = {"batch": [
							 {
								"paymentID": paymentid,
								"action": ostatus, 
								"txhash": txhash,
								"state" : ostatus,
								"date"  : date
							 }	
		]};
		arequest.post(`${baseURL}/paymenttxhash/insert`,insertobj)
		.then((res)=>{
		logger.info(`[APP] Event PaymentStatusChange paymenttxhash Insert : ${paymentid} , staus :${ostatus}`);	
		})
		.catch((error)=>{
			logger.error(`[APP] Event PaymentStatusChange paymenttxhash Insert Fail : ${paymentid} , staus :${ostatus}`);	
		})

}

