const tokendymanicdata = require('../model/token-dymanic-data.model');
const _ = require('lodash');
const logger = require('../lib/logger');
const request = require('axios');
exports.test = function (req,res){
	res.send('Testinggggg');
};
//Name        : insert
//In          : tokendymanic record in json format, post in body with batch as key
//Out         : If all records are valid according to model specification, records will be save 
//				in DB and original records will be return
//				If any validation error is occured, error will return and nothing will be save
//				in DB
//Description :Insert tokens-dynamic-Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter
exports.insert = function(req,res){
	if(req.body.batch){
		//Use insertMany to validate the doc before save, all or nothing
		tokendymanicdata.insertMany(req.body.batch,function(err,docs){
				if(err){
					logger.error(`TokenDymanicData insert - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.status(500).send(err);
				}
				else{
					logger.info(`TokenDymanicData insert - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.json(req.body);

				}
		});		
	}
	else{
		logger.error(`TokenDymanicData insert - No Batch detected - ${req.originalUrl} - ${req.method} - ${req.ip}`);
		res.status(500).send({error:"No Batch detected"});
	}

};
//Name        : gettokendymaindata
//In          : Null or query with params symbol  
//Out         : If Null is given as input, it will returns all tokendymanic records in desc 
//				order
//				If symbol  is given as parameters, it will returns the specific record
//				If any error occurs, status 500 will be return with error message
//Description : Get tokendymanic records, it uses symbol field for filtering, by default, it wil return all tokendymanic records and if symbol param is given, it will return the specific record given by the symbol 
exports.gettokendymanicdata = function(req,res){
		symbol = req.query.symbol;
		if(typeof symbol !== 'undefined' && symbol){
			tokendymanicdata.find({SYMBOL:symbol},function(err,docs){
					if(err){
						logger.error(`TokenDymanicData gettokendymaindata(S = ${symbol}) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`TokenDymanicData gettokendymaindata(S = ${symbol}) -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}
			})
		}else{
			tokendymanicdata.find({},null,{sort: {symbol:-1}},function(err,docs){
					if(err){
						logger.error(`TokenDymanicData gettokendymaindata(default) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`TokenDymanicData gettokendymaindata(default) - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}

					});
		}
				
	
}

//Name        : getbalances
//In          : symbol string  
//Out	      : x
//
//Description :  
exports.getbalances = function(req,res){
      var symbol = req.params.symbol;
      if (req.app.indexerlist.hasOwnProperty(symbol)) {
		logger.info(`TokenDymanicData getbalances(S = ${symbol}) -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
        const decimal_factor = 10 ** (-req.app.configs[symbol].DECIMAL);
        var _balances = _.mapValues(req.app.indexerlist[symbol].getBalances(), b => b*decimal_factor);
        var orderedBal = _(_balances).toPairs().orderBy([1],['desc']).fromPairs().value();
        var memberCapChange = {};
		(async function(){
			let param={"symbol":symbol,"address":req.app.configs[symbol].MEMBERS};
			let supply=req.app.configs[symbol].TOTAL_SUPPLY;
			try{
				logger.info(`TokenDymanicData getbalances(S = ${symbol}) getavgvaluechange`);
				let resp= await request.post(`${req.app.hosturl}/avgvaluedata/getavgvaluechange`,param);
				for(let i=0;i<resp.data.length;i++){
					memberCapChange[resp.data[i].address]={"change":resp.data[i].changepercent,"qty":(resp.data[i].qty["$numberDecimal"]/supply*100)};
				}
        		res.status(200).json({
          		"data": _.mapValues(orderedBal, b => b.toString(10)),
          		"supply": req.app.configs[symbol].TOTAL_SUPPLY,
          		"members": memberCapChange
        		});
			}catch(error){
				logger.error(`TokenDymanicData getbalances(S = ${symbol}) getavgvaluechange - ${error} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
        		res.status(500).send({"function":"TokenDymanicData getbalances",
									  "error":"getavgvaluechange error",
									  "detail":error});
		 	}
		 })();//asyn getavgvaluechange end

      } else {
        	res.status(500).send({"function":"TokenDymanicData getbalances",
								  "error":"No Symbol found in the indexer",
								  "detail":Object.keys(req.app.indexerlist)});
      }
};

