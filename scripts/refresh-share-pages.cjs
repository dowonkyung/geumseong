const fs=require('fs'),path=require('path'),vm=require('vm'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),origin='https://dowonkyung.github.io/geumseong',fallback=origin+'/assets/og-geumseong.png';
const ctx={window:{}};vm.runInNewContext(fs.readFileSync(path.join(root,'board-config.js'),'utf8'),ctx);
const config=ctx.window.GEUMSEONG_BOARD_CONFIG;
const sdk=vm.runInThisContext(fs.readFileSync(path.join(root,'assets/vendor/supabase.js'),'utf8')+';supabase');
const client=sdk.createClient(config.supabaseUrl,config.publishableKey,{auth:{persistSession:false,autoRefreshToken:false}});
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
async function rows(table,columns,published=true){let result=[];for(let offset=0;;offset+=500){let q=client.from(table).select(columns).order('id').range(offset,offset+499);if(published)q=q.eq('status','published');const {data,error}=await q;if(error){if(['42P01','PGRST205'].includes(error.code))return [];throw Error(table+': '+error.message)}result.push(...data);if(data.length<500)return result}}
async function image(bucket,key){if(!key)return fallback;const {data,error}=await client.storage.from(bucket).createSignedUrl(key,300);if(error)throw Error('Thumbnail unavailable: '+error.message);const response=await fetch(data.signedUrl,{redirect:'error'});if(!response.ok)throw Error('Thumbnail HTTP '+response.status);const mime=(response.headers.get('content-type')||'').split(';')[0],ext={'image/png':'png','image/jpeg':'jpg','image/webp':'webp','image/gif':'gif'}[mime];if(!ext)return fallback;const bytes=Buffer.from(await response.arrayBuffer());if(bytes.length>10*1024*1024)throw Error('Thumbnail too large');const file='og/'+crypto.createHash('sha256').update(bytes).digest('hex')+'.'+ext;files.set(file,bytes);return origin+'/share/'+file}
const files=new Map();
async function main(){const manifest={};const groups=await Promise.all([
rows('news_posts','id,title').then(rs=>rs.map(r=>({...r,board_type:'news'}))),
rows('notice_posts','id,title,board_type'),
rows('publication_posts','id,title,board_type,thumbnail_path').then(rs=>rs.map(r=>({...r,bucket:'publication-files'}))),
rows('photo_posts','id,title,thumbnail_path').then(rs=>rs.map(r=>({...r,board_type:'photo',bucket:'photo-files'}))),
rows('community_posts','id,title,board_type',false)
]);
for(const row of groups.flat()){if(!/^[a-z-]+$/.test(row.board_type)||! /^[0-9a-f-]{36}$/i.test(row.id))continue;
const imageUrl=row.thumbnail_path?await image(row.bucket,row.thumbnail_path):fallback;
const route=row.board_type+'/'+row.id,share='/share/'+route+'/',target='/'+row.board_type+'.html?id='+encodeURIComponent(row.id),title=row.title+' | 금성도',description='잘먹고 잘살고 잘먹고사는 인민의 도시, 금성도 금성도입니다.';
manifest[route]=share;
files.set(route+'/index.html','<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><meta name="description" content="'+escape(description)+'"><meta property="og:type" content="article"><meta property="og:title" content="'+escape(title)+'"><meta property="og:description" content="'+escape(description)+'"><meta property="og:image" content="'+escape(imageUrl)+'"><meta property="og:url" content="'+origin+share+'"><meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="'+escape(title)+'"><meta name="twitter:image" content="'+escape(imageUrl)+'"><link rel="canonical" href="'+origin+share+'"><script src="/share-redirect.js" defer></script></head><body><h1>'+escape(row.title)+'</h1><a data-post-link href="'+target+'">게시글 보기</a></body></html>');
}
files.set('manifest.json',JSON.stringify(manifest,null,2)+'\n');
const destination=path.join(root,'share'),stage=path.join(root,'.share-stage');fs.mkdirSync(stage,{recursive:true});
for(const [name,content] of files){const file=path.join(stage,name);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,content)}
fs.rmSync(destination,{recursive:true,force:true});fs.renameSync(stage,destination);console.log('Share previews: '+Object.keys(manifest).length);
}
main().catch(e=>{console.error(e.message);process.exitCode=1});
