const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let TokenDymanicDataSchema= new Schema({
	SYMBOL:{type: String, required: true, unique: true},
	PRICE_HISTORY:{type :[Schema.Types.Decimal128] , required: false},
	BALANCE_HISTORY:{type :Object , required: false},
	});



module.exports = mongoose.model('TokenDymanicData',TokenDymanicDataSchema,'tokens-dynamic-data');
