const express = require('express');
const router = express.Router();
const milestonedata_controller = require('../controller/milestonedata.controller');
router.get('/test',milestonedata_controller.test);
router.post('/insert',milestonedata_controller.insert);
router.post('/getMilestone:days?',milestonedata_controller.getMilestone);


module.exports = router;
