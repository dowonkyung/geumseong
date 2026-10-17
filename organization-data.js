(function(){'use strict';
const aliases={'구청장':'도지사','부구청장':'부도지사'};
function department(value){const name=String(value||'').trim();return aliases[name]||name}
function queryNames(names){return [...new Set([...names,...Object.keys(aliases).filter(name=>names.includes(aliases[name]))])]}
function documents(rows){const map=new Map();for(const row of rows||[]){const key=department(row.department),canonical=key===row.department;if(map.has(key)&&!canonical)continue;map.set(key,{...row,department:key,version:canonical?row.version:0,sections:(row.sections||[]).map(section=>({...section,title:department(section.title),rows:(section.rows||[]).map(member=>({...member,position:department(member.position)}))}))})}return [...map.values()]}
window.GeumseongOrganizationData={department,queryNames,documents};
})();