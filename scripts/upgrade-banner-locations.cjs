const fs=require('fs');
let html=fs.readFileSync('mayor.html','utf8');
if(!html.includes('home-banners.js'))html=html.replace('</head>','<script src="home-banners.js" defer></script><link rel="stylesheet" href="home-banners.css"></head>');
fs.writeFileSync('mayor.html',html);
if(!fs.readFileSync('index.html','utf8').includes('home-banners.js'))throw Error('Existing main banner manager missing');
