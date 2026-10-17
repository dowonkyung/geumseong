(function(){
 const key=document.body.dataset.boardType;
 const labels={media:'언론기사',activity:'도지사동정',notice:'고시 공고',bid:'입찰 공고',legislation:'입법 예고',general:'일반 공고',gazette:'금성 도보',press:'보도자료',briefing:'기자회견(브리핑)',facts:'사실은 이렇습니다'};
 if(!labels[key])return;
 window.BoardContext={key,label:labels[key],list:key+'.html',write:key+'-write.html',preview:key+'-preview.html',isNotice:['notice','bid','legislation','general'].includes(key),isPublication:['gazette','press','briefing','facts','activity','media'].includes(key),isMedia:key==='media',isActivity:['activity','media'].includes(key),isPress:key==='press',isGazette:key==='gazette',isBriefing:key==='briefing',isFact:key==='facts',hasThumbnail:['press','briefing','activity','media'].includes(key)};
})();
