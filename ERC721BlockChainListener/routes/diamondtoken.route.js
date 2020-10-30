const express = require('express');
const router = express.Router();
const diamondtoken_controller = require('../controller/diamondtoken.controller');
router.get('/test',diamondtoken_controller.test);
router.post('/insert',diamondtoken_controller.insert);
router.post('/update',diamondtoken_controller.updatediamondToken);
router.post('/listAllDiamond',diamondtoken_controller.listAllDiamond);


module.exports = router;
