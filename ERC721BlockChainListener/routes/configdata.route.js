const express = require('express');
const router = express.Router();
const configdata_controller = require('../controller/configdata.controller');
router.get('/test',configdata_controller.test);
router.post('/getConfigdata:contractname?',configdata_controller.getConfigdata);
router.post('/update',configdata_controller.updateConfigdata);


module.exports = router;
