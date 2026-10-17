(function(){'use strict';
const boards=new Set(['news','notice','bid','legislation','general','gazette','press','briefing','facts','activity','media','photo','video','free','praise','civil-board']);
const path=location.pathname,pretty=/^\/([a-z-]+)(?:\/([1-9]\d*))?\/?$/.exec(path),file=path.split('/').pop().replace(/-(?:write|preview)\.html$/,'.html').replace(/\.html$/,'');
const board=pretty&&boards.has(pretty[1])?pretty[1]:boards.has(file)?file:null,original=new URLSearchParams(location.search),editing=/-(?:write|preview)\.html$/.test(path);
let registry={boards:{}},id=document.querySelector('meta[name="post-id"]')?.content||document.body?.dataset.civilPostId||original.get('id');
function postNumber(key,value){const group=registry.boards?.[key],number=group?.posts?.[value];return group?.active?.includes(value)&&Number.isSafeInteger(number)&&number>0?number:null}
function postUrl(key,value){const number=postNumber(key,value);return number?'/'+key+'/'+number+'/':'/'+key+'.html?id='+encodeURIComponent(value)}
function fixLink(a){if(a.tagName!=='A'||!a.getAttribute('href'))return;try{const u=new URL(a.getAttribute('href'),document.baseURI);if(u.origin!==location.origin)return;const name=/^\/([a-z-]+)\.html$/.exec(u.pathname)?.[1],value=u.searchParams.get('id');if(!boards.has(name)||!value)return;const target=postUrl(name,value);if(!target.includes('?id='))a.setAttribute('href',target+u.hash)}catch{}}
function scan(root){if(root.nodeType!==1)return;fixLink(root);root.querySelectorAll('a[href]').forEach(fixLink)}
function base(){if(!document.querySelector('base')){const tag=document.createElement('base');tag.href='/';document.head.prepend(tag)}}
const api={board,postUrl,postNumber,boardUrl:key=>registry.boards?.[key]?'/'+key+'/':'/'+key+'.html',get id(){return id},async params(){await api.ready;const result=new URLSearchParams(original);if(id&&!editing)result.set('id',id);return result}};
api.ready=(async()=>{try{const response=await fetch('/post-routes.json',{cache:'no-store'});if(response.ok)registry=await response.json()}catch{}
if(board&&pretty?.[2]&&!id){const group=registry.boards?.[board];id=group?.active?.find(value=>String(group.posts[value])===pretty[2])||null}
if(board&&id&&!editing){const target=postUrl(board,id);if(!target.includes('?id=')){base();history.replaceState(null,'',target+location.hash);document.querySelector('a.skip')?.setAttribute('href',target+'#main')}}
if(document.body){scan(document.body);const observer=new MutationObserver(changes=>{for(const change of changes){if(change.type==='attributes')fixLink(change.target);else change.addedNodes.forEach(scan)}});observer.observe(document.body,{childList:true,subtree:true,attributes:true,attributeFilter:['href']})}
return api})();
window.PostRoutes=api;
})();