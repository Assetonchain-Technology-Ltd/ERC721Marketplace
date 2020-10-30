const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let DiamondTokenSchema= new Schema({
	itemID:{type: String, required: true, unique: true},
	itemURL:{type: String, required: true},
	currentOwner:{type: String, required:true},
	latesttxHash: {type: String, required: false},
	creationtxHash: {type: String, required: false},
	blockchainstatus: {type: String, required: false}
	});



module.exports = mongoose.model('diamondtoken',DiamondTokenSchema);
