const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let PaymentBookSchema= new Schema({
	salesID : {type : Number , required:true },
	paymentID : {type : Number , required:true,unique:true},
	payer :{type: String, required: true},
	amount :{type: Number, required:true},
	state:{type:String ,required:true},
	tx:{type:String ,required:false,default:"NA"},
	br:{type:String ,required:false,default:"NA"},
	paymentType:{type:Number ,required:false,default:0},
	settlementDate:{type:Number ,required:false,default:0},
	seq:{type:Number ,required:false,default:0},
	"P-SETTLE_createdate":{type: Number, required:false,default:0},
	SETTLE_createdate:{type: Number,required:false,default:0},
	CANCEL_createdate:{type: Number,required:false,default:0},
	REJECT_createdate:{type: Number,required:false,default:0}
	});



module.exports = mongoose.model('paymentbook',PaymentBookSchema);
