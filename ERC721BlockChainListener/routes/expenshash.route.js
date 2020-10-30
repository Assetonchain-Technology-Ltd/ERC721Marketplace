const express = require('express');
const router = express.Router();
const expensehash_controller = require('../controller/expensetxhash.controller');
router.get('/test',expensehash_controller.test);
router.post('/insert',expensehash_controller.insert);
router.post('/update',expensehash_controller.updateExpenseTxHash);


module.exports = router;
