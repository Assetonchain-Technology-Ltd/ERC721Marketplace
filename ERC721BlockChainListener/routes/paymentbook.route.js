const express = require('express');
const router = express.Router();
const paymentbook_controller = require('../controller/paymentbook.controller');
router.get('/test',paymentbook_controller.test);
router.post('/insert',paymentbook_controller.insert);
router.post('/update',paymentbook_controller.updatePaymentbook);


module.exports = router;
