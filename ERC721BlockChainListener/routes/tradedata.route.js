const express = require('express');
const router = express.Router();
const tradedata_controller = require('../controller/tradedata.controller');
router.get('/test',tradedata_controller.test);
router.post('/insert',tradedata_controller.insert);
router.post('/getTrade:days?',tradedata_controller.getTrade);


module.exports = router;
