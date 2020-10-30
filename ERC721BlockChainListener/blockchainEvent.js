const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const logger = require('./lib/logger.js');

const Web3 = require('web3');
const eventEmitter = require('events');

module.exports = class Blockchainevent extends eventEmitter {
  constructor( contractname , address, startBlock, provider, eventlist) {
  	super();
	this.contractname = contractname;
	this.contractInterface = require(`openzeppelin-solidity/${contractname}.json`);
    this.address = address;
    this.startBlock = startBlock || 0;
    this.provider = provider;
    this.web3 = new Web3(this.provider);
	this.eventlist = eventlist;
    this.contract = new this.web3.eth.Contract(this.contractInterface.abi, this.address);
	this.subscriptionobj=[];
	this.input=[];
  }


  start() {
	  		for(var i = 0;i<this.eventlist.length;i++){
				const eventJsonInterface = this.web3.utils._.find(
				this.contract._jsonInterface,
				o => o.name === this.eventlist[i] && o.type === 'event',
				);
				this.input[eventJsonInterface.signature]=eventJsonInterface.inputs;
				logger.info(`[BlockchainEvent] address:${this.address} reg event : ${this.eventlist[i]} `) 
				logger.debug(`[BlockchainEvent] address:${this.address} Signature : ${eventJsonInterface.signature} `) 
				const subscription = this.web3.eth.subscribe('logs', {
				address: this.address,
				fromBlock : this.startBlock,
				topics : [eventJsonInterface.signature]
				}, (error, result) => {  // subscribe callback
				  if (!error) {
					const eventObj = this.web3.eth.abi.decodeLog(
						this.input[result.topics[0]],
						result.data,
						result.topics.slice(1)
					  )
					result.data=eventObj;
					this.emitterMethod(result);
					logger.debug(`[BlockchainEvent] Contract : ${this.contractname} event triggered.`); 
					}else{
						logger.error(`[BlockchainEvent] address:${this.address} reg event fail : ${error}`) 
						
					}
				}) // subscribe end
				this.subscriptionobj[i]=subscription;
			}

	}
	
	emitterMethod(obj){
			this.emit(obj.topics[0],obj);
	}
}
