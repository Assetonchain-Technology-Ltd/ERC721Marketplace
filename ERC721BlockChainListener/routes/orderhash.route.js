const express = require('express');
const router = express.Router();
const orderhash_controller = require('../controller/ordertxhash.controller');
router.get('/test',orderhash_controller.test);
router.post('/insert',orderhash_controller.insert);
router.post('/update',orderhash_controller.updateOrderTxHash);


module.exports = router;
