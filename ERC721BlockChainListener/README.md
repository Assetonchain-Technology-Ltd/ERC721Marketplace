# API

The API project follows MVC structure, each collection in DB will result in Model of Mongoose and each model will have associated insert/get api call.Summary as follow :

|Model|PATH|API|METHOD|
|-----|----|---|------|
|tradedatas|/tradedata|||
|||/insert|POST|
|||/getTrade|POST|
|pressdata|/pressdata||
|||/insert|POST|
|||/getPress|POST|
|videodata|/videodata||
|||/insert|POST|
|||/getVideo|POST|
|milestondata|/milestonedata||
|||/insert|POST|
|||/getMilestone|POST|
|tokens-info-data|/tokensinfo||
|||/insert|POST|
|||/getTokensinfo|POST|
|tokens-dynamic-data|/tokendymanic||
|||/insert|POST|
|||/gettokendymanicdata|POST|
|||/getbalances/SYMBOLCODE|GET|
|avgvaluedata|/avgvaluedata||
|||/insert|POST|
|||/updateavgvalue|POST|
|||/getavgvaluedatachange/|POST param:{symbol,array or address}|
|||/getavgvaluedata/SYMBOLCODE&ADDRESS?|POST|
|price_history|/pricehistory||
|||/insert|POST|
|||/getPrice/symbolcode|POST|

## Details

### /tradedata


 |Name        |< POST > /insert| 
 | ------------ | ------------ |
   |In          | trade record in json format, post in body with batch as key| 
   |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return.</p>If any validation error is occured, error will return and nothing will be save in DB|
   |Description |Insert Trade Data from json format in req body with "batch" as key and list as data , data will be save in A    ll or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error     immediately on the first error encounter|

Sample  of Insert data: 
<pre>
{
    "batch": [
        {
            "tradedatetime": "2020-03-19 13:10:00",
            "tradeprice": "1.3",
            "qty": "2000000",
            "ethtransaction": "https://rinkeby.etherscan.io/tx/0x9383d8c789c34e0108d9c2bef4b36564d6f754c75fd515165c1864d7abc4a9fe",
            "currency": "HKD",
            "insertdatetime": "2020-03-19 16:00:00"
        },	
        {
            "tradedatetime": "2020-03-18 12:10:00",
            "tradeprice": "1.2",
            "ethtransaction": "",
            "qty": "94567.23",
            "currency": "HKD",
            "insertdatetime": "2020-03-18 16:00:00"
        }
    ]
	} </pre>


  |Name        | < POST > /getTrade?days=N</br>Optional: days(integer) |
  | ------------ | ------------ |
  |In          | Null or query with params days  |
  |Out         | <p>(Default) If Null is given as input, it will returns latest 5 trade records</p> <p>If days is given as parameters, it will returns pervious N days trade records including today, thus if any cast error occurs for day, wil continuous with default logic.</p><p>If any error occurs, status 500 will be return with error message</p>
  |Remarks| As mongodb will store date in GMT+0, so it is need to restore the currenct time zone for display| 
   |Description | Get Trade records, it uses tradedatetime field for filtering, by default, it wil return 5 latest trade records and if days param is given, it will get those trade with tradedatetime > today-5 including today. | 

Sample 1: 
http://127.0.0.1:5000/tradedata/getTrade
<pre>
[
    {
        "currecny": "USD",
        "_id": "5e7827ea4c7f7911be4a143a",
        "tradedatetime": "2020-03-20T08:00:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.55"
        },
        "qty": {
            "$numberDecimal": "2"
        },
        "ethtransaction": "https://rinkeby.etherscan.io/tx/0x9383d8c789c34e0108d9c2bef4b36564d6f754c75fd515165c1864d7abc4a9fe",
        "insertdatetime": "2020-03-20T08:00:00.000Z",
        "__v": 0
    },
    {
        "currecny": "USD",
        "_id": "5e7827ea4c7f7911be4a143b",
        "tradedatetime": "2020-03-19T08:10:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.8"
        },
        "ethtransaction": "",
        "qty": {
            "$numberDecimal": "1.8"
        },
        "insertdatetime": "2020-03-19T08:00:00.000Z",
        "__v": 0
    },
    {
        "currecny": "USD",
        "_id": "5e782ae14c7f7911be4a143c",
        "tradedatetime": "2020-03-19T05:10:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.3"
        },
        "qty": {
            "$numberDecimal": "2000000"
        },
        "ethtransaction": "https://rinkeby.etherscan.io/tx/0x9383d8c789c34e0108d9c2bef4b36564d6f754c75fd515165c1864d7abc4a9fe",
        "insertdatetime": "2020-03-19T08:00:00.000Z",
        "__v": 0
    },
    {
        "currecny": "USD",
        "_id": "5e782ae14c7f7911be4a143d",
        "tradedatetime": "2020-03-18T04:10:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.2"
        },
        "ethtransaction": "",
        "qty": {
            "$numberDecimal": "94567.23"
        },
        "insertdatetime": "2020-03-18T08:00:00.000Z",
        "__v": 0
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/tradedata/getTrade?days=4
<pre>
[
    {
        "currecny": "USD",
        "_id": "5e7827ea4c7f7911be4a143a",
        "tradedatetime": "2020-03-20T08:00:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.55"
        },
        "qty": {
            "$numberDecimal": "2"
        },
        "ethtransaction": "https://rinkeby.etherscan.io/tx/0x9383d8c789c34e0108d9c2bef4b36564d6f754c75fd515165c1864d7abc4a9fe",
        "insertdatetime": "2020-03-20T08:00:00.000Z",
        "__v": 0
    },
    {
        "currecny": "USD",
        "_id": "5e7827ea4c7f7911be4a143b",
        "tradedatetime": "2020-03-19T08:10:00.000Z",
        "tradeprice": {
            "$numberDecimal": "1.8"
        },
        "ethtransaction": "",
        "qty": {
            "$numberDecimal": "1.8"
        },
        "insertdatetime": "2020-03-19T08:00:00.000Z",
        "__v": 0
    }
]
</pre>

### /pressdata
|Name        | /insert|
|---|---|
  |In          | press record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert Press Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|                 

Sample  of Insert data: 
<pre>
{
    "batch": [
        {
            "publishdate": "2020-03-13",
            "title" : "Solving Rubik’s Cube with a Robot Hand",
            "url": "https://openai.com/blog/solving-rubiks-cube",
            "source": "openAI",
            "createdatetime": "2020-03-21 02:00:00"
        },
        {
            "publishdate": "2020-03-14",
            "title" : "Token Projects Prefer AirSwap OTC",
            "url": "https://medium.com/fluidity/token-projects-prefer-airswap-otc-cfa0105bf89a",
            "source": "medium",
            "createdatetime": "2020-03-21 02:00:00"
        },
        {
            "publishdate": "2020-03-20",
            "title" : "Liquidity Mining Launch!",
            "url": "https://hummingbot.io/blog/2020-03-liquidity-mining-launch",
            "source": "hummingbot",
            "createdatetime": "2020-03-21 02:00:00"
        }
    ]
}
</pre>

  |Name        | < POST > /getPress?days=N </br> Optional : days(integer)| 
  |--|--|
  |In          | Null or query with params days  | 
  |Out         | <p>(Default)If Null is given as input, it will returns all records in desc order</p><p> If days is given as parameters, it will returns pervious N days press records including today,thus if any casting error occurs, it will continuous with default logic. </p><p>If any error occurs, status 500 will be return with error message<p>| 
  |Remarks  | As mongodb will store date in GMT+0, so it is need to restore the currenct time zone for display| 
  |Description | Get Press records, it uses publishdate field for filtering, by default, it wil return all  press records an    d if days param is given, it will get those press with publishdate > today-5 including today. | 
  
Sample 1: 
http://127.0.0.1:5000/pressdata/getPress
<pre>
[
    {
        "_id": "5e782b1c4c7f7911be4a1440",
        "publishdate": "2020-03-20T00:00:00.000Z",
        "title": "Liquidity Mining Launch!",
        "url": "https://hummingbot.io/blog/2020-03-liquidity-mining-launch",
        "source": "hummingbot",
        "createdatetime": "2020-03-20T18:00:00.000Z",
        "__v": 0
    },
    {
        "_id": "5e782b1c4c7f7911be4a143f",
        "publishdate": "2020-03-14T00:00:00.000Z",
        "title": "Token Projects Prefer AirSwap OTC",
        "url": "https://medium.com/fluidity/token-projects-prefer-airswap-otc-cfa0105bf89a",
        "source": "medium",
        "createdatetime": "2020-03-20T18:00:00.000Z",
        "__v": 0
    },
    {
        "_id": "5e782b1c4c7f7911be4a143e",
        "publishdate": "2020-03-13T00:00:00.000Z",
        "title": "Solving Rubik’s Cube with a Robot Hand",
        "url": "https://openai.com/blog/solving-rubiks-cube",
        "source": "openAI",
        "createdatetime": "2020-03-20T18:00:00.000Z",
        "__v": 0
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/pressdata/getPress?days=5
<pre>
[
    {
        "_id": "5e782b1c4c7f7911be4a1440",
        "publishdate": "2020-03-20T00:00:00.000Z",
        "title": "Liquidity Mining Launch!",
        "url": "https://hummingbot.io/blog/2020-03-liquidity-mining-launch",
        "source": "hummingbot",
        "createdatetime": "2020-03-20T18:00:00.000Z",
        "__v": 0
    }
]
</pre>


### /videodata
|Name        | /insert|
|---|---|
  |In          | video record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert video Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>
{
    "batch": [
        {
            "title": "AlphaGo – The Movie | Full Documentary",
            "url": "https://youtu.be/WXuK6gekU1Y",
            "validFrom": "2020-01-01",
            "validTo": "2020-03-18"
        },
        {
        	"title": "DeepMind StarCraft II Demonstration",
            "url": "https://youtu.be/cUTMhmVh1qs",
            "validFrom": "2020-03-19",
            "validTo": "2020-03-20"
        },
        {
			"title": "What is a Quant?",
            "url": "https://youtu.be/lG_OBZocF3E",
            "validFrom": "2020-03-21",
            "validTo": "2020-05-05"
        }
    ]
}
</pre> 
 
 
  |Name        | < POST > /getVideo?days=N </br> Optional : days(integer)| 
  |--|--|
  |In          | Null or query with params days  | 
  |Out         | <p>(Default)If Null is given as input, it will returns all records in desc order</p><p> If days is given as parameters, it will returns pervious N days video records including today,thus if any casting error occurs, it will continuous with default logic. </p><p>If any error occurs, status 500 will be return with error message<p>| 
  |Remarks  | As mongodb will store date in GMT+0, so it is need to restore the currenct time zone for display| 
  |Description | Get Video records, it uses vaildFromfield for filtering, by default, it wil return all  press records and if days param is given, it will get those press with validFrom > today-5 including today. | 
  
Sample 1: 
http://127.0.0.1:5000/videodata/getvideo
<pre>
[
    {
        "_id": "5e782b4d4c7f7911be4a1446",
        "title": "AlphaGo – The Movie | Full Documentary",
        "url": "https://youtu.be/WXuK6gekU1Y",
        "validFrom": "2020-01-01T00:00:00.000Z",
        "validTo": "2020-03-18T00:00:00.000Z",
        "__v": 0
    },
    {
        "_id": "5e782b4d4c7f7911be4a1447",
        "title": "DeepMind StarCraft II Demonstration",
        "url": "https://youtu.be/cUTMhmVh1qs",
        "validFrom": "2020-03-19T00:00:00.000Z",
        "validTo": "2020-03-20T00:00:00.000Z",
        "__v": 0
    },
    {
        "_id": "5e782b4d4c7f7911be4a1448",
        "title": "What is a Quant?",
        "url": "https://youtu.be/lG_OBZocF3E",
        "validFrom": "2020-03-21T00:00:00.000Z",
        "validTo": "2020-05-05T00:00:00.000Z",
        "__v": 0
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/videodata/getvideo?days=5
<pre>
[
    {
        "_id": "5e782b4d4c7f7911be4a1447",
        "title": "DeepMind StarCraft II Demonstration",
        "url": "https://youtu.be/cUTMhmVh1qs",
        "validFrom": "2020-03-19T00:00:00.000Z",
        "validTo": "2020-03-20T00:00:00.000Z",
        "__v": 0
    },
    {
        "_id": "5e782b4d4c7f7911be4a1448",
        "title": "What is a Quant?",
        "url": "https://youtu.be/lG_OBZocF3E",
        "validFrom": "2020-03-21T00:00:00.000Z",
        "validTo": "2020-05-05T00:00:00.000Z",
        "__v": 0
    }
]
</pre>
### /milestonedata
|Name        | /insert|
|---|---|
  |In          | milestone record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert MileStoneData from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>
{
    "batch": [
        {
            "date": "2019-05-11",
            "desc": "Project start",
            "exturl": "https://blog.coinmarketcap.com/2020/01/06/view-from-the-capital-tokenizing-hashpower",
            "isvideo": "false"
        },
        {
            "date": "2019-06-11",
            "desc": "Stage 1",
            "exturl": "https://blog.coinmarketcap.com/2020/03/18/defi-on-bitcoin-the-time-has-come-for-decentralized-finance-to-run-on-top-of-bitcoins-network",
            "isvideo": "false"
        },
        {
            "date": "2019-09-14",
            "desc": "Stage 2",
            "exturl": "https://medium.com/fluidity/ethereum-infrastructure-grows-up-91ab3ca37109",
            "isvideo": "false"
        },
        {
            "date": "2020-01-04",
            "desc": "Stage 3",
            "exturl": "https://youtu.be/EaiAVy2Kb2g",
            "isvideo": "true"
        },
        { 
            "date": "2020-03-17",
            "desc": "Stage 4",
            "exturl": "https://blog.coinmarketcap.com/2020/03/04/coinmarketcap-now-lists-crypto-derivative-markets/",
            "isvideo": "false"
        }
    ]
}
</pre> 

  |Name        | < POST > /getMilestone?days=N </br> Optional : days(integer)| 
  |--|--|
  |In          | Null or query with params days  | 
  |Out         | <p>(Default)If Null is given as input, it will returns all records in desc order</p><p> If days is given as parameters, it will returns pervious N days milestone records including today,thus if any casting error occurs, it will continuous with default logic. </p><p>If any error occurs, status 500 will be return with error message<p>| 
  |Remarks  | As mongodb will store date in GMT+0, so it is need to restore the currenct time zone for display| 
  |Description | Get MileStone records, it uses date field for filtering, by default, it wil return all  press records and if days param is given, it will get those press with date > today-5 including today. | 
  
Sample 1: 
http://127.0.0.1:5000/milestonedata/getmilestone
<pre>
[
    {
        "isvideo": false,
        "_id": "5e782b3f4c7f7911be4a1445",
        "date": "2020-03-17T00:00:00.000Z",
        "desc": "Stage 4",
        "exturl": "https://blog.coinmarketcap.com/2020/03/04/coinmarketcap-now-lists-crypto-derivative-markets/",
        "__v": 0
    },
    {
        "isvideo": true,
        "_id": "5e782b3f4c7f7911be4a1444",
        "date": "2020-01-04T00:00:00.000Z",
        "desc": "Stage 3",
        "exturl": "https://youtu.be/EaiAVy2Kb2g",
        "__v": 0
    },
    {
        "isvideo": false,
        "_id": "5e782b3f4c7f7911be4a1443",
        "date": "2019-09-14T00:00:00.000Z",
        "desc": "Stage 2",
        "exturl": "https://medium.com/fluidity/ethereum-infrastructure-grows-up-91ab3ca37109",
        "__v": 0
    },
    {
        "isvideo": false,
        "_id": "5e782b3f4c7f7911be4a1442",
        "date": "2019-06-11T00:00:00.000Z",
        "desc": "Stage 1",
        "exturl": "https://blog.coinmarketcap.com/2020/03/18/defi-on-bitcoin-the-time-has-come-for-decentralized-finance-to-run-on-top-of-bitcoins-network",
        "__v": 0
    },
    {
        "isvideo": false,
        "_id": "5e782b3f4c7f7911be4a1441",
        "date": "2019-05-11T00:00:00.000Z",
        "desc": "Project start",
        "exturl": "https://blog.coinmarketcap.com/2020/01/06/view-from-the-capital-tokenizing-hashpower",
        "__v": 0
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/milestonedata/getmilestone?days=10
[
    {
        "isvideo": false,
        "_id": "5e782b3f4c7f7911be4a1445",
        "date": "2020-03-17T00:00:00.000Z",
        "desc": "Stage 4",
        "exturl": "https://blog.coinmarketcap.com/2020/03/04/coinmarketcap-now-lists-crypto-derivative-markets/",
        "__v": 0
    }
]
</pre>

### /tokensinfo
|Name        | /insert|
|---|---|
  |In          | token record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert Tokens-info-Data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>

</pre> 

  |Name        | < POST > /getTokensinfo?symbol=String </br> Optional : symbol(String)| 
  |--|--|
  |In          | Null or query with params symbol  | 
  |Out         | <p>(Default)If Null is given as input, it will returns all records in desc order</p><p> If symbols is given as parameters, it will returns the specific record if it exist in the DB,thus if any casting error occurs, it will continuous with default logic. </p><p>If any error occurs, status 500 will be return with error message<p>| 

  |Description | Get Tokens-inf-data records, it uses symbol field for filtering, by default, it wil return all  tokensinfodata records and if symbol param is given, it will return the specific record if find. | 
  
Sample 1: 
http://127.0.0.1:5000/tokensinfo/getTokensinfo
<pre>
[
    {
        "MEMBERS": [],
        "_id": "5e5d3cd6d6a8435f70d1b25b",
        "SYMBOL": "CCT",
        "ADDRESS": "0x3c23dBF412D58F5Af2323bAE71283AD0932223F6",
        "START_BLOCK": "9000000",
        "DECIMAL": 0,
        "TOTAL_SUPPLY": 9282000,
        "TIMEZONE": "America/New_York",
        "MARKTIME": "07:00:00",
        "HISTORY_COUNT": 3
    },
    {
        "MEMBERS": [],
        "_id": "5e5d3cd6d6a8435f70d1b25c",
        "SYMBOL": "SF4E",
        "ADDRESS": "0xAec7d1069e3a914a3EB50f0BFB1796751f2ce48a",
        "START_BLOCK": "5500000",
        "DECIMAL": 18,
        "TOTAL_SUPPLY": 1000000000,
        "TIMEZONE": "America/New_York",
        "MARKTIME": "09:00:00",
        "HISTORY_COUNT": 3
    },
    {
        "MEMBERS": [
            "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83",
            "0x46705dfff24256421A05D056c29E81Bdc09723B8",
            "0xaB5C66752a9e8167967685F1450532fB96d5d24f"
        ],
        "_id": "5e5d3cd6d6a8435f70d1b25d",
        "SYMBOL": "FTT",
        "ADDRESS": "0x50d1c9771902476076ecfc8b2a83ad6b9355a4c9",
        "START_BLOCK": "7000000",
        "DECIMAL": 18,
        "TOTAL_SUPPLY": 347370548,
        "TIMEZONE": "America/New_York",
        "MARKTIME": "00:00:00",
        "HISTORY_COUNT": 3
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/tokensinfo/getTokensinfo?symbol=FTT
<pre>
[
    {
        "MEMBERS": [
            "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83",
            "0x46705dfff24256421A05D056c29E81Bdc09723B8",
            "0xaB5C66752a9e8167967685F1450532fB96d5d24f"
        ],
        "_id": "5e5d3cd6d6a8435f70d1b25d",
        "SYMBOL": "FTT",
        "ADDRESS": "0x50d1c9771902476076ecfc8b2a83ad6b9355a4c9",
        "START_BLOCK": "7000000",
        "DECIMAL": 18,
        "TOTAL_SUPPLY": 347370548,
        "TIMEZONE": "America/New_York",
        "MARKTIME": "00:00:00",
        "HISTORY_COUNT": 3
    }
]


</pre>


### /tokendymanic
|Name        | /insert|
|---|---|
  |In          | token dymainc record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert Tokens-dymanic-data from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>

</pre> 

  |Name        | < POST > /gettokendymanicdata?symbol=String </br> Optional : symbol(String)| 
  |--|--|
  |In          | Null or query with params symbol  | 
  |Out         | <p>(Default)If Null is given as input, it will returns all records in desc order</p><p> If symbols is given as parameters, it will returns the specific record if it exist in the DB,thus if any casting error occurs, it will continuous with default logic. </p><p>If any error occurs, status 500 will be return with error message<p>| 

  |Description | Get Tokens-dymanic-data records, it uses symbol field for filtering, by default, it wil return all  tokensinfodata records and if symbol param is given, it will return the specific record if find. | 
  
Sample 1: 
http://127.0.0.1:5000/tokendymanic/gettokendymanicdata
<pre>
[
    {
        "PRICE_HISTORY": [
            {
                "$numberDecimal": "0.0321"
            },
            {
                "$numberDecimal": "0.0332"
            },
            {
                "$numberDecimal": "0.0298"
            }
        ],
        "BALANCE_HISTORY": [
            {
                "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83": [
                    3000000,
                    3000001.2,
                    3000002.4
                ],
                "0x46705dfff24256421A05D056c29E81Bdc09723B8": [
                    2433434.22,
                    2423442.44,
                    2453212.3
                ],
                "0xaB5C66752a9e8167967685F1450532fB96d5d24f": [
                    321213,
                    321213,
                    321213
                ]
            }
        ],
        "_id": "5e74baac1c9d4400001ca3d7",
        "SYMBOL": "FTT"
    }
]
</pre>

Sampe 2 :
http://127.0.0.1:5000/tokendymanic/gettokendymanicdata?symbol=FTT
<pre>
[
    {
        "PRICE_HISTORY": [
            {
                "$numberDecimal": "0.0321"
            },
            {
                "$numberDecimal": "0.0332"
            },
            {
                "$numberDecimal": "0.0298"
            }
        ],
        "BALANCE_HISTORY": [
            {
                "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83": [
                    3000000,
                    3000001.2,
                    3000002.4
                ],
                "0x46705dfff24256421A05D056c29E81Bdc09723B8": [
                    2433434.22,
                    2423442.44,
                    2453212.3
                ],
                "0xaB5C66752a9e8167967685F1450532fB96d5d24f": [
                    321213,
                    321213,
                    321213
                ]
            }
        ],
        "_id": "5e74baac1c9d4400001ca3d7",
        "SYMBOL": "FTT"
    }
]
</pre>


  |Name        | < GET > /getbalance/{symbol code} </br> Mandatory : symbol code| 
  |--|--|
  |In          | Symbol Code in URL path  | 
  |Out         | <p>It will returns "data","supply" and "member" for the specific symbol record if it exist in the DB </p><p>If any error occurs, status 500 will be return with error message<p>| 

  |Description | Please advise | 
  
Sample 1: 
http://127.0.0.1:5000/tokendymanic/getbalances/FTT

<pre>

{
    "data": {
        "0x5f86Fe0e62D1f0226F535eBe5d98A5d3edC9A615": "7660.6517",
        "0xE93381fB4c4F14bDa253907b18faD305D799241a": "7555.219800000001",
        "0x0681d8Db095565FE8A346fA0277bFfdE9C0eDBBF": "-7555.219800000001",
        "0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE": "-7660.6517"
    },
    "supply": 347370548,
    "members": {
        "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83": "0",
        "0x46705dfff24256421A05D056c29E81Bdc09723B8": "0",
        "0xaB5C66752a9e8167967685F1450532fB96d5d24f": "0"
    }
}
</pre>


### /avgvaluedata
|Name        |<POST> /insert|
|---|---|
  |In          | avgvaluedata record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert avgvaluedata from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>
{
    "batch": [
     
        {
            "HOLDERADDRESS": "0xaB5C66752a9e8167967685F1450532fB96d5d24f",
            "SYMBOL": "FTT",
            "MANUAL": false,
            "PRICE":"4",
            "QTY":"10",
            "CURRENTAVGVALUE":"1.2"
        }
        
    ]
}
</pre> 

  |Name        | < POST > /updateavgvalue?symbol=symbolcode</br>| 
  |--|--|
  |In          | query with params symbol  | 
  |Out         | <p>Success : it will return response 200 and status=success to sender with records on update and insert</p><p>Fail    : If holding is empty list or symbol is not provided or empty string, it will return status 500</p>If any error occurs during update or insert, or the avgdata list is not empty at the end, it will still return status 200 to send but will status=fail in the return message with record of errorlist</p>|
  |Description | <p>This function is used to update the record in avgvaluedata according to the formula in requirement 1.4</p><p>Please kindly noted that the whole block of for loop on holding list until the return statement is in async function and await is declared on update and insert to ensure the data is update/insert in sequence.</p><br>First, it will get the <p>1. latest price of symbol(lastprice)</p><p>2. avgvalue record for that symbol(avgdata)</p><p>3. current holding from getbalance(holding)</p><br>If all data return successfully, it will loop though holding to consume the record in avgdata<p>1. if find in avgdata </p><p>a. update record with lastprice and calcuate the update currentavgvalue</p><p>2. if not find in avgdata</p><p>a. it is a new holder, thise record will insert to avgdata</p><br>If any error occurs during the loop, it will mark it down and continuous on others| 
  
Sample 1: 
http://127.0.0.1:5000/avgvaluedata/updateavgvalue?symbol=FTT
<pre>

</pre>

Sampe 2 :
http://127.0.0.1:5000/tokendymanic/gettokendymanicdata?symbol=FTT

</pre>


  |Name        | < POST > /getavgvaluechange/</br> | 
  |--|--|
  |In          | param in body with json : { "symbol":"code","address":[array of address]} | 
  |Out         | Success : JSON record will be return for those specific symbol and  address with change% and share% order by update time desc</br>Fail    : <p>If Symbol or address is not persent or either one is empty, error 500 will return</p><p>If query retrun error , status 500 will retrun</p>| 
  |Description | This function is used to calculate the change percentage  in valuation in comparison with latest price snapshot and the share% of current holding in individual avgvaluedata record. | 
  
Sample 1: http://127.0.0.1:5000/avgvaluedata/getavgvaluechange</br> 
In :
<pre>
{
	"symbol":"FTT",
	"address":["0x97137466Bc8018531795217f0EcC4Ba24Dcba5c1","0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83"]
}
</pre>
Out: 
<pre>
[
    {
        "address": "0x97137466Bc8018531795217f0EcC4Ba24Dcba5c1",
        "changepercent": 40,
        "qty": {
            "$numberDecimal": "48066857.73432889"
        }
    },
    {
        "address": "0xd769010D3813bAFAf4aDdbfe258EAFD07828bB83",
        "changepercent": 40,
        "qty": {
            "$numberDecimal": "197787706.0839923"
        }
    }
]
</pre>


  |Name        | < POST > /getavgvaluedata/?symbol=xx&address=xxxxx</br> optional address| 
  |--|--|
  |In          | symbol or (symbol,address) | 
  |Out         | Success : <p>1. if only symbol is given, all record regarding to that symbol will be return order by update time desc</p><p>2. if symbol and address is given, record for that specific address and symbol will be return order by update time desc</p> The record will be format with key value pair while key is the address and value is the record</br>Fail    : <p>if symbol is not present or either symbol or address is empty, error 500 will be return</p><p>if query fail, error 500 will return </p>| 
|Description | This function is used to get avgvaluedata records| 
  
Sample 1: http://127.0.0.1:5000/avgvaluedata/getavgvaluedata?symbol=FTT

Out: 
<pre>
{
    "0x1D3d03C37c65D92E146a90a544403960D0FB4549": {
        "MANUAL": false,
        "_id": "5e886622ef3405360ccab04b",
        "HOLDERADDRESS": "0x1D3d03C37c65D92E146a90a544403960D0FB4549",
        "SYMBOL": "FTT",
        "PRICE": {
            "$numberDecimal": "14"
        },
        "QTY": {
            "$numberDecimal": "169.44000000000003"
        },
        "CURRENTAVGVALUE": {
            "$numberDecimal": "10"
        },
        "__v": 0,
        "createdAt": "2020-04-04T10:49:06.479Z",
        "updatedAt": "2020-04-04T12:22:01.222Z"
    },
    "0x5Ad6374d0170Ddd0B2fDf27eC83585273b2CE9A9": {
        "MANUAL": false,
        "_id": "5e884f1bccb0e32998737b57",
        "HOLDERADDRESS": "0x5Ad6374d0170Ddd0B2fDf27eC83585273b2CE9A9",
        "SYMBOL": "FTT",
        "PRICE": {
            "$numberDecimal": "14"
        },
        "QTY": {
            "$numberDecimal": "1E-18"
        },
        "CURRENTAVGVALUE": {
            "$numberDecimal": "10"
        },
        "__v": 0,
        "createdAt": "2020-04-04T09:10:52.067Z",
        "updatedAt": "2020-04-04T12:22:22.120Z"
    },........
</pre>


### /pricehistory
|Name        |<POST> /insert|
|---|---|
  |In          | price_history record in json format, post in body with batch as key| 
  |Out         | <p>If all records are valid according to model specification, records will be save in DB and original records will be return </p><p> If any validation error is occured, error will return and nothing will be save in DB<p>| 
  |Description |Insert avgvaluedata from json format in req body with "batch" as key and list as data , data will be save in All or nothing fashion.Those records will be validate according to Model definition before save in db.It will return error immediately on the first error encounter|

Sample  of Insert data: 
<pre>
[
    {
        "MANUAL": true,
        "_id": "5e887bcd932c08403c4dfa8a",
        "SYMBOL": "FTT",
        "PRICE": {
            "$numberDecimal": "14"
        },
        "CURRENCY": "HKD",
        "__v": 0,
        "createdAt": "2020-04-04T12:21:33.396Z",
        "updatedAt": "2020-04-04T12:21:33.396Z"
    }
]
</pre> 

  |Name        | < POST > /getPrice?symbol=xxxx&currency=xxx</br>| 
  |--|--|
  |In          | symbol and currency  | 
  |Out         | <p>Success : The latest update price record for that symbol and currency will be return</p><p>Fail    : if either symbol or curreny is missing or empty , error 500 will be return</p>| 
  
Sample 1: 
http://127.0.0.1:5000/pricehistory/getprice?symbol=FTT&currency=HKD
<pre>
{
    "batch": [
         {
        	"SYMBOL": "FTT",
            "MANUAL": true,
            "PRICE": "14",
            "CURRENCY":"HKD"
        }
        
    ]
}
</pre>



# Model

## tradedatas
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| tradedatetime  | Date   | yes   |
| tradeprice  | Decimal128  | yes   |
| qty  | Decimal128  | yes  |
| ethtransaction  | String  | no  |
| currency  | String  | no ,default : USD  |
| insertdatetime  | Date  | no, default : Date.now  |

## pressdatas
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| publishdate  | Date   | yes   |
| title | String  | yes   |
| url  | String  | no  |
| source  | String  | no  |
| createdatetime  | Date  | no, default : Date.now  |

## videodatas
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| title  | String  | yes   |
| url | String  | no   |
| validFrom  | Date  | no  |
| validTo  | Date  | no  |

## milestondatas
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| date | Date  | yes   |
| desc | Date  | yes   |
| exturl  | String | no  |
| isVideo | boolean  | no, default : False |


## tokens-info-data
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| SYMBOL | String  | yes , unique=yes  |
| ADDRESS | String  | yes   |
| START_BLOCK | String | no  |
| DECIMAL | Number  | yes |
| TOTAL_SUPPLY | Number  | no |
| MARKTIME | String  | no |
| HISTORY_COUNT | Number  | no |
| MEMBERS | Array of String  | no |
| priceupdateinterval| String | yes ,default:snap  |
| pricefeedmode | String | yes, default:RESTFUL |
| pricehost | String  | yes |
| priceAPIname | String  | yes |
| basecurrency | String  | yes , default:HKD |

## tokens-dynamic-data
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| SYMBOL | String  | yes , unique=yes  |
| PRICE_HISTORY| Array of Decimal128  | no |
| BALANCE_HISTORY | Array of Object | no  |

## avgvaluedata
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| HOLDERADDRESS | String  | yes , composite key |
| SYMBOL| String | yes , composite key  |
| MANUAL | boolean | no, default false  |
| Price | Decimal128 | no  |
| Qty | Decimal128 | no  |
| CURRENTAVGVALUE | Decimal128 | no  |


## price_history
| FieldName |DataType   |Required |
| ------------ | ------------ | ------------ |
| SYMBOL | String  | yes   |
| MANUAL| boolean | no , default : false |
| PRICE | Decimal128 | no  |
| Currency | String | no  |
