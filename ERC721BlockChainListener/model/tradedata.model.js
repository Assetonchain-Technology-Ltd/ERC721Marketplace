const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let TradeDataSchema= new Schema({
	tradedatetime:{type: Date, required: true},
	tradeprice:{type: Schema.Types.Decimal128, required: true},
	qty:{type: Schema.Types.Decimal128,required: true},
	ethtransaction:{type: String, required:false},
	currecny:{type:String,default: "USD"},
	insertdatetime:{type: Date, default: Date.now }
		});



module.exports = mongoose.model('TradeData',TradeDataSchema);
