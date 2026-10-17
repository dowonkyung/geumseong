const fs=require('fs'),path=require('path');
const primary='#845BA6',secondary='#16BECF';
const colors=new Map([['2a5caa',primary],['f04e4c',secondary],['005bad',primary],['0b50d0',primary],['096ab3',primary],['083891',primary],['234e86',primary],['204b8e','#694884'],['063a74','#56386E'],['052b57','#432E54'],['0b4a80','#56386E'],['ecf2fe','#F3EDF8'],['e7f4fe','#F3EDF8']]);
function walk(dir){for(const item of fs.readdirSync(dir,{withFileTypes:true})){if(['.git','.github','vendor','fonts'].includes(item.name))continue;const file=path.join(dir,item.name);if(item.isDirectory())walk(file);else if(/\.(html|css|js|cjs|json|svg|md)$/.test(file)&&!file.endsWith('apply-geumseong-brand.cjs')&&!file.endsWith('saevit-flag.svg')){let s=fs.readFileSync(file,'utf8').replaceAll('송은석 宋恩奭','신제희').replaceAll('宋恩奭','').replaceAll('송은석','신제희').replaceAll('송 은 석','신 제 희').replaceAll('한도윤','신제희');s=s.replace(/#[0-9a-f]{6}\b/gi,c=>colors.get(c.slice(1).toLowerCase())||c).replaceAll('assets/favicon.svg','assets/geumseong-emblem.svg').replaceAll('assets/geumseong-logo.svg','assets/geumseong-logo-brand.svg');fs.writeFileSync(file,s);}}}
walk('.');
for(const name of ['assets/mayors/office-logo.svg','assets/mayors/office-logo-v2.svg'])fs.copyFileSync('assets/geumseong-logo-brand.svg',name);
fs.appendFileSync('mayor-office.css','\n.office-page header .office-logo{width:auto;height:43px;max-width:100%;object-fit:contain}\n');
fs.appendFileSync('organization.css','\n.organization-page .org-node-citizen,.organization-page .org-node-vice,.organization-page .org a.org-node-vice:is(:hover,:active,:visited,:focus){color:#12343A}\n');
const sync='scripts/sync-navigation.cjs';fs.writeFileSync(sync,fs.readFileSync(sync,'utf8').replace('const assets=[',"const assets=['assets/geumseong-logo-brand.svg','assets/geumseong-emblem.svg',"));
console.log('Geumseong branding applied: Shin Jehee, '+primary+', '+secondary);
