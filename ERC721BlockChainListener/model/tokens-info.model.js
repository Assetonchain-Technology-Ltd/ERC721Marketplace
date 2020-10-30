const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let TokensInfoDataSchema= new Schema({
	SYMBOL:{type: String, required: true, unique: true},
	ADDRESS:{type: String, required: true},
	START_BLOCK:{type: String, required:false},
	DECIMAL:{type: Number, required:true},
	TOTAL_SUPPLY:{type: Number, required:false},
	TIMEZONE:{type: String, required:false},
	MARKTIME:{type: String, required:false},
	HISTORY_COUNT:{type: Number, required:false},
	MEMBERS:{type: [String], required:false},
	//New field from Requirement 1.4 31/03/2020
	priceupdateinterval:{type: String,required: true, default:"snap"},
	pricefeedmode:{type: String,required: true, default: "RESTFUL"},
	pricehost:{type: String,required: true},
	priceAPIname:{type: String,required:true},
	basecurrency:{type: String,required:true,default:"HKD"}
	});



module.exports = mongoose.model('TokensInfoData',TokensInfoDataSchema,'tokens-info');
