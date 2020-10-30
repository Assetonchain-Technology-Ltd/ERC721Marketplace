const tradedata = require('../model/tradedata.model');
const logger = require('../lib/logger');

exports.test = function (req,res){
	res.send('Testinggggg');
};

//Name        : insert
//In          : trade record in json format, post in body with batch as key
//Out         : If all records are valid according to model specification, records will be save 
//				in DB and original records will be return
//				If any validation error is occured, error will return and nothing will be save
//				in DB
//Description :Insert Trade Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter
exports.insert = function(req,res){
	if(req.body.batch){
		//Use insertMany to validate the doc before save, all or nothing
		tradedata.insertMany(req.body.batch,function(err,docs){
				if(err){
					logger.error(`TradeData insert - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.status(500).send(err);
				}
				else{
					logger.info(`TradeData insert - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.json(req.body);

				}
		});		
	}
	else{
		logger.error(`TradeData insert - No Batch detected - ${req.originalUrl} - ${req.method} - ${req.ip}`);
		res.status(500).send({error:"No Batch detected"});
	}

};

//Name        : getTrade 
//In          : Null or query with params days  
//Out         : If Null is given as input, it will returns latest 5 trade records  
//				If days is given as parameters, it will returns pervious N days trade records
//				including today
//				If any error occurs, status 500 will be return with error message
//				As mongodb will store date in GMT+0, so it is need to restore the currenct time 
//				zone for display
//Description : Get Trade records, it uses tradedatetime field for filtering, by default, it wil return 5 latest trade records and if days param is given, it will get those trade with tradedatetime > today-5 including today. 
exports.getTrade = function(req,res){
		let days = req.query.days*1;
		if(Number.isInteger(days)){
			let targetdate=new Date();
			targetdate.setDate(targetdate.getDate()-days);
			console.log("getTrade days =:"+days+" Target Date:"+targetdate)
			tradedata.find({tradedatetime:{$gt:targetdate}},function(err,docs){
					if(err){
						logger.error(`TradeData getTrade(days = ${days}) - ${targetdate} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`TradeData getTrade(days = ${days}) - ${targetdate} -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}
			})
		}else{
			tradedata.find({},null,{sort: {tradedatetime:-1},limit:5},function(err,docs){
					if(err){
						logger.error(`TradeData getTrade(default) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`TradeData getTrade(default) - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}

					});
		}
};
