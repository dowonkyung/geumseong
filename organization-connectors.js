(function(){
'use strict';
const chart=document.querySelector('.org-province');
if(!chart)return;
const wrap=chart.closest('.org-wrap'),ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg'),path=document.createElementNS(ns,'path');
svg.classList.add('org-connectors');svg.setAttribute('aria-hidden','true');svg.append(path);wrap.prepend(svg);
let pending=false;
function draw(){
 pending=false;
 const origin=wrap.getBoundingClientRect(),dpr=window.devicePixelRatio||1;
 const snap=v=>(Math.round(v*dpr-dpr/2)+dpr/2)/dpr;
 const box=e=>{const r=e.getBoundingClientRect();return{x:snap(r.left-origin.left+r.width/2),top:snap(r.top-origin.top),bottom:snap(r.bottom-origin.top)}};
 const segments=[],line=(x1,y1,x2,y2)=>segments.push('M'+x1+' '+y1+'L'+x2+' '+y2);
 const governor=box(chart.querySelector('.org-node-mayor')),citizen=box(chart.querySelector('.org-node-citizen'));
 line(citizen.x,citizen.bottom,governor.x,governor.top);
 const advisers=[...chart.querySelectorAll('.org-advisors .org-side')];
 const direct=chart.querySelector('.org-governor-departments');
 function connectGrid(grid,parent){
  const titles=[...grid.children].map(li=>li.querySelector('.dept-title')).filter(Boolean),rows=[];
  for(const title of titles){const b=box(title);let row=rows.find(r=>Math.abs(r.top-b.top)<2);if(!row){row={top:b.top,boxes:[]};rows.push(row)}row.boxes.push(b)}
  rows.sort((a,b)=>a.top-b.top);
  let previous=parent.bottom;
  for(const row of rows){
   const y=snap(row.top-24),xs=[parent.x,...row.boxes.map(b=>b.x)];
   line(parent.x,previous,parent.x,y);line(Math.min(...xs),y,Math.max(...xs),y);
   for(const b of row.boxes)line(b.x,y,b.x,b.top);
   previous=y;
  }
  for(const title of titles){const body=title.nextElementSibling;if(body?.classList.contains('dept-list')){const a=box(title),b=box(body);line(a.x,a.bottom,a.x,b.top)}}
 }
 if(direct)connectGrid(direct,governor);
 for(const adviser of advisers){const b=box(adviser),r=adviser.getBoundingClientRect(),y=snap(r.top-origin.top+r.height/2);line(governor.x,y,b.x,y)}
 for(const heading of chart.querySelectorAll('.org-branch-heading')){
  const grid=heading.nextElementSibling?.querySelector('.org-level-departments');
  if(grid)connectGrid(grid,box(heading.querySelector('.org-node')));
 }
 svg.setAttribute('width',origin.width);svg.setAttribute('height',wrap.scrollHeight);
 svg.setAttribute('viewBox','0 0 '+origin.width+' '+wrap.scrollHeight);
 path.setAttribute('d',segments.join(''));path.setAttribute('fill','none');path.setAttribute('stroke','#B1B8BE');path.setAttribute('stroke-width','1');path.setAttribute('stroke-linecap','square');path.setAttribute('stroke-linejoin','miter');
 chart.classList.add('org-connectors-ready');
}
function schedule(){if(!pending){pending=true;requestAnimationFrame(draw)}}
new ResizeObserver(schedule).observe(chart);
window.addEventListener('resize',schedule);
document.fonts?.ready.then(schedule);
schedule();
})();
