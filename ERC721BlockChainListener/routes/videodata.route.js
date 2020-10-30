const express = require('express');
const router = express.Router();
const videodata_controller = require('../controller/videodata.controller');
router.get('/test',videodata_controller.test);
router.post('/insert',videodata_controller.insert);
router.post('/getVideo:days?',videodata_controller.getVideo);


module.exports = router;
