const express = require('express');
const router = express.Router();
const orderbook_controller = require('../controller/orderbook.controller');
router.get('/test',orderbook_controller.test);
router.post('/insert',orderbook_controller.insert);
router.post('/update',orderbook_controller.updateOrderbook);
router.post('/listAllTrade',orderbook_controller.listAllTrade);


module.exports = router;
