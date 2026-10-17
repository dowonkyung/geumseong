const fs=require('fs'),path=require('path');
const sqlDir='supabase',sqlFiles=fs.readdirSync(sqlDir).filter(n=>n.endsWith('.sql'));
const names=new Set();
for(const name of sqlFiles){const text=fs.readFileSync(path.join(sqlDir,name),'utf8');for(const pattern of [/create table if not exists public\.([a-z_]+)/gi,/create or replace function public\.([a-z_]+)/gi,/create index if not exists ([a-z_]+)/gi,/create policy ([a-z_]+)/gi])for(const m of text.matchAll(pattern))if(!['news_admins','is_news_admin'].includes(m[1]))names.add(m[1]);}
const buckets=['geumseong-news-files','geumseong-notice-files','geumseong-publication-files','geumseong-photo-files','geumseong-community-files'];
function walk(dir){for(const item of fs.readdirSync(dir,{withFileTypes:true})){if(['.git','.github'].includes(item.name))continue;const file=path.join(dir,item.name);if(item.isDirectory())walk(file);else if(/\.(js|cjs|sql|md|html|json)$/.test(file)){let text=fs.readFileSync(file,'utf8');if(file===path.join('supabase','schema.sql'))text=text.slice(text.indexOf('create table if not exists public.geumseong_news_posts'));
for(const name of [...names].sort((a,b)=>b.length-a.length))text=text.replace(new RegExp('\\b'+name+'\\b','g'),'geumseong_'+name);
for(const bucket of buckets)text=text.split("'"+bucket+"'").join("'geumseong-"+bucket+"'").split('"'+bucket+'"').join('"geumseong-'+bucket+'"');
text=text.replaceAll('금성도지사','금성도지사').replaceAll('금성도청 홈','금성도청 홈').replaceAll('href="index.html"','href="index.html"');
fs.writeFileSync(file,text);}}}
walk('.');
fs.writeFileSync('board-config.js',"// 로그인·관리자 계정은 안강진구와 공유하고 게시글·파일은 geumseong_ 전용으로 분리합니다.\nwindow.GEUMSEONG_BOARD_CONFIG={supabaseUrl:'https://qikhxlwthbtrwbrhryex.supabase.co',publishableKey:'sb_publishable_itD8ySTzc0w6VIrC3XDCHQ_l5E27u0H',bucket:'geumseong-news-files'};\n");
const order=['schema.sql','notices.sql','publications.sql','photos.sql','videos.sql','organization.sql','community.sql','civil-board.sql','activity.sql','media-articles.sql'];
fs.writeFileSync('supabase/geumseong-setup.sql',order.map(name=>'-- '+name+'\n'+fs.readFileSync(path.join(sqlDir,name),'utf8')).join('\n\n'));
const setup=fs.readFileSync('GEUMSEONG_SETUP.md','utf8');fs.writeFileSync('GEUMSEONG_SETUP.md',setup.replace('별도 Supabase 프로젝트에서 supabase 폴더 SQL을 설치하고 board-config.js에 공개 URL·키를 입력하세요. 기존 안강진구 저장소와 관리자·게시글은 연결하지 않았습니다.','기존 안강진구 Supabase 프로젝트의 SQL Editor에서 supabase/geumseong-setup.sql 전체를 실행하세요. 로그인 계정과 public.news_admins 관리자 명단은 공유하고, 게시글·파일·조직도는 geumseong_ 전용으로 분리합니다. 도메인이 다르면 같은 계정으로 각 사이트에서 로그인합니다.'));
const postShare=fs.readFileSync('post-share.js','utf8').replace("new URL(manifest[board+'/'+id],location.origin)","new URL(manifest[board+'/'+id].replace(/^\\//,''),new URL('./',location.href))");fs.writeFileSync('post-share.js',postShare);
const generatorFile='scripts/refresh-share-pages.cjs';let generator=fs.readFileSync(generatorFile,'utf8').replace('src="/share-redirect.js"','src="'+new URL('https://dowonkyung.github.io/geumseong/').pathname+'share-redirect.js"').replace("target='/'+row.board_type","target='/geumseong/'+row.board_type");fs.writeFileSync(generatorFile,generator);
const logo='<svg xmlns="http://www.w3.org/2000/svg" width="220" height="70" viewBox="0 0 220 70"><text x="0" y="36" fill="#2A5CAA" font-family="Arial,sans-serif" font-size="34" font-weight="700">geumseong</text><text x="1" y="62" fill="#333" font-family="sans-serif" font-size="22" font-weight="700">금성도</text></svg>';
fs.writeFileSync('assets/geumseong-logo.svg',logo);
for(const name of ['office-logo.svg','office-logo-v2.svg'])fs.writeFileSync('assets/mayors/'+name,'<svg xmlns="http://www.w3.org/2000/svg" width="418" height="60" viewBox="0 0 418 60"><text x="0" y="41" fill="#2A5CAA" font-family="sans-serif" font-size="31" font-weight="700">금성도 열린도지사실</text></svg>');
fs.writeFileSync('assets/og-geumseong.svg','<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630"><rect width="1200" height="630" fill="white"/><text x="600" y="300" text-anchor="middle" fill="#2A5CAA" font-family="sans-serif" font-size="100" font-weight="700">금성도</text><text x="600" y="390" text-anchor="middle" fill="#333" font-family="sans-serif" font-size="40">새빛민주공화국 금성도청</text></svg>');
const out=fs.readFileSync('supabase/geumseong-setup.sql','utf8');if(/(?:create|alter|drop) table(?: if not exists)? public\.(?:geumseong_news_posts|geumseong_community_posts)\b/.test(out))throw Error('Unprefixed source data mutation');
if(!fs.readFileSync('header-auth.js','utf8').includes("from('news_admins')"))throw Error('Shared administrator lookup lost');
console.log('Shared authentication configured; isolated resource identifiers: '+names.size);
