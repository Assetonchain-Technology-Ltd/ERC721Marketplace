const pricehistory = require('../model/price_history.model');
const logger = require('../lib/logger');

exports.test = function (req,res){
	res.send('Testinggggg');
};

//Name        : insert
//In          : milestone record in json format, post in body with batch as key
//Out         : If all records are valid according to model specification, records will be save 
//				in DB and original records will be return
//				If any validation error is occured, error will return and nothing will be save
//				in DB
//Description :Insert MileStone Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter
exports.insert = function(req,res){
	if(req.body.batch){
		//Use insertMany to validate the doc before save, all or nothing
		pricehistory.insertMany(req.body.batch,function(err,docs){
				if(err){
					logger.error(`PriceHistory insert - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.status(500).send(err);
				}
				else{
					logger.info(`PriceHistory insert - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.json(req.body);
				}
		});		
	}
	else{
		logger.error(`PriceHistory insert - No Batch detected - ${req.originalUrl} - ${req.method} - ${req.ip}`);
		res.status(500).json({"function":"PriceHistory Insert","error":"No Batch detected"});
	}

};

//Name        : getPrice
//In          : symbol and currency
//Out         : Success : The latest update price record for that symbol and currency will be return 
//				Fail    : if either symbol or curreny is missing or empty , error 500 will be return
//Description : This function is used to return the latest update record on price for the specific symbol
exports.getPrice = function(req,res){
		let s = req.query.symbol;
		let c = req.query.currency;
		if(typeof s != "undefined" && typeof c != "undefined"){
			if(s !='' && s != null && c !='' && c != null){
				pricehistory.find({SYMBOL:s,CURRENCY:c},null,{sort:{updatedAt:-1},limit:1},function(err,docs){
						if(err){
								logger.error(`PriceHistory getPrice(symbol,currency) -S:=${s}, currency:=${c} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
								res.status(500).send(err);

						}else{
								logger.info(`PriceHistory getPrice(symbol,currency) -S:=${s}, currency:=${c} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
								res.send(docs);
						}

				});//find end
			}else{
				// Empty Parameter
						logger.error(`PriceHistory getPrice(symbol,currency) -S:=${s}, currency:=${c} Empty String is Found - ${req.originalUrl} - ${req.method} - ${req.ip}`);
				
						res.status(500).json({"function":"PriceHistory getPrice","error":"Symbol or Currency is emptry string"});
			}
		}else{
			// Mising Parameter
				logger.error(`PriceHistory getPrice symbol or currency is not supplied - ${req.originalUrl} - ${req.method} - ${req.ip}`);
				res.status(500).json({"function":"PriceHistory getPrice","error":"mising parameter symbol or currency"});
		}
};
