const express = require('express');
const router = express.Router();
const paymenthash_controller = require('../controller/paymenttxhash.controller');
router.get('/test',paymenthash_controller.test);
router.post('/insert',paymenthash_controller.insert);
router.post('/update',paymenthash_controller.updatePaymentTxhash);


module.exports = router;
