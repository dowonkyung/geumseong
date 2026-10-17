# 금성도 홈페이지

안강진구 홈페이지 전체 디자인·정적 자료·게시판 코드를 복제했습니다.

1. Settings → Pages에서 Deploy from a branch, main, /(root)를 선택하세요. 기본 주소는 https://geumseong.saevit.online/ 입니다.
2. 새 도메인을 정한 후 CNAME과 HTML의 미리보기 주소, scripts/refresh-share-pages.cjs의 origin을 변경하세요. 기존 안강진구 CNAME과 공개 게시글 스냅샷은 복제하지 않았습니다.
3. 기존 안강진구 Supabase 프로젝트의 SQL Editor에서 supabase/geumseong-setup.sql 전체를 실행하세요. 로그인 계정과 public.news_admins 관리자 명단은 공유하고, 게시글·파일·조직도는 geumseong_ 전용으로 분리합니다. 도메인이 다르면 같은 계정으로 각 사이트에서 로그인합니다.
4. 로고·사진·배너 및 설명은 복제된 임시 자료입니다. 각 config.js와 assets에서 교체하세요.
5. 공유 미리보기 작업은 .github/workflows/share-previews.yml을 직접 실행할 수 있습니다. 도메인·데이터베이스를 연결한 후 예약 실행을 설정하세요.
