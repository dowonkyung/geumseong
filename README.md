# 금성도청 홈페이지

안강진구 홈페이지의 전체 화면·메뉴·게시판·열린도지사실·통합검색을 복제한 금성도 홈페이지입니다. 기존 사진·배너·소개 내용은 교체 가능한 임시 자료입니다.

## 지금 필요한 설정

1. **웹 공개:** 저장소 Settings → Pages → Deploy from a branch → main → /(root).
2. **금성도 게시판 활성화:** 기존 안강진구 Supabase 프로젝트의 SQL Editor에서 [supabase/geumseong-setup.sql](supabase/geumseong-setup.sql) 전체 실행.
3. **도메인:** 금성도 전용 도메인이 정해지면 CNAME과 공유 미리보기 주소를 설정.

로그인 계정 및 관리자 명단(public.news_admins)은 안강진구와 공유합니다. 게시글·첨부파일·조직도는 geumseong_ 전용 테이블·버킷·함수로 분리했습니다. 도메인이 다르면 로그인 상태는 별도로 유지됩니다.

자세한 내용은 [GEUMSEONG_SETUP.md](GEUMSEONG_SETUP.md)를 확인하세요.
