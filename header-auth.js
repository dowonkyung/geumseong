(function(){
 'use strict';
 let state={user:null,admin:false},client;
 const dialog=document.querySelector('#login-dialog');
 const form=dialog.querySelector('form'),error=dialog.querySelector('#login-error');
 function render(){document.querySelectorAll('.etc-menu .login a,.mobile-login a').forEach(a=>{a.removeAttribute('data-page');a.href='#login';const label=a.querySelector('span');if(label){[...label.childNodes].filter(n=>n.nodeType===3).forEach(n=>n.remove());label.append(state.admin?'로그아웃':'로그인')}else a.textContent=state.admin?'로그아웃':'로그인을 해주세요';a.setAttribute('aria-label',state.admin?'관리자 로그아웃':'로그인')});window.dispatchEvent(new CustomEvent('header-auth-change',{detail:state}))}
 async function refresh(){state={user:null,admin:false};if(client){const {data,error:e}=await client.auth.getUser();if(e&&data?.user)throw e;if(data?.user){const r=await client.from('news_admins').select('user_id').eq('user_id',data.user.id).maybeSingle();if(r.error||!r.data){await client.auth.signOut({scope:'local'});if(r.error)throw Error('관리자 권한을 확인하지 못했습니다. 다시 로그인해 주세요.')}else state={user:data.user,admin:true}}}render();return state}
 const ready=(async()=>{const c=window.GEUMSEONG_BOARD_CONFIG;if(c?.supabaseUrl&&c?.publishableKey){client=window.BoardStore?.client||window.supabase.createClient(c.supabaseUrl,c.publishableKey,{auth:{storageKey:'geumseong-admin',persistSession:true,autoRefreshToken:true,detectSessionInUrl:false}});try{await refresh()}catch(e){error.textContent=e.message;render()}client.auth.onAuthStateChange(()=>setTimeout(()=>refresh().catch(()=>{state={user:null,admin:false};render()}),0))}else render();return state})();
 async function open(){await ready;error.textContent=client?'':'로그인 준비 중입니다. 사이트의 Supabase 연결 설정이 필요합니다.';if(!dialog.open)dialog.showModal();dialog.querySelector('#admin-email').focus()}
 document.addEventListener('click',async e=>{const a=e.target.closest('.etc-menu .login a,.mobile-login a');if(!a)return;e.preventDefault();e.stopImmediatePropagation();await ready;if(state.admin){const r=await client.auth.signOut();if(r.error){await open();error.textContent='로그아웃하지 못했습니다. 다시 시도해 주세요.';return}await refresh()}else await open()},true);
 dialog.querySelector('#cancel-login').onclick=()=>dialog.close();
 dialog.addEventListener('close',()=>{form.reset();error.textContent=''});
 form.onsubmit=async e=>{e.preventDefault();await ready;const button=form.querySelector('[type=submit]');button.disabled=true;error.textContent='';try{if(!client)throw Error('사이트의 Supabase 연결 설정이 필요합니다.');const r=await client.auth.signInWithPassword({email:dialog.querySelector('#admin-email').value.trim(),password:dialog.querySelector('#admin-password').value});dialog.querySelector('#admin-password').value='';if(r.error)throw Error('이메일 또는 비밀번호를 확인해 주세요.');await refresh();if(!state.admin)throw Error('관리자로 등록된 계정만 로그인할 수 있습니다.');dialog.close()}catch(e){if(client&&!state.admin)await client.auth.signOut({scope:'local'});error.textContent=e.message}finally{button.disabled=false}};
 window.HeaderAuth={ready,open,get state(){return state},get client(){return client}};
 if(new URLSearchParams(location.search).get('login')==='1')open();
})();
