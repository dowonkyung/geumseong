const fs=require('fs');
let html=fs.readFileSync('index.html','utf8');
if(!html.includes('home-banners.js'))html=html.replace('</head>','<script src="home-banners.js" defer></script></head>');
if(!html.includes('home-banners.css'))html=html.replace('</head>','<link rel="stylesheet" href="home-banners.css"></head>');
fs.writeFileSync('index.html',html);
const sync='scripts/sync-navigation.cjs';let script=fs.readFileSync(sync,'utf8');if(!script.includes("'home-banners.js'"))script=script.replace('const assets=[',"const assets=['home-banners.js','home-banners.css',");fs.writeFileSync(sync,script);
if(process.env.GITHUB_REPOSITORY.endsWith('/geumseong')){
fs.appendFileSync('header-mayor.css','\nheader .header-search .header-search-btn{background-color:#845BA6}header .header-search .header-search-btn:hover{background-color:#694884}\n');
for(const file of fs.readdirSync('.').filter(n=>n.endsWith('.html')||n.endsWith('.js'))){let text=fs.readFileSync(file,'utf8').replaceAll('assets/mayors/office-logo-v2.svg','assets/mayors/shin-jehee-office.svg').replaceAll('assets/mayors/office-logo.svg','assets/mayors/shin-jehee-office.svg');fs.writeFileSync(file,text);}
}
if(!fs.readFileSync('index.html','utf8').includes('src="home-banners.js"'))throw Error('Banner manager script was not injected');
