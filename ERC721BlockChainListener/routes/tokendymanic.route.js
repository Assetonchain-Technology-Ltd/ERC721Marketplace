const express = require('express');
const router = express.Router();
const tokendymanicdata_controller = require('../controller/tokendynamicdata.controller');
router.get('/test',tokendymanicdata_controller.test);
router.get('/insert',tokendymanicdata_controller.insert);
router.post('/gettokendymanicdata:symbol?',tokendymanicdata_controller.gettokendymanicdata);
router.get('/getbalances/:symbol',tokendymanicdata_controller.getbalances);


module.exports = router;
