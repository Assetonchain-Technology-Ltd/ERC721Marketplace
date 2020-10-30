const videodata = require('../model/videodata.model');
const logger = require('../lib/logger');

exports.test = function (req,res){
	res.send('Testinggggg');
};

//Name        : insert
//In          : video record in json format, post in body with batch as key
//Out         : If all records are valid according to model specification, records will be save 
//				in DB and original records will be return
//				If any validation error is occured, error will return and nothing will be save
//				in DB
//Description :Insert Video Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter
exports.insert = function(req,res){
	if(req.body.batch){
		//Use insertMany to validate the doc before save, all or nothing
		videodata.insertMany(req.body.batch,function(err,docs){
				if(err){
					logger.error(`VideoData insert - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.status(500).send(err);
				}
				else{
					logger.info(`VideoData insert - ${req.originalUrl} - ${req.method} - ${req.ip}`);
					res.json(req.body);

				}
		});		
	}
	else{
		logger.error(`VideoData insert - No Batch detected - ${req.originalUrl} - ${req.method} - ${req.ip}`);
		res.status(500).send({error:"No Batch detected"});
	}

};

//Name        : getVideo
//In          : Null or query with params days  
//Out         : If Null is given as input, it will returns all video records in desc order
//				If days is given as parameters, it will returns pervious N days video records
//				including today
//				If any error occurs, status 500 will be return with error message
//				As mongodb will store date in GMT+0, so it is need to restore the currenct time 
//				zone for display
//Description : Get video records, it uses vaildFrom field for filtering, by default, it wil return all video records and if days param is given, it will get those video with videodatetime > today-5 including today. 
exports.getVideo= function(req,res){
		let days = req.query.days*1;
		if(Number.isInteger(days)){
			let targetdate=new Date();
			targetdate.setDate(targetdate.getDate()-days);
			videodata.find({validFrom:{$gt:targetdate}},function(err,docs){
					if(err){
						logger.error(`VideoData getVideo(days = ${days}) - ${targetdate} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`VideoData getVideo(days = ${days}) - ${targetdate} -  ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}
			})
		}else{
			videodata.find({},null,{sort: {date:-1}},function(err,docs){
					if(err){
						logger.error(`VideoData getVideo(default) - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.status(500).send(err);
					}else{
						logger.info(`VideoData getVideo(default) - ${req.originalUrl} - ${req.method} - ${req.ip}`);
						res.send(docs);
					}

					});
		}
};
