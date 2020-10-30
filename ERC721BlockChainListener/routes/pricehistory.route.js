const express = require('express');
const router = express.Router();
const pricehistory_controller = require('../controller/pricehistory.controller');
router.get('/test',pricehistory_controller.test);
router.post('/insert',pricehistory_controller.insert);
router.post('/getprice',pricehistory_controller.getPrice);


module.exports = router;
