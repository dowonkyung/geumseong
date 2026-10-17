(function(){
 const colors=window.GEUMSEONG_SYMBOLS?.mark?.colors||[];
 const values=[['--org-primary',colors[0]?.hex||'#845BA6'],['--org-accent',colors[1]?.hex||'#16BECF']];
 for(const [name,value] of values)if(/^#[0-9a-f]{6}$/i.test(value))document.documentElement.style.setProperty(name,value);
})();
