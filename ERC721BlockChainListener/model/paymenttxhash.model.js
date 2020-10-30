const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let PaymentTxHashSchema= new Schema({
	paymentID : {type : Number , required:true},
	action :{type: String ,required: true},
	txhash :{type: String, required:true,unique:true},
	state :{type: String, required:true},
	date:{type: Number, required:false},
	});



module.exports = mongoose.model('PaymentTxHash',PaymentTxHashSchema);
