// Libaray declare
const Eventlistener = require('./blockchainEvent.js');
const express = require('express')
const path = require('path');
const cors = require('cors');
const mongoose = require('mongoose');
const request = require('request');
const arequest = require('axios');
const logger = require('./lib/logger');
const morgan = require('morgan');
const bodyParser = require('body-parser');
const eventhandler = require('./lib/eventHandling');

//app setting
const app = express();
app.use(cors());
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(morgan('combined', { stream: logger.stream }));

app.use(express.urlencoded({
    extended: true
}));
app.use(bodyParser.json());


// Variable declare
const PORT = process.env.PORT ||5000;
const PROVIDER = 'ws://172.16.0.223:8546';
const uri = "mongodb://172.16.0.223:27017/ERC721marketplace";
app.hosturl = process.env.HOSTNAME || `http://127.0.0.1:${PORT}`;

// Initial DB Connection
let mongoDB = process.env.MONGODB_URI || uri;
mongoose.connect(mongoDB,{useNewUrlParser: true});
mongoose.Promise = global.Promise;
let db = mongoose.connection;
db.on('err',err=>logger.error('MongoDB Connection Fail :',err));

//Router Declare
const configdata = require('./routes/configdata.route');
const diamondtoken = require('./routes/diamondtoken.route');
const expensebook = require('./routes/expensebook.route');
const expensetxhash = require('./routes/expenshash.route');
const orderbook = require('./routes/orderbook.route');
const ordertxhash = require('./routes/orderhash.route');
const paymentbook = require('./routes/paymentbook.route');
const paymenttxhash = require('./routes/paymenthash.route');



//Router mapping 
app.use('/configdata',configdata);
app.use('/diamondtoken',diamondtoken);
app.use('/expensebook',expensebook);
app.use('/expensetxhash',expensetxhash);
app.use('/orderbook',orderbook);
app.use('/ordertxhash',ordertxhash);
app.use('/paymentbook',paymentbook);
app.use('/paymenttxhash',paymenttxhash);
app.eventListenerlist={};


// Initialize configs with getTokensinfo and indexerlist
logger.info("[APP] Initial configs - eventListener")
request.post(
`${app.hosturl}/configdata/getConfigdata`,
{},
function(error,response,body){
	if(!error && response.statusCode==200){
			 let data = JSON.parse(body);
			 for(var i=0;i<data.length;i++){
			 	logger.debug(`Init eventListener for Config : ${data[i].contract}`);
    			const e = new Eventlistener(data[i].contract, data[i].address, data[i].lastblock, PROVIDER, data[i].eventlist);
			 	logger.debug(`Init eventListener for contract : ${data[i].contract}, Start Block: ${data[i].lastblock}`);
    			app.eventListenerlist[data[i].contract] = e;
				for(var j=0;j<data[i].eventlist.length;j++){
					switch (data[i].eventlist[j]){ // if case for 
						case "NewToken":
							e.addListener("0xf031a088aa7b1646f284daae9871f10581d991a0d4dcfe07f7834d04201680c5",res=>{eventhandler.handleNewTokenEvent(res,app.hosturl)});// addListener end
							break;
						case "Transfer":
							e.addListener("0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",res=>{eventhandler.erc721TransferEvent(res,app.hosturl)});// addListener end
							break;
						case "NewOrderRequest":
							e.addListener("0x40cb330bda5ab218abd314123e39f32e9c6c6e70ffbc6460c50e356b4b1da52b",res=>{eventhandler.handleNewOrderRequest(res,app.hosturl)});
							break;
						case "OrderStatusChange":
							e.addListener("0x18e6968414f33702467961559c1912d6c91683d964cc4a3aa8944716773ed787",res=>{eventhandler.handleOrderStatusChangeEvent(res,app.hosturl)});
							break;
						case "NewTrade":
							e.addListener("0x41d7f52773753000e5b420ad5cbce5826fc7970fd9c04de1b84b3e96a69b28ca",res=>{eventhandler.handleNewTrade(res,app.hosturl)});
							break;
						case "TradeStatusChange":
							e.addListener("0x1cffbf78721f1394874a2ca49635a3941549d1f17edb7aee215cb4f4d2daa4a8",res=>{eventhandler.handleTradeStatusChangeEvent(res,app.hosturl)});
							break;
						case "NewPayment":
							e.addListener("0x8d794f3206c39a72f656444daebc25ce9c948f93533fb8426cd0270e76fed088",res=>{eventhandler.handleNewPayment(res,app.hosturl)});
							break;
						case "PaymentStatusChange":
							e.addListener("0xf0d340fc4adda45d6b253fd9a94016d8806050a61b5c0010ffdae95e82413580",res=>{eventhandler.handlePaymentStatusChangeEvent(res,app.hosturl)});
							break;

						default:
							logger.info("[APP] No Event Match");
					} // switch case end 
				}
    			app.eventListenerlist[data[i].contract].start();
			 	logger.debug(`Init ${data[i].contract} Done`); 
			} // for loop end
		}else{
			logger.debug(`Init getConfigdata error`);
		}
	}
);

module.exports = app;

app.listen(process.env.PORT||5000,console.log('5000'));



