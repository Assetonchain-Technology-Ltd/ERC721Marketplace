const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let ExpenseBookSchema= new Schema({
	orderID : {type : Number , required:true , unique:true},
	seller :{type: String, required: true},
	tradeID :{type: String, required: false,default:0},
	itemID:{type: String ,required: true},
	price :{type: Number, required:true},
	feesprecentage :{type: Number, required:true},
	currecny:{type:String,default: "HKD"},
	paymenttype:{type:Number, required:false},
	settlementdate:{type:Number, required:false,default:0},
	settlementReferenceURL:{type:String, required:false,default:""},
	paymentReferenceURL:{type:String, required:false,default:""},
	state:{type:String ,required:true},
	blockchainstatus:{type:String,required:false},
	OI_createdate:{type: Number, required:false,default:0},
	SC_createdate:{type: Number,required:false,default:0},
	INV_createdate:{type: Number,required:false,default:0},
	INVP_createdate:{type: Number,required:false,default:0},
	SETTLE_createdate:{type: Number,required:false,default:0},
	CANC_createdate:{type: Number,required:false,default:0}
	});



module.exports = mongoose.model('ExpensebookData',ExpenseBookSchema);
