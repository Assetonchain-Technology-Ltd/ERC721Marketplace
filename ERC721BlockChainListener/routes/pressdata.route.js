const express = require('express');
const router = express.Router();
const pressdata_controller = require('../controller/pressdata.controller');
router.get('/test',pressdata_controller.test);
router.post('/insert',pressdata_controller.insert);
router.post('/getPress:days?',pressdata_controller.getPress);


module.exports = router;
