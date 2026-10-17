# 금성도 도메인 연결

사용 주소: https://geumseong.saevit.online/

## Spaceship DNS
saevit.online의 DNS 관리에서 아래 레코드를 추가합니다.

| 항목 | 값 |
|---|---|
| 유형 | CNAME |
| 호스트/Name | geumseong |
| 대상/Value | dowonkyung.github.io |
| TTL | 기본값 |

대상에는 https:// 또는 /geumseong 경로를 넣지 않습니다. 기존 angangjin 및 다른 서브도메인 레코드는 유지합니다. geumseong 호스트에 충돌하는 A/AAAA/CNAME 레코드가 있다면 해당 호스트만 수정합니다.

## GitHub Pages
https://github.com/dowonkyung/geumseong/settings/pages 에서 Deploy from a branch → main → /(root)를 선택합니다.
Custom domain에 geumseong.saevit.online을 입력하고 Save를 누릅니다.
DNS 검사와 인증서 발급이 완료되면 Enforce HTTPS를 켭니다.

CNAME 파일과 HTML 공유 이미지 주소, 공유 페이지 생성기의 도메인·경로는 이 주소 기준으로 설정되어 있습니다. 로그인 계정 공유 설정은 그대로 유지됩니다.
