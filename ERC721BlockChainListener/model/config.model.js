const mongoose = require('mongoose');
const Schema = mongoose.Schema;


//for the Date type in mongodb, it will automatically adjust the value to GMT+0, it is need to recover the time by adjust timezone on getting value.
let ConfigSchema= new Schema({
	contract:{type: String, required: true},
	address:{type: String, required: true},
	lastblock:{type: Number, required:false},
	eventlist : {type: [String], required: false}
	});



module.exports = mongoose.model('configdata',ConfigSchema,'config');
