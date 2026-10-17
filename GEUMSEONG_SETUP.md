# 금성도 홈페이지

안강진구 홈페이지 전체 디자인·정적 자료·게시판 코드를 복제했습니다.

1. Settings → Pages에서 Deploy from a branch, main, /(root)를 선택하세요. 기본 주소는 https://dowonkyung.github.io/geumseong/ 입니다.
2. 새 도메인을 정한 후 CNAME과 HTML의 미리보기 주소, scripts/refresh-share-pages.cjs의 origin을 변경하세요. 기존 안강진구 CNAME과 공개 게시글 스냅샷은 복제하지 않았습니다.
3. 별도 Supabase 프로젝트에서 supabase 폴더 SQL을 설치하고 board-config.js에 공개 URL·키를 입력하세요. 기존 안강진구 저장소와 관리자·게시글은 연결하지 않았습니다.
4. 로고·사진·배너 및 설명은 복제된 임시 자료입니다. 각 config.js와 assets에서 교체하세요.
5. 공유 미리보기 작업은 .github/workflows/share-previews.yml을 직접 실행할 수 있습니다. 도메인·데이터베이스를 연결한 후 예약 실행을 설정하세요.
