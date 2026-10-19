(function(){'use strict';
const aliases={'구청장':'도지사','부구청장':'부도지사'};
function department(value){const name=String(value||'').trim();return aliases[name]||name}
function queryNames(names){return [...new Set([...names,...Object.keys(aliases).filter(name=>names.includes(aliases[name]))])]}
function documents(rows){const map=new Map();for(const row of rows||[]){const key=department(row.department),canonical=key===row.department;if(map.has(key)&&!canonical)continue;map.set(key,{...row,department:key,version:canonical?row.version:0,sections:(row.sections||[]).map(section=>({...section,title:department(section.title),rows:(section.rows||[]).map(member=>({...member,position:department(member.position)}))}))})}return [...map.values()]}

const portraitBucket='geumseong-org-portraits',portraitPattern=/^[0-9a-f-]{36}\.(png|jpg|webp)$/;
function photoURL(path){return portraitPattern.test(String(path||''))?window.GEUMSEONG_BOARD_CONFIG.supabaseUrl+'/storage/v1/object/public/'+portraitBucket+'/'+path:''}
function personCell(row){const cell=document.createElement('td');cell.className='directory-person';const src=photoURL(row.photo_path);if(src){const img=document.createElement('img');img.src=src;img.alt=row.name?row.name+' 사진':'직원 사진';img.width=80;img.height=100;img.loading='lazy';cell.append(img)}const name=document.createElement('span');name.textContent=row.name||'—';cell.append(name);return cell}
window.GeumseongOrganizationData={department,queryNames,documents,photoURL,personCell};
})();