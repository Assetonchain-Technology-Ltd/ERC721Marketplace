const configdata = require('../model/config.model');
const logger = require('../lib/logger');

exports.test = function (req,res){
	res.send('Testinggggg');
};
//Name        : getTokeninfo
//In          : Null or query with params symbol
//Out         : If Null is given as input, it will returns all token-info-data records in desc
//				order
//				If symbol is given as parameter, it will returns the specific symbol record.
//				If any error occurs, status 500 will be return with error message
//Description : Get token-info-data records, it uses symbol field for filtering, by default, it wil return all token-info-data records and if symbol param is given, it will return the specific record with the given symbol 
exports.getConfigdata = function(req,res){
		let contractname = req.query.contractname;
		if(typeof contractname !== 'undefined' && contractname){
			configdata.find({contract:contractname},function(err,docs){
					if(err){
						logger.error(`ConfigData getConfigdata(C = ${contractname}) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`ConfigData getConfigdata(S = ${contractname}) -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}
			})
		}else{
			configdata.find({},null,{sort: {contract:-1}},function(err,docs){
					if(err){
						logger.error(`ConfigData getConfigdata(default) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`ConfigData getConfigdata(default) - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}

					});
		}
};

exports.updateConfigdata = function(req,res){
		if(req.body.key && req.body.value){
			configdata.updateOne(req.body.key,req.body.value,function(err,docs){
				if(err){
					logger.error(`ConfigData Update Fail (key = ${req.body.key.toString()}) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.status(500).send(err);
				}else{
					logger.info(`ConfigData Update Success (key = ${req.body.key.toString()}) -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.send(docs);
				}
			});
		}else{
			logger.error(`ConfigData update - No key/value paire detected - ${req.originalUrl} - ${req.method} - ${req.ip}`);
			res.status(500).send({error:"Key/Value pair not detected"});
		}
};
