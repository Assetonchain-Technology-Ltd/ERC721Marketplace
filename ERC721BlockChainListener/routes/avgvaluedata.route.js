const express = require('express');
const router = express.Router();
const avgvaluedata_controller = require('../controller/avgvaluedata.controller');
router.get('/test',avgvaluedata_controller.test);
router.post('/insert',avgvaluedata_controller.insert);
router.post('/getavgvaluedata',avgvaluedata_controller.getavgvaluedata);
router.post('/getavgvaluechange',avgvaluedata_controller.getavgvaluechange);
router.post('/updateavgvalue',avgvaluedata_controller.updateavgvalue);


module.exports = router;
