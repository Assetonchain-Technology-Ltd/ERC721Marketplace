const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let OrderBookSchema= new Schema({
	TradeID : {type : Number , required:true , unique:true},
	OrderID : {type : Number , required:true , unique:true},
	seller :{type: String, required: true},
	buyer :{type: String, required: false},
	itemID:{type: String ,required: true},
	price :{type: Number, required:true},
	mindeposit :{type: Number, required:true},
	payment : {type:Number,required:false,default:0},
	feesprecentage :{type: Number, required:false},
	state:{type:String ,required:true},
	OPEN_createdate:{type: Number, required:false,default:0},
	PSET_createdate:{type: Number,required:false,default:0},
	PART_createdate:{type: Number,required:false,default:0},
	EXEC_createdate:{type: Number,required:false,default:0},
	CANC_createdate:{type: Number,required:false,default:0}
	});



module.exports = mongoose.model('Orderbook',OrderBookSchema);
