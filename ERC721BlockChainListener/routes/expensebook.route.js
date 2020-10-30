const express = require('express');
const router = express.Router();
const expensebook_controller = require('../controller/expensebook.controller');
router.get('/test',expensebook_controller.test);
router.post('/insert',expensebook_controller.insert);
router.post('/update',expensebook_controller.updateExpensebook);
router.post('/listAllOrder',expensebook_controller.listAllOrder);


module.exports = router;
